#!/bin/bash

# Files to exclude from symlinking
EXCLUDE_FILES=(
    ".gitignore"
    "symlink-dotfiles.sh"
    "README.md"
    "LICENSE"
    ".zed"
)

DRY_RUN=true
if [ "$1" = "-f" ] || [ "$1" = "--force" ]; then
    DRY_RUN=false
    echo "FORCE MODE - Changes will be applied"
    echo ""
else
    echo "DRY RUN MODE - No changes will be made (use -f to apply)"
    echo ""
fi

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles.backup"

if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "Error: This script should be run from within the dotfiles git repository"
    exit 1
fi

cd "$DOTFILES_DIR"

echo "Creating symlinks for all tracked files..."
echo ""

git ls-files | while IFS= read -r file; do
    source_file="$DOTFILES_DIR/$file"
    target_file="$HOME/$file"

    # Check if file is in exclude list
    excluded=false
    for exclude in "${EXCLUDE_FILES[@]}"; do
        if [ "$file" = "$exclude" ]; then
            excluded=true
            # If excluded file exists as symlink, remove it
            if [ -L "$target_file" ]; then
                echo "[UNLINK] $target_file (excluded file, removing existing symlink)"
                if [ "$DRY_RUN" = false ]; then
                    rm "$target_file"
                fi
            else
                echo "[SKIP] $file (excluded from symlinking)"
            fi
            break
        fi
    done

    if [ "$excluded" = true ]; then
        continue
    fi

    if [ -f "$source_file" ]; then
        target_dir=$(dirname "$target_file")

        if [ ! -d "$target_dir" ]; then
            echo "[MKDIR] $target_dir"
            if [ "$DRY_RUN" = false ]; then
                mkdir -p "$target_dir"
            fi
        fi

        if [ -L "$target_file" ]; then
            # Check if symlink already points to the correct location
            link_target=$(readlink "$target_file")
            if [ "$link_target" = "$source_file" ]; then
                echo "[OK] $target_file (already linked correctly)"
                continue
            else
                echo "[UNLINK] $target_file (existing symlink points elsewhere)"
                if [ "$DRY_RUN" = false ]; then
                    rm "$target_file"
                fi
            fi
        elif [ -f "$target_file" ]; then
            backup_file="$BACKUP_DIR/$file"
            backup_file_dir=$(dirname "$backup_file")
            echo "[BACKUP] $target_file -> $backup_file"
            if [ "$DRY_RUN" = false ]; then
                mkdir -p "$backup_file_dir"
                mv "$target_file" "$backup_file"
            fi
        fi

        echo "[LINK] $file -> $target_file"
        if [ "$DRY_RUN" = false ]; then
            ln -sf "$source_file" "$target_file"
        fi
    fi
done

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete. Run with -f to apply changes."
else
    echo "Done! All dotfiles have been symlinked."
fi
