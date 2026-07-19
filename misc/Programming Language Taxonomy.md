

|Column|Meaning|
|---|---|
|**Canonical representative**|The language most representative of the class under a specific interpretation: origin, pure specimen, industrial exemplar, or research exemplar.|
|**Same-slot alternates**|Other languages that genuinely represent the same class.|
|**Ecosystem / implementation notes**|Runtimes, solvers, libraries, front ends, clones, or backends. These are not treated as alternate languages.|

### 1. Core computational paradigms

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Machine-level programming|**Assembly language**|RISC-V asm, x86-64 asm, MIPS asm|ISA-specific, not one universal language.|
|Imperative / procedural|**C**|Pascal, Ada, Modula-2|C remains the cleanest portable procedural systems specimen.|
|Structured programming|**ALGOL 60** as ancestor; **Pascal** as exemplar|Ada, Modula-2, Oberon|ALGOL 60 supplies block-structured ancestry; Pascal embodies the later teaching discipline.|
|Scientific imperative / HPC|**Fortran**|C, C++, Julia|Fortran remains the canonical legacy and current numerical-HPC lineage.|
|Business record processing|**COBOL**|RPG, ABAP, PL/I|Canonical for batch, records, reports, and enterprise transaction processing.|
|Pure lazy functional|**Haskell**|Clean|Haskell is the cleanest mainstream specimen of purity, laziness, static typing, and type classes.|
|Strict ML-family functional|**Standard ML**|OCaml, F#|SML is the formal/pedagogical anchor; OCaml is the pragmatic descendant.|
|Practical typed functional|**OCaml**|F#, Scala, Standard ML|More industrial/practical than SML, less pure than Haskell.|
|Minimal Lisp|**Scheme**|Racket|Canonical small Lisp with lexical scope, first-class procedures, and hygienic macro lineage.|
|Industrial Lisp / macro metaprogramming|**Common Lisp**|Scheme, Racket|Common Lisp is the large-scale Lisp with macros, conditions, CLOS, and image-based development.|
|Language-oriented programming|**Racket**|Common Lisp, JetBrains MPS, Rascal|Racket is the clearest “build languages as libraries” specimen.|
|Logic programming|**Prolog**|Mercury, λProlog|Prolog is the canonical facts/rules/query language with unification and backtracking.|
|Relational programming|**miniKanren**|αKanren, microKanren|`core.logic` is an implementation/embedding, not a separate paradigm representative.|
|Deductive database logic|**Datalog**|LogiQL, Datafun|Soufflé is best treated as a major Datalog system/dialect/compiler, not merely an alternate class.|
|Answer-set programming|**ASP / clingo-style ASP**|DLV-style ASP|Clingo and DLV are solver systems/ecosystems; ASP is distinct from Prolog and Datalog because of stable-model/answer-set semantics.|
|Constraint modeling|**MiniZinc**|AMPL, Essence, OPL|MiniZinc is the clean open modeling-language representative.|
|Rule-based expert systems|**CLIPS**|OPS5|Jess is better treated as a CLIPS-inspired Java rule engine/ecosystem entry.|
|Term rewriting / equational logic|**Maude**|OBJ, Stratego|Canonical executable rewriting-logic style.|
|Array programming|**APL**|J, K, q, BQN|APL is the archetype; J/K/q/BQN are descendants or modern variants.|
|Matrix-first numerical programming|**MATLAB**|Scilab, Julia in some uses|Octave is a MATLAB-compatible clone, not a paradigm alternate in the same sense.|
|Stack programming|**Forth**|PostScript|Forth is practical/extensible; PostScript overlaps as a stack-based page-description language.|
|Pure concatenative programming|**Joy**|Factor, Cat|Joy is the cleaner theoretical concatenative representative; Forth is the practical ancestor.|
|Symbolic computation / CAS|**Wolfram Language**|Macsyma/Maxima, Maple|Mathematica removed: it is not a separate language alternate.|
|Regular-expression language|**Perl-compatible regex**|POSIX regex, Oniguruma-style regex|Regexes are small formal-pattern languages embedded in many hosts.|
|Grammar specification|**BNF / EBNF**|ANTLR grammars, yacc grammars|Parser-generator grammars are DSLs over grammar formalisms.|

