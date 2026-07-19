# Design: Recipe Import & Autosort Engine

- **Status**: Accepted
- **Related**: [Intent 0001](../intent/0001-recipe-planner-phase1.md), [ADR-0003](../adr/0003-first-class-ingredient-groups.md), [ADR-0004](../adr/0004-suggest-and-correct-autosort-ux.md), [ADR-0005](../adr/0005-jsonld-first-recipe-import.md)

## Problem

Tandoor's "auto sort" (split instructions into steps, assign each ingredient to the step that uses it) fails in three ways this design exists to fix:

1. **Exact substring matching** — no normalization, so "diced tomatoes" doesn't match "tomatoes, diced" and any non-verbatim phrasing misses.
2. **Duplicate ingredient, different measurements** — when the same ingredient appears twice at different quantities (e.g. "2 tbsp soy sauce" in a marinade, "1 tbsp soy sauce" in a glaze), first-occurrence matching assigns both mentions to whichever row it finds first — a coin flip, often wrong.
3. **Section references** — steps like "mix the marinade ingredients together" reference a *group*, not any single ingredient's name. No amount of per-ingredient string matching fixes this; the app needs to know "Marinade" is a group with members.

(2) and (3) share a root cause: ingredients need to be sectioned (ADR-0003) before matching can disambiguate them.

## Schema

```
recipe_ingredient_groups
  id, recipe_id, name, position

recipe_ingredients (additive)
  recipe_ingredient_group_id  (nullable FK -> recipe_ingredient_groups)
  preparation                 (string, nullable)  -- "minced", "room temperature"
  position

instructions (additive)
  recipe_ingredient_group_id  (nullable FK -> recipe_ingredient_groups)
                              -- set only when source data structurally ties
                              -- a step to a section (schema.org HowToSection)

instruction_ingredients        -- NEW join table; this IS the autosort output
  instruction_id, recipe_ingredient_id
```

`instruction_ingredients` is what the suggest-and-correct UI (ADR-0004) reads and writes. The matching algorithm below just populates it with an initial best guess; nothing about the schema depends on the guess being right.

## Matching algorithm — tiered, cheapest/most-reliable first

Run in order per recipe; each tier only considers ingredients not yet assigned by an earlier tier.

**Tier 0 — Structural alignment (no text analysis).**
If the source itself encodes sections on both sides (`instructions.recipe_ingredient_group_id` is set — see ADR-0005 on `HowToSection`), assign every ingredient in that group to that instruction directly. Highest confidence, zero guessing.

**Tier 1 — Group name mentioned in prose.**
For steps without structural section data, but where ingredients are grouped, scan the step's normalized text for a group name (e.g. "marinade" appearing in "add the marinade ingredients"). On a match, assign the whole group to that step. This is what fixes the collective-reference failure mode — the step is never asked to individually match every ingredient in the group.

**Tier 2 — Individual fuzzy match.**
For remaining ungrouped or unmatched ingredients: normalize both the step text and the ingredient name (lowercase, strip punctuation, singularize/stem, and — critically — strip the `preparation` text so matching is against the clean canonical name, e.g. "garlic" not "garlic, minced"). Match by token overlap, not substring.

*Updated 2026-07-19*: real-world testing (see project memory) found the original all-tokens-required rule left most ingredients unresolved whenever a step abbreviated away a descriptive modifier ("dark soy sauce" → step just says "soy sauce"). The rule is now: the ingredient's **head noun (last normalized token) must always be present** — never optional, since that's what distinguishes it from an unrelated ingredient sharing an earlier word (e.g. "soy sauce" vs. "soy milk") — and **at most one other (modifier) token may be missing**. When two different ingredients both qualify for the same step and share a head noun (e.g. "baking powder" / "cinnamon powder" both ending in "powder"), a complete match always wins outright; among partial matches only, a unique top scorer wins and a tie is left unresolved rather than guessed. See `app/services/recipe_autosorter.rb`'s `match_score`/`candidate_ingredient_ids` for the implementation and reasoning.

When an ingredient has multiple unassigned occurrences (the duplicate-measurement case):
- Prefer whichever occurrence is still unassigned.
- If the step text restates a quantity ("melt 2 tbsp of the butter"), prefer the occurrence whose `quantity`/`unit` matches, as a tiebreaker.
- Otherwise, fall back to list order (first unassigned occurrence) — still an improvement over Tandoor's plain first-occurrence rule, since already-assigned occurrences are excluded from consideration.

**Tier 2.5 — Implied collective group (added in Unit 08).**
For recipes where grouping exists nowhere in the source data at all — not even a `HowToSection` — but a step's prose refers to a section collectively ("the Marinade ingredients"), detect that reference and, *only* when there's exactly one such label and exactly one contiguous run (by list `position`, length ≥ 2) of still-unassigned ingredients, create a real `RecipeIngredientGroup` for it and assign the whole run to whichever step most directly names the section (preferring a leading `"Label:"` prefix over an earlier passing mention). With more than one label or more than one run, there's no reliable signal to pair them, so this tier bails out entirely rather than guess — see Bolt 008's plan for the case this doesn't cover.

**Tier 3 — Unresolved.**
Anything left over is not force-assigned. It surfaces in the UI as unplaced, for manual drag-in (ADR-0004). Silence beats a wrong guess.

## Shared building block: ingredient-line parser

Both the JSON-LD import path and manual paste need to turn a raw string like `"1 1/2 cups all-purpose flour, sifted"` into:

```
quantity: 1.5
unit: "cups"
name: "all-purpose flour"
preparation: "sifted"
```

One parser, used by both paths. Handles numeric and unicode fractions, a known-unit list, and splits the remainder on the first comma into name vs. preparation. This is a regex/heuristic parser, not NLP — it does not need to be perfect, since its output feeds into a name field the user can edit, and matching (Tier 2) already tolerates imperfect normalization.

## Import pipeline (ADR-0005)

1. Fetch URL → look for `<script type="application/ld+json">` with `@type: "Recipe"` (unwrap `@graph` if present).
2. Extract `recipeIngredient` (flat array of strings, run through the ingredient-line parser) and `recipeInstructions` (flat strings, or `HowToStep`/`HowToSection`).
3. If `HowToSection` is present, that becomes Tier 0 data directly — but note ingredient-side grouping is usually *not* present in JSON-LD even then (see limitation below), so Tier 0 may apply to instructions while ingredients still need manual grouping.
4. If no usable JSON-LD is found, fall back to manual paste of raw ingredient/instruction text, split into lines and run through the same parser + autosort tiers.

## Known limitations

- Ingredient-side section headers ("For the marinade:") are rendered in HTML, not JSON-LD, for most sites. JSON-LD import will often produce ungrouped ingredients even for recipes that are visually sectioned. **Partially mitigated by Tier 2.5 (Unit 08)**: when exactly one section is referenced collectively in prose and exactly one contiguous unassigned run of ingredients exists, it's grouped and assigned automatically. Recipes with *multiple* ungrouped sections (e.g. both an ungrouped "Filling" and "Topping") still fall through to fully manual grouping — pairing multiple labels to multiple runs isn't reliably derivable from position alone, so Tier 2.5 deliberately declines to guess there.
- No synonym/alias handling in this design (e.g. "scallion" vs "green onion", "cilantro" vs "coriander"). Tier 2 matching is normalization + stemming only. An ingredient alias table is a plausible future addition, out of scope here.
- The ingredient-line parser is heuristic; malformed or unusually-phrased ingredient lines may parse into the wrong fields. Since the result lands in editable fields (not committed silently), this is an acceptable failure mode.
