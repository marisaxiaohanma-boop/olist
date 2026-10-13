#!/usr/bin/env bash
# Setup: load both Olist Kaggle datasets into olist001.raw. Safe to re-run (--replace overwrites tables).
# Written from the setup spec after the original load; the original load was not recorded.
# Usage: bash data_prep/1_setup/00_setup_and_load.sh [data_dir, default: data]
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
