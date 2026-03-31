import
  unittest,
  std/[strutils, sugar],
  pipexp,
  math

proc plus20(arg0: int): int = arg0 + 20
proc plus30(arg0: int): int = arg0 + 30
proc mul3(arg0: int): int = arg0 * 3
proc plus20Multi(arg1, arg2, arg3: int): int = arg1 + arg2 + arg3 + 20
proc identityproc(x: proc): proc = x
proc minus(a, b: int): int = a - b
proc divInt(a, b: int): int = a div b
proc formatCoords(x, y, z: int): string = $x & ":" & $y & ":" & $z
proc power10Sum[T](A: openArray[T]): T =
  let len = A.len
  for i in 0 ..< len:
    result +=  A[i] * 10^(len-i-1)


suite "|>":
  let
    arg0 = 10
    A0 = @[1,2,3,4]

  test "builtin procs":
    check:
      arg0 + 20 == arg0 |> +20
      arg0 - 15 == arg0 |> - 15
      arg0 * 2 == arg0 |> *2
      arg0 / 2 == arg0 |> /2
      succ(arg0) == arg0 |> succ
      pred(arg0) == arg0 |> pred

      true and true == true |> and(true)
      true or false == true |> or(false)
      true xor false == true |> xor(false)
      # `not` cannot be natively used
      #not true == true |> not()

      (arg0 == arg0) == (arg0 |> == arg0)
      (arg0 != arg0) == (arg0 |> != arg0)
      (arg0 <= arg0+1) == (arg0 |> <=(arg0+1))
      (arg0 >= arg0+1) == (arg0 |> >=(arg0+1))
      (arg0 < arg0+1) == (arg0 |> <(arg0+1))
      (arg0 > arg0+1) == (arg0 |> >(arg0+1))
      arg0 in [arg0,0] == arg0 |> in [arg0,0]

      A0[2] == A0 |> `[]`(2)
      A0[1..3] == A0 |> `[]`(1..3)

  test "1 argument procs":
    check:
      plus20(arg0) == arg0 |> plus20
      plus20(arg0) == arg0 |> plus20()
      plus20(arg0) == arg0 |> plus20(_)

    test "pipelines 1 argument":
      check:
        plus30(plus20(arg0)) == arg0 |> plus20 |> plus30
        plus20(plus30(arg0)) == arg0 |> plus30 |> plus20
        plus20(plus20(arg0)) == arg0 |> plus20() |> plus20
        plus20(plus20(arg0)) == arg0 |> plus20 |> plus20()
        plus20(plus20(arg0)) == arg0 |> plus20() |> plus20()
        plus20(plus20(arg0)) == arg0 |> plus20(_) |> plus20(_)

  test "multiple argument procs":
    check:
      plus20Multi(arg0,0,0) == arg0 |> plus20Multi(0,0)
      plus20Multi(arg0,0,0) == arg0 |> plus20Multi(_,0,0)
      plus20Multi(arg0,arg0,0) == arg0 |> plus20Multi(_,_,0)
      plus20Multi(arg0,arg0,arg0) == arg0 |> plus20Multi(_,_,_)

    test "pipelines multiple argument":
      check:
       plus20Multi(plus20Multi(arg0,0,0),1,1) == arg0 |> plus20Multi(0,0) |> plus20Multi(1,1)
       plus20Multi(plus20Multi(arg0,0,0),1,1) == arg0 |> plus20Multi(_,0,0) |> plus20Multi(_,1,1)
       plus20Multi(plus20Multi(arg0,1,2),3,4) == arg0 |> plus20Multi(1,2) |> plus20Multi(3,4)
       plus20Multi(1,plus20Multi(arg0,0,0),1) == arg0 |> plus20Multi(0,0) |> plus20Multi(1,_,1)
       plus20Multi(1,1,plus20Multi(arg0,0,0)) == arg0 |> plus20Multi(0,0) |> plus20Multi(1,1,_)

  test "placeholder special":

    test "placeholder indexing":
      check:
        plus20(A0[0]) == A0 |> plus20(_[0])
        plus20(A0[^1]) == A0 |> plus20(_[^1])

    test "placeholder slicing":
      check:
        power10Sum(A0[0..2]) == A0 |> power10Sum(_[0..2])
        power10Sum(A0[0..^1]) == A0 |> power10Sum(_[0..^1])

    test "placeholder calling":
      check:
        mul3(plus20(arg0)) == plus20 |> mul3(_(arg0))
        mul3(plus20(arg0)) == plus20 |> identityproc |> mul3(_(arg0))
        plus30(plus20(mul3(arg0))) == mul3 |> plus20(_(arg0)) |> plus30


  test "lambdas":
    check plus20(arg0) == arg0 |> (
      proc (x: int): int = x + 20
    )

    # pipeline with 1 lambda
    test "pipeline lambdas":
      check plus20(arg0 + 40) == arg0 |> (
        proc (x: int): int = x + 40
      ) |> plus20

      # pipeline with multiple lambdas, not next to each other
      let ret2 = arg0 |> (
        proc (x: int): int = x + 30
      ) |> plus20 |> (
        proc (x: int): int = x + 30
      )

      check (arg0 + 80) == ret2

      # pipeline with multiple lambdas, next to each other
      # FIXME: redefinition of ':anonymous'; previous declaration here:
      let ret3 = arg0 |> (
        proc (x: int): int = x + 30
      ) |> (
        proc (x: int): int = x + 30
      )

      check (arg0 + 60) == ret3



