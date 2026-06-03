# Level 36. Pig Latin: A Secret Language

Have you ever spoken **Pig Latin**? It's a fun word game where you scramble
English words into a secret-sounding language. "Pig" becomes **igpay**. "Latin"
becomes **atinlay**. "Elephant" becomes **elephantyay**.

Let's build a Pig Latin translator in Hica!

## The Rules

There are three simple rules:

| Word starts with... | What to do | Example |
|---|---|---|
| A vowel (a, e, i, o, u) | Add `"yay"` at the end | `elephant` → `elephantyay` |
| One or more consonants | Move consonants to end + `"ay"` | `pig` → `igpay`, `string` → `ingstray` |
| No vowels at all | Just add `"ay"` | `gym` → `gymay` |

## Step 1: Is It a Vowel?

First we need a helper that checks if a single letter is a vowel:

```hica
fun is_vowel(c: string) : bool =>
  contains("aeiouAEIOU", c)

fun main() {
  println(is_vowel("a"))    // true
  println(is_vowel("b"))    // false
  println(is_vowel("E"))    // true
}
```

> We pass a one-character string and check if it appears inside the vowel list.

## Step 2: How Many Consonants at the Start?

Next, we count how many consonants are at the *beginning* of the word.
This uses **recursion** – a function calling itself!

```hica
fun consonant_prefix_len(chars: list<string>) : int =>
  match chars {
    [] => 0,
    [h, ..rest] =>
      if is_vowel(h) { 0 }
      else { 1 + consonant_prefix_len(rest) }
  }
```

Read it like this:
- Empty list? Zero consonants.
- First letter is a vowel? Stop: zero consonants at this point.
- Otherwise? Count this consonant, then check the rest.

For `"string"`, the letters are `["s","t","r","i","n","g"]`. It counts `s`, `t`, `r`, then hits `i` (a vowel) and stops. Result: **3**.

## Step 3: Translate One Word

Now the main rule – translate a single word:

```hica
fun pig_latin_word(word: string) : string {
  let n = str_length(word)
  if n == 0 { word }
  else if is_vowel(word[:1]) { word + "yay" }
  else {
    let idx = consonant_prefix_len(split(word, ""))
    if idx == n { word + "ay" }
    else { word[idx:] + word[:idx] + "ay" }
  }
}

fun main() {
  println(pig_latin_word("pig"))       // igpay
  println(pig_latin_word("latin"))     // atinlay
  println(pig_latin_word("string"))    // ingstray
  println(pig_latin_word("elephant"))  // elephantyay
  println(pig_latin_word("gym"))       // gymay
}
```

- `word[:1]`   … the first character
- `word[idx:]` – everything from index `idx` onwards
- `word[:idx]` – everything before index `idx`

So for `"string"` with `idx = 3`: `"ing"` + `"str"` + `"ay"` = `"ingstray"`

## Step 4: Translate a Whole Sentence

One word is fun, but a whole sentence is better. We split the sentence into
words, translate each one, then join them back together:

```hica
fun pig_latin(text: string) : string =>
  join(map(words(text), (w) => pig_latin_word(w)), " ")

fun main() {
  println(pig_latin("pig latin"))           // igpay atinlay
  println(pig_latin("elephant umbrella"))   // elephantyay umbrellayay
}
```

`words(text)` splits by spaces. `map(...)` applies `pig_latin_word` to every
word. `join(..., " ")` stitches them back with spaces.

## Step 5: The Full Program

Put it all together with an `input` prompt so anyone can use it:

```hica
fun is_vowel(c: string) : bool =>
  contains("aeiouåäöAEIOUÅÄÖ", c)

fun consonant_prefix_len(chars: list<string>) : int =>
  match chars {
    [] => 0,
    [h, ..rest] =>
      if is_vowel(h) { 0 }
      else { 1 + consonant_prefix_len(rest) }
  }

fun pig_latin_word(word: string) : string {
  let n = str_length(word)
  if n == 0 { word }
  else if is_vowel(word[:1]) { word + "yay" }
  else {
    let idx = consonant_prefix_len(split(word, ""))
    if idx == n { word + "ay" }
    else { word[idx:] + word[:idx] + "ay" }
  }
}

fun pig_latin(text: string) : string =>
  join(map(words(text), (w) => pig_latin_word(w)), " ")

fun main() {
  println("Pig Latin Translator")
  println("--------------------")
  let line = input("Enter your message: ")
  let msg = trim(line)
  if str_length(msg) == 0 {
    println("(empty message)")
  } else {
    println(pig_latin(msg))
  }
}
```

Run it:

```
$ hica run pig_latin.hc
Pig Latin Translator
--------------------
Enter your message: hello world
ellohay orldway
```

## Try It Yourself

**Challenge 1:** What does your own name look like in Pig Latin?

**Challenge 2:** Can you make it handle **uppercase** words? `"Hello"` → `"Ellohay"`.
Hint: use `to_upper` on the first letter of the result.

**Challenge 3:** Numbers and punctuation get scrambled too. Can you make the
translator **skip** words that are all digits? Hint: `all_digits(word)`.

**Challenge 4:** Translate a full nursery rhyme or song lyric!
