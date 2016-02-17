#!/bin/sh
# Bash script for importing geodata from geonames.org to database


DB_HOST="localhost"
DB_NAME="geonames"
DB_PORT=3306

BASE_URL="http://download.geonames.org/export/dump"

admin_sql() {
    mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD -Bse "$1"
}

db_sql() {
    mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD --database=$DB_NAME --local-infile=1 -Bse "$1"
}

db_sql_script() {
    mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD --database=$DB_NAME < $1
}

init() {
    :
}

drop() {
    printf >&2 "Dropping database '$DB_NAME'... "
    admin_sql "DROP DATABASE IF EXISTS $DB_NAME;"
    printf >&2 "done\n"
}

create() {
    printf >&2 "Creating database '$DB_NAME'... "
    admin_sql "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8;"
    printf >&2 "done\n"
}

migrate() {
    printf >&2 "Creating structure of database '$DB_NAME'... "
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

    printf >&2 "Importing geonames into database '$DB_NAME'... "
    db_sql "LOAD DATA LOCAL INFILE 'allCountries.txt'       INTO TABLE names                CHARACTER SET 'utf8'"
    db_sql "LOAD DATA LOCAL INFILE 'alternateNames.txt'     INTO TABLE alternate_names      CHARACTER SET 'utf8'"
    db_sql "LOAD DATA LOCAL INFILE 'iso-languagecodes.txt'  INTO TABLE iso_language_codes   CHARACTER SET 'utf8' IGNORE 1 LINES"
    db_sql "LOAD DATA LOCAL INFILE 'admin1CodesASCII.txt'   INTO TABLE admin1_ascii_codes   CHARACTER SET 'utf8'"
    db_sql "LOAD DATA LOCAL INFILE 'admin2Codes.txt'        INTO TABLE admin2_codes         CHARACTER SET 'utf8'"
    db_sql "LOAD DATA LOCAL INFILE 'featureCodes_en.txt'    INTO TABLE feature_codes        CHARACTER SET 'utf8'"
    db_sql "LOAD DATA LOCAL INFILE 'timeZones.txt'          INTO TABLE timezones            CHARACTER SET 'utf8' IGNORE 1 LINES"
    db_sql "LOAD DATA LOCAL INFILE 'countryInfo.txt'        INTO TABLE country_info         CHARACTER SET 'utf8' IGNORE 51 LINES"
    db_sql "LOAD DATA LOCAL INFILE 'continentCodes.txt'     INTO TABLE continent_codes      CHARACTER SET 'utf8'"
    db_sql "LOAD DATA LOCAL INFILE 'hierarchy.txt'          INTO TABLE hierarchy            CHARACTER SET 'utf8'"
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

    printf >&2 "Deleting old names... "
    cat "deletes-$YESTERDAY.txt" | cut -f1 | while read ID; do
        db_sql "DELETE FROM names WHERE name_id = $ID"
    done
    printf >&2 "done\n"

    printf >&2 "Applying changes to names... "
    cat "modifications-$YESTERDAY.txt" | cut -f1 | while read ID; do
        db_sql "DELETE FROM names WHERE name_id = $ID"
    done

    db_sql "LOAD DATA LOCAL INFILE 'modifications-$YESTERDAY.txt' INTO TABLE names CHARACTER SET 'utf8'"
    printf >&2 "done\n"

    printf >&2 "Deleting old alternate names... "
    cat "alternateNamesDeletes-$YESTERDAY.txt" | cut -f1 | while read ID; do
        db_sql "DELETE FROM alternate_names WHERE alternate_name_id = $ID"
    done
    printf >&2 "done\n"

    printf >&2 "Applying changes to alternate names... "
    cat "alternateNamesModifications-$YESTERDAY.txt" | cut -f1 | while read ID; do
        db_sql "DELETE FROM alternate_names WHERE alternate_name_id = $ID"
    done

    db_sql "LOAD DATA LOCAL INFILE 'alternateNamesModifications-$YESTERDAY.txt' INTO TABLE alternate_names CHARACTER SET 'utf8'"
    printf >&2 "done\n"

    cd `dirname "$0"`
}

# Main procedure
. ../data/proc.sh
