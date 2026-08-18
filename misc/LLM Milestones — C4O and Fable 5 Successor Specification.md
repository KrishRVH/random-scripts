# AI Engineering Milestones — C4O and Fable 5 Successor Specification

_Last verified: **August 17, 2026**, America/Chicago._

## 1. Purpose

The original **Claude 4 Opus**—abbreviated **C4O**—was the reference moment when agent-driven software engineering began to feel like an irreversible change to the field.

This specification tracks two forms of capability abundance:

1. **Cloud abundance:** frontier-level intelligence becomes extremely fast and extremely inexpensive.
2. **Local ownership:** the same class of intelligence becomes practical on one consumer RTX 4090 24GB.

It defines two generations of milestones:

- **Milestone A:** successors to original C4O.
- **Milestone B:** successors to Claude Fable 5.

This document supersedes the original strict handoff. The previous requirement—prove superiority on every accepted benchmark row with no missing evidence—was useful for avoiding hype, but too restrictive for identifying when the practical technological event had occurred.

The governing question is now:

> Has this model crossed the reference point strongly enough that, for real agentic software-engineering work, the old model is no longer the meaningful choice?

Benchmarks remain important, but they are evidence rather than the definition of the milestone.

---

## 2. Current status

| Milestone | Status | Current crossing |
|---|---|---|
| **A1 — Fast, cheap cloud C4O successor** | **Achieved** | GPT-5.6 Luna is the full multimodal crossing. DeepSeek V4 Flash 0731 is a text-only crossing. |
| **A2 — Local C4O successor on RTX 4090** | **Core crossing achieved; completion pending** | Qwen3.8-27B has crossed the practical capability milestone. The remaining requirement is more than 200K usable local context. |
| **B1 — Fast, cheap cloud Fable 5 successor** | **Open** | No current model combines Fable-level capability, at least 100 output tokens/second, Luna-class economics, vision, and the complete 1M-context envelope. |
| **B2 — Local Fable 5 successor on RTX 4090** | **Open** | No current model provides Fable-level agency, multimodality, and 1M usable context on one 24GB RTX 4090. |

---

## 3. Status vocabulary

### Full crossing

The candidate satisfies the intended capability, speed, economics, context, and modality envelope.

It does not need to win every benchmark row. It must instead show:

- A substantial broad capability lead or parity with the reference.
- No known regression that materially breaks the intended workflow.
- Practical confirmation from independent evaluations or direct use.

### Text-only crossing

The candidate satisfies the intelligence, speed, context, and economics requirements, but lacks image input.

This is a valid crossing for text-based coding agents, but not a complete replacement for a multimodal reference model.

### Core crossing achieved; completion pending

The central technological event has occurred, but one deliberately retained requirement remains unresolved.

For A2, Qwen3.8-27B has reached the required local capability class. The remaining requirement is the full context target.

### Open

No accepted candidate currently produces the intended experience.

---

## 4. How measurements should be interpreted

### Speed

The hard cloud threshold is:

> **At least 100 generated output tokens per second.**

This means sustained decode speed after generation begins. Time to first answer token is recorded separately because a reasoning model may decode rapidly after spending a long time thinking.

A model can therefore pass the speed threshold while retaining a latency caveat.

### Intelligence

“More capable than the reference” means broadly and practically more capable for agent-driven software engineering.

Evidence should include some combination of:

- Independent aggregate evaluations.
- Coding-agent evaluations.
- Long-horizon repository tasks.
- Tool use and instruction following.
- Multimodal software work.
- Direct experience in the intended workflow.

Universal dominance across every specialist benchmark is no longer required.

### Token efficiency and task economics

Price per million tokens is insufficient by itself. Every serious comparison should track:

- Output and reasoning tokens per task.
- Total agent tokens per task, including cached context where reported.
- Task success or quality.
- Cost per task.
- Agent steps or turns.
- Wall-clock duration.

A verbose model can still qualify when its per-token price is so low that its practical task cost remains negligible. Conversely, an inexpensive list price does not qualify when excessive token use erases the economic advantage.

### Context

Three context numbers must remain distinct:

1. **Advertised context:** the provider or model-card limit.
2. **Native model context:** supported without extrapolation or scaling.
3. **Usable local context:** the largest stable context actually demonstrated on the exact hardware and runtime.

Only the third number determines local milestone completion.

---

# Milestone A — Original C4O Successors

## 5. Frozen C4O baseline

