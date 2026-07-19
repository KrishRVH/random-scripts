# PRD: OmniFlow v3 - Rust Mastery+ Edge Data Plane

**Document status:** Replacement PRD and Rust mastery feature-showoff specification  
**Version:** 3.0  
**Date:** 2026-06-08  
**Rust edition:** 2024  
**Core MSRV target:** Rust 1.96 for the full mastery profile  
**Compatibility profile:** A reduced `stable-core` feature set may support an older MSRV only if it does not weaken the mastery evidence  
**Primary audience:** Rust implementer, technical reviewer, project evaluator, and API reviewer  
**Product class:** Edge-to-cloud telemetry ingestion, transformation, durability, and routing data plane

---

## 0. Delta from v2

OmniFlow v2 already covered the main Rust pillars: ownership, lifetimes, traits, GATs, HRTBs, typestate, async, pinning, concurrency, atomics, unsafe, FFI, I/O safety, `no_std`, macros, Cargo, testing, fuzzing, Miri, Loom, benchmarking, and release engineering.

This v3 overhaul turns the project into a broader Rust mastery+ showcase by adding idiomatic, product-relevant uses for the missing or under-specified Rust corners:

1. Custom dynamically sized types for validated topics and payload views.
2. Smart pointer taxonomy: `Box`, `Box<[T]>`, `Box<str>`, `Rc`, `Weak`, `Arc`, `Cow`, `Bytes`, `Pin<Box<T>>`, and intentional `Deref` policy.
3. Advanced iterator and collection APIs: custom iterator families, `IntoIterator`, `FromIterator`, `Extend`, `ExactSizeIterator`, `FusedIterator`, `DoubleEndedIterator`, `RangeBounds`, `Borrow`, map entry APIs, and disjoint mutable access.
4. Trait-object hierarchy design with trait upcasting, scoped `Any` downcasting, and object-safe adapter layers.
5. Async closures and `AsyncFn*` traits for borrowing async pipeline adapters.
6. Newer pattern ergonomics: `let` chains, `if let` match guards, `assert_matches!`, and compile-time parser readability constraints.
7. Attribute-level Rust: `#[must_use]`, `#[track_caller]`, `#[cold]`, `#[inline]`, `#[repr(align)]`, `#[used]`, unsafe attributes, and diagnostics hints.
8. DST, unsizing, fat-pointer, and coercion literacy without depending on unstable `CoerceUnsized` implementations.
9. Stronger layout, validity, provenance, unaligned-read, niche-optimization, and `repr` policy.
10. Real uses for `MaybeUninit`, `ManuallyDrop`, `NonNull`, `Layout`, `UnsafeCell`, `&raw`, and raw-pointer APIs.
11. FFI edge cases: opaque handles, tagged unions, nullable pointer conventions, `CStr`, `CString`, `OsStr`, `extern "C-unwind"` policy, variadic C functions in labs, and plugin descriptor sections.
12. `std::io` and async I/O traits: `Read`, `Write`, `BufRead`, `Seek`, `IoSlice`, `IoSliceMut`, `AsyncRead`, and `AsyncWrite`.
13. Thread-local scratch, scoped threads, local `!Send` task execution, poisoning strategy, unwind-safety policy, and cache-line padding.
14. Cargo feature topology, `dep:` feature hygiene, mutually exclusive features, custom `cfg` checking, build-script contracts, generated headers, and docs feature surfacing.
15. Labs-only demonstrations for unstable or very niche features: specialization, trait aliases, generic const expressions, allocator API, custom `Try`, async generators/coroutines, portable SIMD, inline assembly, naked functions, custom lock-free primitives, and external types.

The core rule remains unchanged: advanced Rust must serve the data plane. If a feature cannot be tied to a real subsystem, it belongs in `omniflow-labs` or is explicitly rejected.

---

## 1. Product summary

OmniFlow is a production-shaped Rust data plane for telemetry, events, logs, and lightweight edge data. It accepts data over HTTP, MQTT, files, local Unix/Windows resources, and an embedded Rust SDK. It validates and decodes records, applies typed transformation pipelines, persists accepted records to a write-ahead log when configured, enforces bounded resource usage, runs sandboxed and native plugins, and forwards records to sinks.

OmniFlow is also a Rust mastery capstone. The repository must demonstrate stable production Rust plus carefully isolated labs for unstable or very niche language surfaces. The final implementation should read like a serious data-plane system whose design is shaped by Rust rather than a list of disconnected language demos.

The project must not use Rust features as decorations. Every advanced feature must have:

1. A real product use.
2. A simpler alternative considered.
3. A reason the chosen design is worth its complexity.
4. Tests, docs, benchmarks, or verification evidence.
5. A location in `docs/rust-mastery-map.md`.

---

## 2. Product thesis

OmniFlow proves Rust mastery only if the final repository supports this claim:

> This is a useful edge data-plane system whose API design, concurrency model, persistence layer, plugin boundary, embedded SDK, unsafe boundaries, macro tooling, and release discipline are shaped by Rust's ownership, type, async, layout, ABI, and tooling models. Advanced Rust is used narrowly, documented explicitly, and validated with compile-time tests, runtime tests, property tests, fuzzing, Miri, Loom, benchmarks, and code-review artifacts.

The mastery signal is not maximal syntax coverage. The mastery signal is restraint plus depth: sophisticated Rust where it buys correctness, performance, portability, or API clarity.

---

## 3. Product goals

OmniFlow must:

1. Accept telemetry over HTTP, MQTT, file input, local CLI input, and the Rust SDK.
2. Support JSON Lines and a compact binary frame format.
3. Apply configurable transformations, filters, enrichers, and routing rules.
4. Provide both static compile-time pipelines and runtime dynamic pipelines.
5. Support typed topic filters and validated topic strings without allocation where practical.
6. Enforce bounded memory and bounded work under overload.
7. Use fallible allocation, preallocation, and admission control in hot paths.
8. Persist accepted records before acknowledgment when WAL mode is enabled.
9. Replay durable but uncommitted records after restart.
10. Support sandboxed WASM plugins and native C ABI plugins.
11. Provide a `no_std` plus optional `alloc` embedded client SDK.
12. Expose logs, metrics, traces, health, readiness, and diagnostic endpoints.
13. Include repeatable benchmarks, load tests, crash tests, fuzz targets, and verification harnesses.
14. Ship as a reusable workspace with stable public crates, examples, docs, semver policy, MSRV policy, and release gates.
15. Demonstrate Rust's type-system, async, unsafe, ABI, macro, collection, and Cargo edges through product-relevant code.

---

## 4. Rust mastery goals

OmniFlow must demonstrate these stable concepts in production crates:

1. Fundamentals: modules, visibility, structs, enums, pattern matching, functions, methods, tests, docs, examples, doctests.
2. Ownership: moves, borrowing, lifetimes, slices, owned/borrowed APIs, RAII, `Drop`, `Clone`, `Copy`, `Cow`, `Bytes`, and explicit clone-cost documentation.
3. Smart pointers and DSTs: `Box`, `Box<[T]>`, `Box<str>`, `Arc`, `Weak`, `Rc`, `Pin<Box<T>>`, custom DSTs, fat-pointer semantics, unsized coercions through standard pointer types, and disciplined `Deref`.
4. API design: newtypes, validated types, `TryFrom`, `FromStr`, `AsRef`, `AsMut`, `Borrow`, `ToOwned`, `Default`, `Display`, `Debug`, `Error::source`, and typed errors.
5. Collections and iterators: custom iterator structs, `IntoIterator` for owned and borrowed forms, `FromIterator`, `Extend`, `ExactSizeIterator`, `FusedIterator`, `DoubleEndedIterator`, `try_fold`, `ControlFlow`, `RangeBounds`, `Entry`, and heterogenous lookup.
6. Type system: traits, associated types, associated consts, default generic parameters, const generics, GATs, HRTBs, RPITIT, async fn in traits for static dispatch, typestate, sealed traits, variance-aware `PhantomData`, and auto-trait control through fields.
7. Dispatch: monomorphized static paths, `impl Trait`, `dyn Trait`, trait upcasting, object-safe adapters, scoped `Any`/`TypeId` extension storage, type erasure where justified, and clear dyn-compatibility docs.
8. Async: async/await, async closures, `AsyncFn*`, `IntoFuture`, cancellation, manual `Future`/`Stream`, `Poll`, `Context`, `Waker`, `Pin`, true `!Unpin`, projection, task ownership, and local `!Send` execution.
9. Concurrency: bounded channels, semaphores, threads, scoped threads, `Send`, `Sync`, `Arc`, `Mutex`, `RwLock`, atomics, memory orderings, `OnceLock`, `LazyLock`, thread-local storage, and Loom validation.
10. Interior mutability: `Cell`, `RefCell`, `Mutex`, `RwLock`, `OnceLock`, `LazyLock`, and `UnsafeCell` only inside audited custom primitives or labs.
11. Allocation discipline: `try_reserve`, preallocation, `Layout`, global allocator tests, allocation budgets, RAII reservations, bounded collections, and no unbounded hot-path growth.
12. Unsafe Rust: raw pointers, `NonNull`, raw slice creation, `MaybeUninit`, `ManuallyDrop`, `repr(C)`, `repr(transparent)`, `repr(u*)`, `repr(align)`, unions when C ABI requires them, unsafe traits, pointer provenance, alignment, aliasing, invalid values, panic safety, and explicit unsafe blocks inside unsafe functions.
13. FFI and ABI: C ABI, `unsafe extern`, unsafe exported attributes, `CStr`, `CString`, `OsStr`, dynamic loading, opaque handles, tagged unions, allocation/free contracts, panic/unwind boundaries, ABI versioning, and generated C headers.
14. I/O safety: `OwnedFd`, `BorrowedFd`, `AsFd`, `OwnedHandle`, `BorrowedHandle`, `AsHandle`, raw descriptor quarantine, vectored I/O, and sync abstractions.
15. Portability: `no_std`, `alloc`, `core`, conditional compilation, target cfg, `target_has_atomic`, cross-compilation, OS-specific behavior, endian/layout policy, and panic strategy.
16. Macros: `macro_rules!`, proc-macro derives, attribute macros, hygiene, span diagnostics, edition-2024 macro fragment behavior, generated unsafe routing, compile-fail tests, and expansion snapshots.
17. Attributes and diagnostics: `#[must_use]`, `#[track_caller]`, `#[cold]`, `#[inline]`, `#[deprecated]`, `#[non_exhaustive]`, `#[diagnostic::do_not_recommend]`, `#[used]`, `#[unsafe(link_section)]`, and lint expectation policy.
18. Cargo and ecosystem: workspaces, resolver v3, MSRV-aware resolution, feature flags, optional dependencies, build scripts, `cargo:rustc-check-cfg`, examples, benches, docs, semver, release automation, and supply-chain checks.
19. Verification and performance: unit tests, integration tests, doctests, trybuild, proptest, fuzzing, Miri, Loom, sanitizers, Criterion, flamegraphs, allocation counters, cargo-deny/audit, cargo-semver-checks, and manual chaos/load tests.

Labs-only concepts may be demonstrated, but production crates must not depend on them unless they become stable and pass the same product-use bar.

---

## 5. Non-goals

OmniFlow must not:

1. Build a custom async runtime.
2. Add unsafe code when safe Rust meets the target within an acceptable measured envelope.
3. Build a custom lock-free queue in production crates unless safe bounded channels are proven insufficient and the replacement is Loom-verified, Miri-audited where possible, and benchmarked under realistic workloads.
4. Depend on Rust's unstable native ABI for runtime plugins.
5. Require nightly Rust for core crates.
6. Turn the project into a general ETL platform, visual workflow editor, database, distributed consensus system, or cloud service.
7. Treat experimental Rust features as core requirements.
8. Hide advanced concepts in toy examples that do not affect real behavior.
9. Use `Deref` as inheritance or `Index` for fallible public lookups.
10. Transmute wire or disk bytes into Rust structs.
11. Rely on unspecified `repr(Rust)` layout outside compiler-managed Rust-only memory.
12. Use pointer-integer roundtrips as a persistence or identity mechanism.
13. Expose plugin APIs that require Rust-to-Rust dynamic ABI stability.
14. Accept feature soup without proof of benefit.

---

## 6. Target users

### 6.1 Edge operator

Runs OmniFlow near devices or applications and needs bounded memory, durable buffering, replay after restart, clear operational telemetry, and predictable overload behavior.

### 6.2 Platform engineer

Embeds OmniFlow libraries into services and wants stable APIs, strong error types, predictable feature flags, configurable performance tradeoffs, and documented semver behavior.

### 6.3 Embedded developer

Uses the SDK from constrained devices and wants fixed-capacity event construction, binary encoding, optional heap use, `panic = abort` compatibility, and no accidental `std` dependency.

### 6.4 Plugin author

Writes filters and transformations in WASM or native code and wants a stable plugin contract, clear ownership rules, panic containment, ABI versioning, and safe failure behavior.

### 6.5 Rust reviewer

Evaluates whether the repository demonstrates deep Rust knowledge through idiomatic design, compile-time guarantees, safety documentation, verification tooling, and measured tradeoffs.

---

## 7. Design principles

