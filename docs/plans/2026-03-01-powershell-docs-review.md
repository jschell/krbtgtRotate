# krbtgtRotate — PowerShell & Documentation Review
**Date:** 2026-03-01
**Reviewer:** Claude (claude-sonnet-4-6)
**Module Version at Review:** 0.2.1
**Branch:** claude/review-powershell-docs-ssBAw

---

## Scope

Full review of all 13 PowerShell files (3 private, 10 public functions + module loader + manifest) and all 13 documentation files (11 `.md` docs, 1 `about_*.txt` help file, 1 README). Improvements are ordered by **immediacy and impact to end users**.

---

## Priority 1 — Critical Bugs (cause silent runtime failures)

### 1a. Undefined variable in `New-ComplexPassword.ps1`
**File:** `public/New-ComplexPassword.ps1` (original line 189)
**Status:** Fixed in v0.2.2

`Write-Warning $msgWarnPasswordGenerationNotComplex` referenced an undefined variable. The correct name was `$msgPasswordGenerationNotComplex` (defined two lines earlier). When password generation failed after 20 iterations, the warning statement itself threw a `VariableNotFound` error, masking the real failure and potentially leaving a rotation in an undefined mid-state.

**Fix:** `$msgWarnPasswordGenerationNotComplex` → `$msgPasswordGenerationNotComplex`

**Test that catches this:** `Code.Quality.Tests.ps1` T1 — AST analysis verifies all `Write-Warning` variable references are assigned in the same scope.

---

### 1b. `break` used outside loop in `Test-ComplexPassword.ps1`
**File:** `public/Test-ComplexPassword.ps1` (original line 190)
**Status:** Fixed in v0.2.2

In the `Begin` block, a `catch [ADIdentityNotFoundException]` used `break` instead of `return $False`. `break` only works inside loops/switch statements. Outside a loop, it propagates outward and exits the enclosing scope, causing undefined behavior for the caller (`New-ComplexPassword`, `Invoke-KrbtgtPasswordRotate`).

**Fix:** `break` → `return $False`

**Test that catches this:** `Code.Quality.Tests.ps1` T2 — AST analysis walks the parent chain of every `BreakStatementAst` and fails if no enclosing loop or switch is found.

---

### 1c. Cryptic error message in module loader `krbtgtRotate.psm1`
**File:** `krbtgtRotate.psm1` (original lines 29 and 45)
**Status:** Fixed in v0.2.2

Both catch blocks in the function loader emitted the bare string `"Error observed! S_"` — the `S_` is an incomplete placeholder. The string was output to the *success stream*, not the error stream. An administrator importing the module in a new environment with a missing dependency would see this meaningless string with no indication of which file failed or why.

**Fix:** Replaced with `Write-Warning "Error loading '$($entry.FullName)': $($_.Exception.Message)"` — routes to the warning stream and includes the file path and actual exception message.

**Test that catches this:** `Code.Quality.Tests.ps1` T5 — content regex ensures `"Error observed! S_"` no longer appears.

---

## Priority 2 — Documentation Gaps (safety-critical tool)

### 2a. `about_krbtgtRotate.help.txt` — entirely placeholder
**File:** `en-us/about_krbtgtRotate.help.txt`
**Status:** Completed

The file contained only template text. `Get-Help about_krbtgtRotate` returned "Summary of the module" and "Longer description of the module". New content covers: what krbtgt is, why rotation is critical, the safe-rotation strategy (ticket lifetime + clock skew), required privileges, quick-start workflow, and known module limitations.

**Test that catches regressions:** `Documentation.Tests.ps1` — checks placeholder strings are absent and LONG DESCRIPTION has meaningful content.

---

### 2b. `docs/krbtgtRotate.md` — all 10 cmdlet descriptions were `{{template}}`
**File:** `docs/krbtgtRotate.md`
**Status:** Completed

Every cmdlet entry and the module-level description were `{{Manually Enter ... Description Here}}` placeholders. The module index page — the first stop after `Get-Help krbtgtRotate` — appeared completely unmaintained. All 11 descriptions replaced with accurate one-liners. `Download Help Link` and `Help Version` header fields also corrected.

**Test that catches regressions:** `Documentation.Tests.ps1` — scans for `{{Manually Enter` patterns.

---

### 2c. `docs/Write-KrbtgtEventLog.md` — placeholder synopsis/description + broken examples
**File:** `docs/Write-KrbtgtEventLog.md`
**Status:** Completed

