#!/bin/bash
set -e

DATE=$(date +%d-%m-%Y)
BASE="/c/BACKUPS"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

REMOTE_USER="ubuntu"
REMOTE_HOST="<IP>"
REMOTE_BASE="/home/ubuntu"
FOLDER_NAME="<folder_name>" #In remote server

REMOTE_TAR="$REMOTE_BASE/${FOLDER_NAME}_$DATE.tar.gz"
DEST="$BASE/<folder_name>/<folder_name>/<folder_name>_$DATE"
LOCAL_TAR="$DEST/${FOLDER_NAME}_$DATE.tar.gz"

mkdir -p "$DEST"

ssh $SSH_OPTS -i "/c/Users/mahesh.a/Downloads/<pem_key>" $REMOTE_USER@$REMOTE_HOST \
"tar -czf $REMOTE_TAR -C $REMOTE_BASE $FOLDER_NAME"

scp $SSH_OPTS -i "/c/Users/mahesh.a/Downloads/<pem_key>" \
$REMOTE_USER@$REMOTE_HOST:$REMOTE_TAR "$LOCAL_TAR"

ssh $SSH_OPTS -i "/c/Users/mahesh.a/Downloads/<pem_key>" \
$REMOTE_USER@$REMOTE_HOST "rm -f $REMOTE_TAR"

tar -xzf "$LOCAL_TAR" -C "$DEST"
rm -f "$LOCAL_TAR"

echo "✅ HR APPLICATION done"