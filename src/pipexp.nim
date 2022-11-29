import
  std/macros


proc underscorePos(n: NimNode): int =
  for i in 1 ..< n.len:
    if n[i].eqIdent("_"): return i
  return 0


proc underscorePos2(n: NimNode): seq[int] =
  for i in 1 ..< n.len:
    if n[i].eqIdent("_"):
      result.add(i)


macro `|`*(arg, fn: untyped): untyped =
  case fn.kind:
  of nnkIdent:
    result = newCall(fn, arg)
  of nnkCall, nnkCommand:
    var u: seq[int] = underscorePos2(fn)
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
    result = newCall(fn, arg0)
  of nnkCall, nnkCommand:
    let
      u = underscorePos(fn)
      arg = arg0
    result = newNimNode(nnkCall)
      .add(fn[0])
    for i in 1..u-1: result.add fn[i]
    result.add(arg)
    for i in u+1..fn.len-1: result.add fn[i]
  of nnkStmtList, nnkStmtListExpr:
    result = arg0
    for stmt in fn.children:
      result = underscoredCall(stmt, result)
  else:
    result = newCall(fn, arg0)


macro pipe*(arg: untyped, fns: varargs[untyped]): untyped =
  result = arg
  for fn in fns:
    result = underscoredCall(fn, result)
