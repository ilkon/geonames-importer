COPY names FROM 'allCountries.txt' ( FORMAT CSV, DELIMITER '\t' );

COPY alternate_names FROM 'alternateNames.txt' INTO TABLE alternate_names CHARACTER SET 'utf8';

COPY iso_language_codes FROM 'iso-languagecodes.txt' INTO TABLE iso_language_codes CHARACTER SET 'utf8' IGNORE 1 LINES;

COPY admin1_ascii_codes FROM 'admin1CodesASCII.txt' INTO TABLE admin1_ascii_codes CHARACTER SET 'utf8';

COPY admin2_codes FROM 'admin2Codes.txt' INTO TABLE admin2_codes CHARACTER SET 'utf8';

COPY feature_codes FROM 'featureCodes_en.txt' INTO TABLE feature_codes CHARACTER SET 'utf8';

COPY timezones FROM 'timeZones.txt' INTO TABLE timezones CHARACTER SET 'utf8' IGNORE 1 LINES;

COPY country_info FROM 'countryInfo.txt' INTO TABLE country_info CHARACTER SET 'utf8' IGNORE 51 LINES;

COPY continent_codes FROM 'continentCodes.txt' INTO TABLE continent_codes CHARACTER SET 'utf8';

COPY hierarchy FROM 'hierarchy.txt' INTO TABLE hierarchy CHARACTER SET 'utf8';
