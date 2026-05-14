


```koka
fun hc-merge-with( xs, ys, cmp )
  match xs
    Nil -> ys
    Cons(x, xr) -> match ys
      Nil -> xs
      Cons(y, yr) -> if cmp(x, y) then Cons(x, hc-merge-with(xr, ys, cmp)) else Cons(y, hc-merge-with(xs, yr, cmp))

fun hc-sort-by( xs, cmp )
  match xs
    Nil -> Nil
    Cons(_, Nil) -> xs
    _ ->
      val mid = xs.length / 2
      hc-merge-with(hc-sort-by(xs.take(mid), cmp), hc-sort-by(xs.drop(mid), cmp), cmp)

fun main()
  println(hc-sort-by([3, 1, 4, 1, 5], fn(a, b) a <= b))
  println(hc-sort-by(["banana", "apple", "cherry"], fn(a : string, b : string) a <= b))
```