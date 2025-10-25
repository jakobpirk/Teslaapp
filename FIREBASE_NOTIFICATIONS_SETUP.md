# Firebase Cloud Messaging Notification System

This document explains the Firebase-based charging notification system with cloud functions for background monitoring and auto-stop functionality.

## Features

The charging notification system provides:

1. **Firebase Cloud Messaging (FCM)** push notifications:
   - Charging started
   - Charging stopped
   - Target charge level reached
   - Real-time charging progress updates
   - Works even when app is completely closed

2. **Auto-Stop Charging** at user-defined max charge percentage:
   - Set a target battery level (50-100%)
   - Automatically stops charging when target is reached
   - Sends high-priority notification when auto-stop occurs

3. **Cloud Functions Background Monitoring**:
   - Checks charging state every 15 minutes
   - Server-side monitoring (no battery impact on device)
   - Automatic state change detection
   - Direct Tesla API integration

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Mobile/Web)   │
└────────┬────────┘
         │
         ├─ Enables Notifications
         ├─ Sets Max Charge Limit
         │
         ▼
┌─────────────────┐
│   Firestore     │
│  (Settings DB)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Firebase Cloud         │
│  Functions              │
│  ┌──────────────────┐   │
│  │ Scheduled Task   │   │
│  │ (Every 15 min)   │   │
│  └──────────────────┘   │
│         │               │
│         ├─ Get Vehicle State (Tessie API)
│         ├─ Compare with Previous State
│         ├─ Auto-stop if limit reached
│         └─ Send FCM Notifications
└─────────────────────────┘
         │
         ▼
┌─────────────────┐
│  User Device    │
│  (Notification) │
└─────────────────┘
```

## Implementation

### Flutter App Components

1. **FirebaseNotificationService** (`lib/services/firebase_notification_service.dart`)
   - Initializes FCM
   - Manages FCM tokens
   - Handles foreground/background message reception
   - Displays local notifications
   - Topic subscription management

2. **ChargingSettingsService** (`lib/services/charging_settings_service.dart`)
   - Stores max charge limit in SharedPreferences and Firestore
   - Manages monitoring enable/disable state
   - Syncs FCM tokens with Firestore
   - Provides settings to cloud functions

3. **VehicleProvider Updates** (`lib/features/vehicle/presentation/providers/vehicle_provider.dart`)
   - Methods for enabling/disabling notifications
   - Max charge limit management
   - Vehicle-specific topic subscriptions

4. **UI Integration** (`lib/screens/charging_screen.dart`)
   - Auto-Stop Charging section with slider
   - Notifications toggle with feature list
   - Vehicle ID resolution

### Firebase Cloud Functions

Located in `firebase/functions/index.js`:

1. **checkChargingState** (Scheduled)
   - Runs every 15 minutes
   - Queries Firestore for active monitors
   - Fetches vehicle state from Tessie API
   - Detects state changes
   - Sends FCM notifications
   - Auto-stops charging when limit reached

2. **checkVehicleChargingState** (HTTP Callable)
   - Manual trigger for immediate check
   - Used for testing and on-demand updates

3. **onMaxChargeLimitUpdate** (Firestore Trigger)
   - Triggered when max charge limit changes
   - Immediately checks if auto-stop needed

## Setup Guide

### Prerequisites

- Firebase project configured
- Firebase CLI installed: `npm install -g firebase-tools`
- Tessie API key
- Android/iOS app configured (for mobile notifications)

### Step 1: Firebase Project Setup

1. **Create Firebase Project**:
   ```bash
   firebase login
   firebase init
   ```

2. **Select services**:
   - Firestore
   - Functions
   - (Optional) Hosting

3. **Install dependencies**:
   ```bash
   cd firebase/functions
   npm install
   ```

### Step 2: Configure Tessie API Key

Set the Tessie API key in Firebase Functions config:

```bash
firebase functions:config:set tessie.api_key="YOUR_TESSIE_API_KEY"
```

### Step 3: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

The rules in `firestore.rules` ensure:
- Users can only access their own vehicle monitoring data
- Charging sessions are readable by authenticated users
- Pricing data is read-only

### Step 4: Deploy Cloud Functions

```bash
firebase deploy --only functions
```

This deploys:
- `checkChargingState` - Scheduled function (every 15 min)
- `checkVehicleChargingState` - HTTP callable function
- `onMaxChargeLimitUpdate` - Firestore trigger

### Step 5: Configure Mobile Apps

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:label="Tessie"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- FCM notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />

        <!-- Activity config... -->
    </application>
</manifest>
```

Add `google-services.json` to `android/app/`.

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

Add `GoogleService-Info.plist` to `ios/Runner/`.

### Step 6: Test Notifications

1. **Enable notifications in app**
2. **Set max charge limit**
3. **Manually trigger check**:
   ```bash
   firebase functions:shell
   > checkVehicleChargingState({vehicleId: "your-vehicle-id"})
   ```
4. **Monitor logs**:
   ```bash
   firebase functions:log
   ```

## Usage

### For Users

1. **Enable Notifications**:
   - Go to Charging screen
   - Toggle "Charging Notifications"
   - Grant notification permissions

2. **Set Auto-Stop**:
   - Toggle "Auto-Stop Charging"
   - Set target level (50-100%)
   - Charging stops automatically when reached

3. **Notification Types**:
   - **Charging Started**: Shows current battery and target
   - **Charging Stopped**: Shows final battery and reason
   - **Target Reached**: High-priority auto-stop notification
   - **Progress Updates**: Silent progress notifications

