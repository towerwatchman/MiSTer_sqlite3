#!/bin/bash
set -euo pipefail

# Define variables
REPO="towerwatchman/MiSTer_Sqlite3"
INSTALL_DIR="/usr/lib/python3.9/lib-dynload"
PACKAGE_DIR="/usr/lib/python3.9"
TEMP_DIR="/tmp/sqlite3_install"

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., sudo $0)"
  exit 1
fi

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Step 1: Download and extract Python 3.9 distribution, then create sqlite3.tar.gz
wget -q https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tar.xz
tar -xJf Python-3.9.0.tar.xz
cd Python-3.9.0/Lib
tar -czf "$TEMP_DIR/sqlite3.tar.gz" sqlite3
cd "$TEMP_DIR"

# Step 2: Download the latest release from GitHub
LATEST_TAG=$(wget -qO- "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_TAG" ]; then
  echo "Failed to fetch latest release tag"
  exit 1
fi
echo "Latest release tag: $LATEST_TAG"
wget -q "https://github.com/$REPO/releases/download/$LATEST_TAG/sqlite3-mister.tar.gz"

# Step 3: Extract and install files
# Install _sqlite3.so
tar -xzf sqlite3-mister.tar.gz
mv _sqlite3.so "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/_sqlite3.so"

# Install sqlite3 package
tar -xzf sqlite3.tar.gz -C "$PACKAGE_DIR/"

# Step 4: Verify installation
echo "Verifying SQLite3 installation..."
PYTHON_OUTPUT=$(python3 -c "import sqlite3; print(sqlite3.sqlite_version)" 2>&1)
if [[ "$PYTHON_OUTPUT" =~ ^3\.49\.1$ ]]; then
  echo "SQLite3 version 3.49.1 installed successfully."
else
  echo "Verification failed: $PYTHON_OUTPUT"
  exit 1
fi

# Clean up
cd /
rm -rf "$TEMP_DIR"

echo "Installation completed successfully."
exit 0