### 2. Object models

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Class-based OO origin|**Simula**|Smalltalk|Simula is the historical origin for classes, objects, inheritance, and simulation-driven OO.|
|Pure message-passing OO|**Smalltalk**|Ruby, Objective-C|Smalltalk is the clean “objects + messages” exemplar.|
|Industrial nominal class OO|**Java**|C#, C++|Java is the mainstream class/interface/inheritance/package specimen.|
|Zero-overhead systems OO|**C++**|Ada, Objective-C|C++ combines class OO, RAII, templates, and systems-level control.|
|Prototype-based OO|**Self**|JavaScript, Io|Self is the pure canonical prototype language; JavaScript is the industrial exemplar.|
|Generic-function / multiple-dispatch OO|**CLOS**|Julia, Dylan|CLOS is the classic generic-function object model; Julia is the modern technical-computing exemplar.|
|Aspect-oriented programming|**AspectJ**|Hyper/J, Spring AOP style|Spring AOP is framework/ecosystem; AspectJ is the language-level exemplar.|
|Actor-object hybrid|**Erlang** for actors; **Pony** for typed actor objects|Akka/Scala|Erlang belongs more strongly under actors; Pony is a typed object/actor language.|

### 3. Type-system and abstraction axes

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Dynamic typing|**Python**|Ruby, JavaScript, Scheme|Python is the modern general-purpose dynamic-typing exemplar.|
|Optional / erased typing|**TypeScript**|Flow, JSDoc type checking|TypeScript is optional, structural, erased, and intentionally unsound; not sound gradual typing.|
|Sound gradual typing|**Typed Racket**|Reticulated Python, Pyret-style systems|Typed Racket is the canonical research/production example because typed/untyped boundaries can be enforced with contracts.|
|Hindley–Milner inference|**ML / Standard ML**|OCaml, Haskell|This is a type-system projection of the ML family, not a duplicate of the functional row.|
|Module/functor systems|**Standard ML**|OCaml|SML is the cleanest formal module-system representative.|
|Type classes / constrained ad-hoc polymorphism|**Haskell**|PureScript, Scala, Rust traits|Haskell is canonical; Rust traits are the systems-language descendant.|
|Generic programming|**C++ templates**|Ada generics, Rust generics, Haskell type classes|C++ is the industrially canonical compile-time generic-programming language.|
|Ownership / borrowing|**Rust**|Cyclone, Linear Haskell, Clean uniqueness types|Rust is the mainstream canonical ownership/borrow-checking language.|
|Linear / affine resource typing|**Linear Haskell**|Rust, Clean, ATS|Rust is practical; Linear Haskell is closer to the type-theoretic axis.|
|Refinement types|**Liquid Haskell**|F*, Dafny, Flux/Rust research|Canonical for SMT-backed predicates refining ordinary types.|
|Dependent types for programming|**Agda**|Idris, Lean, Rocq/Coq Gallina|Agda is the clean specimen; Idris is more general-purpose-programming oriented.|
|Effect systems|**Koka**|Eff, Links, Frank|Koka is the clearest modern typed-effect language.|
|Algebraic effects / handlers|**Eff**|Koka, Multicore OCaml-style effects|OCaml 5 has effects, but as a mainstream host rather than the pure research specimen.|
|Session types / protocol typing|**Scribble**|Links, Effpi, session-typed Haskell/Scala systems|Scribble is a protocol-language exemplar rather than a general-purpose language.|
|Structural object typing|**TypeScript**|OCaml object types, Go interfaces|TypeScript is canonical for mainstream structural object typing.|

