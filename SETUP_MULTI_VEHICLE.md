# Multi-Vehicle and User Settings Setup Guide

This guide explains how to set up and use the new multi-vehicle system, user-specific statistics, Tessie API key management, and electricity provider selection features.

## Overview of New Features

### 1. **Multi-Vehicle Support**
- Users can now register and manage multiple vehicles
- Each vehicle has its own charging sessions and statistics
- Switch between vehicles easily

### 2. **User-Specific Statistics**
- Each user has their own data completely isolated from other users
- Statistics are calculated per vehicle per user

### 3. **Tessie API Key Management**
- Users can securely store their Tessie API key
- Keys are encrypted and hidden from API responses
- Required before adding vehicles

### 4. **Electricity Provider Selection**
- Choose from mock electricity providers
- Each provider has different pricing structures
- Pricing data is fetched via simulated network calls

### 5. **User Location Setting**
- Set your location for more accurate pricing
- Used in charging recommendations

## Backend Setup

### Step 1: Run Database Migrations

Navigate to the backend directory and run migrations using Docker:

```bash
cd backend

# Run migrations
docker-compose exec app php artisan migrate

# Or if not using Docker:
php artisan migrate
```

This will create the following new tables:
- `electricity_providers` - Store available electricity providers
- `vehicles` - Store user vehicles
- Update `users` table with new fields (tessie_api_key, electricity_provider_id, location)
- Update `charging_sessions` and `charging_recommendations` with foreign key constraints

### Step 2: Seed Mock Electricity Providers

Seed the database with mock electricity providers:

```bash
# Using Docker
docker-compose exec app php artisan db:seed --class=ElectricityProviderSeeder

# Or without Docker
php artisan db:seed --class=ElectricityProviderSeeder
```

This will create 5 mock providers:
1. **GridPower USA** (California, US)
2. **EcoEnergy Europe** (Bavaria, Germany)
3. **PowerPlus UK** (London, UK)
4. **SunPower Australia** (New South Wales, Australia)
5. **VoltStream Canada** (Ontario, Canada)

Each provider has different:
- Time-of-use pricing structures
- Rate types (off-peak, mid-peak, peak)
- Base rates

### Step 3: Restart Backend Server

If your backend is running, restart it to pick up the new routes:

```bash
docker-compose restart app
```

## Frontend Setup

### Step 1: Update Dependencies

Ensure you have the required dependencies in `pubspec.yaml`:

```yaml
dependencies:
  provider: ^6.0.0
  http: ^1.0.0
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.6.0
```

### Step 2: Generate JSON Serialization Code

Run build_runner to generate the DTO serialization code:

```bash
cd /path/to/flutter/app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 3: Register Providers

Update your main app file to register the new providers:

```dart
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'features/vehicle/presentation/providers/vehicle_management_provider.dart';
import 'features/settings/presentation/providers/user_settings_provider.dart';
import 'core/data/datasources/vehicle_http_datasource.dart';
import 'core/data/datasources/user_settings_http_datasource.dart';
import 'core/data/datasources/electricity_provider_http_datasource.dart';

