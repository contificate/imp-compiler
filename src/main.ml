
module CG = Codegen

let parse str =
  let lexbuf = Lexing.from_string str in
  Parser.program Lexer.tokenise lexbuf

let print_parse f =
  try
    List.iter (fun d -> Ast.show_def d |> print_endline) (Core.In_channel.read_all f |> parse)
  with _ -> print_endline "Failed to parse file or file doesn't exist!"

let compile f =
  let defs = parse (Core.In_channel.read_all f) in
  let md = Llvm.create_module CG.ctx f in
  let ir = CG.compile_definitions md defs |> Llvm.string_of_llmodule in
  match Llvm_analysis.verify_module md with
  | Some err ->
     print_endline err
  | _ ->
     Core.Out_channel.write_all (f ^ ".ll") ~data:ir


let options =
  [
    ("-p", Arg.String print_parse, "Parse the given .imp file and print its AST to stdout");
    ("-c", Arg.String compile, "Compile input.imp and output IR to input.imp.ll")
  ]

let unrecognised x =
  "unrecognised option" ^ x ^ ", please use -help"
  |> print_endline

let main () = Arg.parse options unrecognised "IMP Compiler"

let _ = main ()