### 4. Concurrency, distribution, time, and reactivity

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Actor model|**Erlang**|Elixir, Pony|Akka is a framework/library ecosystem, not a language in the same sense.|
|CSP / channel concurrency|**occam**|Go, XC|occam is the paradigmatic CSP language; Go is the industrial descendant.|
|Async event loop|**JavaScript**|Python `asyncio`, Lua in evented hosts|Node.js is a runtime/ecosystem for JavaScript, not a language alternate.|
|Monitor/thread concurrency|**Mesa** historically; **Java** industrially|Concurrent Pascal, C#|Java is the mainstream monitor/thread teaching exemplar.|
|Software transactional memory|**Clojure**|Haskell STM|Clojure is the canonical mainstream STM language.|
|Dataflow programming|**Lucid** theoretically; **LabVIEW** visually|SISAL, Oz dataflow variables|LabVIEW is visual dataflow; Lucid is the older textual dataflow representative.|
|Visual dataflow engineering|**LabVIEW**|Simulink, Max/MSP|Simulink is modeling/simulation-oriented; Max/MSP is media/dataflow-oriented.|
|Synchronous reactive programming|**Lustre**|Esterel, SIGNAL|SCADE is a tool/language ecosystem based on this lineage.|
|Functional reactive programming|**Fran / Yampa**|Reflex, reactive-banana|Elm should not be used as the canonical FRP row; it is better under reactive UI/MVU. Yampa is a Haskell-embedded FRP DSL.|
|Reactive UI / MVU|**Elm**|React/Redux style, SwiftUI-style architectures|Elm’s canonical architecture is Model–View–Update: model, view, update.|
|Distributed fault-tolerant systems|**Erlang**|Elixir|Erlang is canonical both for actors and telecom-style fault tolerance.|
|Productive parallel HPC|**Chapel**|X10, Fortress, UPC|Chapel is the surviving HPCS-style productive-parallel-language exemplar.|
|GPU kernel programming|**CUDA C/C++**|OpenCL C, SYCL, ISPC|CUDA is the industrial CUDA/NVIDIA ecosystem anchor.|
|Shader programming|**GLSL**|HLSL, WGSL, Metal Shading Language|Canonical for graphics pipeline stage programming.|
|Stream processing DSLs|**StreamSQL / Flink SQL style**|ksqlDB, Beam-style pipelines|Mostly embedded in data-processing systems rather than standalone languages.|

### 5. Systems, scripting, operational, and infrastructure languages

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Systems programming|**C**|C++, Zig, Rust|C is still the canonical portable systems language.|
|Safe systems programming|**Rust**|SPARK Ada, Cyclone|Rust is the mainstream ownership-based safe-systems exemplar.|
|Manual-resource systems programming|**C++**|C, Zig, Ada|Kept distinct from “systems OO” only when emphasizing RAII/templates/resource control.|
|General scripting|**Python**|Ruby, Perl|Python is the modern canonical scripting/glue/general automation language.|
|Text/glue scripting|**Perl**|Python, Ruby|Perl is the historical Unix regex/text/glue scripting exemplar.|
|Shell command language|**POSIX sh** / **Bash**|zsh, fish|Bash is the mainstream interactive/scripting shell; POSIX sh is the portability anchor.|
|Object pipeline shell|**PowerShell**|Nushell|PowerShell is canonical for object-valued shell pipelines.|
|Text pattern/action processing|**AWK**|sed, Perl|AWK is the pattern-action text-processing language.|
|Embeddable extension language|**Lua**|Tcl, Guile Scheme|Lua is the game/tool embedding exemplar; Tcl is the command-language ancestor.|
|Build/dependency language|**Make**|Bazel/Starlark, Shake|Ninja is more build-file executor/generator target than canonical human-authored language.|
|Hermetic functional package/config language|**Nix**|Guix Scheme, Dhall|Nix is canonical for purely functional package/build configuration.|
|Infrastructure-as-code configuration|**Terraform HCL**|Pulumi languages, AWS CDK languages|HCL is the Terraform declarative configuration language; Pulumi/CDK are host-language APIs.|
|Typed configuration / data validation|**CUE**|Dhall, Jsonnet|YAML/JSON are data formats, not strong programming-language exemplars.|
|Policy language|**Rego**|Cedar, XACML|Canonical modern policy-as-code language.|
|Smart contracts|**Solidity**|Move, Michelson, Clarity|Solidity is the industrial Ethereum exemplar; Move is important for resource-oriented smart contracts.|
|PLC / industrial control|**Structured Text**|Ladder Logic, Function Block Diagram|IEC 61131-3 language family; Ladder is visual/relay-logic style.|
|Hardware description|**Verilog**|VHDL|Verilog is the classic canonical HDL.|
|Hardware verification|**SystemVerilog**|e / Specman|UVM is a SystemVerilog verification methodology/library, not a language alternate.|
|Hardware construction language|**Chisel**|Bluespec SystemVerilog, Clash|Chisel is embedded in Scala; Bluespec is rule-based HDL.|
|Page-description language|**PostScript**|PDF imaging model|PostScript also overlaps with stack programming.|
|Typesetting macro language|**TeX**|troff|LaTeX is a macro package/format over TeX, not the clean alternate-language entry.|
|Physical-system modeling|**Modelica**|Simscape, Simulink|Modelica is the textual acausal modeling-language exemplar.|

