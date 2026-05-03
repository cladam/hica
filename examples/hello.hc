// Hica — six ways to say hello
//
// 1. Shortest: arrow body (implicit return)
//    fun main() => "Hello, world!"
//
// 2. One-liner block (implicit return)
//    fun main() { "Hello, world!" }
//
// 3. Explicit println
//    fun main() { println("Hello, world!") }
//
// 4. Let binding + implicit return
//    fun main() {
//      let msg = "Hello, world!"
//      msg
//    }
//
// 5. Let binding + println
//    fun main() {
//      let msg = "Hello, world!"
//      println(msg)
//    }
//
// 6. Helper function
//    fun greet() => "Hello, world!"
//    fun main() { greet() }

fun main() => "Hello, world!"
