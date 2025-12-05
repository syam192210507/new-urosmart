"""
TensorFlow Lite YOLO Detector for Urine Microscopy
Replaces PyTorch/Ultralytics for unified model format
"""

import os
import numpy as np
from PIL import Image
import io
from typing import List, Dict, Tuple

try:
    import tensorflow as tf
    TF_AVAILABLE = True
    Interpreter = tf.lite.Interpreter
except ImportError:
    try:
        import tflite_runtime.interpreter as tflite
        TF_AVAILABLE = True
        Interpreter = tflite.Interpreter
    except ImportError:
        TF_AVAILABLE = False
        Interpreter = None


class TFLiteYOLODetector:
    """TFLite YOLO detector for microscopy images"""
    
    # Class mapping (matches training order)
    CLASS_NAMES = {
        0: 'calcium_oxalate',
        1: 'squamous_cells',
        2: 'triple_phosphate',
        3: 'uric_acid',
        4: 'yeast'
    }
    
    def __init__(self, model_path: str = None):
        """Initialize TFLite detector"""
        if model_path is None:
            # Default to models/best.tflite relative to this file
            base_dir = os.path.dirname(os.path.abspath(__file__))
            model_path = os.path.join(base_dir, 'models', 'best.tflite')
            
        self.model_path = model_path
        self.interpreter = None
        self.input_details = None
        self.output_details = None
        self.input_shape = None
        
        if os.path.exists(model_path):
            self.load_model()
    
    def load_model(self):
        """Load TFLite model"""
        if not TF_AVAILABLE:
            print("❌ TensorFlow not available")
            return False
        
        try:
            self.interpreter = Interpreter(model_path=self.model_path)
            self.interpreter.allocate_tensors()
            
            self.input_details = self.interpreter.get_input_details()
            self.output_details = self.interpreter.get_output_details()
            self.input_shape = self.input_details[0]['shape']
            
            print(f"✅ TFLite model loaded: {self.model_path}")
            print(f"   Input shape: {self.input_shape}")
            print(f"   Output shape: {self.output_details[0]['shape']}")
            return True
            
        except Exception as e:
            print(f"❌ Error loading TFLite model: {e}")
            return False
    
    def preprocess_image(self, image: Image.Image) -> np.ndarray:
        """Preprocess image for YOLO inference"""
        # Resize to 640x640
        img_resized = image.resize((640, 640), Image.LANCZOS)
        
        # Convert to numpy array and normalize to [0, 1]
        img_array = np.array(img_resized, dtype=np.float32) / 255.0
        
        # Add batch dimension: [1, 640, 640, 3]
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
    
    def postprocess_yolo(self, output: np.ndarray, conf_threshold: float = 0.55) -> Dict:
        """
        Postprocess YOLO output [1, 9, 8400]
        Same logic as iOS TFLiteWrapper
        """
        # Remove batch dimension: [9, 8400]
        predictions = output[0]
        
        num_classes = 5
        num_predictions = 8400
        
        detections_by_class = {class_id: [] for class_id in range(num_classes)}
        
        # Iterate through 8400 predictions
        for i in range(num_predictions):
            # Get class scores for this prediction
            class_scores = predictions[4:9, i]  # 5 class scores
            
            # Find best class
            max_conf = float(np.max(class_scores))
            best_class = int(np.argmax(class_scores))
            
            if max_conf > conf_threshold:
                # Extract bounding box (center coords + size)
                cx = float(predictions[0, i])
                cy = float(predictions[1, i])
                w = float(predictions[2, i])
                h = float(predictions[3, i])
                
                # Convert to x1, y1, x2, y2 (already normalized [0, 1])
                x1 = cx - w/2
                y1 = cy - h/2
                x2 = cx + w/2
                y2 = cy + h/2
                
                detections_by_class[best_class].append({
                    'confidence': max_conf,
                    'bbox': [x1, y1, x2, y2]
                })
        
        # Apply NMS per class (simplified - just take top detections)
        final_detections = {}
        
        for class_id in range(num_classes):
            class_dets = detections_by_class[class_id]
            
            if len(class_dets) > 0:
                # Sort by confidence
                class_dets.sort(key=lambda x: x['confidence'], reverse=True)
                
                # NMS: keep non-overlapping boxes
                nms_dets = self._nms(class_dets, iou_threshold=0.45)
                
                # Calculate average confidence
                avg_conf = sum(d['confidence'] for d in nms_dets) / len(nms_dets)
                
                final_detections[self.CLASS_NAMES[class_id]] = {
                    'present': True,
                    'count': len(nms_dets),
                    'confidence': round(avg_conf, 3),
                    'detections': nms_dets[:10]  # Limit to 10
                }
            else:
                final_detections[self.CLASS_NAMES[class_id]] = {
                    'present': False,
                    'count': 0,
                    'confidence': 0.0,
                    'detections': []
                }
        
        return final_detections
    
    def _nms(self, detections: List[Dict], iou_threshold: float = 0.45) -> List[Dict]:
        """Simple Non-Maximum Suppression"""
        if len(detections) == 0:
            return []
        
        # Sort by confidence
        detections = sorted(detections, key=lambda x: x['confidence'], reverse=True)
        
        keep = []
        
        while len(detections) > 0:
            # Keep highest confidence detection
            best = detections.pop(0)
            keep.append(best)
            
            # Remove overlapping detections
            detections = [
                d for d in detections
                if self._iou(best['bbox'], d['bbox']) < iou_threshold
            ]
        
        return keep
    
    def _iou(self, box1: List[float], box2: List[float]) -> float:
        """Calculate Intersection over Union"""
        x1_min, y1_min, x1_max, y1_max = box1
        x2_min, y2_min, x2_max, y2_max = box2
        
        # Intersection
        inter_xmin = max(x1_min, x2_min)
        inter_ymin = max(y1_min, y2_min)
        inter_xmax = min(x1_max, x2_max)
        inter_ymax = min(y1_max, y2_max)
        
        inter_width = max(0, inter_xmax - inter_xmin)
        inter_height = max(0, inter_ymax - inter_ymin)
        inter_area = inter_width * inter_height
        
        # Union
        box1_area = (x1_max - x1_min) * (y1_max - y1_min)
        box2_area = (x2_max - x2_min) * (y2_max - y2_min)
        union_area = box1_area + box2_area - inter_area
        
        if union_area == 0:
            return 0
        
        return inter_area / union_area
    
    def detect(self, image_data: bytes, confidence_threshold: float = 0.55) -> Dict:
        """
        Detect objects in microscopy image
        
        Args:
            image_data: Image bytes
            confidence_threshold: Minimum confidence (default 0.40)
            
        Returns:
            Dictionary with detection results
        """
        if self.interpreter is None:
            return {
                'success': False,
                'error': 'TFLite model not loaded',
                'results': {}
            }
        
        try:
            # Load image
            image = Image.open(io.BytesIO(image_data))
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Preprocess
            input_data = self.preprocess_image(image)
            
            # Run inference
            self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
            self.interpreter.invoke()
            
            # Get output
            output_data = self.interpreter.get_tensor(self.output_details[0]['index'])
            
            # Postprocess
            detections = self.postprocess_yolo(output_data, confidence_threshold)
            
            return {
                'success': True,
                'results': detections,
                'total_objects': sum(d['count'] for d in detections.values())
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Detection failed: {str(e)}',
                'results': {}
            }


# Singleton instance
_detector = None

def get_detector(model_path: str = None) -> TFLiteYOLODetector:
    """Get or create TFLite detector instance"""
    global _detector
    
    if _detector is None:
        _detector = TFLiteYOLODetector(model_path)
    
    return _detector


def detect_objects(image_data: bytes, confidence_threshold: float = 0.55) -> Dict:
    """Convenience function for detection"""
    detector = get_detector()
    return detector.detect(image_data, confidence_threshold)
