#!/bin/bash

# import_gtfs.sh: Import a GTFS to Postgres and analyze it using James Wong's GTFS Explore scripts
# Author: Matt Conway

# http://stackoverflow.com/questions/59895
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration and paths
PSQL=psql
CREATEDB=createdb
DROPDB=dropdb
IMPORTER_SRC_DIR=${DIR}/importer/src
TRANSFORMER="java -Xmx15000m -jar ${DIR}/lib/gtfs-transformer.jar"
TRANSFORMS_DIR=${DIR}/transforms
POSTGIS_DIR=/usr/share/postgresql/9.1/contrib/postgis-1.5
GTFSEXPLORE_DIR=${DIR}/..
TEMPLATE_DB=postgis_template

# Modes. These should match file names in the transforms/ dir
#MODES="light_rail subway rail bus"
MODES="all"

# Command line arguments: should be import_gtfs_and_analyze.sh /path/to/gtfs.zip shortname
IN_GTFS=$1
SHORTNAME=$2

# Time it, in seconds
start=`date +%s`

# Check and confirm empty directory
# http://superuser.com/questions/352289
#if [ "$(ls -A)" ]; then
#    echo "Scratch directory $(pwd) is not empty!"
#    exit 1
#fi

# Make sure the short name is safe
echo $SHORTNAME | grep '^[a-zA-Z]\+$'
if [ $? -ne 0 ]; then
    echo Unsafe shortname $SHORTNAME
    exit 1
fi

# Make a directory for files to keep
mkdir output


dbname="${SHORTNAME}"

echo Creating database...
$CREATEDB "$dbname" -T ${TEMPLATE_DB}
if [ $? -ne 0 ]; then
    echo "Cannot use DB name ${dbname}, DB exists (or perhaps a template problem)"
    exit 1
fi

echo Extracting GTFS...
(mkdir "$dbname" && cd "$dbname" && unzip "../${IN_GTFS}")
if [ $? -ne 0 ]; then
    echo "Cannot mkdir $dbname"
    exit 1
fi

echo Loading GTFS data to database...
    # Taken directly from https://github.com/cbick/gtfs_SQL_importer, in the README.md
cat ${IMPORTER_SRC_DIR}/gtfs_tables.sql \
    <(python "${IMPORTER_SRC_DIR}/import_gtfs_to_sql.py" "$dbname") \
    "${IMPORTER_SRC_DIR}/gtfs_tables_makeindexes.sql" \
    "${IMPORTER_SRC_DIR}/gtfs_tables_makespatial.sql" \
    "${IMPORTER_SRC_DIR}/vacuumer.sql" \
    | $PSQL -d "$dbname"

echo Running feed statistics...
    # Send output (the SELECT at the end) to /dev/null since we're running in batch mode
$PSQL -d "$dbname" -f "${GTFSEXPLORE_DIR}/feedstats.sql" -o /dev/null

echo Skipping feed analysis.
    #$PSQL -d "$dbname" -f "${GTFSEXPLORE_DIR}/GTFS Explore.sql" -o /dev/null

echo Saving output...
    # the stats
$PSQL -d "$dbname" \
    -c "\copy gtfs_feed_stats TO output/${dbname}_feed_stats.csv WITH CSV HEADER"

    # the analysis
#    $PSQL -d "$dbname" \
#        -c "\copy (SELECT * FROM route_level_report) TO output/${dbname}_route_level.csv WITH CSV HEADER"
#    $PSQL -d "$dbname" \
#        -c "\copy (SELECT * FROM stop_level_report) TO output/${dbname}_stop_level.csv WITH CSV HEADER"
#    $PSQL -d "$dbname" \
#        -c "\copy (SELECT * FROM stop_route_level_report) TO output/${dbname}_stop_route_level.csv WITH CSV HEADER"

    # Since we created it, clean it up
$DROPDB "$dbname"
rm -rf "${dbname}"

end=`date +%s`

echo ${SHORTNAME},`expr $end - $start` >> output/analysis_stats.csv