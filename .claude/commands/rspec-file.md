Run RSpec on the currently open or selected file.

Identify the file the user is working on from the conversation context (ide_opened_file or ide_selection). Then run:

```bash
rspec <file_path>
```

Summarise the results: how many examples ran, how many passed, how many failed. If there are failures, show the failure messages and the line numbers. Do not show passing test output in full — just the summary line.