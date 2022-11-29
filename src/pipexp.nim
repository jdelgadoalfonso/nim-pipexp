import
  std/macros

proc underscorePos(n: NimNode): seq[int] =
  ## Get the index positions the placeholder arguments
  ## in the procedure call of `n`
  ## Empty seq if no placeholder was found
  for i in 1 ..< n.len:
    if n[i].eqIdent("_"):
      result.add(i)


macro `|`*(arg, fn: untyped): untyped =
  case fn.kind:
  of nnkIdent:
    # When proc is passed without parentheses: arg0 | fn
    result = newCall(fn, arg)
  of nnkCall, nnkCommand:
    # When proc is passed with parentheses: arg0 | fn(...)
    var u: seq[int] = underscorePos(fn)
    result = newNimNode(nnkCall)
      .add(fn[0])
    if fn.len == 1:
      result.add arg
    else:
      if u.len == 0:
        result.add arg
        for i in 1..fn.len-1:
          result.add fn[i]
      else:
        for i in 1..fn.len-1:
          if i in u:
            result.add arg
          else:
            result.add fn[i]
  else:
    result = fn
    result.insert(1, arg)


proc underscoredCall(fn, arg0: NimNode): NimNode =
  case fn.kind:
  of nnkIdent:
    # When proc is passed without parentheses: arg0 | fn
    result = newCall(fn, arg0)
  of nnkCall, nnkCommand:
    # When proc is passed with parentheses: arg0 | fn(...)
    let
      u = underscorePos(fn)
      arg = arg0
    result = newNimNode(nnkCall)
      .add(fn[0])
    if u.len == 0:
      result.add arg
      for i in 1..fn.len-1:
        result.add fn[i]
    else:
      for i in 1..fn.len-1:
        if i in u:
          result.add arg
        else:
          result.add fn[i]
  of nnkStmtList, nnkStmtListExpr:
    # When a block of procs is passed as a pipeline:
    # pipe arg0:
    #   fn0
    #   fn1
    result = arg0
    for stmt in fn.children:
      result = underscoredCall(stmt, result)
  else:
    result = newCall(fn, arg0)


macro pipe*(arg: untyped, fns: varargs[untyped]): untyped =
  result = arg
  for fn in fns:
    result = underscoredCall(fn, result)
