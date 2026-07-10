// Domain primitives — type-safe wrappers for domain concepts
//
// A domain primitive is an opaque type that encodes ONE business concept.
// It validates at construction time so that any value you hold in your hands
// is guaranteed to be correct. You never have to re-validate inside your logic.
//
// This pattern applies to strings, integers, and any other primitive.
// It comes from Domain-Driven Design and prevents:
//   - Injection attacks (can't pass unvalidated strings through the type)
//   - Semantic confusion (can't add a price to a quantity by mistake)
//   - Negative values where only positive make sense
//   - Values that are out of range for the domain

// ── Quantity ────────────────────────────────────────────────────────────────
// A shopping cart quantity is an int — but not ANY int.
// It must be > 0 and has a practical upper bound.
// Without a domain primitive, nothing stops:  cart.add(item, -10)
// which might create a discount in the total.

opaque struct Quantity { n: int }

pub fun make_quantity(n: int) : maybe<Quantity> =>
  if n > 0 && n <= 1000 { Some(Quantity { n: n }) }
  else { None }

pub fun quantity_value(q: Quantity) : int => q.n

// ── Price ───────────────────────────────────────────────────────────────────
// A price in cents: non-negative integer.
// Separating Price and Quantity at the type level means
//   total_price(q: Quantity, p: Price) — not total_price(q: int, p: int)
// The compiler prevents passing them in the wrong order.

opaque struct Price { cents: int }

pub fun make_price(cents: int) : maybe<Price> =>
  if cents >= 0 { Some(Price { cents: cents }) }
  else { None }

pub fun price_cents(p: Price) : int => p.cents

pub fun total_price(q: Quantity, p: Price) : int =>
  quantity_value(q) * price_cents(p)

// ── RoomNumber ──────────────────────────────────────────────────────────────
// A hotel room number: 1-4 uppercase letters followed by 1-4 digits.
// The smart constructor encodes the exact rule once.
// Any function that receives a RoomNumber can trust it is structurally valid.

pub struct RoomNumber priv { code: string }

pub fun make_room(s: string) : maybe<RoomNumber> {
  // format: exactly 1 uppercase letter followed by 2-4 digits (e.g. A101, B4002)
  let n = str_length(s)
  if n < 3 || n > 5 { None }
  else {
    let head  = s[:1]
    let rest  = s[1:]
    if all_upper(head) && all_digits(rest) { Some(RoomNumber { code: s }) }
    else { None }
  }
}

pub fun room_code(r: RoomNumber) : string => r.code


fun main() {
  // ── Quantity ──────────────────────────────────────────────────────────
  let qty = make_quantity(4)
  let bad_qty = make_quantity(-10)   // attempt at the classic "negative discount" bug

  match qty {
    Some(q) => println("quantity: " + show(quantity_value(q))),
    None    => println("rejected")
  }
  match bad_qty {
    Some(_) => println("ERROR: accepted negative quantity"),
    None    => println("rejected negative quantity ✓")
  }

  // ── Price × Quantity → total ──────────────────────────────────────────
  match (make_quantity(3), make_price(499)) {
    (Some(q), Some(p)) => println("total: " + show(total_price(q, p)) + " cents"),
    _                  => println("invalid")
  }

  // Compiler prevents: total_price(price, quantity) — argument order swap
  // is caught at compile time because Price ≠ Quantity

  // ── RoomNumber ────────────────────────────────────────────────────────
  let room = make_room("A101")
  let bad  = make_room("javascript:alert(1)")   // injection attempt

  match room {
    Some(r) => println("room: " + room_code(r)),
    None    => println("rejected")
  }
  match bad {
    Some(_) => println("ERROR: accepted injection string"),
    None    => println("rejected injection attempt ✓")
  }

  // ── The key insight ───────────────────────────────────────────────────
  // Every function downstream that takes Quantity, Price, or RoomNumber
  // receives a value that is KNOWN VALID. There is no need to re-validate
  // deep inside the system — the type is the certificate.
}
