// ============================================================
// Lesson 37: List Extras
// ============================================================
//
// Beyond map/filter/fold, hica gives you more list tools:
//
//   head(list)           - first element (returns maybe)
//   tail(list)           - everything after the first
//   last(list)           - last element (returns maybe)
//   flat_map(list, fn)   - map, then flatten the results
//   sort_by(list, cmp)   - sort using a comparison function
//   sum(list)            - add up all elements (list<int>)
//   product(list)        - multiply all elements (list<int>)
//   unique(list)         - remove duplicates (list<int>)
//   intersperse(list, x) - put x between every element
//   zip_with(a, b, fn)   - zip and transform in one step
//   scan(list, init, fn) - fold that keeps intermediates
//   chunks(list, n)      - split into groups of n
//
// ============================================================

fun main() {
  let nums = [3, 1, 4, 1, 5, 9, 2, 6]

  // head — first element, safe
  println(head(nums))           // Some(3)

  // tail — everything after the first
  println(tail(nums))           // [1, 4, 1, 5, 9, 2, 6]

  // last — last element, safe
  println(last(nums))           // Some(6)

  // flat_map — map then flatten
  let pairs = flat_map([1, 2, 3], (x) => [x, x * 10])
  println(pairs)                // [1, 10, 2, 20, 3, 30]

  // sort_by — sort with a comparison function
  let sorted = sort_by(nums, (a, b) => a <= b)
  println(sorted)               // [1, 1, 2, 3, 4, 5, 6, 9]

  // sort descending
  let desc = sort_by(nums, (a, b) => a >= b)
  println(desc)                 // [9, 6, 5, 4, 3, 2, 1, 1]

  // sum and product
  println(sum([1, 2, 3, 4, 5]))     // 15
  println(product([1, 2, 3, 4, 5])) // 120

  // unique — remove duplicates
  println(unique([1, 2, 3, 2, 1]))  // [1, 2, 3]

  // intersperse — insert a separator
  let spaced = intersperse([1, 2, 3], 0)
  println(spaced)               // [1, 0, 2, 0, 3]

  // zip_with — zip and transform
  let sums = zip_with([1, 2, 3], [10, 20, 30], (a, b) => a + b)
  println(sums)                 // [11, 22, 33]

  // scan — like fold but keeps all intermediate results
  let running = scan([1, 2, 3, 4], 0, (acc, x) => acc + x)
  println(running)              // [0, 1, 3, 6, 10]

  // chunks — split into groups
  println(chunks([1, 2, 3, 4, 5], 2))  // [[1, 2], [3, 4], [5]]
}
