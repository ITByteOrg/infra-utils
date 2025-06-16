# infra-utils
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Reusable utilities and diagnostics for managing infrastructure workflows and automation.

This repository contains a growing collection of PowerShell scripts to support infrastructure engineers working with Terraform, PowerShell automation, and multi-environment orchestration. The tools are structured to be modular, reusable, and easily integrated into CI/CD pipelines or local workflows.

## What's Included

| Script | Purpose |
|--------|---------|
| `Scan-TFVariables.ps1` | Scans Terraform environments for pass-through variables and module input mismatches to reduce false positives and improve configuration hygiene. |

```markdown
1. Clone the repository:

   ```bash
   git clone https://github.com/ITByteEnthusiast/infra-utils.git
   ```

2. Run a script:

   ```powershell
   .\Scan-TFVariables.ps1
   ```

3. View the output:

   Output will display in the terminal and be written to:

   ```
   $HOME\Downloads\VariableScanResults.txt
   ```

## Use Cases

- Reduce unnecessary tflint warnings for pass-through variables

- Detect module input mismatches that could signal drift or typos

- Consolidate infrastructure tooling in one central location for maintenance and scalability

## License
This project is licensed under the Apache License 2.0. You may use, modify, and distribute the scripts with attribution.

## Contributing

While this project is publicly available under an open license, contributions are currently not being accepted.

You're welcome to use, fork, or adapt the scripts for your infrastructure work. If you find them helpful, a star or mention is always appreciated.

## Maintainer
Developed and maintained by ITByteEnthusiast, this project supports real-world infrastructure engineering needs and continuous improvement of automation workflows.
