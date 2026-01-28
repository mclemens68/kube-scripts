#!/bin/bash

# Define the commands you want to add
CRON_COMMANDS=$(
cat <<EOF
*/15 * * * * curl -s http://yelb.uscentral.illumio-demo.com/api/ihop > /dev/null
*/15 * * * * curl -s http://yelb.uscentral.illumio-demo.com/api/chipotle > /dev/null
*/15 * * * * curl -s http://yelb.uscentral.illumio-demo.com/api/outback > /dev/null
*/15 * * * * curl -s http://yelb.uscentral.illumio-demo.com/api/bucadibeppo > /dev/null
EOF
)

# Backup current crontab
crontab -l > mycron_backup 2>/dev/null

# Start with existing crontab or empty if none exists
crontab -l 2>/dev/null > mycron_tmp || true

# Loop through each command and add if not present
while read -r line; do
  grep -F "$line" mycron_tmp > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "$line" >> mycron_tmp
  fi
done <<< "$CRON_COMMANDS"

# Install new crontab
crontab mycron_tmp

# Clean up
rm mycron_tmp

echo "New cron jobs installed. Backup saved as mycron_backup."
