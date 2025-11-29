# Federated Learning - Automatic & Invisible

Federated learning is now **automatically integrated** into your backend. It works seamlessly based on internet connectivity - **no configuration needed**.

## 🎯 How It Works

### Automatic Behavior
- ✅ **No user configuration** - Works invisibly in the background
- ✅ **Internet-based** - Automatically enabled when online, disabled when offline
- ✅ **Automatic aggregation** - Collects updates and aggregates them using Federated Averaging (FedAvg)
- ✅ **Background processing** - Runs in background threads, no impact on API performance

### Connectivity Detection
The system automatically:
- Checks internet connectivity every 60 seconds
- Only accepts/processes updates when online
- Queues updates when offline, processes them when connection returns
- Never blocks or requires user action

## 📡 API Endpoints (For iOS App Integration)

### 1. Submit Model Update
**POST** `/api/model/update`

Client apps automatically submit local model updates when online.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{
  "device_id": "device-uuid",
  "version": 1,
  "weight_updates": {
    "layer1": [0.1, 0.2, 0.3, ...],
    "layer2": [0.4, 0.5, 0.6, ...]
  },
  "num_samples": 50,
  "training_loss": 0.15,
  "validation_accuracy": 0.82
}
```

**Response:**
```json
{
  "status": "aggregated",  // or "pending" or "offline"
  "message": "Update received and aggregated",
  "new_version": 4,
  "pending_count": 0
}
```

### 2. Get Latest Model
**GET** `/api/model/latest`

Clients check periodically for updated global model.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (when online and model available):**
```json
{
  "model_available": true,
  "version": 4,
  "weights": {
    "layer1": [0.12, 0.23, 0.34, ...],
    "layer2": [0.45, 0.56, 0.67, ...]
  },
  "aggregation_timestamp": "2025-11-17T06:10:00",
  "participating_devices": 3,
  "average_accuracy": 0.85
}
```

**Response (when offline):**
```json
{
  "model_available": false,
  "status": "offline",
  "message": "Model available but device is offline"
}
```

### 3. Check for Updates
**GET** `/api/model/check?version=3`

Lightweight endpoint for checking if new model version is available.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `version` (optional): Current client model version (default: 0)

**Response:**
```json
{
  "has_update": true,
  "latest_version": 4,
  "online": true,
  "client_version": 3
}
```

## 🔄 Automatic Aggregation

The system automatically:
1. **Collects updates** from client devices (minimum 3 updates required)
2. **Aggregates using FedAvg** - Weighted average based on number of training samples
3. **Creates global model** - New version with aggregated weights
4. **Updates backend detector** - Automatically loads new model for server-side detection
5. **Saves to disk** - Persists in `federated_models/global_model_latest.json`

**Aggregation Triggers:**
- When threshold reached (3+ updates) and online
- Every 30 minutes if threshold met and online
- Automatically when connection returns after being offline

## 📱 iOS Integration

Add these methods to your `NetworkService.swift`:

```swift
// MARK: - Federated Learning (Automatic)

func submitModelUpdate(
    deviceId: String,
    version: Int,
    weightUpdates: [String: [Double]],
    numSamples: Int,
    trainingLoss: Double,
    validationAccuracy: Double
) async throws {
    guard let token = accessToken else {
        throw NetworkError.unauthorized
    }
    
    let url = URL(string: "\(baseURL)/model/update")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let body: [String: Any] = [
        "device_id": deviceId,
        "version": version,
        "weight_updates": weightUpdates,
        "num_samples": numSamples,
        "training_loss": trainingLoss,
        "validation_accuracy": validationAccuracy
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (_, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }
    
    guard httpResponse.statusCode == 200 else {
        throw NetworkError.serverError(httpResponse.statusCode)
    }
}

func checkModelUpdates(version: Int) async throws -> ModelUpdateCheck {
    guard let token = accessToken else {
        throw NetworkError.unauthorized
    }
    
    var urlComponents = URLComponents(string: "\(baseURL)/model/check")!
    urlComponents.queryItems = [URLQueryItem(name: "version", value: "\(version)")]
    
    var request = URLRequest(url: urlComponents.url!)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }
    
    guard httpResponse.statusCode == 200 else {
        throw NetworkError.serverError(httpResponse.statusCode)
    }
    
    return try JSONDecoder().decode(ModelUpdateCheck.self, from: data)
}

func getLatestModel() async throws -> GlobalModel? {
    guard let token = accessToken else {
        throw NetworkError.unauthorized
    }
    
    let url = URL(string: "\(baseURL)/model/latest")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }
    
    guard httpResponse.statusCode == 200 else {
        throw NetworkError.serverError(httpResponse.statusCode)
    }
    
    let modelResponse = try JSONDecoder().decode(ModelResponse.self, from: data)
    
    return modelResponse.model_available ? modelResponse : nil
}
```

**Automatic Polling (Background):**
```swift
// In your app's background task or when app becomes active
Task {
    do {
        // Check for updates every 5 minutes
        let updateCheck = try await NetworkService.shared.checkModelUpdates(version: currentModelVersion)
        
        if updateCheck.has_update && updateCheck.online {
            // Download and apply new model
            if let newModel = try await NetworkService.shared.getLatestModel() {
                // Apply new model weights to local Core ML model
                applyModelWeights(newModel.weights)
                currentModelVersion = newModel.version
            }
        }
    } catch {
        // Silently fail - federated learning is optional
        print("Federated learning check failed: \(error)")
    }
}
```

## 🔒 Privacy & Security

- ✅ **No raw data** - Only model weight updates are sent, never images or user data
- ✅ **User authentication** - All endpoints require JWT token
- ✅ **Automatic processing** - No user interaction needed
- ✅ **Offline support** - Works offline, syncs when connection returns

## 📊 Model Storage

Federated models are stored in:
- `federated_models/global_model_latest.json` - Latest aggregated model
- `federated_models/global_model_v{N}.json` - Version history

If converted to PyTorch format:
- `federated_models/global_model_latest.pt` - For backend ML detector

## ⚙️ Configuration (Internal Only)

These settings are automatic and not exposed to users:
- `AGGREGATION_THRESHOLD = 3` - Minimum updates before aggregation
- `AGGREGATION_INTERVAL = 1800` - Check every 30 minutes
- `CHECK_INTERNET_INTERVAL = 60` - Check connectivity every minute

## ✅ Status

- ✅ Federated learning module created
- ✅ Internet connectivity detection working
- ✅ Automatic aggregation implemented
- ✅ Integrated into main backend API
- ✅ Endpoints tested and working
- ✅ No user configuration needed
- ✅ Works automatically based on connection

## 🚀 Next Steps

1. **iOS App Integration:**
   - Add federated learning methods to `NetworkService.swift`
   - Implement automatic model update submission
   - Add periodic model update checking

2. **Model Weight Extraction:**
   - Extract weights from Core ML model after local training
   - Format as JSON for submission

3. **Testing:**
   - Test with multiple devices
   - Verify aggregation works correctly
   - Confirm offline/online behavior

The federated learning system is **ready to use** and works **automatically** based on internet connectivity!

