<#
.SYNOPSIS
Analyzes Terraform environment folders to detect declared but unused variables ("pass-throughs")
and module inputs passed but not declared in target modules.

.DESCRIPTION
This utility scans `.tf` files within environment directories to:

- Identify variables declared but never used
- Detect module input arguments that lack corresponding variable declarations
- Report findings per environment with optional debug output

Use cases include:
- Auditing Terraform environments for unused or misaligned configuration
- Validating module interface consistency during development
- Automating static analysis as part of CI/CD pipelines
- Supporting onboarding by highlighting declared inputs vs actual usage

Supports configurable root paths for environment and module folders. Designed to assist
in maintaining hygiene, consistency, and alignment across modular Terraform configurations.

.EXAMPLE
pwsh ./Scan-TFVariables.ps1

Scans the default ./envs and ./modules folders, reporting unused variables and undeclared module inputs per environment.

.EXAMPLE
pwsh ./Scan-TFVariables.ps1 -EnvsRoot "/mnt/c/GitRepos/devops-infra/terraform/envs" -ModulesRoot "/mnt/c/GitRepos/devops-infra/terraform/modules"

Scans Terraform environments and modules from custom paths. Useful when folders are outside the repo root.

.EXAMPLE
pwsh ./Scan-TFVariables.ps1 -EnvsRoot "./sandbox/envs" -ModulesRoot "./sandbox/modules" -Debug

Provides verbose debug output including resolved variable definitions and usage counts. Helpful during local testing or onboarding.
#>
#!/usr/bin/env pwsh
param(
    [string]$EnvsRoot = ".\envs",
    [string]$ModulesRoot = ".\modules",
    [switch]$Debug
)

$envDirs = Get-ChildItem -Path $EnvsRoot -Directory

# $results = @{}
$passThrough = @{}
$moduleMismatch = @{}

if (-not (Test-Path $ModulesRoot)) {
    Write-Warning "Modules root '$ModulesRoot' does not exist. Please verify the path."
    return
}

if (-not (Test-Path $EnvsRoot)) {
    Write-Warning "Environments root '$EnvsRoot' does not exist. Please verify the path."
    return
}

foreach ($env in $envDirs) {
    $envName = $env.Name
    $envPath = $env.FullName
    $varDefs = @{}
    $usedVars = @{}
    $passedInputs = @{}

    # Parse declared variables
    $varFiles = Get-ChildItem -Path $envPath -Filter "*.tf" -Recurse
    foreach ($file in $varFiles) {
        $lines = Get-Content $file.FullName
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match '^\s*variable\s+"(\w+)"') {
                $varDefs[$matches[1]] = $true
            }
        }
    }

    # Parse usages of var.*
    foreach ($file in $varFiles) {
        (Get-Content $file.FullName) -match 'var\.([a-zA-Z_]\w*)' | Out-Null
        foreach ($m in $Matches[1..($Matches.Count - 1)]) {
            $usedVars[$m] = $true
        }
    }

    # Parse variables passed into modules
    foreach ($file in $varFiles) {
        $inModule = $false
        foreach ($line in Get-Content $file.FullName) {
            if ($line -match '^\s*module\s+"') {
                $inModule = $true
            }
            if ($inModule -and $line -match '^\s*(\w+)\s*=\s*var\.([a-zA-Z_]\w*)') {
                $passedInputs[$matches[2]] = @($matches[1]) + $passedInputs[$matches[2]]
            }
            if ($inModule -and $line -match '^\s*}') {
                $inModule = $false
            }
        }
    }

    # Detect which passed inputs are ignored by modules
    foreach ($var in $passedInputs.Keys) {
        foreach ($modArg in $passedInputs[$var]) {
            $moduleBlocks = Select-String -Path "$ModulesRoot/*/variables.tf" -Pattern "variable\s+`"$modArg`"" -Quiet
            if (-not $moduleBlocks) {
                if (-not $moduleMismatch.ContainsKey($envName)) {
                    $moduleMismatch[$envName] = @()
                }
                $moduleMismatch[$envName] += $var
            } else {
                $usedVars[$var] = $true
            }
        }
    }

    # Determine pass-throughs
    $envPassThrough = @(
        $varDefs.Keys | Where-Object { -not $usedVars.ContainsKey($_) }
    ) | Sort-Object

    $passThrough[$envName] = $envPassThrough

    if ($Debug) {
        Write-Host "`n-- DEBUG [$envName] Used Variables --"
        Write-Host ($usedVars.Keys -join ", ")
        Write-Host "-- DEBUG [$envName] Declared Variables --"
        Write-Host ($varDefs.Keys -join ", ")
        Write-Host "-- DEBUG [$envName] Final Pass-Throughs --"
        Write-Host ($envPassThrough -join ", ")
    }
}

# Output report
Write-Host "`n========== PASS-THROUGH VARIABLE REPORT =========="
foreach ($env in $passThrough.Keys) {
    Write-Host "`nEnvironment: $env"
    Write-Host "Pass-Through Variables Count: $($passThrough[$env].Count)"
    $passThrough[$env] | ForEach-Object { Write-Host "[] $_" }
}

Write-Host "`n========== MODULE INPUTS NOT DECLARED =========="
foreach ($env in $moduleMismatch.Keys) {
    Write-Host "`nEnvironment: $env"
    Write-Host "Module Inputs Not Declared Count: $($moduleMismatch[$env].Count)"
    $moduleMismatch[$env] | Sort-Object | Get-Unique | ForEach-Object { Write-Host "[] $_" }
}