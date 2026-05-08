// Bitwise operations

fun main() {
  // bit_and — mask low nibble
  let flags = 255
  println(bit_and(flags, 15))        // 15

  // bit_or — set a bit
  println(bit_or(flags, 256))        // 511

  // bit_xor — toggle bits
  println(bit_xor(170, 255))         // 85

  // bit_not — complement
  println(bit_not(0))                // -1

  // bit_shl — shift left
  println(bit_shl(1, 8))             // 256

  // bit_shr — shift right
  println(bit_shr(256, 4))           // 16

  // UFCS style
  let masked = flags.bit_and(15).bit_shl(2)
  println(masked)                    // 60

  // Extract high nibble of a byte
  // Extract high nibble of a byte (0xAB = 171)
  let byte = 171
  let hi = byte.bit_shr(4).bit_and(15)
  let lo = byte.bit_and(15)
  println("hi={hi} lo={lo}")         // hi=10 lo=11
}
