# Findings Standard

Every `findings.md` in this repo is reviewed against this standard before it's committed.

## 1. Scope: which layer does a finding belong to?

Each step answers a different question. A finding goes in the layer whose question it answers.

| Layer | Question it answers | Belongs here | Does **not** belong here |
|---|---|---|---|
| **Data cleaning** (`cleaning/`) | Is the raw data a faithful, complete, consistent record of how the business works? | Records that break business rules; missing or untracked data; broken joins; load errors; how each issue is fixed in Transform | Which fields or rows a project should use; metric definitions; what an issue means for a project's conclusions |
| **Project** (`p1_…`, `p2_…`, `p3_…`) | What does the data say about the business question, and what should we do? | Scoping (which data, which metric definitions); analysis; recommendations | Re-checking data quality that was already validated |

When a cleaning finding *raises* a project-level question, it's listed under **Hand-off to project scoping** at the end of the cleaning findings, and decided in the project.

## 2. Review checklist

| # | Criterion | Test |
|---|---|---|
| 1 | **Business-model relevant** | Does the finding say which business rule the data follows or breaks (e.g. "a deal can't close before first contact")? |
| 2 | **Scope relevant** | Is it in the right layer (section 1)? Project-level implications go in the hand-off list. |
| 3 | **Stakeholder relevant** | Would a data owner or business stakeholder know what to do with it? Every problem names an owner-level action or a treatment. |
| 4 | **Concise** | Lead with the answer. One idea per paragraph. No step-by-step narration of the queries. |
| 5 | **Clear logic, accurate evidence, real insight** | Every number traces to a query in `sql/` and a file in `results/`. Claims follow from the numbers. It goes beyond restating results to explain *why* (for example, ruling out alternative explanations). |

## 3. Structure of a cleaning `findings.md`

1. **Summary**: one row per core question, each with a direct answer
2. **Business model fit**: does the data follow the business's rules?
3. **Critical missing data**: what's missing, why, and who should fix it at the source
4. **Integrity**: keys, joins, duplicates, completeness of the load
5. **Check-by-check results**: Pass / Fail against the checklist
6. **Hand-off to project scoping**: questions this step raises but doesn't decide
7. **Files**: links to the SQL and results behind every number