**C4O** always means the original Claude 4 Opus release:

| Attribute | C4O baseline |
|---|---|
| Exact API model | `claude-opus-4-20250514` |
| Reasoning mode | Extended thinking |
| Context | 200K tokens |
| Modalities | Text and image input; text output |
| Launch price | $15/M input; $75/M output |
| Weights | Closed |
| Artificial Analysis Intelligence Index | 32*, estimated historical result |
| Current paired AA task economics | Unavailable |
| Current DeepSWE result | Unavailable |

Artificial Analysis marks the C4O score with an asterisk because it is an estimated historical result rather than a fresh execution of the complete current suite. It is a useful directional intelligence bar, not a pristine simultaneous comparison.

The best retained token-use proxy from the original handoff is Kagi’s private benchmark row:

| Metric | C4O proxy |
|---|---:|
| Accuracy | 74.3% |
| Reported tokens per task | 17,058 |
| Mean time per task | 13.3 seconds |

That result is not interchangeable with Artificial Analysis or DeepSWE. It remains useful only as a directional record of how token-efficient C4O felt on one historical task set.

No defensible current value exists for C4O’s:

- Artificial Analysis output tokens per weighted task.
- Artificial Analysis cost per task.
- DeepSWE output tokens or cost per task.
- Current Coding Agent Index economics.

Those fields must remain unknown rather than being reconstructed from unrelated benchmarks.

---

## 6. Milestone A1 — Fast, cheap cloud C4O successor

### Target experience

A full A1 crossing should provide:

| Dimension | Target |
|---|---|
| Capability | Broadly better than C4O for agentic software engineering |
| Output speed | **At least 100 tokens/second** |
| Economics | Luna-class comfortable pricing and negligible practical task cost |
| Token behavior | Reasonable enough that verbosity does not erase the speed or cost advantage |
| Context | At least 200K |
| Modalities | Text and image input for a full crossing |
| Tool use | No material regression for coding agents |

**Luna-class pricing** is the preferred reference, not an inflexible ceiling:

- Approximately **$0.20/M input**
- Approximately **$1.20/M output**
- Roughly the same near-negligible cost class after actual task token consumption

A model may be somewhat more expensive per token and still qualify when cost per successful task remains comparably low.

### Current crossings

| Candidate | AA Index | Output speed | Context | Vision | List price per M input/output | AA output tokens/task | AA cost/task | Status |
|---|---:|---:|---:|---|---:|---:|---:|---|
| **GPT-5.6 Luna `max`** | 52 | **171.2 tok/s** | 1.05M | Yes | **$0.20 / $1.20** | ≈20K | **$0.05** | **Full A1 crossing** |
| **DeepSeek V4 Flash 0731 `max`** | 52 | **103.4 tok/s** | 1M | **No** | $0.44 / $1.32 peak | ≈46K | **$0.11** | **Text-only A1 crossing** |

Luna’s official API envelope includes 1.05M context, 128K maximum output, image input, tool support, and the listed $0.20/$1.20 pricing. Artificial Analysis measures 52 intelligence, 171.2 output tokens/second, approximately 20K weighted output tokens per task, and $0.05 per Intelligence Index task.

DeepSeek V4 Flash 0731 scores 52, generates 103.4 tokens/second, supports 1M context, and costs $0.44/M input and $1.32/M output at the current peak rate. Its approximately 46K output tokens per Intelligence Index task are substantially more than Luna’s, but its cost remains only $0.11 per task. It is open-weight and MIT-licensed, but accepts text only.

### Interpretation

#### GPT-5.6 Luna

Luna satisfies the intended event:

- Broad independent capability is well above the historical C4O aggregate.
- Decode speed comfortably exceeds 100 tokens/second.
- Pricing is in the desired negligible-cost class.
- It retains vision, tools, and more than 1M context.
- Its measured task cost remains tiny despite nontrivial reasoning-token use.

Luna’s **120.23-second time to first answer token at `max`** is a real caveat. It means “fast” here describes generation throughput, not instantaneous completion. The distinction should remain visible, but it does not reverse the A1 crossing under the chosen definition.

#### DeepSeek V4 Flash 0731

DeepSeek crosses the intended text-agent milestone:

- It narrowly clears the hard 100-token/second threshold.
- It substantially exceeds the historical C4O aggregate result.
- It provides 1M context.
- Its effective cost remains extremely low.

Its limitations are equally clear:

