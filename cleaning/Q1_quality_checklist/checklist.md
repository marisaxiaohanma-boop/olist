# Quality Checklist · 标准 v1（2026-10-13 定稿）

> 来源：Growth Analytics Portfolio Plan →「2. Data Cleaning」tab。
> 原则：通过标准在跑 SQL 之前定好，结果出来后拿数字去对标准，不能为了结果好看去改标准。跑完发现漏项或标准不合理，可以修改，但要把版本号升到 v2，并在 `docs/cleaning_log.md` 写明原因。

**阶段 1（做 P1 之前）**：mql_leads、closed_deals、orders、order_items、sellers
**阶段 2（开始 P2 之前）**：customers、order_payments、order_reviews、products、product_category_name_translation

---

## 1. 检查项总览

| # | check_name | 检查什么 | 通过标准（v1） | 不通过时 | 涉及的表 | 阶段 |
|---|---|---|---|---|---|---|
| 1 | rows_completion | 每张表有没有数据，行数是否合理 | 每张表的行数等于 Kaggle 公开版的已知行数（见第 2 节） | 检查导入是否中断，重跑 S1 | 全部 10 张 | 1、2 |
| 2 | data_type | 日期、金额、ID 列有没有被识别成正确类型 | 日期列为 DATE / TIMESTAMP；price、freight_value、payment_value 为 FLOAT64 / NUMERIC；ID 为 STRING。日期列是 STRING 时，转换失败数应为 0 | 记下列名，在 T1 统一转换；转换失败的先看原始值格式 | 全部 | 1、2 |
| 3 | distinct_primary_key | 主键是否唯一，确认每张表一行代表什么 | 总行数 = 主键去重数。order_items、order_payments 一单多行属于正常，不算失败 | 先看重复行是完全重复，还是内容不同；业务上的一对多交给 T2 处理 | orders、sellers、mql_leads、closed_deals、customers、products、order_reviews | 1、2 |
| 4 | null_check | 核心字段的空值数量 | 不设统一门槛，逐列判断（见第 3 节） | 按逐列说明决定接受、剔除还是调查 | 全部 | 1、2 |
| 5 | date_logic | 时间先后关系是否合理 | 送达时间不早于购买时间；won_date 不早于 first_contact_date；日期范围与数据说明一致 | 数量很少就排除并记录；数量多就先停下来查原因 | orders、closed_deals、mql_leads | 1、2 |
| 6 | value_range | 金额和评分是否在合理范围 | price > 0；freight_value ≥ 0；review_score 在 1 到 5 之间；极端值占比低，而且能被业务解释 | 看异常样本，决定剔除、保留还是单独标注 | order_items、order_payments、order_reviews | 1、2 |
| 7 | category_values | 分类字段的取值是否在预期内 | order_status 只出现已知取值；shipped、processing、approved 等中间状态的订单，下单时间不应很早 | 分析只用 delivered；长期停在中间状态的订单排除，并记录数量 | orders | 1 |
| 8 | duplicate_rows | 有没有整行重复 | 整行重复数 = 0，或者已知且能解释 | 去重，并记录去掉了多少行 | 全部 | 1、2 |
| 9 | referential_integrity | 表和表之间能不能对上 | order_items 的订单都能在 orders 中找到；order_items 的 seller_id 都能在 sellers 中找到；closed_deals 的 mql_id 都能在 mql_leads 中找到；orders 的客户 100% 能在 customers 中找到 | 记录孤立记录的数量和比例，判断会不会影响分析 | order_items、orders、sellers、closed_deals、mql_leads、customers | 1、2 |
| 10 | observation_window | P1：成交商家能不能对上订单；有多少商家有完整的 90 天观察期 | 订单数据截止日定为 **2018-08-30**（处理假设，见下方说明）。算出成交商家在 order_items 中的匹配率（match_rate）；won_date 距截止日 ≥ 90 天的商家数，参考门槛 100 家 | 匹配率低：激活率改用“是否有任何订单”来定义。完整窗口的商家太少：窗口缩短到 60 天或 30 天。两种情况都写进 P1 的局限性 | closed_deals、order_items、orders | 1 |
| 11 | category_translation_coverage | P2：商品品类能不能翻译成英文 | 品类在翻译表中的覆盖率接近 100% | 列出没覆盖到的品类，决定手动补充还是归入 unknown | products、product_category_name_translation | 2 |

---

## 2. 阶段 1 的具体指标（SQL 每行输出一个 metric）

这一节把上面的检查拆成 `01_quality_checklist.sql` 里实际要算的每一个 metric。结果表的列为：`check_name | table_name | metric | value | note`。

