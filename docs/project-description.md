## Project Description: Hica
**Hica** is a high-performance, expression-oriented programming language designed for systems-level reliability with a functional heart. It leverages the **Koka ecosystem** to provide advanced effect tracking and memory safety, transpiling to **Koka** source code. Koka then compiles onward to C, JavaScript, or WASM.

### 1. Core Vision
Hica takes the ergonomic, "pragmatic safety" approach of **Lisette** (Rust-like syntax, Go-like simplicity) and fuses it with Koka’s **Algebraic Effect system** and **Perceus memory management**. The goal is a language that feels like a modern scriptable language but runs with the deterministic performance of C.

### 2. Key Pillars
* **The Koka Backbone:** Hica is implemented entirely in Koka. It uses Koka’s row-polymorphism for its type system and Koka’s effect handlers to manage compiler state (parsing, type inference, code generation).
* **Perceus-Powered Memory:** Hica targets Koka, inheriting Koka's **FBIP (Functional But In-Place)** paradigm. It achieves memory safety via precise reference counting without a garbage collector.
* **Effect-First Design:** Side effects (I/O, state, exceptions) are first-class citizens in Hica. The compiler tracks what a function "does," allowing for safer concurrency and more predictable code.
* **Multi-Target Portability:** By transpiling to Koka, Hica programs can be compiled to C, JavaScript, or WASM — wherever Koka can target.

### 3. Language Characteristics (The "Lisette" Influence)
* **Expression-Oriented:** Everything returns a value. `if`, `match`, and `block` are all expressions.
* **Rust-y Syntax:** Uses curly braces `{}` and a familiar keyword set (`let`, `fn`, `match`, `if`).
* **Implicit Returns:** The last expression in a block is the return value.
* **Type Inference:** Strong static typing with Hindley-Milner inference—you rarely need to write types unless you want to.

### 4. Technical Stack
| Component | Tool / Methodology |
| :--- | :--- |
| **Implementation Language** | Koka |
| **Parsing** | Koka Parser Combinators (Indentation + Braces) |
| **Type System** | System F + Row Polymorphism (Algebraic Effects) |
| **Memory Management** | Perceus (Reference Counting with In-place reuse) |
| **Backend Target** | Koka (.kk) → C / JS / WASM via Koka |
| **Runtime** | Koka standard library and runtime |

### 5. High-Level Pipeline
1.  **Hica Source:** Write code in `.hc` files.
2.  **Frontend (Koka):** Parse into an AST using Koka's effect-based parsing.
3.  **Analysis (Koka):** Perform type and effect inference.
4.  **Transformation (Koka):** Convert AST to a Linear IR (Intermediate Representation) suitable for Koka emission.
5.  **Emission:** Generate Koka source code (.kk files) that can be compiled by the Koka toolchain.
