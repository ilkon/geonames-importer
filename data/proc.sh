#!/bin/sh

usage() {
    PN=`basename "$0"`
    echo >&2 "Usage: $PN [OPTIONS] <action>"
    echo >&2 " Where <action>:"
    echo >&2 "    drop              Drop geonames database"
    echo >&2 "    create            Create geonames database"
    echo >&2 "    drop_schema       Drop geonames database schema (PostgreSQL only)"
    echo >&2 "    create_schema     Create geonames database schema (PostgreSQL only)"
    echo >&2 "    migrate           Create structure of geonames database"
    echo >&2 "    seed              Import geonames data"
    echo >&2 "    reset             Reset geonames database and import data"
    echo >&2 "    update            Update database (usually should run daily by cron)"
    echo >&2 " Options:"
    echo >&2 "    -h <host>         Database server address (default: $DB_HOST)"
    echo >&2 "    -r <port>         Database server port (default: $DB_PORT)"
    echo >&2 "    -d <database>     Database name (default: $DB_NAME)"
    echo >&2 "    -s <schema>       Database schema name (PostgreSQL only)"
    echo >&2 "    -u <user>         Username to access database"
    echo >&2 "    -p <password>     User password to access database"
    echo >&2 ""
}

# Main procedure

while getopts "h:r:d:s:u:p:" opt; do
    case $opt in
        h) DB_HOST=$OPTARG ;;
        r) DB_PORT=$OPTARG ;;
        d) DB_NAME=$OPTARG ;;
        s) DB_SCHEMA=$OPTARG ;;
        u) DB_USERNAME=$OPTARG ;;
        p) DB_PASSWORD=$OPTARG ;;
        \?)
            usage
            exit 3
            ;;
    esac
done

init

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
        drop_schema)
            drop_schema
            exit 0
            ;;
        create_schema)
            create_schema
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
