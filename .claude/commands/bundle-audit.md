Run bundler-audit to check for known security vulnerabilities in gem dependencies.

```bash
bin/bundler-audit check --update
```

Review the output and summarise any vulnerabilities found, including:
- The gem name and vulnerable version
- The CVE or advisory ID
- A brief description of the vulnerability

If vulnerabilities are found, list each affected gem and ask the user: "Found X vulnerable gems — would you like me to update them?" If they say yes, run `bundle update` for each affected gem individually (not all at once), e.g.:

```bash
bundle update <gem_name>
```

After each update, confirm what version was installed. Once all updates are done, re-run the audit to confirm no vulnerabilities remain:

```bash
bin/bundler-audit check
```

If no vulnerabilities are found, confirm the project is clean.
