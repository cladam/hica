---
layout: default
title: From Mutable Properties to Pure Lenses
---

# From Mutable Properties to Pure Lenses: Translating Kotlin Getters & Setters to hica

In object-oriented languages like **Kotlin**, state is usually *mutable* and tied directly to objects. Kotlin simplifies state management with **Properties**, which automatically generate getters and setters to encapsulate read/write operations under the hood.

In functional programming languages like **hica**, all data structures (`struct` and `type` declarations) are strictly **immutable**. We do not change fields in place. Instead, we use a concept called **Lenses** (Optics) to focus on, read, and "update" (fully reconstruct) fields cleanly.

This article explores how Kotlin's mutable getter/setter property model maps beautifully to functional, immutable Lenses in hica.

## The Paradigm Shift

| Paradigm | Kotlin (Object-Oriented) | hica (Functional) |
| :--- | :--- | :--- |
| **State Mutation** | Mutable in-place (`var name = "Claes"`) | Immutable. Returns a copy (`User { ... }`) |
| **Encapsulation** | Properties hide backing fields (`field`) | Lenses encapsulate getter/setter lambda pairs |
| **Deep Updates** | Done via mutable references (`a.b.c = v`) | Done by composing pure lenses together |

In hica, we represent a Lens simply as a tuple containing two pure functions:
1. **Getter:** `(S) -> A` (Given a structure `S`, read field `A`)
2. **Setter:** `(S, A) -> S` (Given structure `S` and a new value `A`, return a new structure `S` with the updated value)

```hica
// A hica Lens is a tuple of functions:
let (get, set) = (getter_fn, setter_fn)
```

## Side-by-Side Translations

Below are translations of the core patterns described in the Kotlin Getters and Setters documentation.

### 1. Default Getters and Setters

In Kotlin, defining a property automatically generates a backing field (`field`) with default getters and setters.

#### Kotlin
```kotlin
class Company {
    var name: String = "GeeksforGeeks"
}

fun main() {
    val company = Company()
    println(company.name) // Calls getter: "GeeksforGeeks"
    company.name = "Hica Devs" // Calls setter
}
```

#### hica
In hica, we define a pure `struct` and a lens pair of lambdas to represent the property access.
```hica
struct Company { name: string }

// hica Default Lens: (get, set)
let getter = (c) => c.name
let setter = (c, n) => Company { name: n }
let (company_name_get, company_name_set) = (getter, setter)

// Usage:
let c1 = Company { name: "GeeksforGeeks" }
println(company_name_get(c1)) // "GeeksforGeeks"

let c2 = company_name_set(c1, "Hica Devs") // Returns a new Company, c1 is unchanged!
```

### 2. Custom Getters (Computed Properties)

Kotlin allows custom getters to return derived or formatted values.

#### Kotlin
```kotlin
class Person {
    var firstName: String = "Claes"
    var lastName: String = "Adamsson"
    
    val fullName: String
        get() = "$firstName $lastName"
}
```

#### hica
In hica, we define a "virtual" getter that formats the name. For completeness, we can also write a custom setter that parses the full name back into its components:
```hica
struct Person { first_name: string, last_name: string }

// Virtual Custom Getter / Setter Lens
let getter = (p) => "{p.first_name} {p.last_name}"
let setter = (p, name) => match split(name, " ") {
  [] => Person { first_name: "", last_name: "" },
  [first] => Person { first_name: first, last_name: "" },
  [first, ..rest] => Person { first_name: first, last_name: join(rest, " ") }
}
let (person_full_name_get, person_full_name_set) = (getter, setter)

// Usage:
let p1 = Person { first_name: "Claes", last_name: "Adamsson" }
println(person_full_name_get(p1)) // "Claes Adamsson"

let p2 = person_full_name_set(p1, "Nina Johnsson")
// p2 is Person { first_name: "Nina", last_name: "Johnsson" }
```

### 3. Custom Setters with Validation and Constraints

Kotlin's custom setters are useful for validating inputs, normalizing inputs, or restricting values (like keeping age non-negative).

#### Kotlin
```kotlin
class User {
    var age: Int = 0
        set(value) {
            if (value >= 0) {
                field = value
            }
        }
}
```