1. **Useful first.** The product must work as a real local telemetry gateway.
2. **Stable core, isolated labs.** Production crates use stable Rust. Nightly, unstable, compiler-internal, or architecture-specific experiments stay in `omniflow-labs`.
3. **Safe by default.** Most crates forbid unsafe code. Unsafe crates isolate it and document invariants.
4. **Rust 2024 mainline.** Core crates use `edition = "2024"`; the workspace uses resolver v3.
5. **No accidental unboundedness.** Queues, buffers, plugin memory, WAL segments, retry loops, metric cardinality, and temporary collections have explicit limits.
6. **Borrowed where useful, owned where necessary.** APIs support zero-copy paths without making common usage painful.
7. **Static and dynamic paths are distinct.** Static pipelines optimize for type information and borrowing. Dynamic pipelines optimize for runtime composition and plugin loading.
8. **Trait objects are designed, not incidental.** Every `dyn Trait` API must document object-safety constraints, auto-trait bounds, and lifetime requirements.
9. **Unsafe is a contract.** Unsafe APIs and blocks state invariants, caller/callee responsibilities, and validation coverage.
10. **Cancellation is a normal path.** Dropping futures or stopping tasks must not corrupt WAL state, leak plugin handles, or lose admitted records.
11. **Performance claims require measurement.** Benchmarks include allocation counts, latency percentiles, throughput, CPU, and RSS under overload.
12. **Attribute use is policy-driven.** Attributes such as `inline`, `cold`, `track_caller`, `repr`, `must_use`, and unsafe exported attributes require a reason.
13. **Feature flags are part of the API.** Feature names, optional dependencies, and cfg combinations must be tested and documented.
14. **Labs teach without contaminating core.** Labs can be deliberately esoteric, but must not become a dumping ground for unsound or undocumented code.

---

## 8. Workspace architecture

```text
omniflow/
  Cargo.toml
  crates/
    omniflow-core/
    omniflow-codec/
    omniflow-routing/
    omniflow-pipeline/
    omniflow-server/
    omniflow-cli/
    omniflow-sdk/
    omniflow-wal/
    omniflow-io/
    omniflow-alloc/
    omniflow-plugin-api/
    omniflow-plugin-wasm/
    omniflow-plugin-cabi/
    omniflow-observability/
    omniflow-macros/
    omniflow-testkit/
    omniflow-labs/
  examples/
    beginner-file-ingest/
    static-pipeline/
    async-closure-pipeline/
    dynamic-plugin-wasm/
    native-plugin-cabi/
    embedded-no-std/
    local-plugin-thread-affinity/
  benches/
  fuzz/
  xtask/
  docs/
```

### 8.1 Crate responsibilities

| Crate | Purpose | Rust focus |
|---|---|---|
| `omniflow-core` | Event IDs, timestamps, validated topic DSTs, payload views, attributes, shared errors, feature-neutral primitives | ownership, borrowing, lifetimes, custom DSTs, `NonZero*`, `Cow`, `Bytes`, `Box<str>`, `Box<[T]>`, `no_std`, `alloc` |
| `omniflow-codec` | JSONL, binary frame, optional CBOR/MessagePack, parsing and encoding | slices, lifetimes, `TryFrom`, endian policy, `MaybeUninit`, `assert_matches!`, fallible allocation, fuzzing |
| `omniflow-routing` | Topic matching, routing tables, sink selection, route reload snapshots | custom iterators, `Borrow`, `Hash`, `RangeBounds`, `Entry`, `get_disjoint_mut`, `Arc`, `Weak` |
| `omniflow-pipeline` | Static and dynamic stage execution | traits, GATs, HRTBs, RPITIT, async closures, trait upcasting, typestate, object-safe adapters |
| `omniflow-server` | Async HTTP/MQTT daemon, backpressure, shutdown | async/await, manual polling, `IntoFuture`, cancellation, `Send`/`Sync`, local `!Send` tasks, channels, semaphores |
| `omniflow-cli` | User CLI and admin commands | config, typed errors, source chains, `Path`/`OsStr`, snapshot tests, `track_caller` test helpers |
| `omniflow-sdk` | Embedded/event client SDK | `no_std`, `alloc`, const generics, fixed-capacity buffers, `MaybeUninit` arrays, target cfg |
| `omniflow-wal` | Durable append, checkpoint, replay, inspection | RAII, `Drop`, mmap, I/O safety, `NonNull`, provenance, alignment, `Layout`, panic safety |
| `omniflow-io` | OS file-descriptor/handle wrappers and fsync/vectored I/O abstractions | `OwnedFd`, `BorrowedFd`, `AsFd`, Windows handles, raw descriptor quarantine, `IoSlice` |
| `omniflow-alloc` | Allocation budgets and failing-allocator test helpers | `try_reserve`, `Layout`, `GlobalAlloc` tests, admission guards, `#[must_use]` |
| `omniflow-plugin-api` | Plugin types and stable host/plugin contract | sealed traits, trait upcasting hierarchy, ABI-neutral model, `Any`, semver |
| `omniflow-plugin-wasm` | WASM runtime host and sandbox limits | resource limits, dynamic dispatch, async boundary, bounded memory, errors |
| `omniflow-plugin-cabi` | Native plugin loader and C ABI shims | `repr(C)`, `repr(transparent)`, unions, `unsafe extern`, unsafe attrs, C strings, `ManuallyDrop`, panic safety |
| `omniflow-observability` | Logs, metrics, traces, health reports | `tracing`, atomics, `repr(align)`, `OnceLock`, `LazyLock`, thread-local shards, exporters |
| `omniflow-macros` | Pipeline DSL and plugin/stage derives | `macro_rules!`, proc macros, hygiene, spans, edition-2024 fragments, diagnostics, trybuild |
| `omniflow-testkit` | Integration, chaos, compile-fail, fixtures, deterministic clocks | property tests, fixtures, scoped threads, manual poll harness, temporary dirs |
| `omniflow-labs` | Isolated advanced experiments | specialization, trait aliases, generic const expressions, allocator API, custom `Try`, async generators, portable SIMD, inline asm, naked functions, custom lock-free structures |
| `xtask` | Repo automation | Cargo orchestration, generated C headers, docs tables, release checks |

### 8.2 Workspace lint baseline

```toml
[workspace]
resolver = "3"
members = ["crates/*", "xtask"]

[workspace.package]
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"
repository = "https://example.invalid/omniflow"

[workspace.lints.rust]
unsafe_op_in_unsafe_fn = "deny"
missing_docs = "warn"
unreachable_pub = "warn"
unexpected_cfgs = "deny"
static_mut_refs = "deny"
missing_abi = "deny"
never_type_fallback_flowing_into_unsafe = "deny"

[workspace.lints.clippy]
unwrap_used = "warn"
expect_used = "warn"
panic = "warn"
undocumented_unsafe_blocks = "deny"
large_futures = "warn"
large_enum_variant = "warn"
manual_assert = "warn"
```

Crate-specific rules:

1. Most crates set `unsafe_code = "forbid"`.
2. `omniflow-wal`, `omniflow-plugin-cabi`, `omniflow-io`, selected codec optimization modules, and `omniflow-labs` may allow unsafe.
3. `omniflow-labs` may relax selected lints, but it must not be a dependency of production crates.
4. Any `#[allow(...)]` or `#[expect(...)]` must include a reason when the lint supports it.
5. Public crates deny `missing_docs` at release time.

---

## 9. Runtime data flow

```text
Ingress -> Admission -> Decode -> WAL append -> Pipeline -> Sink commit -> WAL checkpoint
             |             |          |             |           |
             v             v          v             v           v
          reject/wait   parse err   durable       transform    retry/dead-letter
```

### 9.1 Acknowledgment rule

If WAL is enabled, an event is acknowledged to the ingress client only after the record is durably appended according to the configured durability policy.

### 9.2 Boundedness rule

An ingress request can only become an admitted event after memory, queue, WAL, and plugin-output budgets have been reserved. Once admitted, the normal hot path must not rely on unbounded infallible allocation.

### 9.3 Ownership rule

Ingress owns bytes initially. The codec produces borrowed `EventRef<'_>` views where possible. Pipeline stages may borrow, transform into owned records, or request explicit allocation from an allocation budget. WAL archived views borrow from mmap-backed segments and never expose raw byte reinterpretation as typed Rust structs.

### 9.4 Lifecycle token rule

State transitions use explicit tokens:

```text
IngressAccepted -> DecodeOk -> WalReserved -> WalAppended -> WalDurable -> SinkCommitted -> Checkpointed
```

Tokens are `#[must_use]`. Dropping an uncommitted token rolls back or releases reservations according to its state. Commit methods consume prior tokens and return the next token.

---

## 10. Functional requirements

## 10.1 CLI

The CLI must support:

```bash
omniflow init
omniflow config validate
omniflow server run
omniflow ingest file ./events.jsonl
omniflow ingest frame ./events.omni
omniflow tail
omniflow wal inspect
omniflow wal replay
omniflow plugin load ./filter.wasm
omniflow plugin load ./target/release/libnative_filter.so
omniflow bench local
omniflow load http --rate 50000 --duration 60s
omniflow chaos kill-restart --iterations 100
```

Rust concepts: modules, structs, enums, pattern matching, `Option`, `Result`, `?`, `Display`, `Debug`, `FromStr`, `Path`, `PathBuf`, `OsStr`, `OsString`, iterators, source chains, snapshot tests.

Requirements:

1. Invalid commands return typed user-facing errors with source chains.
2. Config validation exits nonzero on invalid config.
3. File ingestion uses the same codec and pipeline engine as the server.
4. CLI uses broad error aggregation only at the binary boundary; libraries expose typed errors.
5. Paths are handled as `Path`/`PathBuf` and `OsStr`/`OsString`; lossy UTF-8 conversion is forbidden except for display-only diagnostics.
6. Error constructors used by test fixtures and CLI assertions use `#[track_caller]` where call-site location materially improves diagnostics.
7. CLI parser tests use `assert_matches!` for structured error assertions.

Acceptance criteria:

1. Snapshot tests cover success, validation failure, path encoding edge cases, and plugin-load failure.
2. `omniflow wal inspect` accepts range syntax and validates it without panics.
3. `omniflow ingest file` can run with `--no-wal`, `--wal`, and `--dry-run` modes.

---

## 10.2 Configuration system

Configuration is loaded from TOML, environment variables, and CLI overrides.

Example:

```toml
[server]
bind = "0.0.0.0:8080"
shutdown_grace_ms = 10000
max_inflight_events = 4096
local_plugin_threads = 1

[admission]
max_event_bytes = 1048576
max_batch_events = 512
overflow = "reject"
allocation_budget_bytes = 67108864

[ingress.http]
enabled = true
queue_capacity = 2048

[ingress.mqtt]
enabled = true
broker = "mqtt://localhost:1883"
topics = ["sensor/#", "logs/#"]

[wal]
enabled = true
path = "./data/omniflow.wal"
segment_bytes = 134217728
fsync = "per_batch"
mmap_read = true

[[pipeline.stage]]
kind = "wasm"
path = "./plugins/filter.wasm"

[[pipeline.stage]]
kind = "native"
path = "./target/release/libnative_filter.so"
thread_affinity = "local"

[[sink]]
kind = "http"
url = "http://localhost:9000/ingest"
```

Rust concepts: serde derive, `Default`, `TryFrom`, validated newtypes, non-exhaustive enums, `Cow<'a, str>`, `PathBuf`, `SocketAddr`, `Duration`, feature-gated config sections, `#[serde(borrow)]`, `#[serde(deny_unknown_fields)]`, and typestate validation.

Requirements:

1. Unknown dangerous fields are rejected unless `allow_unknown = true` is explicit and scoped.
2. Config validation reports all independent validation errors when practical.
3. Typestate compile-fail tests prove `run()` cannot be called without ingress and sink configuration.
4. Public config enums are `#[non_exhaustive]` where downstream exhaustive matching would create semver traps.
5. Borrowed deserialization is used for validation-only paths to avoid allocating every string.
6. Owned config snapshots use `Arc<ConfigSnapshot>` and `Arc::make_mut` where copy-on-write reloads are cheaper than rebuilding.
7. Config reload publishes immutable snapshots; running tasks hold `Arc` clones and never borrow from mutable global state.
8. `Weak` backreferences are used only to avoid cycles in diagnostic graphs, not to express required ownership.

Acceptance criteria:

1. Invalid configs produce stable diagnostic snapshots.
2. Reload tests prove old snapshots remain valid until all tasks release them.
3. Compile-fail tests cover missing ingress, missing sink, invalid WAL durability configuration, and stage feature mismatches.
4. Feature-specific config docs are generated from the same source as validation metadata.

---

## 10.3 Event model with validated DSTs

OmniFlow must expose owned, borrowed, archived, and custom-DST event forms.

```rust
#[repr(transparent)]
pub struct TopicStr(str);

pub struct TopicBuf(Box<TopicStr>);

pub struct OwnedEvent {
    id: EventId,
    timestamp: Timestamp,
    topic: TopicBuf,
    payload: bytes::Bytes,
    attributes: AttributeMap,
}

pub struct EventRef<'a> {
    id: EventId,
    timestamp: Timestamp,
    topic: &'a TopicStr,
    payload: &'a [u8],
    attributes: AttributeRef<'a>,
}

pub struct ArchivedEvent<'a> {
    segment: WalSegmentRef<'a>,
    record: WalRecordRef<'a>,
}
```

