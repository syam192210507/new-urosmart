"""
UroSmart Backend API
Flask-based REST API for user authentication and medical report management
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from flask_mail import Mail, Message
from datetime import datetime, timedelta
import os
from werkzeug.utils import secure_filename
import uuid
from itsdangerous import URLSafeTimedSerializer

import random
from twilio.rest import Client

# Import TFLite detector (unified model format)
try:
    from tflite_detector import detect_objects, get_detector
    ML_AVAILABLE = True
    print("✅ TFLite detector loaded")
except ImportError as e:
    print(f"⚠️  TFLite detector not available: {e}")
    ML_AVAILABLE = False

# Import Federated Learning (automatic - no user configuration needed)
try:
    from federated_learning import get_federated_manager, is_online
    FEDERATED_AVAILABLE = True
except ImportError as e:
    print(f"⚠️  Federated learning not available: {e}")
    FEDERATED_AVAILABLE = False

# Initialize Flask app
app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///urosmart.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=30)
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(__file__), 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Email Configuration
app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER', 'smtp.gmail.com')
app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT', 587))
app.config['MAIL_USERNAME'] = os.environ.get('MAIL_USERNAME')
app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD')
app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS', 'True').lower() == 'true'
app.config['MAIL_USE_SSL'] = os.environ.get('MAIL_USE_SSL', 'False').lower() == 'true'
app.config['MAIL_DEFAULT_SENDER'] = os.environ.get('MAIL_DEFAULT_SENDER', app.config['MAIL_USERNAME'])

# Twilio Configuration
app.config['TWILIO_ACCOUNT_SID'] = os.environ.get('TWILIO_ACCOUNT_SID')
app.config['TWILIO_AUTH_TOKEN'] = os.environ.get('TWILIO_AUTH_TOKEN')
app.config['TWILIO_PHONE_NUMBER'] = os.environ.get('TWILIO_PHONE_NUMBER')

# Validate critical secrets
if not app.config['SECRET_KEY']:
    if os.environ.get('FLASK_ENV') == 'production':
        raise ValueError("No SECRET_KEY set for production application")
    else:
        print("⚠️  WARNING: No SECRET_KEY set. Using insecure default for development.")
        app.config['SECRET_KEY'] = 'dev-secret-key-change-in-production'

if not app.config['JWT_SECRET_KEY']:
    if os.environ.get('FLASK_ENV') == 'production':
        raise ValueError("No JWT_SECRET_KEY set for production application")
    else:
        print("⚠️  WARNING: No JWT_SECRET_KEY set. Using insecure default for development.")
        app.config['JWT_SECRET_KEY'] = 'jwt-secret-key-change-in-production'

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'images'), exist_ok=True)
os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'reports'), exist_ok=True)

from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

# Initialize extensions
# Configure CORS based on environment
cors_origins = os.environ.get('CORS_ORIGINS', '*').split(',')
CORS(app, resources={r"/api/*": {"origins": cors_origins}})

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)
mail = Mail(app)

# Initialize Rate Limiter
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["200 per day", "50 per hour"],
    storage_uri="memory://"
)

# Database Models
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    phone_number = db.Column(db.String(20), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    reset_otp = db.Column(db.String(6), nullable=True)
    reset_otp_expires = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    reports = db.relationship('MedicalReport', backref='user', lazy=True, cascade='all, delete-orphan')
    
    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    
    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        return {
            'id': self.id,
            'phone_number': self.phone_number,
            'email': self.email,
            'created_at': self.created_at.isoformat(),
        }

    def generate_otp(self):
        """Generate 6-digit OTP and set expiration"""
        if app.debug or app.testing:
            # Deterministic OTP for development: last 6 digits of phone number
            digits = ''.join(filter(str.isdigit, self.phone_number))
            if len(digits) >= 6:
                self.reset_otp = digits[-6:]
            else:
                self.reset_otp = digits.ljust(6, '0')
        else:
            self.reset_otp = str(random.randint(100000, 999999))
            
        self.reset_otp_expires = datetime.utcnow() + timedelta(minutes=10)
        return self.reset_otp

    def verify_otp(self, otp):
        """Verify OTP and expiration"""
        if not self.reset_otp or not self.reset_otp_expires:
            return False
        if self.reset_otp != otp:
            return False
        if datetime.utcnow() > self.reset_otp_expires:
            return False
        return True


class MedicalReport(db.Model):
    __tablename__ = 'medical_reports'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    case_number = db.Column(db.String(50), nullable=False, index=True)
    report_date = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    
    # Analysis results
    yeast_present = db.Column(db.Boolean, default=False)
    yeast_count = db.Column(db.Integer, default=0)
    yeast_confidence = db.Column(db.Float, default=0.0)
    
    triple_phosphate_present = db.Column(db.Boolean, default=False)
    triple_phosphate_count = db.Column(db.Integer, default=0)
    triple_phosphate_confidence = db.Column(db.Float, default=0.0)
    
    calcium_oxalate_present = db.Column(db.Boolean, default=False)
    calcium_oxalate_count = db.Column(db.Integer, default=0)
    calcium_oxalate_confidence = db.Column(db.Float, default=0.0)
    
    squamous_cells_present = db.Column(db.Boolean, default=False)
    squamous_cells_count = db.Column(db.Integer, default=0)
    squamous_cells_confidence = db.Column(db.Float, default=0.0)
    
    uric_acid_present = db.Column(db.Boolean, default=False)
    uric_acid_count = db.Column(db.Integer, default=0)
    uric_acid_confidence = db.Column(db.Float, default=0.0)
    
    # File paths
    image_paths = db.Column(db.Text)  # JSON array of image paths
    pdf_path = db.Column(db.String(255))
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'case_number': self.case_number,
            'report_date': self.report_date.isoformat(),
            'results': {
                'yeast': {
                    'present': self.yeast_present,
                    'count': self.yeast_count,
                    'confidence': self.yeast_confidence
                },
                'triple_phosphate': {
                    'present': self.triple_phosphate_present,
                    'count': self.triple_phosphate_count,
                    'confidence': self.triple_phosphate_confidence
                },
                'calcium_oxalate': {
                    'present': self.calcium_oxalate_present,
                    'count': self.calcium_oxalate_count,
                    'confidence': self.calcium_oxalate_confidence
                },
                'squamous_cells': {
                    'present': self.squamous_cells_present,
                    'count': self.squamous_cells_count,
                    'confidence': self.squamous_cells_confidence
                },
                'uric_acid': {
                    'present': self.uric_acid_present,
                    'count': self.uric_acid_count,
                    'confidence': self.uric_acid_confidence
                }
            },
            'image_paths': self.image_paths,
            'pdf_path': self.pdf_path,
            'created_at': self.created_at.isoformat()
        }


def validate_image_file(file_stream):
    """
    Validate that the file is a valid image using Pillow
    Returns True if valid, False otherwise
    """
    try:
        from PIL import Image
        # Move pointer to beginning
        file_stream.seek(0)
        # Try to open and verify
        img = Image.open(file_stream)
        img.verify()
        # Reset pointer for saving
        file_stream.seek(0)
        return True
    except Exception:
        return False


# API Routes

@app.route('/api/health', methods=['GET'])
@limiter.exempt
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@app.route('/api/auth/signup', methods=['POST'])
@limiter.limit("5 per minute")
def signup():
    """User registration endpoint"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not all(key in data for key in ['phone_number', 'email', 'password']):
            return jsonify({'error': 'Missing required fields'}), 400
            
        # Validate phone number (must be 10 digits)
        phone = data['phone_number']
        if not phone.isdigit() or len(phone) != 10:
            return jsonify({'error': 'Phone number must be exactly 10 digits'}), 400

        # Validate email (must be @gmail.com)
        if not data['email'].endswith('@gmail.com'):
            return jsonify({'error': 'Only @gmail.com email addresses are allowed'}), 400
        
        # Check if user already exists
        if User.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email already registered'}), 409
        
        if User.query.filter_by(phone_number=data['phone_number']).first():
            return jsonify({'error': 'Phone number already registered'}), 409
        
        # Create new user
        user = User(
            phone_number=data['phone_number'],
            email=data['email']
        )
        user.set_password(data['password'])
        
        db.session.add(user)
        db.session.commit()
        
        # Generate access token
        access_token = create_access_token(identity=str(user.id))
        
        return jsonify({
            'message': 'User created successfully',
            'user': user.to_dict(),
            'access_token': access_token
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    """User login endpoint"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not all(key in data for key in ['email', 'password']):
            return jsonify({'error': 'Missing email or password'}), 400
        
        # Find user
        user = User.query.filter_by(email=data['email']).first()
        
        if not user or not user.check_password(data['password']):
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # Generate access token
        access_token = create_access_token(identity=str(user.id))
        
        return jsonify({
            'message': 'Login successful',
            'user': user.to_dict(),
            'access_token': access_token
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/forgot-password', methods=['POST'])
@limiter.limit("3 per minute")
def forgot_password():
    """Request password reset via OTP"""
    try:
        data = request.get_json()
        if 'phone_number' not in data:
            return jsonify({'error': 'Phone number is required'}), 400
            
        user = User.query.filter_by(phone_number=data['phone_number']).first()
        if not user:
            # Don't reveal if user exists
            return jsonify({'message': 'If your number is registered, you will receive an OTP.'}), 200
            
        otp = user.generate_otp()
        db.session.commit()
        
        # Send OTP via Twilio
        try:
            # Print OTP to console for development/testing without credits
            print(f"🔐 OTP for {user.phone_number}: {otp}")
            
            if app.config['TWILIO_ACCOUNT_SID'] and app.config['TWILIO_AUTH_TOKEN']:
                client = Client(app.config['TWILIO_ACCOUNT_SID'], app.config['TWILIO_AUTH_TOKEN'])
                message = client.messages.create(
                    body=f"Your UroSmart reset code is: {otp}",
                    from_=app.config['TWILIO_PHONE_NUMBER'],
                    to=user.phone_number
                )
                print(f"📱 SMS sent to {user.phone_number}: {message.sid}")
            else:
                print("⚠️  Twilio credentials not set. OTP printed to console only.")
            
        except Exception as e:
            print(f"❌ Failed to send SMS: {e}")
            # Continue anyway so user can use console OTP in dev
            # In prod, you might want to return error
        
        return jsonify({
            'message': 'OTP sent successfully',
            'dev_otp': otp if app.debug else None
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/reset-password', methods=['POST'])
@limiter.limit("5 per minute")
def reset_password():
    """Reset password with OTP"""
    try:
        data = request.get_json()
        required_fields = ['phone_number', 'otp', 'new_password']
        if not all(key in data for key in required_fields):
            return jsonify({'error': 'Phone number, OTP, and new password are required'}), 400
            
        user = User.query.filter_by(phone_number=data['phone_number']).first()
        if not user:
            return jsonify({'error': 'Invalid request'}), 400
            
        if not user.verify_otp(data['otp']):
            return jsonify({'error': 'Invalid or expired OTP'}), 400
            
        user.set_password(data['new_password'])
        # Clear OTP after successful reset
        user.reset_otp = None
        user.reset_otp_expires = None
        db.session.commit()
        
        return jsonify({'message': 'Password has been reset successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Get current user information"""
    try:
        user_id = int(get_jwt_identity())
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'user': user.to_dict()}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/reports', methods=['POST'])
def create_report():
    """Create a new medical report (JWT optional in development)"""
    try:
        # Try to get user_id from JWT, fallback to default for development
        try:
            user_id = int(get_jwt_identity())
            print(f"📝 Creating report for authenticated user {user_id}")
        except:
            # Development mode: use default user for testing
            user_id = 1
            print(f"⚠️  Development mode: Creating report for default user {user_id}")
        
        data = request.get_json()
        
        # Validate required fields
        if 'case_number' not in data:
            return jsonify({'error': 'Case number is required'}), 400
        
        # Create new report
        report = MedicalReport(
            user_id=user_id,
            case_number=data.get('case_number'),
            yeast_present=data.get('yeast_present', False),
            yeast_count=data.get('yeast_count', 0),
            yeast_confidence=data.get('yeast_confidence', 0.0),
            triple_phosphate_present=data.get('triple_phosphate_present', False),
            triple_phosphate_count=data.get('triple_phosphate_count', 0),
            triple_phosphate_confidence=data.get('triple_phosphate_confidence', 0.0),
            calcium_oxalate_present=data.get('calcium_oxalate_present', False),
            calcium_oxalate_count=data.get('calcium_oxalate_count', 0),
            calcium_oxalate_confidence=data.get('calcium_oxalate_confidence', 0.0),
            squamous_cells_present=data.get('squamous_cells_present', False),
            squamous_cells_count=data.get('squamous_cells_count', 0),
            squamous_cells_confidence=data.get('squamous_cells_confidence', 0.0),
            uric_acid_present=data.get('uric_acid_present', False),
            uric_acid_count=data.get('uric_acid_count', 0),
            uric_acid_confidence=data.get('uric_acid_confidence', 0.0),
            image_paths=data.get('image_paths', '[]'),
            pdf_path=data.get('pdf_path')
        )
        
        db.session.add(report)
        db.session.commit()
        
        return jsonify({
            'message': 'Report created successfully',
            'report': report.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/reports', methods=['GET'])
@jwt_required()
def get_reports():
    """Get all reports for current user"""
    try:
        user_id = int(get_jwt_identity())
        
        # Query parameters for filtering
        case_number = request.args.get('case_number')
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        # Build query
        query = MedicalReport.query.filter_by(user_id=user_id)
        
        if case_number:
            query = query.filter(MedicalReport.case_number.contains(case_number))
        
        if start_date:
            query = query.filter(MedicalReport.report_date >= datetime.fromisoformat(start_date))
        
        if end_date:
            query = query.filter(MedicalReport.report_date <= datetime.fromisoformat(end_date))
        
        # Order by date descending
        reports = query.order_by(MedicalReport.report_date.desc()).all()
        
        return jsonify({
            'reports': [report.to_dict() for report in reports],
            'count': len(reports)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/reports/<int:report_id>', methods=['GET'])
@jwt_required()
def get_report(report_id):
    """Get a specific report"""
    try:
        user_id = int(get_jwt_identity())
        report = MedicalReport.query.filter_by(id=report_id, user_id=user_id).first()
        
        if not report:
            return jsonify({'error': 'Report not found'}), 404
        
        return jsonify({'report': report.to_dict()}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/reports/<int:report_id>', methods=['DELETE'])
@jwt_required()
def delete_report(report_id):
    """Delete a specific report"""
    try:
        user_id = get_jwt_identity()
        report = MedicalReport.query.filter_by(id=report_id, user_id=user_id).first()
        
        if not report:
            return jsonify({'error': 'Report not found'}), 404
        
        db.session.delete(report)
        db.session.commit()
        
        return jsonify({'message': 'Report deleted successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/upload/image', methods=['POST'])
@jwt_required()
def upload_image():
    """Upload microscopy image"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
            
        # Security: Validate file type
        if not validate_image_file(file):
            return jsonify({'error': 'Invalid image file'}), 400
        
        # Generate unique filename
        filename = f"{uuid.uuid4()}_{secure_filename(file.filename)}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], 'images', filename)
        
        # Save file
        file.save(filepath)
        
        return jsonify({
            'message': 'Image uploaded successfully',
            'filename': filename,
            'path': f'/api/files/images/{filename}'
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/files/images/<filename>', methods=['GET'])
@jwt_required()
def get_image(filename):
    """Retrieve uploaded image"""
    try:
        filename = secure_filename(filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], 'images', filename)
        
        if not os.path.exists(filepath):
            return jsonify({'error': 'File not found'}), 404
        
        return send_file(filepath)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/files/reports/<filename>', methods=['GET'])
@jwt_required()
def get_pdf_report(filename):
    """Retrieve PDF report"""
    try:
        filename = secure_filename(filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], 'reports', filename)
        
        if not os.path.exists(filepath):
            return jsonify({'error': 'File not found'}), 404
        
        return send_file(filepath, mimetype='application/pdf')
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/detect', methods=['POST'])
def detect_microscopy_objects():
    # Allow detection without auth for easier testing
    # Can add @jwt_required() back if needed
    """
    Detect objects in microscopy image using ML
    
    Accepts:
        - multipart/form-data with 'file' field
        - Optional 'confidence' parameter (default 0.25)
    
    Returns:
        JSON with detection results for each object type
    """
    try:
        if not ML_AVAILABLE:
            return jsonify({
                'error': 'ML detection not available',
                'message': 'Install ML dependencies: pip install ultralytics pillow numpy'
            }), 503
        
        # Check if file is present
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
            
        # Security: Validate file type
        if not validate_image_file(file):
            return jsonify({'error': 'Invalid image file'}), 400
        
        # Get confidence threshold
        confidence = float(request.form.get('confidence', 0.15))
        
        # Read image data
        image_data = file.read()
        
        # Run detection
        results = detect_objects(image_data, confidence_threshold=confidence)
        
        if 'error' in results:
            return jsonify(results), 500
        
        return jsonify({
            'message': 'Detection completed',
            'detection_results': results
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/detect/status', methods=['GET'])
def detection_status():
    """Check ML detection availability"""
    if ML_AVAILABLE:
        try:
            detector = get_detector()
            return jsonify({
                'available': detector.interpreter is not None,
                'backend': 'TensorFlow Lite',
                'model': 'best.tflite',
                'unified_format': True,
                'message': 'TFLite detection available (same model as iOS)'
            }), 200
        except Exception as e:
            return jsonify({
                'available': False,
                'error': str(e)
            }), 500
    else:
        return jsonify({
            'available': False,
            'message': 'TFLite detection not configured. Install: pip install tensorflow'
        }), 503


# Federated Learning Endpoints (Automatic - invisible to users)
# These endpoints work automatically based on internet connectivity

@app.route('/api/model/update', methods=['POST'])
@jwt_required()
def submit_model_update():
    """
    Submit model update from client device (automatic - no user action needed)
    Client apps automatically submit updates when online
    """
    if not FEDERATED_AVAILABLE:
        return jsonify({
            'error': 'Federated learning not available',
            'status': 'offline'
        }), 503
    
    try:
        user_id = int(get_jwt_identity())
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['device_id', 'version', 'weight_updates', 'num_samples', 
                          'training_loss', 'validation_accuracy']
        
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Create model update
        from federated_learning import ModelUpdate
        
        update = ModelUpdate(
            device_id=data['device_id'],
            version=data['version'],
            weight_updates=data['weight_updates'],
            num_samples=data['num_samples'],
            training_loss=data['training_loss'],
            validation_accuracy=data['validation_accuracy'],
            timestamp=datetime.utcnow().isoformat()
        )
        
        # Add update (automatically processes if online)
        manager = get_federated_manager()
        result = manager.add_update(update)
        
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/model/latest', methods=['GET'])
@jwt_required()
def get_latest_model():
    """
    Get latest aggregated model weights (automatic - clients check periodically)
    Returns latest model if available and online
    """
    if not FEDERATED_AVAILABLE:
        return jsonify({
            'error': 'Federated learning not available',
            'model_available': False
        }), 503
    
    try:
        manager = get_federated_manager()
        global_model = manager.get_global_model()
        
        if not global_model:
            return jsonify({
                'model_available': False,
                'message': 'No global model available yet'
            }), 200
        
        # Only return model if online
        if not manager.is_connected():
            return jsonify({
                'model_available': False,
                'status': 'offline',
                'message': 'Model available but device is offline'
            }), 200
        
        return jsonify({
            'model_available': True,
            'version': global_model.version,
            'weights': global_model.weights,
            'aggregation_timestamp': global_model.aggregation_timestamp,
            'participating_devices': global_model.participating_devices,
            'average_accuracy': global_model.average_accuracy
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/model/check', methods=['GET'])
@jwt_required()
def check_model_updates():
    """
    Check if new model version is available (automatic - clients poll periodically)
    Lightweight endpoint for checking updates
    """
    if not FEDERATED_AVAILABLE:
        return jsonify({
            'has_update': False,
            'online': False
        }), 200
    
    try:
        manager = get_federated_manager()
        global_model = manager.get_global_model()
        client_version = request.args.get('version', type=int, default=0)
        
        has_update = False
        latest_version = 0
        
        if global_model:
            latest_version = global_model.version
            has_update = latest_version > client_version
        
        return jsonify({
            'has_update': has_update and manager.is_connected(),
            'latest_version': latest_version,
            'online': manager.is_connected(),
            'client_version': client_version
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Database initialization
@app.before_request
def create_tables():
    """Create database tables if they don't exist"""
    if not hasattr(app, 'tables_created'):
        db.create_all()
        app.tables_created = True


if __name__ == '__main__':
    # Create tables
    with app.app_context():
        db.create_all()
    
    # Run server
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    print(f"🚀 UroSmart Backend running on http://localhost:{port}")
    print(f"📚 API Documentation: http://localhost:{port}/api/health")
    if debug:
        print("⚠️  WARNING: Debug mode is ENABLED")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
