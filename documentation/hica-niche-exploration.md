# Hica Niche Exploration

A creative exploration of differentiated focus areas beyond table-stakes HTTP servers.

---

## Why a niche matters

Many languages compete for general-purpose mindshare and lose. The ones that break through often own a specific domain first: Lua owns game scripting, R owns statistics, Erlang owns telecom reliability, SQL owns relational queries. Hica's combination of **effect types + Perceus/no-GC + WASM target** is unusual enough that it can own something specific — the question is what.

---

## Candidate niches

### 1. AI Agent Capability Language ★★★★★

The 2026 problem nobody has solved at the language level: **"What can this agent actually do?"**

Python agents call APIs you didn't expect, read files you didn't want, execute processes you never audited. MCP tool schemas are declarative but not verified against the implementation — the agent can diverge from its schema.

Hica's effect types are compile-time proof. A function's effect signature IS its capability declaration, and the compiler verifies it matches the implementation. An agent typed with only `network` and `file-read` effects literally cannot delete a file — the compiler rejects it.

Combined with WASM: the compile-time claim becomes a hardware-enforced sandbox.

**Tagline:** *"Build AI agents where the compiler is the security policy."*

Why no one else has this: Python has no effect system. Rust is too hard for agent code. TypeScript has no effects. Haskell has them but is inaccessible. Hica has the right difficulty level AND the effect system.

---

### 2. Typed Edge Scripting ★★★★

Edge compute in 2026 (Cloudflare Workers, Fastly Compute@Edge, WasmEdge, Deno Deploy) wants:
- Small, fast, stateless functions
- No runtime to install
- Sandboxed execution

Current tools: JavaScript (dynamic, no effect guarantees), Python (not WASM-native), Rust (too verbose for scripting), Bash (no types, not portable).

Hica fits precisely: compiles to WASM, no GC, effect types declare what a script touches. Deploy a hica binary to Cloudflare Workers and the edge platform can see from the effect signature: this function only makes outbound HTTP calls and reads environment variables.

**Tagline:** *"Typed scripts for the edge. No runtime. No surprises."*

---

### 3. Typed Workflow Choreography ★★★★★

This is the most differentiated angle — and it connects directly to Choreo.

