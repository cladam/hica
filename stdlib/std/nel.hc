// hica — std/nel — Non-empty list of strings
// Import with: import "std/nel"

pub type Nel {
  Nel(head: string, tail: list<string>)
}

// Create a Nel with a single element
pub fun nel_of(x: string) : Nel =>
  Nel(x, [])

// Convert a Nel to a standard list of strings
pub fun nel_to_list(n: Nel) : list<string> => match n {
  Nel(h, t) => [h] + t
}

// Get the head of the Nel
pub fun nel_head(n: Nel) : string => match n {
  Nel(h, _) => h
}

// Map a function over each element of the Nel, returning a new Nel
pub fun nel_map(n: Nel, f: (string) -> string) : Nel => match n {
  Nel(h, t) => Nel(f(h), map(t, f))
}

// Concatenate two Nel values into a single Nel
pub fun nel_concat(a: Nel, b: Nel) : Nel => match a {
  Nel(ah, at) => match b {
    Nel(bh, bt) => Nel(ah, at + [bh] + bt)
  }
}
