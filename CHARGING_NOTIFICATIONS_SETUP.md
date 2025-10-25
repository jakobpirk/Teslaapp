# Charging Notifications Setup Guide

This document explains the charging notification system and how to configure it for mobile platforms.

## Features

The charging notification system provides:

1. **Push Notifications** for charging events:
   - Charging started
   - Charging stopped
   - Target charge level reached
   - Real-time charging progress updates

2. **Auto-Stop Charging** at a user-defined max charge percentage:
   - Set a target battery level (50-100%)
   - Automatically stops charging when target is reached
   - Sends notification when auto-stop occurs

3. **Background Monitoring**:
   - Checks charging state every 15 minutes
   - Works even when app is closed
   - Minimal battery impact

## Implementation

### Core Components

1. **NotificationService** (`lib/services/notification_service.dart`)
   - Manages all notification types
   - Handles permission requests
   - Provides notification methods for different charging events

2. **ChargingMonitorService** (`lib/services/charging_monitor_service.dart`)
   - Background task management
   - Monitors charging state changes
   - Triggers notifications and auto-stop functionality
   - Stores max charge limit preferences

3. **VehicleProvider Updates** (`lib/features/vehicle/presentation/providers/vehicle_provider.dart`)
   - Integration with monitoring service
   - Methods for enabling/disabling notifications
   - Max charge limit management

4. **UI Integration** (`lib/screens/charging_screen.dart`)
   - Auto-Stop Charging section with slider
   - Notifications toggle with feature list
   - Visual feedback for enabled features

## Usage

### For Users

1. **Enable Notifications**:
   - Go to the Charging screen
   - Toggle "Charging Notifications" switch
   - Grant notification permissions when prompted

2. **Set Auto-Stop Charging**:
   - Toggle "Auto-Stop Charging" switch
   - Use the slider to set target battery level (50-100%)
   - Charging will automatically stop when target is reached

3. **Notification Types**:
   - **Charging Started**: Shows current battery and target level
   - **Charging Stopped**: Shows final battery level and reason
   - **Target Reached**: High-priority notification when auto-stop occurs
   - **Progress Updates**: Ongoing notification during charging

### For Developers

#### Enable Android Support

Since this is currently a web-focused app, to enable notifications on Android:

1. **Add Android Configuration**:
   ```bash
   flutter create --platforms=android .
   ```

2. **Update `android/app/src/main/AndroidManifest.xml`**:
   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android">
       <!-- Add permissions -->
       <uses-permission android:name="android.permission.INTERNET"/>
       <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
       <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
       <uses-permission android:name="android.permission.WAKE_LOCK"/>

       <application
           android:label="Tessie"
           android:name="${applicationName}"
           android:icon="@mipmap/ic_launcher">

           <!-- Notification icon (optional) -->
           <meta-data
               android:name="com.google.firebase.messaging.default_notification_icon"
               android:resource="@drawable/ic_notification" />

           <!-- Workmanager receiver for background tasks -->
           <receiver
               android:name="androidx.work.impl.background.systemalarm.RescheduleReceiver"
               android:enabled="true"
               android:exported="false">
               <intent-filter>
                   <action android:name="android.intent.action.BOOT_COMPLETED"/>
               </intent-filter>
           </receiver>

           <activity
               android:name=".MainActivity"
               android:exported="true"
               android:launchMode="singleTop"
               android:theme="@style/LaunchTheme"
               android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
               android:hardwareAccelerated="true"
               android:windowSoftInputMode="adjustResize">
               <!-- ... rest of activity config ... -->
           </activity>
       </application>
   </manifest>
   ```

3. **Update `android/app/build.gradle`**:
   ```gradle
   android {
       compileSdkVersion 33

       defaultConfig {
           minSdkVersion 21
           targetSdkVersion 33
       }
   }

   dependencies {
       implementation 'androidx.work:work-runtime:2.8.1'
   }
   ```

#### Enable iOS Support

1. **Add iOS Configuration**:
   ```bash
   flutter create --platforms=ios .
   ```

2. **Update `ios/Runner/Info.plist`**:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>fetch</string>
       <string>processing</string>
   </array>
   ```