void main() {
  final client = http.Client();

  runApp(
    MultiProvider(
      providers: [
        // Existing providers...

        // New providers
        ChangeNotifierProvider(
          create: (_) => VehicleManagementProvider(
            VehicleHttpDataSource(client: client),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UserSettingsProvider(
            UserSettingsHttpDataSource(client: client),
            ElectricityProviderHttpDataSource(client: client),
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

### Step 4: Initialize Providers After Login

After user authentication, initialize the providers:

```dart
// After successful login
final authProvider = context.read<AuthProvider>();
final token = authProvider.token;

// Set tokens for new providers
context.read<VehicleManagementProvider>().setToken(token);
context.read<UserSettingsProvider>().setToken(token);

// Load initial data
await context.read<VehicleManagementProvider>().loadVehicles();
await context.read<UserSettingsProvider>().initialize();
```

## API Endpoints Reference

### Vehicle Management

```
GET    /api/v1/vehicles              - Get all user vehicles
GET    /api/v1/vehicles/active       - Get only active vehicles
POST   /api/v1/vehicles              - Create new vehicle
GET    /api/v1/vehicles/{id}         - Get specific vehicle
PUT    /api/v1/vehicles/{id}         - Update vehicle
DELETE /api/v1/vehicles/{id}         - Deactivate vehicle
GET    /api/v1/vehicles/{id}/statistics - Get vehicle statistics
```

### Electricity Providers

```
GET    /api/v1/electricity-providers                    - Get all providers
GET    /api/v1/electricity-providers/country/{country}  - Get by country
GET    /api/v1/electricity-providers/{id}               - Get specific provider
GET    /api/v1/electricity-providers/{id}/pricing/current   - Current pricing
GET    /api/v1/electricity-providers/{id}/pricing/forecast  - Price forecast
```

### User Settings

```
GET    /api/v1/user/settings                     - Get user settings
GET    /api/v1/user/profile                      - Get user profile
POST   /api/v1/user/settings/tessie-api-key     - Update Tessie API key
DELETE /api/v1/user/settings/tessie-api-key     - Remove Tessie API key
POST   /api/v1/user/settings/electricity-provider - Update provider
POST   /api/v1/user/settings/location            - Update location
```

## Usage Flow

### 1. First-Time User Setup

```
1. User registers/logs in
2. User navigates to Settings screen
3. User enters Tessie API key (required)
4. User selects electricity provider
5. User sets location
6. User can now add vehicles
```

### 2. Adding a Vehicle

```
1. Navigate to Vehicle Management screen
2. Click "Add Vehicle" button
3. Enter:
   - Tessie Vehicle ID (required)
   - Display Name (required)
   - Model (optional)
   - Other details (optional)
4. Vehicle is added and automatically selected
```

### 3. Using Multiple Vehicles

```
1. View all vehicles in Vehicle Management screen
2. Selected vehicle is highlighted
3. Tap on a vehicle to select it
4. All charging sessions and stats are filtered by selected vehicle
5. Charging recommendations are vehicle-specific
```

### 4. Viewing Statistics

```
1. In Vehicle Management, tap menu on a vehicle
2. Select "View Statistics"
3. See:
   - Total charging sessions
   - Total energy consumed
   - Total cost
   - Average cost per session
```

## Data Flow

### Charging Recommendations with User's Provider

The smart charging service now uses the user's selected electricity provider:

```
1. User selects electricity provider in settings
2. Provider's pricing data is fetched via simulated API calls
3. ElectricityProviderService calculates time-of-use rates
4. Pricing stored in pricing_history table
5. SmartChargingService uses this data for recommendations
6. Recommendations are vehicle-specific and user-specific
```

### Mock Electricity Provider Pricing

Each provider has:
- **Rate Types**: Different pricing tiers
- **Time Windows**: When each rate applies
- **Base Rates**: Starting price per kWh
- **Seasonal Adjustments**: Summer (+10%), Winter (+15%)
- **Random Variation**: ±5% to simulate real-world fluctuations

Example for GridPower USA:
- Off-peak (12am-6am, 10pm-12am): $0.12/kWh
- Mid-peak (6am-2pm, 8pm-10pm): $0.22/kWh
- Peak (2pm-8pm): $0.35/kWh

## Navigation Integration

Add navigation buttons to access the new screens:

```dart
// In your main menu/drawer
ListTile(
  leading: Icon(Icons.directions_car),
  title: Text('My Vehicles'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VehicleManagementScreen()),
    );
  },
),
ListTile(
  leading: Icon(Icons.settings),
  title: Text('Settings'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserSettingsScreen()),
    );
  },
),
```

## Testing the System

### 1. Test User Registration and Settings

```bash
# Register a new user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'

# Update Tessie API key
curl -X POST http://localhost:8000/api/v1/user/settings/tessie-api-key \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tessie_api_key": "your_tessie_key_here"}'
```

### 2. Test Electricity Provider Selection

```bash
# Get all providers
curl http://localhost:8000/api/v1/electricity-providers

# Select a provider
curl -X POST http://localhost:8000/api/v1/user/settings/electricity-provider \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"electricity_provider_id": "PROVIDER_ID"}'
```

### 3. Test Vehicle Management

```bash
# Add a vehicle
curl -X POST http://localhost:8000/api/v1/vehicles \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tessie_vehicle_id": "12345",
    "display_name": "My Model 3",
    "model": "Model 3",
    "year": 2023
  }'

# Get all vehicles
curl http://localhost:8000/api/v1/vehicles \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Troubleshooting

### Migration Issues

If you encounter migration errors:

```bash
# Reset database (WARNING: This deletes all data)
php artisan migrate:fresh

# Re-run migrations step by step
php artisan migrate:rollback
php artisan migrate
```

### Provider Not Loading

If providers aren't showing:

```bash
# Check if seeder ran successfully
php artisan tinker
>>> \App\Models\ElectricityProvider::count()

# If count is 0, run seeder again
>>> exit
php artisan db:seed --class=ElectricityProviderSeeder
```

### Token Issues

If getting authentication errors:
1. Check token is being passed correctly in headers
2. Verify token hasn't expired
3. Check Sanctum configuration in Laravel

## Security Notes

1. **Tessie API keys** are:
   - Stored encrypted in database
   - Hidden from all API responses
   - Never logged or exposed

2. **Vehicle IDs** from Tessie are:
   - Hidden from frontend responses
   - Used only for internal API calls

3. **User data isolation**:
   - All queries are scoped by authenticated user
   - No cross-user data access possible
   - Foreign key constraints ensure data integrity

## Next Steps

After setup, you can:
1. Enhance the UI with better styling
2. Add more electricity providers
3. Implement real Tessie API integration
4. Add push notifications for charging recommendations
5. Create dashboards for multi-vehicle overview
6. Add vehicle sharing between users
7. Implement charging schedules per vehicle

## Support

For issues or questions, please check:
- Backend logs: `backend/storage/logs/laravel.log`
- Frontend console in browser developer tools
- Network tab for API call details
