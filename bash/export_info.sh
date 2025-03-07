#!/bin/bash

# Script to export command history and installed packages on Kali Linux
# Make it executable: chmod +x export_info.sh
# Run it: ./export_info.sh

# Create output directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="kali_export_$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"

echo "Creating exports in directory: $OUTPUT_DIR"

# Export bash history
echo "Exporting bash history..."
if [ -f ~/.bash_history ]; then
    cp ~/.bash_history "$OUTPUT_DIR/bash_history.txt"
    echo "✓ Bash history exported to $OUTPUT_DIR/bash_history.txt"
else
    echo "× Bash history file not found at ~/.bash_history"
    # Try to get history from current session
    history > "$OUTPUT_DIR/current_session_history.txt"
    echo "✓ Current session history exported to $OUTPUT_DIR/current_session_history.txt"
fi

# Export zsh history if it exists (some Kali installations use zsh)
if [ -f ~/.zsh_history ]; then
    cp ~/.zsh_history "$OUTPUT_DIR/zsh_history.txt"
    echo "✓ Zsh history exported to $OUTPUT_DIR/zsh_history.txt"
fi

# Export list of all installed packages
echo "Exporting installed packages..."
dpkg --get-selections > "$OUTPUT_DIR/installed_packages_all.txt"
echo "✓ Complete package list exported to $OUTPUT_DIR/installed_packages_all.txt"

# Export list of explicitly installed packages (not dependencies)
apt-mark showmanual > "$OUTPUT_DIR/installed_packages_manual.txt"
echo "✓ Manually installed packages exported to $OUTPUT_DIR/installed_packages_manual.txt"

# Export package details with versions
dpkg-query -W -f='${Package}\t${Version}\t${Status}\n' | grep "install ok installed" > "$OUTPUT_DIR/package_versions.txt"
echo "✓ Package versions exported to $OUTPUT_DIR/package_versions.txt"

# Export Kali-specific tool information if possible
if command -v kali-tools ; then
    echo "Exporting Kali tools information..."
    kali-tools list > "$OUTPUT_DIR/kali_tools.txt" 2>/dev/null
    echo "✓ Kali tools information exported to $OUTPUT_DIR/kali_tools.txt"
fi

# Create a compressed archive of all exports
echo "Creating compressed archive..."
tar -czf "${OUTPUT_DIR}.tar.gz" "$OUTPUT_DIR"
echo "✓ All exports compressed to ${OUTPUT_DIR}.tar.gz"

echo "Export complete! Files are available in:"
echo "- Directory: $OUTPUT_DIR"
echo "- Archive: ${OUTPUT_DIR}.tar.gz"
