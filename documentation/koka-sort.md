
# Merge Sort for Koka

Koka's standard library doesn't include a sort function. This is a pure,
functional merge sort that works on any list type via a user-supplied
comparison function.

Standalone file: [`koka-sort/sort.kk`](koka-sort/sort.kk)

## Implementation

The sort is split into two functions:

- **`merge-with`** — merges two already-sorted lists using a comparator
- **`sort-by`** — recursive merge sort: split at midpoint, sort halves, merge

Both require the `div` effect because `take`/`drop` make the recursion
non-structurally decreasing.

```koka
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
```

## Usage

```koka
fun main()
  val nums = [3, 1, 4, 1, 5, 9, 2, 6]
  println(nums.sort.show)                   // [1,1,2,3,4,5,6,9]
  println(nums.sort-by(fn(a, b) a >= b).show)  // [9,6,5,4,3,2,1,1]

  val fruits = ["banana", "apple", "cherry", "date"]
  println(fruits.sort-by(fn(a, b) a <= b).show)  // ["apple","banana","cherry","date"]
  println(fruits.sort-by(fn(a : string, b : string) a.count < b.count).show)
  // ["date","apple","banana","cherry"]
```

## In hica

hica exposes `sort_by` as a prelude function. Example: [`../examples/sort.hc`](../examples/sort.hc)

```hica
fun main() {
  println(sort_by([3, 1, 4, 1, 5], (a, b) => a <= b))
  println(sort_by(["banana", "apple", "cherry"], (a, b) => a <= b))
}
```

No effect annotations needed, hica handles that in codegen.