3. **Request Notification Permissions**:
   Permissions are automatically requested when notifications are enabled in the app.

## Technical Details

### Background Task Frequency

- Background checks run every **15 minutes** (minimum interval for WorkManager)
- Can be adjusted in `charging_monitor_service.dart`:
  ```dart
  frequency: const Duration(minutes: 15)
  ```

### Storage

Settings are stored in SharedPreferences:
- `max_charge_limit`: Target battery percentage (int)
- `monitoring_enabled`: Whether notifications are enabled (bool)
- `last_charging_state`: Previous charging state (bool)
- `last_battery_level`: Previous battery level (int)

### Notification Channels

**Android Channels**:
1. `charging_channel`: Standard charging notifications
2. `charging_progress_channel`: Low-priority ongoing progress notifications

**iOS**: Uses Darwin notification settings with configurable alert, badge, and sound options.

### Battery Impact

The notification system is designed for minimal battery usage:
- Background tasks only run every 15 minutes
- No continuous polling or location services
- Uses Android WorkManager's battery-optimized scheduling
- Notifications are triggered only on state changes

## Testing

### Manual Testing

1. **Test Notification Service**:
   ```dart
   // In charging screen, manually trigger check:
   await provider.checkChargingState();
   ```

2. **Test Auto-Stop**:
   - Enable auto-stop with target < current battery
   - Start charging
   - Verify charging stops when target is reached

3. **Test Background Monitoring**:
   - Enable notifications
   - Close the app
   - Start/stop charging from vehicle
   - Wait up to 15 minutes for notification

### Debug Logging

Enable debug logging in `charging_monitor_service.dart`:
```dart
await Workmanager().initialize(
  callbackDispatcher,
  isInDebugMode: true, // Set to true for logging
);
```

## Troubleshooting

### Notifications Not Appearing

1. **Check Permissions**:
   - Android: Settings > Apps > Tessie > Notifications
   - iOS: Settings > Tessie > Notifications

2. **Verify Background Tasks**:
   - Android: Settings > Apps > Tessie > Battery > Unrestricted

3. **Check Logs**:
   ```bash
   flutter logs
   ```

### Auto-Stop Not Working

1. Verify max charge limit is set:
   ```dart
   final limit = await provider.getMaxChargeLimit();
   print('Max charge limit: $limit');
   ```

2. Check if notifications are enabled (required for auto-stop)

3. Verify Tesla API connectivity

### Background Tasks Not Running

1. **Android Battery Optimization**:
   - Disable battery optimization for the app
   - Some manufacturers (Samsung, Xiaomi, etc.) have aggressive battery savers

2. **Check WorkManager Status**:
   - Use Android Debug Database to inspect WorkManager tasks
   - Verify task is registered and scheduled

## Future Enhancements

Potential improvements:

1. **Customizable Check Frequency**:
   - Allow users to set how often to check (15min - 1hr)
   - Trade-off between responsiveness and battery life

2. **Smart Notifications**:
   - Only notify during specific hours (e.g., 7am-10pm)
   - Notification grouping for multiple events

3. **Charging Schedules**:
   - Start charging at specific times
   - Integration with smart charging recommendations

4. **Historical Data**:
   - Track notification history
   - Auto-stop success rate
   - Charging patterns

5. **Widget Support**:
   - Home screen widget showing battery level
   - Quick toggle for auto-stop

## Dependencies

The notification system uses:

- `flutter_local_notifications: ^17.0.0` - Local push notifications
- `workmanager: ^0.5.2` - Background task scheduling
- `permission_handler: ^11.0.1` - Runtime permission handling
- `shared_preferences: ^2.2.2` - Settings storage

## API Integration

The system integrates with the Tessie API:

- **GET vehicle state**: Check battery level and charging status
- **POST stop_charging**: Automatically stop when target is reached

Rate limiting: Background checks are limited to every 15 minutes to respect API limits.

## Privacy & Security

- All data stored locally on device
- No data sent to third parties
- Notification content can be hidden in lock screen settings
- Background tasks only access vehicle data, no location tracking

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review logs for error messages
3. Verify all dependencies are installed
4. Ensure mobile platform (Android/iOS) is properly configured