suite "pipe":
  let
    arg0 = 10
    A0 = @[1,2,3,4]

  test "1 argument procs":
    check:
      plus20(arg0) == pipe(arg0, plus20)
      plus20(arg0) == pipe(arg0, plus20())
      plus20(arg0) == pipe(arg0, plus20(_))

    let ret1 = pipe arg0:
      plus20
    let ret2 = pipe arg0:
      plus20()
    let ret3 = pipe arg0:
      plus20(_)

    check:
      plus20(arg0) == ret1
      plus20(arg0) == ret2
      plus20(arg0) == ret3

  test "multiple argument procs":
    check:
      plus20Multi(arg0,0,0) == pipe(arg0, plus20Multi(0,0))
      plus20Multi(arg0,0,0) == pipe(arg0, plus20Multi(_,0,0))
      plus20Multi(arg0,arg0,0) == pipe(arg0, plus20Multi(_,_,0))
      plus20Multi(arg0,arg0,arg0) == pipe(arg0, plus20Multi(_,_,_))

  test "lambdas":
    check:
      plus20(arg0) == pipe(arg0,
        proc (x: int): int = x + 20
      )

      plus20(arg0) == pipe(arg0, (
        proc (x: int): int = x + 20
      ))

    # pipeline with 1 lambda
    let ret1 = pipe arg0:
      ( proc (x: int): int = x + 20 )

    check plus20(arg0) == ret1

    # pipeline with multiple lambdas, not correlatives
    let ret2 = pipe arg0:
      ( proc (x: int): int = x + 30 )
      plus20
      ( proc (x: int): int = x + 30 )

    check (arg0 + 80) == ret2

    # pipeline with multiple lambdas, correlatives
    let ret3 = pipe arg0:
      ( proc (x: int): int = x + 30 )
      ( proc (x: int): int = x + 30 )
      plus20

    check (arg0 + 80) == ret3


  test "placeholder special":

    test "placeholder indexing":
      check:
        plus20(A0[0]) == pipe(A0, plus20(_[0]))
        plus20(A0[^1]) == pipe(A0, plus20(_[^1]))

    test "placeholder slicing":

      let ret1 = pipe A0:
        power10Sum(_[0..2])

      check:
        power10Sum(A0[0..2]) == pipe(A0, power10Sum(_[0..2]))
        power10Sum(A0[0..^1]) == pipe(A0, power10Sum(_[0..^1]))
        power10Sum(A0[0..2]) == ret1

    test "placeholder calling":
      let ret1 = pipe mul3:
        plus20(_(arg0))
        plus30

      check:
        mul3(plus20(arg0)) == pipe(plus20, mul3(_(arg0)))
        mul3(plus20(arg0)) == pipe(plus20, identityproc, mul3(_(arg0)))
        plus30(plus20(mul3(arg0))) == pipe(mul3, plus20(_(arg0)), plus30)
        plus30(plus20(mul3(arg0))) == ret1


suite "std/sugar integration":
  let arg0 = 10

  test "|> with arrow syntax":
    # IMPORTANTE: Dentro de un 'test' (que es un proc), las flechas
    # deben tener tipos explícitos: (x: int) => ...
    # De lo contrario, Nim intenta crear un proc genérico anidado, lo cual es ilegal.
    check:
      (arg0 |> ((x: int) => x + 20)) == 30
      (arg0 |> ((x: int) => x * 2)) == 20

      # Encadenamiento
      (arg0 |> ((x: int) => x + 5) |> ((y: int) => y * 2)) == 30

  test "pipe macro with arrow syntax":
    # Mismo caso aquí, necesitamos especificar los tipos de entrada
    let val1 = pipe arg0:
      (x: int) => x + 5
      (x: int) => x * 2

    check val1 == 30

    # Inline pipe
    # Nota: Aquí usamos paréntesis extra alrededor de la definición de la flecha
    # para asegurar que el parser no se confunda con las comas del pipe().
    check pipe(arg0, ((x: int) => x + 5), ((x: int) => x * 2)) == 30