Design requirements:

1. `TopicStr` is a custom dynamically sized type representing a validated topic string.
2. `TopicBuf` owns a `Box<TopicStr>` or `Arc<TopicStr>` depending on feature and sharing needs.
3. Safe constructors validate topic syntax before producing `&TopicStr`, `Box<TopicStr>`, or `Arc<TopicStr>`.
4. The only unsafe conversion from `str` to `TopicStr` lives in one audited module and relies on `repr(transparent)` over `str`.
5. `TopicBuf` implements `Deref<Target = TopicStr>` only because it is a pointer-like owning type. Non-pointer wrappers must not use `Deref` to simulate inheritance.
6. `TopicBuf` implements `Borrow<TopicStr>` and `AsRef<TopicStr>` so maps keyed by owned topics support borrowed lookup.
7. `EventId` uses a nonzero representation where possible so `Option<EventId>` remains compact.
8. `Timestamp`, `WalOffset`, `RecordIndex`, and `ByteLen` are newtypes. Arithmetic is checked, saturating, or wrapping only when explicitly documented.
9. `OwnedEvent::as_ref()` returns `EventRef<'_>`.
10. `ArchivedEvent<'a>` is a view into WAL bytes and must not outlive the mapped segment.
11. `Clone` cost is documented for all owning types.
12. `Copy` is allowed only for small scalar value types such as IDs, flags, timestamps, offsets, lengths, and enum tags.
13. `Index` is not implemented for user-supplied attributes because missing keys are normal. `get`, `get_required`, and typed accessors are used instead.
14. `Index` may be implemented only for internal fixed tables where all indexes are validated and panic would indicate an internal bug.

Rust concepts: ownership, borrowing, lifetimes, DSTs, fat pointers, slices, `Cow`, `Bytes`, `Box`, `Arc`, `Weak`, `Deref`, `Borrow`, `AsRef`, `ToOwned`, `From`, `TryFrom`, `FromStr`, `NonZeroU64`, niche optimization, `Copy`, `Clone`, `Drop`, `PhantomData`.

Acceptance criteria:

1. Zero-copy decode path exists from binary frame bytes to `EventRef<'_>`.
2. `TopicStr` validation tests cover empty topics, wildcards, UTF-8, separators, maximum lengths, and normalization.
3. Compile-fail tests prevent constructing `TopicStr` without validation.
4. `HashMap<TopicBuf, Route>` supports lookup by `&TopicStr` without allocation.
5. Benchmarks report allocations per event and bytes allocated per event for JSONL, binary borrowed, and binary owned paths.
6. Compile-fail tests prevent archived WAL views from escaping their segment lifetime.
7. `size_of::<Option<EventId>>() == size_of::<EventId>()` is asserted where the representation intends this guarantee.

---

## 10.4 Attribute and metadata model

Attributes must support borrowed wire views, owned maps, typed values, and plugin ABI conversion.

```rust
pub enum AttributeValue<'a> {
    Bytes(&'a [u8]),
    Str(&'a str),
    I64(i64),
    U64(u64),
    F64(f64),
    Bool(bool),
}

pub struct AttributeMap {
    inner: smallvec_or_indexmap::Map<AttributeKeyBuf, OwnedAttributeValue>,
}
```

Requirements:

1. Public Rust APIs expose a typed enum for attributes.
2. Wire and ABI forms do not expose Rust `bool`, `char`, enum layout, or `repr(Rust)` structs.
3. Attribute iteration preserves configured ordering when deterministic output is requested.
4. `IntoIterator` is implemented for `AttributeMap`, `&AttributeMap`, and `&mut AttributeMap` when useful.
5. `Extend` and `FromIterator` are implemented for attribute construction from validated key-value pairs.
6. `try_extend`-like fallible APIs are provided for hot paths where allocation failure is recoverable.
7. Attribute key lookup uses `Borrow<AttributeKeyStr>` or `Borrow<str>` after validation rules are documented.
8. Map mutation uses entry APIs to avoid double lookup.
9. Pairwise route or attribute updates use disjoint mutable access where available instead of unsafe aliasing.

Rust concepts: enum layout discipline, iterators, `IntoIterator`, `FromIterator`, `Extend`, `Borrow`, `Entry`, fallible allocation, typed values, semver-safe enums.

Acceptance criteria:

1. Attribute roundtrip tests cover borrowed, owned, and ABI forms.
2. No public attribute accessor panics on missing user data.
3. Benchmarks compare borrowed attribute iteration, owned map construction, and plugin ABI conversion.
4. Fuzzing covers malformed keys and invalid typed values.

---

## 10.5 Codec and parser layer

OmniFlow supports:

1. JSON Lines for human-readable ingestion.
2. Binary frames for high-throughput ingestion.
3. Optional CBOR or MessagePack behind feature flags.

Binary frame v1:

```text
magic:       u32  little-endian, fixed value
version:     u16  little-endian
flags:       u16  little-endian
topic_len:   u16  little-endian
attr_len:    u32  little-endian
payload_len: u32  little-endian
header_crc:  u32  little-endian
topic:       [u8; topic_len]
attributes:  [u8; attr_len]
payload:     [u8; payload_len]
body_crc:    u32  little-endian
```

Parser requirements:

1. No parser may panic on arbitrary bytes.
2. No wire or disk bytes may be blindly `transmute`d into Rust structs.
3. Endian, alignment, padding, and validity rules are stated in `docs/wire-format.md`.
4. Fast paths may use unsafe only behind a feature flag after a safe baseline exists.
5. All buffer growth uses `try_reserve` or an admission budget on hot paths.
6. Unaligned data uses explicit byte parsing or `read_unaligned` only inside audited unsafe wrappers.
7. Pattern-heavy parsing uses `let else`, `let` chains, and `if let` guards where they make parser states clearer.
8. Tests use `assert_matches!` for structured error validation rather than fragile string matching.
9. `MaybeUninit` is permitted only for batch initialization or parser scratch buffers where safe initialization would cause measured overhead.
10. Unsafe parser helpers must use `&raw const` or `addr_of!` instead of creating references to unaligned or uninitialized fields.
11. `ControlFlow` and `Iterator::try_fold` are used for early-exit validation when they reduce branching complexity.
12. `#[cold]` is allowed for rare error-construction paths after measurement or readability justification.
13. `#[inline]` and `#[inline(always)]` require benchmark evidence or cross-crate abstraction justification.

Rust concepts: slices, lifetimes, `let else`, `let` chains, `if let` guards, `TryFrom<&[u8]>`, custom error enums, parser state machines, `MaybeUninit`, endian policy, `&raw`, pointer/alignment discipline, `ControlFlow`, fuzzing.

Acceptance criteria:

1. Fuzz target `frame_decode` runs against arbitrary input.
2. Proptest verifies encode/decode roundtrips.
3. Corpus includes truncated frames, malicious lengths, invalid UTF-8 topics, wrong CRCs, maximum-size frames, and mixed-version frames.
4. Benchmarks compare JSONL, binary safe parser, and optional optimized parser.
5. Miri tests cover unsafe parser helpers if any exist.
6. Parser tests assert exact structured variants with `assert_matches!`.
7. `docs/patterns-in-parsers.md` explains when pattern syntax improved clarity and when explicit matches were retained.

---

## 10.6 Allocation and admission control

OmniFlow must treat allocation failure and overload as expected system conditions.

Requirements:

1. Admission reserves event, batch, queue, WAL, and plugin-output capacity before acknowledging work.
2. Hot-path `Vec`, `VecDeque`, `BytesMut`, `String`, and map growth uses `try_reserve` or preallocated slabs where practical.
3. Batch decoding caps batch length, aggregate byte size, and output expansion ratio.
4. Plugin output has hard byte and event-count budgets.
5. Retry queues and dead-letter queues are bounded.
6. Tests include a failing global allocator in selected crates.
7. OOM-like allocation refusal is reported as a typed overload/resource error, not a panic, wherever recovery is possible.
8. `std::alloc::Layout` is used in test allocators, WAL slab planning, and FFI allocation contracts.
9. RAII reservation guards are `#[must_use]`; dropping without commit releases capacity.
10. `mem::take`, `mem::replace`, and `Option::take` are preferred for safe state extraction during cancellation and shutdown.
11. `Box<[T]>` is used for immutable route snapshots and replay batches after final size is known.
12. `Box::leak` is allowed only for process-lifetime metric names or test fixtures and must be documented as intentional.
13. `ManuallyDrop` is allowed only in FFI/resource transfer code where normal `Drop` would double-free or prematurely free after ownership transfer.

Rust concepts: fallible allocation, `TryReserveError`, `Layout`, `GlobalAlloc`, `Box<[T]>`, `VecDeque`, RAII guards, `Drop` rollback, `mem::take`, `Option::take`, `ManuallyDrop`, bounded collections, backpressure.

Acceptance criteria:

1. Load tests prove RSS remains within configured bounds under sustained overload.
2. Unit tests inject allocation failure into parser, batcher, WAL, config reload, and plugin-output paths.
3. Admission tokens are released on early return, panic during test hooks, cancellation, and sink failure.
4. Metrics expose admission accepted/rejected/waited, reserved bytes, in-use bytes, and allocation failures.
5. Miri covers FFI ownership-transfer helpers that use `ManuallyDrop` or raw ownership conversions.
6. No production hot path calls `reserve` where `try_reserve` is practical.

---

## 10.7 Routing, iterators, and collection design

Routing must demonstrate idiomatic collection and iterator design rather than hiding everything behind `Vec` and ad hoc loops.

Conceptual APIs:

```rust
pub struct RouteTable {
    routes: Arc<[Route]>,
    index: HashMap<TopicBuf, RouteId>,
}

impl RouteTable {
    pub fn routes(&self) -> Routes<'_>;
    pub fn matching<'a>(&'a self, topic: &'a TopicStr) -> MatchingRoutes<'a>;
    pub fn inspect_range<R>(&self, range: R) -> RouteRange<'_>
    where
        R: RangeBounds<RouteIndex>;
}
```

Requirements:

1. Immutable route snapshots are stored as `Arc<[Route]>` or `Box<[Route]>`, not `Vec`, after construction is complete.
2. Route lookup maps support borrowed lookup by `&TopicStr` or validated key references.
3. Route builders use `FromIterator`, `Extend`, and fallible extension APIs.
4. Iterators expose exact guarantees: `ExactSizeIterator` only when exact length is cheap and correct; `FusedIterator` only when post-`None` behavior is guaranteed; `DoubleEndedIterator` only for naturally bidirectional storage.
5. `RangeBounds<RouteIndex>` supports CLI and API inspection without forcing callers to allocate ranges.
6. `HashMap::entry` or equivalent entry APIs are used for normalization and duplicate handling.
7. Disjoint mutable access is used for safe simultaneous mutation of distinct routes or sink counters.
8. `try_fold` is used for fallible route validation and early exit.
9. `ControlFlow` is used for visitor-style inspection when stopping early is normal behavior.
10. Closure adapters cover `Fn`, `FnMut`, and `FnOnce` correctly; mutable closures are not accidentally shared across threads.
11. Internal route IDs are newtypes, not bare `usize`.
12. `Index<RouteIndex>` is internal-only and documented as panic-on-bug; public APIs return `Option` or typed errors.

Rust concepts: `Arc<[T]>`, `Box<[T]>`, custom iterators, `IntoIterator`, `FromIterator`, `Extend`, `ExactSizeIterator`, `FusedIterator`, `DoubleEndedIterator`, `RangeBounds`, `Borrow`, `Hash`, `Entry`, `get_disjoint_mut`, `try_fold`, `ControlFlow`, closure traits.

Acceptance criteria:

1. Route table APIs are allocation-free for borrowed lookup.
2. Iterator law tests verify size hints, fused behavior, double-ended ordering, and empty edge cases.
3. Property tests compare optimized routing against a simple reference implementation.
4. Benchmarks compare static route snapshots against dynamic route maps under reload.
5. Compile-fail tests reject mixing raw indexes from different domains.

---

## 10.8 Pipeline engine

OmniFlow supports two pipeline modes:

1. **Static pipeline:** compile-time known stages, monomorphized, allocation-minimal, best for embedded and high-throughput deployments.
2. **Dynamic pipeline:** runtime-loaded stages through object-safe adapters, best for plugins and operator-defined pipelines.

### 10.8.1 Static synchronous stage

```rust
pub trait Stage {
    type Error;

    fn name(&self) -> &'static str;

    fn process<'a>(
        &'a self,
        event: EventRef<'a>,
        budget: &'a mut AllocationBudget,
    ) -> Result<StageResult<'a>, Self::Error>;
}
```

### 10.8.2 Lending stage with GAT

```rust
pub trait LendingStage {
    type Output<'a>
    where
        Self: 'a;

    type Error;

    fn process<'a>(
        &'a self,
        event: EventRef<'a>,
    ) -> Result<Self::Output<'a>, Self::Error>;
}
```

### 10.8.3 Static async stage using async fn in traits

```rust
pub trait AsyncStage {
    type Error;

    async fn process_async<'a>(
        &'a self,
        event: EventRef<'a>,
        cx: StageContext<'a>,
    ) -> Result<OwnedEvent, Self::Error>;
}
```

### 10.8.4 Async closure adapter

