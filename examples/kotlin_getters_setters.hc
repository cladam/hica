// Translation of Kotlin Getters & Setters to hica Lenses
// Side-by-side verification of how mutable OO state translates to pure functional immutability.

import "std/list"
import "account_module"

// --- Default Getter & Setter ---
struct Company { name: string }

// --- Custom Getter (Computed Property) ---
struct Person { first_name: string, last_name: string }

// --- Custom Setter (Validation / Logic) ---
struct User { username: string, age: int }

test "Kotlin Default Getter and Setter translation" {
  let c1 = Company { name: "GeeksforGeeks" }

  // hica Default Lens: (get, set)
  let getter = (c) => c.name
  let setter = (c, n) => Company { name: n }
  let (company_name_get, company_name_set) = (getter, setter)

  // Reading: get()
  assert(company_name_get(c1) == "GeeksforGeeks")

  // Writing: set() -> returns a brand new Company
  let c2 = company_name_set(c1, "Hica Devs")
  assert(company_name_get(c2) == "Hica Devs")
  assert(company_name_get(c1) == "GeeksforGeeks") // c1 is unchanged!
}

test "Kotlin Custom Getter (Computed Property) translation" {
  let p1 = Person { first_name: "Claes", last_name: "Adamsson" }

  // Virtual Custom Getter / Setter Lens
  let getter = (p) => "{p.first_name} {p.last_name}"
  let setter = (p, name) => match split(name, " ") {
    [] => Person { first_name: "", last_name: "" },
    [first] => Person { first_name: first, last_name: "" },
    [first, ..rest] => Person { first_name: first, last_name: join(rest, " ") }
  }
  let (person_full_name_get, person_full_name_set) = (getter, setter)

  // Custom getter: Reads derived value
  assert(person_full_name_get(p1) == "Claes Adamsson")

  // Custom setter: Sets derived value, splitting it back into components
  let p2 = person_full_name_set(p1, "Nina Johnsson")
  assert(p2.first_name == "Nina")
  assert(p2.last_name == "Johnsson")

  // Custom setter with more names:
  let p3 = person_full_name_set(p1, "Sven Ingvar Olsson")
  assert(p3.first_name == "Sven")
  assert(p3.last_name == "Ingvar Olsson")
}

test "Kotlin Custom Setter (with Validation) translation" {
  let u1 = User { username: "cladam", age: 46 }

  // Validating Setter Lens
  let getter = (u) => u.age
  let setter = (u, val) => if val >= 0 {
    User { username: u.username, age: val }
  } else {
    u // Reject change, return original user
  }
  let (user_age_get, user_age_set) = (getter, setter)

  // Valid change
  let u2 = user_age_set(u1, 25)
  assert(user_age_get(u2) == 25)

  // Invalid change (ignored/rejected)
  let u3 = user_age_set(u1, -5)
  assert(user_age_get(u3) == 46) // Retains original age!
}

test "Kotlin Private Setter translation using modules" {
  let acc = make_account(101, 100)

  // We can read balance using the public getter
  assert(account_balance_get(acc) == 100)

  // We can use the public deposit function (which uses the private setter inside the module)
  let acc2 = deposit(acc, 50)
  assert(account_balance_get(acc2) == 150)

  // Invalid deposit is ignored
  let acc3 = deposit(acc, -20)
  assert(account_balance_get(acc3) == 100)
}