- SYNOPSIS was "Brief description of the function"
- DESCRIPTION was "Detailed description of the function" followed by raw implementation notes (byte-array math) that leaked out of the source code
- Both examples used `Verb-Noun -ParameterA 'someValue'` template text

Replaced all three areas with accurate content and working `Write-KrbtgtEventLog` examples, including the EventID computation scheme moved to a proper descriptive context.

**Test that catches regressions:** `Documentation.Tests.ps1` + `Function.Help.Tests.ps1` T6.

---

### 2d. `docs/Write-LogMessage.md` — placeholder description, thin examples
**File:** `docs/Write-LogMessage.md`
**Status:** Completed

SYNOPSIS/DESCRIPTION were placeholders. Only one example provided, with no guidance on how to locate the generated log file. Added accurate SYNOPSIS/DESCRIPTION, a second example showing `-OutPath` and `-FileName` usage, and instructions for finding logs written to `$env:Temp`.

---

### 2e. `docs/Invoke-KrbtgtPasswordRotate.md` — WhatIf/Confirm placeholders
**File:** `docs/Invoke-KrbtgtPasswordRotate.md`
**Status:** Completed

`-WhatIf` description was `{{Fill WhatIf Description}}` and `-Confirm` was `{{Fill Confirm Description}}`. `-WhatIf` is especially important for this tool — it lets operators do a dry run. The new description clarifies what `-WhatIf` does and does *not* do (prerequisites still validate, but no password change occurs).

---

### 2f. `ReadMe.md` — missing essential operational information
**File:** `ReadMe.md`
**Status:** Completed

Added six sections:
1. **Required Privileges** — Domain Admin membership, elevated session requirement
2. **Step-by-Step: First Rotation** — 8-step guide from module import through log review
3. **What to Expect** — typical verbose output during a successful rotation
4. **Post-Rotation Validation** — `PasswordLastSet` check and replication verification commands
5. **Rollback and Recovery** — explicit warning against double-rotation, `repadmin` steps, authentication failure timeline
6. **Troubleshooting** — table of 8 common error scenarios with causes and resolutions; also expanded Documentation link list to include all 10 cmdlets

---

## Priority 3 — Medium Impact Code Quality

### 3a. Typos "obseved" in `Invoke-KrbtgtPasswordRotate.ps1`
**File:** `public/Invoke-KrbtgtPasswordRotate.ps1`
**Status:** Fixed in v0.2.2

Four identical instances of `"Halting error(s) have been obseved."` in `Throw` and event log messages. These strings appear during incident response; typos erode confidence and make log searching unreliable.

**Fix:** Global replace `obseved` → `observed` across all 4 instances.

**Test that catches regressions:** `Code.Quality.Tests.ps1` T3 — known-typo list scanned against all string literals.

---

## New Tests Added

| Test File | What It Catches |
|---|---|
| `tests/Code.Quality.Tests.ps1` | T1: `Write-Warning` undefined variable refs; T2: `break` outside loops; T3: known typos in string literals; T4: unexpected Global variable creation; T5: incomplete module loader error messages |
| `tests/Function.Help.Tests.ps1` (extended) | T6: "Brief description", "Detailed description", "Verb-Noun" placeholder strings in comment-based help |
| `tests/Documentation.Tests.ps1` | Placeholder strings in markdown docs and about_*.help.txt; required README sections |
| `tests/PSScriptAnalyzer.Tests.ps1` | PSScriptAnalyzer violations (with documented per-file rule exclusions) |

All new tests run without an Active Directory connection (pure static analysis).

---

## Known Remaining Issues (tracked for future versions)

These were identified but deferred from this pass:

| Issue | Location | Reason Deferred |
|---|---|---|
| Pre-rotate / post-rotate sync code duplication | `Invoke-KrbtgtPasswordRotate.ps1` ~lines 451–507 and 566–622 | Refactor requires new private function, risk to rotation-critical path; no functional bug |
| Global variable creation via `InfoVariable` | `Test-Port.ps1`, `Test-PortTCP.ps1` | Documented workaround for pre-WMF5; allowlisted in T4 test |
| TCP resource `Dispose()` not in `try/finally` | `Test-PortTCP.ps1` | Low blast radius; no reported failures |
| `$global:HaltingErrorCount` and `$global:paramWriteLog` globals | `Invoke-KrbtgtPasswordRotate.ps1` | Acknowledged in help as known limitation; removal requires larger refactor |
| Malformed parameter type syntax `[string][Microsoft.ActiveDirectory.Management.ADUser]` | `New-ComplexPassword.ps1`, `Test-ComplexPassword.ps1` | Functionally works due to PowerShell's implicit conversion; documented as PSSA exception |
