# hica-registry

**Files:**
- [auth.hc](../../../hica-registry/src/auth.hc)
- [db.hc](../../../hica-registry/src/db.hc)
- [routes.hc](../../../hica-registry/src/routes.hc)
- [main.hc](../../../hica-registry/src/main.hc)

---

# Project Architecture & Export Directory: `auth.hc`

## Module Overview
- **Source File:** `../hica-registry/src/auth.hc`
## Dependencies
- `web`
- `sqlite`

## Public API Catalog

### Public Functions

| Function | Signature | Description |
| --- | --- | --- |
| `bearer_token` | `fun bearer_token(req: t365) : maybe<string>` | *(No documentation provided)* |
| `sha256_file` | `fun sha256_file(path: string) : result<string, string>` | *(No documentation provided)* |
| `sha256_str` | `fun sha256_str(s: string) : result<string, string>` | *(No documentation provided)* |
| `check_auth` | `fun check_auth(db: Db, req: t396) : maybe<int>` | *(No documentation provided)* |


---

# Domain Data Models & Type Dictionary

*(No structs or enums defined in this module)*

---

# Purity and Side Effects Tracking Matrix

| Function | Signature | Purity Status | Detected Effect Dependencies |
| --- | --- | --- | --- |
| `bearer_token` | `fun bearer_token(req: t365) : maybe<string>` | ✅ Pure | None |
| `sha256_file` | `fun sha256_file(path: string) : result<string, string>` | ✅ Pure | None |
| `sha256_str` | `fun sha256_str(s: string) : result<string, string>` | ⚡ Impure | I/O & FileSystem |
| `check_auth` | `fun check_auth(db: Db, req: t396) : maybe<int>` | ✅ Pure | None |

---

# Hica Analysis Hotspot: `../hica-registry/src/auth.hc`

## Function Context
- **Name:** `check_auth`
- **Signature:** `fun check_auth(db: Db, req: t396) : maybe<int>`
- **Location:** `../hica-registry/src/auth.hc:89`
- **Debt Score:** 8 (High)

## Detected FP Anti-Patterns
1. **Error Handling:** Nested 'match' on maybe/result (score: +8)
   - *Hint:* Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.

## Code Snippet
```hica
fun check_auth(db, req) {
  match bearer_token(req) {
    None => None,
    Some(tok) => match sha256_str(tok) {
      Err(_) => None,
      Ok(hash) =>
        match sqlite_query_p(db,
            "SELECT user_id FROM tokens WHERE token_hash = ?",
            [param(hash)]) {
          Err(_) => None,
          Ok(res) => match res.rows {
            [] => None,
            [r, ..] => {
              let uid = match row_int(r, 0) { Some(n) => n, None => 0 }
              let _ = sqlite_exec_p(db,
                "UPDATE tokens SET last_used_at = datetime('now') " +
                "WHERE token_hash = ?",
                [param(hash)])
              Some(uid)
            }
          }
        }
    }
  }
}
```

---

## Summary
- **Functions analysed:** 4
- **Functions with debt:** 1
- **Total debt score:** 8

**FP Quality Index: 92/100**

---

# Router Map & Symbolic Index

This index maps symbol names to their original file ranges, for tool and human reference.

