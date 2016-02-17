# Geonames database importer

As it's stated on their [site](http://www.geonames.org/), GeoNames geographical database covers all countries and contains over eight million placenames. This database is available for download free of charge under a creative commons attribution license.

This script downloads all the tables available on Geonames.org and imports them into local database. Also it can be used to keep local database up to date by synchronizing it with Geonames.org. When running with a special option it downloads daily diff's and applies them to current database.

The script supports MySQL and PostgreSQL databases.

## Usage

The basics of this script are quite simple:

```sh
cd mysql
importer.sh [OPTIONS] <action>
```

Where **\<action\>** can be one of the following:

* `drop` --- drops database
* `create` --- creates empty database
* `migrate` --- creates structure of local geonames database
* `seed` --- downloads geonames data and imports them into local database
* `reset` --- resets geonames database and import data
* `update` --- updates database (usually should run daily by cron)

Options are:

* `-h <host>` --- database server address (default: `localhost`)
* `-r <port>` --- database server port (default: `3306`)
* `-d <database>` --- database name (default: `geonames`)
* `-u <user>` --- username to access database
* `-p <password>` --- user password to access database

## Examples

To create local database `geonames`:

```sh
importer.sh -u root -p ROOT_PASSWORD create
```

To prepare local database `geonames` (create empty tables) :

```sh
importer.sh -u geouser -p GEOUSER_PASSWORD migrate
```

To import geonames data into local `geonames` database:

```sh
importer.sh -u geouser -p GEOUSER_PASSWORD seed
```

To apply yesterday's changes in geonames.org to local database `geonames`:

```sh
importer.sh -u geouser -p GEOUSER_PASSWORD update
```

## License

**Geonames database importer** is Copyright © 2014-2016 Ilya Konyukhov. It is free software and may be redistributed under the terms specified in the [LICENSE](https://github.com/ilkon/geonames-importer/blob/master/LICENSE) file.
