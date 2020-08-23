#!/usr/bin/env python
import glob
import logging
import logging.handlers

# Please don't give "/" in last
base_path = "/tmp/shtest"
LOG_FILENAME = base_path + '/PeerStatsSummary.log'

# Set up a specific logger with our desired output level
my_logger = logging.getLogger('MyLogger')
my_logger.setLevel(logging.DEBUG)

# Add the log message handler to the logger
handler = logging.handlers.RotatingFileHandler(LOG_FILENAME, maxBytes=20, backupCount=5)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s','%d-%b-%y %H:%M:%S')


my_logger.addHandler(handler)
handler.setFormatter(formatter)


# Log some messages
for i in range(20):
    my_logger.info('i = %d' % i)

# See what files are created
logfiles = glob.glob('%s*' % LOG_FILENAME)

for filename in logfiles:
    print(filename)
