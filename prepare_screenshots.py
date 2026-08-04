import os
import shutil

locales = {
    "Italian (it)": "it",
    "Japanese (ja)": "ja",
    "Chinese Simplified (zh-Hans)": "zh-Hans"
}

for lang_dir, locale_code in locales.items():
    src_dir = os.path.join("./app_Screen_Render/apple", lang_dir)
    target_dir = os.path.join("./screenshots", locale_code)
    
    if os.path.exists(src_dir):
        os.makedirs(target_dir, exist_ok=True)
        for root, dirs, files in os.walk(src_dir):
            for file in files:
                if file.endswith(".png"):
                    src_path = os.path.join(root, file)
                    device_folder = os.path.basename(root)
                    clean_device = device_folder.replace(" ", "_")
                    new_filename = f"{clean_device}_{file}"
                    target_path = os.path.join(target_dir, new_filename)
                    shutil.copy2(src_path, target_path)

print("Screenshots prepared successfully.")
