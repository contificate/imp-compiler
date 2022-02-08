
module CG = Codegen

let parse str =
  let lexbuf = Lexing.from_string str in
  try
    Ok (Parser.program Lexer.tokenise lexbuf)
  with
  | Lexer.Error _ | Parser.Error ->
     let (s, e) = (Lexing.lexeme_start lexbuf, Lexing.lexeme_end lexbuf) in
     Error ("Parse error, offsets: " ^ string_of_int s ^ " -> " ^ string_of_int e)

let (>>) f g x = g (f x)

let print_parse f =
  match parse (Core.In_channel.read_all f) with
  | Ok defs ->
     List.iter (Ast.show_def >> print_endline) defs
  | Error msg ->
     print_endline msg

let compile f =
  let open Core in
  match parse (In_channel.read_all f) with
  | Error msg -> print_endline msg
  | Ok defs ->
     let md = Llvm.create_module CG.ctx f in
     let ir = CG.compile_definitions md defs |> Llvm.string_of_llmodule in
     match Llvm_analysis.verify_module md with
     | Some err ->
        print_endline err
     | _ ->
        Out_channel.write_all (f ^ ".ll") ~data:ir

let options =
  [
    ("-p", Arg.String print_parse, "Parse the given .imp file and print its AST to stdout");
    ("-c", Arg.String compile, "Compile input.imp and output IR to input.imp.ll");
    ("-s", Arg.Unit Service.run_server, "Run the compiler as a service over DBus")
  ]


let unrecognised =
  Printf.printf "unrecognised option, %s, please use -help"

let main () =
  Arg.parse options unrecognised "IMP Compiler"

let () =
  main ()