### 6. Formal methods, specification, and verification

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Dependent-type proof assistant|**Rocq / Coq**|Lean, Agda|Rocq is the current name of the former Coq Proof Assistant; Lean is the modern fast-growing proof/programming ecosystem.|
|HOL proof assistant|**Isabelle/HOL**|HOL4, HOL Light|Canonical higher-order-logic proof-assistant lineage.|
|Mathematical proof assistant|**Lean**|Rocq, Isabelle/HOL, Mizar|Lean is especially canonical for current formalized mathematics communities.|
|Auto-active verification language|**Dafny**|Viper, WhyML|Canonical for code plus specifications plus SMT-backed verification.|
|Proof-oriented effectful programming|**F***|WhyML, Dafny|F* is the dependent/effectful verification-programming exemplar.|
|Verified high-integrity imperative|**SPARK Ada**|Ada + contracts, MISRA C + tools|SPARK is the industrial proof-oriented Ada subset/ecosystem.|
|Deductive verification platform|**WhyML / Why3**|Boogie, Viper|Often serves as an intermediate verification language.|
|Temporal/action system specification|**TLA+**|Promela/SPIN for model checking; Event-B for refinement|PlusCal is not an alternate to TLA+; it translates to TLA+.|
|Relational model finding|**Alloy**|Z, B/Event-B|TLA+ removed from this slot. Kodkod is Alloy’s model-finding backend, not an alternate language.|
|State-based formal specification|**Z notation**|B, Event-B, VDM|Z is set-theoretic/schema-based; better neighbor for Alloy than TLA+.|
|Process algebra / protocol modeling|**CSPm**|Promela, mCRL2, LOTOS|Distinct from actor/CSP implementation languages.|
|SMT solver interchange language|**SMT-LIB**|TPTP for theorem proving|Z3, CVC5, Yices are solvers, not language alternates.|
|C annotation/specification language|**ACSL**|JML for Java, SPARK contracts for Ada|ACSL is canonical around Frama-C-style C verification.|

### 7. Data, query, statistical, scientific, and AI-adjacent DSLs

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Relational database/query|**SQL**|Tutorial D, Rel|PostgreSQL/MySQL/SQLite are implementations/systems, not language alternates.|
|RDF graph query|**SPARQL**|—|Canonical for RDF triple/graph querying.|
|Property-graph query|**Cypher**|GQL, Gremlin|GQL is the standardization direction; Cypher is the practical canonical syntax.|
|XML query/transformation|**XQuery**|XPath, XSLT|XSLT is transformation-first; XPath is selector/query sublanguage.|
|JSON query/transformation|**jq**|JSONata, JMESPath|jq is the canonical programmable JSON pipeline language.|
|Statistical programming|**R**|S, SAS, Stata|R is the canonical open statistical-computing language.|
|Split-apply-combine dataframe programming|**dplyr**|pandas, Polars, data.table|dplyr is a grammar of data manipulation; pandas/Polars are APIs/libraries, though they function as embedded DSLs.|
|Numerical engineering|**MATLAB**|Julia, NumPy/SciPy Python, Scilab|MATLAB is matrix-first; Julia is more general technical computing.|
|Modern scientific multiple dispatch|**Julia**|—|Julia overlaps with multiple-dispatch OO and scientific computing.|
|Symbolic mathematics|**Wolfram Language**|Macsyma/Maxima, Maple|Same correction as above: Mathematica is not the alternate.|
|Probabilistic statistical modeling|**Stan**|PyMC, Turing.jl|Stan is the practical canonical Bayesian/statistical modeling language.|
|Historical Bayesian PPL|**BUGS**|JAGS, WinBUGS, OpenBUGS|BUGS is the historical graphical-model Bayesian PPL lineage.|
|Universal/generative probabilistic programming|**Church**|WebPPL, Anglican, Gen|Church/WebPPL are canonical research exemplars; Gen is important for programmable inference.|
|Differentiable programming|**Dex** research-wise; **Swift differentiable programming** as language-feature exemplar|Julia/Zygote-style systems, JAX as embedded Python framework|JAX/PyTorch are frameworks, not standalone languages. Swift’s differentiable-programming work is a language-feature exemplar.|
|Agent-based modeling|**NetLogo**|StarLogo, Repast DSLs|NetLogo is the canonical educational/scientific ABM language.|
|Simulation modeling|**Modelica**|Simulink, GPSS|Modelica is acausal physical modeling; GPSS is classic discrete-event simulation.|

