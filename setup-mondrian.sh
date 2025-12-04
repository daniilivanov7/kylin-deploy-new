#!/bin/bash

set -e

echo "[1/7] Создаём структуру директорий..."
mkdir -p /mondrian-kylin
cd /mondrian-kylin
mkdir -p lib schema conf

echo "[2/7] Скачиваем xmondrian.war..."
wget -q -O xmondrian.war "https://github.com/rpbouman/xmondrian/raw/master/dist/xmondrian.war"

echo "[3/7] Распаковываем WAR..."
mkdir -p xmondrian
cd xmondrian
jar -xf ../xmondrian.war
cd /mondrian-kylin

echo "[4/7] Скачиваем Kylin JDBC драйвер..."
wget -q -O ./lib/kylin-jdbc.jar \
  "https://repo1.maven.org/maven2/org/apache/kylin/kylin-jdbc/5.0.0/kylin-jdbc-5.0.0.jar"
cp ./lib/kylin-jdbc.jar ./xmondrian/WEB-INF/lib/

echo "[5/7] Скачиваем JAXB зависимости..."
wget -q -O ./lib/jaxb-api.jar "https://repo1.maven.org/maven2/javax/xml/bind/jaxb-api/2.3.1/jaxb-api-2.3.1.jar"
wget -q -O ./lib/jaxb-impl.jar "https://repo1.maven.org/maven2/com/sun/xml/bind/jaxb-impl/2.3.1/jaxb-impl-2.3.1.jar"
wget -q -O ./lib/jaxb-core.jar "https://repo1.maven.org/maven2/com/sun/xml/bind/jaxb-core/2.3.0.1/jaxb-core-2.3.0.1.jar"
wget -q -O ./lib/activation.jar "https://repo1.maven.org/maven2/javax/activation/activation/1.1.1/activation-1.1.1.jar"
cp ./lib/jaxb-*.jar ./lib/activation.jar ./xmondrian/WEB-INF/lib/

echo "[6/7] Создаём конфигурацию datasources.xml..."
mkdir -p ./xmondrian/WEB-INF/schema

cat > ./xmondrian/WEB-INF/datasources.xml << 'EOF'
<?xml version="1.0"?>
<DataSources>
  <DataSource>
    <DataSourceName>Kylin_Productivity</DataSourceName>
    <DataSourceDescription>Productivity Dataset on Apache Kylin 5</DataSourceDescription>
    <URL>http://localhost:8080/xmondrian/xmla</URL>
    <DataSourceInfo>Provider=mondrian;Jdbc=jdbc:kylin://host.docker.internal:7070/learn_kylin;JdbcDrivers=org.apache.kylin.jdbc.Driver;JdbcUser=ADMIN;JdbcPassword=KYLIN</DataSourceInfo>
    <ProviderName>Mondrian</ProviderName>
    <ProviderType>MDP</ProviderType>
    <AuthenticationMode>Unauthenticated</AuthenticationMode>
    <Catalogs>
      <Catalog name="KylinProductivity">
        <Definition>/WEB-INF/schema/schema.xml</Definition>
      </Catalog>
    </Catalogs>
  </DataSource>
</DataSources>
EOF

