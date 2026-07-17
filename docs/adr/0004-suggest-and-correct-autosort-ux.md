# ADR-0004: Suggest-and-correct UX for autosort

- **Status**: Accepted
- **Related**: [Intent 0001](../intent/0001-recipe-planner-phase1.md), [Design: Recipe Import & Autosort](../design/recipe-import-and-autosort.md)

## Context

The autosort engine (splitting instructions into steps and assigning ingredients/groups to each step) relies on structural cues, prose matching, and fuzzy text matching. None of these are guaranteed correct for arbitrary recipe writing — the whole premise of this project is that Tandoor's equivalent feature gets it wrong often enough to be frustrating. Two UX options:

1. **Fully automatic** — commit the engine's best guess with no review step.
2. **Suggest-and-correct** — render the engine's output as an editable draft (ingredients/groups assignable per step, drag or add/remove) before it's saved.

## Decision

Suggest-and-correct. The autosort output is always a reviewable draft, never a silent commit.

Rationale: a wrong automatic assignment is strictly worse than no assignment, because it's confidently wrong and easy to miss — that is the exact failure mode motivating this project. A quick manual fix on a mostly-right draft is cheap; hunting for a silently-wrong ingredient assignment later is not.

## Consequences

- Need `instruction_ingredients` (the join table holding the actual assignments) to be editable through the UI, not just written once by the import/parse job.
- Need UI affordance for "unresolved" ingredients that the engine couldn't confidently place, so they're visibly pending rather than silently dropped.
- Slightly more UI work upfront than a "just trust the algorithm" approach — accepted tradeoff given the goal is correctness, not speed of import.
