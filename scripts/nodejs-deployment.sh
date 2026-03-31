#!/bin/bash
ID=$(id -u)

# Validation Function
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo "ERROR: $2 ... FAILED"
        exit 1
    else
        echo "$2 ... SUCCESS"
    fi
}

# Check Root User
if [ $ID -ne 0 ]; then
    echo "Please run this script as root user"
    exit 1
else
    echo "Running as root user"
fi


# System Update
apt update -y 
apt upgrade -y


# Install Curl
apt install -y curl 

VALIDATE $? "Installing Curl"


# Install NodeJS 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 

apt install -y nodejs 

VALIDATE $? "Installing NodeJS"


# Install PM2
echo "Installing PM2..." 

npm install -g pm2 

VALIDATE $? "Installing PM2"


#validate the installations
echo "Installation Completed Successfully"
echo "Node Version: $(node -v)"
echo "NPM Version : $(npm -v)"
echo "PM2 Version : $(pm2 -v)"
echo "Logs stored at: /tmp/terminal.txt"