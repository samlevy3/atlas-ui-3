#!/bin/bash
# Cloud Foundry pre-start script
# This script runs before the application starts

# Create runtime directories
mkdir -p /home/vcap/app/logs
mkdir -p /home/vcap/app/feedback
mkdir -p /home/vcap/app/uploads

# If overrides directory is empty, copy defaults
if [ -d /home/vcap/app/config/defaults ] && [ "$(ls -A /home/vcap/app/config/overrides 2>/dev/null | wc -l)" = "0" ]; then
    cp -n /home/vcap/app/config/defaults/* /home/vcap/app/config/overrides/ 2>/dev/null || true
fi

echo "Cloud.gov pre-start configuration complete"
