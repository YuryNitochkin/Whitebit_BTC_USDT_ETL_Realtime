{{ config(
    materialized='incremental',
    engine='ReplacingMergeTree()',
    order_by='(trade_id, side)'
) }}

SELECT
    JSONExtractUInt(trade, 'id')            AS trade_id,
    toDecimal64(JSONExtractString(trade, 'price'), 8)  AS price,
    toDecimal64(JSONExtractString(trade, 'amount'), 8) AS amount,
    JSONExtractString(trade, 'type')         AS side,
    toDateTime64(JSONExtractFloat(trade, 'time'), 6)   AS trade_time,
    now64(6)                                 AS ingested_at
FROM raw_trades
ARRAY JOIN JSONExtractArrayRaw(payload, 'params', 2) AS trade