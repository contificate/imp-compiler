open Lwt

(* response format for dbus methods *)
type response = { status: bool; value: string }
[@@deriving yojson]

(* represent an offset pair within the source *)
type loc = int * int
[@@deriving yojson]

(* attempt to parse program *)
let parse_imp source =
  let lexbuf = Lexing.from_string source in
  let response = 
    try
      let defs = Parser.program Lexer.tokenise lexbuf in
      { status = true; value = List.map Ast.show_def defs |> String.concat "\n" }
    with
    | Lexer.Error _ | Parser.Error ->
       let range = (Lexing.lexeme_start lexbuf, Lexing.lexeme_end lexbuf) in
       { status = false; value = loc_to_yojson range |> Yojson.Safe.to_string }
  in
  response_to_yojson response |> Yojson.Safe.to_string |> return

(* attempt to compile program *)
let compile_imp source =
  let lexbuf = Lexing.from_string source in
  let response = 
    try
      let defs = Parser.program Lexer.tokenise lexbuf in
      let ctx = Llvm.create_context () in
      let modu = Codegen.compile_definitions (Llvm.create_module ctx "source.imp") defs in
      { status = true; value = Llvm.string_of_llmodule modu}
    with
    | Lexer.Error _ | Parser.Error ->
       let range = (Lexing.lexeme_start lexbuf, Lexing.lexeme_end lexbuf) in
       { status = false; value = loc_to_yojson range |> Yojson.Safe.to_string }
  in
  response_to_yojson response |> Yojson.Safe.to_string |> return
  

(* bind interface methods to callbacks *)
let interface =
  Server.Org_imp_Compiler.make
    {
      Server.Org_imp_Compiler.m_ParseIMP = (fun _ -> parse_imp);
      Server.Org_imp_Compiler.m_CompileIMP = (fun _ -> compile_imp);
    }

(* indefinitely act as compilation service *)
let run_server () =
  Lwt_main.run
    begin
      let%lwt bus = OBus_bus.session () in
      let%lwt _ = OBus_bus.request_name bus "imp.compiler" in
      let obj = OBus_object.make ~interfaces:[interface] ["Compiler"] in
      OBus_object.attach obj ();

      OBus_object.export bus obj;
      fst (wait ())
    end
