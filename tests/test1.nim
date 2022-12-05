import unittest

import pipexp

proc plus20(arg0: int): int = arg0 + 20
proc plus30(arg0: int): int = arg0 + 30
proc plus20Multi(arg1, arg2, arg3: int): int = arg1 + arg2 + arg3 + 20

suite "|":
  let arg0 = 10

  test "builtin procs":
    check arg0 + 20 == arg0 | +20

  test "1 argument procs":
    check:
      plus20(arg0) == arg0 | plus20
      plus20(arg0) == arg0 | plus20()
      plus20(arg0) == arg0 | plus20(_)

    test "pipelines":
      check:
        plus30(plus20(arg0)) == arg0 | plus20 | plus30
        plus20(plus30(arg0)) == arg0 | plus30 | plus20
        plus20(plus20(arg0)) == arg0 | plus20() | plus20
        plus20(plus20(arg0)) == arg0 | plus20 | plus20()
        plus20(plus20(arg0)) == arg0 | plus20() | plus20()
        plus20(plus20(arg0)) == arg0 | plus20(_) | plus20(_)

  test "multiple argument procs":
    check:
      plus20Multi(arg0,0,0) == arg0 | plus20Multi(0,0)
      plus20Multi(arg0,0,0) == arg0 | plus20Multi(_,0,0)
      plus20Multi(arg0,arg0,0) == arg0 | plus20Multi(_,_,0)
      plus20Multi(arg0,arg0,arg0) == arg0 | plus20Multi(_,_,_)

    test "pipelines":
      check:
       plus20Multi(plus20Multi(arg0,0,0),1,1) == arg0 | plus20Multi(0,0) | plus20Multi(1,1)
       plus20Multi(plus20Multi(arg0,0,0),1,1) == arg0 | plus20Multi(_,0,0) | plus20Multi(_,1,1)
       plus20Multi(plus20Multi(arg0,1,2),3,4) == arg0 | plus20Multi(1,2) | plus20Multi(3,4)
       plus20Multi(1,plus20Multi(arg0,0,0),1) == arg0 | plus20Multi(0,0) | plus20Multi(1,_,1)
       plus20Multi(1,1,plus20Multi(arg0,0,0)) == arg0 | plus20Multi(0,0) | plus20Multi(1,1,_)

  test "lambdas":
    check plus20(arg0) == arg0 | {
      proc (x: int): int = x + 20
    }

    test "pipelines":
      check plus20(arg0 + 40) == arg0 | {
        proc (x: int): int = x + 40
      } | plus20


suite "pipe":
  let arg0 = 10

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

      plus20(arg0) == pipe(arg0, {
        proc (x: int): int = x + 20
      })

    let ret1 = pipe arg0:
      { proc (x: int): int = x + 20 }

    check plus20(arg0) == ret1
