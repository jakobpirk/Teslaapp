# Clean Architecture Documentation

This document describes the clean architecture implementation for the Tessie Tesla API Flutter application.

## Overview

The application has been refactored to follow Clean Architecture principles, providing clear separation of concerns and making the codebase more maintainable, testable, and scalable.

## Architecture Layers

### 1. Domain Layer (`lib/core/domain/`)

The innermost layer containing business logic and entities. This layer has no dependencies on external frameworks or libraries.

#### Entities (`entities/`)
Pure business objects that represent the core data structures:
- `vehicle_entity.dart` - Represents vehicle state and properties

#### Repository Interfaces (`repositories/`)
Abstract contracts defining data operations:
- `vehicle_repository.dart` - Interface for all vehicle-related operations

#### Use Cases (`usecases/`)
Single-responsibility business logic operations:
- `get_vehicle_state.dart` - Retrieve vehicle state
- `wake_vehicle.dart` - Wake up the vehicle
- `vehicle_lock_operations.dart` - Lock/unlock operations
- `vehicle_alert_operations.dart` - Flash lights, honk horn
- `climate_operations.dart` - Climate control operations
- `charging_operations.dart` - Charging control operations
- `security_operations.dart` - Sentry mode operations
- `vehicle_access_operations.dart` - Frunk, trunk, windows operations

#### Failures (`failures/`)
Domain-specific error types:
- `ServerFailure` - Server-related errors
- `NetworkFailure` - Network connectivity errors
- `AuthenticationFailure` - Authentication errors
- `VehicleFailure` - Vehicle-specific errors

### 2. Data Layer (`lib/core/data/`)

Responsible for data management and implementing repository interfaces.

#### Models/DTOs (`models/`)
Data Transfer Objects for API responses:
- `vehicle_dto.dart` - Raw API response structure

#### Mappers (`mappers/`)
Convert between DTOs and domain entities:
- `vehicle_mapper.dart` - DTO ↔ Entity conversion

#### Data Sources (`datasources/`)
- `vehicle_remote_data_source.dart` - HTTP API client implementation

#### Repository Implementation (`repositories/`)
- `vehicle_repository_impl.dart` - Implements domain repository interface
  - Handles data fetching
  - Error handling and conversion to domain failures
  - Maps DTOs to entities

### 3. Presentation Layer (`lib/features/vehicle/presentation/`)

UI and state management layer.

#### Providers (`providers/`)
- `vehicle_provider.dart` - State management using ChangeNotifier
  - Depends only on use cases (not data layer directly)
  - Manages UI state
  - Handles user interactions

#### Screens (`lib/screens/`)
- `home_screen.dart` - Main dashboard
- `climate_screen.dart` - Climate controls
- `charging_screen.dart` - Charging management

#### Widgets (`lib/widgets/`)
- `status_card.dart` - Reusable status display
- `action_button.dart` - Reusable action button

## Dependency Flow

```
Presentation Layer (UI/Providers)
        ↓ (depends on)
Domain Layer (Use Cases/Entities/Repository Interfaces)
        ↑ (implemented by)
Data Layer (Repository Impl/Data Sources/DTOs)
```

**Key Principle**: Dependencies point inward. The domain layer has no dependencies on outer layers.

## Dependency Injection

Implemented using `get_it` package (`lib/core/di/injection_container.dart`):

```dart
// Initialize dependencies
await initializeDependencies();

// Access dependencies
final provider = sl<VehicleProvider>();
```

### Registered Dependencies:
1. External: HTTP Client
2. Data Sources: Remote API client
3. Repositories: Vehicle repository implementation
4. Use Cases: All business logic operations
5. Providers: State management

## Error Handling

Uses the `Either` pattern from the `dartz` package:

```dart
// Success case
Right(vehicleEntity)

// Failure case
Left(ServerFailure("Error message"))
```

All use cases return `Future<Either<Failure, Result>>` for type-safe error handling.

## Key Benefits

### 1. Separation of Concerns
- Each layer has a single, well-defined responsibility
- Business logic isolated from UI and data concerns

### 2. Testability
- Domain layer can be tested independently
- Use cases can be tested with mocked repositories
- Providers can be tested with mocked use cases

