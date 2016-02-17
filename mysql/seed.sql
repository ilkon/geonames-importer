LOAD DATA LOCAL INFILE 'allCountries.txt' INTO TABLE names CHARACTER SET 'utf8';

LOAD DATA LOCAL INFILE 'alternateNames.txt' INTO TABLE alternate_names CHARACTER SET 'utf8';

LOAD DATA LOCAL INFILE 'iso-languagecodes.txt' INTO TABLE iso_language_codes CHARACTER SET 'utf8' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'admin1CodesASCII.txt' INTO TABLE admin1_ascii_codes CHARACTER SET 'utf8';

LOAD DATA LOCAL INFILE 'admin2Codes.txt' INTO TABLE admin2_codes CHARACTER SET 'utf8';

LOAD DATA LOCAL INFILE 'featureCodes_en.txt' INTO TABLE feature_codes CHARACTER SET 'utf8';

LOAD DATA LOCAL INFILE 'timeZones.txt' INTO TABLE timezones CHARACTER SET 'utf8' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'countryInfo.txt' INTO TABLE country_info CHARACTER SET 'utf8' IGNORE 51 LINES;

LOAD DATA LOCAL INFILE 'continentCodes.txt' INTO TABLE continent_codes CHARACTER SET 'utf8';

LOAD DATA LOCAL INFILE 'hierarchy.txt' INTO TABLE hierarchy CHARACTER SET 'utf8';
