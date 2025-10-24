# Tessie Tesla Control App

A modern, sleek Flutter mobile application for controlling Tesla vehicles through the Tessie API. Features a beautiful dark UI with smooth animations, comprehensive vehicle control capabilities, and a Laravel backend API for data storage.

## Features

### Vehicle Monitoring
- Real-time battery level and range
- Vehicle state (online/asleep)
- Climate status
- Lock status
- Location tracking

### Climate Control
- Start/stop climate system
- Adjust temperature settings
- Defrost controls
- Seat heating and cooling
- Steering wheel heater

### Charging Management
- Start/stop charging
- Set charge limit
- Monitor charging rate
- Battery health indicators
- Charging tips and recommendations
- Charging session history and statistics
- Cost tracking and analytics

### Vehicle Actions
- Lock/unlock doors
- Flash lights
- Honk horn
- Sentry mode control
- Open frunk/trunk
- Vent/close windows

### Security & Authentication
- Face biometric authentication
- Secure session management
- Local and remote enrollment

## Screenshots

The app features:
- **Dark mode UI** with modern card-based design
- **Smooth animations** using flutter_animate
- **Intuitive controls** with visual feedback
- **Real-time updates** with pull-to-refresh

## Installation

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- A Tessie API account with API key
- Your Tesla vehicle VIN
- Docker & Docker Compose (for backend)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Teslaapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up the backend**

   See [BACKEND_SETUP.md](BACKEND_SETUP.md) for detailed instructions:
   ```bash
   cd backend
   cp .env.example .env
   docker-compose up -d
   docker-compose exec app composer install
   docker-compose exec app php artisan migrate
   ```

4. **Configure API credentials**

   Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

   Edit `.env` and add your credentials:
   ```
   TESSIE_API_KEY=your_tessie_api_key_here
   TESSIE_VIN=your_vehicle_vin_here
   BACKEND_API_URL=http://localhost:8080
   ```

   For Android emulator: `BACKEND_API_URL=http://10.0.2.2:8080`

5. **Run the app**
   ```bash
   flutter run
   ```

## Getting Tessie API Credentials

1. Visit [tessie.com](https://tessie.com) and create an account
2. Link your Tesla account
3. Navigate to the Developer API section
4. Generate an API key
5. Find your vehicle VIN in the app or Tesla account

## Project Structure

```
.
├── backend/                          # Laravel Backend API
│   ├── app/
│   │   ├── Http/Controllers/Api/     # REST API Controllers
│   │   └── Models/                   # Eloquent Models
│   ├── database/migrations/          # Database Migrations
│   ├── routes/api.php                # API Routes
│   ├── docker-compose.yml            # Docker Compose Config
│   ├── Dockerfile                    # Docker Image Config
│   └── README.md                     # Backend Documentation
├── lib/                              # Flutter App
│   ├── core/
│   │   ├── data/
│   │   │   ├── datasources/          # Data sources (HTTP, Local)
│   │   │   ├── models/               # DTOs
│   │   │   └── repositories/         # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/             # Domain entities
│   │   │   ├── repositories/         # Repository interfaces
│   │   │   └── usecases/             # Business logic
│   │   └── di/                       # Dependency Injection
│   ├── features/
│   │   ├── vehicle/                  # Vehicle control feature
│   │   └── charging_stats/           # Charging statistics
│   ├── screens/                      # UI Screens
│   ├── utils/                        # Utilities & Theme
│   └── main.dart                     # App entry point
├── BACKEND_SETUP.md                  # Backend Setup Guide
└── README.md                         # This file
```

## API Integration

This app integrates with the Tessie API which provides:
- RESTful API endpoints at `api.tessie.com`
- Bearer token authentication
- Real-time vehicle data
- Vehicle command execution
- Works even when vehicle is asleep

### Supported Endpoints

- **State**: `/state` - Get vehicle status
- **Battery**: `/battery` - Battery health
- **Lock/Unlock**: `/lock`, `/unlock`
- **Climate**: `/start_climate`, `/stop_climate`, `/set_temperature`
- **Charging**: `/start_charging`, `/stop_charging`, `/set_charge_limit`
- **Actions**: `/flash`, `/honk`, `/wake`
- **Sentry**: `/enable_sentry_mode`, `/disable_sentry_mode`
- **Trunks**: `/open_front_trunk`, `/open_rear_trunk`

## Technologies Used

### Frontend (Flutter)
- **Flutter** - Cross-platform mobile framework
- **Provider** - State management
- **Dio** - HTTP client for API communication
- **Google Fonts** - Typography
- **Flutter Animate** - Smooth animations
- **Shared Preferences** - Local storage
- **Local Auth** - Biometric authentication

### Backend (Laravel)
- **Laravel 10** - PHP framework
- **MySQL 8.0** - Relational database
- **Redis** - Caching and sessions
- **Nginx** - Web server
- **Docker** - Containerization

## UI/UX Features

- **Modern Dark Theme** with gradient accents
- **Smooth animations** on all interactions
- **Responsive design** for different screen sizes
- **Visual feedback** for all actions
- **Pull-to-refresh** for real-time updates
- **Snackbar notifications** for action confirmation
- **Color-coded status** indicators

## Development

### Adding New Features

1. Add endpoint to `lib/constants/api_constants.dart`
2. Create service method in `lib/services/tessie_api_service.dart`
3. Add provider method in `lib/providers/vehicle_provider.dart`
4. Update UI in relevant screen

### Customization

- **Colors**: Edit `lib/utils/app_theme.dart`
- **Animations**: Modify `.animate()` chains in widgets
- **API endpoints**: Update `lib/constants/api_constants.dart`

## Security Notes

- Never commit your `.env` file with real credentials
- The `.env` file is gitignored by default
- Store API keys securely
- Use environment variables in production

## Troubleshooting

### API Connection Issues
- Verify your API key is correct in `.env`
- Check your internet connection
- Ensure your Tesla is linked to Tessie

### Vehicle Not Responding
- Try waking the vehicle first
- Check if vehicle is in service mode
- Verify VIN is correct

## License

This project is for educational purposes. Ensure compliance with Tesla's and Tessie's terms of service.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues with:
- **Tessie API**: Visit [help.tessie.com](https://help.tessie.com)
- **This app**: Open an issue in the repository

## Acknowledgments

- Built with the Tessie API
- Designed for Tesla owners
- Inspired by modern mobile design patterns

---

**Note**: This is an unofficial app and is not affiliated with Tesla, Inc. or Tessie.
