#!/bin/sh
set -e

INTERVAL="${DBT_RUN_INTERVAL:-60}"

echo "[dbt-loop] старт, интервал ${INTERVAL}s"

while true; do
    echo "[dbt-loop] $(date -u +%FT%TZ) launching dbt run"
    if dbt run; then
        echo "[dbt-loop] dbt run OK"
    else
        echo "[dbt-loop] dbt run FAILED (continue the loop)"
    fi
    echo "[dbt-loop] сплю ${INTERVAL}s"
    sleep "$INTERVAL"
done