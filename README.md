GTFS_Explore_Tool
=================

A postgres based analysis of transit service from a GTFS feed using TCQSM based methodologies and batch analysis tools.

This is a series of .sql scripts and R code designed to provide the user with information about the transit service described in a GTFS feed using methodologies from the Transit Capacity and Quality of Service Manual 2nd Ed (The project visiting the third editions is at  http://tcqsm.org).

There is also a batch analysis element which will loop through the analysis of many agencies and return aggregate results which can be analyzed by the R code. 

The postgres scripts rely on:
 - a properly formed GTFS feed
 - use of the gtfs_sql_importer (https://github.com/cbick/gtfs_SQL_importer)
 - PostgreSQL 9.1 w/ PostGIS support enabled
 
The batch importer also uses the excellent [OneBusAway GTFS Transformer](http://developer.onebusaway.org/modules/onebusaway-gtfs-modules/current-SNAPSHOT/onebusaway-gtfs-transformer-cli.html) tool, which is licensed under the Apache 2 license and is checked in in the lib/ directory.

Limitations of the scripts:
 - Works when stops are coded individually, not with time-point only feeds
 - Requires use of shapes.txt file for any distance related functions
 - Does not currently work on files using frequency-based schedules.
