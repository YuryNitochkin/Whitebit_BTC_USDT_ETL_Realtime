import json
import os
import signal
from confluent_kafka import Consumer, KafkaError
import clickhouse_connect
from clickhouse_connect.driver.client import Client


KAFKA_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9094")
TOPIC = "raw-data"

running = True

def get_clickhouse_client() -> Client:
    """Создаёт клиент ClickHouse из переменных окружения."""
    return clickhouse_connect.get_client(
        host=os.getenv("CLICKHOUSE_HOST", "localhost"),
        port=int(os.getenv("CLICKHOUSE_PORT", "8123")),
        username=os.getenv("CLICKHOUSE_USER", "default"),
        password=os.getenv("CLICKHOUSE_PASSWORD", ""),
        database=os.getenv("CLICKHOUSE_DATABASE", "analytics"),
    )

def init_db() -> Client:
    """Создаёт таблицу (если нет) и возвращает клиент."""
    client = get_clickhouse_client()
    
    client.command("""
        CREATE TABLE IF NOT EXISTS analytics.raw_trades
        (
            payload String,
            ingested_at DateTime DEFAULT now()
        )
        ENGINE = MergeTree()
        ORDER BY ingested_at
        SETTINGS index_granularity = 8192;
    """)
    
    return client


def shutdown(signum, frame):
    global running
    print("Получен сигнал завершения, останавливаемся...")
    running = False


signal.signal(signal.SIGINT, shutdown)
signal.signal(signal.SIGTERM, shutdown)


def main():
    print(f"Подключаемся к Kafka: {KAFKA_SERVERS}")
    consumer = Consumer({
        "bootstrap.servers": KAFKA_SERVERS,
        "group.id": "duckdb-consumer",
        "auto.offset.reset": "earliest",
        "enable.auto.commit": True,
    })
    consumer.subscribe([TOPIC])

    chclient = init_db()

    print("Начинаем читать сообщения...")
    while running:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                continue
            print(f"Ошибка Kafka: {msg.error()}")
            continue

        try:
            raw = msg.value().decode("utf-8")
            data = json.loads(raw)

            # Пишем только trades_update, остальное игнорируем
            if data.get("method") != "trades_update":
                continue

            chclient.insert(
                            "analytics.raw_trades",
                            [[raw]],  # данные передаются как список строк (каждая строка — список значений)
                            column_names=["payload"]
                        )
            print("Записано 1 сообщение в raw_trades")
        except Exception as e:
            print(f"Ошибка обработки сообщения: {e}")

    print("Закрываем соединения...")
    consumer.close()
    chclient.close()
    print("Готово.")


if __name__ == "__main__":
    main()