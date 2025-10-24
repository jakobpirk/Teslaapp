# Backend Setup Guide

This document explains how the backend was set up and how to migrate from Firebase to the Laravel backend.

## Overview

The Tessie app has been updated to use a Laravel backend API instead of Firebase Firestore for data storage. This provides:

- Better control over data
- Traditional relational database (MySQL)
- RESTful API endpoints
- Docker-based deployment
- Easier local development

## What Changed

### 1. Data Storage Migration

**Before (Firebase Firestore):**
- Charging sessions stored in Firestore collection `charging_sessions`
- Face auth enrollments in `face_enrollments` collection
- Face auth sessions in `face_auth_sessions` collection

**After (Laravel Backend):**
- Charging sessions stored in MySQL table `charging_sessions`
- Face auth enrollments in MySQL table `face_enrollments`
- Face auth sessions in MySQL table `face_auth_sessions`

### 2. Flutter App Changes

#### New Data Sources

Two new HTTP-based data sources replace Firebase:

1. **`ChargingStatsHttpDataSource`** (`lib/core/data/datasources/charging_stats_http_datasource.dart`)
   - Replaces `ChargingStatsRemoteDataSourceImpl`
   - Uses Dio HTTP client instead of Firestore
   - All CRUD operations via REST API

2. **`FaceAuthHttpDataSource`** (`lib/core/data/datasources/face_auth_http_data_source.dart`)
   - Replaces `FaceAuthRemoteDataSourceImpl`
   - Uses Dio HTTP client instead of Firestore
   - Authentication operations via REST API

#### Updated Dependencies

The dependency injection container (`lib/core/di/injection_container.dart`) now:
- Uses Dio HTTP client for backend communication
- Removed Firebase Firestore dependency
- Configures base URL from environment variable `BACKEND_API_URL`

#### Configuration

Add to your `.env` file:
```env
BACKEND_API_URL=http://localhost:8080
```

For different environments:
- **Android Emulator**: `http://10.0.2.2:8080`
- **iOS Simulator**: `http://localhost:8080`
- **Physical Device**: `http://YOUR_COMPUTER_IP:8080`

### 3. pubspec.yaml Changes (Optional)

You can now remove Firebase dependencies if not used elsewhere:

```yaml
# Can be removed if not using Firebase
# firebase_core: ^2.24.2
# cloud_firestore: ^4.14.0
```

The app already has Dio installed, so no new dependencies are required.

## Backend Setup

### Quick Start

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Start Docker containers:**
   ```bash
   docker-compose up -d
   ```

4. **Install dependencies:**
   ```bash
   docker-compose exec app composer install
   ```

5. **Run migrations:**
   ```bash
   docker-compose exec app php artisan migrate
   ```

6. **Test the API:**
   ```bash
   curl http://localhost:8080/api/v1/health
   ```

### Verify Installation

Visit http://localhost:8080 in your browser. You should see:
```json
{
  "message": "Tessie Backend API",
  "version": "1.0.0",
  "docs": "/api/v1/health"
}
```

## API Endpoints

### Charging Sessions

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/charging-sessions/vehicle/{vehicleId}` | Get all sessions for vehicle |
| GET | `/api/v1/charging-sessions/{id}` | Get specific session |
| POST | `/api/v1/charging-sessions` | Create new session |
| PUT | `/api/v1/charging-sessions/{id}` | Update session |
| DELETE | `/api/v1/charging-sessions/{id}` | Delete session |
| GET | `/api/v1/charging-sessions/vehicle/{vehicleId}/recent` | Get most recent session |
| GET | `/api/v1/charging-sessions/vehicle/{vehicleId}/date-range` | Get sessions by date range |

### Face Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/face-auth/enrollments` | Register enrollment |
| GET | `/api/v1/face-auth/enrollments/{userId}` | Get enrollment |
| DELETE | `/api/v1/face-auth/enrollments/{userId}` | Delete enrollment |
| POST | `/api/v1/face-auth/verify` | Verify authentication |
| POST | `/api/v1/face-auth/sessions/verify` | Verify session token |
| POST | `/api/v1/face-auth/sessions/invalidate` | Invalidate session |

## Testing

### Test Backend API

