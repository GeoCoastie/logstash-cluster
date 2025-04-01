#!/bin/bash

# Function to read user input for network configuration
function get_network_input() {
    read -p "Enter the network CIDR (e.g., 192.168.1.0/24): " NETWORK_CIDR
    read -p "Enter the network name (e.g., Local Network): " NETWORK_NAME
}

# Update package lists
sudo apt update

# Install Zeek
sudo apt install -y zeek

# Modify zeekctl.cfg to comment out the "# Mail Options" section
ZECKCTL_CFG="/opt/zeek/etc/zeekctl.cfg"

# Check if the zeekctl.cfg file exists
if [[ -f "$ZECKCTL_CFG" ]]; then
    # Backup the original zeekctl.cfg
    sudo cp "$ZECKCTL_CFG" "$ZECKCTL_CFG.bak"

    # Comment out the "# Mail Options" section
    sudo sed -i '/^# Mail Options/,/^$/ s/^/#/' "$ZECKCTL_CFG"

    echo "zeekctl.cfg updated successfully."
else
    echo "zeekctl.cfg file not found: $ZECKCTL_CFG"
fi

# Modify local.zeek to load json-logs.zeek
LOCAL_ZEEK="/opt/zeek/share/zeek/site/local.zeek"

# Check if the local.zeek file exists
if [[ -f "$LOCAL_ZEEK" ]]; then
    # Backup the original local.zeek
    sudo cp "$LOCAL_ZEEK" "$LOCAL_ZEEK.bak"

    # Add the line before the "@load misc" entry
    sudo sed -i '/@load misc/i @load policy/tuning/json-logs.zeek' "$LOCAL_ZEEK"

    echo "local.zeek updated successfully."
else
    echo "local.zeek file not found: $LOCAL_ZEEK"
fi

# Modify networks.cfg to allow user input for network CIDR and name
NETWORKS_CFG="/opt/zeek/etc/networks.cfg"

# Get user input for network details
get_network_input

# Check if the networks.cfg file exists
if [[ -f "$NETWORKS_CFG" ]]; then
    # Backup the original networks.cfg
    sudo cp "$NETWORKS_CFG" "$NETWORKS_CFG.bak"

    # Append the user-defined network CIDR and name
    echo "$NETWORK_CIDR    $NETWORK_NAME" | sudo tee -a "$NETWORKS_CFG"

    echo "networks.cfg updated with: $NETWORK_CIDR    $NETWORK_NAME"
else
    echo "networks.cfg file not found: $NETWORKS_CFG"
fi

# Install Filebeat
sudo apt install -y filebeat

# Modify filebeat.yml
FILEBEAT_CONFIG="/etc/filebeat/filebeat.yml"

# Check if the file exists
if [[ -f "$FILEBEAT_CONFIG" ]]; then
    # Backup the original configuration
    sudo cp "$FILEBEAT_CONFIG" "$FILEBEAT_CONFIG.bak"

    # Modify paths to include Zeek logs
    sudo sed -i '/^paths:/c\  paths: ["/opt/zeek/logs/current/conn.log"]' "$FILEBEAT_CONFIG"

    # Add tags under processors
    sudo sed -i '/processors:/a\    add_tags: ["_filebeat_zeek_live"]' "$FILEBEAT_CONFIG"

    echo "Filebeat configuration updated successfully."
else
    echo "Filebeat configuration file not found: $FILEBEAT_CONFIG"
fi

# Enable and start Filebeat service
sudo systemctl enable filebeat
sudo systemctl start filebeat

echo "Zeek and Filebeat installation complete."