suite "Unpacking with _[index]":
  test "Tuple unpacking":
    let coords = (10, 5)

    # Resta: 10 - 5
    check (coords |> minus(_[0], _[1])) == 5

    # Inverso: 5 - 10
    check (coords |> minus(_[1], _[0])) == -5

    # Operaciones mixtas
    check (coords |> divInt(_[0], 2)) == 5

  test "Seq/Array unpacking":
    let list = @[10, 20, 30]
    let arr = [1, 2, 3]

    # Arrays y secuencias funcionan igual
    check (list |> minus(_[1], _[0])) == 10 # 20 - 10
    check (arr |> formatCoords(_[0], _[1], _[2])) == "1:2:3"

  test "Slicing and Negative Indices":
    let list = @[1, 2, 3, 4]

    # Obtener el último elemento
    check (list |> _[^1]) == 4

    # Obtener un rango (devuelve seq)
    check (list |> _[0..1]) == @[1, 2]

  test "Pipeline integration":
    # (10, 2) -> minus -> 8 -> *2 -> 16
    check ((10, 2) |> minus(_[0], _[1]) |> ((x: int) => x * 2)) == 16

  test "Pipe macro unpacking":
    let val = pipe (100, 20):
      minus(_[0], _[1])  # 100 - 20 = 80
      divInt(_, 2)       # 80 div 2 = 40

    check val == 40


suite "Recursive Placeholder":
  test "Nested calls":
    let n = "123"
    # El "_" está dentro de parseInt, que está dentro de float()
    # Equivale a: float(parseInt("123"))
    check (n |> float(parseInt(_))) == 123.0

  test "Deeply nested":
    proc wrap(s: string): string = "[" & s & "]"

    # Equivale a: wrap(wrap(wrap("hola")))
    check ("hola" |> wrap(wrap(wrap(_)))) == "[[[hola]]]"

  test "Complex expressions with _[index]":
    let data = @["a", "b", "c"]
    # Equivale a: (data[1]).toUpperAscii()
    check (data |> (_[1]).toUpperAscii()) == "B"

  test "Multiple placeholders in different branches":
    proc joinThree(a, b, c: string): string = a & b & c

    # Equivale a: joinThree("x".toUpper, "x", "x".toUpper)
    check ("x" |> joinThree(_.toUpperAscii, _, _.toUpperAscii)) == "XxX"


suite "Tap Operator |!":
  test "Basic tap with echo (side effect)":
    var sideEffectValue = 0
    proc saveValue(x: int) = sideEffectValue = x

    let result = 10 |> plus20 |! saveValue |> plus30

    # El resultado final debe ser 10 + 20 + 30 = 60
    check result == 60
    # El efecto secundario debe haber capturado el 30 (10 + 20)
    check sideEffectValue == 30

  test "Tap with placeholders":
    var logMsg = ""
    proc logger(msg: string) = logMsg = msg

    let val = "naranja" |! logger("Log: " & _) |> toUpperAscii()

    check val == "NARANJA"
    check logMsg == "Log: naranja"

  test "Tap with placeholders inline proc":
    var logMsg = ""

    let val = "naranja" |! ((proc (msg: string) = logMsg = msg)("Log: " & _)) |> toUpperAscii()

    check val == "NARANJA"
    check logMsg == "Log: naranja"

  test "Tap with placeholders inline sugar":
    var logMsg = ""

    let val = "naranja" |!
      ((msg: string) => (logMsg = "Log: " & msg)) |>
      toUpperAscii()

    check val == "NARANJA"
    check logMsg == "Log: naranja"

  test "Tap doesn't execute argument twice":
    var counter = 0
    proc getVal(): int =
      counter += 1
      return 10

    # Si evaluáramos 'arg' dos veces, counter sería 2
    let res = getVal() |! plus20 |> plus30

    check res == 40
    check counter == 1

  test "Multi-line pipe with Tap":
    var loggerCalledWith = 0

    let val = 10 |>
      plus20 |!
      (proc (x: int) = loggerCalledWith = x) |>
      plus30

    check val == 60
    check loggerCalledWith == 30

  test "Multi-line sudar pipe with Tap":
    var loggerCalledWith = 0

    let val = 10 |>
      plus20 |!
      {(x: int) => (loggerCalledWith = x)} |>
      plus30

    check val == 60
    check loggerCalledWith == 30
