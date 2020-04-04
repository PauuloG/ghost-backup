#!/bin/bash

# Sourced by ghost-backup backup and restore

# Match string to indicate a db archive
DB_ARCHIVE_MATCH="${BACKUP_FILE_PREFIX}.*db.*gz"
# Match string to indicate a ghost archive
GHOST_ARCHIVE_MATCH="${BACKUP_FILE_PREFIX}.*ghost.*tar"
# Match string to indicate a ghost json export file
GHOST_JSON_FILE_MATCH="${BACKUP_FILE_PREFIX}.*ghost.*json"

NOW=`date +'%Y_%m_%d'`

# Initially set to false before being tested
MYSQL_CONTAINER_LINKED=false
GHOST_CONTAINER_LINKED=false

# Simple log, write to stdout
log () {
    echo "`date -u`: $1" | tee -a $LOG_LOCATION
}

# Check if we have a mysql container on the network to use (instead of sqlite)
checkMysqlAvailable () {
    log "Checking if a mysql container exists on the network at $MYSQL_SERVICE_NAME:$MYSQL_SERVICE_PORT"

    if nc -z $MYSQL_SERVICE_NAME $MYSQL_SERVICE_PORT > /dev/null 2>&1 ; then
        MYSQL_CONTAINER_LINKED=true
        log "...a mysql container exists on the network. Using mysql mode"

        # Check the appropriate env vars needed for mysql have been set
        if [ -z "$MYSQL_USER" ]; then log "Error: MYSQL_USER not set. Make sure it's set for your ghost-backup container?"; log "Finished: FAILURE"; exit 1; fi
        if [ -z "$MYSQL_DATABASE" ]; then log "Error: MYSQL_DATABASE not set. Make sure it's set for your ghost-backup container?"; log "Finished: FAILURE"; exit 1; fi
        if [ -z "$MYSQL_PASSWORD" ]; then log "Error: MYSQL_PASSWORD not set. Make sure it's set for your ghost-backup container?"; log "Finished: FAILURE"; exit 1; fi

    else
        log "...no mysql container exists on the network. Using sqlite mode"
    fi
}

# Check if we have a ghost on the network to use for json file backup/restore
checkGhostAvailable () {
    log "Checking if a ghost container exists on the network at $GHOST_SERVICE_NAME:$GHOST_SERVICE_PORT"

    if nc -z $GHOST_SERVICE_NAME $GHOST_SERVICE_PORT > /dev/null 2>&1 ; then
        GHOST_CONTAINER_LINKED=true
        log "...found ghost service on the network"
    else
        log "...no ghost service found on the network"
    fi
}

getCookie () {
    COOKIE=$(curl -c - --silent "$GHOST_SERVICE_PROTOCOL$GHOST_SERVICE_NAME/ghost/api/v3/admin/session" \
        --header "Origin: $GHOST_SERVICE_PROTOCOL$GHOST_SERVICE_NAME" \
        --header 'Content-Type: application/json' \
        --data-raw "{
            \"username\": \"$GHOST_USER_USERNAME\",
            \"password\": \"$GHOST_USER_PASSWORD\"
        }")
}

# Run before both the backup and restore scripts
checkMysqlAvailable
