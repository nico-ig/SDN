#!/bin/bash
export PYTHONWARNINGS="ignore"

# pipx install openai-whisper --pip-args="--extra-index-url https://download.pytorch.org/whl/cpu"

# Check if a directory argument was provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <path_to_directory> [language]"
    echo "Exemple: $0 /media/usb <pt/en> <base/small/medium/large/large-v3>"
    echo "Use <model>.en to english audios with accent"
    exit 1
fi

TARGET_DIR="$1"
LANG="$2"
MODEL="$3"

# Check if the provided argument is actually a directory
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

# Define output directories INSIDE current directory
TRANSCRIPT_DIR="transcripts"
ORIGINAL_DIR="recordings" # Changed name to match usage below

# Create the subfolders
mkdir -p "$TRANSCRIPT_DIR" "$ORIGINAL_DIR"

echo "Processing files in: $TARGET_DIR"

# Enable nullglob
shopt -s nullglob nocaseglob

# Flag to track if we actually did anything
CHANGES_MADE=false

# Initialize an empty array to track specific files
FILES_TO_STAGE=()

# Loop through all .wav files in the target directory
for FILE_PATH in "$TARGET_DIR"/*.wav; do
    
    # Define the variables you use below
    FILENAME=$(basename "$FILE_PATH")
    BASE_NAME="${FILENAME%.*}"
    
    echo "------------------------------------------------"
    echo "Found audio: $FILENAME"
    echo "Transcribing..."
    
    # Use FILE_PATH (full path) to read, otherwise it won't find the file
    whisper "$FILE_PATH" --model "$MODEL" --output_format txt --output_dir "$TRANSCRIPT_DIR" --language "$LANG" --threads 3
    
    # Check if Whisper finished successfully
    if [ $? -eq 0 ]; then
        echo "✅ Success! Moving original file..."
        
        # Use FILENAME variable we created
        mv "$FILE_PATH" "$ORIGINAL_DIR/"

        # The new path (where the audio is now)
        FILES_TO_STAGE+=("$ORIGINAL_DIR/$FILENAME")
        # The new transcripts
        FILES_TO_STAGE+=("$TRANSCRIPT_DIR/$BASE_NAME"*)

        CHANGES_MADE=true
    else
        echo "❌ Error processing $FILENAME. File was NOT moved."
    fi

done

echo "------------------------------------------------"
echo "Batch processing finished."

# Git Operations
if [ "$CHANGES_MADE" = true ]; then
    echo "Changes detected. Preparing to commit..."
    
    # Add changes (new transcripts and moved audio files)
    git add "${FILES_TO_STAGE[@]}"
    
    # Commit with a timestamp
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    git commit -m "Auto-transcription batch: $TIMESTAMP"
    
    # Push to remote
    echo "Pushing to remote repository..."
    git push
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully pushed to remote."
    else
        echo "⚠️ Error pushing to remote. Check your internet or git credentials."
    fi
    
else
    echo "No files were transcribed. Nothing to commit."
fi
