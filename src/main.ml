
module CG = Codegen

let prog =
"
integer test(a) =
  let r := 0 in
  do {
    if (a > 2) { if(a = 10) { r := 33; } else {}; } else { r := 2; };
  } return r

integer main() = test(10) 

"

let parse str =
  let lexbuf = Lexing.from_string str in
  Parser.program Lexer.tokenise lexbuf

let main () =
  let compile f =
    let defs = parse (Core.In_channel.read_all f) in
    let md = Llvm.create_module CG.ctx f in
    let ir = CG.compile_definitions md defs |> Llvm.string_of_llmodule in
    match Llvm_analysis.verify_module md with
    | Some err ->
       print_endline err
    | _ ->
       print_endline ir;
       Core.Out_channel.write_all (f ^ ".ll") ~data:ir
  in
  List.iter compile (List.tl (Array.to_list Sys.argv))
  
  
let _ = main ()
