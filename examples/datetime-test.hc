// Test datetime prelude functions

import "std/datetime"

fun main() {
  println("datetime prelude tests")

  // --- is_valid_date ---
  assert(is_valid_date("2024-05-15") == true)
  assert(is_valid_date("2024-02-29") == true)   // leap year
  assert(is_valid_date("2023-02-29") == false)  // not a leap year
  assert(is_valid_date("2024-13-01") == false)  // month > 12
  assert(is_valid_date("2024-00-01") == false)  // month 0
  assert(is_valid_date("2024-01-32") == false)  // day > 31
  assert(is_valid_date("2024-04-31") == false)  // April has 30 days
  assert(is_valid_date("hello") == false)
  assert(is_valid_date("") == false)
  println("  is_valid_date: ok")

  // --- is_valid_time ---
  assert(is_valid_time("07:32:00") == true)
  assert(is_valid_time("23:59:59") == true)
  assert(is_valid_time("00:00:00") == true)
  assert(is_valid_time("07:32:00.123") == true)
  assert(is_valid_time("07:32:00.123456") == true)
  assert(is_valid_time("24:00:00") == false)
  assert(is_valid_time("12:60:00") == false)
  assert(is_valid_time("12:30:60") == false)
  assert(is_valid_time("hello") == false)
  // seconds-omitted forms
  assert(is_valid_time("07:32") == true)
  assert(is_valid_time("23:59") == true)
  assert(is_valid_time("00:00") == true)
  assert(is_valid_time("24:00") == false)
  assert(is_valid_time("12:60") == false)
  println("  is_valid_time: ok")

  // --- is_local_date ---
  assert(is_local_date("2024-05-15") == true)
  assert(is_local_date("not-a-date") == false)
  println("  is_local_date: ok")

  // --- is_local_time ---
  assert(is_local_time("07:32:00") == true)
  assert(is_local_time("07:32:00.999") == true)
  assert(is_local_time("not-time") == false)
  assert(is_local_time("07:32") == true)
  println("  is_local_time: ok")

  // --- is_local_datetime ---
  assert(is_local_datetime("2024-05-15T07:32:00") == true)
  assert(is_local_datetime("2024-05-15t07:32:00") == true)
  assert(is_local_datetime("2024-05-15 07:32:00") == true)
  assert(is_local_datetime("2024-05-15T07:32:00.123") == true)
  assert(is_local_datetime("2024-05-15T07:32") == true)
  assert(is_local_datetime("1979-05-27 07:32") == true)
  assert(is_local_datetime("hello") == false)
  println("  is_local_datetime: ok")

  // --- is_iso_datetime ---
  assert(is_iso_datetime("2024-05-15T07:32:00Z") == true)
  assert(is_iso_datetime("2024-05-15T07:32:00+02:00") == true)
  assert(is_iso_datetime("2024-05-15T07:32:00-05:30") == true)
  assert(is_iso_datetime("2024-05-15T07:32:00.123Z") == true)
  assert(is_iso_datetime("2024-05-15T07:32:00.123+02:00") == true)
  assert(is_iso_datetime("1979-05-27T07:32Z") == true)
  assert(is_iso_datetime("1979-05-27 07:32Z") == true)
  assert(is_iso_datetime("1979-05-27T07:32+02:00") == true)
  assert(is_iso_datetime("not-a-datetime") == false)
  println("  is_iso_datetime: ok")

  // --- date_parts ---
  match date_parts("2024-05-15") {
    Ok(parts) => {
      assert(parts.0 == 2024)
      assert(parts.1 == 5)
      assert(parts.2 == 15)
    },
    Err(_) => assert(false)
  }
  match date_parts("bad") {
    Ok(_) => assert(false),
    Err(_) => assert(true)
  }
  println("  date_parts: ok")

  // --- time_parts ---
  match time_parts("07:32:45") {
    Ok(parts) => {
      assert(parts.0 == 7)
      assert(parts.1 == 32)
      assert(parts.2 == 45)
    },
    Err(_) => assert(false)
  }
  match time_parts("07:32:45.123") {
    Ok(parts) => {
      assert(parts.0 == 7)
      assert(parts.1 == 32)
      assert(parts.2 == 45)
    },
    Err(_) => assert(false)
  }
  println("  time_parts: ok")

  // --- time_parts seconds-omitted ---
  match time_parts("07:32") {
    Ok(parts) => {
      assert(parts.0 == 7)
      assert(parts.1 == 32)
      assert(parts.2 == 0)
    },
    Err(_) => assert(false)
  }
  println("  time_parts (HH:MM): ok")

  // --- datetime_date ---
  match datetime_date("2024-05-15T07:32:00Z") {
    Ok(d) => assert(d == "2024-05-15"),
    Err(_) => assert(false)
  }
  println("  datetime_date: ok")

  // --- datetime_time ---
  match datetime_time("2024-05-15T07:32:00Z") {
    Ok(t) => assert(t == "07:32:00"),
    Err(_) => assert(false)
  }
  match datetime_time("2024-05-15T07:32:00.123+02:00") {
    Ok(t) => assert(t == "07:32:00.123"),
    Err(_) => assert(false)
  }
  println("  datetime_time: ok")

  // --- datetime_time seconds-omitted ---
  match datetime_time("1979-05-27T07:32Z") {
    Ok(t) => assert(t == "07:32"),
    Err(_) => assert(false)
  }
  match datetime_time("1979-05-27T07:32+02:00") {
    Ok(t) => assert(t == "07:32"),
    Err(_) => assert(false)
  }
  println("  datetime_time (HH:MM): ok")

  // --- datetime_offset ---
  match datetime_offset("2024-05-15T07:32:00Z") {
    Some(o) => assert(o == "Z"),
    None => assert(false)
  }
  match datetime_offset("2024-05-15T07:32:00+02:00") {
    Some(o) => assert(o == "+02:00"),
    None => assert(false)
  }
  match datetime_offset("2024-05-15T07:32:00") {
    Some(_) => assert(false),
    None => assert(true)
  }
  println("  datetime_offset: ok")

  // --- datetime_kind ---
  assert(datetime_kind("07:32:00") == "local-time")
  assert(datetime_kind("2024-05-15") == "local-date")
  assert(datetime_kind("2024-05-15T07:32:00") == "local-datetime")
  assert(datetime_kind("2024-05-15T07:32:00Z") == "offset-datetime")
  assert(datetime_kind("2024-05-15T07:32:00+02:00") == "offset-datetime")
  assert(datetime_kind("07:32") == "local-time")
  assert(datetime_kind("1979-05-27T07:32") == "local-datetime")
  assert(datetime_kind("1979-05-27T07:32Z") == "offset-datetime")
  assert(datetime_kind("garbage") == "invalid")
  println("  datetime_kind: ok")

  // --- date_cmp ---
  assert(date_cmp("2024-01-01", "2024-12-31") == -1)
  assert(date_cmp("2024-12-31", "2024-01-01") == 1)
  assert(date_cmp("2024-05-15", "2024-05-15") == 0)
  println("  date_cmp: ok")

  // --- time_cmp ---
  assert(time_cmp("07:00:00", "23:00:00") == -1)
  assert(time_cmp("23:00:00", "07:00:00") == 1)
  assert(time_cmp("12:30:00", "12:30:00") == 0)
  println("  time_cmp: ok")

  // --- datetime_cmp ---
  assert(datetime_cmp("2024-01-01T00:00:00", "2024-12-31T23:59:59") == -1)
  assert(datetime_cmp("2025-01-01T00:00:00", "2024-12-31T23:59:59") == 1)
  println("  datetime_cmp: ok")

  // --- is_before ---
  assert(is_before("2024-01-01", "2024-12-31") == true)
  assert(is_before("2024-12-31", "2024-01-01") == false)
  assert(is_before("07:00:00", "23:00:00") == true)
  assert(is_before("2024-01-01T00:00:00", "2024-12-31T00:00:00") == true)
  println("  is_before: ok")

  // --- offset_to_minutes ---
  match offset_to_minutes("Z") {
    Ok(m) => assert(m == 0),
    Err(_) => assert(false)
  }
  match offset_to_minutes("+02:00") {
    Ok(m) => assert(m == 120),
    Err(_) => assert(false)
  }
  match offset_to_minutes("-05:30") {
    Ok(m) => assert(m == -330),
    Err(_) => assert(false)
  }
  match offset_to_minutes("bad") {
    Ok(_) => assert(false),
    Err(_) => assert(true)
  }
  println("  offset_to_minutes: ok")

  // --- day_of_week ---
  // 2024-05-15 is a Wednesday
  match day_of_week("2024-05-15") {
    Ok(d) => assert(d == "wednesday"),
    Err(_) => assert(false)
  }
  // 2026-05-15 is a Friday
  match day_of_week("2026-05-15") {
    Ok(d) => assert(d == "friday"),
    Err(_) => assert(false)
  }
  // 2000-01-01 is a Saturday
  match day_of_week("2000-01-01") {
    Ok(d) => assert(d == "saturday"),
    Err(_) => assert(false)
  }
  match day_of_week("bad") {
    Ok(_) => assert(false),
    Err(_) => assert(true)
  }
  println("  day_of_week: ok")

  println("all datetime tests passed")
}
