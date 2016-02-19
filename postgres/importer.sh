#!/bin/sh
# Bash script for importing geodata from geonames.org to database


DB_HOST="localhost"
DB_NAME="geonames"
DB_PORT=5432

DB_SCHEMA="geonames"

BASE_URL="http://download.geonames.org/export/dump"

admin_sql() {
    psql --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME --command="$1"
}

db_sql() {
    psql --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME --dbname=$DB_NAME --command="$1"
}

db_sql_script() {
    psql --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME --dbname=$DB_NAME --file=$1
}

init() {
    export PGPASSWORD="${DB_PASSWORD}"
}

drop() {
    printf >&2 "Dropping database '$DB_NAME'...\n"
    admin_sql "DROP DATABASE IF EXISTS $DB_NAME;"
    printf >&2 "done\n"
}

create() {
    printf >&2 "Creating database '$DB_NAME'...\n"
    admin_sql "CREATE DATABASE $DB_NAME;"
    printf >&2 "done\n"
}

drop_schema() {
    printf >&2 "Dropping schema '$DB_SCHEMA'...\n"
    db_sql "DROP SCHEMA IF EXISTS $DB_SCHEMA;"
    printf >&2 "done\n"
}

create_schema() {
    printf >&2 "Creating schema '$DB_SCHEMA'...\n"
    db_sql "CREATE SCHEMA $DB_SCHEMA;"
    printf >&2 "done\n"
}

migrate() {
    printf >&2 "Creating structure of database '$DB_NAME'...\n"
    db_sql_script "schema.sql"
    printf >&2 "done\n"
}

seed() {
    FILES_TO_DOWNLOAD="admin1CodesASCII.txt admin2Codes.txt allCountries.zip alternateNames.zip countryInfo.txt featureCodes_en.txt hierarchy.zip timeZones.txt"
    FILES_TO_UNZIP="allCountries.zip alternateNames.zip hierarchy.zip"

    cd .. && mkdir -p downloads && cd downloads

    cp -v ../data/continentCodes.txt ./

    for FILE in $FILES_TO_DOWNLOAD; do
        wget "$BASE_URL/$FILE"
    done
    for FILE in $FILES_TO_UNZIP; do
        unzip "$FILE"
    done

    sed -i -e 1,51d countryInfo.txt

    DIR="$( pwd )"

    printf >&2 "Importing geonames into database '$DB_NAME'...\n"
    db_sql "COPY $DB_SCHEMA.names              FROM '$DIR/allCountries.txt'        ( FORMAT CSV, DELIMITER E'\t', QUOTE E'\b')"
    db_sql "COPY $DB_SCHEMA.alternate_names    FROM '$DIR/alternateNames.txt'      ( FORMAT CSV, DELIMITER E'\t' )"
    db_sql "COPY $DB_SCHEMA.iso_language_codes FROM '$DIR/iso-languagecodes.txt'   ( FORMAT CSV, DELIMITER E'\t', HEADER ON )"
    db_sql "COPY $DB_SCHEMA.admin1_ascii_codes FROM '$DIR/admin1CodesASCII.txt'    ( FORMAT CSV, DELIMITER E'\t' )"
    db_sql "COPY $DB_SCHEMA.admin2_codes       FROM '$DIR/admin2Codes.txt'         ( FORMAT CSV, DELIMITER E'\t' )"
    db_sql "COPY $DB_SCHEMA.feature_codes      FROM '$DIR/featureCodes_en.txt'     ( FORMAT CSV, DELIMITER E'\t' )"
    db_sql "COPY $DB_SCHEMA.timezones          FROM '$DIR/timeZones.txt'           ( FORMAT CSV, DELIMITER E'\t', HEADER ON )"
    db_sql "COPY $DB_SCHEMA.country_info       FROM '$DIR/countryInfo.txt'         ( FORMAT CSV, DELIMITER E'\t' )"
    db_sql "COPY $DB_SCHEMA.continent_codes    FROM '$DIR/continentCodes.txt'      ( FORMAT CSV, DELIMITER E'\t' )"
    db_sql "COPY $DB_SCHEMA.hierarchy          FROM '$DIR/hierarchy.txt'           ( FORMAT CSV, DELIMITER E'\t' )"
    printf >&2 "done\n"

    cd `dirname "$0"`
}

update() {
    YESTERDAY=`date --date='1 day ago' +%F`
    FILES_TO_DOWNLOAD="modifications-$YESTERDAY.txt deletes-$YESTERDAY.txt alternateNamesModifications-$YESTERDAY.txt alternateNamesDeletes-$YESTERDAY.txt"

    cd .. && mkdir -p downloads && cd downloads

    for FILE in $FILES_TO_DOWNLOAD; do
        wget "$BASE_URL/$FILE"
    done

    DIR="$( pwd )"

    printf >&2 "Deleting old names...\n"
    cat "deletes-$YESTERDAY.txt" | cut -f1 | while read ID; do
        db_sql "DELETE FROM $DB_SCHEMA.names WHERE name_id = $ID"
    done
    printf >&2 "done\n"

    printf >&2 "Applying changes to names...\n"
    cat "modifications-$YESTERDAY.txt" | cut -f1 | while read ID; do
        db_sql "DELETE FROM $DB_SCHEMA.names WHERE name_id = $ID"
    done

    db_sql "COPY $DB_SCHEMA.names FROM '$DIR/modifications-$YESTERDAY.txt' ( FORMAT CSV, DELIMITER E'\t', QUOTE E'\b')"
    printf >&2 "done\n"

    printf >&2 "Deleting old alternate names...\n"
    cat "alternateNamesDeletes-$YESTERDAY.txt" | cut -f1 | while read ID; do
        db_sql "DELETE FROM $DB_SCHEMA.alternate_names WHERE alternate_name_id = $ID"
    done
    printf >&2 "done\n"

    printf >&2 "Applying changes to alternate names...\n"
    cat "alternateNamesModifications-$YESTERDAY.txt" | cut -f1 | while read ID; do
        db_sql "DELETE FROM $DB_SCHEMA.alternate_names WHERE alternate_name_id = $ID"
    done

    db_sql "COPY $DB_SCHEMA.alternate_names FROM '$DIR/alternateNamesModifications-$YESTERDAY.txt' ( FORMAT CSV, DELIMITER E'\t' )"
    printf >&2 "done\n"

    cd `dirname "$0"`
}

cd `dirname "$0"`

# Main procedure
. ../data/proc.sh