```rust
pub fn async_filter<F>(name: &'static str, f: F) -> AsyncFilter<F>
where
    F: for<'a> AsyncFn(EventRef<'a>) -> bool + Send + Sync + 'static;
```

The async closure adapter exists because borrowed async closures can borrow from their captures and from the event argument without forcing an owned event at every filter boundary.

### 10.8.5 Dyn-compatible adapter

```rust
pub trait DynStage: StageBase + Send + Sync {
    fn name(&self) -> &str;

    fn process_boxed(
        &self,
        event: OwnedEvent,
        budget: &mut AllocationBudget,
    ) -> Result<Vec<OwnedEvent>, StageError>;
}

pub trait StageBase: Any {
    fn stage_kind(&self) -> StageKind;
}

pub trait InspectableStage: DynStage {
    fn inspect(&self) -> StageInspection<'_>;
}
```

Design requirements:

1. GAT/lending stages are used only where borrowed output materially reduces allocation.
2. Async trait methods are allowed for static dispatch but require object-safe boxed-future adapters for dynamic dispatch.
3. Runtime plugin stages use `DynStage`, not a GAT or `async fn` trait directly.
4. Closures can be adapted into stages via blanket impls where trait coherence permits.
5. Async closures and `AsyncFn*` are used for static filters/enrichers that borrow event data across awaits.
6. Trait upcasting is used for `&dyn InspectableStage -> &dyn DynStage -> &dyn StageBase` and for scoped `Any` downcasting in diagnostics.
7. `Any`/`TypeId` type-erasure is allowed only for explicitly scoped extension storage, diagnostics, and test fixtures, not general business logic.
8. Blanket impls that create confusing diagnostics may use `#[diagnostic::do_not_recommend]` when it produces clearer user errors.
9. Trait object public APIs must spell out auto-traits and lifetimes, for example `Box<dyn DynStage + Send + Sync + 'static>`.
10. Non-`Send` stages are supported only in explicitly local pipelines or local plugin executors.
11. `impl Trait` return APIs are used for static builder combinators; public type aliases to opaque impl traits stay labs-only unless stabilized and justified.

Rust concepts: traits, associated types, associated consts, GATs, HRTBs, `impl Trait`, RPITIT, async fn in traits, async closures, `AsyncFn`, object safety/dyn compatibility, `dyn Trait`, trait upcasting, blanket impls, sealed traits, type erasure, `Any`, `TypeId`, allocation budgeting.

Acceptance criteria:

1. Static pipeline benchmark shows lower allocation than dynamic pipeline for borrowed transforms.
2. Async closure pipeline example filters records by querying an async metadata cache without forcing an owned event before the filter.
3. Dynamic pipeline supports runtime plugin loading.
4. Docs explain the static async trait path versus object-safe boxed adapter path.
5. Compile-fail tests prove non-dyn-compatible traits are not exposed as plugin trait objects.
6. Trait upcasting tests prove inspection APIs do not require ad hoc forwarding methods.
7. Diagnostic tests verify blanket impl hints do not recommend internal marker traits to users.

---

## 10.9 Typestate lifecycle

Pipeline lifecycle uses typestate to prevent invalid states.

Example states:

```rust
PipelineBuilder<NoIngress, NoWal, NoSink>
PipelineBuilder<HasIngress, WalConfigured, HasSink>
RunningPipeline
DrainingPipeline
StoppedPipeline
```

Requirements:

1. `.run()` is unavailable until ingress and sink are configured.
2. WAL acknowledgment is unavailable before durable append.
3. Plugin unload is unavailable while a running pipeline holds references to plugin symbols.
4. Checkpoint commit is unavailable until sink commit succeeds.
5. State markers are zero-sized or uninhabited and sealed where external implementation would be unsound.
6. `PhantomData` encodes state, lifetimes, variance, and auto-trait effects deliberately.
7. `PhantomData<Rc<()>>` or equivalent fields make thread-affine handles `!Send`/`!Sync` without relying on unstable negative impls.
8. `PluginSymbol<'lib, T>` is lifetime-bound to the loaded library handle and cannot outlive it.
9. Builder methods are `#[must_use]` so ignored state transitions are caught by lints.
10. Typestate is used only where it removes real runtime failure modes; dynamic user config still returns runtime validation errors.

Rust concepts: generics, default type parameters, `PhantomData`, zero-sized types, uninhabited marker types, sealed traits, compile-time state machines, variance markers, auto-trait control, ownership of lifecycle tokens.

Acceptance criteria:

1. `trybuild` tests cover invalid state transitions.
2. Runtime lifecycle errors exist only for genuinely dynamic conditions.
3. State transition docs include the simpler runtime-check alternative and why typestate is worth it here.
4. Compile-fail tests prove thread-affine plugin handles cannot be sent to worker threads.
5. Compile-fail tests prove plugin symbols cannot outlive loaded libraries.

---

## 10.10 Async server, cancellation, and backpressure

The server accepts HTTP and MQTT ingestion, handles shutdown, and coordinates WAL, pipeline, plugins, and sinks.

Endpoints:

```text
POST /ingest
POST /ingest/batch
GET  /healthz
GET  /readyz
GET  /metrics
GET  /debug/pipeline
GET  /debug/tasks
```

Shutdown phases:

1. Stop accepting new ingress.
2. Notify producers and plugin hosts.
3. Stop creating new admitted work.
4. Drain bounded queues until deadline.
5. Flush and sync WAL according to durability policy.
6. Finish or cancel sink commits according to idempotency guarantees.
7. Release plugin handles only after no stage references remain.
8. Emit final metrics and exit.

Requirements:

1. Request handlers reserve resources before expensive work.
2. Dropping a request future midway releases uncommitted reservations.
3. `JoinSet` or equivalent task management tracks owned tasks.
4. Local `!Send` plugin work runs on a dedicated local executor/thread and communicates over bounded channels.
5. `IntoFuture` may be implemented for a start token or run handle only if it improves ergonomics without hiding lifecycle state.
6. Manual `Future`/`Stream` implementations are limited to framed ingress, deterministic tests, or adapters that cannot be expressed clearly with async blocks.
7. `Waker::noop` is used in deterministic poll tests; custom `RawWaker` is labs-only unless required.
8. `Arc` is used for shared immutable stage state; `Rc` is allowed only for single-threaded local graphs and tests.
9. Mutex poisoning policy is explicit: recover, replace state, or abort the subsystem depending on data criticality.
10. `catch_unwind` is used around native plugin calls, not around arbitrary application logic.
11. `AssertUnwindSafe` requires a safety note explaining why contained state remains valid after panic.
12. Backpressure outcomes are typed: reject, wait, shed low-priority, sample, or close ingress.

Rust concepts: async/await, async closures, `Future`, `IntoFuture`, `Stream`, `select!`, cancellation tokens, `JoinSet`, bounded channels, semaphores, `Arc`, `Rc`, `Send`, `Sync`, local task sets, `Waker`, `UnwindSafe`, `AssertUnwindSafe`, `catch_unwind`.

Acceptance criteria:

1. SIGTERM exits cleanly and deterministically.
2. Dropping a request future midway does not leave an admitted record half-owned or half-acked.
3. Overload returns `429`, waits, samples, or sheds low-priority records according to configuration.
4. Integration tests cover cancellation during decode, WAL append, plugin call, sink retry, and shutdown.
5. Metrics expose queue depth, wait time, rejections, cancellation count, local plugin queue depth, and shutdown phase durations.
6. Compile-fail tests prove local plugin futures are not spawned onto multithreaded executors.

---

## 10.11 Custom `!Unpin` framed stream

Implement a custom framed stream that demonstrates pinning for real, not by requiring all fields to be `Unpin`.

Conceptual type:

```rust
pub struct FramedIngress<R> {
    reader: R,
    buffer: BytesMut,
    state: DecodeState,
    _pin: core::marker::PhantomPinned,
}
```

Requirements:

1. The primary implementation must support `R` that is not `Unpin`.
2. Field projection uses a projection helper crate unless manual unsafe projection is justified and audited.
3. Documentation explains which fields are structurally pinned and which are not.
4. Compile-fail tests prove pinned values cannot be moved after pinning.
5. Cancellation tests drop the stream while a partial frame is buffered.
6. The design explicitly avoids self-referential structs unless pinning and projection invariants are fully documented.
7. `Pin<Box<T>>` is used when heap pinning is needed for dynamic stream storage.
8. Manual `poll_next` follows `Poll::Pending` and waker registration rules.
9. Drop behavior is safe if the stream is dropped in any decode state.

Rust concepts: `Pin`, `Unpin`, `PhantomPinned`, manual `poll_next`, `Poll`, `Context`, `Waker`, projection, cancellation safety, structural pinning, drop safety.

Acceptance criteria:

1. Tests cover partial frames, EOF, malformed frames, backpressure, and cancellation.
2. The stream works with a deliberately `!Unpin` test reader.
3. No unsafe pin projection exists unless documented in `unsafe-audit.md`.
4. Miri covers unsafe projection helpers if any exist.
5. Docs explain why pinning is needed here and why the rest of the project avoids self-referential data.

---

## 10.12 WAL and crash recovery

The WAL persists admitted records before acknowledgment when enabled.

Record lifecycle:

```text
Reserved -> Appended -> Durable -> Delivered -> Checkpointed -> Reclaimable
```

Requirements:

1. WAL append has a transaction guard that rolls back incomplete records on drop.
2. Segment files use OS-specific sync safely through `omniflow-io`.
3. Mmap views are read-only and lifetime-bound to their segment owner.
4. On-disk layout is not Rust struct layout; parsing is explicit byte parsing.
5. Every numeric field has defined endian, size, range, and validity rules.
6. Alignment is checked before any typed read; unaligned reads are explicit and audited.
7. Pointer provenance rules are documented for mmap pointers and raw slices.
8. Recovery handles torn writes, corrupt checksums, truncated records, and unknown future versions.
9. `NonNull<[u8]>` or equivalent internal representations may be used for non-null mmap regions after validation.
10. Raw slice construction uses `slice::from_raw_parts` only after documenting pointer, alignment, initialized memory, and length invariants.
11. `MaybeUninit` is used only for bounded batch-read buffers or partial initialization where every initialized element is tracked.
12. `ManuallyDrop` is used only if ownership transfer or partial initialization cannot be expressed safely.
13. `ptr::copy_nonoverlapping`, `read_unaligned`, or `drop_in_place` require local wrappers and tests.
14. `repr(align(64))` may be used for WAL writer state or metrics shards only with a false-sharing rationale.
15. WAL offsets and lengths use checked arithmetic and never silently wrap.
16. `ArchivedEvent<'a>` variance and drop-check behavior are explained in docs.

Rust concepts: RAII, `Drop`, panic safety, `fsync`, I/O safety, mmap, lifetimes, `NonNull`, raw slices, `PhantomData`, variance, pointer provenance, alignment, `Layout`, `MaybeUninit`, `ManuallyDrop`, checksums, property tests.

Acceptance criteria:

1. Kill after append but before checkpoint causes replay.
2. Kill before durable append never exposes a corrupt committed record.
3. WAL inspector reports record states and checksum failures.
4. Fuzz target `wal_segment` never panics on arbitrary bytes.
5. Miri covers mmap view lifetime helpers where possible.
6. No public API exposes raw fd/handle ownership without an unsafe boundary.
7. `docs/pointer-provenance-and-layout.md` includes all raw pointer construction sites.
8. Property tests compare WAL replay against a simple in-memory model.

---

## 10.13 I/O safety and vectored I/O layer

`omniflow-io` owns platform file and socket handle abstractions.

Requirements:

1. Public Unix APIs accept `impl AsFd` or `BorrowedFd<'_>` where borrowing is sufficient.
2. Public Windows APIs accept `impl AsHandle` or `BorrowedHandle<'_>` where borrowing is sufficient.
3. Ownership transfer uses `OwnedFd` / `OwnedHandle`.
4. Raw fd/handle construction is unsafe and requires a `SAFETY:` explanation.
5. Duplicating, closing, and passing descriptors across plugin or child-process boundaries is explicitly documented.
6. Sync APIs are generic over `Read`, `Write`, `BufRead`, and `Seek` where practical.
7. WAL writes use `IoSlice` and vectored writes where it reduces syscalls.
8. Read buffers use `IoSliceMut` only when initialization and aliasing are clear.
9. Async APIs are generic over runtime traits at boundary crates, not core crates.
10. Path APIs preserve platform semantics and do not require UTF-8.
11. File sync policy distinguishes data sync, metadata sync, directory sync, and platform limitations.

Rust concepts: I/O safety, owned vs borrowed OS resources, RAII, unsafe constructors, platform `cfg`, `Read`, `Write`, `BufRead`, `Seek`, `IoSlice`, `IoSliceMut`, async I/O traits, safe wrappers.

Acceptance criteria:

1. WAL sync works through safe descriptor/handle APIs.
2. Native plugin loader does not double-close or leak handles.
3. Tests cover descriptor duplication, close-on-drop behavior, and platform-specific cfg compilation.
4. Vectored WAL write benchmarks compare syscall count and throughput against non-vectored writes.
5. Windows and Unix CI compile platform-specific modules.

---

## 10.14 Plugin system

OmniFlow supports two plugin classes:

