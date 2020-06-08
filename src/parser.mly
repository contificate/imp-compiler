
(* 

The shift/reduce conflict lies in the "let" and "do" constructs. 

For example: let x := 3 in x + let y := 4 in y
should parse as:
let x := 3 in x + (let y := 4 in y)
however the ambiguity is that it could be parsed as
(let x := 3 in x) + (let y := 4 in y)
which would be wrong.

I can't think of a way to factor this grammar without changing the meaning
of its programs or changing the syntax to introduce tokens that remove the conflict (at the cost of burden to the programmer).

*)

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
%token MUL
%token ADD SUB
%token EQ NE LT LE GT GE

%token EOF

(* program is a list of definitions and a top-level expr *)

%start <Ast.def list> program

(* fix 3 conflicts by assigning precedences *)
%left ADD SUB
%left MUL

%type <Ast.expr> expr
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
  | x = expr ADD y = expr
    { Iop (Add, x, y) }
  | x = expr SUB y = expr
    { Iop (Sub, x, y) }
  | x = expr MUL y = expr
    { Iop (Mul, x, y) }
  | LPAR e = expr RPAR
    { e }
  | SUB x = INT
    { Literal (-x) }
  | LET x = IDENT ASSIGN e = expr IN y = expr
    { Let (x, e, y) }
  | f = IDENT LPAR xs = separated_list(COMMA, expr) RPAR
    { Apply (f, xs) } 
  | DO c = cmd RETURN e = expr
    { Do (c, e) }

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
