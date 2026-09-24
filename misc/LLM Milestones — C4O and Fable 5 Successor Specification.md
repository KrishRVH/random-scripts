# AI Engineering Milestones — Opus 4.6 and Fable 5 Successor Specification

_Cloud evidence checked: **September 24, 2026**, America/Chicago (Fable 5 rows: September 22, 2026). Local owner observations were last recorded August 17, 2026._

## 1. Purpose

The original **Claude 4 Opus**—abbreviated **C4O**—was the reference moment when agent-driven software engineering began to feel like an irreversible change to the field. That bar has now been crossed in the cloud and, in capability, locally. It is retired to a historical record (§8).

The new first-generation bar is **Claude Opus 4.6**: the model at which agentic software engineering became reliable enough to hand over substantial, multi-hour work.

This specification tracks two forms of capability abundance:

1. **Cloud abundance:** frontier-level intelligence becomes extremely fast and extremely inexpensive.
2. **Local ownership:** the same class of intelligence becomes practical on one consumer RTX 4090 24GB.

It defines two generations of milestones:

- **Milestone A:** successors to Claude Opus 4.6. _(Upgraded from original C4O on September 24, 2026.)_
- **Milestone B:** successors to Claude Fable 5.

This document supersedes the original strict handoff. The previous requirement—prove superiority on every accepted benchmark row with no missing evidence—was useful for avoiding hype, but too restrictive for identifying when the practical technological event had occurred.

The governing question is now:

> Has this model crossed the reference point strongly enough that, for real agentic software-engineering work, the old model is no longer the meaningful choice?

Benchmarks remain important, but they are evidence rather than the definition of the milestone.

---

## 2. Current status

| Milestone                                     | Status   | Current crossing                                                                                                                                               |
| --------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A1 — Fast, cheap cloud Opus 4.6 successor** | **Open** | GPT-6 Luna and DeepSeek V4.1 Flash meet the speed, price, context, and vision envelope but are not accepted as Opus 4.6-level agentic engineers.               |
| **A2 — Local Opus 4.6 successor on RTX 4090** | **Open** | Qwen3.8-27B is the best local model and a C4O successor, but not Opus 4.6-level, and its usable local context is ≈96K.                                         |
| **B1 — Fast, cheap cloud Fable 5 successor**  | **Open** | No current model combines Fable-level capability, at least 100 output tokens/second, GPT-6 Luna-class economics, vision, and the complete 1M-context envelope. |
| **B2 — Local Fable 5 successor on RTX 4090**  | **Open** | No current model provides Fable-level agency, multimodality, and 1M usable context on one 24GB RTX 4090.                                                       |

Retired C4O record (§8): cloud C4O successor **achieved** by GPT-6 Luna and DeepSeek V4.1 Flash; local C4O successor **core crossing achieved** by Qwen3.8-27B, context-incomplete.

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

In the retired C4O record, Qwen3.8-27B reached the required local capability class while the full context target remained open.

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

# Milestone A — Claude Opus 4.6 Successors

## 5. Frozen Opus 4.6 baseline

**Opus 4.6** always means the February 5, 2026 release:

| Attribute             | Opus 4.6 baseline                                                |
| --------------------- | ---------------------------------------------------------------- |
| Exact API model       | `claude-opus-4-6`                                                |
| Reasoning mode        | Adaptive thinking; effort `low`/`medium`/`high`/`max`            |
| Reference setting     | Adaptive reasoning, `max` effort                                 |
| Context               | 1M tokens (API; launched as beta); 200K at standard pricing      |
| Maximum output        | 128K tokens                                                      |
| Modalities            | Text and image input; text output                                |
| Price                 | **$5/M input; $25/M output**; $10/$37.50 above 200K input tokens |
| Prompt-cache discount | 90% on cached input                                              |
| Weights               | Closed                                                           |

### Artificial Analysis profile

