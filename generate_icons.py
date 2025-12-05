import os
from PIL import Image
import json

def generate_icons(source_image_path, output_dir):
    # Ensure output directory exists
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Load source image
    img = Image.open(source_image_path)
    
    # Define required sizes for iPhone
    sizes = [
        (1024, "1024.png"),
        (180, "180.png"),  # 60pt @3x
        (120, "120.png"),  # 60pt @2x, 40pt @3x
        (87, "87.png"),    # 29pt @3x
        (80, "80.png"),    # 40pt @2x
        (60, "60.png"),    # 20pt @3x
        (58, "58.png"),    # 29pt @2x
        (40, "40.png")     # 20pt @2x
    ]

    generated_files = []

    print(f"Processing {source_image_path}...")

    for size, filename in sizes:
        # Resize image
        resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
        
        # Save
        output_path = os.path.join(output_dir, filename)
        resized_img.save(output_path)
        generated_files.append(filename)
        print(f"Generated {filename} ({size}x{size})")

    # Update Contents.json
    contents_json = {
        "images": [
            {
                "size": "20x20",
                "idiom": "iphone",
                "filename": "40.png",
                "scale": "2x"
            },
            {
                "size": "20x20",
                "idiom": "iphone",
                "filename": "60.png",
                "scale": "3x"
            },
            {
                "size": "29x29",
                "idiom": "iphone",
                "filename": "58.png",
                "scale": "2x"
            },
            {
                "size": "29x29",
                "idiom": "iphone",
                "filename": "87.png",
                "scale": "3x"
            },
            {
                "size": "40x40",
                "idiom": "iphone",
                "filename": "80.png",
                "scale": "2x"
            },
            {
                "size": "40x40",
                "idiom": "iphone",
                "filename": "120.png",
                "scale": "3x"
            },
            {
                "size": "60x60",
                "idiom": "iphone",
                "filename": "120.png",
                "scale": "2x"
            },
            {
                "size": "60x60",
                "idiom": "iphone",
                "filename": "180.png",
                "scale": "3x"
            },
            {
                "size": "1024x1024",
                "idiom": "ios-marketing",
                "filename": "1024.png",
                "scale": "1x"
            }
        ],
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }

    with open(os.path.join(output_dir, "Contents.json"), "w") as f:
        json.dump(contents_json, f, indent=4)
    
    print("Contents.json updated successfully!")

if __name__ == "__main__":
    SOURCE_IMAGE = "/Users/sail/.gemini/antigravity/brain/c91e19a0-c8b8-4afb-a1e4-aa1b7bca0b47/uploaded_image_1764751198258.png"
    OUTPUT_DIR = "/Users/sail/Desktop/UroSmart/frontend/UroSmart/Assets.xcassets/AppIcon.appiconset"
    
    generate_icons(SOURCE_IMAGE, OUTPUT_DIR)
