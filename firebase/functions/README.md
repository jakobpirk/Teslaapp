# Firebase Cloud Functions for Charging Notifications

This directory contains Firebase Cloud Functions that monitor Tesla vehicle charging state and send push notifications via Firebase Cloud Messaging (FCM).

## Functions

### 1. `checkChargingState` (Scheduled)

**Trigger**: PubSub schedule (every 15 minutes)

**Purpose**: Monitor all enabled vehicles for charging state changes

**Process**:
1. Query Firestore for active monitoring entries
2. For each vehicle:
   - Fetch current state from Tessie API
   - Compare with last known state
   - Detect charging started/stopped
   - Check if max charge limit reached
   - Send appropriate FCM notifications
   - Update Firestore with latest state

### 2. `checkVehicleChargingState` (HTTP Callable)

**Trigger**: Called from Flutter app

**Purpose**: Manually trigger charging state check for specific vehicle

**Parameters**:
```javascript
{
  vehicleId: string // Vehicle VIN or identifier
}
```

**Usage**:
```dart
final callable = FirebaseFunctions.instance.httpsCallable('checkVehicleChargingState');
final result = await callable.call({'vehicleId': 'your-vehicle-id'});
```

### 3. `onMaxChargeLimitUpdate` (Firestore Trigger)

**Trigger**: Firestore document update (`charging_monitors/{vehicleId}`)

**Purpose**: Immediately check if vehicle needs to be stopped when max charge limit is updated

**Process**:
1. Detect `maxChargeLimit` field change
2. If monitoring is enabled, check current state
3. Auto-stop if already at or above new limit

## Setup

### Install Dependencies

```bash
npm install
```

### Configure Tessie API Key

```bash
firebase functions:config:set tessie.api_key="YOUR_TESSIE_API_KEY_HERE"
```

### Deploy

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:checkChargingState
```

## Development

### Local Testing

1. **Start emulators**:
   ```bash
   firebase emulators:start --only functions,firestore
   ```

2. **Set up local config**:
   ```bash
   firebase functions:config:get > .runtimeconfig.json
   ```

3. **Test function**:
   ```bash
   npm run shell
   > checkChargingState()
   > checkVehicleChargingState({vehicleId: "test-vehicle"})
   ```

### Debugging

**View logs**:
```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only checkChargingState

# Follow logs in real-time
firebase functions:log --only checkChargingState --follow
```

**Test FCM sending**:
```javascript
const messaging = admin.messaging();
const message = {
  token: 'device-fcm-token',
  notification: {
    title: 'Test Notification',
    body: 'Testing FCM from Cloud Function'
  }
};

messaging.send(message)
  .then(response => console.log('Success:', response))
  .catch(error => console.error('Error:', error));
```

## Environment Variables

Set via Firebase Functions config:

```bash
# Set Tessie API key
firebase functions:config:set tessie.api_key="your-api-key"

# View current config
firebase functions:config:get

# Clear config (careful!)
firebase functions:config:unset tessie
```

## Firestore Schema

### Collection: `charging_monitors`

Document ID: `{vehicleId}`

```javascript
{
  vehicleId: string,          // Vehicle VIN or identifier
  fcmToken: string,           // Device FCM token for notifications
  enabled: boolean,           // Is monitoring active?
  maxChargeLimit: number,     // Target battery % for auto-stop (optional)
  lastChargingState: boolean, // Was vehicle charging last check?
  lastBatteryLevel: number,   // Battery level from last check
  lastChecked: timestamp,     // Last time function checked this vehicle
  updatedAt: timestamp        // Last time settings were updated
}
```

## Tessie API Integration

### Endpoints Used

**Get Vehicle State**:
```http
GET https://api.tessie.com/{vehicleId}/state
Authorization: Bearer {api_key}
```

**Stop Charging**:
```http
POST https://api.tessie.com/{vehicleId}/command/stop_charging
Authorization: Bearer {api_key}
```

### Response Structure

```javascript
{
  charge_state: {
    battery_level: 75,           // Battery percentage
    charging_state: "Charging",  // "Charging", "Complete", "Disconnected"
    battery_range: 245.6,        // Miles of range
    charge_rate: 45              // kW charging rate
  }
}
```

## FCM Notification Structure

### Charging Started
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
  },
  android: {
    priority: "normal",
    notification: {
      channelId: "charging_channel",
      sound: "default"
    }
  }
}
```