| Metric                                                     | Opus 4.6 adaptive `max` |
| ---------------------------------------------------------- | ----------------------: |
| Intelligence Index v4.3.2                                  |       **32**, estimated |
| Output speed                                               |               ≈40 tok/s |
| Time to first answer token                                 |             ≈21 seconds |
| Humanity's Last Exam                                       |                     40% |
| CritPt                                                     |                     13% |
| AA-LCR v1.1                                                |                     78% |
| AA-Omniscience                                             |                      14 |
| Terminal-Bench 4.0, SciCode, GDPval-AA, AutomationBench-AA |       Not run on v4.3.2 |
| Weighted output tokens / cost per AA task                  |             Unavailable |

The [Artificial Analysis row](https://artificialanalysis.ai/models/claude-opus-4-6-adaptive) is marked deprecated, and its v4.3.2 score is an **estimate**: the agentic and coding components of the current suite, including Terminal-Bench 4.0, were never run on it. Like the C4O asterisk, it is a directional marker, not a fresh same-suite result. It must not be used alone to rank a candidate above or below Opus 4.6.

### Vendor-reported coding evidence

Anthropic's [release announcement](https://www.anthropic.com/news/claude-opus-4-6) reports **81.42% on SWE-bench Verified** (with a prompt modification) and top results at launch on Terminal-Bench 2.0, SWE-bench Pro, and OSWorld. These are vendor results on older benchmark versions, not shared-harness rows.

No accepted DeepSWE v1.1 row exists for Opus 4.6; the [shared leaderboard](https://deepswe.datacurve.ai/) lists later Claude models only.

### What the Opus 4.6 bar represents

Opus 4.6 is the **practical agentic-engineering target** for Milestone A:

- Reliable multi-hour autonomous coding with limited supervision.
- Strong repository-scale understanding and multi-file changes.
- Mature tool use, including terminal and computer use.
- Self-testing and error recovery.
- Vision for design and UI validation.
- Large working context.

Because the AA estimate is weak evidence, the milestone rests primarily on independent coding-agent results and owner-observed workflow comparison.

---

## 6. Milestone A1 — Fast, cheap cloud Opus 4.6 successor

### Target experience

A full A1 crossing should provide:

| Dimension      | Target                                                                      |
| -------------- | --------------------------------------------------------------------------- |
| Capability     | Broadly Opus 4.6-level or better for agentic software engineering           |
| Output speed   | **At least 100 tokens/second**                                              |
| Economics      | GPT-6 Luna-class comfortable pricing and negligible practical task cost     |
| Token behavior | Reasonable enough that verbosity does not erase the speed or cost advantage |
| Context        | At least 200K; 1M preferred, matching Opus 4.6's API envelope               |
| Modalities     | Text and image input for a full crossing                                    |
| Tool use       | Opus 4.6-class coding, terminal, file, and structured tool reliability      |

**GPT-6 Luna-class pricing** is the preferred reference, not an inflexible ceiling:

- Approximately **$0.10/M input**
- Approximately **$0.50/M output**
- Roughly the same near-negligible cost class after actual task token consumption

A model may be somewhat more expensive per token and still qualify when cost per successful task remains comparably low.

### Current candidates

| Candidate                     | AA Index v4.3.2 |   Output speed | First answer | Context | Vision | List price per M input/output | AA output tokens/task | AA cost/task | Status           |
| ----------------------------- | --------------: | -------------: | -----------: | ------: | ------ | ----------------------------: | --------------------: | -----------: | ---------------- |
| **GPT-6 Luna `max`**          |              37 | **≈141 tok/s** |       ≈107 s |   1.05M | Yes    |             **$0.10 / $0.50** |                  ≈51K |    **$0.07** | **Not accepted** |
| **DeepSeek V4.1 Flash `max`** |              39 | **≈232 tok/s** |        ≈10 s |      1M | Yes    |            $0.30 / $1.20 peak |                  ≈89K |    **$0.27** | **Not accepted** |

Both candidates pass the speed, economics, context, and vision envelope. The open question is capability alone.

[Official OpenAI documentation](https://developers.openai.com/api/docs/models/gpt-6-luna) specifies `gpt-6-luna`, 1.05M context, 128K maximum output, image input, tools, and $0.10/$0.50 pricing. The [Luna–Opus 4.6 comparison](https://artificialanalysis.ai/models/comparisons/claude-opus-4-6-adaptive-vs-gpt-6-luna) reports 37 intelligence, about 141 output tokens/second, about 107 seconds to first answer token, about 51K output tokens, and $0.07 per Intelligence Index task. Earlier checks measured 157.2 tok/s and 153 seconds; these live figures shift with serving conditions.

[DeepSeek's API documentation](https://api-docs.deepseek.com/quick_start/pricing/) identifies `deepseek-flash` as V4.1 Flash, with 1M context, up to 384K output, image input, tool calls, and $0.30/$1.20 peak pricing. Off-peak prices are $0.15/$0.60. The [DeepSeek–Opus 4.6 comparison](https://artificialanalysis.ai/models/comparisons/claude-opus-4-6-adaptive-vs-deepseek-v4-1-flash) reports 39 intelligence, about 232 output tokens/second, about 9.5 seconds to first answer token, about 89K output tokens, and $0.27 per task. The model has downloadable MIT-licensed weights, though its 552B total parameters do not make it a plausible single-4090 candidate.

### Interpretation

The headline AA index favors both challengers: 37 and 39 against Opus 4.6's estimated 32. That is **not** accepted as a crossing:

- Opus 4.6's 32 is an estimate missing every agentic and coding component of v4.3.2, so the gap is not a like-for-like comparison.
- On the components both sides actually ran, the picture is mixed rather than a clear lead. Luna and DeepSeek are ahead on CritPt (19% and 14% versus 13%) and AA-LCR (83% and 84% versus 78%). They trail on Humanity's Last Exam (39% each versus 40%) and on AA-Omniscience, where DeepSeek scores −5 against Opus 4.6's 14.
- Neither challenger has an independent coding-agent row. OpenAI reports **66.6%** and DeepSeek **74.2%** on DeepSWE v1.1; both are vendor results, and neither appears on the [shared leaderboard](https://deepswe.datacurve.ai/).
- Luna scores **13%** and DeepSeek **27%** on AA's Terminal-Bench 4.0, well short of Fable's 42%. No Opus 4.6 score exists for direct comparison, but these are weak results for a reference defined by terminal-heavy agent work.
- Owner-observed use does not place either model at Opus 4.6's level for real agentic engineering.

#### GPT-6 Luna

Luna remains the A1 economic reference. Its roughly 107-second first-answer delay at `max` also limits how fast it feels in practice, despite its decode speed.

#### DeepSeek V4.1 Flash

DeepSeek is the faster and stronger-scoring of the two, with short first-answer latency. It is more verbose (≈89K versus Luna's ≈51K output tokens per AA task), though its $0.27 task cost shows verbosity has not erased its economics. Independent same-harness confirmation of its vendor DeepSWE result is the evidence most likely to move it toward acceptance.

### A1 verdict

> **Milestone A1 is open.**

The envelope is already available; the missing piece is independently confirmed Opus 4.6-level agentic coding at GPT-6 Luna-class speed and cost.

---

## 7. Milestone A2 — Local Opus 4.6 successor on one RTX 4090

### Target experience

A complete A2 crossing requires:

| Dimension   | Target                                                                       |
| ----------- | ---------------------------------------------------------------------------- |
| Hardware    | One RTX 4090 with 24GB VRAM                                                  |
| Execution   | Fully local; no cloud or second GPU                                          |
| Weights     | Downloadable and locally usable                                              |
| Capability  | Broadly Opus 4.6-level or better in the actual software-engineering workflow |
| Modalities  | Text and image input                                                         |
| Context     | **More than 200K usable local context**                                      |
| Speed       | Interactive enough for sustained agent use                                   |
| Reliability | Stable multi-turn coding and tool workflows                                  |

Local speed is intentionally practical rather than ceremonial:

- Approximately 15 generated tokens/second is acceptable.
- Approximately 30 or more is preferred.
- Stable agent execution matters more than a synthetic peak.

### Current best local model: Qwen3.8-27B

Qwen3.8-27B is a dense 27B vision-language model with Apache-2.0 weights, image and video understanding, configurable reasoning, 262,144 native context, and extension support up to 1M.

Artificial Analysis currently reports:

- Intelligence Index: **52** on the earlier AA index version; not comparable with current v4.3.2 scores.
- Total output generated during the Intelligence Index: **160M tokens**
- Hosted speed and task cost: not yet available on the exact AA model row

On the intended RTX 4090 24GB system (owner-observed):

- Qwen3.8-27B feels better than original C4O for the practical software-engineering workflow (August 17, 2026).
- It does **not** reach Opus 4.6's level of agentic engineering (September 24, 2026).
- It fits and runs locally at useful speed.
- The current usable context is approximately **96K** (August 17, 2026).

It therefore misses A2 on both capability and context.

### Future measurements

Record for every local candidate:

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

“Native 262K context” does not satisfy the context requirement by itself. The exact local artifact must actually load and operate beyond 200K.

### A2 verdict

> **Milestone A2 is open.**

The next local event is an open-weight model that matches Opus 4.6 in the owner's real workflow and holds more than 200K usable context on one RTX 4090 24GB.

---

## 8. Retired C4O milestone — historical record

The first Milestone A generation used original Claude 4 Opus as its reference. It is closed and kept for history; do not revise it.

### C4O baseline

| Attribute                              | C4O baseline                      |
| -------------------------------------- | --------------------------------- |
| Exact API model                        | `claude-opus-4-20250514`          |
| Reasoning mode                         | Extended thinking                 |
| Context                                | 200K tokens                       |
| Modalities                             | Text and image input; text output |
| Launch price                           | $15/M input; $75/M output         |
| Weights                                | Closed                            |
| Artificial Analysis Intelligence Index | 32*, estimated historical result  |
| Current paired AA task economics       | Unavailable                       |
| Current DeepSWE result                 | Unavailable                       |

The best retained token-use proxy is Kagi's private benchmark row: **74.3%** accuracy, **17,058** reported tokens per task, **13.3 seconds** mean time per task. It is not interchangeable with Artificial Analysis or DeepSWE. No defensible current value exists for C4O's AA or DeepSWE task economics, and none should be reconstructed from unrelated benchmarks.

### C4O outcomes

| Milestone                          | Outcome                                        | Crossing                                                                                         |
| ---------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Cloud C4O successor**            | **Achieved**                                   | GPT-6 Luna and DeepSeek V4.1 Flash: full multimodal crossings.                                   |
| **Local C4O successor (RTX 4090)** | **Core crossing achieved; context-incomplete** | Qwen3.8-27B feels better than C4O in the owner's workflow; usable local context ≈96K, not >200K. |

---

# Milestone B — Claude Fable 5 Successors

## 9. Frozen Fable 5 baseline

Milestone B uses the deployed Claude Fable 5 experience as the new reference point.

| Attribute              | Fable 5 baseline                                              |
| ---------------------- | ------------------------------------------------------------- |
| API model              | `claude-fable-5`                                              |
| Positioning at release | Anthropic’s most capable widely released model                |
| Intended workload      | Long-running agents, difficult coding, complex knowledge work |
| Reasoning              | Adaptive reasoning, always on                                 |
| Context                | **1M tokens**                                                 |
| Maximum output         | **128K tokens**                                               |
| Modalities             | Text and image input; text output                             |
| Price                  | **$10/M input; $50/M output**                                 |
| Prompt-cache discount  | 90% on cached input                                           |
| Weights                | Closed                                                        |

Anthropic describes Fable 5 as a model for long-running agents that can plan across stages, delegate to sub-agents, check its own work, perform complex migrations, write tests, and use vision to validate implementation against intended designs.

### Deployed-product caveat

Fable 5 includes safety routing for some cybersecurity and biology requests. Artificial Analysis therefore labels its evaluated row:

> Claude Fable 5 — Adaptive Reasoning, Max Effort, Opus 4.8 Fallback

Milestone B uses this actual deployed experience rather than pretending that an unrestricted underlying model is separately available.

---

## 10. Fable 5 capability and economics profile

### Model-level Artificial Analysis profile

| Metric                             |          Fable 5 |
| ---------------------------------- | ---------------: |
| Intelligence Index v4.3.2          |           **50** |
| Output speed                       |    **≈61 tok/s** |
| Time to first answer token         | **≈113 seconds** |
| Weighted output tokens per AA task |             ≈67K |
| Cost per AA task                   |        **$8.75** |
| Total AA output tokens             |        **≈126M** |
| Total AA evaluation cost           |     **≈$11,161** |
| Context                            |               1M |
| Vision                             |              Yes |

The [current Artificial Analysis row](https://artificialanalysis.ai/models/claude-fable-5) measures Fable on Index v4.3.2. The earlier 62-point v4.1.1 result is not numerically comparable with the current 50-point score; the benchmark changed. Approximate per-task token use and first-answer latency come from [same-version model comparisons](https://artificialanalysis.ai/models/comparisons/deepseek-v4-1-flash-vs-claude-fable-5). The model row has since been marked deprecated, but Fable 5 remains this milestone's frozen reference.

### Independent DeepSWE v1.1 profile

| Metric                     | Fable 5 `xhigh` |
| -------------------------- | --------------: |
| Pass rate                  |    **70% ± 3%** |
| Average output tokens/task |         **80K** |
| Average cost/task          |      **$13.41** |
| Agent steps/task           |          **68** |

The [current DeepSWE v1.1 leaderboard](https://deepswe.datacurve.ai/) contains 113 original long-horizon engineering tasks and runs listed models through mini-swe-agent for consistency. The `xhigh` row is the current accepted result for Fable 5.

### Artificial Analysis Coding Agent Index profile

The earlier Fable 5 `max` with fallback run in Claude Code recorded the following on Coding Agent Index v1.3. This dated row is retained as context, not compared numerically with newer index or harness versions:

| Metric                    |           Result |
| ------------------------- | ---------------: |
| Coding Agent Index v1.3   |           **66** |
| DeepSWE                   |              66% |
| Terminal-Bench v2         |              83% |
| SWE-Atlas-QnA             |              49% |
| Average total tokens/task |          **14M** |
| Average API cost/task     |       **$11.70** |
| Average wall time/task    | **23.4 minutes** |

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

## 11. Milestone B1 — Fast, cheap cloud Fable 5 successor

### Target experience

A full B1 crossing requires:

| Dimension       | Target                                                                            |
| --------------- | --------------------------------------------------------------------------------- |
| Capability      | Fable 5-level or better for long-horizon agentic software engineering             |
| Output speed    | **At least 100 tokens/second**                                                    |
| Economics       | Approximately GPT-6 Luna-class pricing and similarly low cost per successful task |
| Context         | **At least 1M usable context**                                                    |
| Output envelope | Sufficient for long autonomous runs; ideally near Fable’s 128K maximum            |
| Modalities      | Text and image input                                                              |
| Tool use        | Mature coding, terminal, file, and structured tool behavior                       |
| Token behavior  | No verbosity severe enough to erase the speed or cost advantage                   |

A text-only model may receive a **B1 text-only crossing**, but cannot be considered the complete successor.

### Practical capability threshold

No single benchmark defines Fable equivalence. A plausible candidate should show:

- Roughly Fable-class independent aggregate intelligence.
- Competitive coding-agent performance.
- No severe regression in long-horizon repository work.
- Strong instruction following and tool reliability.
- Comparable ability to maintain plans and recover from errors.
- Direct evidence from ambitious real-world projects.

Fable's current AA Index v4.3.2 score of 50 is a useful same-version marker, not a permanent mathematical cutoff. The older v4.1.1 score of 62 must not be compared directly with current candidates.

A B1 crossing implies an A1 crossing; no candidate should be considered for B1 before it clears the Opus 4.6 bar.

### Current candidates

#### GPT-6 Luna

Already satisfies:

- More than 100 output tokens/second.
- GPT-6 Luna-class pricing by definition.
- 1M-class context.
- Vision and tools.
- Very low list prices and a measured $0.07 AA task cost.

Still missing:

- Fable-level capability.
- Fable-level long-horizon coding-agent performance.
- Faster first-answer latency at maximum reasoning.

Its AA Index v4.3.2 score of **37** is materially below Fable's **50** in the same version. OpenAI reports **66.6%** on DeepSWE v1.1 at `max`, near Fable's current independent **70% ± 3%** result, but that Luna result has not yet appeared on the independent shared leaderboard with task cost and token use. A same-harness coding-agent result and direct evidence on ambitious real projects are still needed. Its approximately 107-second first-token delay also limits the practical meaning of its high decode speed.

#### DeepSeek V4.1 Flash

Already satisfies:

- More than 100 output tokens/second.
- Low measured cost per model-evaluation task.
- 1M context.
- Image input and mature tool support.
- A vendor-reported 74.2% on DeepSWE v1.1.

Still missing:

- Fable-level broad intelligence: its same-version AA score is **39**, versus **50** for Fable.
- Independent same-harness confirmation of Fable-level long-horizon coding performance.
- Better token efficiency and direct evidence from ambitious real-world projects.

The vendor DeepSWE score is promising but is not an independent shared-leaderboard row. The independent AA comparison also shows a notable Terminal-Bench 4.0 gap, **27% versus Fable's 42%**, despite DeepSeek's strength on other tasks.

#### Qwen3.8-27B

Already provides:

- Open weights.
- Vision.
- 262K native context with extension support.
- A strong historical 52 AA result at only 27B parameters (earlier index version).

It does not currently have the accepted hosted speed, production economics, 1M default serving envelope, or Fable-level capability evidence required for B1.

### B1 verdict

> **Milestone B1 remains open.**

The likely future crossing is a model with approximately Fable-level agency, GPT-6 Luna-like task economics, at least 100 output tokens/second, vision, and 1M context. DeepSeek now satisfies the speed, vision, and context envelope; it has not yet cleared even the Opus 4.6 capability bar.

---

## 12. Milestone B2 — Local Fable 5 successor on one RTX 4090

### Target experience

A complete B2 crossing requires:

| Dimension   | Target                                                  |
| ----------- | ------------------------------------------------------- |
| Hardware    | One RTX 4090 24GB                                       |
| Execution   | Local only; no cloud or second GPU                      |
| Weights     | Downloadable and locally usable                         |
| Capability  | Fable 5-level practical agentic software engineering    |
| Modalities  | Text and image input                                    |
| Context     | **1M stable, usable local context**                     |
| Speed       | Interactive enough for extended autonomous work         |
| Reliability | Stable long-running tool and coding loops               |
| Ownership   | No dependency on a hosted proprietary inference service |

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

Qwen3.8-27B establishes that C4O-class local agency is now practical. Opus 4.6-class local agency (A2) is the next event; Fable-class agency plus multimodality and a full 1M working context on the same 24GB GPU comes after it.

---

## 13. Consolidated task-economics ledger

### Artificial Analysis model-level economics

| Model                                  | AA Index (version) |   Output speed | First-answer latency | Weighted output tokens/task | Cost/task | Total AA output |
| -------------------------------------- | -----------------: | -------------: | -------------------: | --------------------------: | --------: | --------------: |
| **Original C4O** _(retired)_           |   32* (historical) |              — |                    — |                           — |         — |               — |
| **Claude Opus 4.6 adaptive `max`**     | 32* (v4.3.2, est.) |      ≈40 tok/s |                ≈21 s |                           — |         — |               — |
| **GPT-6 Luna `max`**                   |        37 (v4.3.2) | **≈141 tok/s** |               ≈107 s |                        ≈51K | **$0.07** |           ≈150M |
| **DeepSeek V4.1 Flash `max`**          |        39 (v4.3.2) | **≈232 tok/s** |                ≈10 s |                        ≈89K | **$0.27** |           ≈250M |
| **Qwen3.8-27B**                        | 52 (earlier index) |              — |                    — |  Not yet extracted reliably |         — |            160M |
| **Claude Fable 5 `max` with fallback** |    **50 (v4.3.2)** |      ≈61 tok/s |               ≈113 s |                        ≈67K | **$8.75** |           ≈130M |

The Luna, DeepSeek, and Fable v4.3.2 rows can be compared directly on the current Artificial Analysis suite. The [Luna](https://artificialanalysis.ai/models/gpt-6-luna), [DeepSeek](https://artificialanalysis.ai/models/deepseek-v4-1-flash), [Opus 4.6](https://artificialanalysis.ai/models/claude-opus-4-6-adaptive), and [Fable](https://artificialanalysis.ai/models/claude-fable-5) model pages provide speed, index, pricing, and total-token values. The [Luna–Fable](https://artificialanalysis.ai/models/comparisons/gpt-6-luna-vs-claude-fable-5), [DeepSeek–Fable](https://artificialanalysis.ai/models/comparisons/deepseek-v4-1-flash-vs-claude-fable-5), [Luna–Opus 4.6](https://artificialanalysis.ai/models/comparisons/claude-opus-4-6-adaptive-vs-gpt-6-luna), and [DeepSeek–Opus 4.6](https://artificialanalysis.ai/models/comparisons/claude-opus-4-6-adaptive-vs-deepseek-v4-1-flash) comparisons provide weighted output-token, cost, and first-answer figures. These live measurements may shift as evaluations and serving conditions change. Neither estimated score (C4O, Opus 4.6) nor Qwen's earlier-version score belongs in a numerical ranking against fully run v4.3.2 rows.

### Long-horizon software-engineering economics

| Model                      | DeepSWE v1.1 pass rate | Evidence                       | Output tokens/task |  Cost/task | Steps/task |     Coding Agent Index |
| -------------------------- | ---------------------: | ------------------------------ | -----------------: | ---------: | ---------: | ---------------------: |
| **Original C4O**           |                      — | —                              |                  — |          — |          — |                      — |
| **Claude Opus 4.6**        |                      — | No shared v1.1 row             |                  — |          — |          — |                      — |
| **GPT-6 Luna `max`**       |                  66.6% | OpenAI release                 |                  — |          — |          — | Pending comparable row |
| **DeepSeek V4.1 Flash**    |                  74.2% | DeepSeek release               |                  — |          — |          — | Pending comparable row |
| **Qwen3.8-27B**            |                      — | No accepted exact-model row    |                  — |          — |          — |       No exact 27B row |
| **Claude Fable 5 `xhigh`** |           **70% ± 3%** | Independent shared leaderboard |            **80K** | **$13.41** |     **68** |    Historical v1.3: 66 |

The [shared DeepSWE v1.1 leaderboard](https://deepswe.datacurve.ai/) does not yet list the two new candidates or Opus 4.6. The candidates' reported rates come from the [OpenAI](https://openai.com/index/introducing-gpt-6-sol-and-luna/) and [DeepSeek](https://api-docs.deepseek.com/updates/) releases, respectively. Neither release supplies the same-harness output-token, step, or cost measurements needed for the blank cells. Fable's Coding Agent Index 66 is from an earlier v1.3 run in Claude Code and is not a current cross-model comparison.

### Economic conclusions

1. **GPT-6 Luna is the least expensive candidate.** It provides vision and 1.05M context at $0.10/$0.50 per million input/output tokens and $0.07 per AA task. Low AA task cost still does not establish cost per successful coding task.

2. **DeepSeek V4.1 Flash is faster to start and decode, but more verbose.** It uses approximately 89K AA output tokens per task versus Luna's 51K. Its measured AA task cost is $0.27 at peak pricing. Its DeepSWE cost and step count are not yet independently available.

3. **The economics of A1 are already solved; the capability is not.** Both candidates deliver Opus 4.6-beating speed at a small fraction of its $5/$25 list price. A1 now waits on capability evidence, not price or speed.

4. **Fable remains far more expensive per measured AA task.** Its $8.75 cost reflects both its $10/$50 list pricing and the current v4.3.2 task mix. Do not infer a model's efficiency from total evaluation tokens alone.

5. **Agent-harness token totals are a separate measurement.** A 14M-token coding-agent task can include repeatedly cached repository context and tool transcripts. It must not be compared directly with a 67K model-evaluation output count.

6. **No objective C4O or Opus 4.6 corollary exists for the modern task-economics columns.** The Kagi 17,058-token C4O result is retained as a historical proxy, not inserted into incompatible AA or DeepSWE tables.

---

## 14. Evidence hierarchy

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

## 15. Future update protocol

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
- Do not treat Opus 4.6's estimated v4.3.2 score as a fresh full-suite result.
- Preserve exact benchmark and harness versions.
- Keep Milestone A and Milestone B baselines historically fixed; keep the retired C4O record unchanged.

---

## 16. Final milestone definitions

### A1 — Opus 4.6 cloud abundance

> Broadly Opus 4.6-level or better for agentic software engineering, at least 100 output tokens/second, GPT-6 Luna-class inexpensive, reasonably token-efficient, and at least 200K context.

- **Full crossing:** includes vision.
- **Text-only crossing:** lacks vision.
- **Status:** **Open.**

### A2 — Opus 4.6 local ownership

> Broadly Opus 4.6-level or better for real agentic software work, multimodal, open-weight, practical on one RTX 4090 24GB, and capable of more than 200K usable local context.

- **Status:** **Open.**

### B1 — Fable cloud abundance

> Fable 5-level long-horizon agency, at least 100 output tokens/second, approximately GPT-6 Luna-class economics, vision, mature tools, and at least 1M usable context.

- **Status:** **Open.**

### B2 — Fable local ownership

> Fable 5-level practical agency, multimodal open weights, 1M usable context, and stable interactive execution on one RTX 4090 24GB.

- **Status:** **Open.**

### Retired — C4O

- **Cloud:** **Achieved** by GPT-6 Luna and DeepSeek V4.1 Flash.
- **Local:** **Core crossing achieved** by Qwen3.8-27B; context-incomplete at ≈96K.

---

## 17. Continuation prompt

> Continue from this specification using exact model identities and current benchmark versions. Milestone A's reference is Claude Opus 4.6 (`claude-opus-4-6`, adaptive `max`); original C4O is a retired historical record and must not be revised. Update Milestones A1, A2, B1, and B2 separately. Always report output speed, first-answer latency, context, modalities, list pricing, output tokens per task, total agent tokens per task where available, cost per task, and direct workflow evidence. Use GPT-6 Luna (`gpt-6-luna`) and DeepSeek V4.1 Flash (`deepseek-flash`) for the current cloud comparison. Treat Qwen3.8-27B—not Qwen3.8 Max—as the current local model. Do not rank candidates against Opus 4.6's estimated AA score alone; require independent coding-agent evidence or owner-observed workflow evidence. Do not invent C4O or Opus 4.6 task-economics values where no comparable measurement exists. Preserve A1, A2, B1, and B2 as open unless new evidence materially changes those conclusions.