### Firestore Data Structure

```
charging_monitors/{vehicleId}
  ├─ vehicleId: string
  ├─ fcmToken: string
  ├─ enabled: boolean
  ├─ maxChargeLimit: number (optional)
  ├─ lastChargingState: boolean
  ├─ lastBatteryLevel: number
  ├─ lastChecked: timestamp
  └─ updatedAt: timestamp
```

## API Integration

### Tessie API Endpoints Used

```
GET  https://api.tessie.com/{vehicleId}/state
POST https://api.tessie.com/{vehicleId}/command/stop_charging
```

**Authentication**: Bearer token in `Authorization` header

**Rate Limiting**: Cloud function checks every 15 minutes (minimum interval to respect API limits)

## Notification Payload Structure

```javascript
{
  notification: {
    title: "Charging Started",
    body: "Battery at 65%. Target: 80%"
  },
  data: {
    type: "charging_started",
    vehicleId: "5YJSA1E26HF123456",
    batteryLevel: "65"
  }
}
```

## Cost Considerations

### Firebase Free Tier (Spark Plan)

- **Cloud Functions**: 2M invocations/month
  - With hourly checks: ~2,880/vehicle/month
  - Can monitor ~694 vehicles on free tier
- **Firestore**: 50K reads, 20K writes/day
  - Sufficient for typical usage
- **FCM**: Unlimited messages

### Estimated Costs (Paid Plan)

For 1 vehicle with 15-min checks:
- **Functions**: ~$0.10/month
- **Firestore**: ~$0.05/month
- **Total**: ~$0.15/month per vehicle

## Troubleshooting

### Notifications Not Received

1. **Check FCM Token**:
   ```dart
   final token = await vehicleProvider.getFcmToken();
   print('FCM Token: $token');
   ```

2. **Verify Firestore**:
   - Check `charging_monitors` collection
   - Ensure `enabled: true` and `fcmToken` is set

3. **Check Function Logs**:
   ```bash
   firebase functions:log --only checkChargingState
   ```

4. **Test FCM Manually**:
   Use Firebase Console > Cloud Messaging > Send test message

### Auto-Stop Not Working

1. **Verify max charge limit in Firestore**:
   ```javascript
   db.collection('charging_monitors').doc('vehicleId').get()
   ```

2. **Check Tessie API connectivity**:
   - Verify API key is configured
   - Check function logs for API errors

3. **Test function manually**:
   ```bash
   firebase functions:shell
   > checkVehicleChargingState({vehicleId: "your-vehicle-id"})
   ```

### Cloud Function Errors

1. **Check Tessie API key**:
   ```bash
   firebase functions:config:get
   ```

2. **View detailed logs**:
   ```bash
   firebase functions:log --only checkChargingState
   ```

3. **Common issues**:
   - Invalid API key
   - Vehicle ID mismatch
   - Network timeouts

## Development

### Local Testing

1. **Start Firebase Emulators**:
   ```bash
   firebase emulators:start
   ```

2. **Test functions locally**:
   ```bash
   cd firebase/functions
   npm run shell
   ```

3. **Run app with emulators**:
   Update Firebase initialization to use emulators

### Function Deployment

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:checkChargingState

# Deploy with debug info
firebase deploy --only functions --debug
```

## Security

### Firestore Security Rules

- Users can only access their own vehicle data
- Cloud functions use admin SDK (bypass rules)
- API keys stored in Firebase Functions config (secure)

### Data Privacy

- FCM tokens stored securely in Firestore
- No personal data in notification payloads
- Vehicle data only accessed via authenticated APIs

## Future Enhancements

1. **Dynamic Check Frequency**:
   - Increase frequency when charging
   - Reduce when idle

2. **Smart Scheduling**:
   - Integration with electricity pricing
   - Charge only during cheapest hours

3. **Multi-Vehicle Support**:
   - Monitor multiple vehicles per user
   - Vehicle-specific notification preferences

4. **Advanced Analytics**:
   - Charging patterns
   - Cost savings tracking
   - Battery health monitoring

5. **Notification Customization**:
   - Quiet hours
   - Notification importance levels
   - Custom sound/vibration patterns

## Support

### Logs and Debugging

**Flutter App**:
```bash
flutter logs
```

**Cloud Functions**:
```bash
firebase functions:log
firebase functions:log --only checkChargingState
```

**Firestore**:
- Use Firebase Console > Firestore Database
- Check document timestamps and values

### Common Issues

| Issue | Solution |
|-------|----------|
| No notifications | Check FCM token, verify Firestore entry |
| Auto-stop not working | Verify maxChargeLimit in Firestore |
| Function timeouts | Increase timeout in `firebase.json` |
| API errors | Check Tessie API key configuration |

## Dependencies

**Flutter**:
- `firebase_core: ^2.24.2`
- `firebase_messaging: ^14.7.10`
- `cloud_firestore: ^4.14.0`
- `flutter_local_notifications: ^17.0.0`
- `permission_handler: ^11.0.1`
- `shared_preferences: ^2.2.2`

**Cloud Functions**:
- `firebase-admin: ^11.11.0`
- `firebase-functions: ^4.5.0`
- `axios: ^1.6.0`

## License

This notification system is part of the Tessie app and follows the same license.

## Contributing

When making changes:
1. Update this documentation
2. Test with Firebase emulators
3. Deploy to staging first
4. Monitor function logs for errors
5. Update Firestore security rules if needed
