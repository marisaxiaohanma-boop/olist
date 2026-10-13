# Data prep

Everything that happens to the data before analysis, in three steps:

| Step | Question it answers | Changes data? | Scope |
|---|---|---|---|
| [**1 · Setup**](1_setup) | Is the raw data loaded, and is the environment ready? | Loads `raw` only | Shared |
| [**2 · Data QA**](2_data_qa) | Is the raw data a faithful record of how the business works: does it follow the business model, is critical data missing, do the tables join? | No | Shared |
| [**3 · Transformation**](3_transformation) | Given what a project needs, how do we fix the issues Data QA found and build its `clean` tables, and did we lose anything along the way? | Yes, writes `clean` | Per project |

Transformation is per project because what counts as "clean" depends on the business question. For example, which order statuses count as revenue is a P1 decision, not a data-quality fact. Each project's transformation starts after that project's scoping.

**Start here:** [Data QA findings](2_data_qa/findings.md).
