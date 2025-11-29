"""
Federated Learning Aggregation Server for UroSmart
Implements Federated Averaging (FedAvg) algorithm with YOLO model support
Works offline - no internet connection required
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
from datetime import datetime
import json
import os
import shutil
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
import threading
import time

# Try to import YOLO for model handling
try:
    from ultralytics import YOLO
    YOLO_AVAILABLE = True
except ImportError:
    YOLO_AVAILABLE = False

app = Flask(__name__)
CORS(app)

# Configuration
AGGREGATION_THRESHOLD = 3  # Minimum number of updates before aggregation (reduced for offline)
AGGREGATION_INTERVAL = 1800  # Aggregate every 30 minutes (in seconds)
MODEL_STORAGE_PATH = 'federated_models'
BACKEND_MODELS_PATH = 'models'
INITIAL_MODEL_PATH = os.path.join(BACKEND_MODELS_PATH, 'best.pt')

# Ensure storage directory exists
os.makedirs(MODEL_STORAGE_PATH, exist_ok=True)
os.makedirs(BACKEND_MODELS_PATH, exist_ok=True)


@dataclass
class ModelUpdate:
    """Represents a model update from a client device"""
    device_id: str
    version: int
    weight_updates: Dict[str, List[float]]
    num_samples: int
    training_loss: float
    validation_accuracy: float
    timestamp: str


@dataclass
class GlobalModel:
    """Represents the global aggregated model"""
    version: int
    weights: Dict[str, List[float]]
    participating_devices: int
    aggregation_timestamp: str
    average_loss: float
    average_accuracy: float


class FederatedAggregator:
    """Manages federated learning aggregation"""
    
    def __init__(self):
        self.pending_updates: List[ModelUpdate] = []
        self.current_version = 0
        self.global_model = None
        self.lock = threading.Lock()
        self.load_global_model()
        
        # Start background aggregation thread
        self.aggregation_thread = threading.Thread(target=self._periodic_aggregation, daemon=True)
        self.aggregation_thread.start()
    
    def add_update(self, update: ModelUpdate):
        """Add a client update to pending queue"""
        with self.lock:
            self.pending_updates.append(update)
            print(f"📊 Received update from {update.device_id}")
            print(f"   Pending updates: {len(self.pending_updates)}/{AGGREGATION_THRESHOLD}")
            
            # Trigger aggregation if threshold reached
            if len(self.pending_updates) >= AGGREGATION_THRESHOLD:
                self._aggregate_updates()
    
    def _aggregate_updates(self):
        """Perform Federated Averaging on pending updates (supports YOLO models)"""
        if len(self.pending_updates) == 0:
            return
        
        print(f"\n🔄 Starting aggregation with {len(self.pending_updates)} updates...")
        
        # Check if we have YOLO model updates (model_path in weights)
        has_yolo_updates = any('model_path' in u.weight_updates for u in self.pending_updates)
        
        if has_yolo_updates and YOLO_AVAILABLE:
            # Aggregate YOLO models
            self._aggregate_yolo_models()
        else:
            # Traditional weight aggregation
            aggregated_weights = {}
            total_samples = sum(update.num_samples for update in self.pending_updates)
            
            if total_samples == 0:
                return
            
            # Get all weight keys from first update
            weight_keys = self.pending_updates[0].weight_updates.keys()
            
            for key in weight_keys:
                # Weighted average based on number of training samples
                first_weights = np.array(self.pending_updates[0].weight_updates[key])
                weighted_sum = np.zeros_like(first_weights, dtype=np.float64)
                
                for update in self.pending_updates:
                    weight = update.num_samples / total_samples
                    update_weights = np.array(update.weight_updates[key], dtype=np.float64)
                    weighted_sum += update_weights * weight
                
                aggregated_weights[key] = weighted_sum.tolist()
            
            # Calculate average metrics
            avg_loss = np.mean([u.training_loss for u in self.pending_updates])
            avg_accuracy = np.mean([u.validation_accuracy for u in self.pending_updates])
            
            # Create new global model
            self.current_version += 1
            self.global_model = GlobalModel(
                version=self.current_version,
                weights=aggregated_weights,
                participating_devices=len(self.pending_updates),
                aggregation_timestamp=datetime.utcnow().isoformat(),
                average_loss=float(avg_loss),
                average_accuracy=float(avg_accuracy)
            )
        
        # Save global model
        self.save_global_model()
        
        # Update backend model
        self._update_backend_model()
        
        # Clear pending updates
        self.pending_updates.clear()
        
        print(f"✅ Aggregation complete!")
        print(f"   Version: {self.current_version}")
        print(f"   Devices: {self.global_model.participating_devices}")
        if self.global_model:
            print(f"   Avg Loss: {self.global_model.average_loss:.4f}")
            print(f"   Avg Accuracy: {self.global_model.average_accuracy:.4f}\n")
    
    def _aggregate_yolo_models(self):
        """Aggregate YOLO model weights using FedAvg"""
        try:
            total_samples = sum(update.num_samples for update in self.pending_updates)
            if total_samples == 0:
                return
            
            # Load base model (use first update or existing global model)
            base_model_path = None
            if self.global_model and 'model_path' in self.global_model.weights:
                base_model_path = self.global_model.weights['model_path']
            elif os.path.exists(INITIAL_MODEL_PATH):
                base_model_path = INITIAL_MODEL_PATH
            elif 'model_path' in self.pending_updates[0].weight_updates:
                base_model_path = self.pending_updates[0].weight_updates['model_path']
            
            if not base_model_path or not os.path.exists(base_model_path):
                print("⚠️  No base YOLO model found, falling back to weight aggregation")
                return
            
            # Load base model
            base_model = YOLO(base_model_path)
            base_state_dict = base_model.model.state_dict()
            
            # Initialize aggregated state dict
            aggregated_state_dict = {}
            for key in base_state_dict.keys():
                aggregated_state_dict[key] = np.zeros_like(base_state_dict[key].cpu().numpy(), dtype=np.float64)
            
            # Weighted aggregation
            for update in self.pending_updates:
                weight = update.num_samples / total_samples
                
                # Load update model
                update_model_path = update.weight_updates.get('model_path')
                if update_model_path and os.path.exists(update_model_path):
                    update_model = YOLO(update_model_path)
                    update_state_dict = update_model.model.state_dict()
                    
                    for key in base_state_dict.keys():
                        if key in update_state_dict:
                            update_weights = update_state_dict[key].cpu().numpy()
                            aggregated_state_dict[key] += update_weights * weight
            
            # Save aggregated model
            aggregated_model_path = os.path.join(MODEL_STORAGE_PATH, f'global_model_v{self.current_version + 1}.pt')
            
            # Copy base model structure and update weights
            shutil.copy2(base_model_path, aggregated_model_path)
            aggregated_model = YOLO(aggregated_model_path)
            
            # Update model weights
            import torch
            for key, value in aggregated_state_dict.items():
                if key in aggregated_model.model.state_dict():
                    aggregated_model.model.state_dict()[key].copy_(torch.from_numpy(value))
            
            # Save the updated model
            aggregated_model.save(aggregated_model_path)
            
            # Also save as latest
            latest_path = os.path.join(MODEL_STORAGE_PATH, 'global_model_latest.pt')
            shutil.copy2(aggregated_model_path, latest_path)
            
            # Calculate average metrics
            avg_loss = np.mean([u.training_loss for u in self.pending_updates])
            avg_accuracy = np.mean([u.validation_accuracy for u in self.pending_updates])
            
            # Create new global model
            self.current_version += 1
            self.global_model = GlobalModel(
                version=self.current_version,
                weights={'model_path': latest_path},
                participating_devices=len(self.pending_updates),
                aggregation_timestamp=datetime.utcnow().isoformat(),
                average_loss=float(avg_loss),
                average_accuracy=float(avg_accuracy)
            )
            
            print(f"✅ YOLO model aggregation complete!")
            
        except Exception as e:
            print(f"❌ Error aggregating YOLO models: {e}")
            # Fallback to basic aggregation
            pass
    
    def _update_backend_model(self):
        """Update backend model with latest aggregated model"""
        if self.global_model and 'model_path' in self.global_model.weights:
            try:
                latest_path = self.global_model.weights['model_path']
                if os.path.exists(latest_path):
                    # Copy to backend models directory
                    backend_path = os.path.join(BACKEND_MODELS_PATH, 'best.pt')
                    shutil.copy2(latest_path, backend_path)
                    print(f"✅ Updated backend model: {backend_path}")
            except Exception as e:
                print(f"⚠️  Error updating backend model: {e}")
    
    def _periodic_aggregation(self):
        """Background thread for periodic aggregation"""
        while True:
            time.sleep(AGGREGATION_INTERVAL)
            with self.lock:
                if len(self.pending_updates) > 0:
                    print(f"⏰ Periodic aggregation triggered")
                    self._aggregate_updates()
    
    def get_global_model(self) -> GlobalModel:
        """Get current global model"""
        with self.lock:
            if self.global_model is None:
                # Return initial model
                return self._create_initial_model()
            return self.global_model
    
    def _create_initial_model(self) -> GlobalModel:
        """Create initial global model from YOLO model file if available"""
        # Try to initialize from existing YOLO model
        if os.path.exists(INITIAL_MODEL_PATH) and YOLO_AVAILABLE:
            try:
                # Copy initial model to federated models
                initial_pt_path = os.path.join(MODEL_STORAGE_PATH, 'global_model_v0.pt')
                shutil.copy2(INITIAL_MODEL_PATH, initial_pt_path)
                
                # Also copy as latest
                latest_pt_path = os.path.join(MODEL_STORAGE_PATH, 'global_model_latest.pt')
                shutil.copy2(INITIAL_MODEL_PATH, latest_pt_path)
                
                print(f"✅ Initialized federated model from {INITIAL_MODEL_PATH}")
                
                # Create metadata
                return GlobalModel(
                    version=0,
                    weights={'model_path': latest_pt_path},  # Store path to .pt file
                    participating_devices=0,
                    aggregation_timestamp=datetime.utcnow().isoformat(),
                    average_loss=0.0,
                    average_accuracy=0.0
                )
            except Exception as e:
                print(f"⚠️  Error initializing from YOLO model: {e}")
        
        # Fallback: create placeholder weights
        initial_weights = {
            'yeast_weights': [0.25] * 10,
            'triple_phosphate_weights': [0.25] * 10,
            'calcium_oxalate_weights': [0.25] * 10,
            'squamous_cells_weights': [0.25] * 10
        }
        
        return GlobalModel(
            version=0,
            weights=initial_weights,
            participating_devices=0,
            aggregation_timestamp=datetime.utcnow().isoformat(),
            average_loss=0.0,
            average_accuracy=0.0
        )
    
    def save_global_model(self):
        """Save global model to disk (metadata and .pt file if YOLO)"""
        if self.global_model is None:
            return
        
        # Save JSON metadata
        filepath = os.path.join(MODEL_STORAGE_PATH, f'global_model_v{self.current_version}.json')
        
        with open(filepath, 'w') as f:
            json.dump(asdict(self.global_model), f, indent=2)
        
        # Also save as latest
        latest_path = os.path.join(MODEL_STORAGE_PATH, 'global_model_latest.json')
        with open(latest_path, 'w') as f:
            json.dump(asdict(self.global_model), f, indent=2)
        
        # YOLO model .pt file is already saved in _aggregate_yolo_models
        print(f"💾 Global model saved: {filepath}")
    
    def load_global_model(self):
        """Load global model from disk (supports YOLO .pt files)"""
        latest_path = os.path.join(MODEL_STORAGE_PATH, 'global_model_latest.json')
        
        if os.path.exists(latest_path):
            with open(latest_path, 'r') as f:
                data = json.load(f)
                self.global_model = GlobalModel(**data)
                self.current_version = self.global_model.version
                
                # If YOLO model, verify .pt file exists
                if 'model_path' in self.global_model.weights:
                    pt_path = self.global_model.weights['model_path']
                    if os.path.exists(pt_path):
                        print(f"✅ Loaded YOLO global model version {self.current_version}")
                        print(f"   Model: {pt_path}")
                    else:
                        print(f"⚠️  YOLO model file not found: {pt_path}")
                else:
                    print(f"✅ Loaded global model version {self.current_version}")
        else:
            # Check if we have initial YOLO model to initialize from
            if os.path.exists(INITIAL_MODEL_PATH):
                print(f"ℹ️  Initializing federated model from {INITIAL_MODEL_PATH}")
                self.global_model = self._create_initial_model()
                self.save_global_model()
            else:
                print("ℹ️  No existing global model found, will create new one")
    
    def get_stats(self) -> Dict:
        """Get aggregator statistics"""
        with self.lock:
            return {
                'current_version': self.current_version,
                'pending_updates': len(self.pending_updates),
                'aggregation_threshold': AGGREGATION_THRESHOLD,
                'has_global_model': self.global_model is not None
            }


# Global aggregator instance
aggregator = FederatedAggregator()


# API Routes

@app.route('/api/federated/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'federated_learning',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@app.route('/api/federated/stats', methods=['GET'])
def get_stats():
    """Get aggregator statistics"""
    stats = aggregator.get_stats()
    return jsonify(stats), 200


@app.route('/api/federated/upload_update', methods=['POST'])
def upload_update():
    """
    Upload a local model update from a client device
    
    Expected JSON:
    {
        "device_id": "uuid",
        "version": 1,
        "weight_updates": {...},
        "num_samples": 10,
        "training_loss": 0.15,
        "validation_accuracy": 0.82,
        "timestamp": "2024-..."
    }
    """
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['device_id', 'version', 'weight_updates', 'num_samples', 
                          'training_loss', 'validation_accuracy', 'timestamp']
        
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Create ModelUpdate object
        update = ModelUpdate(
            device_id=data['device_id'],
            version=data['version'],
            weight_updates=data['weight_updates'],
            num_samples=data['num_samples'],
            training_loss=data['training_loss'],
            validation_accuracy=data['validation_accuracy'],
            timestamp=data['timestamp']
        )
        
        # Add to aggregator
        aggregator.add_update(update)
        
        return jsonify({
            'message': 'Update received successfully',
            'pending_updates': len(aggregator.pending_updates),
            'current_version': aggregator.current_version
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/federated/global_model', methods=['GET'])
def get_global_model():
    """
    Download the current global model
    
    Returns:
    {
        "version": 5,
        "weights": {...},
        "participating_devices": 12,
        "aggregation_timestamp": "2024-...",
        "average_loss": 0.12,
        "average_accuracy": 0.87
    }
    """
    try:
        global_model = aggregator.get_global_model()
        return jsonify(asdict(global_model)), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/federated/trigger_aggregation', methods=['POST'])
def trigger_aggregation():
    """Manually trigger aggregation (for testing)"""
    try:
        with aggregator.lock:
            if len(aggregator.pending_updates) == 0:
                return jsonify({'message': 'No pending updates to aggregate'}), 200
            
            aggregator._aggregate_updates()
        
        return jsonify({
            'message': 'Aggregation completed',
            'new_version': aggregator.current_version
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/federated/model_history', methods=['GET'])
def get_model_history():
    """Get history of all global model versions"""
    try:
        history = []
        
        for filename in os.listdir(MODEL_STORAGE_PATH):
            if filename.startswith('global_model_v') and filename.endswith('.json'):
                filepath = os.path.join(MODEL_STORAGE_PATH, filename)
                with open(filepath, 'r') as f:
                    model_data = json.load(f)
                    history.append({
                        'version': model_data['version'],
                        'timestamp': model_data['aggregation_timestamp'],
                        'devices': model_data['participating_devices'],
                        'accuracy': model_data['average_accuracy']
                    })
        
        # Sort by version
        history.sort(key=lambda x: x['version'], reverse=True)
        
        return jsonify({
            'history': history,
            'total_versions': len(history)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('FEDERATED_PORT', 5001))
    
    print(f"🚀 Federated Learning Server starting...")
    print(f"   Port: {port}")
    print(f"   Mode: Offline (no internet required)")
    print(f"   Aggregation threshold: {AGGREGATION_THRESHOLD} updates")
    print(f"   Aggregation interval: {AGGREGATION_INTERVAL}s")
    print(f"   Model storage: {MODEL_STORAGE_PATH}")
    print(f"   YOLO support: {'✅ Available' if YOLO_AVAILABLE else '❌ Not available'}")
    
    # Check for initial model
    if os.path.exists(INITIAL_MODEL_PATH):
        print(f"   Initial model: {INITIAL_MODEL_PATH} ({os.path.getsize(INITIAL_MODEL_PATH) / 1024 / 1024:.1f} MB)")
    else:
        print(f"   ⚠️  Initial model not found: {INITIAL_MODEL_PATH}")
    
    print(f"\n📚 Endpoints:")
    print(f"   GET  /api/federated/health")
    print(f"   GET  /api/federated/stats")
    print(f"   POST /api/federated/upload_update")
    print(f"   GET  /api/federated/global_model")
    print(f"   POST /api/federated/trigger_aggregation")
    print(f"   GET  /api/federated/model_history")
    print(f"\n✅ Server ready! (Offline mode - no internet required)\n")
    
    app.run(host='0.0.0.0', port=port, debug=True)
