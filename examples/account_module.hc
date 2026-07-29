// examples/account_module.hc
// Module illustrating read-only access (public getter, private constructor/setter)

// The type name is public, but the constructor is private ('priv') to this module.
// Callers in other modules cannot write Account { ... } directly.
pub struct Account priv { id: int, balance: int }

// Smart constructor — the only way to create an Account from another module
pub fun make_account(id: int, initial_balance: int) : Account =>
  if initial_balance >= 0 {
    Account { id: id, balance: initial_balance }
  } else {
    Account { id: id, balance: 0 }
  }

// Public Getter: accessible everywhere
pub fun account_balance_get(a: Account) : int => a.balance

// Public action that returns a new Account with an updated balance,
// enforcing invariants. Only this module can construct the updated Account.
pub fun deposit(a: Account, amount: int) : Account =>
  if amount > 0 {
    Account { id: a.id, balance: a.balance + amount }
  } else {
    a
  }
