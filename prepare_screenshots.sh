#!/bin/bash
mkdir -p ./screenshots/it
mkdir -p ./screenshots/ja
mkdir -p ./screenshots/zh-Hans

# Map source folders to target locale folders
declare -A locales
locales=( ["Italian (it)"]="it" ["Japanese (ja)"]="ja" ["Chinese Simplified (zh-Hans)"]="zh-Hans" )

for lang_dir in "${!locales[@]}"; do
  locale_code=${locales[$lang_dir]}
  src_dir="./app_Screen_Render/apple/$lang_dir"
  
  if [ -d "$src_dir" ]; then
    # Iterate through all device subdirectories
    find "$src_dir" -type f -name "*.png" | while read -r file; do
      # Get the device folder name (e.g. "iPhones  6.5")
      device_folder=$(basename "$(dirname "$file")")
      # Get the filename (e.g. "01.png")
      filename=$(basename "$file")
      
      # Clean up the device folder name for the new filename (replace spaces with underscores)
      clean_device=${device_folder// /_}
      
      # Construct new unique filename
      new_filename="${clean_device}_${filename}"
      
      # Copy the file
      cp "$file" "./screenshots/$locale_code/$new_filename"
    done
  fi
done

echo "Screenshots prepared."
