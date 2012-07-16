#!/bin/bash

# import_gtfs.sh: Import a GTFS to Postgres and analyze it using James Wong's GTFS Explore scripts
# Author: Matt Conway

# http://stackoverflow.com/questions/59895
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration and paths
PSQL=psql
CREATEDB=createdb
IMPORTER_SRC_DIR=${DIR}/importer/src
TRANSFORMER="java -jar ${DIR}/lib/gtfs-transformer.jar"
TRANSFORMS_DIR=${DIR}/transforms
POSTGIS_DIR=/usr/share/postgresql/9.1/contrib/postgis-1.5
GTFSEXPLORE_DIR=${DIR}/..
TEMPLATE_DB=postgis_template

# Modes. These should match file names in the transforms/ dir
MODES="light_rail subway rail bus"

# Command line arguments: should be import_gtfs_and_analyze.sh /path/to/gtfs.zip slug
IN_GTFS=$1
SLUG=$2

# Time it, in seconds
start=`date +%s`

# Check and confirm empty directory
# http://superuser.com/questions/352289
if [ "$(ls -A)" ]; then
    echo "Scratch directory $(pwd) is not empty!"
    exit 1
fi

# Make a directory for files to keep
mkdir output

for mode in $MODES; do
    dbname="${SLUG}_${mode}"

    # First, split the GTFS by mode
    echo Transforming GTFS...
    $TRANSFORMER --transform=${TRANSFORMS_DIR}/${mode}.json $IN_GTFS ${dbname}
    if [ $? -ne 0 ]; then
        echo "Transformation failed, see previous errors."
        exit 1
    fi

    # If there is not a stop_times.txt, this agency does not support this mode
    if [ ! -e ${dbname}/stop_times.txt ]; then
        echo "Agency ${SLUG} does not operate mode ${mode}"
        continue
    fi

    # Now create the database
    # The template DB must be owned by the user executing createdb, it seems;
    # http://www.paolocorti.net/2008/01/30/installing-postgis-on-ubuntu/ section 5
    echo Creating database...
    $CREATEDB $dbname -T ${TEMPLATE_DB}
    if [ $? -ne 0 ]; then
        echo "Cannot use DB name ${dbname}, DB exists (or perhaps a template problem)"
        exit 1
    fi

    echo Loading GTFS data to database...
    # Taken directly from https://github.com/cbick/gtfs_SQL_importer, in the README.md
    cat ${IMPORTER_SRC_DIR}/gtfs_tables.sql \
        <(python ${IMPORTER_SRC_DIR}/import_gtfs_to_sql.py ${dbname}) \
        ${IMPORTER_SRC_DIR}/gtfs_tables_makeindexes.sql \
        ${IMPORTER_SRC_DIR}/gtfs_tables_makespatial.sql \
        ${IMPORTER_SRC_DIR}/vacuumer.sql \
        | $PSQL -d $dbname

    echo Running feed statistics...
    # TODO: biased because of transformer output?
    # Send output (the SELECT at the end) to /dev/null since we're running in batch mode
    $PSQL -d $dbname -f ${GTFSEXPLORE_DIR}/feedstats.sql -o /dev/null

    echo Running feed analysis...
    $PSQL -d $dbname -f "${GTFSEXPLORE_DIR}/GTFS Explore.sql" -o /dev/null

    echo Saving output...
    # the stats
    $PSQL -d $dbname \
        -c "\copy gtfs_feed_stats TO output/${dbname}_feed_stats.csv WITH CSV HEADER"

    # the analysis
    $PSQL -d $dbname \
        -c "\copy (SELECT * FROM route_level_report) TO output/${dbname}_route_level.csv WITH CSV HEADER"
    $PSQL -d $dbname \
        -c "\copy (SELECT * FROM stop_level_report) TO output/${dbname}_stop_level.csv WITH CSV HEADER"
    $PSQL -d $dbname \
        -c "\copy (SELECT * FROM stop_route_level_report) TO output/${dbname}_stop_route_level.csv WITH CSV HEADER"
done

end=`date +%s`

echo ${SLUG},`expr $end - $start` >> output/analysis_stats.csv