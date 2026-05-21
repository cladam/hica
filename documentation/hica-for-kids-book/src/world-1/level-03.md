# Level 3. Getting Started

### What you need

#### Install Koka

Install [Koka](https://koka-lang.github.io/koka/doc/book.html#install) version 3.2 or newer.

#### Linux / macOS / Chromebook

```sh
curl -fsSL https://cladam.github.io/hica/install.sh | sh
```

This downloads the latest release binary and installs it to `~/.local/bin`.
Make sure that directory is on your `PATH`.

To install elsewhere:

```sh
curl -fsSL https://cladam.github.io/hica/install.sh | HICA_INSTALL_DIR=/usr/local/bin sh
```

#### Windows (PowerShell)

```powershell
irm https://cladam.github.io/hica/install.ps1 | iex
```

This installs hica to `%LOCALAPPDATA%\hica` and adds it to your user PATH.
Override the install directory with `$env:HICA_INSTALL_DIR`.

### Try things interactively

Start the REPL to experiment without creating a file:

```sh
hica repl
```

```
hica=> 1 + 2
3
hica=> _ * 10
30
hica=> "hi " + "there"
hi there
```

Type `:quit` to exit. The `_` holds your last result.

### Try it in the browser

Don't want to install anything? The [hica Playground](https://cladam.github.io/hica/playground/) lets you write and run hica code directly in your browser: no setup required. It comes with example programs you can explore with one click.
