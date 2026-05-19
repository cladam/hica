// hica playground runtime
'use strict';

const __hc_output = [];
function println(s) { const line = String(s); __hc_output.push(line); if (typeof process !== 'undefined') process.stdout.write(line + '\n'); }
function print(s) { const t = String(s); __hc_output.push(t); if (typeof process !== 'undefined') process.stdout.write(t); }
function __tuple(...args) { const t = [...args]; t.__tuple = true; return t; }
function show(v) {
  if (v === null || v === undefined) return 'Nothing';
  if (typeof v === 'boolean') return v ? 'True' : 'False';
  if (typeof v === 'string') return v;
  if (typeof v === 'number') return Number.isInteger(v) ? String(v) : v.toPrecision(17).replace(/0+$/, '').replace(/\\.$/, '.0');
  if (Array.isArray(v) && v.__tuple) return '(' + v.map(show_list_elem).join(',') + ')';
  if (Array.isArray(v)) return '[' + v.map(show_list_elem).join(',') + ']';
  if (typeof v === 'object' && v.__tag === 'Ok') return 'Right(' + show_list_elem(v.value) + ')';
  if (typeof v === 'object' && v.__tag === 'Err') return 'Left(' + show_list_elem(v.value) + ')';
  if (typeof v === 'object' && v.__tag) return v.__tag + (v.__args && v.__args.length > 0 ? '(' + v.__args.map(show).join(', ') + ')' : '');
  if (typeof v === 'object' && v.__show) return v.__show();
  if (typeof v === 'object') return JSON.stringify(v);
  return String(v);
}
function show_maybe(v) { return v === null ? 'Nothing' : 'Just(' + show(v) + ')'; }
function show_result(r) {
  if (r && r.__tag === 'Ok') return 'Right(' + show_list_elem(r.value) + ')';
  if (r && r.__tag === 'Err') return 'Left(' + show_list_elem(r.value) + ')';
  return show(r);
}
function show_list_elem(v) {
  if (typeof v === 'string' && v.length === 1) return "'" + v + "'";
  if (typeof v === 'string') return '"' + v + '"';
  return show(v);
}
function abs(n) { return Math.abs(n); }
function min(a, b) { return Math.min(a, b); }
function max(a, b) { return Math.max(a, b); }
function str_length(s) { return s.length; }
function contains(s, sub) { return s.includes(sub); }
function split(s, sep) { return sep === '' ? [...s] : s.split(sep); }
function join(xs, sep) { return xs.join(sep); }
function trim(s) { return s.trim(); }
function replace(s, old, nw) { return s.replaceAll(old, nw); }
function to_upper(s) { return s.toUpperCase(); }
function to_lower(s) { return s.toLowerCase(); }
function parse_int(s) { const n = parseInt(s, 10); return isNaN(n) ? null : n; }
function parse_float(s) { const n = parseFloat(s); return isNaN(n) ? null : n; }
function to_int(s) { const n = parseInt(s, 10); return isNaN(n) ? -1 : n; }
function enumerate(xs) { return xs.map((x, i) => __tuple(i, x)); }
function head(xs) { return xs.length > 0 ? xs[0] : null; }
function tail(xs) { return xs.slice(1); }
function length(xs) { return xs.length; }
function reverse(xs) { return [...xs].reverse(); }
function sort(xs) { return [...xs].sort((a,b) => a < b ? -1 : a > b ? 1 : 0); }
function map(xs, f) { return xs.map(f); }
function filter(xs, f) { return xs.filter(f); }
function fold(xs, init, f) { return xs.reduce((acc, x) => f(acc, x), init); }
function foreach(xs, f) { xs.forEach(f); }
function take(xs, n) { return xs.slice(0, n); }
function drop(xs, n) { return xs.slice(n); }
function zip(xs, ys) { return xs.map((x, i) => i < ys.length ? __tuple(x, ys[i]) : null).filter(p => p !== null); }
function concat(xss) { return [].concat(...xss); }
function cons(x, xs) { return [x, ...xs]; }
function find(xs, f) { const r = xs.find(f); return r === undefined ? null : r; }
function all(xs, f) { return xs.every(f); }
function any(xs, f) { return xs.some(f); }
function repeat(n, f) { for (let i = 0; i < n; i++) f(); }
function random(lo, hi) { return Math.floor(Math.random() * (hi - lo + 1)) + lo; }
function assert(cond, msg) { if (!cond) throw new Error('assertion failed: ' + (msg || '')); }

