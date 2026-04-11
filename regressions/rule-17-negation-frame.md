# Regression: "reject-then-correct" negation frame

**Rule:** Do not open a positive claim by first negating an alternative. Covers `"不是X，而是Y"` / `"It's not X, it's Y"` and all variants.

**Source model:** GPT-5.4

**Test input:** a commentary on Marc Andreessen's "five traits of innovators" framework (open ended, ~300 words of context), asking the model to summarize + give its take. This prompt reliably exercises the pattern because the natural rhetorical move is to reject the reader's assumed answer before stating the real one.

## Leak count over time

| Version | Rule state | Leak count | Notes |
|---|---|---|---|
| v0.2.x (no rule) | not present | many | "不是X而是Y" showed up in almost every contrastive sentence |
| v0.3.0 (initial rule) | single-line rule banning the phrase as "a rhetorical device" | **6** | Rule read but model kept interpreting its own usage as non-rhetorical technical distinction |
| v0.3.1 (tightened) | expanded to cover variants, removed the "rhetorical device" escape hatch, kept at position 14 (last) | **4** | All four leaks were classic form in the first 3 paragraphs |
| v0.4.0 (reordered + meta rule) | rule promoted to position 2, added a top-of-prompt meta constraint naming it as "your single hardest constraint", added "chained negations" variant | **3 + 1 new variant** | Structural improvement helped but model still leaked 3 times classic form. Plus one never-before-seen variant: "correct then reject" (positive claim followed by `而不是Y`), which the v0.4.0 rule text did not cover. The `"一句话总结"` closing stamp also leaked despite being explicitly banned in v0.4.0 rule 13 — closing rule was still at position 13 of 14, too low for attention weight. |
| v0.5.0 (few-shot + broadened scope + closing rule promoted) | Added BAD/GOOD example pairs below the meta constraint. Broadened rule 2 to cover "any order" of negation (not just "reject then correct"). Removed the concrete `"不是交易信号"` example from rule body because v0.4.0 showed the model copied it verbatim into a response instead of avoiding it. Promoted the closing-pattern rule from position 13 to position 3 so Chinese summary stamps get comparable attention to opening-clause rules. | *target: 0-1* | pending verification |

## v0.3.1 leak excerpts

From a real GPT-5.4 response to the Andreessen prompt after installing `v0.3.1`:

1. Opening sentence: `"真正的创新者不是'有创意的人'，而是五种特质同时拉满的稀有人"`
2. Mid-paragraph: `"创新的瓶颈常常不是钱，不是想法，而是'能把想法熬成现实的那种人'太少"` (chained negation form)
3. Mid-paragraph: `"最关键的其实不是'五项清单'本身，而是中间那个张力"`
4. Closing: `"这条讲的不是'天才灵感'，讲的是'极少数人怎么把反常识想法扛过漫长现实'"`

## v0.4.0 leak excerpts

From a real GPT-5.4 response to the Andreessen prompt after installing `v0.4.0`:

1. **New variant (reverse order):** `"真正的创新者=五种特质同时拉满的人，而不是单纯'聪明'或'有创意'的人"` — this is "correct then reject" order. The v0.4.0 rule only banned "open by negating," which assumes negation-first order. This form appends a negation after a positive claim and slipped through.
2. Classic form: `"最稀缺的不是高智商，是'开放性+尽责性'同时很高"` — standard, with the `而` elided but the structure intact.
3. Self-quoting leak: `"这更像一个'创始人筛选框架'，不是交易信号"` — the rule text in v0.4.0 literally contained the phrase `"不是交易信号"` as a negative example. The model copied it into its own response. Putting specific negative examples in rule text backfires because models use them as templates, not anti-patterns.
4. Classic form: `"很多人不是想不出新点子，而是扛不住周围人的否定"`
5. Closing-rule bypass: the final section of the response was headed `"一句话总结："` even though v0.4.0 rule 13 explicitly banned `"一句话总结"` in its closing-pattern list. Rule 13 was still at position 13 of 14.

## Why v0.3.1 and v0.4.0 still leaked

1. **Attention decay by rule position.** v0.3.1 had the rule at position 14 (last). v0.4.0 moved the negation rule to position 2 and saw meaningful drop (4 → 3 on the classic form), but left the closing-pattern rule at position 13, which then leaked the exact phrase the rule named.
2. **Negative examples in rule text become templates.** The specific `"不是交易信号"` phrase in v0.4.0 rule 2 was intended as an illustration of what not to write. The model then wrote it verbatim. Models can confuse "here's an example of the forbidden shape" with "here's an approved phrase to use."
3. **Rule text covered only one order.** v0.4.0 rule 2 said "open a positive claim by first negating." That banned the common form but not the reverse form (append `而不是Y` to a positive claim). GPT-5.4 switched to the uncovered variant and produced a clean "correct then reject" sentence that technically did not match the rule description.
4. **No positive demonstration.** All v0.3.x and v0.4.0 iterations relied on prohibition text alone ("do not do X"). Models with strong priors for X respond better to showing both sides of a transformation (BAD → GOOD) than to prohibitions, because the transformation gives them a concrete alternative direction.

## v0.4.0 fix (partial)

Three changes in `prompt.md` for v0.4.0:

1. Promoted the rule to position 2, right after "Lead with the answer".
2. Added a top-level meta constraint marking it as "your single hardest constraint".
3. Added the "chained negations" variant (`"不是A，不是B，而是C"`).

Outcome: 4 → 3 on the classic form, but the test also surfaced a new variant (reverse order) and a closing-rule bypass. Motivated v0.5.0.

## v0.5.0 fix

Four changes in `prompt.md` for v0.5.0, in response to observed v0.4.0 leaks:

1. **Broadened rule 2 scope from "open by negating" to "any position."** The rule text now covers both "reject then correct" and "correct then reject" orders, plus chained, symmetric, and no-conjunction variants.
2. **Removed the specific `"不是交易信号"` example from the rule body.** v0.4.0 showed the model copied it verbatim. New rule text is structural only — no concrete phrases the model can reuse as templates.
3. **Added BAD / GOOD example pairs below the meta constraint.** Four pairs covering standard form, reverse form, single-sided form, and English form. Positive demonstrations give the model a transformation direction instead of just a prohibition.
4. **Promoted the closing-pattern rule from position 13 to position 3** so Chinese summary-stamp closers ("一句话总结" and friends) get attention weight comparable to rule 2.

## How to re-run this test

1. Install the latest `prompt.md` via any of the supported paths (`clawhub install talk-normal && bash skills/talk-normal/install.sh`, paste GitHub link into OpenClaw, or manual `git clone`).
2. Start a fresh GPT-5.4 conversation in OpenClaw or ChatGPT custom instructions.
3. Paste the Andreessen "five traits of innovators" context (or any open-ended commentary prompt that asks for a summary + take).
4. Count occurrences of the pattern in the response. Target is 0 to 1. Anything above 2 means the rule is still not holding and needs further iteration.

## Related observations from the same test

- `"一句话总结"` as a closing header was not caught by v0.3.1 rule 15 because the rule only listed English variants ("In conclusion", "In summary", "Hope this helps", "Feel free to ask"). Fixed in v0.4.0 by adding Chinese summary-stamp closers (`一句话总结`, `总结一下`, `简而言之`, `概括来说`, `总而言之`) to the same rule.
- No violations of the "hypothetical follow-up offer" rule (no `"如果你愿意，我可以..."` at the end of the response). This rule is holding in both v0.3.1 and expected to hold in v0.4.0.