| check_name | table_name | metric | 通过标准 |
|---|---|---|---|
| rows_completion | mql_leads | row_count | = 8,000 |
| rows_completion | closed_deals | row_count | = 842 |
| rows_completion | orders | row_count | = 99,441 |
| rows_completion | order_items | row_count | = 112,650 |
| rows_completion | sellers | row_count | = 3,095 |
| data_type | 5 张表 | 每列一行：column_name 和 data_type（查 INFORMATION_SCHEMA.COLUMNS） | 符合第 1 节 #2 的标准 |
| data_type | 日期是 STRING 的列 | `<列名>_cast_fail` = SAFE_CAST 后变空、但原值不为空的行数 | = 0 |
| distinct_primary_key | orders | dup_order_id = 行数 − 不重复的 order_id 数 | = 0 |
| distinct_primary_key | sellers | dup_seller_id | = 0 |
| distinct_primary_key | mql_leads | dup_mql_id | = 0 |
| distinct_primary_key | closed_deals | dup_mql_id | = 0 |
| distinct_primary_key | order_items | dup_order_item_key（order_id + order_item_id） | = 0（作为一对多粒度的确认） |
| null_check | 5 张表 | 每列一行：`null_<列名>` 的空值数 | 按第 3 节逐列判断 |
| date_logic | orders | delivered_before_purchase（送达时间早于下单时间） | = 0 或极少 |
| date_logic | orders | min_purchase_ts / max_purchase_ts | 在数据说明的范围内（约 2016-09 到 2018-10） |
| date_logic | closed_deals | won_before_first_contact（关联 mql_leads 后，won_date 早于 first_contact_date） | = 0 或极少 |
| date_logic | mql_leads | min / max first_contact_date | 约 2017-06 到 2018-05 |
| date_logic | closed_deals | min / max won_date | 不早于 mql 的起始日期 |
| value_range | order_items | price_le_0 | = 0 |
| value_range | order_items | freight_lt_0 | = 0 |
| value_range | order_items | price_p99 / price_max | 用来看极端值，note 里写判断 |
| category_values | orders | 每个 order_status 一行：订单数 | 只出现已知取值 |
| category_values | orders | 中间状态订单的最早下单时间 | 不应该很早；note 写出数量 |
| duplicate_rows | 5 张表 | full_row_dups（`TO_JSON_STRING(t)` 去重后的差额） | = 0 |
| referential_integrity | order_items → orders | orphan_order_items（在 orders 中找不到的订单） | = 0 |
| referential_integrity | order_items → sellers | orphan_seller_ids（在 sellers 中找不到的 seller_id） | = 0 |
| referential_integrity | closed_deals → mql_leads | orphan_closed_deals（在 mql_leads 中找不到的 mql_id） | = 0 |
| observation_window | closed_deals → order_items | match_rate = 有订单的成交商家数 / 成交商家数 | 记录数值；低的话按 #10 的处理方式 |
| observation_window | closed_deals | sellers_with_90d_window（won_date ≤ 2018-08-30 − 90 天 = 2018-06-01） | ≥ 100 |
| observation_window | orders | orders_after_cutoff（下单日期晚于 2018-08-30 的订单数） | 记录，作为截止日的依据 |

---

## 3. null_check 逐列说明

SQL 只算空值数量。空值代表什么、能不能接受，要结合业务判断。下表先写跑之前的假设，跑完后再填实际空值数和决定。

| 表 | 字段 | 空值可能代表什么（跑之前的假设） | 实际空值数 | 对分析的影响 | 决定（接受 / 剔除 / 调查） |
|---|---|---|---|---|---|
| mql_leads | origin | 渠道来源没有记录 | | P1 按渠道分组的核心字段 | 填 unknown 并单独列出，不删除 |
| closed_deals | business_segment、lead_type、business_type | 销售没有填写 | | 影响 P1 分析 4 的拆分 | 跑完再决定 |
| orders | order_id、customer_id | 主键不应该为空 | | 有空值说明导入或数据本身有问题 | 有空值必须调查 |
| orders | order_approved_at | 订单没通过付款审核，例如被取消 | | 一般不影响，分析只用 delivered | 跑完再决定 |
| orders | order_delivered_customer_date | 订单还没送达或被取消，不一定是错误 | | 影响 P2 的延迟分析 | 状态是 delivered 但这一列为空：保留在复购计算中，从延迟分析中排除 |
| products | product_category_name | 卖家没有填品类 | | 影响 P2 按品类分层 | 跑完再决定（阶段 2） |
| order_reviews | review_comment_message | 客户只打分没写评论，属于正常情况 | | 不影响，本项目不用评论文本 | 接受（阶段 2） |

---

## 4. 补充说明（2026-10-13 定稿时确认）

1. **订单数据截止日 = 2018-08-30。** 这是为了让数据更合理而做的处理假设，不是数据本身的事实。依据：2018-08-29 之后每天只有个位数订单，2018-08-30 之后一共只有 25 笔，最后一笔在 2018-10-17。如果直接用 MAX(下单时间) 当截止日，会高估有完整 90 天观察期的商家数。另外，从 2018-08-22 起每日订单量就开始下滑（187 → 14），可能是数据导出时最后一周还没收全。这一点只做记录，不影响截止日的选择。
2. **geolocation 已从 raw 删除。** 三个项目都不用这张表，删除后 raw 是 10 张表。
3. **阶段 2 的预期 Fail。** order_reviews.review_id 在 Olist 数据里已知有几百条重复（同一条评价挂在多个订单上），distinct_primary_key 这一项预计会 Fail。T2 已经计划每单只取最新一条评价，所以不影响分析。
4. **阶段 2 的精确行数。** customers 99,441；order_payments 103,886；order_reviews 99,224；products 32,951；product_category_name_translation 71。