echo "[7/7] Создаём Mondrian Schema..."
cat > ./xmondrian/WEB-INF/schema/schema.xml << 'EOF'
<?xml version="1.0"?>
<Schema name="PRODUCTIVITY_KYLIN">

  <Cube name="Productivity" defaultMeasure="Sum Amount">

    <!-- FACT TABLE -->
    <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>

    <!-- ===================== DIMENSIONS ===================== -->

    <!-- TIME DIMENSION (CALC_DATE) -->
    <Dimension name="Calc Date" foreignKey="CALC_DATE">
      <Hierarchy hasAll="true" primaryKey="CALC_DATE">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Calc Date" column="CALC_DATE" type="String" uniqueMembers="false"/>
      </Hierarchy>
    </Dimension>

    <!-- WAREHOUSE DIMENSION -->
    <Dimension name="Warehouse" foreignKey="WH_ID">
      <Hierarchy hasAll="true" primaryKey="WH_ID">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Warehouse ID" column="WH_ID" type="Numeric" uniqueMembers="true"/>
      </Hierarchy>
    </Dimension>

    <!-- OFFICE DIMENSION -->
    <Dimension name="Office" foreignKey="OFFICE_ID">
      <Hierarchy hasAll="true" primaryKey="OFFICE_ID">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Office ID" column="OFFICE_ID" type="Numeric" uniqueMembers="true"/>
        <Level name="Office Country" column="OFFICE_COUNTRY_CODE" type="String" uniqueMembers="false"/>
      </Hierarchy>
    </Dimension>

    <!-- EMPLOYEE DIMENSION -->
    <Dimension name="Employee" foreignKey="EMPLOYEE_ID">
      <Hierarchy hasAll="true" primaryKey="EMPLOYEE_ID">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Employee ID" column="EMPLOYEE_ID" type="Numeric" uniqueMembers="true"/>
      </Hierarchy>
    </Dimension>

    <!-- PRODUCT TYPE -->
    <Dimension name="Product Type" foreignKey="PRODTYPE_ID">
      <Hierarchy hasAll="true" primaryKey="PRODTYPE_ID">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Product Type ID" column="PRODTYPE_ID" type="Numeric" uniqueMembers="true"/>
        <Level name="Product Type Code" column="PRODTYPE_CODE" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- ENTRY DIMENSION -->
    <Dimension name="Entry" foreignKey="ENTRY">
      <Hierarchy hasAll="true" primaryKey="ENTRY">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Entry" column="ENTRY" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- WORLD ENTRY DIMENSION -->
    <Dimension name="World Entry" foreignKey="WORLD_ENTRY">
      <Hierarchy hasAll="true" primaryKey="WORLD_ENTRY">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="World Entry" column="WORLD_ENTRY" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- IS CREDIT -->
    <Dimension name="Is Credit" foreignKey="IS_CREDIT">
      <Hierarchy hasAll="true" primaryKey="IS_CREDIT">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Is Credit" column="IS_CREDIT" type="Boolean"/>
      </Hierarchy>
    </Dimension>

    <!-- CURRENCY -->
    <Dimension name="Currency" foreignKey="CURRENCY_ID">
      <Hierarchy hasAll="true" primaryKey="CURRENCY_ID">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Currency ID" column="CURRENCY_ID" type="Numeric"/>
      </Hierarchy>
    </Dimension>

    <!-- PAY PART -->
    <Dimension name="Pay Part" foreignKey="PAY_PART">
      <Hierarchy hasAll="true" primaryKey="PAY_PART">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Pay Part" column="PAY_PART" type="Numeric"/>
      </Hierarchy>
    </Dimension>

    <!-- RATE DATE -->
    <Dimension name="Rate Date" foreignKey="RATE_DT">
      <Hierarchy hasAll="true" primaryKey="RATE_DT">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Rate Date" column="RATE_DT" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- CREATE DATE -->
    <Dimension name="Create Date" foreignKey="CREATE_DT">
      <Hierarchy hasAll="true" primaryKey="CREATE_DT">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Create Date" column="CREATE_DT" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- OPERATION DATE -->
    <Dimension name="Operation Date" foreignKey="OPER_DT">
      <Hierarchy hasAll="true" primaryKey="OPER_DT">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="Operation Date" column="OPER_DT" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- WORLD REPORTED DATE -->
    <Dimension name="World Reported Date" foreignKey="WORLD_REPORTED_DT">
      <Hierarchy hasAll="true" primaryKey="WORLD_REPORTED_DT">
        <Table name="PRODUCTIVITY" schema="PRODUCTIVITY_DB"/>
        <Level name="World Reported Date" column="WORLD_REPORTED_DT" type="String"/>
      </Hierarchy>
    </Dimension>

    <!-- ========== MEASURES ========== -->

    <Measure name="Sum Amount"
             column="AMOUNT"
             aggregator="sum" formatString="#,###.00"/>

    <Measure name="Cnt WhId"
             column="WH_ID"
             aggregator="count" formatString="#,###.0000"/>

  </Cube>

</Schema>
EOF

echo "[8/8] Пересобираем WAR файл..."
cd /mondrian-kylin/xmondrian
jar -cvf ../xmondrian-kylin.war . > /dev/null
cd /mondrian-kylin

echo ""
echo "=========================================="
echo "Mondrian настроен!"
echo "=========================================="
echo ""
echo "Готовый WAR: /mondrian-kylin/xmondrian-kylin.war"
echo ""
echo "Следующий шаг: запустить Tomcat с этим WAR"
echo "  docker run -d --name mondrian \\"
echo "    --network kylin-network \\"
echo "    -p 8080:8080 \\"
echo "    -v /mondrian-kylin/xmondrian-kylin.war:/usr/local/tomcat/webapps/xmondrian.war \\"
echo "    tomcat:9-jdk11"
echo ""
echo "XMLA endpoint: http://localhost:8080/xmondrian/xmla"
