# Findings Standard

Every `findings.md` in this repo is reviewed against this standard before it's committed.

## 1. Scope: which layer does a finding belong to?

Each step answers a different question. A finding goes in the layer whose question it answers.

| Layer | Question it answers | Belongs here | Does **not** belong here |
|---|---|---|---|
| **Shared Data QA** (`data_prep/2_data_qa`) | Is the raw data a faithful, complete, consistent record of how the business works? | Records that break business rules; missing or untracked data; broken joins; load errors; *recommended* handling for each issue | Which fields or rows a project should use; metric definitions; what an issue means for a project's conclusions |
| **Project transformation** (`data_prep/3_transformation/p…`) | Given this project's scope, how is the data fixed and reshaped, and did anything get lost? | Which Q1 treatments were applied; clean-table design; reconciliation results | Re-deciding scope, or new data-quality checks (those go back to Data QA) |
| **Project analysis** (`p1_…`, `p2_…`, `p3_…`) | What does the data say about the business question, and what should we do? | Scoping (which data, which metric definitions); analysis; recommendations | Re-checking data quality that was already validated |

When a Data QA finding *raises* a project-level question, it's listed under **Hand-off to project scoping** at the end of the Data QA findings, and decided in the project.

## 2. Review checklist

| # | Criterion | Test |
|---|---|---|
| 1 | **Business-model relevant** | Does the finding say which business rule the data follows or breaks (e.g. "a deal can't close before first contact")? |
| 2 | **Scope relevant** | Is it in the right layer (section 1)? Project-level implications go in the hand-off list. |
| 3 | **Stakeholder relevant** | Would a data owner or business stakeholder know what to do with it? Every problem names an owner-level action or a treatment. |
| 4 | **Concise** | Lead with the answer. One idea per paragraph. No step-by-step narration of the queries. |
| 5 | **Clear logic, accurate evidence, real insight** | Every number traces to a query in `sql/` and a file in `results/`. Claims follow from the numbers. It goes beyond restating results to explain *why* (for example, ruling out alternative explanations). |

## 3. How the standard is enforced

| Layer | Covers | How |
|---|---|---|
| **Automated** | English only; required sections; links resolve; every file in `sql/` and `results/` is linked (traceability); status icons have a legend; every ⚠️ / ❌ row has a treatment; the check-by-check table has the required columns and every non-pass row explains what it means | [`scripts/check_findings.py`](../scripts/check_findings.py), run by a git pre-commit hook. A commit that fails is blocked. One-time setup after cloning: `git config core.hooksPath .githooks` |
| **Review** | Criteria 1–5 in section 2 that need judgment | Before committing, the author scores every finding against criteria 1–5 using the template below. Any finding that misses a criterion is rewritten, moved to the hand-off list, or cut |

**Review template** (completed before each commit, not stored in the findings file):

| Finding | 1 Business | 2 Scope | 3 Stakeholder | 4 Concise | 5 Evidence & insight | Action |
|---|---|---|---|---|---|---|
| e.g. 2a Unknown channel | ✅ breaks rule B2 | ✅ data-source issue | ✅ names an owner action | ✅ | ✅ 3 tests rule out alternatives; numbers in `03_…csv` | Keep |

**Plain-language test:** every table must be readable on its own. If a reader can't tell from the row alone what was tested, what was found, and what happens next, rewrite the row.

**Check-by-check table:** this is the most detailed table in a Data QA findings file, not a summary. It has the columns *Check · Passes if… · Result · What we found · What it means · Treatment*. For every ⚠️ / ❌ row:
- **What we found** gives the specific numbers and which records are affected (e.g. "1,655 orders still `shipped` / `processing`… placed 30+ days ago"), not a label like "stuck orders".
- **What it means** gives the judgment: the likely cause, and the evidence that rules out other explanations (e.g. "all are past their promised delivery date, so the outcome was never recorded, not slow delivery").
- Labels like "Minor" or "See 2b" are never enough on their own.

## 4. Structure of a Data QA `findings.md`

1. **Summary**: one row per core question, each with a direct answer
2. **Business model fit**: does the data follow the business's rules?
3. **Critical missing data**: what's missing, why, and who should fix it at the source
4. **Integrity**: keys, joins, duplicates, completeness of the load
5. **Check-by-check results**: Pass / Fail against the checklist
6. **Hand-off to project scoping**: questions this step raises but doesn't decide
7. **Files**: links to the SQL and results behind every number