- No image input.
- Greater reasoning verbosity.
- Lower current DeepSWE success than Luna.

On the shared DeepSWE v1.1 leaderboard, DeepSeek uses 108K output tokens and 153 steps per task, compared with Luna’s 73K output tokens and 102 steps. Nevertheless, DeepSeek costs only $0.10 per task versus Luna’s $0.61. It is token-inefficient relative to Luna, but still economically efficient.

### A1 verdict

> **Milestone A1 is achieved.**

- **Complete multimodal crossing:** GPT-5.6 Luna.
- **Text-only crossing:** DeepSeek V4 Flash 0731.

---

## 7. Milestone A2 — Local C4O successor on one RTX 4090

### Target experience

A complete A2 crossing requires:

| Dimension | Target |
|---|---|
| Hardware | One RTX 4090 with 24GB VRAM |
| Execution | Fully local; no cloud or second GPU |
| Weights | Downloadable and locally usable |
| Capability | Broadly C4O-level or better in the actual software-engineering workflow |
| Modalities | Text and image input |
| Context | **More than 200K usable local context** |
| Speed | Interactive enough for sustained agent use |
| Reliability | Stable multi-turn coding and tool workflows |

Local speed is intentionally practical rather than ceremonial:

- Approximately 15 generated tokens/second is acceptable.
- Approximately 30 or more is preferred.
- Stable agent execution matters more than a synthetic peak.

### Current candidate: Qwen3.8-27B

Qwen3.8-27B is a dense 27B vision-language model with Apache-2.0 weights, image and video understanding, configurable reasoning, 262,144 native context, and extension support up to 1M.

Artificial Analysis currently reports:

- Intelligence Index: **52**
- Total output generated during the Intelligence Index: **160M tokens**
- Hosted speed and task cost: not yet available on the exact AA model row

### Owner-observed result

On the intended RTX 4090 24GB system:

- Qwen3.8-27B already feels better than original C4O for the practical software-engineering workflow.
- It fits and runs locally at useful speed.
- The current usable context is approximately **96K**.

This direct workflow result is the decisive evidence for the core A2 event. A benchmark cannot substitute for the actual model, quantization, hardware, harness, and codebase combination being targeted.

### Remaining requirement

The completion target is now:

> Demonstrate **more than 200K stable, usable context** on the same RTX 4090 24GB system without making the model impractically slow or unreliable.

“Native 262K context” does not satisfy this requirement by itself. The exact local artifact must actually load and operate beyond 200K.

Future measurements should record:

- Quantization and checksum.
- Runtime and version.
- KV-cache precision.
- GPU and CPU offload.
- Peak VRAM and system RAM.
- Prompt-processing speed.
- Decode speed.
- Maximum stable context.
- Quality at that context.
- Multi-turn agent stability.

### A2 verdict

> **The central A2 capability event has occurred. The complete milestone remains open only on context.**

**Qwen3.8-27B is the first accepted practical local C4O successor.**  
The remaining finish line is **more than 200K usable context on one RTX 4090 24GB**.

---

# Milestone B — Claude Fable 5 Successors

## 8. Frozen Fable 5 baseline

Milestone B uses the deployed Claude Fable 5 experience as the new reference point.

| Attribute | Fable 5 baseline |
|---|---|
| API model | `claude-fable-5` |
| Positioning | Anthropic’s most capable widely released model |
| Intended workload | Long-running agents, difficult coding, complex knowledge work |
| Reasoning | Adaptive reasoning, always on |
| Context | **1M tokens** |
| Maximum output | **128K tokens** |
| Modalities | Text and image input; text output |
| Price | **$10/M input; $50/M output** |
| Prompt-cache discount | 90% on cached input |
| Weights | Closed |

Anthropic describes Fable 5 as a model for long-running agents that can plan across stages, delegate to sub-agents, check its own work, perform complex migrations, write tests, and use vision to validate implementation against intended designs.

### Deployed-product caveat

Fable 5 includes safety routing for some cybersecurity and biology requests. Artificial Analysis therefore labels its evaluated row:

> Claude Fable 5 — Adaptive Reasoning, Max Effort, Opus 4.8 Fallback

Milestone B uses this actual deployed experience rather than pretending that an unrestricted underlying model is separately available.

---

## 9. Fable 5 capability and economics profile

### Model-level Artificial Analysis profile

