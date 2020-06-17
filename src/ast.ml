
(* arithmetic operators on integer expressions *)
type op = Add | Sub | Mul
[@@deriving show {with_path = false}]

(* comparison operators on boolean expressions *)
type cmp = Eq | Ne | Lt | Le | Gt | Ge
[@@deriving show {with_path = false}]

(* integer expressions *)
type expr =
  | Literal of int
  | Var of string
  | Iop of op * expr * expr
  | Let of string * expr * expr
  | Do of cmd * expr
  | Apply of string * expr list
[@@deriving show {with_path = false}]
(* imperative commands *)
and cmd =
  | Block of cmd list
  | If of bexpr * cmd * cmd
  | While of bexpr * cmd
  | Assign of string * expr
  | New of string * expr * cmd
  | Call of string * expr list
[@@deriving show {with_path = false}]
(* boolean expressions *)
and bexpr =
  | True
  | False
  | Negate of bexpr
  | Bop of cmp * expr * expr
[@@deriving show {with_path = false}]

(* return "types" of top-level definitions; int | unit *)
type typ = Integer | Command
[@@deriving show {with_path = false}]

(* imperative constructs *)
type def =
  | Function of string * string list * expr
  | Routine of string * string list * cmd
[@@deriving show {with_path = false}]

