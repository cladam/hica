// Rethinking classic OOP design patterns in hica.
// Inspired by "Rethinking Java Design Patterns: From OOP to FP"
// by Nicolas Duminil (DZone, 2026).
//
// We reuse the article's Product domain (Book / Electronic / Fashion)
// and translate each of the five patterns into idiomatic hica.

// --- Shared domain ------------------------------------------------------

type Product {
  Book(name: string, description: string, price: float),
  Electronic(name: string, description: string, price: float),
  Fashion(name: string, description: string, price: float)
}

// Small accessors so we don't repeat the match everywhere.
fun product_name(p: Product) : string => match p {
  Book(n, _, _)       => n,
  Electronic(n, _, _) => n,
  Fashion(n, _, _)    => n
}

fun product_desc(p: Product) : string => match p {
  Book(_, d, _)       => d,
  Electronic(_, d, _) => d,
  Fashion(_, d, _)    => d
}

fun product_price(p: Product) : float => match p {
  Book(_, _, pr)       => pr,
  Electronic(_, _, pr) => pr,
  Fashion(_, _, pr)    => pr
}

// A tiny float helper — SKILL.md notes prelude `min` is int-only.
fun min_float(a: float, b: float) : float => if a <= b { a } else { b }

// --- 1. Factory --------------------------------------------------------
//
// Java OOP: a `ProductFactory` class with a `switch` on `ProductType`.
// Java FP:  attach a constructor reference to each enum constant.
// hica:     the type's variants ARE the factory. Each variant is already
//           a first-class constructor function.

test "Factory — constructors are already values" {
  // No factory class, no switch, no enum-with-constructor-reference.
  // The variants of `type Product` are the factory.
  let book = Book("Book1", "A book", 20.50)
  let phone = Electronic("Phone1", "A phone", 499.00)
  let shirt = Fashion("Shirt1", "A shirt", 39.00)

  assert(product_name(book) == "Book1")
  assert(product_price(phone) == 499.00)
  assert(product_desc(shirt) == "A shirt")

  // Java's "factory as a value" trick — pick a constructor at runtime —
  // is just a lambda in hica:
  let make_a_book = (n, d, pr) => Book(n, d, pr)
  let book2 = make_a_book("Book2", "Another book", 15.00)
  assert(product_name(book2) == "Book2")
}


// --- 2. Visitor --------------------------------------------------------
//
// Java OOP: every Product implements `accept(visitor)`, and each visitor
//           has one `visit()` per concrete type (double dispatch).
// Java FP:  seal the hierarchy, exhaustive `switch` pattern-matches
//           each record.
// hica:     just a `fun` with `match`. No accept, no visitor interface,
//           no double dispatch — exhaustiveness is checked by default.

fun vat(p: Product) : float => match p {
  Book(_, _, price)       => price * 0.055,   // reduced rate for books
  Electronic(_, _, price) => price * 0.20,
  Fashion(_, _, price)    => price * 0.20
}

fun ship_cost(p: Product) : float => match p {
  Book(_, _, _)           => 3.00,
  Electronic(_, _, price) => 10.00 + (price * 0.02),
  Fashion(_, _, _)        => 5.00
}

fun discount(p: Product) : float => match p {
  Book(_, _, price)       => price * 0.05,
  Electronic(_, _, price) => price * 0.10,
  Fashion(_, _, price)    => price * 0.15
}

test "Visitor — sealed type + exhaustive match" {
  let book = Book("Book1", "A book", 100.00)
  let phone = Electronic("Phone1", "A phone", 500.00)
  let shirt = Fashion("Shirt1", "A shirt", 40.00)

  // Adding a new operation is a new top-level `fun`.
  // No visitor class, no accept method on the Product variants.
  assert(vat(book) == 5.50)
  assert(vat(phone) == 100.00)
  assert(ship_cost(phone) == 20.00)
  assert(ship_cost(book) == 3.00)
  assert(discount(shirt) == 6.00)
}


// --- 3. Builder --------------------------------------------------------
//
// Java OOP: a mutable OrderBuilder accumulator + build().
// Java FP:  each step is a `UnaryOperator<Order>`, composed with andThen.
// hica:     each step is a plain function `(Order, ...) -> Order`.
//           `|>` puts the accumulator in first-arg position, so the
//           steps read exactly like the Java fluent API — but with no
//           mutable builder object involved. This is the same shape used
//           throughout the hica stdlib (see `std/cli`, `std/log`).

struct Order {
  customer: string,
  currency: string,
  items: list<Product>,
  coupon_code: maybe<string>,
  gift_wrap: bool,
  note: maybe<string>
}

fun empty_order(customer: string, currency: string) =>
  Order {
    customer: customer,
    currency: currency,
    items: [],
    coupon_code: None,
    gift_wrap: false,
    note: None
  }

fun add_item(o: Order, p: Product) =>
  Order {
    customer: o.customer,
    currency: o.currency,
    items: [p] + o.items,
    coupon_code: o.coupon_code,
    gift_wrap: o.gift_wrap,
    note: o.note
  }

fun set_coupon(o: Order, code: string) =>
  Order {
    customer: o.customer,
    currency: o.currency,
    items: o.items,
    coupon_code: Some(code),
    gift_wrap: o.gift_wrap,
    note: o.note
  }

