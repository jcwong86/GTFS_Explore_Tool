# Run batch analysis on GTFS feeds
# Input: A list of data exchange ids

from sys import argv
from subprocess import call
from re import compile
from urllib2 import urlopen
from xml.dom.minidom import parse
from os.path import dirname

# http://stackoverflow.com/questions/595305
here = dirname(argv[0])

snre = compile('^[a-zA-Z0-9]+$')

reader = open(argv[1])

for line in reader:
    shortname = line[:-1].replace('-', '')

    if snre.match(shortname) == None:
        print 'Invalid short name %s' % shortname
        continue

    # get the rss
    rss = parse(urlopen('http://www.gtfs-data-exchange.com/agency/%s/feed' % line[:-1]))
    links = rss.getElementsByTagName('link')

    gtfs = ''
    for link in links:
        if link.getAttribute('rel') == 'enclosure':
            gtfs = link.getAttribute('href')
            break

    if gtfs == '':
        print "no GTFS for agency %s" % shortname
        continue

    call(['wget', gtfs, '-O', shortname + '.zip'])
    call([here + '/import_gtfs_and_analyze.sh', shortname + '.zip', shortname])

    # Don't remove the GTFSs, they mat be useful later.
