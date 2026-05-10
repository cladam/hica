// Hica — Expression evaluator (recursive enum)
// Classic algebraic data type example from CS3110

type Expr {
  Num(value: int),
  Add(left: Expr, right: Expr),
  Mul(left: Expr, right: Expr),
  Neg(operand: Expr)
}

fun eval(e: Expr) : int => match e {
  Num(n)    => n,
  Add(a, b) => eval(a) + eval(b),
  Mul(a, b) => eval(a) * eval(b),
  Neg(x)    => 0 - eval(x)
}

fun show_expr(e: Expr) : string => match e {
  Num(n)    => "{n}",
  Add(a, b) => "({show_expr(a)} + {show_expr(b)})",
  Mul(a, b) => "({show_expr(a)} * {show_expr(b)})",
  Neg(x)    => "-{show_expr(x)}"
}

fun main() {
  // (2 + 3) * -(4)
  let expr = Mul(
    Add(Num(2), Num(3)),
    Neg(Num(4))
  )

  println(show_expr(expr))
  println("= {eval(expr)}")

  // 1 + 2 + 3
  let sum3 = Add(Num(1), Add(Num(2), Num(3)))
  println(show_expr(sum3))
  println("= {eval(sum3)}")
}
