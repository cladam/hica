---
layout: default
title: Rethinking Design Patterns in hica
---

# Rethinking Design Patterns in hica

In August 2026, Nicolas Duminil published [*Rethinking Java Design Patterns: From OOP to FP*](https://dzone.com/articles/rethinking-java-design-patterns) on DZone.
Walking through five of the classic *Gang of Four* patterns: **Factory**, **Visitor**, **Builder**, **Decorator** and **Strategy**, he shows how each one shrinks when you shift a Java codebase from an object-oriented style to a functional one. 
Interfaces collapse into `Function<A, B>`. Wrapper classes collapse into `UnaryOperator<T>`. Fluent builders collapse into `andThen` chains of copy operations.

The article's punchline, borrowed from a story about Richard Feynman, is *"turtles all the way down"*: once you commit to the functional style,
you keep composing functions all the way to the bottom.

The article is a Java story. In hica, the context is different: there is no OOP baseline to refactor away. 
Features that modern Java must explicitly adopt (sealed types, first-class functions, exhaustive pattern matching, immutable records, and closures) are language defaults in hica.
So several of the five patterns don't *shrink* here; they vanish.

This article evaluates the same five patterns using Duminil's `Product` domain (Book / Electronic / Fashion).
The full, runnable code lives in [`examples/design_patterns.hc`](https://github.com/cladam/hica/blob/main/examples/design_patterns.hc)
and every snippet you see below is verified by a `hica test` block.

## A shared domain

```hica
type Product {
  Book(name: string, description: string, price: float),
  Electronic(name: string, description: string, price: float),
  Fashion(name: string, description: string, price: float)
}
```

This is all that's needed: one `type` declaration, three variants, all immutable. 
This is a *sealed* algebraic data type. There is no `Product` class, no `accept()` method, no interface hierarchy. 
It already tells the compiler that a `Product` is *exactly one of* these three shapes; a constraint enforced by the compiler across all examples below.

Three tiny accessors keep the pattern-matching noise out of every subsequent example:

```hica
fun product_price(p: Product) : float => match p {
  Book(_, _, pr)       => pr,
  Electronic(_, _, pr) => pr,
  Fashion(_, _, pr)    => pr
}
```

Now let's tour the patterns.

## 1. Factory: the pattern that was never there

Duminil's article opens with a classic Java Factory: a `ProductFactory` class using a `switch` statement over a `ProductType` enum. 
Adding a new product variant requires updating both the enum and the factory class.
Java's FP escape hatch is elegant but still visible: attach a constructor reference to each `enum` constant so that adding a new type
automatically requires a matching factory function.

In hica, the same idea shows up much earlier, before you even get to "how do I construct one of these?". 
The variants of a sealed `type` *are* the factory:

```hica
let book  = Book("Book1", "A book", 20.50)
let phone = Electronic("Phone1", "A phone", 499.00)
let shirt = Fashion("Shirt1", "A shirt", 39.00)
```

`Book`, `Electronic` and `Fashion` are ordinary functions. 
You can pass them around, store them in a variable, wrap them in a lambda:

```hica
let make_a_book = (n, d, pr) => Book(n, d, pr)
let book2 = make_a_book("Book2", "Another book", 15.00)
```

There is no `ProductFactory` class to update when you add a new variant.
Add a new variant to `type Product` and every downstream `match` becomes a compile error until you handle it; which is exactly the safety net
the Java FP refactor is trying to reintroduce. hica gives you that safety net by default, without a pattern.

**What disappeared:** The factory class, the parallel enum, constructor references, and the associated boilerplate.

## 2. Visitor: the pattern *is* the language

The Visitor pattern demonstrates the largest structural shift when moving from OOP to FP.
In classical Java it requires *double dispatch*: every `Product` grows an `accept(visitor)` method, and every visitor declares a `visit` overload per concrete product type. 
Adding a new operation is cheap (one new visitor class), but adding a new *type* is expensive (every visitor must grow a new `visit` overload).

Modern Java lets you `seal` the hierarchy and use exhaustive `switch` pattern-matching. The `accept` method disappears; the visitor becomes an ordinary `Function<Product, R>`. 
This is a huge simplification, and Duminil rightly celebrates it.

In hica, this structure is native rather than refactored.
A visitor is just a `fun`:

```hica
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
```

Each operation is a top-level function. They can live in different files, in different modules; the `Product` type knows nothing about them. 
If you add a fourth variant to `Product`, the compiler will point at every one of these `match`es and tell you which arm you forgot; because the type is sealed and exhaustiveness is checked.

There is no visitor class. There is no `accept` method. There is no double dispatch. 
What Java earned back through `sealed` + `switch` in 2021, hica has as its default idiom.

**What disappeared:** The entire pattern hierarchy. Concepts like `accept` methods and double dispatch do not exist in the hica implementation.

## 3. Builder: composition, without the accumulator

The Builder pattern addresses the telescoping constructor problem – handling objects with required and optional fields without exponential constructor overloads.

Duminil's Java OOP version is the classic mutable accumulator: an `OrderBuilder` you call `.addItem(...)`, `.coupon(...)`, `.giftWrap()` on, 
and finally `.build()` to freeze into an immutable `Order`. The Java FP version keeps the immutable target but replaces the accumulator
with `UnaryOperator<Order>` values: pure functions from `Order` to `Order`, glued together with `andThen`.

hica's Builder sits between the two: no mutable accumulator (because `struct` is immutable), *and* no `UnaryOperator<Order>` wrapper needed
(because our pipe operator does the same job with plain multi-arg functions):

```hica
struct Order {
  customer: string,
  currency: string,
  items: list<Product>,
  coupon_code: maybe<string>,
  gift_wrap: bool,
  note: maybe<string>
}

fun empty_order(customer: string, currency: string) => Order { ... }

fun add_item(o: Order, p: Product)         => Order { ..., items: [p] + o.items }
fun set_coupon(o: Order, code: string)     => Order { ..., coupon_code: Some(code) }
fun mark_as_gift_wrap(o: Order)            => Order { ..., gift_wrap: true }
fun with_note(o: Order, text: string)      => Order { ..., note: Some(text) }
```

Because each function accepts the accumulator as its first argument, updates pipe directly using `|>`:

```hica
let order = empty_order("Alice", "EUR")
  |> add_item(book)
  |> add_item(phone)
  |> set_coupon("SUMMER")
  |> mark_as_gift_wrap
  |> with_note("please deliver after 5pm")
```

This reads exactly like the Java fluent API. But there is no builder object at all: no mutation, no `.build()`, 
no separation between "under construction" and "finished". Every intermediate step is already a first-class, immutable `Order`. 
If you want to keep one and reuse it (like building a second order that starts from the first one's line items) you just... bind it to a `let` and pipe it into more steps.

The same shape shows up all over the hica standard library (`std/cli`, `std/log`, HML, etc.), because it's simply how you compose transformations over immutable values in hica.

**What survived:** the *idea* of composing a value step by step. What disappeared: the mutable builder, the `.build()` boundary, 
the `UnaryOperator<Order>` wrapping, and the need to give any of this a special name.

## 4. Decorator: stacking functions instead of objects

The Decorator pattern is Java's answer to a specific kind of combinatorial explosion: instead of writing `DiscountedTaxedGiftWrappedProduct`, 
you stack independent decorator objects at runtime. In classical Java that means an abstract `ProductDecorator` class, one concrete wrapper class per behaviour, 
and a lot of delegation boilerplate. Java FP shrinks each decorator to a `UnaryOperator<Product>`; they compose with `andThen`.

In hica, a decorator is a `Product -> Product` function. That's the whole story:

```hica
fun rebuild(p: Product, new_desc: string, new_price: float) : Product => match p {
  Book(n, _, _)       => Book(n, new_desc, new_price),
  Electronic(n, _, _) => Electronic(n, new_desc, new_price),
  Fashion(n, _, _)    => Fashion(n, new_desc, new_price)
}

fun discounted(p: Product)    : Product =>
  rebuild(p, product_desc(p) + " (discounted)", product_price(p) * 0.90)

fun taxed(p: Product)         : Product =>
  rebuild(p, product_desc(p) + " (VAT incl.)", product_price(p) * 1.20)

fun gift_wrapped(p: Product)  : Product =>
  rebuild(p, product_desc(p) + " (gift-wrapped)", product_price(p) + 5.00)
```

Function composition replaces nested object instantiation:

```hica
let wrapped = book |> discounted |> taxed |> gift_wrapped
//   100.00  --discounted--> 90.00 --taxed--> 108.00 --gift_wrapped--> 113.00
assert(product_price(wrapped) == 113.00)
```

Notice that where Java writes `new GiftWrapped(new Taxed(new Discounted(book)))` (which you have to read inside-out), hica's `|>` reads exactly in stacking order, top to bottom.

**Note on implementation**: Duminil's Java version requires a `BaseProduct` adapter because the domain type is sealed. In hica, functions operate directly on the sealed type without adapters.

**Performance**: While hica structs are immutable, they use Koka's Perceus reference counting. When a value's reference count is one (as in a single pipeline), field updates execute in-place compiled down to mutation efficiency.

**What survived:** the *composition*; Decorator names something real, and the name still fits. 
What disappeared: the wrapper classes, the abstract decorator, the delegation boilerplate, and the adapter.

## 5. Strategy: the interface *was* the function

A single-method, stateless interface like `ShippingStrategy` is functionally identical to a function type.
In Java that observation lets him delete the interface and replace it with `Function<Product, BigDecimal>`.

In hica we never wrote the interface. Strategies are just functions from `Product` to `float`:

```hica
fun standard_shipping(p: Product) : float => 4.99

fun express_shipping(p: Product) : float =>
  9.99 + (product_price(p) * 0.02)
```

The article's parameterised `FreeOverShipping` class (the one that holds a threshold and a fallback strategy in instance fields) becomes a *closure*. 
Higher-order functions capture parameters without ceremony:

```hica
fun free_over(threshold: float, otherwise: (Product) -> float) : (Product) -> float =>
  (p) => if product_price(p) >= threshold { 0.0 } else { otherwise(p) }
```

`free_over(50.00, standard_shipping)` is now a fully-configured strategy value, ready to be called or passed around. 
No `new FreeOverShipping(...)`; no fields; no constructor.

Combining strategies is what really shows the payoff. The article mentions that "pick the cheapest of these options" would need yet another
class on the OOP side. In hica it's a one-liner:

```hica
fun cheapest(a: (Product) -> float, b: (Product) -> float) : (Product) -> float =>
  (p) => min_float(a(p), b(p))
```

And Duminil's `ShippingCalculator` context class: the object whose entire reason to exist was to hold a strategy field so `total()` could delegate to it, is just another higher-order function:

```hica
fun total_with(strategy: (Product) -> float, p: Product) : float =>
  product_price(p) + strategy(p)
```

Which you call as `total_with(express_shipping, book)`. No setStrategy. No context object. No dependency injection. Just pass the function you want.

**What disappeared:** The interface, concrete strategy classes, and context wrappers; all replaced by first-class functions and closures.

## The bigger picture

Duminil's analysis demonstrates how modern Java adopts functional paradigms. Where Java has incrementally introduced sealed types, pattern matching, and lambdas, hica includes them as core primitives:

* **Factory:** Replaced by algebraic type constructors.
* **Visitor:** Replaced by exhaustive pattern matching over sealed types.
* **Builder:** Replaced by standard functions composed via the pipe operator (`|>`).
* **Decorator:** Replaced by direct `T -> T` function composition.
* **Strategy:** Replaced by first-class functions and higher-order parameters.

Rather than adapting object-oriented patterns to functional idioms, hica relies on immutable data, functions, and composition directly.

## Running the code

Every example above is verified by a test in the same file. 
Try it yourself:

```bash
hica test examples/design_patterns.hc
```

You should see:

```
running 5 test(s)...

  ✓ Factory — constructors are already values
  ✓ Visitor — sealed type + exhaustive match
  ✓ Builder — steps are ordinary functions composed with pipes
  ✓ Decorator — Product-to-Product functions stack with pipes
  ✓ Strategy — algorithms are function values, context is a HOF

5 test(s) passed
```

## Further reading

- [Rethinking Java Design Patterns: From OOP to FP](https://dzone.com/articles/rethinking-java-design-patterns): Nicolas Duminil's original article. Recommended if you want to see the parallel Java code in detail.
- [From Mutable Properties to Pure Lenses](/docs/lenses-vs-kotlin-properties): a companion piece translating Kotlin getters and setters into hica lenses.
- [`examples/design_patterns.hc`](https://github.com/cladam/hica/blob/main/examples/design_patterns.hc): the full, runnable source for every snippet in this article.
