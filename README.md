# IMP Compiler
An LLVM-based toy compiler for a variant of "IMP" described in CS311 (Programming Languages Design & Implementation). 

## Compilation
In order to compile this, you use the `dune` build system (install dependencies w/ `opam`).
```
opam install dune menhir llvm
cd imp-compiler
dune build src/main.exe
```

## Usage
Currently the usage is quite limited:
```
./_build/default/src/main.exe file1 file2 ... fileN
```
This will parse, compile, dump the LLVM module for each file to both `stdin` and a `fileX.ll` locally.
In order to run an IMP program, the program must contain a `main` function w/ 0 arguments (as that compiles directly to `main` that gets called from `libc`'s entry routine):

- You can interpret the programs w/ `lli fileX.ll`.
- You can target an architecture supported by LLVM w/ `llc` (and a target architecture provided by `-march=`, e.g. `llc -march=arm64 program.ll` will produce AArch64 assembly):
```
./build/default/src/main.exe program.ll
llc program.ll
gcc program.s -o program && ./program
```
You can also play around with LLVM's own optimisations w/ `opt`, for example: `opt -O3 program.ll -S` will apply aggressive optimisations (you can list all of the optimisations w/ `opt -h`).

## TODO:
- Use OCaml's argument parser to allow for more flexible options (e.g. `-parse` to dump the AST).
- Actually handle parsing errors w/ locations.
- Provide `emacs`, `vim`, etc. highlighting files.
- Wouldn't be far-fetched to provide debugging information w/ lines corresponding to imperative constructs of the language. Though this would require actually using LLVM's targeting APIs directly.
- Provide some example programs in an `example/` sub-directory.
## Implementation Notes 
- The `new` construct is known as `let` in this language, though, that might change given that both the refer to mutable lvalues.
- All variables are spilled to local `alloca` locations, this is so that all variables are lvalues such that we don't need to insert phi functions in order to merge re-defs of SSA variables at join points. Luckily for us, LLVM's `mem2reg` pass does a really good job of lifting these. The compilation for a function proceeds as you would expect: all parameters are spilled into local "stack" (`alloca`) locations then the body is compiled w/ an environment prepended with the spilled locations (all read/writes of named variables compiled to load/stores, respectively). The compilation of `let` follows  a similar scheme.
- The grammar hasn't been properly factored and I'm missing some useful constructs. For example, there are currently ~6  shift/reduce conflicts that menhir arbitrarily resolves. As for the useful constructs that are currently lacking: there's no unary `-x` syntax for negative literals (though this would be easy to add - currently one can just define `-x` as `0 - x`), there's no `if` statement without an `else`.
- There's probably bugs. 