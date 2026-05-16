---
layout: default
title: Libraries - hica
---

# Libraries

External libraries for hica. Until hica has a package registry with dependency management, libraries are installed as git submodules.

## Installation

Add a library as a git submodule to your project:

```sh
git submodule add https://github.com/cladam/yaml.git lib/yaml
```

Then import it in your hica source:

```rust
import "./lib/yaml/src/yaml"
```

## Available Libraries

### yaml

YAML parser and emitter for hica.

- **Repository**: [github.com/cladam/yaml](https://github.com/cladam/yaml)
- **Install**: `git submodule add https://github.com/cladam/yaml.git lib/yaml`
- **Import**: `import "./lib/yaml/src/yaml"`

### toml

TOML parser for hica.

- **Repository**: [github.com/cladam/toml](https://github.com/cladam/toml)
- **Install**: `git submodule add https://github.com/cladam/toml.git lib/toml`
- **Import**: `import "./lib/toml/src/toml"`

### hml

HML, Hica Markup Language parser for hica.

- **Repository**: [github.com/cladam/hml](https://github.com/cladam/hml)
- **Install**: `git submodule add https://github.com/cladam/hml.git lib/hml`
- **Import**: `import "./lib/toml/src/hml"`

### http

HTTP library written in Koka, based on libcurl

- **Repository**: [github.com/cladam/http](https://github.com/cladam/http)
- **Install**: `git submodule add https://github.com/cladam/http.git lib/http`
- **Import**: `import "./lib/toml/src/http"`