| Metric | Fable 5 |
|---|---:|
| Intelligence Index v4.1.1 | **62** |
| Output speed | **66.5 tok/s** |
| Time to first answer token | **141.52 seconds** |
| Weighted output tokens per AA task | ≈33.1K |
| Cost per AA task | **$3.14** |
| Total AA output tokens | **83M** |
| Total AA evaluation cost | **$5,455.22** |
| Context | 1M |
| Vision | Yes |

Artificial Analysis measures Fable at 62 intelligence, 66.5 output tokens/second, 141.52 seconds to first answer token, and $3.14 per weighted Intelligence Index task. The complete run generated 83M output tokens.

### Independent DeepSWE v1.1 profile

| Metric | Fable 5 `max` |
|---|---:|
| Pass rate | **70% ± 4%** |
| Average output tokens/task | **119K** |
| Average cost/task | **$21.63** |
| Agent steps/task | **88** |

DeepSWE v1.1 contains 113 original long-horizon engineering tasks and runs the compared models through mini-swe-agent for consistency.

### Artificial Analysis Coding Agent Index profile

Fable 5 `max` with fallback in Claude Code currently records:

| Metric | Result |
|---|---:|
| Coding Agent Index v1.3 | **66** |
| DeepSWE | 66% |
| Terminal-Bench v2 | 83% |
| SWE-Atlas-QnA | 49% |
| Average total tokens/task | **14M** |
| Average API cost/task | **$11.70** |
| Average wall time/task | **23.4 minutes** |

The 14M figure includes total agent token traffic—input, cached context, and output—across long multi-turn executions. It is not comparable to the 119K DeepSWE output-token figure.

### What the Fable bar represents

Fable 5 is not the speed or cost target. It is the **capability and workflow target**:

- High reliability on difficult, underspecified work.
- Long-horizon planning.
- Strong repository-scale engineering.
- Effective tool use.
- Multimodal validation.
- Self-testing and self-correction.
- Enough context to hold very large working sets.
- The ability to operate with limited supervision for extended periods.

Milestone B asks when that experience becomes either abundant in the cloud or locally owned.

---

## 10. Milestone B1 — Fast, cheap cloud Fable 5 successor

### Target experience

A full B1 crossing requires:

| Dimension | Target |
|---|---|
| Capability | Fable 5-level or better for long-horizon agentic software engineering |
| Output speed | **At least 100 tokens/second** |
| Economics | Approximately Luna-class pricing and similarly low cost per successful task |
| Context | **At least 1M usable context** |
| Output envelope | Sufficient for long autonomous runs; ideally near Fable’s 128K maximum |
| Modalities | Text and image input |
| Tool use | Mature coding, terminal, file, and structured tool behavior |
| Token behavior | No verbosity severe enough to erase the speed or cost advantage |

A text-only model may receive a **B1 text-only crossing**, but cannot be considered the complete successor.

### Practical capability threshold

No single benchmark defines Fable equivalence. A plausible candidate should show:

- Roughly Fable-class independent aggregate intelligence.
- Competitive coding-agent performance.
- No severe regression in long-horizon repository work.
- Strong instruction following and tool reliability.
- Comparable ability to maintain plans and recover from errors.
- Direct evidence from ambitious real-world projects.

An AA score of 62 is a useful marker, not a permanent mathematical cutoff. Benchmark revisions and model-specific strengths must be considered.

### Current candidates

#### GPT-5.6 Luna

Already satisfies:

- More than 100 output tokens/second.
- Luna-class pricing by definition.
- 1M-class context.
- Vision and tools.
- Very low task cost.

Still missing:

- Fable-level capability.
- Fable-level long-horizon coding-agent performance.
- Faster first-answer latency at maximum reasoning.

Its AA score of 52 remains materially below Fable’s 62, and its Coding Agent Index result of 59 in Codex is below Fable’s 66 in Claude Code. The harnesses differ, so this is directional rather than a pure model comparison.

#### DeepSeek V4 Flash 0731

Already satisfies:

- More than 100 output tokens/second.
- Extremely low cost.
- 1M context.
- Strong terminal-oriented agent performance.

Still missing:

- Fable-level broad intelligence.
- Fable-level long-horizon coding performance.
- Image input.
- Better token efficiency.

#### Qwen3.8-27B

Already provides:

- Open weights.
- Vision.
- 262K native context with extension support.
- A strong 52 AA result at only 27B parameters.

It does not currently have the accepted hosted speed, production economics, 1M default serving envelope, or Fable-level capability evidence required for B1.

### B1 verdict

