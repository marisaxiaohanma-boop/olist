#!/usr/bin/env bash
# S1 Setup：把两个 Olist Kaggle 数据集导入 olist001.raw，可重复运行（--replace 会覆盖旧表）。
# 注意：这个脚本是根据计划里 S1 的描述重新写的，不是当初实际运行的那一份。
# 如果你手上还有原始脚本，请用原始脚本替换这个文件。
# 用法：bash scripts/00_setup_and_load.sh [数据目录，默认 data]
set -euo pipefail

PROJECT=olist001
DATASET=raw
DATA_DIR="${1:-data}"

mkdir -p "$DATA_DIR"
kaggle datasets download -d olistbr/brazilian-ecommerce -p "$DATA_DIR" --unzip
kaggle datasets download -d olistbr/marketing-funnel-olist -p "$DATA_DIR" --unzip

for f in "$DATA_DIR"/*.csv; do
  name=$(basename "$f" .csv)
  name=${name#olist_}
  name=${name%_dataset}
  [[ $name == geolocation ]] && continue
  [[ $name == marketing_qualified_leads ]] && name=mql_leads

  echo "Loading $f -> $PROJECT:$DATASET.$name"
  bq load --project_id="$PROJECT" --replace --autodetect \
    --source_format=CSV --skip_leading_rows=1 --allow_quoted_newlines \
    "$DATASET.$name" "$f"
done
