// Hica — closures
// Closures are anonymous functions that capture their environment.

fun main() {
  // A closure stored in a variable
  let double = (x) => x * 2;
  println(double(5));

  // Closures passed to higher-order functions
  let nums = [1, 2, 3, 4, 5];
  let squares = map(nums, (x) => x * x);
  println(squares);

  let evens = filter(nums, (x) => x % 2 == 0);
  println(evens);

  let total = fold(nums, 0, (acc, x) => acc + x);
  println(total);

  // Closures capture values from their scope
  let factor = 10;
  let scale = (x) => x * factor;
  println(scale(7));

  // Composing closures with pipe
  let result = 3 |> double |> scale;
  println(result)
}