### Max Charge Reached
```javascript
{
  notification: {
    title: "Charge Limit Reached",
    body: "Battery reached 80% (target: 80%). Charging stopped automatically."
  },
  data: {
    type: "max_charge_reached",
    vehicleId: "5YJSA1E26HF123456",
    batteryLevel: "80",
    maxChargeLimit: "80"
  },
  android: {
    priority: "high",  // High priority for important event
    notification: {
      channelId: "charging_channel",
      sound: "default"
    }
  }
}
```

## Error Handling

### Tessie API Errors

```javascript
try {
  const response = await axios.get(`https://api.tessie.com/${vehicleId}/state`, {
    headers: { 'Authorization': `Bearer ${apiKey}` }
  });
} catch (error) {
  if (error.response?.status === 401) {
    console.error('Invalid Tessie API key');
  } else if (error.response?.status === 404) {
    console.error('Vehicle not found');
  } else {
    console.error('API error:', error.message);
  }
}
```

### FCM Errors

```javascript
try {
  await messaging.send(message);
} catch (error) {
  if (error.code === 'messaging/registration-token-not-registered') {
    // Token is invalid, remove from Firestore
    await db.collection('charging_monitors').doc(vehicleId).update({
      fcmToken: admin.firestore.FieldValue.delete()
    });
  }
}
```

## Performance

### Execution Time

- Average: 2-3 seconds per vehicle
- With 10 vehicles: ~30 seconds total
- Function timeout: 540 seconds (default)

### Cost Estimation

**Free Tier (Spark Plan)**:
- 2M function invocations/month
- Hourly checks: 2,880 invocations/vehicle/month
- Can monitor ~694 vehicles on free tier

**Paid Plan (Blaze)**:
- $0.40 per 1M invocations
- $0.0000025 per GB-second
- ~$0.10/month per vehicle with 15-min checks

## Monitoring

### Cloud Functions Dashboard

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project
3. Navigate to Functions
4. View metrics, logs, and health

### Alerts

Set up alerts for:
- Function errors
- High execution time
- API failures

```bash
# Create alert in Firebase Console
Functions > checkChargingState > Metrics > Create Alert
```

## Testing Checklist

Before deploying:

- [ ] Tessie API key configured
- [ ] Functions deploy successfully
- [ ] Firestore rules deployed
- [ ] Test manual trigger works
- [ ] Verify FCM notifications received
- [ ] Check auto-stop functionality
- [ ] Monitor function logs for errors
- [ ] Test with multiple vehicles

## Troubleshooting

### Function Not Running

1. Check scheduler:
   ```bash
   gcloud scheduler jobs list
   ```

2. Manually trigger:
   ```bash
   gcloud scheduler jobs run checkChargingState
   ```

### No Notifications Sent

1. Check FCM token validity
2. Verify `enabled: true` in Firestore
3. Check function logs for errors
4. Test FCM manually in Firebase Console

### API Errors

1. Verify Tessie API key:
   ```bash
   firebase functions:config:get tessie.api_key
   ```

2. Test API directly:
   ```bash
   curl -H "Authorization: Bearer YOUR_API_KEY" \
        https://api.tessie.com/{vehicleId}/state
   ```

## Support

For issues:
1. Check function logs: `firebase functions:log`
2. Review Firestore data structure
3. Test with emulators locally
4. Check Tessie API status

## Version

- **Node.js**: 18
- **firebase-functions**: ^4.5.0
- **firebase-admin**: ^11.11.0
