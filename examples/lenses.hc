// Exploring Lenses in Hica
// Since Hica does not have let-polymorphism for top-level functions across multiple call sites,
// we represent lenses directly as tuples of functions and destructure them to avoid
// tuple accessor overloading issues in Koka.

struct Address { street: string, city: string }
struct User { name: string, address: Address }

test "lens get and set" {
  // A lens is a tuple: (get, set)
  let (addr_get, addr_set) = (
    (u) => u.address,
    (u, a) => User { name: u.name, address: a }
  )

  let (street_get, street_set) = (
    (a) => a.street,
    (a, s) => Address { street: s, city: a.city }
  )

  // Lens composition:
  let (user_street_get, user_street_set) = (
    (u) => street_get(addr_get(u)),
    (u, s) => addr_set(u, street_set(addr_get(u), s))
  )

  let u1 = User { name: "Alice", address: Address { street: "123 Main St", city: "Wonderland" } }

  // View
  let current_street = user_street_get(u1)
  assert(current_street == "123 Main St")

  // Set
  let u2 = user_street_set(u1, "456 Elm St")
  assert(u2.address.street == "456 Elm St")
  assert(u2.name == "Alice")
  assert(u2.address.city == "Wonderland")

  // Over (modify)
  let over_street = (u, f) => {
    let old_val = user_street_get(u)
    user_street_set(u, f(old_val))
  }

  let u3 = over_street(u1, (s) => "{s} Apt 4B")
  assert(u3.address.street == "123 Main St Apt 4B")
}
