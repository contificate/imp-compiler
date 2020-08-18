
{
  open Parser
  exception Error of string
}

let ident = ['_' 'a'-'z' 'A'-'Z'] ['_' 'a'-'z' 'A'-'Z' '0'-'9']*

rule tokenise = parse
| [' ' '\t' '\n']
    { tokenise lexbuf }
| ['0'-'9']+ as i
    { INT (int_of_string i) }
| '('
    { LPAR }
| ')'
    { RPAR }
| '='
    { EQ }
| '{'
    { LBRACE }
| '}'
    { RBRACE }
| '+'
    { ADD }
| '-'
    { SUB }
| '*'
    { MUL }
| ','
    { COMMA }
| '!'
    { NOT }
| ';'
    { SEMICOLON }
| ":="
    { ASSIGN }
| "!="
    { NE }
| '<'
    { LT }
| "<="
    { LE }
| '>'
    { GT }
| ">="
    { GE }
| "if"
    { IF }
| "else"
    { ELSE }
| "while"
    { WHILE }
| "let"
    { LET }
| "in"
    { IN }
| "integer"
    { INTEGER }
| "command"
    { COMMAND }
| "true"
    { TRUE }
| "false"
    { FALSE }
| "do"
    { DO }
| "return"
    { RETURN }
| "//"
    { read_comment lexbuf }
| ident as i
  { IDENT i }
| eof
   { EOF }
and read_comment = parse
| '\n'
    { tokenise lexbuf }
| [^ '\n']+
    { read_comment lexbuf }
   