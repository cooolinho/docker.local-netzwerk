#!/bin/bash

# Stop on error
set -e

# Configure those to match your Docker container names
DOCKER_CONTAINER_POSTGRES="planka-db"
DOCKER_CONTAINER_PLANKA="planka"

# Use provided archive
BACKUP_ARCHIVE="2026-07-26T05-14-50Z-backup.tgz"

if [ -z "$BACKUP_ARCHIVE" ]; then
    echo "Usage: $0 <backup-archive.tgz>"
    exit 1
fi

BACKUP_DIR=$(dirname "$BACKUP_ARCHIVE")
BACKUP_TEMP="$BACKUP_DIR/$(basename "$BACKUP_ARCHIVE" .tgz)"

echo -n "Extracting tarball $BACKUP_ARCHIVE ... "
tar -C "$BACKUP_DIR" -xzf "$BACKUP_ARCHIVE"
echo "Success!"
echo

echo -n "Importing postgres database ... "
cat "$BACKUP_TEMP/postgres.sql" | docker exec -i "$DOCKER_CONTAINER_POSTGRES" psql -U planka planka
echo "Success!"
echo

#echo -n "Importing data volume ... "
#docker run --rm --user root --volumes-from "$DOCKER_CONTAINER_PLANKA" -v "$BACKUP_TEMP:/backup" node:22-alpine sh -c "cp -rf /backup/user-avatars/. /app/public/user-avatars && chown -R node:node /app/public/user-avatars/*"
#docker run --rm --user root --volumes-from "$DOCKER_CONTAINER_PLANKA" -v "$BACKUP_TEMP:/backup" node:22-alpine sh -c "cp -rf /backup/project-background-images/. /app/public/project-background-images && chown -R node:node /app/public/project-background-images/*"
#docker run --rm --user root --volumes-from "$DOCKER_CONTAINER_PLANKA" -v "$BACKUP_TEMP:/backup" node:22-alpine sh -c "cp -rf /backup/attachments/. /app/private/attachments && chown -R node:node /app/private/attachments/*"
#echo "Success!"
#echo

echo -n "Cleaning up temporary files and directories ... "
rm -r "$BACKUP_TEMP"
echo "Success!"
echo

echo "Restore complete!"