### 3. Maintainability
- Changes to API don't affect business logic
- UI changes don't affect core functionality
- Easy to understand and modify

### 4. Scalability
- Easy to add new features following the same pattern
- Can swap implementations (e.g., add local caching) without changing domain layer

### 5. Type Safety
- Either pattern provides compile-time error handling
- No silent failures or uncaught exceptions

## Usage Example

### Adding a New Feature

1. **Domain Layer**: Define entity, use case, and repository method
2. **Data Layer**: Implement repository method and data source
3. **Dependency Injection**: Register new use case
4. **Presentation**: Inject use case into provider and use in UI

### Example: Lock Vehicle

```dart
// 1. Domain: Use Case
class LockVehicle extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  Future<Either<Failure, void>> call() {
    return repository.lockVehicle();
  }
}

// 2. Data: Repository Implementation
Future<Either<Failure, void>> lockVehicle() async {
  try {
    await remoteDataSource.lockVehicle();
    return Right(null);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}

// 3. Presentation: Provider
Future<void> lock() async {
  final result = await lockVehicle.call();
  result.fold(
    (failure) => _error = failure.message,
    (_) => await refreshVehicleState(),
  );
}

// 4. UI: Call provider method
await provider.lock();
```

## Dependencies

### Core
- `dartz: ^0.10.1` - Functional programming utilities (Either pattern)
- `get_it: ^7.6.4` - Dependency injection

### State Management
- `provider: ^6.1.1` - State management

### HTTP
- `http: ^1.1.2` - HTTP client

## File Structure

```
lib/
├── core/
│   ├── domain/
│   │   ├── entities/
│   │   │   └── vehicle_entity.dart
│   │   ├── repositories/
│   │   │   └── vehicle_repository.dart
│   │   ├── usecases/
│   │   │   ├── usecase.dart
│   │   │   ├── get_vehicle_state.dart
│   │   │   ├── wake_vehicle.dart
│   │   │   ├── vehicle_lock_operations.dart
│   │   │   ├── vehicle_alert_operations.dart
│   │   │   ├── climate_operations.dart
│   │   │   ├── charging_operations.dart
│   │   │   ├── security_operations.dart
│   │   │   └── vehicle_access_operations.dart
│   │   └── failures/
│   │       └── failure.dart
│   ├── data/
│   │   ├── models/
│   │   │   └── vehicle_dto.dart
│   │   ├── mappers/
│   │   │   └── vehicle_mapper.dart
│   │   ├── datasources/
│   │   │   └── vehicle_remote_data_source.dart
│   │   └── repositories/
│   │       └── vehicle_repository_impl.dart
│   └── di/
│       └── injection_container.dart
├── features/
│   └── vehicle/
│       └── presentation/
│           └── providers/
│               └── vehicle_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── climate_screen.dart
│   └── charging_screen.dart
├── widgets/
│   ├── status_card.dart
│   └── action_button.dart
├── utils/
│   └── app_theme.dart
├── constants/
│   └── api_constants.dart
└── main.dart
```

## Testing Strategy

### Unit Tests
- Domain layer: Test use cases with mocked repositories
- Data layer: Test repository implementation with mocked data sources
- Presentation layer: Test providers with mocked use cases

### Integration Tests
- Test complete flows through all layers

### Widget Tests
- Test UI components in isolation

## Future Enhancements

1. **Local Caching**: Add local data source for offline support
2. **Background Sync**: Periodic state updates
3. **Push Notifications**: Real-time vehicle alerts
4. **Multiple Vehicles**: Support for multiple Tesla vehicles
5. **Analytics**: Track usage patterns
6. **Error Logging**: Centralized error tracking

## Migration Notes

### Breaking Changes
- Provider method names have been updated to be more concise
- Direct API service access removed
- State now uses domain entities instead of DTOs

### Migration Path
1. Run `flutter pub get` to install new dependencies
2. Update any custom code referencing old provider methods
3. Test all features to ensure proper functionality

## Conclusion

This clean architecture implementation provides a solid foundation for the Tessie app, making it easier to maintain, test, and extend with new features while keeping the codebase organized and scalable.
