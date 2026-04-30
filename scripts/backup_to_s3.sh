#!/bin/bash

# Variables
CONTAINER_NAME="<container_name>"
DB_USER="<db_username>"
DB_NAME="<db_name>"

BACKUP_DIR="/home/ubuntu/db-backups"
DATE=$(date +%d-%m-%Y)
FILE_NAME="<file_name>_${DATE}.dump"

S3_BUCKET="s3://<bucket_name>/<inside directory name>"

AWS_BIN="/usr/local/bin/aws"

# Create backup directory if not exists
mkdir -p $BACKUP_DIR

echo "Starting backup: $FILE_NAME"

# Run pg_dump inside docker (staging)
docker exec $CONTAINER_NAME pg_dump -Fc -U $DB_USER -d $DB_NAME > $BACKUP_DIR/$FILE_NAME

# Check if backup successful
if [ $? -eq 0 ]; then
    echo "Backup successful"

    # Upload to S3
    $AWS_BIN s3 cp $BACKUP_DIR/$FILE_NAME $S3_BUCKET/$FILE_NAME

    if [ $? -eq 0 ]; then
        echo "Upload to S3 successful"
    else
        echo "S3 upload failed"
    fi
else
    echo "Backup failed"
fi

# LOCAL CLEANUP (older than 7 days)
find $BACKUP_DIR -type f -name "<backup_file_name>_*.dump" -mtime +7 -delete

echo "Old local backups deleted"
