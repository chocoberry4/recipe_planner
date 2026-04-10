Run RuboCop linter on the project using Rails Omakase style rules.

```bash
bin/rubocop
```

Review the output and summarise any offences found, grouped by file.

If there are auto-correctable offences, run autocorrect immediately without asking:

```bash
bin/rubocop -A
```

Then confirm what was fixed. If there are non-auto-correctable offences, list them for the user to fix manually.
