Generate a commit message for the user to paste based on the current staged and unstaged changes.

```bash
git diff HEAD
```

```bash
git status --short
```

Review the changes and write a concise commit message following these rules:
- First line: short summary under 72 characters, imperative mood ("Add", "Fix", "Update", not "Added", "Fixed")
- If needed, a blank line then a short body explaining *why*, not *what*
- Do not include the Co-Authored-By trailer

Present just the commit message in a code block for the user to copy and paste. Do not run the commit yourself.