Choreo (https://github.com/cladam/choreo) is a BDD test runner for CLI/API interactions. It uses a `feature → scenario → test { given / when / then }` structure with typed actors (Terminal, FileSystem, Web, System) and stateful dependencies between tests (`Test has_succeeded X`).

What choreo implicitly models:
- **State machines**: `given` = precondition, `when` = trigger, `then` = post-state
- **Actor choreography**: multiple systems interacting in a typed sequence
- **Dependency graphs**: steps depend on prior steps (forming a DAG)

**The leap**: what if this model moved from *testing* to *production*?

Hica could be the language where you define system workflows as explicit, typed state machines — and the compiler proves they're correct before they run.

---

## Deep dive: Typed Workflow Choreography

### From Choreo to Hica Choreography

| Choreo today | Hica choreography vision |
|---|---|
| BDD test runner | Behavioral workflow specification + execution |
| `.chor` files interpreted at runtime | `.hc` files compiled to WASM |
| `given/when/then` for assertions | `state/on/transition` for production workflows |
| Terminal, FileSystem, Web actors | Any effect-typed actor (DB, queue, network, vault) |
| `Test has_succeeded X` dependencies | Typed state transitions verified by compiler |
| Runtime assertion failures | Compile-time state machine consistency checks |
| JSON test reports | Typed execution traces / audit logs |
| Rust binary + interpreter | WASM binary, runs on any edge runtime |

### What the language could look like

```hica
// Actors declare their effect types
actor Database {
  read: db-read
  write: db-write
}

actor Http {
  call: network
}

// States are types — the compiler tracks valid transitions
type DeployState {
  Idle
  Deploying
  Healthy
  Degraded
  RolledBack
}

// A workflow is a state machine: each step has typed preconditions and effects
workflow DeployService {

  step StartDeploy : Idle -> Deploying {
    given: state is Idle
    when:
      Http call "POST /deploy" with artifact
    then:
      state becomes Deploying
  }

  step HealthCheck : Deploying -> Healthy | Degraded {
    given: state is Deploying
    when:
      Http call "GET /health"
    then:
      on 200 => state becomes Healthy
      on _   => state becomes Degraded
  }

  step Rollback : Degraded -> RolledBack {
    given: state is Degraded
    when:
      Http call "POST /rollback"
    then:
      state becomes RolledBack
  }
}
```

The compiler:
- Rejects transitions to undefined states
- Proves which effects each step uses (no hidden DB writes in a "read-only" step)
- Checks there are no dead states (states with no valid exit transition)
- Emits a WASM binary that runs anywhere with zero dependencies

### Why this is differentiated

**GitHub Actions YAML**: YAML is untyped. Any step can do anything. No actor model, no state machine, no effect checking.

**Temporal/Durable Functions**: Python or TypeScript SDKs. No effect tracking. Runtime errors, not compile-time proofs. Requires running a Temporal cluster.

**TLA+/Alloy**: Formal spec tools that don't execute. Hica specs run.

**Choreo**: Test runner, not production runtime. No type system for effects.

Hica would be the only language where:
1. Workflows are typed state machines verified by the compiler
2. Each step's capabilities are declared as effects (no hidden side effects)
3. The output is a WASM binary that runs on any modern edge runtime
4. The syntax is readable enough for non-compiler-experts

### Concrete use cases

**CI/CD pipeline definition** — Replace GitHub Actions YAML with typed hica choreography. The compiler catches: "this build step declares no network effects but calls npm install."

**API gateway policies** — "If auth fails → redirect to login; if rate limited → 429; otherwise → forward." Stateful, typed, compiled to WASM for Cloudflare Workers.

**Health check + failover** — "Poll endpoint, if degraded for 3 consecutive checks → switch traffic to standby." Express as a state machine in hica, deploy to edge.

**Webhook processor** — receive → validate → transform → emit → audit. Typed effects prove the handler only calls exactly what it declared.

**Deployment orchestration** — blue/green, canary, rollback — all as a typed state machine where the compiler rejects invalid transitions.

---

## The connection between the two: Edge Scripting + State Machines

These two niches reinforce each other:

- Edge scripting needs *typed*, *sandboxed*, *portable* scripts → hica's effect types + WASM
- Workflow choreography needs *verifiable state machines* that run *anywhere* → hica's type system + WASM
- Both need *no runtime to install* → Perceus / no GC

The compound positioning:

> **Hica is the language for typed workflow choreography at the edge.**
> Write system workflows as state machines. The compiler proves they're correct.
> Deploy to any WASM runtime. No surprises at 3am.

The story also has a natural public origin: "I built Choreo for testing CLI tools. Then we asked: what if the same model proved production workflows correct before they ran?"

---

## Relationship to Choreo

Choreo proved the concept: human-readable scripted system interactions with a typed actor model. It's a great foundation for the idea. The evolution:

- Choreo: *test that your system behaves correctly*
- Hica choreography: *define how your system behaves, compile-time verified, production-ready*

The `.chor` DSL could eventually be a frontend that compiles to hica, or hica could offer a choreo-compatible import mode for testing. Either way, the intellectual lineage is clear and worth documenting publicly — it's a good story.

---

## Recommended next steps

1. **Write one concrete workflow example** in hica syntax (even if the language can't run it yet). Get the syntax right before building the runtime.
2. **Identify the minimum viable effect vocabulary** for edge workflows: `network`, `fs-read`, `fs-write`, `env`, `db-read`, `db-write`, `queue`.
3. **Map choreo's actor model to hica effects** — each choreo actor becomes an effect declaration.
4. **Build a showcase**: a hica workflow that deploys a service, health-checks it, and rolls back on failure — compiled to WASM, running on a local WasmEdge or Cloudflare worker.
5. **Position publicly**: "We built Choreo for testing. Then we wondered: what if the same model proved your production workflows correct?"
