# Q1 Findings · 阶段 1 · 标准 v1

- 运行日期：2026-10-13
- SQL：`sql/01_quality_checklist.sql`（标准检查）、`sql/02_followups_stage1.sql`（对需要判断的结果做追查）
- 结果：`results/quality_check_results_stage1.csv`（122 行）、`results/followups_stage1.csv`
- 扫描量：约 38 MB，费用可以忽略

## 总览

| check_name | 结果 | 一句话 |
|---|---|---|
| rows_completion | ✅ Pass | 5 张表的行数和 Kaggle 公开版完全一致 |
| data_type | ✅ Pass | 日期列已经是 DATE / TIMESTAMP，金额是 FLOAT64，ID 是 STRING；没有以 STRING 存储的日期列 |
| distinct_primary_key | ✅ Pass | 5 张表的主键都没有重复 |
| null_check | ⚠️ 需说明 | 核心字段都没有空值；closed_deals 有 5 个字段大面积缺失；发现“伪空值”（见下文） |
| date_logic | ❌ Fail（量很少） | 1 条成交早于首次接触；送达早于下单 = 0 |
| value_range | ✅ Pass | 没有 ≤ 0 的价格，也没有负运费；极端值能被业务解释 |
| category_values | ❌ Fail | 有 1,655 笔订单长期停在中间状态 |
| duplicate_rows | ✅ Pass | 5 张表都没有整行重复 |
| referential_integrity | ✅ Pass | 三条关联都是 0 条孤立记录 |
| observation_window | ⚠️ 需说明 | 有完整窗口的商家数达标（667 家），但匹配率只有 45% |

## 逐项判断

### rows_completion ✅
mql_leads 8,000、closed_deals 842、orders 99,441、order_items 112,650、sellers 3,095，全部等于预期。导入完整。

### data_type ✅
- autodetect 已经把所有日期列识别成 DATE / TIMESTAMP，`string_date_columns = 0`。所以 T1 不需要用 SAFE_CAST 转换，只需要在比较前把 TIMESTAMP 统一转成 DATE。
- `sellers.seller_zip_code_prefix` 是 STRING，正确，能保留开头的 0。
- `closed_deals.average_stock` 是 STRING，它本来就是分档文本，不是数值。

### distinct_primary_key ✅
orders.order_id、sellers.seller_id、mql_leads.mql_id、closed_deals.mql_id 的重复数都是 0。order_items 的 (order_id, order_item_id) 也唯一，确认一行 = 一个订单里的一件商品。

### null_check ⚠️

| 表.字段 | 空值数 | 判断 |
|---|---|---|
| mql_leads.origin | 60（0.75%） | 按计划填 unknown。**但原始数据里已经有 1,099 条取值就是 `unknown`**，合并后 unknown 共 1,159 条，占 **14.5%**。在 P1 按渠道分析时必须单独列出 |
| closed_deals.business_segment / lead_type / business_type | 1 / 6 / 10 | 都低于 1.2%，填 unknown 后可以用于 P1 分析 4 |
| closed_deals.lead_behaviour_profile | 177（21%） | 缺失多，只作为参考，不作为主要拆分维度 |
| closed_deals.has_company / has_gtin / average_stock / declared_product_catalog_size | 约 92% | 基本没有数据，不进 clean 表 |
| closed_deals.declared_monthly_revenue | 0 | **伪空值**：没有空值，但有 797 条（94.7%）是 0，实际上等于“没填”。不进 clean 表 |
| orders.order_id / customer_id | 0 | 通过 |
| orders.order_approved_at | 160 | 其中 delivered 订单 14 条，量很少，接受（P1 不用这个字段） |
| orders.order_delivered_customer_date | 2,965 | 其中状态是 delivered 的只有 8 条。按计划：保留在复购计算中，从延迟分析中排除（这是 P2 的处理） |

### date_logic ❌（量很少）
- 送达早于下单：0。
- **won_date 早于 first_contact_date：1 条**（mql_id `b91cf881…`，提前 2 天）。按标准“数量很少就排除并记录”，在 T4 生成 clean.closed_deals 时排除。
- 日期范围：orders 2016-09-04 到 2018-10-17；mql 2017-06-14 到 2018-05-31，都符合预期。
- **won_date 最晚到 2018-11-14，晚于订单数据截止日。** 有 50 家商家在 2018-08-30 之后才成交，订单数据里不可能有它们的订单。observation_window 会自动排除它们，这里只做记录。

