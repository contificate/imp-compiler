
(* TODO: _actually_ resolve the ambiguity? *)

(* lexemes *)
%token <int> INT
%token <string> IDENT

(* syntactic noise *)
%token LPAR RPAR
%token LBRACE RBRACE
%token COMMA
%token SEMICOLON
%token NOT

(* keywords *)
%token IF ELSE WHILE LET IN INTEGER COMMAND DO RETURN
%token TRUE FALSE

(* operators *)
%token ASSIGN
%token ADD SUB
%token EQ NE LT LE GT GE

%token EOF

(* program is a list of definitions and a top-level expr *)

%start <Ast.def list> program

%type <Ast.expr> expr
%type <Ast.op> op
%type <Ast.bexpr> bexpr 
%type <Ast.cmp> cmp
%type <Ast.cmd> cmd
%type <Ast.def> def

%%

program:
  | defs = list(def) EOF
    { defs }

expr:
  | x = INT
    { Literal x }
  | x = IDENT
    { Var x }
  | x = expr; o = op; y = expr
    { Iop (o, x, y) }
  | LET x = IDENT ASSIGN e = expr IN y = expr
    { Let (x, e, y) }
  | f = IDENT LPAR xs = separated_list(COMMA, expr) RPAR
    { Apply (f, xs) }
  | DO c = cmd RETURN e = expr
    { Do (c, e) }
  | LPAR e = expr RPAR
    { e }

op:
  | ADD
    { Add }
  | SUB
    { Sub }

cmp:
  | EQ
    { Eq }
  | NE
    { Ne }
  | LT
    { Lt }
  | LE
    { Le }
  | GT
    { Gt }
  | GE
    { Ge }

bexpr:
  | TRUE
    { True }
  | FALSE
    { False }
  | NOT e = bexpr
    { Negate e }
  | x = expr c = cmp y = expr
    { Bop (c, x, y) }
  | LPAR e = bexpr RPAR
    { e }

cmd:
  | IF LPAR e = bexpr RPAR t = cmd ELSE f = cmd
    { If (e, t, f) }
  | WHILE LPAR e = bexpr RPAR c = cmd
    { While (e, c) }
  | LET x = IDENT ASSIGN e = expr IN y = cmd
    { New (x, e, y) }
  | x = IDENT ASSIGN e = expr
    { Assign (x, e) }
  | f = IDENT LPAR xs = separated_list(COMMA, expr) RPAR
    { Call (f, xs) }
  | LBRACE; cs = list(terminated(cmd, SEMICOLON)); RBRACE
    { Block (cs) }

def:
  | INTEGER f = IDENT LPAR xs = separated_list(COMMA, IDENT) RPAR EQ e = expr
    { Function (f, xs, e) }
  | COMMAND f = IDENT LPAR xs = separated_list(COMMA, IDENT) RPAR EQ c = cmd
    { Routine (f, xs, c) }
