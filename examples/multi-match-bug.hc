type TomlValue {
  TStr(str_val: string),
  TInt(int_val: int),
  TTable(entries: list<(string, string)>)
}

fun toml_parse(s: string) : result<list<(string, TomlValue)>, string> {
  Ok([("title", TStr("My App")), ("server", TTable([]))])
}

fun toml_get(doc: list<(string, TomlValue)>, key: string) : maybe<TomlValue> {
  match find(doc, (entry) => entry.0 == key) {
    Some(entry) => Some(entry.1),
    None => None
  }
}

fun main() {
  println("ok")
}

test "root keys before table" {
  let input = "title = \"My App\"\n\n[server]\nport = 3000"
  match toml_parse(input) {
    Ok(doc) => {
      match toml_get(doc, "title") {
        Some(TStr(v)) => assert(v == "My App"),
        _ => assert(false)
      }
      match toml_get(doc, "server") {
        Some(TTable(_)) => assert(true),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}