> **Milestone B1 remains open.**

The likely future crossing is a model with approximately Fable-level agency, Luna-like pricing, at least 100 output tokens/second, vision, and 1M context.

---

## 11. Milestone B2 — Local Fable 5 successor on one RTX 4090

### Target experience

A complete B2 crossing requires:

| Dimension | Target |
|---|---|
| Hardware | One RTX 4090 24GB |
| Execution | Local only; no cloud or second GPU |
| Weights | Downloadable and locally usable |
| Capability | Fable 5-level practical agentic software engineering |
| Modalities | Text and image input |
| Context | **1M stable, usable local context** |
| Speed | Interactive enough for extended autonomous work |
| Reliability | Stable long-running tool and coding loops |
| Ownership | No dependency on a hosted proprietary inference service |

Indicative local speed:

- 15 tokens/second is acceptable.
- 30 or more is preferred.
- Stability, prompt processing, and long-context behavior matter more than peak decode speed.

### What “Fable-level” means locally

The candidate does not need to reproduce every Fable benchmark score. It must provide the same practical class of experience:

- Accept a large, difficult engineering objective.
- Understand a substantial repository.
- Construct and maintain a multi-stage plan.
- Use tools without constant correction.
- Implement, test, debug, and revise.
- Preserve goals across long executions.
- Use vision when the task requires it.
- Complete work that would currently justify selecting Fable 5.

### Context requirement

The 1M target is intentionally ambitious.

It refers to **actually usable context on the RTX 4090**, including enough generation headroom for the agent to continue working. A model card claiming 1M through RoPE scaling does not qualify when the local runtime fails, becomes unusably slow, or requires memory beyond the specified machine.

### B2 verdict

> **Milestone B2 remains open.**

Qwen3.8-27B establishes that C4O-class local agency is now practical. The next event is substantially harder: Fable-class agency plus multimodality and a full 1M working context on the same 24GB GPU.

---

## 12. Consolidated task-economics ledger

### Artificial Analysis model-level economics

| Model | AA Index | Output speed | First-answer latency | Weighted output tokens/task | Cost/task | Total AA output |
|---|---:|---:|---:|---:|---:|---:|
| **Original C4O** | 32* | — | — | — | — | — |
| **GPT-5.6 Luna `max`** | 52 | **171.2 tok/s** | 120.23 s | ≈20K | **$0.05** | 130M |
| **DeepSeek V4 Flash 0731 `max`** | 52 | **103.4 tok/s** | **1.19 s** | ≈46K | **$0.11** | 210M |
| **Qwen3.8-27B** | 52 | — | — | Not yet extracted reliably | — | 160M |
| **Claude Fable 5 `max` with fallback** | **62** | 66.5 tok/s | 141.52 s | ≈33.1K | **$3.14** | 83M |

The Luna and DeepSeek per-task values come from Artificial Analysis’s weighted task-token chart: approximately 14K reasoning plus 6K answer tokens for Luna, and 37K reasoning plus 9K answer tokens for DeepSeek. Model-level totals and costs come from the respective AA model pages.

### Long-horizon software-engineering economics

| Model | DeepSWE pass rate | Output tokens/task | Cost/task | Steps/task | AA Coding Agent Index | AA Coding Agent total tokens/task | AA Coding Agent cost/task |
|---|---:|---:|---:|---:|---:|---:|---:|
| **Original C4O** | — | — | — | — | — | — | — |
| **GPT-5.6 Luna `max`** | **67% ± 4%** | **73K** | $0.61 | 102 | 59 | 15.5M | **$0.31** |
| **DeepSeek V4 Flash `max`** | 53% ± 4% | 108K | **$0.10** | 153 | 55 | 20.9M | **$0.07** |
| **Qwen3.8-27B** | No accepted shared-leaderboard row | — | — | — | No exact 27B row | — | — |
| **Claude Fable 5 `max`** | **70% ± 4%** | 119K | **$21.63** | 88 | **66** | 14M | **$11.70** |

DeepSWE figures come from the shared v1.1 leaderboard. Artificial Analysis Coding Agent Index figures come from its current Claude Code and Codex model-variant table.

### Economic conclusions

1. **Luna is the strongest complete A1 economic crossing.** It combines the highest relevant decode speed, vision, 1M context, strong quality, and low task cost.

2. **DeepSeek is verbose but still extremely cheap.** It uses more output tokens and steps than Luna while solving fewer DeepSWE tasks, yet costs one-sixth as much on that benchmark.

