# AGENTS.md

Guidance for any agent or developer working in this repository.

## Bar: A+ codebase

This project holds itself to an A+ standard. That means:

- **Everything is testable.** Game logic lives in pure Dart classes with no
  widget or platform dependencies. UI is thin. Anything that can be a pure
  function is a pure function.
- **Run tests after every change, no matter how small.**
  `flutter test` must pass before committing. If you changed logic, the test
  that covers it must exist and run.
- **100% coverage is the target.** `flutter test --coverage` should report full
  coverage of `lib/src/**`. Generated files (`*.g.dart`, generated l10n) are
  excluded. If you add code you cannot cover, refactor it until you can.
- **No hardcoded user-facing strings.** All copy goes through the ARB files in
  `l10n/`. English is the source of truth; keep the other locales in sync.
- **No magic numbers in the UI layer.** Colors, sizes, durations and curves
  live in `lib/src/theme/`. A widget file should read like layout, not like a
  spreadsheet.
- **Determinism.** Anything random takes an injectable seed. Golden tests must
  be reproducible on any machine.
- **Small commits.** One concern per commit. Commit early, commit often.

## Layout

- `lib/src/game/` - pure Dart game engine. No Flutter imports beyond
  `foundation`.
- `lib/src/theme/` - design tokens (colors, text styles, metrics, motion).
- `lib/src/presentation/` - widgets, painters, screens.
- `l10n/` - ARB files. `flutter gen-l10n` generates into
  `lib/l10n/generated/` (do not edit generated files).
- `tools/` - repo tooling (asset generation, coverage reporting).
- `test/` - mirrors `lib/`. Golden files live in `test/goldens/`.

## Workflow

- Work happens on branches, merged through merge requests.
- Never commit on `main` directly for feature work.
- Verification before pushing: `flutter analyze` and `flutter test` clean.
- Goldens regenerate with `flutter test --update-goldens` only when a visual
  change is intentional; say so in the MR description.

## Commits

- Short, plain messages. Describe the change, not the journey.
