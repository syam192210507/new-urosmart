# UroSmart Backend API

Flask-based REST API for UroSmart iOS app with user authentication and medical report management.

## Features

- ✅ User authentication (signup/login with JWT)
- ✅ Secure password hashing (bcrypt)
- ✅ Medical report storage and retrieval
- ✅ Image upload handling
- ✅ PDF report management
- ✅ SQLite database (easy to switch to PostgreSQL)
- ✅ RESTful API design
- ✅ CORS enabled for iOS app

## Quick Start

### 1. Install Dependencies

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings (optional for development)
```

### 3. Run the Server

```bash
python app.py
```

Server will start at `http://localhost:5000`

## API Endpoints

### Authentication

#### Sign Up
```http
POST /api/auth/signup
Content-Type: application/json

{
  "phone_number": "+1234567890",
  "email": "user@example.com",
  "password": "securepassword"
}

Response:
{
  "message": "User created successfully",
  "user": {
    "id": 1,
    "phone_number": "+1234567890",
    "email": "user@example.com",
    "created_at": "2025-10-13T04:24:01.000000"
  },
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}

Response:
{
  "message": "Login successful",
  "user": {...},
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer <access_token>

Response:
{
  "user": {
    "id": 1,
    "phone_number": "+1234567890",
    "email": "user@example.com",
    "created_at": "2025-10-13T04:24:01.000000"
  }
}
```

### Medical Reports

#### Create Report
```http
POST /api/reports
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "case_number": "CASE-2025-001",
  "yeast_present": true,
  "yeast_count": 5,
  "yeast_confidence": 0.92,
  "triple_phosphate_present": false,
  "triple_phosphate_count": 0,
  "triple_phosphate_confidence": 0.0,
  "calcium_oxalate_present": true,
  "calcium_oxalate_count": 3,
  "calcium_oxalate_confidence": 0.85,
  "squamous_cells_present": false,
  "squamous_cells_count": 0,
  "squamous_cells_confidence": 0.0,
  "image_paths": "[\"image1.jpg\", \"image2.jpg\"]",
  "pdf_path": "report_001.pdf"
}

Response:
{
  "message": "Report created successfully",
  "report": {
    "id": 1,
    "case_number": "CASE-2025-001",
    "report_date": "2025-10-13T04:24:01.000000",
    "results": {...},
    "created_at": "2025-10-13T04:24:01.000000"
  }
}
```

#### Get All Reports
```http
GET /api/reports
Authorization: Bearer <access_token>

# Optional query parameters:
# ?case_number=CASE-2025
# ?start_date=2025-10-01T00:00:00
# ?end_date=2025-10-31T23:59:59

Response:
{
  "reports": [...],
  "count": 10
}
```

#### Get Single Report
```http
GET /api/reports/<report_id>
Authorization: Bearer <access_token>

Response:
{
  "report": {...}
}
```

#### Delete Report
```http
DELETE /api/reports/<report_id>
Authorization: Bearer <access_token>

Response:
{
  "message": "Report deleted successfully"
}
```

### File Upload

#### Upload Image
```http
POST /api/upload/image
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

file: <image_file>

Response:
{
  "message": "Image uploaded successfully",
  "filename": "uuid_filename.jpg",
  "path": "/api/files/images/uuid_filename.jpg"
}
```

#### Get Image
```http
GET /api/files/images/<filename>
Authorization: Bearer <access_token>

Response: Image file
```

#### Get PDF Report
```http
GET /api/files/reports/<filename>
Authorization: Bearer <access_token>

Response: PDF file
```

### Health Check

```http
GET /api/health

Response:
{
  "status": "healthy",
  "timestamp": "2025-10-13T04:24:01.000000"
}
```

## Database Schema

### Users Table
- `id` - Primary key
- `phone_number` - Unique phone number
- `email` - Unique email address
- `password_hash` - Bcrypt hashed password
- `created_at` - Account creation timestamp
- `updated_at` - Last update timestamp

