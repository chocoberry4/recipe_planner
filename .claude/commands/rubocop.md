Run RuboCop linter on the project using Rails Omakase style rules.

```bash
bin/rubocop
```

Review the output and summarise any offences found, grouped by file. Then ask the user: "There are X auto-correctable offences — would you like me to run autocorrect?" If they say yes, run:

```bash
bin/rubocop -A
```

Then confirm what was fixed.