```bash
# Health check
curl http://localhost:8080/api/v1/health

# Create a charging session
curl -X POST http://localhost:8080/api/v1/charging-sessions \
  -H "Content-Type: application/json" \
  -d '{
    "vehicle_id": "test123",
    "start_time": "2024-01-20T10:00:00Z",
    "energy_added": 45.5,
    "cost": 12.50,
    "location": "Home"
  }'

# Get sessions for vehicle
curl http://localhost:8080/api/v1/charging-sessions/vehicle/test123
```

### Test Flutter App

1. Update `.env` with `BACKEND_API_URL`
2. Restart the Flutter app
3. Test charging features and face authentication
4. Check backend logs: `docker-compose logs -f app`

## Data Migration (Optional)

If you have existing data in Firebase, you'll need to migrate it:

1. **Export from Firebase:**
   - Use Firebase Console to export Firestore data
   - Or write a script to fetch data via Firebase Admin SDK

2. **Transform data:**
   - Convert Firestore Timestamps to MySQL timestamps
   - Ensure UUIDs are preserved or generated

3. **Import to MySQL:**
   ```bash
   docker-compose exec db mysql -u tessie_user -p tessie
   ```

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│                 │
│  - Dio Client   │
│  - HTTP Sources │
└────────┬────────┘
         │ HTTP/REST
         │
┌────────▼────────┐
│  Nginx (8080)   │
└────────┬────────┘
         │
┌────────▼────────┐
│  Laravel API    │
│  - Controllers  │
│  - Models       │
│  - Migrations   │
└────┬──────┬─────┘
     │      │
     │      └──────┐
┌────▼────┐   ┌───▼─────┐
│  MySQL  │   │  Redis  │
│  (3306) │   │  (6379) │
└─────────┘   └─────────┘
```

## Troubleshooting

### Connection Refused

**Problem:** Flutter app can't connect to backend

**Solutions:**
- Check backend is running: `docker-compose ps`
- Verify correct URL in `.env`
- For Android emulator, use `http://10.0.2.2:8080`
- Check firewall settings

### Database Errors

**Problem:** Migration fails or database connection errors

**Solutions:**
```bash
# Check database container
docker-compose logs db

# Recreate database
docker-compose down -v
docker-compose up -d
docker-compose exec app php artisan migrate
```

### Port Conflicts

**Problem:** Port 8080 already in use

**Solution:** Edit `docker-compose.yml` to use a different port:
```yaml
nginx:
  ports:
    - "9000:80"  # Change to available port
```

Then update `BACKEND_API_URL` in Flutter app's `.env`.

## Production Deployment

For production, consider:

1. **Security:**
   - Use HTTPS/SSL
   - Implement API authentication (Laravel Sanctum)
   - Set proper CORS headers
   - Use environment variables for secrets

2. **Performance:**
   - Enable Laravel caching
   - Use Redis for sessions
   - Configure database indexes
   - Set up CDN for static assets

3. **Monitoring:**
   - Set up logging (Laravel Log)
   - Use monitoring tools (New Relic, Datadog)
   - Configure error tracking (Sentry)

4. **Deployment:**
   - Use proper hosting (AWS, DigitalOcean, etc.)
   - Set up CI/CD pipeline
   - Configure automated backups
   - Use load balancing if needed

## File Structure

```
backend/
├── app/
│   ├── Http/
│   │   └── Controllers/
│   │       └── Api/
│   │           ├── ChargingSessionController.php
│   │           └── FaceAuthController.php
│   └── Models/
│       ├── ChargingSession.php
│       ├── FaceEnrollment.php
│       └── FaceAuthSession.php
├── database/
│   └── migrations/
│       ├── *_create_charging_sessions_table.php
│       ├── *_create_face_enrollments_table.php
│       └── *_create_face_auth_sessions_table.php
├── routes/
│   ├── api.php
│   └── web.php
├── docker/
│   └── nginx/
│       └── conf.d/
│           └── default.conf
├── docker-compose.yml
├── Dockerfile
├── .env.example
└── README.md
```

## Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- Backend API README: `backend/README.md`

## Support

For issues or questions:
1. Check this documentation
2. Review `backend/README.md`
3. Check Docker logs: `docker-compose logs`
4. Refer to the main project repository

---

**Migration Summary:**
- ✅ Laravel backend with Docker setup
- ✅ MySQL database with migrations
- ✅ REST API endpoints for all operations
- ✅ Flutter app updated to use HTTP instead of Firebase
- ✅ Complete documentation and setup guides