- [`bearer_token`](../../../hica-registry/src/auth.hc#L32)
- [`sha256_file`](../../../hica-registry/src/auth.hc#L51)
- [`sha256_str`](../../../hica-registry/src/auth.hc#L75)
- [`check_auth`](../../../hica-registry/src/auth.hc#L89)
---

# Project Architecture & Export Directory: `db.hc`

## Module Overview
- **Source File:** `../hica-registry/src/db.hc`
## Dependencies
- `sqlite`

## Public API Catalog

### Public Functions

| Function | Signature | Description |
| --- | --- | --- |
| `schema_sql` | `fun schema_sql() : string` | *(No documentation provided)* |
| `init_db` | `fun init_db(db: Db) : ()` | *(No documentation provided)* |
| `upgrade_db` | `fun upgrade_db(db: Db) : ()` | *(No documentation provided)* |
| `seed_admin_token` | `fun seed_admin_token(db: Db) : ()` | *(No documentation provided)* |
| `sopt` | `fun sopt(m: maybe<string>) : string` | *(No documentation provided)* |
| `iopt` | `fun iopt(m: maybe<int>) : int` | *(No documentation provided)* |


---

# Domain Data Models & Type Dictionary

*(No structs or enums defined in this module)*

---

# Purity and Side Effects Tracking Matrix

| Function | Signature | Purity Status | Detected Effect Dependencies |
| --- | --- | --- | --- |
| `schema_sql` | `fun schema_sql() : string` | ✅ Pure | None |
| `init_db` | `fun init_db(db: Db) : ()` | ⚡ Impure | Console |
| `upgrade_db` | `fun upgrade_db(db: Db) : ()` | ⚡ Impure | Console |
| `seed_admin_token` | `fun seed_admin_token(db: Db) : ()` | ⚡ Impure | I/O & FileSystem, Console |
| `sopt` | `fun sopt(m: maybe<string>) : string` | ✅ Pure | None |
| `iopt` | `fun iopt(m: maybe<int>) : int` | ✅ Pure | None |

---

# Hica Analysis Hotspot: `../hica-registry/src/db.hc`

## Summary
✅ **No functional debt detected** — all 6 function(s) are clean.

**FP Quality Index: 100/100**

---

# Router Map & Symbolic Index

This index maps symbol names to their original file ranges, for tool and human reference.

- [`schema_sql`](../../../hica-registry/src/db.hc#L22)
- [`init_db`](../../../hica-registry/src/db.hc#L88)
- [`upgrade_db`](../../../hica-registry/src/db.hc#L103)
- [`seed_admin_token`](../../../hica-registry/src/db.hc#L158)
- [`sopt`](../../../hica-registry/src/db.hc#L187)
- [`iopt`](../../../hica-registry/src/db.hc#L194)
---

# Project Architecture & Export Directory: `routes.hc`

## Module Overview
- **Source File:** `../hica-registry/src/routes.hc`
## Dependencies
- `web`
- `multipart`
- `json`
- `sqlite`
- `./db`
- `./auth`

## Public API Catalog

### Public Functions

| Function | Signature | Description |
| --- | --- | --- |
| `download_url` | `fun download_url(name: string, ver: string) : string` | *(No documentation provided)* |
| `tarball_url` | `fun tarball_url(name: string, ver: string) : string` | *(No documentation provided)* |
| `pkg_stub_json` | `fun pkg_stub_json(r: Row) : Json` | *(No documentation provided)* |
| `version_json` | `fun version_json(name: string, r: Row) : Json` | *(No documentation provided)* |
| `first_active` | `fun first_active(rows: list<Row>) : string` | *(No documentation provided)* |
| `handle_health` | `fun handle_health(db: Db, req: t715) : ServerResponse` | *(No documentation provided)* |
| `handle_summary` | `fun handle_summary(db: Db, req: t729) : ServerResponse` | *(No documentation provided)* |
| `handle_index` | `fun handle_index(db: Db, req: t802) : ServerResponse` | *(No documentation provided)* |
| `handle_search` | `fun handle_search(db: Db, req: t826) : ServerResponse` | *(No documentation provided)* |
| `handle_get_package` | `fun handle_get_package(db: Db, req: t896) : ServerResponse` | *(No documentation provided)* |
| `handle_publish` | `fun handle_publish(db: Db, req: t943, on_publish: maybe<(string, string, string, string, string, string, t1007, t954) -> t1008>) : ServerResponse` | *(No documentation provided)* |
| `handle_get_version` | `fun handle_get_version(db: Db, req: t1062) : ServerResponse` | *(No documentation provided)* |
| `handle_download` | `fun handle_download(db: Db, req: t1087) : ServerResponse` | *(No documentation provided)* |
| `handle_yank` | `fun handle_yank(db: Db, req: t1117) : ServerResponse` | *(No documentation provided)* |
| `handle_unyank` | `fun handle_unyank(db: Db, req: t1156) : ServerResponse` | *(No documentation provided)* |
| `handle_list_owners` | `fun handle_list_owners(db: Db, req: t1195) : ServerResponse` | *(No documentation provided)* |
| `handle_add_owner` | `fun handle_add_owner(db: Db, req: t1233) : ServerResponse` | *(No documentation provided)* |
| `handle_remove_owner` | `fun handle_remove_owner(db: Db, req: t1310) : ServerResponse` | *(No documentation provided)* |
| `handle_hica_downloads` | `fun handle_hica_downloads(db: Db, req: t1405) : ServerResponse` | *(No documentation provided)* |
| `handle_hica_download` | `fun handle_hica_download(db: Db, req: t1464) : ServerResponse` | *(No documentation provided)* |
| `build_routes` | `fun build_routes(db: t1478) : t1481` | *(No documentation provided)* |
| `build_routes_cooperative` | `fun build_routes_cooperative(db: Db, on_publish: maybe<(string, string, string, string, string, string, t1007, t1318) -> t1008>) : list<t1520>` | *(No documentation provided)* |


---

# Domain Data Models & Type Dictionary

*(No structs or enums defined in this module)*

---

# Purity and Side Effects Tracking Matrix

| Function | Signature | Purity Status | Detected Effect Dependencies |
| --- | --- | --- | --- |
| `download_url` | `fun download_url(name: string, ver: string) : string` | ✅ Pure | None |
| `tarball_url` | `fun tarball_url(name: string, ver: string) : string` | ✅ Pure | None |
| `pkg_stub_json` | `fun pkg_stub_json(r: Row) : Json` | ✅ Pure | None |
| `version_json` | `fun version_json(name: string, r: Row) : Json` | ✅ Pure | None |
| `first_active` | `fun first_active(rows: list<Row>) : string` | ⚡ Impure | Divergent (recursion/loop) |
| `handle_health` | `fun handle_health(db: Db, req: t715) : ServerResponse` | ✅ Pure | None |
| `handle_summary` | `fun handle_summary(db: Db, req: t729) : ServerResponse` | ✅ Pure | None |
| `handle_index` | `fun handle_index(db: Db, req: t802) : ServerResponse` | ✅ Pure | None |
| `handle_search` | `fun handle_search(db: Db, req: t826) : ServerResponse` | ✅ Pure | None |
| `handle_get_package` | `fun handle_get_package(db: Db, req: t896) : ServerResponse` | ✅ Pure | None |
| `handle_publish` | `fun handle_publish(db: Db, req: t943, on_publish: maybe<(string, string, string, string, string, string, t1007, t954) -> t1008>) : ServerResponse` | ⚡ Impure | I/O & FileSystem |
| `handle_get_version` | `fun handle_get_version(db: Db, req: t1062) : ServerResponse` | ✅ Pure | None |
| `handle_download` | `fun handle_download(db: Db, req: t1087) : ServerResponse` | ✅ Pure | None |
| `handle_yank` | `fun handle_yank(db: Db, req: t1117) : ServerResponse` | ✅ Pure | None |
| `handle_unyank` | `fun handle_unyank(db: Db, req: t1156) : ServerResponse` | ✅ Pure | None |
| `handle_list_owners` | `fun handle_list_owners(db: Db, req: t1195) : ServerResponse` | ✅ Pure | None |
| `handle_add_owner` | `fun handle_add_owner(db: Db, req: t1233) : ServerResponse` | ✅ Pure | None |
| `handle_remove_owner` | `fun handle_remove_owner(db: Db, req: t1310) : ServerResponse` | ✅ Pure | None |
| `handle_hica_downloads` | `fun handle_hica_downloads(db: Db, req: t1405) : ServerResponse` | ✅ Pure | None |
| `handle_hica_download` | `fun handle_hica_download(db: Db, req: t1464) : ServerResponse` | ⚡ Impure | I/O & FileSystem |
| `build_routes` | `fun build_routes(db: t1478) : t1481` | ✅ Pure | None |
| `build_routes_cooperative` | `fun build_routes_cooperative(db: Db, on_publish: maybe<(string, string, string, string, string, string, t1007, t1318) -> t1008>) : list<t1520>` | ✅ Pure | None |

---

# Hica Analysis Hotspot: `../hica-registry/src/routes.hc`

## Function Context
- **Name:** `handle_summary`
- **Signature:** `fun handle_summary(db: Db, req: t729) : ServerResponse`
- **Location:** `../hica-registry/src/routes.hc:103`
- **Debt Score:** 25 (Critical)

## Detected FP Anti-Patterns
1. **Error Handling:** Nested 'match' on maybe/result (score: +8)
   - *Hint:* Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.
2. **Error Handling:** Nested 'match' on maybe/result (score: +8)
   - *Hint:* Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.
3. **Closure & Lambda Noise:** Redundant lambda wrapper (Lambda Noise) (score: +3)
   - *Hint:* Convert to point-free style (e.g. filter(is_even) instead of filter((x) => is_even(x))).
4. **Closure & Lambda Noise:** Redundant lambda wrapper (Lambda Noise) (score: +3)
   - *Hint:* Convert to point-free style (e.g. filter(is_even) instead of filter((x) => is_even(x))).
5. **Closure & Lambda Noise:** Redundant lambda wrapper (Lambda Noise) (score: +3)
   - *Hint:* Convert to point-free style (e.g. filter(is_even) instead of filter((x) => is_even(x))).

## Code Snippet
```hica
fun handle_summary(db, req) {
  match sqlite_query_p(db,
          "SELECT (SELECT COUNT(*) FROM packages), " +
          "       (SELECT COUNT(*) FROM versions), " +
          "       (SELECT COALESCE(SUM(count), 0) FROM downloads)",
          []) {
    Err(e) => error_response(e.message),
    Ok(sr) => match sr.rows {
      [] => error_response("stats query returned no rows"),
      [srow, .._] => {
        let num_pkgs = iopt(row_int(srow, 0))
        let num_vers = iopt(row_int(srow, 1))
        let num_dl   = iopt(row_int(srow, 2))
        match sqlite_query_p(db,
                "SELECT p.name, p.description, " +
                "  (SELECT v.version FROM versions v WHERE v.package_id = p.id " +
                "   AND v.yanked = 0 ORDER BY v.published_at DESC, v.id DESC LIMIT 1), " +
                "  COALESCE(SUM(d.count), 0) " +
                "FROM packages p " +
                "LEFT JOIN versions v2 ON v2.package_id = p.id " +
                "LEFT JOIN downloads d ON d.version_id = v2.id " +
                "GROUP BY p.id, p.name, p.description " +
                "ORDER BY COALESCE(SUM(d.count), 0) DESC LIMIT 5",
                []) {
          Err(e) => error_response(e.message),
          Ok(dr) =>
            match sqlite_query_p(db,
                    "SELECT p.name, p.description, " +
                    "  (SELECT v.version FROM versions v WHERE v.package_id = p.id " +
                    "   AND v.yanked = 0 ORDER BY v.published_at DESC, v.id DESC LIMIT 1), " +
                    "  COALESCE((SELECT SUM(d2.count) FROM downloads d2 " +
                    "             JOIN versions v2 ON v2.id = d2.version_id " +
                    "             WHERE v2.package_id = p.id), 0) " +
                    "FROM packages p ORDER BY p.created_at DESC LIMIT 5",
                    []) {
              Err(e) => error_response(e.message),
              Ok(nr) =>
                match sqlite_query_p(db,
                        "SELECT p.name, p.description, " +
                        "  (SELECT v.version FROM versions v WHERE v.package_id = p.id " +
                        "   AND v.yanked = 0 ORDER BY v.published_at DESC, v.id DESC LIMIT 1), " +
                        "  COALESCE((SELECT SUM(d2.count) FROM downloads d2 " +
                        "             JOIN versions v2 ON v2.id = d2.version_id " +
                        "             WHERE v2.package_id = p.id), 0) " +
                        "FROM packages p " +
                        "ORDER BY (SELECT MAX(v.published_at) FROM versions v " +
                        "          WHERE v.package_id = p.id) DESC LIMIT 5",
                        []) {
                  Err(e) => error_response(e.message),
                  Ok(ur) => {
                    let most_dl  = map(dr.rows, (r) => pkg_stub_json(r))
                    let new_pkgs = map(nr.rows, (r) => pkg_stub_json(r))
                    let just_upd = map(ur.rows, (r) => pkg_stub_json(r))
                    json_response(json_emit(JObject([
                      ("num_packages",    JInt(num_pkgs)),
                      ("num_versions",    JInt(num_vers)),
                      ("num_downloads",   JInt(num_dl)),
                      ("most_downloaded", JArray(most_dl)),
                      ("new_packages",    JArray(new_pkgs)),
                      ("just_updated",    JArray(just_upd))
                    ])))
                  }
                }
            }
        }
      }
    }
  }
}
```

---

## Function Context
- **Name:** `handle_hica_downloads`
- **Signature:** `fun handle_hica_downloads(db: Db, req: t1405) : ServerResponse`
- **Location:** `../hica-registry/src/routes.hc:667`
- **Debt Score:** 8 (High)

## Detected FP Anti-Patterns
1. **Error Handling:** Nested 'match' on maybe/result (score: +8)
   - *Hint:* Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.

## Code Snippet
```hica
fun handle_hica_downloads(db, req) {
  match sqlite_query_p(db,
          "SELECT COALESCE(SUM(count), 0) FROM hica_downloads", []) {
    Err(e) => error_response(e.message),
    Ok(tr) => match tr.rows {
      [] => error_response("stats query returned no rows"),
      [trow, .._] => {
        let total = iopt(row_int(trow, 0))
        match sqlite_query_p(db,
                "SELECT version, COALESCE(SUM(count), 0) FROM hica_downloads " +
                "GROUP BY version ORDER BY version DESC", []) {
          Err(e) => error_response(e.message),
          Ok(vr) =>
            match sqlite_query_p(db,
                    "SELECT os, COALESCE(SUM(count), 0) FROM hica_downloads " +
                    "WHERE os != '' GROUP BY os ORDER BY SUM(count) DESC", []) {
              Err(e) => error_response(e.message),
              Ok(or) => {
                let by_version = map(vr.rows, (r) => JObject([
                  ("version",   JString(sopt(row_str(r, 0)))),
                  ("downloads", JInt(iopt(row_int(r, 1))))
                ]))
                let by_os = map(or.rows, (r) => JObject([
                  ("os",        JString(sopt(row_str(r, 0)))),
                  ("downloads", JInt(iopt(row_int(r, 1))))
                ]))
                json_response(json_emit(JObject([
                  ("total",      JInt(total)),
                  ("by_version", JArray(by_version)),
                  ("by_os",      JArray(by_os))
                ])))
              }
            }
        }
      }
    }
  }
}
```

---

## Function Context
- **Name:** `handle_remove_owner`
- **Signature:** `fun handle_remove_owner(db: Db, req: t1310) : ServerResponse`
- **Location:** `../hica-registry/src/routes.hc:596`
- **Debt Score:** 8 (High)

## Detected FP Anti-Patterns
1. **Error Handling:** Nested 'match' on maybe/result (score: +8)
   - *Hint:* Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.

## Code Snippet
```hica
fun handle_remove_owner(db, req) {
  let name = path_str(req, "name")
  match check_auth(db, req) {
    None => unauthorized("valid Bearer token required"),
    Some(uid) =>
      match sqlite_query_p(db,
              "SELECT id FROM packages WHERE name = ?", [param(name)]) {
        Err(e) => error_response(e.message),
        Ok(pres) => match pres.rows {
          [] => not_found_response(),
          [prow, .._] => {
            let pkg_id = iopt(row_int(prow, 0))
            match sqlite_query_p(db,
                    "SELECT 1 FROM package_owners WHERE package_id = ? AND user_id = ?",
                    [param(show(pkg_id)), param(show(uid))]) {
              Err(e) => error_response(e.message),
              Ok(ores) => match ores.rows {
                [] => forbidden("not an owner of '" + name + "'"),
                [_, .._] => {
                  let bdoc   = json_ok(parse_json(req_body(req)))
                  let handle = str_or(bdoc |> at("handle"), "")
                  if handle == "" {
                    status_response(400, "missing 'handle' in request body")
                  } else {
                    match sqlite_query_p(db,
                            "SELECT id FROM users WHERE handle = ?", [param(handle)]) {
                      Err(e) => error_response(e.message),
                      Ok(ures) => match ures.rows {
                        [] => status_response(400, "user '" + handle + "' does not exist"),
                        [urow, .._] => {
                          let rem_uid = iopt(row_int(urow, 0))
                          match sqlite_query_p(db,
                                  "SELECT COUNT(*) FROM package_owners WHERE package_id = ?",
                                  [param(show(pkg_id))]) {
                            Err(e) => error_response(e.message),
                            Ok(cres) => match cres.rows {
                              [crow, .._] =>
                                if iopt(row_int(crow, 0)) <= 1 {
                                  status_response(400, "cannot remove the last owner of '" + name + "'")
                                } else {
                                  let _ = sqlite_exec_p(db,
                                    "DELETE FROM package_owners WHERE package_id = ? AND user_id = ?",
                                    [param(show(pkg_id)), param(show(rem_uid))])
                                  json_response(json_emit(JObject([
                                    ("ok",      JBool(true)),
                                    ("package", JString(name)),
                                    ("handle",  JString(handle))
                                  ])))
                                },
                              _ => error_response("unexpected db state")
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
  }
}
```

---

## Function Context
- **Name:** `handle_add_owner`
- **Signature:** `fun handle_add_owner(db: Db, req: t1233) : ServerResponse`
- **Location:** `../hica-registry/src/routes.hc:542`
- **Debt Score:** 8 (High)

## Detected FP Anti-Patterns
1. **Error Handling:** Nested 'match' on maybe/result (score: +8)
   - *Hint:* Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.

## Code Snippet
```hica
fun handle_add_owner(db, req) {
  let name = path_str(req, "name")
  match check_auth(db, req) {
    None => unauthorized("valid Bearer token required"),
    Some(uid) =>
      match sqlite_query_p(db,
              "SELECT id FROM packages WHERE name = ?", [param(name)]) {
        Err(e) => error_response(e.message),
        Ok(pres) => match pres.rows {
          [] => not_found_response(),
          [prow, .._] => {
            let pkg_id = iopt(row_int(prow, 0))
            match sqlite_query_p(db,
                    "SELECT 1 FROM package_owners WHERE package_id = ? AND user_id = ?",
                    [param(show(pkg_id)), param(show(uid))]) {
              Err(e) => error_response(e.message),
              Ok(ores) => match ores.rows {
                [] => forbidden("not an owner of '" + name + "'"),
                [_, .._] => {
                  let bdoc   = json_ok(parse_json(req_body(req)))
                  let handle = str_or(bdoc |> at("handle"), "")
                  if handle == "" {
                    status_response(400, "missing 'handle' in request body")
                  } else {
                    match sqlite_query_p(db,
                            "SELECT id FROM users WHERE handle = ?", [param(handle)]) {
                      Err(e) => error_response(e.message),
                      Ok(ures) => match ures.rows {
                        [] => status_response(400, "user '" + handle + "' does not exist"),
                        [urow, .._] => {
                          let new_uid = iopt(row_int(urow, 0))
                          let _ = sqlite_exec_p(db,
                            "INSERT OR IGNORE INTO package_owners(package_id, user_id) VALUES (?, ?)",
                            [param(show(pkg_id)), param(show(new_uid))])
                          json_response(json_emit(JObject([
                            ("ok",      JBool(true)),
                            ("package", JString(name)),
                            ("handle",  JString(handle))
                          ])))
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
  }
}
```

---

## Function Context
- **Name:** `handle_unyank`
- **Signature:** `fun handle_unyank(db: Db, req: t1156) : ServerResponse`
- **Location:** `../hica-registry/src/routes.hc:480`
- **Debt Score:** 8 (High)

## Detected FP Anti-Patterns
1. **Error Handling:** Nested 'match' on maybe/result (score: +8)
   - *Hint:* Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.

## Code Snippet
```hica
fun handle_unyank(db, req) {
  let name = path_str(req, "name")
  let ver  = path_str(req, "version")
  match check_auth(db, req) {
    None => unauthorized("valid Bearer token required"),
    Some(_) =>
      match sqlite_query_p(db,
              "SELECT v.id FROM versions v " +
              "JOIN packages p ON p.id = v.package_id " +
              "WHERE p.name = ? AND v.version = ?", [param(name), param(ver)]) {
        Err(e)   => error_response(e.message),
        Ok(res)  => match res.rows {
          [] => not_found_response(),
          [_, .._] =>
            match sqlite_exec_p(db,
                "UPDATE versions SET yanked = 0 " +
                "WHERE package_id = (SELECT id FROM packages WHERE name = ?) " +
                "AND version = ?", [param(name), param(ver)]) {
              Err(e) => error_response(e.message),
              Ok(_)  => json_response(json_emit(JObject([
                ("ok",      JBool(true)),
                ("package", JString(name)),
                ("version", JString(ver)),
                ("yanked",  JBool(false))
              ])))
            }
        }
      }
  }
}
```

---

## Function Context
- **Name:** `handle_yank`
- **Signature:** `fun handle_yank(db: Db, req: t1117) : ServerResponse`
- **Location:** `../hica-registry/src/routes.hc:448`
- **Debt Score:** 8 (High)

## Detected FP Anti-Patterns
1. **Error Handling:** Nested 'match' on maybe/result (score: +8)
   - *Hint:* Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.

## Code Snippet
```hica
fun handle_yank(db, req) {
  let name = path_str(req, "name")
  let ver  = path_str(req, "version")
  match check_auth(db, req) {
    None => unauthorized("valid Bearer token required"),
    Some(_) =>
      match sqlite_query_p(db,
              "SELECT v.id FROM versions v " +
              "JOIN packages p ON p.id = v.package_id " +
              "WHERE p.name = ? AND v.version = ?", [param(name), param(ver)]) {
        Err(e)   => error_response(e.message),
        Ok(res)  => match res.rows {
          [] => not_found_response(),
          [_, .._] =>
            match sqlite_exec_p(db,
                "UPDATE versions SET yanked = 1 " +
                "WHERE package_id = (SELECT id FROM packages WHERE name = ?) " +
                "AND version = ?", [param(name), param(ver)]) {
              Err(e) => error_response(e.message),
              Ok(_)  => json_response(json_emit(JObject([
                ("ok",      JBool(true)),
                ("package", JString(name)),
                ("version", JString(ver)),
                ("yanked",  JBool(true))
              ])))
            }
        }
      }
  }
}
```

---

## Summary
- **Functions analysed:** 22
- **Functions with debt:** 6
- **Total debt score:** 65

**FP Quality Index: 35/100**

---

# Router Map & Symbolic Index

This index maps symbol names to their original file ranges, for tool and human reference.

- [`download_url`](../../../hica-registry/src/routes.hc#L34)
- [`tarball_url`](../../../hica-registry/src/routes.hc#L40)
- [`pkg_stub_json`](../../../hica-registry/src/routes.hc#L50)
- [`version_json`](../../../hica-registry/src/routes.hc#L60)
- [`first_active`](../../../hica-registry/src/routes.hc#L71)
- [`handle_health`](../../../hica-registry/src/routes.hc#L87)
- [`handle_summary`](../../../hica-registry/src/routes.hc#L103)
- [`handle_index`](../../../hica-registry/src/routes.hc#L173)
- [`handle_search`](../../../hica-registry/src/routes.hc#L192)
- [`handle_get_package`](../../../hica-registry/src/routes.hc#L248)
- [`handle_publish`](../../../hica-registry/src/routes.hc#L288)
- [`handle_get_version`](../../../hica-registry/src/routes.hc#L400)
- [`handle_download`](../../../hica-registry/src/routes.hc#L420)
- [`handle_yank`](../../../hica-registry/src/routes.hc#L448)
- [`handle_unyank`](../../../hica-registry/src/routes.hc#L480)
- [`handle_list_owners`](../../../hica-registry/src/routes.hc#L517)
- [`handle_add_owner`](../../../hica-registry/src/routes.hc#L542)
- [`handle_remove_owner`](../../../hica-registry/src/routes.hc#L596)
- [`handle_hica_downloads`](../../../hica-registry/src/routes.hc#L667)
- [`handle_hica_download`](../../../hica-registry/src/routes.hc#L711)
- [`build_routes`](../../../hica-registry/src/routes.hc#L727)
- [`build_routes_cooperative`](../../../hica-registry/src/routes.hc#L731)
---

# Project Architecture & Export Directory: `main.hc`

## Module Overview
- **Source File:** `../hica-registry/src/main.hc`
## Dependencies
- `web`
- `sqlite`
- `std/actor`
- `./db`
- `./routes`
- `./auth`

*(No public API exported)*

---

# Domain Data Models & Type Dictionary

## Structs (Data Models)

### Struct `TarballWorkerState`
| Field | Type | Description |
| --- | --- | --- |
| `dummy` | `int` | *(Field)* |

## Algebraic Data Types (Enums)

### Type `TarballWorkerMsg`
#### Variants
- `PublishTask(db: Db, name: string, ver: string, desc: string, repo: string, lic: string, claimed: string, tar_bytes: string, user_id: int)`


---

# Purity and Side Effects Tracking Matrix

| Function | Signature | Purity Status | Detected Effect Dependencies |
| --- | --- | --- | --- |
| `tarballworker_receive` | `fun tarballworker_receive(state: TarballWorkerState, msg: TarballWorkerMsg) : TarballWorkerState` | ⚡ Impure | I/O & FileSystem, Console |
| `on_publish` | `fun on_publish(db: Db, name: string, ver: string, desc: string, repo: string, lic: string, claimed: string, tar_bytes: string, user_id: int) : ()` | ✅ Pure | None |
| `main` | `fun main() : ()` | ⚡ Impure | I/O & FileSystem, Console |
| `run_loop` | `fun run_loop(srv: int, db: Db, worker: TarballWorkerState) : ()` | ⚡ Impure | Divergent (recursion/loop) |

---

# Hica Analysis Hotspot: `../hica-registry/src/main.hc`

## Function Context
- **Name:** `tarballworker_receive`
- **Signature:** `fun tarballworker_receive(state: TarballWorkerState, msg: TarballWorkerMsg) : TarballWorkerState`
- **Location:** `../hica-registry/src/main.hc:48`
- **Debt Score:** 5 (Medium)

## Detected FP Anti-Patterns
1. **Immutability:** Mutable 'var' declaration used (score: +5)
   - *Hint:* Suggest using 'map', 'filter', 'fold', or lazy streams instead.

## Code Snippet
```hica
actor TarballWorker {
  var dummy = 0

  receive(msg) => match msg {
    PublishTask(db, name, ver, desc, repo, lic, claimed, tar_bytes, user_id) => {
      let tdir  = match get_env("HICA_TARBALL_DIR") {
        Some(d) => d,
        None    => "./tarballs"
      }
      let pkg_dir = tdir + "/" + name
      let tpath   = pkg_dir + "/" + name + "-" + ver + ".tar.gz"
      match exec("mkdir -p " + pkg_dir) {
        Err(e) => println("[Background Worker] could not create tarball dir: " + e),
        Ok(_) => {
          write_file(tpath, tar_bytes)
          match sha256_file(tpath) {
            Err(e) => println("[Background Worker] sha256 failed: " + e),
            Ok(actual_sum) =>
              if claimed != "" && claimed != actual_sum {
                println("[Background Worker] checksum mismatch")
              } else {
                let _ = sqlite_exec_p(db,
                  "INSERT OR IGNORE INTO packages(name, description, repository, license) " +
                  "VALUES (?, ?, ?, ?)",
                  [param(name), param(desc), param(repo), param(lic)])
                let _ = sqlite_exec_p(db,
                  "INSERT OR IGNORE INTO package_owners(package_id, user_id) " +
                  "SELECT p.id, ? FROM packages p " +
                  "WHERE p.name = ? " +
                  "AND NOT EXISTS (SELECT 1 FROM package_owners po WHERE po.package_id = p.id)",
                  [param(show(user_id)), param(name)])
                match sqlite_exec_p(db,
                    "INSERT INTO versions(package_id, version, checksum, tarball_path, published_by) " +
                    "VALUES ((SELECT id FROM packages WHERE name = ?), ?, ?, ?, ?)",
                    [param(name), param(ver), param(actual_sum), param(tpath), param(show(user_id))]) {
                  Err(e) => println("[Background Worker] could not publish: " + e.message),
                  Ok(_) => println("[Background Worker] successfully published " + name + "@" + ver)
                }
              }
          }
        }
      }
    }
  }
}
```

---

## Summary
- **Functions analysed:** 4
- **Functions with debt:** 1
- **Total debt score:** 5

**FP Quality Index: 95/100**

---

# Router Map & Symbolic Index

This index maps symbol names to their original file ranges, for tool and human reference.

- [`tarballworker_receive`](../../../hica-registry/src/main.hc#L48)
- [`on_publish`](../../../hica-registry/src/main.hc#L94)
- [`main`](../../../hica-registry/src/main.hc#L101)
- [`run_loop`](../../../hica-registry/src/main.hc#L129)