1. WASM plugins for sandboxed untrusted or semi-trusted user transformations.
2. C ABI plugins for native integrations where WASM is insufficient.

Rust-to-Rust dynamic ABI is forbidden for runtime plugins.

### 10.14.1 WASM plugins

Requirements:

1. WASM memory is limited by configuration.
2. CPU/fuel/time limits are enforced.
3. Host functions expose only capability-scoped APIs.
4. Plugin output is bounded by event count and bytes.
5. Plugin errors are structured and observable.
6. WASM plugin state cannot borrow host event memory across host calls.
7. WASM stage adapters are dynamic stages and do not use lending output.

Acceptance criteria:

1. WASM plugin transforms events in end-to-end tests.
2. Fuel exhaustion, memory exhaustion, and invalid output fail safely.
3. Plugin output expansion ratio is enforced.

### 10.14.2 Native C ABI plugins

Conceptual ABI:

```rust
#[repr(C)]
pub struct OmniSlice {
    ptr: *const u8,
    len: usize,
}

#[repr(transparent)]
pub struct OmniStatus(u32);

#[repr(C)]
pub struct OmniEvent {
    topic: OmniSlice,
    payload: OmniSlice,
    attributes: OmniSlice,
}

#[repr(C)]
pub union OmniAttributePayload {
    bytes: OmniSlice,
    i64_value: i64,
    u64_value: u64,
    f64_value: f64,
    bool_value: u8,
}

#[repr(C)]
pub struct OmniAttribute {
    kind: u32,
    key: OmniSlice,
    payload: OmniAttributePayload,
}

#[repr(C)]
pub struct OmniPluginVTable {
    abi_version: u32,
    abi_size: usize,
    name: unsafe extern "C" fn() -> OmniSlice,
    process: unsafe extern "C" fn(OmniEvent, *mut OmniPluginCtx) -> OmniStatus,
    free: unsafe extern "C" fn(*mut OmniPluginCtx),
}
```

Requirements:

1. Exported symbols use Rust 2024 unsafe attribute syntax such as `#[unsafe(no_mangle)]`, `#[unsafe(export_name = "...")]`, and `#[unsafe(link_section = "...")]` where applicable.
2. Plugin descriptor statics may use `#[used]` and a platform-specific link section to avoid dead stripping.
3. FFI declarations use `unsafe extern` blocks.
4. `unsafe_op_in_unsafe_fn` is denied in plugin ABI crates.
5. Panics must not unwind through an `extern "C"` boundary.
6. `extern "C-unwind"` is used only if the ABI deliberately supports unwinding and the docs explain why.
7. ABI structs use `repr(C)` or `repr(transparent)` with layout tests.
8. Plugin-owned memory has explicit allocation/free pairing.
9. Host-owned input pointers may not be stored past the callback.
10. Plugin unload waits until all borrowed symbols and stage handles are gone.
11. ABI version mismatch fails safely.
12. `bool`, `char`, Rust enums without `repr`, references, slices, `String`, `Vec`, and Rust trait objects are forbidden in C ABI structs.
13. Nullable pointer conventions are explicit: null plus zero length may represent empty byte slices; null with nonzero length is invalid.
14. `CStr` and `CString` are used for C strings. File paths remain platform strings and are not forced through `CString` except where the platform ABI requires it.
15. Function pointer identity checks use function-address comparison only for diagnostics, never for security or semantic identity.
16. Opaque handles are newtyped raw pointers internally and exposed only through safe host wrappers.
17. `Send`/`Sync` for native plugin handles requires an unsafe impl with a documented proof or is prevented by marker fields.
18. `ManuallyDrop` and `Box::into_raw`/`Box::from_raw` are used only for explicit ownership transfer across ABI.
19. Tagged unions must validate tags before reading union fields.
20. `repr(packed)` is forbidden in plugin ABI unless a C dependency requires it; even then fields are accessed only through raw pointers and unaligned reads.

Rust concepts: `repr(C)`, `repr(transparent)`, `repr(u32)`, unions, raw pointers, opaque handles, `CStr`, `CString`, unsafe extern blocks, unsafe attributes, `#[used]`, `link_section`, panic boundaries, dynamic loading, `catch_unwind`, `AssertUnwindSafe`, ABI versioning, unsafe traits, `Send`/`Sync`, `ManuallyDrop`.

Acceptance criteria:

1. Valid native plugin transforms events.
2. Invalid ABI version returns structured load error.
3. Panicking plugin is quarantined and cannot unwind across host ABI.
4. Miri-compatible tests cover FFI wrappers where practical.
5. Fuzz target `plugin_abi` mutates plugin input/output boundaries.
6. Layout tests assert size, alignment, and field offsets for ABI structs.
7. Generated C header matches Rust ABI definitions.
8. Compile-fail tests prevent references, Rust strings, or Rust trait objects in ABI structs.

### 10.14.3 Optional C integration

OmniFlow includes one meaningful optional C integration:

1. CRC32C backend,
2. compression backend,
3. OS-specific sync backend, or
4. native syslog sink.

Requirements:

1. Pure Rust implementation exists as the default or fallback.
2. C backend is feature-gated.
3. `build.rs` handles platform detection and link directives.
4. Safe wrapper prevents invalid pointer/length pairs.
5. Tests compare C and Rust implementations over random inputs.
6. Panic/unwind and allocation boundaries are documented.
7. C variadic functions, if used for syslog, are isolated in one wrapper and have format strings controlled by the host.

Acceptance criteria:

1. C backend can be disabled.
2. Cross-platform CI validates fallback behavior.
3. Fuzzing covers both safe and native implementations.
4. Variadic FFI remains labs-only unless the syslog sink proves a real product need.

---

## 10.15 Embedded and `no_std` SDK

The SDK lets constrained devices build and encode events.

Feature model:

```toml
[features]
default = ["std"]
std = ["alloc"]
alloc = []
embedded-net = []
serde = []
```

Conceptual API:

```rust
pub struct FixedEvent<const MAX_TOPIC: usize, const MAX_PAYLOAD: usize, const STRICT: bool = true> {
    topic: ArrayString<MAX_TOPIC>,
    payload: ArrayVec<u8, MAX_PAYLOAD>,
}
```

Requirements:

1. `omniflow-core` builds without default features.
2. `omniflow-sdk` supports zero-heap fixed-capacity encoding.
3. Optional `alloc` enables owned dynamic buffers.
4. `std` enables networking, time, filesystem, and richer error sources.
5. Embedded examples build for at least one Cortex-M target.
6. `panic = abort` compatibility is documented.
7. Const generics encode fixed buffer capacities.
8. Const assertions reject impossible SDK frame capacities at compile time where stable Rust can express them.
9. Generic const expressions beyond stable support are labs-only.
10. `MaybeUninit` arrays may be used for fixed-capacity staging if every initialized element is tracked and tested.
11. `core` APIs are used by default; `alloc` and `std` APIs are behind explicit cfgs.
12. `target_has_atomic` cfgs gate atomic metrics support on embedded targets.
13. The library does not define a panic handler; examples choose one.

Rust concepts: `#![no_std]`, `alloc`, `core`, const generics, default const parameters where appropriate, fixed-capacity buffers, `MaybeUninit`, conditional compilation, target-specific builds, panic strategy, `target_has_atomic`.

Acceptance criteria:

1. `cargo build -p omniflow-core --no-default-features` succeeds.
2. `cargo build -p omniflow-sdk --target thumbv7em-none-eabihf --no-default-features` succeeds.
3. Embedded example encodes an event without heap allocation.
4. Docs distinguish `core`, `alloc`, and `std` APIs.
5. Compile-fail tests cover capacity overflow and disabled-allocation misuse.

---

## 10.16 Observability

OmniFlow emits logs, metrics, traces, and diagnostic state.

Requirements:

1. `tracing` spans connect ingress, decode, WAL append, stage processing, sink commit, and checkpoint.
2. Metrics include queue depth, admitted/rejected events, reserved bytes, WAL bytes, replay count, plugin errors, sink retries, and latency histograms.
3. Global registries use `OnceLock`, `LazyLock`, or dependency injection; mutable statics are forbidden except isolated FFI interop with documented safety.
4. Hot-path metrics use atomics or low-contention aggregation.
5. Exporters are feature-gated.
6. Atomic memory orderings are documented: `Relaxed` for independent counters, `Acquire/Release` for state publication, and `SeqCst` only with explicit justification.
7. Cache-sensitive counters may use `#[repr(align(64))]` or a cache-padding wrapper after measurement.
8. Thread-local scratch buffers or metric shards may be used when they reduce contention without hiding unbounded memory.
9. Metrics cardinality is bounded by config.
10. Diagnostic snapshots use `Arc<[T]>` or `Box<[T]>` for immutable views.

Rust concepts: `Arc`, atomics, memory orderings, `OnceLock`, `LazyLock`, `thread_local!`, `repr(align)`, dynamic dispatch for exporters, structured logging, async instrumentation, feature flags.

Acceptance criteria:

1. `/metrics` exposes Prometheus-compatible metrics.
2. Trace IDs correlate a record through all lifecycle phases.
3. Logging and metrics overhead is measured in benchmarks.
4. Loom tests cover any custom atomic publication primitive.
5. Metrics cardinality overload is tested.

---

## 10.17 Sinks and delivery semantics

Supported sinks:

1. stdout/file sink,
2. HTTP forwarder,
3. SQLite or local durable sink,
4. native syslog sink behind feature/labs gate,
5. in-memory deterministic test sink.

Requirements:

1. Sink interface supports idempotency keys.
2. Retry policy is bounded and observable.
3. Sink cancellation is safe.
4. WAL checkpoint occurs only after sink commit condition is satisfied.
5. Backoff uses jitter and respects shutdown.
6. Sink traits support static dispatch for built-in sinks and object-safe adapters for dynamic configuration.
7. `ControlFlow` is used for sink visitor APIs where early stop is normal.
8. `IoSlice` may be used for file sinks to avoid concatenating buffers.
9. `AsyncWrite` adapters are used for runtime sinks; core sink interfaces avoid pinning callers to a single async runtime where possible.
10. Idempotency keys are newtypes and implement `Display`/`FromStr` but not arbitrary arithmetic.

Rust concepts: async traits/static dispatch, boxed-future dynamic adapters, associated error types, trait objects, cancellation safety, retries, `ControlFlow`, vectored I/O, newtypes.

Acceptance criteria:

1. Sink failure does not lose admitted durable records.
2. Retried sink commits do not duplicate checkpointed records under idempotent sink mode.
3. In-memory sink supports deterministic integration and property tests.
4. File sink benchmarks compare buffered, unbuffered, and vectored writes.

---

## 10.18 Macros and developer ergonomics

Macro features must improve user ergonomics, not hide complexity.

Required macros:

1. `pipeline! { ... }` declarative macro for simple static pipeline construction.
2. `topic!("sensor.temp")` macro for compile-time topic validation when the literal is known.
3. `#[derive(OmniPlugin)]` for plugin metadata and registration boilerplate.
4. `#[derive(ValidatedNewtype)]` for internal validated wrapper patterns where hand-written code would be repetitive.
5. `#[omniflow_stage]` attribute macro for generating safe host adapters and C ABI export glue where appropriate.

Requirements:

1. Macro-generated unsafe code must route through audited helper functions or emit `SAFETY:` comments in generated code where inspectable.
2. Span diagnostics should point to the user's invalid stage/plugin/topic definition.
3. Macro hygiene must prevent accidental capture.
4. Generated code has trybuild tests and expansion snapshots where useful.
5. `macro_rules!` uses explicit fragment specifiers and accounts for Rust 2024 `expr` behavior.
6. Declarative macros use `compile_error!` for mutually exclusive syntax or feature combinations.
7. Proc macros preserve user generics, where clauses, visibility, docs, and cfg attributes.
8. Proc macros do not generate public semver commitments accidentally.
9. Macro expansion docs show equivalent hand-written code.
10. `#[diagnostic::do_not_recommend]` may hide internal blanket impls from user diagnostics.

Rust concepts: `macro_rules!`, proc-macro derives, attribute macros, hygiene, spans, generated code, `compile_error!`, macro fragment specifiers, diagnostics, compile-fail tests.

Acceptance criteria:

1. Macro-generated plugin behaves the same as hand-written plugin registration.
2. Invalid macro use produces actionable compile errors.
3. Public docs show both macro and non-macro forms.
4. trybuild tests cover invalid topic literals, invalid ABI fields, non-object-safe stage definitions, and missing lifetimes.
5. Expansion snapshots catch accidental semver-visible generated API changes.

---

## 10.19 Build scripts, generated artifacts, and Cargo feature topology

Build-time behavior is part of the product.

Requirements:

1. `build.rs` scripts declare `rerun-if-changed` and `rerun-if-env-changed` precisely.
2. Native C integrations emit correct `cargo:rustc-link-lib` and `cargo:rustc-link-search` lines.
3. Build scripts generate C headers or route tables only into `OUT_DIR`.
4. Generated source included with `include!` must be deterministic and documented.
5. Static fixtures may use `include_bytes!` or `include_str!` where embedding improves test or default config behavior.
6. `env!` and `option_env!` may embed build metadata only if reproducibility impacts are documented.
7. Custom cfgs use `cargo:rustc-check-cfg` so misspelled cfgs fail CI.
8. Feature flags use explicit optional dependency naming and avoid accidental public features.
9. Mutually exclusive features use compile-time errors.
10. The feature matrix is tested with cargo-hack or equivalent.
11. Default features are minimal and documented.
12. `std`, `alloc`, and `no_std` feature layering is acyclic.
13. `wasm`, `cabi`, `simd`, `mmap`, `sqlite`, `syslog`, and `bench-internals` features have clear API impact.

