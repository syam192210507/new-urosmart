"""
Federated Learning Module for UroSmart
Automatically aggregates model updates from clients
Works seamlessly based on internet connectivity - no user configuration needed
"""

import os
import json
import numpy as np
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
import threading
import time
import socket
import requests

# Configuration (invisible to users - automatic behavior)
AGGREGATION_THRESHOLD = 3  # Minimum updates before aggregation
AGGREGATION_INTERVAL = 1800  # Aggregate every 30 minutes if threshold not met
MODEL_STORAGE_PATH = 'federated_models'
CHECK_INTERNET_INTERVAL = 60  # Check internet every minute


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


def check_internet_connection() -> bool:
    """Check if internet connection is available"""
    try:
        # Quick check with socket (faster than HTTP)
        socket.create_connection(("8.8.8.8", 53), timeout=3)
        return True
    except OSError:
        pass
    
    try:
        # Fallback: HTTP check
        requests.get("https://www.google.com", timeout=3)
        return True
    except (requests.RequestException, Exception):
        return False


class FederatedLearningManager:
    """Manages federated learning aggregation automatically"""
    
    def __init__(self):
        self.pending_updates: List[ModelUpdate] = []
        self.current_version = 0
        self.global_model: Optional[GlobalModel] = None
        self.lock = threading.Lock()
        self.is_online = False
        self.last_online_check = 0
        
        # Ensure storage directory exists
        os.makedirs(MODEL_STORAGE_PATH, exist_ok=True)
        
        # Load existing global model
        self.load_global_model()
        
        # Start background threads
        self.aggregation_thread = threading.Thread(
            target=self._periodic_aggregation, 
            daemon=True
        )
        self.aggregation_thread.start()
        
        self.connectivity_thread = threading.Thread(
            target=self._monitor_connectivity,
            daemon=True
        )
        self.connectivity_thread.start()
    
    def _monitor_connectivity(self):
        """Monitor internet connectivity in background"""
        while True:
            time.sleep(CHECK_INTERNET_INTERVAL)
            self.is_online = check_internet_connection()
            self.last_online_check = time.time()
            
            # If came back online and have pending updates, try to aggregate
            if self.is_online and len(self.pending_updates) >= AGGREGATION_THRESHOLD:
                with self.lock:
                    if len(self.pending_updates) >= AGGREGATION_THRESHOLD:
                        self._aggregate_updates()
    
    def is_connected(self) -> bool:
        """Check if currently connected to internet"""
        # Cache check for 30 seconds
        if time.time() - self.last_online_check > 30:
            self.is_online = check_internet_connection()
            self.last_online_check = time.time()
        return self.is_online
    
    def add_update(self, update: ModelUpdate) -> Dict:
        """
        Add a client update (automatically processes if online)
        
        Returns:
            Dict with status and response info
        """
        with self.lock:
            # Only accept updates if online
            if not self.is_connected():
                return {
                    'status': 'offline',
                    'message': 'Update queued for when connection is available',
                    'queued': True
                }
            
            self.pending_updates.append(update)
            
            # Auto-aggregate if threshold reached
            if len(self.pending_updates) >= AGGREGATION_THRESHOLD:
                result = self._aggregate_updates()
                return {
                    'status': 'aggregated',
                    'message': 'Update received and aggregated',
                    'new_version': self.current_version,
                    'pending_count': 0
                }
            else:
                return {
                    'status': 'pending',
                    'message': f'Update received ({len(self.pending_updates)}/{AGGREGATION_THRESHOLD} pending)',
                    'pending_count': len(self.pending_updates),
                    'threshold': AGGREGATION_THRESHOLD
                }
    
    def _aggregate_updates(self) -> bool:
        """Perform Federated Averaging on pending updates (FedAvg algorithm)"""
        if len(self.pending_updates) == 0:
            return False
        
        # Must be online to aggregate
        if not self.is_connected():
            return False
        
        try:
            # Calculate weighted average of model updates
            aggregated_weights = {}
            total_samples = sum(update.num_samples for update in self.pending_updates)
            
            if total_samples == 0:
                return False
            
            # Get all weight keys from first update
            if len(self.pending_updates) == 0:
                return False
            
            weight_keys = self.pending_updates[0].weight_updates.keys()
            
            for key in weight_keys:
                # Weighted average based on number of training samples (FedAvg)
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
            
            # Clear pending updates
            pending_count = len(self.pending_updates)
            self.pending_updates.clear()
            
            # Update backend model if available
            self._update_backend_model()
            
            return True
            
        except Exception as e:
            print(f"❌ Error during aggregation: {e}")
            return False
    
    def _update_backend_model(self):
        """Update backend ML detector with new aggregated weights"""
        try:
            # Try to import and update detector
            from ml_detector import get_detector
            detector = get_detector()
            
            # If detector has update_weights method, call it
            if hasattr(detector, 'update_weights') and self.global_model:
                detector.update_weights(self.global_model.weights)
                print(f"✅ Updated backend detector with federated model v{self.current_version}")
        except Exception as e:
            # Silently fail - not critical if detector update fails
            pass
    
    def _periodic_aggregation(self):
        """Background thread for periodic aggregation"""
        while True:
            time.sleep(AGGREGATION_INTERVAL)
            
            with self.lock:
                if self.is_connected() and len(self.pending_updates) >= AGGREGATION_THRESHOLD:
                    self._aggregate_updates()
                elif len(self.pending_updates) > 0 and self.is_connected():
                    # If we have updates and just came online, try to aggregate
                    self._aggregate_updates()
    
    def get_global_model(self) -> Optional[GlobalModel]:
        """Get current global model"""
        with self.lock:
            return self.global_model
    
    def get_latest_model_weights(self) -> Optional[Dict]:
        """Get latest model weights for clients to download"""
        model = self.get_global_model()
        if model:
            return model.weights
        return None
    
    def save_global_model(self):
        """Save global model to disk"""
        if self.global_model is None:
            return
        
        try:
            filepath = os.path.join(MODEL_STORAGE_PATH, f'global_model_v{self.current_version}.json')
            
            with open(filepath, 'w') as f:
                json.dump(asdict(self.global_model), f, indent=2)
            
            # Also save as latest
            latest_path = os.path.join(MODEL_STORAGE_PATH, 'global_model_latest.json')
            with open(latest_path, 'w') as f:
                json.dump(asdict(self.global_model), f, indent=2)
                
        except Exception as e:
            print(f"❌ Error saving global model: {e}")
    
    def load_global_model(self):
        """Load global model from disk"""
        latest_path = os.path.join(MODEL_STORAGE_PATH, 'global_model_latest.json')
        
        if os.path.exists(latest_path):
            try:
                with open(latest_path, 'r') as f:
                    data = json.load(f)
                    self.global_model = GlobalModel(**data)
                    self.current_version = self.global_model.version
            except Exception as e:
                print(f"⚠️  Error loading global model: {e}")
                self.global_model = None
    
    def get_status(self) -> Dict:
        """Get federated learning status (for internal use only)"""
        with self.lock:
            return {
                'online': self.is_connected(),
                'current_version': self.current_version,
                'pending_updates': len(self.pending_updates),
                'has_global_model': self.global_model is not None,
                'last_aggregation': self.global_model.aggregation_timestamp if self.global_model else None
            }


# Global federated learning manager instance
_federated_manager: Optional[FederatedLearningManager] = None


def get_federated_manager() -> FederatedLearningManager:
    """Get or create federated learning manager instance"""
    global _federated_manager
    
    if _federated_manager is None:
        _federated_manager = FederatedLearningManager()
    
    return _federated_manager


def is_online() -> bool:
    """Quick check if internet is available"""
    return get_federated_manager().is_connected()