### 8. Quantum programming

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Quantum algorithm language|**Q#**|Quipper, Silq|Q# is the current industrial standalone language exemplar from Microsoft.|
|Quantum embedded circuit DSL|**Qiskit** as Python-embedded DSL/SDK|Cirq, PennyLane|Qiskit is officially an SDK for constructing/optimizing/executing quantum circuits, so it belongs in ecosystem/embedded-DSL space rather than “standalone language.”|
|Functional quantum programming|**Quipper**|Proto-Quipper, QWire|Quipper is the canonical scalable functional quantum-language research exemplar.|
|Safe high-level quantum programming|**Silq**|—|Silq is notable for high-level quantum programming with a static type system and safe automatic uncomputation.|

### 9. Educational, end-user, and visual languages

|Class|Canonical representative|Same-slot alternates|Ecosystem / implementation notes|
|---|--:|--:|---|
|Beginner interactive programming|**BASIC**|Python, Pascal|BASIC is the historical canonical beginner-access language.|
|Educational turtle programming|**Logo**|NetLogo, StarLogo|Logo is the turtle/constructivist educational archetype.|
|Block-based novice programming|**Scratch**|Blockly, Snap!|Scratch is the canonical modern blocks language.|
|End-user spreadsheet programming|**Excel formulas**|Google Sheets formulas, Lotus 1-2-3|Spreadsheets are end-user functional/dataflow programming environments, even if not always classified as PLs.|
|Visual dataflow|**LabVIEW**|Simulink, Max/MSP|Listed once here conceptually; also relevant to concurrency/dataflow, but not duplicated as a separate row.|
|Visual block/dataflow for children|**Scratch**|Blockly, Snap!|Different from LabVIEW: novice education rather than engineering dataflow.|
|Notebook-centered computational language use|**Wolfram notebooks / Mathematica environment**|Jupyter notebooks|This is an interaction environment, not a separate language class.|

## Condensed canon after the corrections

|Class|Canonical answer|
|---|--:|
|Imperative / procedural|**C**|
|Structured|**ALGOL 60** ancestor; **Pascal** exemplar|
|Systems|**C**|
|Safe systems|**Rust**|
|Class-based OO origin|**Simula**|
|Pure message OO|**Smalltalk**|
|Industrial OO|**Java**|
|Prototype OO|**Self**; **JavaScript** industrially|
|Multiple dispatch|**CLOS**; **Julia** modernly|
|Pure lazy FP|**Haskell**|
|Strict typed FP|**Standard ML**; **OCaml** practically|
|Minimal Lisp|**Scheme**|
|Industrial Lisp/metaprogramming|**Common Lisp**|
|Language-oriented programming|**Racket**|
|Logic|**Prolog**|
|Relational programming|**miniKanren**|
|Deductive database|**Datalog**|
|Answer-set programming|**ASP / clingo-style ASP**|
|Constraint modeling|**MiniZinc**|
|Relational query|**SQL**|
|Array|**APL**|
|Stack|**Forth**|
|Concatenative|**Joy** / **Factor**|
|Symbolic computation|**Wolfram Language**; alternates **Macsyma/Maxima**, **Maple**|
|Scripting|**Python**|
|Shell|**POSIX sh / Bash**|
|Text processing|**AWK**|
|Actor model|**Erlang**|
|CSP/channel concurrency|**occam**; **Go** industrially|
|Async event loop|**JavaScript**|
|Synchronous reactive|**Lustre**|
|Functional reactive programming|**Fran / Yampa**|
|Reactive UI / MVU|**Elm**|
|Visual dataflow|**LabVIEW**|
|Generic programming|**C++**|
|Optional erased typing|**TypeScript**|
|Sound gradual typing|**Typed Racket**|
|Dependent typed programming|**Agda** / **Idris**|
|Proof assistant|**Rocq/Coq**, **Lean**|
|HOL proof assistant|**Isabelle/HOL**|
|Auto-active verification|**Dafny**|
|Verified high-integrity imperative|**SPARK Ada**|
|Temporal/action specification|**TLA+**|
|Relational model finding|**Alloy**|
|Statistical programming|**R**|
|Numerical/matrix|**MATLAB**|
|Scientific/HPC|**Fortran**|
|Modern technical computing|**Julia**|
|Dataframe split-apply-combine|**dplyr**; pandas/Polars as embedded API exemplars|
|Hardware description|**Verilog**|
|Hardware verification|**SystemVerilog**|
|Rule-based expert systems|**CLIPS**|
|Probabilistic programming|**Stan**, **BUGS**, **Church/WebPPL/Gen** by subfamily|
|Quantum programming|**Q#**, **Quipper**, **Silq** by subfamily|
|Build/dependency|**Make**|
|Functional package/config|**Nix**|
|Infrastructure config|**Terraform HCL**|
|Policy-as-code|**Rego**|
|Educational blocks|**Scratch**|
|Educational turtle|**Logo**|
|Beginner interactive|**BASIC**|