Rust concepts: Cargo resolver v3, MSRV-aware dependency selection, feature unification, optional dependencies, build scripts, generated code, `include!`, `include_bytes!`, `env!`, custom cfg checking, compile-time feature errors.

Acceptance criteria:

1. `cargo hack` or equivalent validates all relevant feature combinations.
2. Build scripts are deterministic under clean builds.
3. Generated C headers are checked into release artifacts or reproducibly generated by `xtask`.
4. `--no-default-features`, `--all-features`, and selected minimal feature sets pass CI.

---

## 10.20 Performance, SIMD, and low-level labs

Performance requirements are real product requirements, not microbenchmark theater.

Initial targets on a developer laptop:

| Metric | Target |
|---|---:|
| HTTP ingest throughput | 50k events/sec |
| Binary frame decode | 250k frames/sec |
| WAL append, batched | 100k events/sec |
| p95 ingest-to-sink latency under normal load | < 20 ms |
| Memory under overload | bounded by configured queues and buffers |
| SDK fixed-buffer mode heap allocations | 0 |

Optional optimized paths:

1. CRC32C may use runtime CPU feature detection and `std::arch` where useful.
2. SIMD paths must have safe fallbacks.
3. Unsafe target-feature functions must be isolated behind safe dispatch wrappers.
4. Benchmarks must prove measurable benefit before optimized paths remain enabled.
5. `core::hint::black_box` is used in benchmarks, not production logic.
6. `spin_loop` is labs-only unless a real short-wait primitive is justified and Loom-tested.
7. `unreachable_unchecked` is forbidden in production crates.
8. Inline assembly is labs-only unless a platform integration requires it.
9. Naked functions are labs-only and restricted to embedded/ABI trampolines or architecture probes.
10. Portable SIMD remains labs-only until stable and justified.

Rust concepts: Criterion, allocation tracking, flamegraphs, CPU feature detection, target-specific cfg, `#[target_feature]`, `std::arch`, `black_box`, inline assembly labs, naked functions labs, safe fallback design.

Acceptance criteria:

1. Benchmarks report throughput, p50/p95/p99 latency, allocations/event, bytes/event, RSS, WAL replay speed, plugin overhead, and feature-specific optimized-path deltas.
2. Optimized paths are feature-gated and tested against safe baselines.
3. No unsafe optimization is accepted if the safe version is within 10% for the documented workload.
4. Labs low-level examples include explicit target cfgs and do not build by default.

---

## 11. Rust coverage ledger

Every row below must map to code, docs, and tests. `docs/rust-mastery-map.md` must include file paths and acceptance evidence.

### 11.1 Fundamentals and syntax

| Concept | Product use | Evidence |
|---|---|---|
| Variables, mutability, shadowing | CLI/config normalization, parser state | unit tests |
| Scalar types, arrays, tuples | frame headers, counters, parser returns | codec tests |
| Strings and slices | topics and payloads | zero-copy tests |
| Structs and enums | events, configs, lifecycle states, errors | rustdoc/tests |
| Pattern matching and guards | parsing and state machines | branch tests/fuzz |
| `let else` | parser precondition exits | codec tests |
| `let` chains | config and parser validation | parser/config tests |
| `if let` match guards | routing and error classification | match tests |
| `assert_matches!` | parser/WAL/plugin tests | unit tests |
| Labeled loops/blocks | parser control flow where clearer | unit tests |
| Modules and visibility | workspace crate boundaries | rustdoc/private API review |
| Docs and doctests | public examples | docs CI |

### 11.2 Ownership, lifetimes, and smart pointers

| Concept | Product use | Evidence |
|---|---|---|
| Moves | ingress-to-queue handoff | compile tests |
| Shared and mutable borrows | event views and decode buffers | unit tests |
| Explicit lifetimes | `EventRef<'a>`, `ArchivedEvent<'a>` | compile-fail tests |
| Custom DSTs | `TopicStr` | validation tests/Miri |
| Fat pointer understanding | `&TopicStr`, `Box<TopicStr>` docs | rustdoc |
| `Cow<'a, T>` | borrowed/owned config and payload fields | serde tests |
| `Bytes` | shared immutable payload ownership | clone-cost benchmarks |
| `Box<T>` | dyn adapters and owned internals | API tests |
| `Box<[T]>` | immutable snapshots and batches | allocation benchmarks |
| `Box<str>` | owned validated strings before DST cast | unit tests |
| `Arc<T>` | shared stage/config snapshots | concurrency tests |
| `Weak<T>` | diagnostic graph backrefs | leak tests |
| `Rc<T>` | local single-threaded graphs/tests | compile-fail Send tests |
| `Deref` policy | pointer-like wrappers only | API docs |
| `Drop` and RAII | WAL transaction/admission guards | crash/panic tests |
| `Clone`/`Copy` discipline | cheap handles vs owning payloads | allocation benchmarks |
| `PhantomData` and variance | typestate, mmap views, plugin symbols | safety docs/Miri |

### 11.3 Traits, type system, and dispatch

| Concept | Product use | Evidence |
|---|---|---|
| Traits and bounds | stages, sinks, exporters | API tests |
| Associated types | stage output/error | pipeline tests |
| Associated consts | protocol versions and limits | codec tests |
| Default generic parameters | pipeline builder defaults | compile tests |
| Generics and where clauses | static pipeline and SDK buffers | compile tests |
| Const generics | fixed-capacity SDK events | embedded build |
| Explicitly inferred const args | local array construction examples | doctests |
| `const fn` and const assertions | protocol sizes and invariants | compile tests |
| GATs | lending stage outputs and WAL iterators | compile tests |
| HRTBs | lifetime-generic callbacks | compile tests |
| `AsyncFn*` | async closure stage adapters | async tests |
| RPITIT / async fn in traits | static async stages | compile tests |
| `impl Trait` | static abstraction returns | rustdoc/API tests |
| `dyn Trait` | runtime plugins/sinks | integration tests |
| Trait upcasting | stage inspection hierarchy | API tests |
| Dyn compatibility | object-safe adapters | compile-fail tests |
| Sealed traits | internal lifecycle states | compile-fail tests |
| Coherence/orphan-rule design | plugin extension traits | API docs |
| `?Sized` and DSTs | slices, topic DSTs, trait objects | API tests |
| `Any`/`TypeId` | scoped extension storage | tests and docs |
| `#[diagnostic::do_not_recommend]` | hidden blanket impl diagnostics | trybuild snapshots |

### 11.4 Collections and iterators

| Concept | Product use | Evidence |
|---|---|---|
| Custom iterator structs | routes, WAL replay, attributes | iterator law tests |
| `IntoIterator` for owned/borrowed | attributes and route snapshots | API tests |
| `FromIterator` | route and attribute builders | unit tests |
| `Extend` | config accumulation | unit tests |
| Tuple `FromIterator`/`Extend` | testkit fanout collections | testkit tests |
| `ExactSizeIterator` | immutable snapshots | iterator tests |
| `FusedIterator` | WAL scanner after EOF | iterator tests |
| `DoubleEndedIterator` | route inspection | iterator tests |
| `RangeBounds` | CLI/API inspection ranges | CLI tests |
| `Borrow` | heterogenous map lookup | allocation tests |
| Entry APIs | duplicate config normalization | config tests |
| Disjoint mutable access | route/sink pair updates | unit tests |
| `try_fold` | fallible validation | property tests |
| `ControlFlow` | early-stop visitors | unit tests |

### 11.5 Error and panic discipline

| Concept | Product use | Evidence |
|---|---|---|
| `Result` and `?` | all fallible APIs | codebase/tests |
| Typed errors | config/codec/WAL/plugin | unit tests |
| Source chains | CLI and diagnostics | snapshot tests |
| `Infallible` / `!` where useful | impossible stage errors or fatal exits | compile tests |
| Never-type fallback lint | unsafe-adjacent code hygiene | lint CI |
| `catch_unwind` | native plugin quarantine | plugin tests |
| `AssertUnwindSafe` policy | plugin panic boundary | safety docs |
| Poisoning strategy | mutex-protected shared state | tests/docs |
| Panic during drop | WAL rollback/admission release | panic tests |
| `panic = abort` | embedded SDK compatibility | target build |
| `#[track_caller]` | assertion helpers/error construction | snapshot tests |
| `#[cold]` | rare error paths | benchmark review |
| `#[must_use]` | guards/tokens/builders | lint tests |

### 11.6 Async and concurrency

| Concept | Product use | Evidence |
|---|---|---|
| async/await | server handlers and sinks | integration tests |
| Async closures | borrowing static filters | integration tests |
| `IntoFuture` | run/start token ergonomics | API tests |
| Manual `Future`/`Stream` | framed ingress stream | unit tests |
| `Pin` and true `!Unpin` | custom stream with pinned reader | pin tests |
| `Poll`, `Context`, `Waker` | manual polling | tests/docs |
| `Waker::noop` | deterministic poll tests | testkit tests |
| Cancellation | shutdown and dropped futures | integration tests |
| Bounded channels/semaphores | admission and backpressure | load tests |
| Threads/scoped threads | load generators and CPU transforms | tests |
| Local `!Send` execution | native plugin affinity | compile/integration tests |
| `Send`/`Sync` | task handoff and shared stages | compile tests |
| Thread affinity / `!Send` handles | plugin loader handles | compile-fail tests |
| Atomics and memory ordering | metrics and state publication | Loom/docs |
| Interior mutability | metrics, mocks, registries | unit tests |
| Thread-local storage | metric shards/scratch | contention benchmarks |

### 11.7 Unsafe, layout, FFI, and OS resources

| Concept | Product use | Evidence |
|---|---|---|
| Unsafe blocks/functions | FFI, mmap, parser optimizations | safety comments/Miri |
| Rust 2024 unsafe extern | C ABI declarations | compile tests |
| Unsafe attributes | exported plugin symbols/sections | compile tests |
| `unsafe_op_in_unsafe_fn` | unsafe-body discipline | lints CI |
| Raw pointers | plugin ABI and mmap internals | Miri/fuzz |
| `&raw const` / `&raw mut` | unaligned or uninitialized raw access | Miri tests |
| `NonNull` | non-null mmap ranges and handles | Miri tests |
| Pointer provenance | mmap/raw pointer policy | unsafe-audit docs |
| Alignment/unaligned reads | WAL/frame parsing | Miri/fuzz |
| `MaybeUninit` | batch buffers and fixed arrays | Miri/tests |
| `ManuallyDrop` | FFI-owned resources only if needed | Miri/tests |
| `UnsafeCell` | labs/custom primitive only | Loom/Miri |
| `repr(C)` | plugin ABI structs | ABI layout tests |
| `repr(transparent)` | FFI-safe newtypes and DST wrappers | ABI/layout tests |
| `repr(u*)` | wire/ABI tags | codec tests |
| `repr(align)` | cache-padded metrics shards | benchmarks |
| `repr(packed)` policy | avoided except required C interop | unsafe docs |
| Unions | C ABI tagged attribute payload | FFI tests |
| Unsafe traits | `Send`/`Sync` for FFI handles if sound | safety docs |
| I/O safety | fd/handle ownership and borrowing | platform tests |
| Panic/unwind boundary | native plugins | plugin tests |
| C variadics | optional syslog labs | labs tests |

### 11.8 Portability, Cargo, and ecosystem

| Concept | Product use | Evidence |
|---|---|---|
| Workspaces | multi-crate architecture | CI |
| Resolver v3 / Rust 2024 | MSRV-aware dependency resolution | CI |
| Feature flags | protocol/plugin/std/alloc options | cargo-hack |
| Optional dependencies | WASM/C ABI/SQLite/syslog | feature tests |
| Mutually exclusive features | C backend choices | compile_error tests |
| Workspace lints | consistent unsafe/lint policy | CI |
| `cargo:rustc-check-cfg` | custom cfg hygiene | CI |
| Build scripts | FFI/platform codegen | CI |
| `include_bytes!`/`include_str!` | fixtures/default schemas | tests |
| Target cfg | Unix/Windows/embedded | matrix builds |
| `target_has_atomic` | embedded metrics support | target builds |
| `no_std`/`alloc` | core and SDK | target builds |
| Examples | user-facing scenarios | CI |
| Rustdoc/doctests | API education | docs CI |
| Semver/MSRV | library stability | release checks |

### 11.9 Verification and quality

| Tool/concept | Product use | Evidence |
|---|---|---|
| Unit tests | pure logic | CI |
| Integration tests | server/CLI/WAL/plugins | CI |
| Doctests | examples compile | CI |
| trybuild | compile-time API guarantees | CI |
| Proptest | codec/pipeline/WAL invariants | CI |
| Fuzzing | frame/WAL/plugin boundaries | fuzz corpus |
| Miri | unsafe and lifetime validation | CI |
| Loom | custom concurrency interleavings | CI |
| Sanitizers | native/FFI checks | nightly/manual job |
| Criterion | performance tracking | bench reports |
| Flamegraphs | performance investigation | docs |
| Allocation tracking | hot-path allocation budgets | bench reports |
| cargo-deny/audit | dependency/security policy | CI |
| cargo-semver-checks | public API compatibility | release CI |
| cargo-hack or equivalent | feature matrix | CI |

