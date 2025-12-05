import requests
import json
import os
from PIL import Image, ImageDraw, ImageFont

# Path to the uploaded image
image_path = "/Users/sail/.gemini/antigravity/brain/da081aee-1757-4d83-81a2-255430ba67c9/uploaded_image_1764044946774.png"
url = "http://localhost:5000/api/detect"

if not os.path.exists(image_path):
    print(f"Error: Image not found at {image_path}")
    exit(1)

print(f"Sending image to {url} with confidence=0.10...")
try:
    with open(image_path, 'rb') as f:
        files = {'file': f}
        data = {'confidence': 0.10}
        response = requests.post(url, files=files, data=data)
    
    if response.status_code == 200:
        print("✅ Success!")
        result = response.json()
        print(json.dumps(result, indent=2))
        
        # Visualize results
        print("\n🎨 Generating annotated image...")
        
        # Open original image
        img = Image.open(image_path)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        draw = ImageDraw.Draw(img)
        width, height = img.size
        
        # Colors for different classes
        colors = {
            'calcium_oxalate': 'red',
            'squamous_cells': 'green',
            'triple_phosphate': 'blue',
            'uric_acid': 'yellow',
            'yeast': 'orange'
        }
        
        detection_results = result.get('detection_results', {})
        results_dict = detection_results.get('results', {})
        
        count = 0
        for class_name, data in results_dict.items():
            if not data.get('present', False):
                continue
                
            color = colors.get(class_name, 'white')
            detections = data.get('detections', [])
            
            for det in detections:
                count += 1
                bbox = det['bbox'] # [x1, y1, x2, y2] normalized
                conf = det['confidence']
                
                # Convert to pixel coordinates
                x1 = bbox[0] * width
                y1 = bbox[1] * height
                x2 = bbox[2] * width
                y2 = bbox[3] * height
                
                # Draw box
                draw.rectangle([x1, y1, x2, y2], outline=color, width=3)
                
                # Draw label
                label = f"{class_name}: {conf:.2f}"
                draw.text((x1, y1-10), label, fill=color)
        
        output_path = os.path.join(os.path.dirname(image_path), "annotated_result.png")
        img.save(output_path)
        print(f"✅ Saved annotated image to: {output_path}")
        print(f"Total detections visualized: {count}")
        
    else:
        print(f"❌ Failed with status {response.status_code}")
        print(response.text)
except Exception as e:
    print(f"❌ Error: {e}")
