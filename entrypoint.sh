#!/bin/bash

set -e

# Create the backup folder if it doesn't exist
# Create sub-folder for current date
NOW="$(date +'%Y_%m_%d')"
BACKUP_LOCATION="$BACKUP_LOCATION/$NOW"
mkdir -p $BACKUP_LOCATION

exec "$@"
