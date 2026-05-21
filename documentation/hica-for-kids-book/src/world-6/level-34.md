# Level 34. Dates & Times: What Day Is It?

Hica has built-in functions for working with dates and times. They use
**strings** that look like this:

- A **date**: `"2026-05-15"` — year, month, day, separated by dashes
- A **time**: `"07:32:00"` — hours, minutes, seconds, separated by colons
- A **datetime**: `"2026-05-15T07:32:00"` — a date and time joined by `T`

Think of it like writing a date on a letter — you write it in a standard
format so everyone can read it.

### Is this date real?

```hica
fun main() {
  println(is_valid_date("2024-05-15"))   // true
  println(is_valid_date("2024-02-30"))   // false — February doesn't have 30 days!
  println(is_valid_date("2024-13-01"))   // false — there's no month 13
}
```

Hica knows about **leap years** too:

```hica
fun main() {
  println(is_valid_date("2024-02-29"))   // true  — 2024 is a leap year
  println(is_valid_date("2023-02-29"))   // false — 2023 is not
}
```

### What kind of date is this?

The `datetime_kind` function tells you what you're looking at:

```hica
fun main() {
  println(datetime_kind("2024-05-15"))                // "local-date"
  println(datetime_kind("07:32:00"))                   // "local-time"
  println(datetime_kind("2024-05-15T07:32:00"))        // "local-datetime"
  println(datetime_kind("2024-05-15T07:32:00Z"))       // "offset-datetime"
  println(datetime_kind("banana"))                     // "invalid"
}
```

### Breaking a date apart

You can split a date into its pieces — year, month, and day:

```hica
fun main() {
  match date_parts("2026-05-15") {
    Ok(d) => println("Year: {d.0}, Month: {d.1}, Day: {d.2}"),
    Err(e) => println(e)
  }
}
```

### Which comes first?

```hica
fun main() {
  println(is_before("2024-01-01", "2024-12-31"))   // true
  println(is_before("2024-12-31", "2024-01-01"))   // false
}
```

### What day of the week?

```hica
fun main() {
  match day_of_week("2026-05-15") {
    Ok(d) => println("Today is " + d),   // "Today is friday"
    Err(e) => println(e)
  }
}
```

**🎯 Challenge:** Write a program that asks the user for their birthday
(as `YYYY-MM-DD`) and tells them what day of the week they were born!