### Medical Reports Table
- `id` - Primary key
- `user_id` - Foreign key to users
- `case_number` - Case identifier
- `report_date` - Report creation date
- `yeast_present`, `yeast_count`, `yeast_confidence`
- `triple_phosphate_present`, `triple_phosphate_count`, `triple_phosphate_confidence`
- `calcium_oxalate_present`, `calcium_oxalate_count`, `calcium_oxalate_confidence`
- `squamous_cells_present`, `squamous_cells_count`, `squamous_cells_confidence`
- `image_paths` - JSON array of image filenames
- `pdf_path` - PDF report filename
- `created_at` - Report creation timestamp

## iOS Integration

### 1. Create Network Service

Create a new Swift file `NetworkService.swift`:

```swift
import Foundation

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://localhost:5000/api"
    private var accessToken: String?
    
    func signup(phoneNumber: String, email: String, password: String) async throws -> User {
        let url = URL(string: "\(baseURL)/auth/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phone_number": phoneNumber,
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        self.accessToken = response.access_token
        return response.user
    }
    
    func login(email: String, password: String) async throws -> User {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        self.accessToken = response.access_token
        return response.user
    }
    
    func createReport(report: MedicalReportData) async throws -> MedicalReport {
        guard let token = accessToken else {
            throw NetworkError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/reports")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONEncoder().encode(report)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ReportResponse.self, from: data)
        
        return response.report
    }
    
    func getReports() async throws -> [MedicalReport] {
        guard let token = accessToken else {
            throw NetworkError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/reports")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ReportsResponse.self, from: data)
        
        return response.reports
    }
}

struct AuthResponse: Codable {
    let user: User
    let access_token: String
}

struct User: Codable {
    let id: Int
    let phone_number: String
    let email: String
    let created_at: String
}

enum NetworkError: Error {
    case unauthorized
}
```

### 2. Update SignUpView

```swift
Button(action: {
    Task {
        do {
            let user = try await NetworkService.shared.signup(
                phoneNumber: phoneNumber,
                email: emailAddress,
                password: password
            )
            await MainActor.run {
                isLoggedIn = true
            }
        } catch {
            print("Signup error: \(error)")
        }
    }
}) {
    Text("Sign Up")
        .font(.system(size: 16, weight: .medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
}
```

## Production Deployment

### Using Gunicorn

```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Using Docker

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
```

Build and run:

```bash
docker build -t urosmart-backend .
docker run -p 5000:5000 urosmart-backend
```

### Environment Variables for Production

```bash
export SECRET_KEY="your-production-secret-key"
export JWT_SECRET_KEY="your-production-jwt-secret"
export DATABASE_URL="postgresql://user:pass@host:5432/dbname"
export DEBUG=False
```

## Database Migration to PostgreSQL

1. Install PostgreSQL driver:
```bash
pip install psycopg2-binary
```

2. Update DATABASE_URL in `.env`:
```
DATABASE_URL=postgresql://username:password@localhost:5432/urosmart
```

3. Restart the server - tables will be created automatically

## Security Best Practices

1. **Change default secrets** - Update SECRET_KEY and JWT_SECRET_KEY in production
2. **Use HTTPS** - Always use SSL/TLS in production
3. **Rate limiting** - Add Flask-Limiter for API rate limiting
4. **Input validation** - Validate all user inputs
5. **SQL injection** - SQLAlchemy ORM prevents SQL injection
6. **Password security** - Bcrypt with salt rounds
7. **Token expiration** - JWT tokens expire after 30 days

## Testing

### Using cURL

```bash
# Sign up
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+1234567890","email":"test@example.com","password":"test123"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Get reports (replace TOKEN with actual token)
curl -X GET http://localhost:5000/api/reports \
  -H "Authorization: Bearer TOKEN"
```

### Using Postman

1. Import the API endpoints
2. Set up environment variables for base_url and access_token
3. Test all endpoints

## Troubleshooting

### Database locked error
- SQLite doesn't handle concurrent writes well
- Switch to PostgreSQL for production

### CORS errors from iOS
- Check CORS_ORIGINS in config
- Ensure proper headers are set

### JWT token expired
- Tokens expire after 30 days
- Implement refresh token flow if needed

### File upload fails
- Check MAX_CONTENT_LENGTH setting
- Ensure uploads directory exists and is writable

## Support

For issues or questions:
1. Check the logs: `tail -f app.log`
2. Verify database: `sqlite3 urosmart.db ".tables"`
3. Test endpoints: Use the health check endpoint first

## License

MIT License - See LICENSE file for details
