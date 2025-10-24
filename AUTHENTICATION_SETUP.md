# Authentication Setup Guide

This guide explains how to set up and use the authentication system for the Tesla app.

## Backend Setup (Laravel)

### 1. Run Migrations

The authentication system requires the following database tables:
- `users` - User accounts
- `personal_access_tokens` - Sanctum API tokens
- `password_reset_tokens` - Password reset codes

Run migrations inside the Docker container:

```bash
cd backend
docker-compose exec app php artisan migrate
```

### 2. Test the Backend

Run the authentication tests:

```bash
docker-compose exec app php artisan test --filter=AuthenticationTest
```

### API Endpoints

The following endpoints are available:

**Public Endpoints:**
- `POST /api/v1/auth/register` - Register a new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/forgot-password` - Request password reset code
- `POST /api/v1/auth/verify-reset-code` - Verify reset code
- `POST /api/v1/auth/reset-password` - Reset password with code

**Protected Endpoints (require Bearer token):**
- `GET /api/v1/auth/me` - Get current user
- `POST /api/v1/auth/logout` - Logout

### Example Requests

**Register:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

## Frontend Setup (Flutter)

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Backend URL

Update the backend URL in `lib/constants/backend_api_constants.dart`:

```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL/api/v1';
```

For Android emulator, use: `http://10.0.2.2:8080/api/v1`
For iOS simulator, use: `http://localhost:8080/api/v1`

### 3. Run the App

```bash
flutter run
```

### 4. Run Tests

```bash
flutter test
```

## Authentication Flow

### Login Flow
1. User opens app → Splash screen checks for saved token
2. If token exists and valid → Navigate to Home screen
3. If no token → Navigate to Login screen
4. User enters credentials → Calls backend API
5. On success → Token saved securely → Navigate to Home screen

### Registration Flow
1. User taps "Sign Up" on Login screen
2. Fills registration form → Calls backend API
3. On success → Token saved securely → Navigate to Home screen

### Password Reset Flow
1. User taps "Forgot Password" on Login screen
2. Enters email → Backend sends 6-digit code
3. User enters code and new password
4. On success → Navigate to Login screen

## Security Features

- **Token Storage:** Tokens are stored securely using Flutter Secure Storage
- **Token Management:** Old tokens are revoked on login
- **Password Hashing:** Passwords are hashed using bcrypt
- **Reset Code Expiry:** Reset codes expire after 15 minutes
- **HTTPS:** Use HTTPS in production

## UI Design

The authentication screens feature:
- Modern gradient backgrounds
- Smooth animations using flutter_animate
- Form validation with helpful error messages
- Loading states with progress indicators
- Password visibility toggle
- Responsive design

## Architecture

The app follows Clean Architecture principles:

```
lib/
├── core/
│   ├── domain/
│   │   ├── entities/           # User, AuthResponse entities
│   │   ├── repositories/       # Auth repository interface
│   │   └── usecases/           # Login, Register, etc.
│   ├── data/
│   │   ├── models/             # DTOs
│   │   ├── datasources/        # HTTP and local storage
│   │   ├── repositories/       # Repository implementations
│   │   └── mappers/            # Entity ↔ DTO mappers
├── features/
│   └── auth/
│       └── presentation/
│           ├── screens/        # Login, Register, etc.
│           └── providers/      # AuthProvider for state
```

## Troubleshooting

### Backend Issues

**Migration errors:**
- Ensure database is running: `docker-compose up -d`
- Check database connection in `.env`

**Token not working:**
- Check Sanctum middleware is configured in `bootstrap/app.php`
- Verify API routes are using correct prefix

### Frontend Issues

**Can't connect to backend:**
- Check backend URL in `backend_api_constants.dart`
- For Android emulator, use `10.0.2.2` instead of `localhost`
- Ensure backend is running

**Token not persisting:**
- Check Flutter Secure Storage permissions in AndroidManifest.xml
- For iOS, ensure keychain access is configured

**Build errors:**
- Run `flutter clean && flutter pub get`
- Check all dependencies are installed

## Next Steps

After authentication is working:
1. Add email verification
2. Implement refresh tokens
3. Add social login (Google, Apple)
4. Add biometric authentication
5. Implement role-based access control