---

## 12. Labs-only Rust esoterics

`omniflow-labs` exists to demonstrate advanced Rust concepts that are unstable, architecture-specific, or too niche for production crates.

Labs must be useful experiments, not random syntax. Each lab has a README explaining why it is not in core.

| Lab | Concept | Product-adjacent use | Core policy |
|---|---|---|---|
| `labs-specialized-codec` | specialization/min-specialization | Compare generic codec dispatch against specialized payload scanners | labs-only until stable; safe baseline remains core |
| `labs-trait-aliases` | trait aliases | Shorten repeated `DynStage + Send + Sync + 'static` bounds | labs-only until stable and semver impact is clear |
| `labs-generic-const-exprs` | generic const expressions | Express `MAX_FRAME = HEADER + MAX_TOPIC + MAX_PAYLOAD` at type level | core uses runtime or simple const checks |
| `labs-allocator-api` | allocator API | Per-pipeline arena or bump allocator experiments | core uses global allocator tests and admission budgets |
| `labs-custom-try` | `Try`/residual customization | Validation DSL using `?` for recoverable multi-error collection | core uses `Result`, `ControlFlow`, and explicit collectors |
| `labs-async-generators` | generator/coroutine experiments | Stream parser prototype | core uses manual `Stream` or async-stream crates if justified |
| `labs-portable-simd` | portable SIMD | Topic scan, CRC, delimiter detection | core uses safe scalar plus `std::arch` optional paths |
| `labs-inline-asm` | `asm!` | Timestamp counter or architecture probe for benchmarks | core uses standard timing APIs |
| `labs-naked-functions` | naked functions / `naked_asm!` | Embedded trampoline/reset-vector demonstration | never required by server; target-gated labs only |
| `labs-lockfree-ring` | `UnsafeCell`, atomics, custom lock-free queue | Compare against bounded channel under load | production only if proven necessary and Loom-verified |
| `labs-extern-types` | extern type/opaque C objects | Model foreign opaque plugin context | core uses raw opaque pointers/newtypes |
| `labs-unsize-coercions` | custom unsizing/coercion experiments | Explore smart-pointer ergonomics for custom DSTs | core relies on standard unsizing through Box/Arc/reference |
| `labs-variadic-ffi` | C variadic functions | Syslog wrapper with host-controlled format string | core prefers safe logging/exporter APIs |

Acceptance criteria for labs:

1. Labs are not workspace default members unless they build on stable without special flags.
2. Nightly labs are behind explicit toolchain files or CI jobs.
3. No production crate depends on `omniflow-labs`.
4. Labs document unsoundness risks and why the code is not production.
5. If a lab graduates to core, it must satisfy the normal unsafe, testing, docs, and benchmark policies.

---

## 13. Safety and soundness policy

### 13.1 Unsafe acceptance rule

Unsafe code is accepted only if:

1. Safe Rust cannot express the boundary or cannot meet the measured requirement.
2. The invariant can be stated precisely.
3. Safe callers cannot trigger UB through the public API.
4. Miri, Loom, fuzzing, or targeted tests cover the relevant failure modes where practical.
5. Panic paths and drop behavior are documented.
6. A reviewer can audit the unsafe block without understanding unrelated business logic.
7. The unsafe block is the smallest practical block.
8. Unsafe operations inside unsafe functions still appear inside explicit `unsafe {}` blocks.
9. `SAFETY:` comments explain why the operation is valid, not what the code does mechanically.
10. The simpler safe alternative and benchmark delta are recorded when unsafe exists for performance.

Unsafe code is rejected if:

1. A safe alternative is within 10% for the target workload.
2. The invariant is vague.
3. Ownership or aliasing is ambiguous.
4. FFI allocation/free responsibility is unclear.
5. It depends on layout guarantees Rust does not provide.
6. It assumes pointer-integer roundtrips preserve provenance without documentation.
7. It creates references to unaligned, uninitialized, dangling, or aliased mutable memory.
8. It permits unwinding across a non-unwinding ABI boundary.
9. It uses `unreachable_unchecked` in production crates.
10. It hides raw pointer lifetimes behind `'static` without proof.

### 13.2 Required unsafe docs

`docs/unsafe-audit.md` must include, for every unsafe site:

1. File and line range.
2. Code owner.
3. Unsafe operation category.
4. Safety invariant.
5. Caller responsibility.
6. Callee responsibility.
7. Why safe Rust was insufficient.
8. Miri/Loom/fuzz/test coverage.
9. Failure mode if violated.
10. Panic and drop behavior.
11. Review date.
12. Graduation/rejection status if the code came from labs.

### 13.3 Layout and validity rules

1. `repr(Rust)` layout is not part of wire, disk, or ABI formats.
2. `repr(C)` is used for C ABI structs only; it does not make nested Rust-layout fields C-compatible.
3. `repr(transparent)` is used for FFI-safe newtypes and validated DST wrappers.
4. `repr(u*)` is used for closed wire tags only when unknown values are rejected before conversion.
5. Open ABI status and flag values use integer newtypes, not Rust enums.
6. `bool` across ABI is represented as `u8` with explicit valid values.
7. `char` is forbidden across ABI and wire unless encoded explicitly as Unicode scalar value.
8. `repr(packed)` is avoided. If unavoidable for C interop, references to packed fields are forbidden; raw pointers and unaligned reads are required.
9. `MaybeUninit<T>` is not a way to bypass type validity. It tracks uninitialized memory until initialization is complete.
10. `ManuallyDrop<T>` is not a way to ignore ownership. It is used only where explicit drop timing is required.

---

## 14. Documentation requirements

The repository must include:

```text
docs/
  architecture.md
  rust-mastery-map.md
  rust-esoterics-ledger.md
  wire-format.md
  wal-format.md
  unsafe-audit.md
  pointer-provenance-and-layout.md
  dst-and-topic-types.md
  allocation-and-admission.md
  collections-and-iterators.md
  async-cancellation.md
  pinning-and-projection.md
  backpressure.md
  plugin-abi.md
  io-safety.md
  no-std-sdk.md
  macros.md
  build-scripts-and-cfg.md
  feature-flags.md
  benchmarking.md
  semver-policy.md
  msrv-policy.md
  release-checklist.md
  labs.md
```

### 14.1 `rust-mastery-map.md`

For every notable Rust concept:

1. Concept.
2. Subsystem.
3. File/module.
4. Why the feature is useful here.
5. Simpler alternative considered.
6. Tests or tools proving behavior.
7. Whether the concept is core, optional, or labs-only.
8. Rust version/MSRV impact.
9. Safety review link if applicable.

### 14.2 `rust-esoterics-ledger.md`

Must list every esoteric feature with one of these statuses:

1. **Core-required:** needed by production product behavior.
2. **Core-optional:** feature-gated and benchmark-justified.
3. **Testkit:** used only for verification or examples.
4. **Labs:** isolated experiment.
5. **Rejected:** considered and intentionally excluded.

Each entry must include a one-paragraph justification and the actual code path.

### 14.3 `dst-and-topic-types.md`

Must explain:

1. Why `TopicStr` is a custom DST.
2. How validation precedes unsafe conversion.
3. Why `repr(transparent)` is sufficient for the wrapper.
4. Fat-pointer implications.
5. `Deref`, `Borrow`, `AsRef`, and `ToOwned` policy.
6. Clone-cost and allocation behavior for `TopicBuf`.

### 14.4 `pointer-provenance-and-layout.md`

Must explain:

1. Why on-disk/wire data is not Rust struct layout.
2. Endian policy.
3. Alignment policy.
4. Unaligned read policy.
5. Pointer provenance policy for mmap and FFI.
6. Why `transmute` is forbidden for frame/WAL parsing.
7. How `NonNull` is used and what it does not prove.
8. How raw slices are constructed.
9. How Miri is used and what Miri cannot prove.
10. Why integer-to-pointer casts are forbidden in production code.

### 14.5 `allocation-and-admission.md`

Must explain:

1. Admission budgets.
2. Fallible allocation strategy.
3. Hot-path preallocation.
4. Plugin-output limits.
5. `Layout` usage.
6. Failing-allocator tests.
7. Overload behavior and HTTP/MQTT semantics.
8. RAII rollback.
9. Where intentional leaks are allowed.

### 14.6 `collections-and-iterators.md`

Must explain:

1. Route table collection choices.
2. Why route snapshots use `Arc<[T]>` or `Box<[T]>`.
3. Iterator trait guarantees.
4. Heterogenous lookup through `Borrow`.
5. Entry/disjoint-mut usage.
6. Why `Index` is avoided in public fallible lookups.
7. `ControlFlow` and `try_fold` usage.

### 14.7 `async-cancellation.md`

Must explain:

1. Task ownership.
2. Cancellation points.
3. Drop safety.
4. Shutdown phases.
5. WAL interaction.
6. Sink retry interaction.
7. Plugin unload interaction.
8. Local `!Send` plugin execution.
9. `catch_unwind` scope.

### 14.8 `pinning-and-projection.md`

Must explain:

1. Why `FramedIngress` is `!Unpin`.
2. Which fields are pinned.
3. Projection strategy.
4. Drop behavior.
5. Cancellation with partial frames.
6. Why self-referential structures are avoided elsewhere.

### 14.9 `plugin-abi.md`

Must explain:

1. ABI versioning.
2. Symbol names and unsafe attributes.
3. `unsafe extern` declarations.
4. Layout guarantees.
5. Ownership across ABI.
6. Allocation/free contract.
7. Panic/unwind behavior.
8. Thread-safety guarantees.
9. Plugin unload safety.
10. Tagged union validation.
11. Nullable pointer convention.
12. Generated C header policy.
13. Link-section descriptor policy.

### 14.10 `build-scripts-and-cfg.md`

Must explain:

1. Build script responsibilities.
2. Generated file reproducibility.
3. C header generation.
4. Link directives.
5. Custom cfg names.
6. Feature-flag interactions.
7. Target-specific dependencies.

---

## 15. Testing and verification requirements

### 15.1 Required CI jobs

```bash
cargo fmt --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
cargo test --workspace --no-default-features
cargo doc --workspace --no-deps --all-features
cargo test -p omniflow-testkit compile_fail
cargo miri test -p omniflow-core
cargo miri test -p omniflow-codec
cargo miri test -p omniflow-wal
cargo miri test -p omniflow-plugin-cabi
cargo test -p omniflow-labs --features loom
cargo deny check
cargo semver-checks check-release
cargo hack check --workspace --feature-powerset --depth 2
```

### 15.2 Required target and feature jobs

```bash
cargo build -p omniflow-core --no-default-features
cargo build -p omniflow-sdk --no-default-features
cargo build -p omniflow-sdk --features alloc --no-default-features
cargo build -p omniflow-sdk --target thumbv7em-none-eabihf --no-default-features
cargo test -p omniflow-plugin-cabi --features cabi
cargo test -p omniflow-plugin-wasm --features wasm
cargo test -p omniflow-codec --features simd
```

### 15.3 Required manual or scheduled jobs

```bash
cargo fuzz run frame_decode
cargo fuzz run wal_segment
cargo fuzz run plugin_abi
cargo bench --workspace
omniflow load http --rate 100000 --duration 300s
omniflow chaos kill-restart --iterations 1000
```

### 15.4 Compile-fail guarantees

Compile-fail tests must prove:

1. Invalid pipeline typestate transitions fail.
2. Archived WAL views cannot outlive mapped segments.
3. Non-`Send` plugin handles cannot be moved to worker threads.
4. GAT/lending stage traits are not exposed as dynamic plugin trait objects.
5. Pinned `!Unpin` stream components cannot be moved after pinning.
6. Unsafe constructors require explicit unsafe call sites.
7. `TopicStr` cannot be constructed without validation.
8. Plugin symbols cannot outlive dynamic library handles.
9. ABI structs cannot include Rust references, `String`, `Vec`, or Rust trait objects.
10. Feature-incompatible config sections fail cleanly.
11. Ignored `#[must_use]` lifecycle tokens are caught.
12. Raw indexes from different domains cannot be mixed.

### 15.5 Property and model tests

Property tests must cover:

1. Binary frame encode/decode roundtrip.
2. JSONL parse/render stability.
3. Route matcher equivalence with reference implementation.
4. WAL append/replay equivalence with in-memory model.
5. Admission token accounting under arbitrary error/cancel sequences.
6. Plugin output budget enforcement.
7. Attribute ABI conversion roundtrip.
8. Iterator laws for custom iterators.

### 15.6 Miri scope

Miri must cover:

1. Topic DST validation and conversion helpers.
2. Parser unsafe helpers.
3. WAL mmap view construction where practical.
4. FFI slice validation and ownership transfer helpers.
5. `MaybeUninit` batch buffers.
6. `ManuallyDrop` ownership transfer paths.
7. Any custom unsafe pointer arithmetic.

Miri limitations must be documented. OS syscalls, actual dynamic loading, and some FFI behavior require additional tests.

### 15.7 Loom scope

Loom must cover:

