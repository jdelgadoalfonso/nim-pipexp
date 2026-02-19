import
  std/macros

const PLACEHOLDER = "_"

proc transformRecursive(n: NimNode, arg: NimNode, found: var bool): NimNode =
  ## Recorre el árbol buscando "_" o expresiones con "_"
  
  # 1. Identificador "_"
  if n.kind == nnkIdent and n.eqIdent(PLACEHOLDER):
    found = true
    return arg

  # 2. Expresiones compuestas (_[0], _.name, _(arg))
  if n.kind in {nnkBracketExpr, nnkCall, nnkDotExpr} and n.len > 0 and n[0].eqIdent(PLACEHOLDER):
    found = true
    result = copyNimTree(n)
    result[0] = arg
    return result

  # 3. No entrar en Lambdas para evitar conflictos de scope
  if n.kind == nnkLambda:
    return n

  # 4. Recursión en hijos
  result = copyNimNode(n)
  for child in n:
    result.add transformRecursive(child, arg, found)

proc isSugarArrow(n: NimNode): bool =
  n.kind == nnkInfix and n[0].eqIdent("=>")

proc processPipe(arg, fn: NimNode): NimNode =
  # Primero intentamos transformación recursiva para casi cualquier estructura
  if fn.kind in {nnkCall, nnkCommand, nnkBracketExpr, nnkDotExpr, nnkInfix, nnkPrefix, nnkPar, nnkCurly}:
    var found = false
    let transformed = transformRecursive(fn, arg, found)
    if found: return transformed

  # Si no se encontró un placeholder, aplicamos lógica por tipo de nodo
  case fn.kind:
  of nnkIdent, nnkLambda:
    # arg |> f  => f(arg)
    result = newCall(fn, arg)

  of nnkCall, nnkCommand:
    # arg |> f(1, 2) => f(arg, 1, 2)
    result = newNimNode(nnkCall).add(fn[0])
    result.add arg
    for i in 1 ..< fn.len:
      result.add fn[i]

  of nnkPrefix:
    # CASO CRÍTICO: arg |> +20 => arg + 20
    # fn[0] es el operador, fn[1] es el valor
    result = newNimNode(nnkInfix).add(fn[0], arg, fn[1])

  of nnkInfix:
    if fn.isSugarArrow:
      result = newCall(fn, arg)
    else:
      # arg |> + 1 => arg + 1
      result = copyNimTree(fn)
      result.insert(1, arg)

  of nnkPar, nnkCurly:
    # Manejo de (proc...) o (x => x+1)
    if fn.len > 0 and (fn[0].kind == nnkLambda or fn[0].isSugarArrow):
      result = newCall(fn[0], arg)
    else:
      # Si es algo como (f), lo tratamos como llamada
      result = newCall(fn, arg)

  of nnkStmtList, nnkStmtListExpr:
    result = arg
    for stmt in fn:
      result = processPipe(result, stmt)

  else:
    # Fallback para cualquier otro caso
    result = newCall(fn, arg)

macro `|>`*(arg, fn: untyped): untyped =
  result = processPipe(arg, fn)

macro pipe*(arg: untyped, fns: varargs[untyped]): untyped =
  result = arg
  for fn in fns:
    result = processPipe(result, fn)