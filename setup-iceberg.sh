#!/bin/bash

set -e

echo "=========================================="
echo "Настройка Iceberg для Kylin 5"
echo "=========================================="

# 1. Создаём bucket в MinIO
echo "[1/6] Создаём bucket в MinIO..."
docker exec minio mc alias set local http://localhost:9000 admin password123 2>/dev/null || true
docker exec minio mc mb local/warehouse --ignore-existing 2>/dev/null || true
echo "      Bucket создан"

# 2. Настраиваем core-site.xml с S3 credentials
echo "[2/6] Настраиваем core-site.xml..."
docker exec kylin5 bash -c '
cat > /opt/hadoop-3.2.4/etc/hadoop/core-site.xml << "EOF"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/data/hadoop</value>
    </property>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>root</value>
    </property>
    <property>
        <name>fs.s3a.endpoint</name>
        <value>http://minio:9000</value>
    </property>
    <property>
        <name>fs.s3a.access.key</name>
        <value>admin</value>
    </property>
    <property>
        <name>fs.s3a.secret.key</name>
        <value>password123</value>
    </property>
    <property>
        <name>fs.s3a.path.style.access</name>
        <value>true</value>
    </property>
    <property>
        <name>fs.s3a.impl</name>
        <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>
    </property>
    <property>
        <name>fs.s3a.connection.ssl.enabled</name>
        <value>false</value>
    </property>
</configuration>
EOF
'
echo "      core-site.xml настроен"

# 3. Скачиваем Iceberg Runtime
echo "[3/6] Скачиваем Iceberg Runtime 1.7.1..."
docker exec kylin5 bash -c '
  if [ ! -f /opt/apache-hive-3.1.3-bin/lib/iceberg-hive-runtime-1.7.1.jar ]; then
    wget -q -O /opt/apache-hive-3.1.3-bin/lib/iceberg-hive-runtime-1.7.1.jar \
      "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-hive-runtime/1.7.1/iceberg-hive-runtime-1.7.1.jar"
    echo "      Iceberg Runtime скачан"
  else
    echo "      Iceberg Runtime уже существует"
  fi
'

# 4. Копируем JAR-файлы
echo "[4/6] Копируем JAR-файлы..."
docker exec kylin5 bash -c '
  cp -n /opt/apache-hive-3.1.3-bin/lib/iceberg-hive-runtime-1.7.1.jar \
     /home/kylin/apache-kylin-5.0.2-bin/spark/jars/ 2>/dev/null || true
  
  cp -n /opt/apache-hive-3.1.3-bin/lib/iceberg-hive-runtime-1.7.1.jar \
     /home/kylin/apache-kylin-5.0.2-bin/spark/hive_1_2_2/ 2>/dev/null || true
  
  cp -n /home/kylin/apache-kylin-5.0.2-bin/spark/jars/aws-java-sdk-bundle-1.11.271.jar \
     /opt/hadoop-3.2.4/share/hadoop/common/lib/ 2>/dev/null || true
  
  cp -n /home/kylin/apache-kylin-5.0.2-bin/spark/jars/hadoop-aws-2.10.1.jar \
     /opt/hadoop-3.2.4/share/hadoop/common/lib/ 2>/dev/null || true
  
  cp -n /home/kylin/apache-kylin-5.0.2-bin/spark/jars/aws-java-sdk-bundle-1.11.271.jar \
     /home/kylin/apache-kylin-5.0.2-bin/spark/hive_1_2_2/ 2>/dev/null || true
  
  cp -n /home/kylin/apache-kylin-5.0.2-bin/spark/jars/hadoop-aws-2.10.1.jar \
     /home/kylin/apache-kylin-5.0.2-bin/spark/hive_1_2_2/ 2>/dev/null || true
'
echo "      JAR-файлы скопированы"

# 5. Добавляем конфигурацию Iceberg в kylin.properties
echo "[5/6] Настраиваем kylin.properties..."
docker exec kylin5 bash -c '
  if ! grep -q "ICEBERG + S3 CONFIGURATION" /home/kylin/apache-kylin-5.0.2-bin/conf/kylin.properties; then
    cat >> /home/kylin/apache-kylin-5.0.2-bin/conf/kylin.properties << "EOF"

# ========== ICEBERG + S3 CONFIGURATION ==========
kylin.engine.spark-conf.spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
kylin.engine.spark-conf.spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkSessionCatalog
kylin.engine.spark-conf.spark.sql.catalog.spark_catalog.type=hive
kylin.engine.spark-conf.spark.hadoop.fs.s3a.endpoint=http://minio:9000
kylin.engine.spark-conf.spark.hadoop.fs.s3a.access.key=admin
kylin.engine.spark-conf.spark.hadoop.fs.s3a.secret.key=password123
kylin.engine.spark-conf.spark.hadoop.fs.s3a.path.style.access=true
kylin.engine.spark-conf.spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
kylin.storage.columnar.spark-conf.spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
kylin.storage.columnar.spark-conf.spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkSessionCatalog
kylin.storage.columnar.spark-conf.spark.sql.catalog.spark_catalog.type=hive
kylin.storage.columnar.spark-conf.spark.hadoop.fs.s3a.endpoint=http://minio:9000
kylin.storage.columnar.spark-conf.spark.hadoop.fs.s3a.access.key=admin
kylin.storage.columnar.spark-conf.spark.hadoop.fs.s3a.secret.key=password123
kylin.storage.columnar.spark-conf.spark.hadoop.fs.s3a.path.style.access=true
kylin.storage.columnar.spark-conf.spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
EOF
    echo "      Конфигурация добавлена"
  else
    echo "      Конфигурация уже существует"
  fi
'

# 6. Перезапускаем Hive Metastore
echo "[6/6] Перезапускаем Hive Metastore..."
docker exec kylin5 bash -c 'pkill -f HiveMetaStore 2>/dev/null || true'
sleep 2
docker exec kylin5 /opt/apache-hive-3.1.3-bin/bin/start-hivemetastore.sh

echo "      Ожидаем запуска Metastore..."
for i in {1..30}; do
    if docker exec kylin5 ps aux | grep -v grep | grep -q HiveMetaStore; then
        echo "      ✅ Hive Metastore запущен"
        break
    fi
    sleep 1
done

echo ""
echo "=========================================="
echo "✅ Настройка Iceberg завершена!"
echo "=========================================="
