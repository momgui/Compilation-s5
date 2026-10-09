# Micro-Go compiler

A compiler for Micro-Go, a subset of Go, written in OCaml. It produces MIPS assembly that runs in the [SPIM](https://spimsimulator.sourceforge.net/) simulator.

## Example

`micro-go/tests/point.go`:

```go
package main;
import "fmt";

type point struct { x,y int };

func main() {
     a := new(point);
     b := new(point);
     a.x = 1;
     a.y = 2;
     b.x = 3;
     b.y = 4;
     fmt.Print(a.x + a.y + b.x + b.y)
}
```

```
$ ./mgoc.exe tests/point.go      # writes tests/point.s
$ spim -file tests/point.s
Loaded: .../exceptions.s
10
```

## Pipeline

All source files are in `micro-go/`.

1. **Lexer** (`mgolexer.mll`, ocamllex). Keywords, identifiers, decimal and hexadecimal integer literals (a literal that does not fit in 64 bits is a lexical error), string literals with `\n \t \" \\` escapes, `//` and `/* */` comments. It implements Go-style automatic semicolon insertion: a `;` is emitted at a newline (or at a line-ending or end-of-file `//` comment) when the previous token is an identifier, a literal, `true`, `false`, `nil`, `return`, `)`, `}`, `++` or `--`.
2. **Parser** (`mgoparser.mly`, Menhir). Builds the AST defined in `mgoast.ml`, with the operator precedence of the course specification (`.` binds tightest).
3. **Type checker** (`typechecker.ml`). Checks types, scopes and declarations (see "Static checks" below).
4. **MIPS code generation** (`compile.ml`, using the MIPS helpers in `mips.ml`). Following the scheme set by the course, each expression leaves its result in `$t0` with intermediate values on the stack, and arguments are passed on the stack. Structs are allocated on the heap with the `sbrk` syscall, functions return up to two values in `$v0`/`$v1`, and `fmt.Print` is compiled to SPIM print syscalls.

`mgoc.ml` is the driver.

## Supported subset

- `package main`, optional `import "fmt"` (importing `fmt` without using it, or using it without importing it, is an error)
- Types `int`, `bool`, `string` and pointers to structs `*S`
- Struct declarations, including recursive structs (for example linked lists); allocation with `new(S)`
- Field read and write, `++`/`--` on variables and fields, chained access `a.b.c`
- `nil`, assigned to pointers and compared with `==`/`!=` against them (`nil == nil` and `nil.x` are rejected)
- Operators `+ - * / %`, unary `-`, `!`, `< <= > >= == !=`, `&& ||`
- `var` declarations with a type, an initialiser or both, short declarations `:=`, multiple assignment, the blank identifier `_` in declarations (`a, _ := f()`)
- Functions, recursion, mutual recursion, functions used before their declaration
- Multiple return values (at most two in code generation)
- `if` / `else` / `else if`
- `for {}`, `for cond {}`, `for init; cond; post {}` and the forms without init or post
- Block scoping and shadowing
- `fmt.Print` with one or more arguments of type `int`, `bool`, `string` or pointer

Static checks performed by the type checker:

- type correctness of expressions and statements
- `main` must exist and take no parameters and return no results
- a function with results must return on every path (an infinite `for {}` also counts)
- no duplicate struct or function names, no redeclaration in the same block
- unused local variables are an error (an assignment alone does not count as a use, as in Go)

Not supported: methods, arrays and slices, `&` and `*` expressions, struct values, global variables, `break`/`continue`, other `fmt` functions, string operations other than `==` and `!=` (no concatenation).

## Build and run

Prerequisites: OCaml, dune, Menhir and SPIM.

```
# macOS with Homebrew
brew install ocaml dune menhir spim

# or with opam (SPIM comes from your system package manager)
opam install dune menhir
```

Build:

```
cd micro-go
dune build @all        # or: make
```

The `dune` file promotes the executable, so the build writes `micro-go/mgoc.exe`. The `mgoc.exe` committed in the repository is a Linux x86-64 binary; rebuild it on any other platform (the rebuild replaces the tracked file, so git shows it as modified). `make clean` (`dune clean`) deletes `mgoc.exe`.

Menhir prints `18 shift/reduce conflicts were arbitrarily resolved` during the build. The build still succeeds. 15 of them involve `.` and are resolved as intended (`.` binds tightest); the other 3 involve `,` and are the reason trailing commas are rejected (see "Known limitations").

Compile and run a program:

```
./mgoc.exe file.go         # writes file.s next to file.go
spim -file file.s
```

Options: `--parse-only` stops after parsing, `--type-only` stops after type checking.

Run the tests:

```
make test                  # runs --parse-only on the 7 original tests
```

To check the output of a test, compile it and run the `.s` file in SPIM as shown above. Note that `./mgoc.exe tests/X.go` overwrites the committed `tests/X.s`. SPIM always exits with status 0, even after a runtime exception, so check its output.

## Tests

Results of the current compiler on every program in `micro-go/tests`:

| Test | Result | Verdict |
|---|---|---|
| `arith.go` | prints `42` | OK |
| `div.go` | prints `13`, `13`, `73`, `268566528` | Lines 1-2 wrong: they should print `73` like line 3 (two-value bug below); line 4 prints the pointer as an address |
| `edge_cases.go` | prints nothing (it prints only when a check fails) | OK |
| `instr.go` | prints `512` | OK |
| `min.go` | prints `42` | OK |
| `nil_fail.go` | rejected: `Cannot compare nil with nil` | OK (must be rejected) |
| `nil_test.go` | prints `okok` | OK |
| `point.go` | prints `10` | OK |
| `redecl.go` | rejected: `Variable x already declared in this block` | OK (must be rejected) |
| `shadow.go` | prints `21` | OK |
| `test.go` | rejected: `main function missing` (reported at line 0) | OK (no `main`) |
| `var.go` | prints `42` | OK |

All tests pass `--parse-only`. `tests/inc_used.s`, `shadow_bug.s` and `shadow_bug_2.s` have no `.go` source, and the committed `tests/div.s` and `tests/redecl.s` come from an earlier version of the compiler (the current one generates a different `div.s` and rejects `redecl.go`).

## Known limitations

Main bugs, all reproduced:

- **String literals are not re-escaped in the assembly**, so a string containing `\"` or `\\` breaks the generated `.asciiz` (`compile.ml:377`). `\n` and `\t` work.
- **Two-value calls lose a value in two places.** `fmt.Print(f())` prints the wrong first value because `$v0` is overwritten by the syscall number (`compile.ml:111`), and `return f()` passes on only one value.
- **Syntax errors are reported as an internal anomaly** (`MenhirBasics.Error`, exit code 2) instead of `syntax error` with a location, because the `exception Error` declared in the parser header shadows Menhir's. Lexical and type errors are reported correctly.
- **`&&` and `||` do not short-circuit**, so `p != nil && p.x > 0` dereferences `nil`.
- **`var x int` without an initialiser is not set to zero.**
- **Some invalid programs crash the compiler instead of being rejected** (exit code 2): `_` as an assignment target, a two-value call assigned to struct fields, a duplicate struct field, a struct used by value.

Smaller gaps: unused function parameters are rejected (Go allows them), at most two return values in code generation, `f(g())` with a multi-value `g` is not supported, trailing commas are rejected, literals are truncated to 32 bits at run time, there are no runtime checks (nil dereference, division by zero), `fmt.Print` does not separate its operands, and whole-program errors (missing `main`, `fmt` import) are reported at line 0.

## Project context and credits

Pair project by Guillaume Mombellet and Arthur Legal for the course "Langages de programmation, interprétation, compilation" (L3, semester 5) at Université Paris-Saclay, autumn 2025.

The course provided a skeleton (initial commit `ca52045`): the AST (`mgoast.ml`, unchanged since apart from one blank line), the driver `mgoc.ml`, stub versions of `mgolexer.mll`, `mgoparser.mly` and `typechecker.ml`, the build files, and seven test programs (`arith`, `div`, `instr`, `min`, `point`, `test`, `var`). For code generation the course provided four more files: `mips.ml` (a MIPS emission interface; only two register names were added after its first commit), a skeleton of `compile.ml`, a `typechecker.ml` adjusted to return the declarations, and a `mgoc.ml` extended to call code generation. These were not committed separately, so the history cannot show which lines of `compile.ml` come from the course.

Written in the project, starting from those stubs: the lexer (including automatic semicolon insertion), the parser, the type checker (including the unused-variable check), the code generation in `compile.ml` (383 lines in the final version), and the tests `edge_cases.go`, `nil_fail.go`, `nil_test.go`, `redecl.go` and `shadow.go`.

The finished compiler is on branch `guillaume`. Branch `main` stops shortly after the skeleton (small edits to the stubs, a README and a `.gitignore`), and branch `Arthur` holds a separate lexer commit that was not merged.

## Repository layout

```
micro-go/
  mgoc.ml           driver (command-line options, error reporting)
  mgolexer.mll      lexer (ocamllex)
  mgoparser.mly     parser (Menhir)
  mgoast.ml         AST
  typechecker.ml    type checker
  typechecker.mli
  compile.ml        MIPS code generation
  mips.ml           MIPS instruction helpers
  dune, dune-project, Makefile
  tests/            test programs (.go) and generated assembly (.s)
  README.md         project description (in French)
LICENSE             MIT
```

## License

MIT, see `LICENSE`.
