
open Ast
open Llvm
module LA = Llvm_analysis

type gen_ctx = { md: llmodule; b: llbuilder }

let ctx = create_context ()
let i32 = i32_type ctx
type env = (string * llvalue) list

let const_tt = const_int (i1_type ctx) 1
let const_ff = const_int (i1_type ctx) 0

exception Error of string

let (>>) g f = (fun x -> g x |> f)

let undefined = const_int i32 (-1)

(* no built-in way it seems, sue me *)
let is_pointer_t v =
  let typ = string_of_lltype (type_of v) in
  String.get typ (String.length typ - 1) = '*'

let rec lookup k = function
  | [] -> None
  | ((x, v) :: tl) ->
     if k = x then
       Some v
     else
       lookup k tl

let value_of_var gc env x =
  match lookup x env with
  | None -> raise (Error ("No variable " ^ x ^ " in environment!"))
  | Some v ->
     (if is_pointer_t v then build_load v "" gc.b else v)

let op_of_op = function
  | Add -> build_add
  | Sub -> build_sub
  | Mul -> build_mul

let cond_of_cmp = function
  | Eq -> Icmp.Eq
  | Ne -> Icmp.Ne
  | Lt -> Icmp.Slt
  | Le -> Icmp.Sle
  | Gt -> Icmp.Sgt
  | Ge -> Icmp.Sge

let negate_cmp = function
  | Eq -> Ne
  | Ne -> Eq
  | Lt -> Ge
  | Le -> Gt
  | Gt -> Le
  | Ge -> Lt

let negate_bexpr = function
  | True -> False
  | False -> True
  | Negate b -> b
  | Bop (cmp, x, y) ->
     Bop (negate_cmp cmp, x, y) 

let rec compile_expr gc env e =
  match e with
  | Literal i -> (const_int i32 i, env)
  | Var x -> (value_of_var gc env x, env)
  | Let (x, e, e') ->
  (* evaluate e, extend x  *)
     let loc = build_alloca i32 x gc.b in
     let (ex, _) = compile_expr gc env e in
     build_store ex loc gc.b |> ignore;
     compile_expr gc ((x, loc) :: env) e'
  | Apply (f, xs) ->
     (match lookup_function f gc.md with
      | None -> raise (Error ("Couldn't find function " ^ f))
      | Some fn ->
         (build_call fn (List.map (compile_expr gc env >> fst) xs |> Array.of_list) "" gc.b, env))
  | Iop (op, x, y) ->
     let compile = compile_expr gc env >> fst in
     let (lhs, rhs) = (compile x, compile y) in
     (op_of_op op lhs rhs "" gc.b, env)
  | Do (c, e) -> (* do c return e *)
     compile_cmd gc env c;
     compile_expr gc env e
  and
    compile_cmd gc env c =
    match c with
    | Block cs ->
       List.iter (compile_cmd gc env) cs
    | Assign (x, e) ->
       let (e', _) = compile_expr gc env e in
       (match lookup x env with
        | None -> raise (Error ("No such variable " ^ x))
        | Some l -> build_store e' l gc.b |> ignore)
    | If (c, t, f) ->
       let source = insertion_block gc.b in
       let parent = block_parent source in
        let new_block n =
          append_block ctx n parent
        in
        begin
          let (sink, tb, eb) = (new_block "sink", new_block "then", new_block "else") in
          let fill (branch, body) =
            position_at_end branch gc.b;
            compile_cmd gc env body;
            build_br sink gc.b |> ignore
          in
          (* create the conditional branch *)
          let cond = compile_bexpr gc env c in
          position_at_end source gc.b;
          build_cond_br cond tb eb gc.b |> ignore;
          (* fill in branch targets *)
          fill (tb, t);
          fill (eb, f);
          (* continue from sink *)
          position_at_end sink gc.b
        end
    | New (x, e, c) ->
       let loc = build_alloca i32 x gc.b in
       build_store (compile_expr gc env e |> fst) loc gc.b |> ignore;
       compile_cmd gc ((x, loc) :: env) c
    | Call (f, xs) ->
       (match lookup_function f gc.md with
        | None -> raise (Error ("Couldn't find function " ^ f))
        | Some fn ->
           (build_call fn (List.map (compile_expr gc env >> fst) xs |> Array.of_list) "" gc.b, env) |> ignore)
    | While (c, body) ->
       let parent = block_parent (insertion_block gc.b) in
        let new_block n =
          append_block ctx n parent
        in
        let (sink, tb, bb) = (new_block "sink", new_block "test", new_block "body") in
        begin
          (* branch to while header *)
          position_at_end (insertion_block gc.b) gc.b;
          build_br tb gc.b |> ignore;
          (* test loop condition in header *)
          position_at_end tb gc.b;
          let cond = compile_bexpr gc env c in
          build_cond_br cond bb sink gc.b |> ignore;
          (* compile loop body *)
          position_at_end bb gc.b;
          compile_cmd gc env body;
          (* jump back to loop test *)
          build_br tb gc.b |> ignore;
          (* continue generation in sink *)
          position_at_end sink gc.b;
        end
  and
    compile_bexpr gc env = function
    | True -> const_tt
    | False -> const_ff
    | Negate b ->
       compile_bexpr gc env (negate_bexpr b)
    | Bop (op, x, y) ->
       let compile = compile_expr gc env >> fst in
       let (lhs, rhs) = (compile x, compile y) in
       build_icmp (cond_of_cmp op) lhs rhs "" gc.b


let compile_function gc (f, xs, body) =
  let arity = List.length xs in
  let ty = function_type i32 (Array.make arity i32) in
  let func = declare_function f ty gc.md in
  let entry = append_block ctx (f ^ "_entry") func in
  begin
    (* go to entry *)
    position_at_end entry gc.b;
    let locs : env = List.map (fun x -> (x, build_alloca i32 x gc.b)) xs in
    (* spill every argument into locals *)
    let spill i arg =
      build_store arg (List.nth locs i |> snd) gc.b |> ignore
    in
    Array.iteri spill (params func);
    (* compile the body and return its evaluation *)
    let result = compile_expr gc locs body  |> fst in
    if (f = "main" && arity = 0) then
      (match lookup_function "printf" gc.md with
       | None -> build_ret (const_int i32 1) |> ignore
       | Some printf ->
          let reloc = build_global_stringptr "result = %d\n" "fmt" gc.b in
          let fmt = build_gep reloc [|(const_int i32 0)|] "" gc.b in
          build_call printf [|fmt; result|] "" gc.b |> ignore;
          build_ret (const_int i32 0) gc.b |> ignore)
    else
      build_ret result gc.b |> ignore;
    if LA.verify_function func then
      print_endline ("Successfully compiled " ^ f ^ "!")
    else
      print_endline ("Code generation failed for " ^ f ^ "!")
  end

let compile_definitions md defs =
  let gctx = { md = md; b = builder ctx } in
  (* declare printf for main's return *)
  declare_function "printf" (var_arg_function_type i32 [|i8_type ctx |> pointer_type|]) md |> ignore;
  (* top-level construct dispatch *)
  let compile_def = function
    | Function (f, xs, body) ->
       compile_function gctx (f, xs, body)
    | _ -> ((* routine compilation? solely side-effectual, what's the point? *))
  in
  List.iter compile_def defs;
  md
