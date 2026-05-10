// A simple module to demonstrate imports
// Only pub functions are visible to importers

pub fun hello(name: string) {
  println("hello, " + name + "!")
}

pub fun goodbye(name: string) {
  println("goodbye, " + name + "!")
}

fun secret() => println("you can't see me")