#### hica
In hica, we can implement the exact same validation inside our lens setter. If the new value is invalid, the setter simply returns the original `User` unchanged.
```hica
struct User { username: string, age: int }

// Validating Setter Lens
let getter = (u) => u.age
let setter = (u, val) => if val >= 0 {
  User { username: u.username, age: val }
} else {
  u // Reject change, return original user state!
}
let (user_age_get, user_age_set) = (getter, setter)

// Usage:
let u1 = User { username: "cladam", age: 46 }

let u2 = user_age_set(u1, 25) // u2.age is 25
let u3 = user_age_set(u1, -5) // REJECTED! u3.age remains 46
```

### 4. Changing Setter Visibility (Private Setters)

In Kotlin, you can restrict who can modify a property by making its setter `private`. This keeps the property public for reading but limits modification to the class itself.

#### Kotlin
```kotlin
class Account(id: Int, initialBalance: Int) {
    val id = id
    var balance: Int = initialBalance
        private set // Read-only from the outside, writeable inside the class
        
    fun deposit(amount: Int) {
        if (amount > 0) balance += amount
    }
}
```

#### hica
In hica, we model private setters elegantly using **Private Constructors** (`pub struct ... priv`) and our module boundaries. 
By defining our type in a separate module (`account_module.hc`), we export the struct's type and a getter function, but **do not** export a direct setter or allow external modules to construct the struct directly. Instead, callers must use public action functions (like `deposit`) to get a updated struct state!

```hica
// account_module.hc — separate module file
// Type is public, but constructor is private ('priv') to this module
pub struct Account priv { id: int, balance: int }

// Smart constructor — the only way to construct an Account outside this module
pub fun make_account(id: int, initial_balance: int) : Account =>
  if initial_balance >= 0 { Account { id: id, balance: initial_balance } }
  else { Account { id: id, balance: 0 } }

// Public Getter: accessible everywhere
pub fun account_balance_get(a: Account) : int => a.balance

// Public Action: behaves like deposit(), returning the updated state
pub fun deposit(a: Account, amount: int) : Account =>
  if amount > 0 { Account { id: a.id, balance: a.balance + amount } }
  else { a }
```

When importing this module into our main application, callers can easily view the property value but are strictly forbidden from raw construction/direct field modifications:

```hica
import "account_module"

let acc = make_account(101, 100)
println(account_balance_get(acc)) // Reads balance: 100

// Safe: update via the public action
let acc2 = deposit(acc, 50) // Balance becomes 150

// COMPILE ERROR: other modules cannot write Account { ... } or manually mutate fields!
// let acc3 = Account { id: 101, balance: 99999 } 
```

## Nested Composition (The Real Power of Lenses)

In Kotlin, updating nested properties looks convenient but relies heavily on mutability:
```kotlin
user.address.street = "456 Elm St"
```
If `user` and `address` were immutable in Kotlin, you would have to write painful nested copies:
```kotlin
val newUser = user.copy(
    address = user.address.copy(
        street = "456 Elm St"
    )
)
```
With hica lenses, we can define a single **Lens Composition** operation once, and use it to update deeply nested fields cleanly:

```hica
// Compose two lenses (outer S -> A and inner A -> B) to make a lens (S -> B)
let (user_street_get, user_street_set) = (
  (u) => street_get(addr_get(u)),
  (u, s) => addr_set(u, street_set(addr_get(u), s))
)

// Usage is simple, flat, and completely pure:
let u2 = user_street_set(u1, "456 Elm St")
```

## Running the Code

hica includes verified tests for these exact patterns. You can view and run the fully verified implementations inside the workspace:

```bash
hica test examples/kotlin_getters_setters.hc
```

This will run the test suite and confirm that all default, computed, validating, and private getters and setters compile and pass successfully:
```
running 4 test(s)...

  ✓ Kotlin Default Getter and Setter translation
  ✓ Kotlin Custom Getter (Computed Property) translation
  ✓ Kotlin Custom Setter (with Validation) translation
  ✓ Kotlin Private Setter translation using modules

4 test(s) passed
```