// Maybe/Result helpers
const None = null;
function Some(v) { return v; }
function is_some(v) { return v !== null; }
function is_none(v) { return v === null; }
function unwrap(v) { if (v === null) throw new Error('unwrap on None'); return v; }
function unwrap_or(v, d) { return v !== null ? v : d; }
function unwrap_maybe_or(v, d) { return v !== null ? v : d; }
function map_maybe(m, f) { return m !== null ? Some(f(m)) : null; }
function and_then(m, f) { return m !== null ? f(m) : null; }
function or_else(m, f) { return m !== null ? m : f(); }
function Ok(v) { return { __tag: 'Ok', value: v, __args: [v] }; }
function Err(v) { return { __tag: 'Err', value: v, __args: [v] }; }
function is_ok(r) { return r && r.__tag === 'Ok'; }
function is_err(r) { return r && r.__tag === 'Err'; }
function unwrap_result(r) { if (r.__tag === 'Ok') return r.value; throw new Error('unwrap on Err: ' + r.value); }
function unwrap_result_or(r, d) { return r.__tag === 'Ok' ? r.value : d; }
function map_result(r, f) { return r.__tag === 'Ok' ? Ok(f(r.value)) : r; }
function and_then_result(r, f) { return r.__tag === 'Ok' ? f(r.value) : r; }
function map_err(r, f) { return r.__tag === 'Err' ? Err(f(r.value)) : r; }

// Prelude: string helpers
function is_empty(s) { return s.length === 0; }
function is_blank(s) { return s.trim().length === 0; }
function words(s) { return s.split(' ').filter(w => w.length > 0); }
function lines(s) { return s.split('\n'); }
function unwords(ws) { return ws.join(' '); }
function unlines(ls) { return ls.join('\n'); }
function starts_with(s, pre) { return s.startsWith(pre); }
function ends_with(s, suf) { return s.endsWith(suf); }
function repeat_str(s, n) { return n <= 0 ? '' : s.repeat(n); }
function pad_left(s, w, ch) { return repeat_str(ch, Math.max(0, w - s.length)) + s; }
function pad_right(s, w, ch) { return s + repeat_str(ch, Math.max(0, w - s.length)); }
function index_of(s, sub) { const i = s.indexOf(sub); return i === -1 ? null : i; }
function count_substr(s, sub) { return s.split(sub).length - 1; }
function surround(s, w) { return w + s + w; }

// Prelude: operators
function is_positive(n) { return n > 0; }
function is_negative(n) { return n < 0; }
function is_zero(n) { return n === 0; }
function is_even(n) { return n % 2 === 0; }
function is_odd(n) { return n % 2 !== 0; }
function identity(x) { return x; }
function not_(b) { return !b; }
function to_float(n) { return n; }
function show_fixed(f, prec) { return f.toFixed(prec); }

// I/O (Node.js only — no-op in browser)
function get_args() { return typeof process !== 'undefined' ? process.argv.slice(2) : []; }
function read_file(path) { try { const fs = require('fs'); return fs.readFileSync(path, 'utf8'); } catch(e) { return null; } }
function read_lines(path) { const s = read_file(path); return s !== null ? s.split('\n') : []; }
function write_file(path, content) { try { const fs = require('fs'); fs.writeFileSync(path, content); return true; } catch(e) { return false; } }
function removeprefix(s, pre) { return s.startsWith(pre) ? s.slice(pre.length) : s; }
function removesuffix(s, suf) { return s.endsWith(suf) ? s.slice(0, s.length - suf.length) : s; }
function char_at(s, i) { return i >= 0 && i < s.length ? s[i] : null; }
function substring(s, start, end) { return s.slice(start, end); }
function to_string(v) { return show(v); }
function chars(s) { return [...s]; }
function char_to_string(c) { return c; }
function ord(c) { return typeof c === 'string' ? c.charCodeAt(0) : c; }
function chr(n) { return String.fromCharCode(n); }
function is_digit(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return n >= 48 && n <= 57; }
function is_upper(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return n >= 65 && n <= 90; }
function is_lower(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return n >= 97 && n <= 122; }
function is_alpha(c) { return is_upper(c) || is_lower(c); }
function is_alnum(c) { return is_alpha(c) || is_digit(c); }
function is_space(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return n === 32 || n === 9 || n === 10 || n === 13; }
function is_punct(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return (n >= 33 && n <= 47) || (n >= 58 && n <= 64) || (n >= 91 && n <= 96) || (n >= 123 && n <= 126); }
function all_digits(s) { return s.length > 0 && [...s].every(c => is_digit(c)); }
function all_alpha(s) { return s.length > 0 && [...s].every(c => is_alpha(c)); }
function all_upper(s) { return s.length > 0 && [...s].every(c => is_upper(c)); }
function all_lower(s) { return s.length > 0 && [...s].every(c => is_lower(c)); }
function all_alnum(s) { return s.length > 0 && [...s].every(c => is_alnum(c)); }


function has_digit(s) {
  return any(chars(s), ((c) => {
    return is_digit(c);
  }));
}

function validate(password) {
  const long_enough = (str_length(password) >= 6);
  return (long_enough && has_digit(password));
}

// Entry point
if (typeof main === 'function') { const __r = main(); if (__r !== undefined && __r !== null) println(show(__r)); }
