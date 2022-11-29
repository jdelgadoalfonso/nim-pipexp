import unittest

import pipexp

proc plus20(arg0: int): int = arg0 + 20
proc plus30(arg0: int): int = arg0 + 30
proc plus20Multi(arg1, arg2, arg3: int): int = arg1 + arg2 + arg3 + 20

suite "|":
  test "builtin procs":
    let arg0 = 10
    assert arg0 + 20 == arg0 | +20

  test "1 argument procs":
    let arg0 = 10
    assert plus20(arg0) == arg0 | plus20
    assert plus20(arg0) == arg0 | plus20()
    assert plus20(arg0) == arg0 | plus20(_)

    test "pipelines":
      assert plus30(plus20(arg0)) == arg0 | plus20 | plus30
      assert plus20(plus30(arg0)) == arg0 | plus30 | plus20
      assert plus20(plus20(arg0)) == arg0 | plus20() | plus20
      assert plus20(plus20(arg0)) == arg0 | plus20 | plus20()
      assert plus20(plus20(arg0)) == arg0 | plus20() | plus20()
      assert plus20(plus20(arg0)) == arg0 | plus20(_) | plus20(_)

  test "multiple argument procs":
    let arg0 = 10
    assert plus20Multi(arg0,0,0) == arg0 | plus20Multi(0,0)
    assert plus20Multi(arg0,0,0) == arg0 | plus20Multi(_,0,0)
    assert plus20Multi(arg0,arg0,0) == arg0 | plus20Multi(_,_,0)
    assert plus20Multi(arg0,arg0,arg0) == arg0 | plus20Multi(_,_,_)

    test "pipelines":
      assert plus20Multi(plus20Multi(arg0,0,0),1,1) == arg0 | plus20Multi(0,0) | plus20Multi(1,1)
      assert plus20Multi(plus20Multi(arg0,0,0),1,1) == arg0 | plus20Multi(_,0,0) | plus20Multi(_,1,1)
      assert plus20Multi(plus20Multi(arg0,1,2),3,4) == arg0 | plus20Multi(1,2) | plus20Multi(3,4)
      assert plus20Multi(1,plus20Multi(arg0,0,0),1) == arg0 | plus20Multi(0,0) | plus20Multi(1,_,1)
      assert plus20Multi(1,1,plus20Multi(arg0,0,0)) == arg0 | plus20Multi(0,0) | plus20Multi(1,1,_)


suite "pipe":
  test "1 argument procs":
    let arg0 = 10
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
    let arg0 = 10
    assert plus20Multi(arg0,0,0) == pipe(arg0, plus20Multi(0,0))
    assert plus20Multi(arg0,0,0) == pipe(arg0, plus20Multi(_,0,0))
    assert plus20Multi(arg0,arg0,0) == pipe(arg0, plus20Multi(_,_,0))
    assert plus20Multi(arg0,arg0,arg0) == pipe(arg0, plus20Multi(_,_,_))


