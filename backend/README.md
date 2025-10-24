# Tessie Backend API

A Laravel-based REST API backend for the Tessie Tesla app. This backend replaces Firebase Firestore with a traditional REST API, providing endpoints for charging sessions and face authentication.

## Features

- **Charging Sessions API**: Store and retrieve charging session data
- **Face Authentication API**: Manage face authentication enrollments and sessions
- **Docker Support**: Complete Docker setup with MySQL, Redis, and Nginx
- **RESTful Design**: Clean, RESTful API endpoints
- **Database Migrations**: Automated database schema management

## Tech Stack

- **Framework**: Laravel 10
- **Database**: MySQL 8.0
- **Cache/Sessions**: Redis
- **Web Server**: Nginx
- **PHP**: 8.2
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker & Docker Compose
- Git

## Quick Start

### 1. Clone and Setup

```bash
cd backend
cp .env.example .env
```

### 2. Generate Application Key

Edit `.env` and add a random 32-character key for `APP_KEY`:
```
APP_KEY=base64:YOUR_32_CHARACTER_KEY_HERE
```

Or generate one using:
```bash
docker-compose run --rm app php artisan key:generate
```

### 3. Start Services

```bash
docker-compose up -d
```

This will start:
- **App** (PHP-FPM): Laravel application
- **Nginx**: Web server on port 8080
- **MySQL**: Database on port 3306
- **Redis**: Cache/sessions on port 6379

### 4. Install Dependencies

```bash
docker-compose exec app composer install
```

### 5. Run Migrations

```bash
docker-compose exec app php artisan migrate
```

### 6. Verify Installation

Visit: http://localhost:8080

You should see a JSON response:
```json
{
  "message": "Tessie Backend API",
  "version": "1.0.0",
  "docs": "/api/v1/health"
}
```

## API Endpoints

### Health Check
```
GET /api/v1/health
```

### Charging Sessions

```
GET    /api/v1/charging-sessions                           - Get all sessions
GET    /api/v1/charging-sessions/{id}                      - Get session by ID
POST   /api/v1/charging-sessions                           - Create new session
PUT    /api/v1/charging-sessions/{id}                      - Update session
DELETE /api/v1/charging-sessions/{id}                      - Delete session
GET    /api/v1/charging-sessions/vehicle/{vehicleId}       - Get sessions by vehicle
GET    /api/v1/charging-sessions/vehicle/{vehicleId}/recent - Get most recent session
GET    /api/v1/charging-sessions/vehicle/{vehicleId}/date-range - Get sessions by date range
```

#### Example: Create Charging Session

```bash
curl -X POST http://localhost:8080/api/v1/charging-sessions \
  -H "Content-Type: application/json" \
  -d '{
    "vehicle_id": "12345",
    "start_time": "2024-01-20T10:00:00Z",
    "end_time": "2024-01-20T11:30:00Z",
    "energy_added": 45.5,
    "cost": 12.50,
    "location": "Home Charger",
    "charge_rate": 11.5,
    "start_battery_level": 20,
    "end_battery_level": 80
  }'
```

### Face Authentication

```
POST   /api/v1/face-auth/enrollments                  - Register new enrollment
GET    /api/v1/face-auth/enrollments/{userId}         - Get enrollment
DELETE /api/v1/face-auth/enrollments/{userId}         - Delete enrollment
POST   /api/v1/face-auth/verify                       - Verify authentication
POST   /api/v1/face-auth/sessions/verify              - Verify session token
POST   /api/v1/face-auth/sessions/invalidate          - Invalidate session
```

#### Example: Register Face Enrollment

```bash
curl -X POST http://localhost:8080/api/v1/face-auth/enrollments \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "device_id": "device456"
  }'
```

## Database Schema

### charging_sessions
- `id` (UUID, primary key)
- `vehicle_id` (string, indexed)
- `start_time` (timestamp, indexed)
- `end_time` (timestamp, nullable)
- `energy_added` (decimal)
- `cost` (decimal)
- `location` (string, nullable)
- `charge_rate` (decimal, nullable)
- `start_battery_level` (integer, nullable)
- `end_battery_level` (integer, nullable)
- `created_at`, `updated_at` (timestamps)

