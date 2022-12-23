# Nim-pipexp 

Expression-based pipe operators with placeholder argument for Nim.

## Nim already has UCS

### UCS
Nim already has a nice syntax sugar called
"[Universal Call Syntax](https://en.wikipedia.org//wiki/Uniform_Function_Call_Syntax)"
or UCS that lets you call procedures on arguments with the popular 'dot'
notation of other object-oriented languages. So this already acts
like a simple chaining pipe operator for functions with
first argument on the left-hand side:

```nim
proc plus20(arg0: int): int = arg0 + 20
proc plus(arg0, x: int): int = arg0 + x

let a = 10 . plus20
10 . plus20 . echo
10 . plus20 . plus20() . echo
10 . plus(20) . echo
10 . plus(30) . plus(40) . echo
```

Sometimes this is all you need.
However you can't use this syntax if you want
to pipe into procs on arguments other than the
first one.

## Usage

With `pipexp` you can still use a UCS syntax, but also
use a placeholder "`_`" argument where the return of
the previous pipe is inserted to:

*I don't know if I'll keep `|` as the operator, it's still early*

```nim
import pipexp
proc plus20(arg0: int): int = arg0 + 20
proc plus_a0(arg, x: int): int = arg + x
proc plus_a1(x, arg: int): int = arg + x

let a = 10 | plus20
10 | plus20 | echo
10 | plus20 | plus20() | plus20(_) | echo
10 | plus_a0(20) | echo
10 | plus_a0(_,20) | echo
10 | plus_a1(20,_) | echo
10 | plus_a1(30,_) | plus_a1(40,_) | echo

# You can pass multiple placeholders:
proc plus_as(a1, a2, a3: int): int = a1 + a2 + a3
10 | plus_as(_,_,50) | echo
10 | plus_as(90,_,_) | echo
10 | plus_as(_,_,_) | echo

# You can pass lambdas if they are enclosed by curly brackets or parentheses:
10 | {
proc(x: int): int =
  x + 20
} | echo

# You can index the placeholder
[10,20] | plus20(_[1]) | echo
[10,20] | plus20(_[0]) | echo

# You can call the placeholder
plus20 | plus20(_(10)) | echo
```

You can also make use of a pipeline macro called `pipe` to
separate the callables in different lines:
```nim
let b = pipe(10, plus20)
pipe(10, plus20, echo)
pipe(10, plus20, plus20(), plus20(_), echo)
pipe(10, plus_a1(30,_), plus_a1(40,_), echo)

let c = pipe 10:
  plus20
  plus_a0(40)
  plus_a1(30,_)
  {
    proc (_: int): int =
      _ + 50
  }
```

## Nim also has [`dup`](https://nim-lang.org/docs/sugar.html#dup.m%2CT%2Cvarargs%5Buntyped%5D) and [`with`](https://nim-lang.org/docs/with.html#with.m%2Ctyped%2Cvarargs%5Buntyped%5D)

If your functions are in-place instead (they modify a var argument)
you can use the
[`dup`](https://nim-lang.org/docs/sugar.html#dup.m%2CT%2Cvarargs%5Buntyped%5D)
macro from `std/sugar` to work on a mutable copy of the argument,
chain functions modifying it, and return it at the end:

```nim
import std/sugar
proc plus20InPlace(arg0: var int): void = arg0 += 20
proc plusInPlace(arg0: var int, x: int): void = arg0 += x

let arg: int = 10
let a = dup(arg, plus20InPlace)
let b = dup arg:
  plus20InPlace
  plus20InPlace()
  plusInPlace(_,30)
echo $arg & " " & $a & " " & $b
```

or the
[`with`](https://nim-lang.org/docs/with.html#with.m%2Ctyped%2Cvarargs%5Buntyped%5D)
macro from `std/with` to just chain those in-place functions
on the argument:

```nim
import std/with
proc plus20InPlace(arg0: var int): void = arg0 += 20
proc plusInPlace(arg0: var int, x: int): void = arg0 += x

var arg: int = 10
with arg:
  plus20InPlace
  plus20InPlace()
  plusInPlace(_,30)
echo arg
```

## To-do
- [ ] Support anonymous procs
	- [X] Nim native lambdas
	- [ ] `=>` anonymous procs from `std/sugar`
- [ ] Other features like [Pipe.jl](https://github.com/oxinabox/Pipe.jl)
	- [X] Indexing placeholder
	- [ ] Unpacking placeholder
	- [X] Calling placeholder
- [ ] Allow configuring the placeholder symbol
- [X] Allow multiple instances of the placeholder

Maybe:
- Other operators like [magrittr](https://github.com/tidyverse/magrittr)

## Similar
- [Iterr](https://github.com/hamidb80/iterrr)
- [Pipe](https://github.com/CosmicToast/pipe)
- [Pipelines](https://github.com/calebwin/pipelines)

## See also
- [Pipe proposal in JavaScript](https://github.com/tc39/proposal-pipeline-operator)
