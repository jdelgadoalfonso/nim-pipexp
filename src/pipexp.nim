import
  std/macros

const PLACEHOLDER = "_"

proc placeholderPos(n: NimNode): seq[int] =
  ## Devuelve los índices de los argumentos que contienen el placeholder '_'
  for i in 1 ..< n.len:
    # Caso 1: El argumento es exactamente "_"
    if n[i].eqIdent(PLACEHOLDER):
      result.add(i)
    # Caso 2: El argumento es una expresión compleja que empieza por "_"
    # Ej: _[0], _[1], _(10), _.campo
    elif (n[i].kind in [nnkBracketExpr, nnkCall, nnkDotExpr]) and
         n[i][0].eqIdent(PLACEHOLDER):
      result.add(i)

template addArgsAndPlaceholders(phIndices: seq[int], arg, fn: NimNode): untyped =
  if phIndices.len == 0:
    # Si no hay placeholder explícito, añade 'arg' al principio
    result.add arg
    for i in 1..fn.len-1:
      result.add fn[i]
  else:
    # Si hay placeholders, sustitúyelos
    for i in 1..fn.len-1:
      if i in phIndices:
        if fn[i].eqIdent(PLACEHOLDER):
          # Sustitución directa: arg |> f(_, 1) -> f(arg, 1)
          result.add arg
        elif (fn[i].kind in [nnkBracketExpr, nnkCall, nnkDotExpr]) and
          fn[i][0].eqIdent(PLACEHOLDER):
          # Sustitución interna: 
          # arg |> f(_[0]) -> f(arg[0])
          # arg |> f(_.name) -> f(arg.name)
          fn[i][0] = arg
          result.add fn[i]
      else:
        result.add fn[i]

proc isSugarArrow(n: NimNode): bool =
  ## Detecta si es una flecha de std/sugar (=>)
  n.kind == nnkInfix and n[0].eqIdent("=>")

macro `|>`*(arg, fn: untyped): untyped =
  case fn.kind:
  of nnkIdent:
    # arg |> f
    result = newCall(fn, arg)

  of nnkCall, nnkCommand:
    # arg |> f(...)
    var u: seq[int] = placeholderPos(fn)
    result = newNimNode(nnkCall)
      .add(fn[0])
    if fn.len == 1:
      result.add arg
    else:
      addArgsAndPlaceholders(u, arg, fn)

  of nnkPar, nnkCurly:
    # arg |> (x => x+1)
    if fn[0].kind == nnkLambda or fn[0].isSugarArrow:
      result = newCall(fn[0], arg)
    else:
      raise newException(Exception, "expected Lambda or Arrow expression after '(' or '{'")
  
  of nnkInfix:
    # Soporte para sugar directo si el parser lo permite
    if fn.isSugarArrow:
      result = newCall(fn, arg)
    else:
      result = fn
      result.insert(1, arg)
      
  # Soporte directo para indexación: arg |> _[0]
  of nnkBracketExpr:
    if fn[0].eqIdent(PLACEHOLDER):
      fn[0] = arg
      result = fn
    else:
      # Fallback por si acaso
      result = newCall(fn, arg)

  else:
    result = fn
    result.insert(1, arg)


proc placeholderCall(fn, arg0: NimNode): NimNode =
  case fn.kind:
  of nnkIdent:
    # When proc is passed without parentheses: arg0 | fn
    result = newCall(fn, arg0)

  of nnkCall, nnkCommand:
    # When proc is passed with arguments: arg0 | fn(...)
    let
      u: seq[int] = placeholderPos(fn)
      arg: NimNode = arg0
    result = newNimNode(nnkCall)
      .add(fn[0])
    addArgsAndPlaceholders(u, arg, fn)

  of nnkPar, nnkCurly:
    if fn[0].kind == nnkLambda or fn[0].isSugarArrow:
      result = newCall(fn[0], arg0)
    else:
      raise newException(Exception, "expected Lambda or Arrow expression after '(' or '{'")

  of nnkInfix:
    if fn.isSugarArrow:
      result = newCall(fn, arg0)
    else:
      result = newCall(fn, arg0)

  # Soporte para pipe arg: _[0]
  of nnkBracketExpr:
    if fn[0].eqIdent(PLACEHOLDER):
      var newFn = fn
      newFn[0] = arg0
      result = newFn
    else:
       result = newCall(fn, arg0)

  of nnkStmtList, nnkStmtListExpr:
    # When a block of procs is passed as a pipeline:
    # pipe arg0:
    #   fn0
    #   fn1
    result = arg0
    for stmt in fn.children:
      result = placeholderCall(stmt, result)

  else:
    result = newCall(fn, arg0)


macro pipe*(arg: untyped, fns: varargs[untyped]): untyped =
  ## Pipeline macro.
  ## Passes the first argument through a pipeline of
  ## procedure calls from left to right
  ## It may also accept the calls as an indented statement list

  result = arg
  for fn in fns:
    result = placeholderCall(fn, result)
