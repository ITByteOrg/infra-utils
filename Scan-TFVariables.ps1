<#
.SYNOPSIS
Scans a Terraform environment directory for declared variables that are not directly used (pass-through variables).

.DESCRIPTION
- Parses all `.tf` files under a specified `envsRoot` directory.
- Identifies variable declarations and checks for usage **outside** module blocks.
- Reports variables that are only passed through and never referenced directly.
- Output is written to `$HOME\Downloads\VariableScanResults.txt`.

.PARAMETER envsRoot
Root path of the Terraform environments to scan (set in script variable).

.PARAMETER modulesRoot
Root path of reusable Terraform modules (optional, for future expansion).

.OUTPUT
Text file listing pass-through variables for each environment, with timestamps.

.EXAMPLE
Just run the script:
    ./Scan-TFVariables.ps1

#>
$envsRoot    = "C:\GitRepos\devops-infra\terraform\envs"
$modulesRoot = "C:\GitRepos\devops-infra\terraform\modules"
$outputPath  = Join-Path $HOME "Downloads\VariableScanResults.txt"

# Prep for fresh output
if (Test-Path $outputPath) { Remove-Item $outputPath }
Add-Content $outputPath "Terraform Variable Scan Results - $(Get-Date)`n"

Get-ChildItem -Path $envsRoot -Directory | ForEach-Object {
    $envName = $_.Name
    $envPath = $_.FullName
    Write-Host "`nEnvironment: $envName" -ForegroundColor Cyan
    Add-Content $outputPath "`nEnvironment: $envName"

    $varDefs  = @{}
    $usedVars = @{}

    # ─── 1. Collect declared variables ─────────────────────────────
    Get-ChildItem -Path $envPath -Recurse -Include *.tf | ForEach-Object {
        $file = $_.FullName
        Select-String -Path $file -Pattern 'variable\s+"([^"]+)"' | ForEach-Object {
            $varName = $_.Matches.Groups[1].Value
            if (-not $varDefs.ContainsKey($varName)) {
                $varDefs[$varName] = $file
            }
        }
    }

    # ─── 2. Track usage OUTSIDE module blocks ──────────────────────
    Get-ChildItem -Path $envPath -Recurse -Include *.tf | ForEach-Object {
        $file = $_.FullName
        $inModuleBlock = $false
        Get-Content $file | ForEach-Object {
            $line = $_.Trim()
            if ($line -match '^module\s+"') { $inModuleBlock = $true }
            elseif ($inModuleBlock -and $line -eq '}') { $inModuleBlock = $false }

            if (-not $inModuleBlock) {
                foreach ($var in $varDefs.Keys) {
                    if ($line -match "var\.$var") {
                        $usedVars[$var] = $true
                    }
                }
            }
        }
    }

    # ─── 3. Report pass-through variables ──────────────────────────
    $passThrough = $varDefs.Keys | Where-Object { -not $usedVars.ContainsKey($_) }
    if ($passThrough.Count -gt 0) {
        Write-Host "Pass-through variables:" -ForegroundColor Yellow
        Add-Content $outputPath "Pass-through variables:"
        foreach ($var in $passThrough) {
            Write-Host "   • $var"
            Add-Content $outputPath "   • $var"
        }
    }

    # ─── 4. Check module input mismatches ──────────────────────────
    Get-ChildItem -Path $envPath -Recurse -Include *.tf | ForEach-Object {
        $file = $_.FullName
        $lines = Get-Content $file
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            if ($line -match '^module\s+"([^"]+)"\s+\{') {
                $moduleName = $matches[1]
                $inputs     = @()
                $j = $i + 1
                while ($j -lt $lines.Count -and $lines[$j] -notmatch '^\}') {
                    $inputLine = $lines[$j].Trim()
                    if ($inputLine -match '^([a-zA-Z0-9_]+)\s+=') {
                        $inputs += $matches[1]
                    }
                    $j++
                }

                $moduleFolder = Join-Path $modulesRoot $moduleName
                if (-not (Test-Path $moduleFolder)) {
                    continue
                }

                $declaredVars = @()
                Get-ChildItem -Path $moduleFolder -Recurse -Include *.tf | ForEach-Object {
                    Select-String -Path $_.FullName -Pattern 'variable\s+"([^"]+)"' | ForEach-Object {
                        $declaredVars += $_.Matches.Groups[1].Value
                    }
                }

                $undeclared = $inputs | Where-Object { $_ -notin $declaredVars }
                if ($undeclared.Count -gt 0) {
                    Write-Host "🚩 Module '$moduleName': Passed inputs not declared" -ForegroundColor Red
                    Add-Content $outputPath "🚩 Module '$moduleName': Passed inputs not declared"
                    foreach ($miss in $undeclared) {
                        Write-Host "   • $miss"
                        Add-Content $outputPath "   • $miss"
                    }
                    Add-Content $outputPath "   From: $file"
                }
            }
        }
    }
}
