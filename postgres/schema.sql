SET search_path TO geonames;

-- all countries combined in one file, see 'geoname' table for columns
DROP TABLE IF EXISTS names;
CREATE TABLE names (
  name_id INT PRIMARY KEY,          -- integer id of record in geonames database
  name TEXT,                        -- name of geographical point (utf8) varchar(200)
  ascii_name TEXT,                  -- name of geographical point in plain ascii characters, varchar(200)
  alternate_names TEXT,             -- alternate names, comma separated varchar(5000)
  latitude DECIMAL(10,7),           -- latitude in decimal degrees (wgs84)
  longitude DECIMAL(10,7),          -- longitude in decimal degrees (wgs84)
  feature_class CHAR(1),            -- see http://www.geonames.org/export/codes.html, char(1)
  feature_code VARCHAR(10),         -- see http://www.geonames.org/export/codes.html, varchar(10)
  country_code CHAR(2),             -- ISO-3166 2-letter country code, 2 characters
  cc2 VARCHAR(250),                 -- alternate country codes, comma separated, ISO-3166 2-letter country code, 60 characters
  admin1_code VARCHAR(20),          -- fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
  admin2_code VARCHAR(80),          -- code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80)
  admin3_code VARCHAR(20),          -- code for third level administrative division, varchar(20)
  admin4_code VARCHAR(20),          -- code for fourth level administrative division, varchar(20)
  population BIGINT,                -- bigint (8 byte int)
  elevation INT,                    -- in meters, integer
  dem INT,                          -- digital elevation model, srtm3 or gtopo30, average elevation of 3''x3'' (ca 90mx90m) or 30''x30'' (ca 900mx900m) area in meters, integer. srtm processed by cgiar/ciat.
  timezone VARCHAR(40),             -- the timezone id (see file timeZone.txt) varchar(40)
  modified_at DATE                  -- date of last modification in yyyy-MM-dd format
);

-- alternate names with language codes and geonameId
DROP TABLE IF EXISTS alternate_names;
CREATE TABLE alternate_names (
  alternate_name_id INT PRIMARY KEY,-- the id of this alternate name, int
  name_id INT,                      -- geonameId referring to id in table 'geoname', int
  iso_language_code VARCHAR(7),     -- iso 639 language code 2- or 3-characters; 4-characters 'post' for postal codes and 'iata','icao' and faac for airport codes, fr_1793 for French Revolution names, abbr for abbreviation, link for a website, varchar(7)
  alternate_name TEXT,              -- alternate name or name variant, varchar(200)
  is_preferred BOOLEAN,             -- '1', if this alternate name is an official/preferred name
  is_short BOOLEAN,                 -- '1', if this is a short name like 'California' for 'State of California'
  is_colloquial BOOLEAN,            -- '1', if this alternate name is a colloquial or slang term
  is_historic BOOLEAN               -- '1', if this alternate name is historic and was used in the past
);

-- iso 639 language codes, as used for alternate names in file alternateNames.zip
DROP TABLE IF EXISTS iso_language_codes;
CREATE TABLE iso_language_codes (
  iso_639_3 CHAR(4),
  iso_639_2 VARCHAR(50),
  iso_639_1 VARCHAR(50),
  language_name TEXT
);

-- ascii names of admin divisions. (beta > http://forum.geonames.org/gforum/posts/list/208.page--1143)
DROP TABLE IF EXISTS admin1_ascii_codes;
CREATE TABLE admin1_ascii_codes (
  code VARCHAR(125),
  name TEXT,
  ascii_name TEXT,
  name_id INT
);

-- names for administrative subdivision 'admin2 code' (UTF8), Format : concatenated codes <tab>name <tab> asciiname <tab> geonameId
DROP TABLE IF EXISTS admin2_codes;
CREATE TABLE admin2_codes (
  code VARCHAR(125),
  name TEXT,
  ascii_name TEXT,
  name_id INT
);

-- name and description for feature classes and feature codes
DROP TABLE IF EXISTS feature_codes;
CREATE TABLE feature_codes (
  code VARCHAR(7),
  name TEXT,
  description TEXT
);

-- countryCode, timezoneId, gmt offset on 1st of January, dst offset to gmt on 1st of July (of the current year), rawOffset without DST
DROP TABLE IF EXISTS timezones;
CREATE TABLE timezones (
  iso_alpha2 CHAR(2),
  timezone_id VARCHAR(200),
  gmt_offset DECIMAL(3,1),
  dst_offset DECIMAL(3,1),
  raw_offset DECIMAL(3,1)
);

-- country information : iso codes, fips codes, languages, capital ,...
--     see the geonames webservices for additional country information,
--     bounding box                         : http://ws.geonames.org/countryInfo?
--     country names in different languages : http://ws.geonames.org/countryInfoCSV?lang=it
DROP TABLE IF EXISTS country_info;
CREATE TABLE country_info (
  iso_alpha2 CHAR(2),                 -- ISO
  iso_alpha3 CHAR(3),                 -- ISO3
  iso_numeric INT,                    -- ISO-Numeric
  fips_code VARCHAR(3),               -- fips
  name VARCHAR(256),                  -- Country
  capital VARCHAR(256),               -- Capital
  area_in_sqkm DOUBLE PRECISION,      -- Area(in sq km)
  population INT,                     -- Population
  continent CHAR(2),                  -- Continent
  tld CHAR(8),                        -- tld
  currency_code CHAR(3),              -- CurrencyCode
  currency_name CHAR(20),             -- CurrencyName
  phone CHAR(32),                     -- Phone
  postal_code_format VARCHAR(128),    -- Postal Code Format
  postal_code_regex VARCHAR(256),     -- Postal Code Regex
  languages TEXT,                     -- Languages
  name_id INT,                        -- geonameid
  neighbours VARCHAR(256),            -- neighbours
  equivalent_fips_code CHAR(16)       -- EquivalentFipsCode
);

DROP TABLE IF EXISTS continent_codes;
CREATE TABLE continent_codes (
  code CHAR(2),
  name VARCHAR(20),
  name_id INT
);

-- parentId, childId, type. The type 'ADM' stands for the admin hierarchy modeled by the admin1-4 codes.
-- The other entries are entered with the user interface. The relation toponym-adm hierarchy is not included in the file,
-- it can instead be built from the admincodes of the toponym.
DROP TABLE IF EXISTS hierarchy;
CREATE TABLE hierarchy (
  parent_id INT,
  child_id INT,
  type VARCHAR(50)
);
