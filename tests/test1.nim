import unittest

import pipexp

proc plus20(arg0: int): int = arg0 + 20
proc plus20Multi(arg1, arg2, arg3: int): int = arg1 + arg2 + arg3 + 20

suite "|":
  let arg0 = 10

  test "builtin procs":
    assert arg0 + 20 == arg0 | +20

  test "1 argument procs":
    assert plus20(arg0) == arg0 | plus20
    assert plus20(arg0) == arg0 | plus20()
    assert plus20(arg0) == arg0 | plus20(_)

  test "multiple argument procs":
    assert plus20Multi(arg0,0,0) == arg0 | plus20Multi(0,0)
    assert plus20Multi(arg0,0,0) == arg0 | plus20Multi(_,0,0)
    assert plus20Multi(arg0,arg0,0) == arg0 | plus20Multi(_,_,0)
    assert plus20Multi(arg0,arg0,arg0) == arg0 | plus20Multi(_,_,_)

  test "lambdas":
    assert plus20(arg0) == arg0 | {
      proc (x: int): int = x + 20
    }

    test "pipelines":
      # FIXME:
      # This test passes somehow, but it cannot be used in code:
      #   redefinition of ':anonymous'; previous declaration here: ...
      # Lambdas apparently are being redeclared with name :anonymous
      assert plus20(arg0 + 40) == arg0 | {
        proc (x: int): int = x + 40
      } | plus20


suite "pipe":
  let arg0 = 10

  test "1 argument procs":
    assert plus20(arg0) == pipe(arg0, plus20)
    assert plus20(arg0) == pipe(arg0, plus20())
    assert plus20(arg0) == pipe(arg0, plus20(_))

    let ret1 = pipe arg0:
      plus20
    let ret2 = pipe arg0:
      plus20()
    let ret3 = pipe arg0:
      plus20(_)

    assert plus20(arg0) == ret1
    assert plus20(arg0) == ret2
    assert plus20(arg0) == ret3


  test "multiple argument procs":
    assert plus20Multi(arg0,0,0) == pipe(arg0, plus20Multi(0,0))
    assert plus20Multi(arg0,0,0) == pipe(arg0, plus20Multi(_,0,0))
    assert plus20Multi(arg0,arg0,0) == pipe(arg0, plus20Multi(_,_,0))
    assert plus20Multi(arg0,arg0,arg0) == pipe(arg0, plus20Multi(_,_,_))