fun mark_as_gift_wrap(o: Order) =>
  Order {
    customer: o.customer,
    currency: o.currency,
    items: o.items,
    coupon_code: o.coupon_code,
    gift_wrap: true,
    note: o.note
  }

fun with_note(o: Order, text: string) =>
  Order {
    customer: o.customer,
    currency: o.currency,
    items: o.items,
    coupon_code: o.coupon_code,
    gift_wrap: o.gift_wrap,
    note: Some(text)
  }

test "Builder — steps are ordinary functions composed with pipes" {
  let book = Book("Book1", "A book", 20.00)
  let phone = Electronic("Phone1", "A phone", 500.00)

  // `|>` is our `andThen`. No builder object, no `.build()`.
  let order = empty_order("Alice", "EUR")
    |> add_item(book)
    |> add_item(phone)
    |> set_coupon("SUMMER")
    |> mark_as_gift_wrap
    |> with_note("please deliver after 5pm")

  assert(order.customer == "Alice")
  assert(length(order.items) == 2)
  assert(order.coupon_code == Some("SUMMER"))
  assert(order.gift_wrap)
  assert(order.note == Some("please deliver after 5pm"))
}


// --- 4. Decorator ------------------------------------------------------
//
// Java OOP: an abstract `ProductDecorator` + a wrapper class per behaviour.
// Java FP:  each decorator is a `UnaryOperator<Product>`, composed via andThen.
// hica:     each decorator is a plain `Product -> Product` function.
//           Stack them with `|>` — Perceus RC means "rebuild the record"
//           is often an in-place update at runtime.

fun rebuild(p: Product, new_desc: string, new_price: float) : Product => match p {
  Book(n, _, _)       => Book(n, new_desc, new_price),
  Electronic(n, _, _) => Electronic(n, new_desc, new_price),
  Fashion(n, _, _)    => Fashion(n, new_desc, new_price)
}

fun discounted(p: Product) : Product =>
  rebuild(p, product_desc(p) + " (discounted)", product_price(p) * 0.90)

fun taxed(p: Product) : Product =>
  rebuild(p, product_desc(p) + " (VAT incl.)", product_price(p) * 1.20)

fun gift_wrapped(p: Product) : Product =>
  rebuild(p, product_desc(p) + " (gift-wrapped)", product_price(p) + 5.00)

test "Decorator — Product-to-Product functions stack with pipes" {
  let book = Book("Book1", "A book", 100.00)

  // Java's `new GiftWrapped(new Taxed(new Discounted(book)))` reads
  // inside-out. `|>` reads left-to-right: exactly the stacking order.
  let wrapped = book |> discounted |> taxed |> gift_wrapped
  //  100.00 --discounted--> 90.00 --taxed--> 108.00 --gift_wrapped--> 113.00
  assert(product_price(wrapped) == 113.00)

  // A decoration is just a function you can apply again:
  let half_off = book |> discounted |> discounted
  //  100.00 --> 90.00 --> 81.00
  assert(product_price(half_off) == 81.00)
}


// --- 5. Strategy -------------------------------------------------------
//
// Java OOP: a `ShippingStrategy` interface + one class per algorithm
//           + a `ShippingCalculator` context object that holds the strategy.
// Java FP:  each algorithm is a `Function<Product, BigDecimal>`; the
//           parameterised `FreeOverShipping` becomes a higher-order
//           function; the context becomes a higher-order function.
// hica:     the "interface" *was* a function type — `(Product) -> float`.
//           There is no interface to declare, just plain functions.

// The two constant algorithms are plain functions.
fun standard_shipping(p: Product) : float => 4.99

fun express_shipping(p: Product) : float =>
  9.99 + (product_price(p) * 0.02)

// A parameterised strategy is a higher-order function returning a strategy.
// Threshold and fallback are captured in the closure — no class needed.
fun free_over(threshold: float, otherwise: (Product) -> float) : (Product) -> float =>
  (p) => if product_price(p) >= threshold { 0.0 } else { otherwise(p) }

// Combinators over strategies — the "cheapest of two" is a one-liner.
fun cheapest(a: (Product) -> float, b: (Product) -> float) : (Product) -> float =>
  (p) => min_float(a(p), b(p))

// The Java `ShippingCalculator` context is just another higher-order function.
fun total_with(strategy: (Product) -> float, p: Product) : float =>
  product_price(p) + strategy(p)

test "Strategy — algorithms are function values, context is a HOF" {
  let book = Book("Book1", "A book", 100.00)

  assert(standard_shipping(book) == 4.99)
  assert(express_shipping(book) == 11.99)

  // Parameterised strategy — closure over threshold + fallback.
  let free_over_50 = free_over(50.00, standard_shipping)
  let free_over_150 = free_over(150.00, standard_shipping)
  assert(free_over_50(book) == 0.0)      // 100 >= 50, ships free
  assert(free_over_150(book) == 4.99)    // 100 <  150, falls back

  // Combinator: pick the cheaper of two strategies.
  let best = cheapest(standard_shipping, express_shipping)
  assert(best(book) == 4.99)

  // "Context": no ShippingCalculator class — total_with is just a HOF.
  assert(total_with(standard_shipping, book) == 104.99)
  assert(total_with(express_shipping, book) == 111.99)
}