Forced 15 item compression:

1. Systems and performance programming — C; C++ and Rust as the abstraction and safety branches. Folds machine-level, imperative/procedural, all three systems rows, generic programming, ownership, and the GPU/shader rows (CUDA is a C++ dialect). C stays canonical as the ABI substrate; the doc's own three-way systems split is the eras of one domain.


2. Managed industrial OO — Java (C#). Folds industrial nominal OO, monitor/thread concurrency, and absorbs Simula/Smalltalk as origins and COBOL as the legacy stratum it displaced. Java earns it on ecosystem mass, not design merit.


3. The web platform — JavaScript/TypeScript. Folds async event loop, industrial prototype OO, optional erased typing, structural object typing, and MVU (Elm as concept source). Four of the doc's rows are projections of one deployment monopoly: the browser.


4. Scripting and automation — Python; strata: AWK/Perl (text), Bash/PowerShell (process composition), Lua/Tcl (embedding). Folds general scripting, dynamic typing, text rows, regex, both shell rows, and embeddable extension. One super-domain — coordination of existing programs and text — with four honest sub-models. Demoting Lua from a standalone slot is the cost of importance-weighting; I'd defend it reluctantly.


5. Typed functional programming — Haskell; SML/OCaml as the strict lineage. Folds pure-lazy FP, both ML rows, Hindley–Milner, type classes, modules, and the refinement/linear/effects research periphery, which are features of this tradition rather than domains.


6. Lisp and language-oriented metaprogramming — Scheme, Common Lisp, Racket jointly. The doc's three rows are one irreducible axis: homoiconicity and syntactic abstraction. No other slot can absorb "programs that write programs" without losing the concept.


7. Logic, constraint, and rule systems — Prolog; Datalog and MiniZinc as the industrial descendants. Folds logic, relational programming (miniKanren), deductive databases, ASP, constraint modeling, expert systems, and rewriting. Computation as deduction/search over declarations; Prolog is origin, Datalog is where it actually ships (static analysis, Datomic).


8. Declarative query — SQL; SPARQL/Cypher/jq for graph and document shapes. Folds the §7 query rows. SQL alone justifies the slot: fifty years unreplaced, the most-executed declarative language in existence.


9. Statistical and probabilistic computing — R; Stan as the Bayesian frontier. Folds statistical programming, dataframe grammars, and all three PPL rows. R is where statistics is natively spoken; probabilistic programming is that domain's live edge, not a separate one.


10. Numerical, array, and symbolic scientific computing — Fortran/MATLAB/Julia; APL lineage and Wolfram Language as the array and symbolic poles. Folds scientific HPC, matrix-first, array programming, symbolic computation, and Chapel. One domain — mathematics executed — with Julia as the ongoing unification attempt.


11. Concurrent and fault-tolerant distributed systems — Erlang; Go as the CSP-industrial pole (occam as ancestor). Folds actor model, CSP/channels, distributed fault tolerance, and STM as a footnote. The doc's Erlang duplication resolves itself once these rows merge.


12. Formal specification and verification — Rocq/Lean for proof, TLA+ for design-level specification; Dafny, SPARK, Alloy, Isabelle in between. Folds all of §6 plus dependent-typed programming. Two genuinely different activities (proving programs vs. model-checking designs) sharing one correctness-by-construction domain.


13. Hardware and physical-system description — Verilog/SystemVerilog; VHDL, Chisel, plus Lustre, Structured Text, and Modelica as the control-and-modeling stratum. Folds HDL, hardware verification and construction, synchronous reactive, PLC, and simulation modeling. The unifying idea: describing concurrent physical/temporal systems rather than instruction streams — the taxonomy's only fully non-von-Neumann territory.


14. Build, configuration, and infrastructure — Make as ancestor; Nix and Terraform HCL as the modern declarative poles, CUE/Rego adjacent. Folds the §5 infra rows. Underrated expansive: every deployed system passes through these languages.


15. End-user and educational programming — Excel formulas; Scratch/Logo/BASIC for pedagogy. Folds §9. Spreadsheet formulas are, by user count, the most-used functional language ever shipped


