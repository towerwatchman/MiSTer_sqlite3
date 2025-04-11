#!/bin/bash
set -euo pipefail

# Define variables
REPO="towerwatchman/MiSTer_Sqlite3"
INSTALL_DIR="/usr/lib/python3.9/lib-dynload"
PACKAGE_DIR="/usr/lib/python3.9"
TEMP_DIR="/tmp/sqlite3_install"

# Function to print debug messages
debug() {
  echo "[DEBUG] $1"
}

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (e.g., sudo $0)"
  exit 1
fi

debug "Starting SQLite3 installation process..."

# Create temporary directory
debug "Creating temporary directory: $TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Step 1: Download and extract Python 3.9 distribution, then create sqlite3.tar.gz
debug "Downloading Python 3.9 distribution from python.org..."
wget -q https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tar.xz
debug "Extracting Python-3.9.0.tar.xz..."
tar -xJf Python-3.9.0.tar.xz
cd Python-3.9.0/Lib
debug "Creating sqlite3.tar.gz from Python 3.9 Lib directory..."
tar -czf "$TEMP_DIR/sqlite3.tar.gz" sqlite3
cd "$TEMP_DIR"

# Step 2: Download the latest release from GitHub
debug "Fetching latest release tag from GitHub repository: $REPO..."
LATEST_TAG=$(wget -qO- "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_TAG" ]; then
  echo "Error: Failed to fetch latest release tag"
  exit 1
fi
debug "Latest release tag retrieved: $LATEST_TAG"
debug "Downloading sqlite3-mister.tar.gz from release $LATEST_TAG..."
wget -q "https://github.com/$REPO/releases/download/$LATEST_TAG/sqlite3-mister.tar.gz"

# Step 3: Extract and install files
# Install _sqlite3.so
debug "Extracting sqlite3-mister.tar.gz..."
tar -xzf sqlite3-mister.tar.gz
debug "Moving _sqlite3.so to $INSTALL_DIR..."
mv _sqlite3.so "$INSTALL_DIR/"
debug "Setting execute permissions on $INSTALL_DIR/_sqlite3.so..."
chmod +x "$INSTALL_DIR/_sqlite3.so"

# Install sqlite3 package
debug "Extracting sqlite3.tar.gz to $PACKAGE_DIR/..."
tar -xzf sqlite3.tar.gz -C "$PACKAGE_DIR/"

# Step 4: Verify installation
debug "Verifying SQLite3 installation by checking version..."
PYTHON_OUTPUT=$(python3 -c "import sqlite3; print(sqlite3.sqlite_version)" 2>&1)
if [[ "$PYTHON_OUTPUT" =~ ^3\.49\.1$ ]]; then
  debug "SQLite3 version 3.49.1 verified successfully."
else
  echo "Error: Verification failed: $PYTHON_OUTPUT"
  exit 1
fi

# Clean up
debug "Cleaning up temporary directory: $TEMP_DIR..."
cd /
rm -rf "$TEMP_DIR"

echo "SQLite3 installation completed successfully."
exit 0