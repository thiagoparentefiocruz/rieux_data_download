#!/bin/bash

hpc_data_download() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: hpc_data_download <user@hpc:/path/to/remote_file_or_folder> </path/to/local_folder>"
        return 1
    fi

    local REMOTE_SRC="$1"
    local LOCAL_DEST="$2"
    
    local REMOTE_HOST="${REMOTE_SRC%%:*}"
    local REMOTE_DIR="${REMOTE_SRC#*:}"

    echo "🚀 Starting smart HPC download pipeline..."

    local OS_TYPE=$(uname -s)
    local CMD_HASH_CHECK=()
    local CMD_RSYNC=()

    case "$OS_TYPE" in
        Darwin*)
            echo "🍎 System detected: macOS. Configuring caffeinate and shasum..."
            CMD_HASH_CHECK=(shasum -a 256 -c)
            CMD_RSYNC=(caffeinate -i rsync -avP)
            ;;
        Linux*)
            echo "🐧 System detected: Linux/WSL. Configuring sha256sum..."
            CMD_HASH_CHECK=(sha256sum -c)
            CMD_RSYNC=(rsync -avP)
            ;;
        *)
            echo "❌ Operating System '$OS_TYPE' not supported."
            return 1
            ;;
    esac

    local ORIGINAL_DIR=$(pwd)
    
    # Ensure the local destination folder exists
    mkdir -p "$LOCAL_DEST"

    echo "---------------------------------------------------"
    echo "Analyzing the HPC target and calculating hashes in real-time..."
    
    # Ask the server if it's a directory or a file
    local REMOTE_IS_DIR=$(ssh "$REMOTE_HOST" "[ -d '$REMOTE_DIR' ] && echo 'YES' || echo 'NO'")
    local RSYNC_SRC=""

    if [ "$REMOTE_IS_DIR" = "YES" ]; then
        # It's a folder: calculate the content hash and force the trailing slash in rsync
        ssh "$REMOTE_HOST" "cd '$REMOTE_DIR' && find . -type f ! -path '*/.*' -exec sha256sum {} +" > "$LOCAL_DEST/checksums_remote.txt"
        RSYNC_SRC="${REMOTE_SRC%/}/"
    else
        # It's a single file: calculate the hash only for it
        ssh "$REMOTE_HOST" "cd \"\$(dirname '$REMOTE_DIR')\" && sha256sum \"\$(basename '$REMOTE_DIR')\"" > "$LOCAL_DEST/checksums_remote.txt"
        RSYNC_SRC="${REMOTE_SRC}"
    fi

    # Check if the checksum file was saved and is not empty (in case the target doesn't exist on the server)
    if [ ! -s "$LOCAL_DEST/checksums_remote.txt" ]; then
        echo "❌ Error: The file or folder was not found on the HPC or is empty."
        rm -f "$LOCAL_DEST/checksums_remote.txt"
        return 1
    fi
    echo "✅ Remote checksums mapped and saved locally."

    echo "---------------------------------------------------"
    echo "Starting secure transfer (rsync)..."

    "${CMD_RSYNC[@]}" "$RSYNC_SRC" "$LOCAL_DEST/"

    if [ $? -ne 0 ]; then
        echo "❌ Error or interruption during transfer."
        echo "Just run the command again to resume from where it left off."
        return 1
    fi
    echo "✅ Download complete."

    echo "---------------------------------------------------"
    echo "Verifying local data integrity..."
    
    cd "$LOCAL_DEST" || return 1
    
    # The local machine reads the generated text file and checks if the transfer was perfect
    "${CMD_HASH_CHECK[@]}" checksums_remote.txt

    if [ $? -eq 0 ]; then
        echo "---------------------------------------------------"
        echo "🎉 SUCCESS! Transfer cryptographically validated."
    else
        echo "---------------------------------------------------"
        echo "⚠️ WARNING: Verification failed for one or more files. Check the log above."
    fi

    cd "$ORIGINAL_DIR"
}

hpc_data_download "$@"
