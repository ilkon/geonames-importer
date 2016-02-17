#!/bin/sh
# Bash script for importing geodata from geonames.org to database


DB_HOST="localhost"
DB_NAME="geonames"

BASE_URL="http://download.geonames.org/export/dump"

usage() {
    PN=`basename "$0"`
    echo >&2 "Usage: $PN [OPTIONS] <action>"
    echo >&2 " Where <action>:"
    echo >&2 "    drop              Drop geonames database"
    echo >&2 "    create            Create geonames database"
    echo >&2 "    migrate           Create structure of geonames database"
    echo >&2 "    seed              Import geonames data"
    echo >&2 "    reset             Reset geonames database and import data"
    echo >&2 "    update            Update database (usually should run daily by cron)"
    echo >&2 " Options:"
    echo >&2 "    -t <db type>      mysql | postgres"
    echo >&2 "    -h <host>         Database server address (default: $DB_HOST)"
    echo >&2 "    -r <port>         Database server port (default: $DB_PORT)"
    echo >&2 "    -n <database>     Database name (default: $DB_NAME)"
    echo >&2 "    -u <user>         Username to access database"
    echo >&2 "    -p <password>     User password to access database"
    echo >&2 ""
}

admin_sql() {
    if [ "$DB_TYPE" = "mysql" ]; then
        mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD -Bse "$1"
    elif [ "$DB_TYPE" = "postgres" ]; then
        psql --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME -W --command="$1"
    fi
}

db_sql() {
    if [ "$DB_TYPE" = "mysql" ]; then
        mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD --database=$DB_NAME --local-infile=1 -Bse "$1"
    elif [ "$DB_TYPE" = "postgres" ]; then
        psql --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME --dbname=$DB_NAME -W --command="$1"
    fi
}

db_sql_script() {
    if [ "$DB_TYPE" = "mysql" ]; then
        mysql --host=$DB_HOST --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD --database=$DB_NAME --local-infile=1 < $1
    elif [ "$DB_TYPE" = "postgres" ]; then
        psql --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME --dbname=$DB_NAME -W --file=$1
    fi
}

drop() {
    printf >&2 "Dropping database '$DB_NAME'... "
    admin_sql "DROP DATABASE IF EXISTS $DB_NAME;"
    printf >&2 "done\n"
}

create() {
    printf >&2 "Creating database '$DB_NAME'... "
    if [ "$DB_TYPE" = "mysql" ]; then
        admin_sql "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8;"
    elif [ "$DB_TYPE" = "postgres" ]; then
        admin_sql "CREATE DATABASE $DB_NAME;"
    fi
    printf >&2 "done\n"
}

migrate() {
    printf >&2 "Creating structure of database '$DB_NAME'... "
    db_sql_script "$DB_TYPE/schema.sql"
    printf >&2 "done\n"
}

seed() {
    FILES_TO_DOWNLOAD="admin1CodesASCII.txt admin2Codes.txt allCountries.zip alternateNames.zip countryInfo.txt featureCodes_en.txt hierarchy.zip timeZones.txt"
    FILES_TO_UNZIP="allCountries.zip alternateNames.zip hierarchy.zip"

    mkdir -p downloads && cd downloads

    cp -v ../data/continentCodes.txt ./

    for FILE in $FILES_TO_DOWNLOAD; do
        wget "$BASE_URL/$FILE"
    done
    for FILE in $FILES_TO_UNZIP; do
        unzip "$FILE"
    done

    printf >&2 "Importing geonames into database '$DB_NAME'... "
    db_sql_script "../$DB_TYPE/seed.sql"
    printf >&2 "done\n"

    cd ..
}

update() {
    echo >&2 "Updating database $DB_NAME..."

    YESTERDAY=`date --date='1 day ago' +%F`

    FILES_TO_DOWNLOAD="modifications-$YESTERDAY.txt deletes-$YESTERDAY.txt alternateNamesModifications-$YESTERDAY.txt alternateNamesDeletes-$YESTERDAY.txt"

    mkdir -p downloads && cd downloads

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

    cd ..
}

# Main procedure
cd "$( dirname "$0" )"

while getopts "t:h:r:n:u:p:" opt; do
    case $opt in
        t) DB_TYPE=$OPTARG ;;
        h) DB_HOST=$OPTARG ;;
        r) DB_PORT=$OPTARG ;;
        n) DB_NAME=$OPTARG ;;
        u) DB_USERNAME=$OPTARG ;;
        p) DB_PASSWORD=$OPTARG ;;
        \?)
            usage
            exit 3
            ;;
    esac
done

if [ "$DB_TYPE" = "mysql" ]; then
    if [ -z $DB_PORT ] ; then
        DB_PORT=3306
    fi
elif [ "$DB_TYPE" = "postgres" ]; then
    if [ -z $DB_PORT ] ; then
        DB_PORT=5432
    fi
else
    usage
    exit 3
fi

shift `expr $OPTIND - 1`

if [ $# -eq 1 ]; then
    case $1 in
        drop)
            drop
            exit 0
            ;;
        create)
            create
            exit 0
            ;;
        migrate)
            migrate
            exit 0
            ;;
        seed)
            seed
            exit 0
            ;;
        reset)
            drop
            create
            migrate
            seed
            exit 0
            ;;
        update)
            update
            exit 0
            ;;
        *)
            usage
    		exit 3
            ;;
    esac
else
    usage
    exit 3
fi
