// hica — Bank Account Actor Example
//
// Demonstrates using the enhanced std/actor library (send/ask helpers)
// with a stateful bank account actor using first-class actor syntax.

import "std/actor"

type BankMsg {
  Deposit(amount: int),
  Withdraw(amount: int),
  GetBalance
}

actor BankAccount {
  var balance = 0

  receive(msg: BankMsg) => match msg {
    Deposit(amount) => {
      balance = balance + amount;
      println("  [Bank] Deposited {amount}. New Balance: {balance}")
    }
    Withdraw(amount) => {
      if balance >= amount {
        balance = balance - amount;
        println("  [Bank] Withdrew {amount}. New Balance: {balance}")
      } else {
        println("  [Bank] Withdrawal of {amount} REJECTED. Insufficient funds! Balance remains: {balance}")
      }
    }
    GetBalance => {
      // Dummy to return the state, query is processed via ask projection
      println("  [Bank] Querying balance...")
    }
  }
}

fun main() {
  // Start with an empty account
  var account = BankAccountState { balance: 0 }

  println("Opening Bank Account with Balance: {account.balance}")

  // Perform deposits using stdlib `send` (updates state)
  println("Depositing 100...")
  account = bankaccount_receive(account, Deposit(100))

  println("Depositing 50...")
  account = bankaccount_receive(account, Deposit(50))

  // Perform withdrawal using `send` (updates state)
  println("Withdrawing 70...")
  account = bankaccount_receive(account, Withdraw(70))

  // Query balance using stdlib `ask`
  println("Querying current balance via stdlib 'ask'...")
  let bal = ask(account, GetBalance, bankaccount_receive, (state) => state.balance)
  println("Current Balance is: {show(bal)}")

  // Try overdraft
  println("Attempting overdraft of 200...")
  account = bankaccount_receive(account, Withdraw(200))
}
