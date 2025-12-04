#!/bin/bash

echo "[1/2] Проверяем Hive Metastore..."
docker exec kylin5 bash -c '
  if ! ps aux | grep -v grep | grep -q HiveMetaStore; then
    echo "      Запускаем Hive Metastore..."
    /opt/apache-hive-3.1.3-bin/bin/start-hivemetastore.sh
    sleep 15
  else
    echo "      Hive Metastore уже запущен"
  fi
'

echo "[2/2] Создаём Iceberg таблицу из Avro файлов..."
docker exec kylin5 bash -c '
/home/kylin/apache-kylin-5.0.2-bin/spark/bin/spark-sql \
  --packages org.apache.spark:spark-avro_2.12:3.3.0 \
  --conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkSessionCatalog \
  --conf spark.sql.catalog.spark_catalog.type=hive \
  --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
  --conf spark.hadoop.fs.s3a.endpoint=http://minio:9000 \
  --conf spark.hadoop.fs.s3a.access.key=admin \
  --conf spark.hadoop.fs.s3a.secret.key=password123 \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
  -e "
    CREATE DATABASE IF NOT EXISTS productivity_db;
    CREATE TABLE IF NOT EXISTS productivity_db.productivity
    USING iceberg
    LOCATION '\''s3a://warehouse/productivity_db/productivity'\''
    AS SELECT * FROM avro.\`s3a://warehouse/productivity_avro/\`;
    SELECT COUNT(*) AS total_records FROM productivity_db.productivity;
    SELECT * FROM productivity_db.productivity LIMIT 5;
  "
'

echo "Перезапускаем Kylin, чтобы подхватить новую базу..."

docker exec kylin5 bash -c '
/home/kylin/apache-kylin-5.0.2-bin/bin/kylin.sh restart
'