### value_range ✅
price 没有 ≤ 0 的值；中位数 74.99，P99 是 890，最大值 6,735。freight_value 没有负值，P99 是 84.38，最大值 409.68。极端值只占很小比例，而且是高价商品，业务上说得通，保留。

### category_values ❌
order_status 只出现 8 个已知取值（delivered 96,478、shipped 1,107、canceled 625、unavailable 609、invoiced 314、processing 301、created 5、approved 2）。下单超过 30 天还停在中间状态的订单有 **1,655 笔**：shipped 1,058、processing 301、invoiced 289、created 5、approved 2。按标准，分析只用 delivered，这些订单排除并记录数量。

### duplicate_rows ✅
5 张表都没有整行重复。

### referential_integrity ✅
- order_items → orders：0 条孤立。
- order_items → sellers：0 条孤立。
- closed_deals → mql_leads：0 条孤立。842 条成交都能对回线索，P1 的关联路径没有问题。

### observation_window ⚠️
- 成交商家 842 家，其中 **380 家（45.1%）** 在 order_items 里至少有一笔订单。
- 按成交月份拆开看：2018-01 到 2018-05 成交的商家，匹配率稳定在 50%–56%；2018-06 以后快速下降（40% → 27% → 6% → 0%），因为这些商家成交太晚，订单数据已经截止。
- 匹配上的商家里，**没有一家**在成交日期之前就有订单。说明 seller_id 的关联口径是可靠的。
- 有完整 90 天窗口的商家（won_date ≤ 2018-06-01）：**667 家**，其中有订单的 **346 家**。都远高于 100 家的门槛，不需要把窗口缩短到 60 天或 30 天。
- 截止日之后的订单：21 笔。

**解读：** 即使是成交早、观察期足够的商家，也只有大约一半出现在订单数据里。原因可能有两个，用现有数据分不开：一是确实有一半商家成交后没开始卖货；二是 Kaggle 的订单数据是抽样（约 10 万笔），部分商家的订单没被抽到。这一点必须写进 P1 的局限性。

## 需要你决定的事

1. **null_check 标准是否升级到 v2？** 现在的 v1 只数 NULL，漏掉了“用 0 或 `unknown` 代替空值”的伪空值（declared_monthly_revenue 94.7% 是 0；origin 有 1,099 条 `unknown`）。建议在 v2 里加一项 `placeholder_values`：检查数值字段等于 0 的比例、分类字段等于 unknown / other 的比例。按计划的规则，升级要在 Cleaning Log 写明原因。
2. **P1 的订单状态口径。** checklist 写的是“分析只用 delivered”，但 P1 tab 的分析 2 写的是“状态不是 canceled / unavailable”（会把长期停在 shipped 的订单也算进去）。建议统一成**只用 delivered**：和 checklist 一致，也能避开这 1,655 笔可疑订单。
3. **匹配率 45% 怎么处理。** checklist 写的是“匹配率低时，激活率改用‘是否有任何订单’”。我的建议是**保留 90 天口径**：完整窗口的商家有 667 家，样本足够；对不上订单的商家计为“未激活”（P1 分析 2 本来就是这么写的：没有订单的商家记为 0）。同时在局限性里写明“可能有一部分是抽样导致的”。

## 进入 Transform 的处理清单（已经确定的部分）

| 步骤 | 处理 |
|---|---|
| T1 | 不需要 SAFE_CAST；比较日期前统一用 DATE() 转换 |
| T3 | origin：NULL 和 `unknown` 合并为 unknown（共 1,159 条，14.5%），其他取值去空格、转小写 |
| T4 clean.closed_deals | 排除 won_date 早于 first_contact_date 的 1 条；不保留 has_company、has_gtin、average_stock、declared_product_catalog_size、declared_monthly_revenue |
| T4 clean.seller_orders | 订单状态口径取决于决定 2 |