### face_enrollments
- `id` (UUID, primary key)
- `user_id` (string, indexed)
- `enrolled_at` (timestamp)
- `is_active` (boolean, indexed)
- `device_id` (string, nullable)
- `biometric_type` (string, default: 'face')
- `created_at`, `updated_at` (timestamps)

### face_auth_sessions
- `id` (UUID, primary key)
- `user_id` (string, indexed)
- `enrollment_id` (string, foreign key)
- `authenticated_at` (timestamp)
- `expires_at` (timestamp, indexed)
- `is_authenticated` (boolean)
- `confidence_score` (decimal)
- `method` (string, default: 'faceBiometric')
- `created_at`, `updated_at` (timestamps)

## Docker Commands

### View Logs
```bash
docker-compose logs -f app
docker-compose logs -f nginx
```

### Access Container Shell
```bash
docker-compose exec app bash
```

### Stop Services
```bash
docker-compose down
```

### Rebuild Containers
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Run Artisan Commands
```bash
docker-compose exec app php artisan <command>
```

## Development

### Running Tests
```bash
docker-compose exec app php artisan test
```

### Clear Cache
```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
```

### Database Operations

#### Fresh Migration (WARNING: Destroys data)
```bash
docker-compose exec app php artisan migrate:fresh
```

#### Rollback Migration
```bash
docker-compose exec app php artisan migrate:rollback
```

#### Check Migration Status
```bash
docker-compose exec app php artisan migrate:status
```

## Configuration

### Environment Variables

Key environment variables in `.env`:

```env
APP_NAME=TessieBackend
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8080

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=tessie
DB_USERNAME=tessie_user
DB_PASSWORD=tessie_password

REDIS_HOST=redis
REDIS_PORT=6379
```

### Ports

Default ports (configurable in `docker-compose.yml`):
- **8080**: Nginx (HTTP API)
- **3306**: MySQL
- **6379**: Redis

To change the Nginx port, edit `docker-compose.yml`:
```yaml
nginx:
  ports:
    - "9000:80"  # Change 8080 to 9000
```

## Connecting Flutter App

Update your Flutter app's `.env` file:

```env
BACKEND_API_URL=http://localhost:8080
```

For Android emulator, use:
```env
BACKEND_API_URL=http://10.0.2.2:8080
```

For iOS simulator, use:
```env
BACKEND_API_URL=http://localhost:8080
```

For physical devices on the same network, use your computer's IP:
```env
BACKEND_API_URL=http://192.168.1.XXX:8080
```

## Troubleshooting

### Port Already in Use

If port 8080 is already in use:
1. Stop the conflicting service
2. Or change the port in `docker-compose.yml`

### Permission Issues

If you encounter permission issues:
```bash
docker-compose exec app chown -R tessie:tessie /var/www
docker-compose exec app chmod -R 775 storage bootstrap/cache
```

### Database Connection Failed

1. Check if MySQL container is running:
   ```bash
   docker-compose ps
   ```

2. Check MySQL logs:
   ```bash
   docker-compose logs db
   ```

3. Verify database credentials in `.env`

### Composer Install Fails

```bash
docker-compose exec app composer install --no-scripts
docker-compose exec app composer dump-autoload
```

## Production Deployment

For production deployment:

1. Update `.env`:
   ```env
   APP_ENV=production
   APP_DEBUG=false
   ```

2. Use proper secrets:
   - Generate secure APP_KEY
   - Use strong database passwords
   - Configure SSL/TLS

3. Enable optimizations:
   ```bash
   docker-compose exec app php artisan config:cache
   docker-compose exec app php artisan route:cache
   docker-compose exec app php artisan view:cache
   docker-compose exec app composer install --optimize-autoloader --no-dev
   ```

4. Set up proper logging and monitoring

## License

MIT

## Support

For issues or questions, please refer to the main project repository.
