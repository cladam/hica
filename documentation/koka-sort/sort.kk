// Merge sort for Koka
//
// Koka's standard library doesn't include a sort function.
// This is a pure, functional merge sort that works on any list type
// via a user-supplied comparison function.
//
// Contributed by the hica project — https://github.com/cladam/hica

// Merge two sorted lists using a comparison function.
// `cmp(a, b)` should return True when `a` should come before `b`.
fun merge-with( xs : list<a>, ys : list<a>, cmp : (a, a) -> bool ) : div list<a>
  match xs
    Nil -> ys
    Cons(x, xr) -> match ys
      Nil -> xs
      Cons(y, yr) ->
        if cmp(x, y) then Cons(x, merge-with(xr, ys, cmp))
        else Cons(y, merge-with(xs, yr, cmp))

// Sort a list using merge sort with a comparison function.
// `cmp(a, b)` should return True when `a` should come before `b`.
// Use `<=` for ascending order, `>=` for descending.
fun sort-by( xs : list<a>, cmp : (a, a) -> bool ) : div list<a>
  match xs
    Nil -> Nil
    Cons(_, Nil) -> xs
    _ ->
      val mid = xs.length / 2
      merge-with(sort-by(xs.take(mid), cmp), sort-by(xs.drop(mid), cmp), cmp)

// Convenience: sort a list of ints in ascending order.
fun sort( xs : list<int> ) : div list<int>
  sort-by(xs, fn(a, b) a <= b)

fun main()
  // Sort integers
  val nums = [3, 1, 4, 1, 5, 9, 2, 6]
  println(nums.sort.show)
  // [1, 1, 2, 3, 4, 5, 6, 9]

  // Sort strings alphabetically
  val fruits = ["banana", "apple", "cherry", "date"]
  println(fruits.sort-by(fn(a, b) a <= b).show)
  // ["apple", "banana", "cherry", "date"]

  // Sort strings by length
  println(fruits.sort-by(fn(a : string, b : string) a.count < b.count).show)
  // ["date", "apple", "banana", "cherry"]

  // Sort descending
  println(nums.sort-by(fn(a, b) a >= b).show)
  // [9, 6, 5, 4, 3, 2, 1, 1]