1. Any custom atomic state publication.
2. Admission counters if lock-free.
3. Shutdown flags if implemented with atomics.
4. Labs lock-free ring buffer.
5. Plugin unload coordination if custom atomics are used.

---

## 16. Milestones

## Milestone 1 - Workspace, CLI, and core event model

Scope:

1. Workspace with Rust 2024, resolver v3, workspace lints.
2. `omniflow-core`, `omniflow-cli`, typed errors, config validation.
3. Owned and borrowed event model.
4. Custom `TopicStr` DST and `TopicBuf`.
5. File ingestion to stdout.
6. Initial rust-mastery map.

Definition of done:

```bash
cargo fmt --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
omniflow ingest file examples/events.jsonl
```

Additional acceptance:

1. `TopicStr` validation tests pass.
2. `HashMap<TopicBuf, _>` borrowed lookup tests pass.
3. `size_of` niche assertions pass where intended.

## Milestone 2 - Codec, zero-copy parsing, and allocation discipline

Scope:

1. Binary frame format and JSONL codec.
2. Borrowed parse views.
3. `try_reserve` allocation paths.
4. Failing-allocator tests.
5. Pattern-based parser ergonomics.
6. Fuzz and proptest coverage.

Definition of done:

```bash
cargo test -p omniflow-codec
cargo fuzz run frame_decode
cargo bench -p omniflow-codec
```

Additional acceptance:

1. Parser tests use structured `assert_matches!`.
2. Unsafe parser helper, if any, is in `unsafe-audit.md`.
3. Allocation failure is not a panic in recoverable hot paths.

## Milestone 3 - Routing, iterators, and collection semantics

Scope:

1. Route table and topic filter model.
2. Immutable snapshots with `Arc<[T]>` or `Box<[T]>`.
3. Custom iterator family.
4. Heterogenous lookup.
5. Entry and disjoint-mut updates.

Definition of done:

```bash
cargo test -p omniflow-routing
cargo bench -p omniflow-routing
```

Additional acceptance:

1. Iterator law tests pass.
2. Property tests compare against reference route matcher.
3. Public APIs avoid panicking index lookups.

## Milestone 4 - Pipeline type-system design

Scope:

1. Static pipeline.
2. Dynamic object-safe adapter pipeline.
3. GAT lending stages.
4. Async static stage path and boxed dynamic path.
5. Async closure adapters.
6. Trait upcasting hierarchy.
7. Typestate builder and compile-fail tests.

Definition of done:

```bash
cargo test -p omniflow-pipeline
cargo test -p omniflow-testkit compile_fail
```

Additional acceptance:

1. Async closure pipeline example compiles and runs.
2. Trait upcasting tests pass.
3. Non-dyn-compatible trait misuse fails with useful diagnostics.

## Milestone 5 - Async server, backpressure, and true pinning

Scope:

1. HTTP ingestion.
2. MQTT ingestion.
3. Bounded queues and semaphores.
4. Graceful shutdown.
5. Custom `!Unpin` framed stream.
6. Local `!Send` plugin executor skeleton.

Definition of done:

```bash
cargo test -p omniflow-server
omniflow load http --rate 50000 --duration 60s
```

Additional acceptance:

1. Memory remains bounded.
2. Cancellation tests pass.
3. Pinning compile-fail tests pass.
4. Local `!Send` executor compile tests pass.

## Milestone 6 - WAL, I/O safety, and crash recovery

Scope:

1. WAL append, durable sync, checkpoints, replay.
2. `omniflow-io` descriptor/handle safety.
3. Vectored I/O.
4. Mmap archived views.
5. Pointer provenance and layout docs.
6. Crash and fuzz tests.

Definition of done:

```bash
cargo miri test -p omniflow-wal
cargo fuzz run wal_segment
omniflow chaos kill-restart --iterations 100
```

Additional acceptance:

1. Vectored write benchmark exists.
2. Unsafe WAL sites are audited.
3. WAL model tests pass.

## Milestone 7 - Plugins, native FFI, and ABI descriptors

Scope:

1. WASM plugin host.
2. C ABI plugin loader.
3. Rust 2024 unsafe extern and unsafe attribute policy.
4. Link-section plugin descriptor.
5. Tagged union attribute payload.
6. Panic quarantine.
7. ABI layout tests.
8. Generated C header.

Definition of done:

```bash
cargo test -p omniflow-plugin-api
cargo test -p omniflow-plugin-wasm
cargo test -p omniflow-plugin-cabi
cargo fuzz run plugin_abi
```

Additional acceptance:

1. Layout tests validate ABI structs.
2. Header generation is reproducible.
3. Invalid pointer and invalid tag fuzz cases fail safely.

## Milestone 8 - Embedded SDK and portability

Scope:

1. `no_std` core and SDK builds.
2. Fixed-capacity SDK event API.
3. Optional `alloc` support.
4. Embedded example.
5. Atomic cfg fallback.
6. `MaybeUninit` fixed-array staging if justified.

Definition of done:

```bash
cargo build -p omniflow-core --no-default-features
cargo build -p omniflow-sdk --target thumbv7em-none-eabihf --no-default-features
```

Additional acceptance:

1. SDK fixed-buffer mode allocates zero bytes.
2. Capacity compile-fail tests pass.
3. Docs explain panic strategy.

## Milestone 9 - Macros, build scripts, and feature topology

Scope:

1. `pipeline!` macro.
2. `topic!` macro.
3. `#[derive(OmniPlugin)]`.
4. `#[derive(ValidatedNewtype)]`.
5. `#[omniflow_stage]`.
6. Macro diagnostics and trybuild tests.
7. Build script check-cfg and header generation.
8. Feature matrix CI.

Definition of done:

```bash
cargo test -p omniflow-macros
cargo test -p omniflow-testkit compile_fail
cargo hack check --workspace --feature-powerset --depth 2
```

Additional acceptance:

1. Macro expansion snapshots pass.
2. Generated C header is checked.
3. Custom cfg typos fail CI.

## Milestone 10 - Performance, SIMD, observability, and labs

Scope:

1. Criterion benchmark suite.
2. Allocation tracking.
3. Flamegraph docs.
4. Optional CPU-feature optimized CRC/codec path.
5. Full metrics/tracing.
6. Labs for unstable/niche features.

Definition of done:

```bash
cargo bench --workspace
omniflow bench local
cargo test -p omniflow-labs --all-features
```

Additional acceptance:

1. Optimized paths beat safe baselines by documented margin.
2. Labs are isolated from production dependency graph.
3. Observability overhead benchmark is published.

## Milestone 11 - Production hardening and release discipline

Scope:

1. Complete docs.
2. Security/dependency checks.
3. Semver and MSRV policy.
4. Release artifacts.
5. End-to-end examples.
6. Rust esoterics ledger completed.

Definition of done:

```bash
cargo test --workspace --all-features
cargo test --workspace --no-default-features
cargo doc --workspace --no-deps --all-features
cargo deny check
cargo semver-checks check-release
```

Additional acceptance:

1. `rust-mastery-map.md` maps every concept to code and evidence.
2. `rust-esoterics-ledger.md` has no unresolved entries.
3. Unsafe audit has no stale reviews.

---

## 17. Example user journeys

### 17.1 Beginner local ingestion

```bash
omniflow init
omniflow config validate
omniflow ingest file examples/events.jsonl
```

### 17.2 Static high-performance pipeline

```rust
let pipeline = Pipeline::builder()
    .ingress(HttpIngress::new("0.0.0.0:8080")?)
    .stage(Filter::new(|event| event.topic() == topic!("sensor.temp")))
    .stage(JsonNormalize::new())
    .sink(FileSink::new("./out.jsonl")?)
    .build()?
    .run()
    .await?;
```

### 17.3 Borrowing async closure pipeline

```rust
let cache = MetadataCache::connect("http://localhost:9001").await?;

let stage = async_filter("known-device", async |event: EventRef<'_>| {
    let Some(device_id) = event.attributes().get_str("device.id") else {
        return false;
    };

    cache.contains(device_id).await
});

Pipeline::builder()
    .ingress(HttpIngress::new("0.0.0.0:8080")?)
    .stage(stage)
    .sink(HttpSink::new("http://localhost:9000/ingest")?)
    .build()?
    .run()
    .await?;
```

### 17.4 Dynamic plugin pipeline

```bash
omniflow plugin load ./plugins/normalize_temperature.wasm
omniflow plugin load ./target/release/libnative_crc_filter.so
omniflow server run --config omniflow.toml
```

### 17.5 Embedded fixed-buffer SDK

```rust
let mut event: FixedEvent<32, 128> = FixedEvent::new();
event.set_topic("sensor.temp")?;
event.set_payload(br#"{"value":42}"#)?;
let bytes = event.encode_frame()?;
client.send(bytes)?;
```

### 17.6 Crash recovery

```bash
omniflow server run --config wal-enabled.toml
omniflow chaos kill-restart --during wal-append --iterations 1000
omniflow wal inspect ./data/omniflow.wal
```

### 17.7 WAL inspection with ranges

```bash
omniflow wal inspect ./data/omniflow.wal --records 10..50
omniflow wal inspect ./data/omniflow.wal --records ..=100
omniflow wal inspect ./data/omniflow.wal --records 500..
```

### 17.8 Local thread-affine native plugin

```toml
[[pipeline.stage]]
kind = "native"
path = "./plugins/thread_affine_filter.so"
thread_affinity = "local"
```

This plugin is executed on a dedicated local executor. Its handle is intentionally `!Send`; compile-fail tests prove it cannot be moved to worker threads.

---

## 18. Release criteria

A release candidate is acceptable only if:

1. All required CI jobs pass.
2. All unsafe blocks are documented in `unsafe-audit.md`.
3. `rust-mastery-map.md` maps every major concept to code and tests.
4. `rust-esoterics-ledger.md` classifies every esoteric feature as core, optional, testkit, labs, or rejected.
5. Load tests prove bounded memory under overload.
6. Crash tests prove durable replay behavior.
7. Plugin tests prove panic, ABI mismatch, invalid tag, and invalid pointer handling fail safely.
8. `no_std` SDK target builds pass.
9. Public APIs have docs and doctests.
10. Dependency audit and semver checks pass.
11. Benchmarks include current numbers and comparison to prior release.
12. Feature matrix tests cover documented combinations.
13. Generated C headers match Rust ABI definitions.
14. All `#[allow]`/`#[expect]` exceptions are justified.
15. No production crate depends on `omniflow-labs`.

---

## 19. Highest-risk areas and mitigations

| Risk | Why it matters | Mitigation |
|---|---|---|
| Feature soup | Weakens product and mastery signal | Feature justification, simpler-alternative docs, esoterics ledger |
| Unsound custom DST | Validated topic wrapper uses unsafe conversion | Single audited module, validation tests, Miri |
| Unsound unsafe parser/WAL view | UB destroys credibility | Safe baseline, Miri, fuzzing, unsafe audit |
| Pointer provenance mistakes | Mmap and FFI are easy to get subtly wrong | Dedicated provenance/layout doc and raw-pointer quarantine |
| Invalid `repr` assumptions | Wire/disk/ABI layout bugs | No `repr(Rust)` for external data, layout tests, docs |
| Unbounded allocation | Data planes fail under overload | Admission budgets, `try_reserve`, failing-allocator tests |
| Async cancellation bugs | Dropped futures can corrupt state | Explicit cancellation docs and tests |
| Pinning theater | `Pin` can be superficial or unsound | True `!Unpin` reader, projection tests, docs |
| Plugin ABI unsoundness | FFI failure can corrupt host | Versioned ABI, panic quarantine, allocation contract, fuzzing |
| Unwind boundary mistakes | Panic across C ABI can be undefined | `catch_unwind`, `C-unwind` policy, tests |
| Dyn/static trait confusion | GAT/async traits are not direct plugin objects | Object-safe adapter layer and compile-fail tests |
| Trait upcasting misuse | Downcasting/inspection can become business logic | Restrict `Any` to diagnostics/extensions |
| no_std scope creep | Embedded support can dominate project | SDK only encodes/sends; server remains std-only |
| Broken feature flags | Common Rust workspace failure | cargo-hack, all-features/no-default CI, check-cfg |
| Over-optimized unsafe code | Performance code becomes unjustified risk | Safe baseline and 10% rejection rule |
| Misleading macro APIs | Generated code can hide complexity | Hand-written equivalents, expansion snapshots, trybuild |
| Labs contaminating core | Nightly experiments harm stability | Dependency graph check and release gate |

---

## 20. Final standard

OmniFlow v3 is complete only when a reviewer can inspect the repository and find:

1. A useful edge telemetry data plane.
2. Idiomatic Rust APIs for everyday users.
3. Advanced Rust where it materially improves the design.
4. Explicitly isolated labs for unstable or very niche Rust.
5. Narrow unsafe boundaries with precise invariants.
6. Strong compile-time guarantees where they reduce real runtime risk.
7. Runtime behavior validated under overload, cancellation, crash, malformed input, plugin failure, and platform variation.
8. Documentation that explains tradeoffs rather than merely naming features.
9. A Rust feature map that connects concepts to code, tests, and product value.
10. Benchmarks that decide whether optimization complexity remains justified.

The intended mastery signal is not that OmniFlow uses every Rust feature everywhere. The signal is that it knows where each feature belongs.