3. **Fable is not especially token-wasteful at the model-evaluation level.** Its expense is driven primarily by its $10/$50 pricing. It generates fewer total AA output tokens than Luna, DeepSeek, or Qwen, but costs far more per task.

4. **Agent-harness token totals are a separate measurement.** A 14M-token coding-agent task can include repeatedly cached repository context and tool transcripts. It must not be compared directly with a 33K model-evaluation output count.

5. **No objective C4O corollary exists for the modern task-economics columns.** The Kagi 17,058-token result is retained as a historical proxy, not inserted into incompatible AA or DeepSWE tables.

---

## 13. Evidence hierarchy

Future evaluations should label evidence using these levels:

### 1. Owner-observed

Direct use on the intended hardware, harness, codebase, and workflow.

This is especially important for local milestones. It can outweigh a small benchmark difference because it measures the actual intended experience.

### 2. Independent same-harness evaluation

Examples include:

- Artificial Analysis.
- Shared DeepSWE leaderboard runs.
- Reproducible local tests using an exact artifact.

This is the strongest evidence for cross-model comparison.

### 3. Vendor-reported evaluation

Useful for understanding the model’s intended strengths, but not automatically comparable with another vendor’s numbers.

### 4. Community report

Useful for discovering plausible configurations and performance ranges. It should not establish a final milestone alone unless independently reproduced.

---

## 14. Future update protocol

For each serious candidate, record:

### Identity

- Exact model and checkpoint.
- Reasoning effort.
- Provider or local artifact.
- Quantization.
- Evaluation date.

### Capability

- Artificial Analysis Intelligence Index.
- Coding Agent Index and component evaluations.
- DeepSWE or a comparable long-horizon software benchmark.
- Vision and tool support.
- Direct workflow verdict.

### Speed

- Output tokens/second.
- Time to first answer token.
- Prompt-processing speed for local models.
- End-to-end wall time on representative tasks.

### Economics

- Input, cached-input, cache-write, and output prices.
- Long-context premiums.
- Output or reasoning tokens per task.
- Total agent tokens per task.
- Cost per task.
- Cost per successful task.

### Local deployment

- GPU, CPU, RAM, operating system.
- Runtime and commit.
- Quantization checksum.
- KV-cache precision.
- Offload.
- VRAM and RAM use.
- Maximum stable context.
- Decode and prefill speed.
- Ten-or-more-turn agent stability.

### Comparison discipline

- Do not substitute Qwen3.8 Max for Qwen3.8-27B.
- Do not treat advertised context as usable local context.
- Do not treat low list pricing as proof of low task cost.
- Do not compare token totals across different accounting definitions without labeling them.
- Preserve exact benchmark and harness versions.
- Keep Milestone A and Milestone B baselines historically fixed.

---

## 15. Final milestone definitions

### A1 — C4O cloud abundance

> Broadly better than original C4O, at least 100 output tokens/second, Luna-class inexpensive, reasonably token-efficient, and at least 200K context.

- **Full crossing:** includes vision.
- **Text-only crossing:** lacks vision.
- **Status:** **Achieved.**

### A2 — C4O local ownership

> Broadly C4O-level or better for real agentic software work, multimodal, open-weight, practical on one RTX 4090 24GB, and capable of more than 200K usable local context.

- **Status:** **Core crossing achieved by Qwen3.8-27B.**
- **Completion condition:** exceed 200K stable context on the intended 4090 setup.

### B1 — Fable cloud abundance

> Fable 5-level long-horizon agency, at least 100 output tokens/second, approximately Luna-class economics, vision, mature tools, and at least 1M usable context.

- **Status:** **Open.**

### B2 — Fable local ownership

> Fable 5-level practical agency, multimodal open weights, 1M usable context, and stable interactive execution on one RTX 4090 24GB.

- **Status:** **Open.**

---

## 16. Continuation prompt

> Continue from this specification using exact model identities and current benchmark versions. Update Milestones A1, A2, B1, and B2 separately. Always report output speed, first-answer latency, context, modalities, list pricing, output tokens per task, total agent tokens per task where available, cost per task, and direct workflow evidence. Treat Qwen3.8-27B—not Qwen3.8 Max—as the current A2 model. Do not invent C4O task-economics values where no comparable measurement exists. Preserve A1 as achieved, A2 as capability-crossed but context-incomplete, and B1/B2 as open unless new evidence materially changes those conclusions.