# Unit 07: Autosort Review UI

- **Related**: [ADR-0004](../../adr/0004-suggest-and-correct-autosort-ux.md)
- **Depends on**: Unit 02 (Slice B — Create/Edit/Detail), Unit 03, Unit 05, Unit 06

## Goal

Implement the suggest-and-correct UI — this is where ADR-0004 actually becomes usable rather than just a policy.

## In scope

- Vue component rendering each instruction step with its assigned ingredients/groups
- Editable: add/remove an ingredient from a step, drag an ingredient between steps
- "Unresolved ingredients" tray for Tier-3 leftovers from the matching engine
- Save action persisting corrections to `instruction_ingredients`

## Out of scope

- The matching logic itself (Unit 05) — this unit only renders and edits its output

## Acceptance criteria

- A user can review an imported or manually-entered recipe's autosort result, fix a wrong assignment, and save it
