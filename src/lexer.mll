
{
  open Parser
  exception Error of string
}

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
| ['a'-'z']+ as i
  { IDENT i }
| eof
   { EOF }
   