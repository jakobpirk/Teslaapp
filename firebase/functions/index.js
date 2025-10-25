const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Scheduled function to check charging state for all monitored vehicles
 * Runs every 15 minutes
 */
exports.checkChargingState = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    console.log('Starting charging state check...');

    try {
      // Get all active charging monitors
      const monitorsSnapshot = await db.collection('charging_monitors')
        .where('enabled', '==', true)
        .get();

      console.log(`Found ${monitorsSnapshot.size} active monitors`);

      const promises = monitorsSnapshot.docs.map(async (doc) => {
        const data = doc.data();
        const vehicleId = data.vehicleId;
        const fcmToken = data.fcmToken;
        const maxChargeLimit = data.maxChargeLimit;

        try {
          // Get vehicle state from Tessie API
          const vehicleState = await getVehicleState(vehicleId);

          if (vehicleState) {
            await processChargingState(
              vehicleId,
              fcmToken,
              vehicleState,
              maxChargeLimit,
              data
            );
          }
        } catch (error) {
          console.error(`Error processing vehicle ${vehicleId}:`, error);
        }
      });

      await Promise.all(promises);
      console.log('Charging state check completed');
    } catch (error) {
      console.error('Error in checkChargingState:', error);
    }

    return null;
  });

/**
 * Process charging state and send notifications
 */
async function processChargingState(vehicleId, fcmToken, vehicleState, maxChargeLimit, previousData) {
  const { batteryLevel, isCharging, chargingState } = vehicleState;
  const wasCharging = previousData.lastChargingState || false;
  const lastBatteryLevel = previousData.lastBatteryLevel || 0;

  console.log(`Processing ${vehicleId}: Battery ${batteryLevel}%, Charging: ${isCharging}`);

  // Detect charging started
  if (isCharging && !wasCharging) {
    await sendNotification(fcmToken, {
      title: 'Charging Started',
      body: `Battery at ${batteryLevel}%${maxChargeLimit ? `. Target: ${maxChargeLimit}%` : ''}`,
      data: {
        type: 'charging_started',
        vehicleId,
        batteryLevel: batteryLevel.toString(),
      },
    });
  }

  // Detect charging stopped
  if (!isCharging && wasCharging) {
    const reason = batteryLevel >= 100
      ? 'Fully charged'
      : maxChargeLimit && batteryLevel >= maxChargeLimit
        ? 'Target reached'
        : 'Charging interrupted';

    await sendNotification(fcmToken, {
      title: 'Charging Stopped',
      body: `Battery at ${batteryLevel}%. ${reason}`,
      data: {
        type: 'charging_stopped',
        vehicleId,
        batteryLevel: batteryLevel.toString(),
        reason,
      },
    });
  }

  // Check if max charge limit reached (auto-stop)
  if (isCharging && maxChargeLimit && batteryLevel >= maxChargeLimit) {
    console.log(`Max charge limit reached for ${vehicleId}: ${batteryLevel}% >= ${maxChargeLimit}%`);

    // Stop charging via Tessie API
    await stopCharging(vehicleId);

    // Send high-priority notification
    await sendNotification(fcmToken, {
      title: 'Charge Limit Reached',
      body: `Battery reached ${batteryLevel}% (target: ${maxChargeLimit}%). Charging stopped automatically.`,
      data: {
        type: 'max_charge_reached',
        vehicleId,
        batteryLevel: batteryLevel.toString(),
        maxChargeLimit: maxChargeLimit.toString(),
      },
    }, true); // High priority
  }

  // Send progress notification if charging and battery changed
  if (isCharging && maxChargeLimit && batteryLevel < maxChargeLimit && batteryLevel !== lastBatteryLevel) {
    await sendNotification(fcmToken, {
      title: 'Charging Progress',
      body: `Battery: ${batteryLevel}% / ${maxChargeLimit}%`,
      data: {
        type: 'charging_progress',
        vehicleId,
        batteryLevel: batteryLevel.toString(),
        maxChargeLimit: maxChargeLimit.toString(),
      },
    }, false, true); // Low priority, silent
  }

  // Update last known state
  await db.collection('charging_monitors').doc(vehicleId).update({
    lastChargingState: isCharging,
    lastBatteryLevel: batteryLevel,
    lastChecked: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Get vehicle state from Tessie API
 */
async function getVehicleState(vehicleId) {
  const apiKey = functions.config().tessie?.api_key;

  if (!apiKey) {
    console.error('Tessie API key not configured');
    return null;
  }

  try {
    const response = await axios.get(
      `https://api.tessie.com/${vehicleId}/state`,
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
        },
      }
    );

    const data = response.data;

    return {
      batteryLevel: data.charge_state?.battery_level || 0,
      isCharging: data.charge_state?.charging_state === 'Charging',
      chargingState: data.charge_state?.charging_state,
      batteryRange: data.charge_state?.battery_range,
      chargeRate: data.charge_state?.charge_rate,
    };
  } catch (error) {
    console.error(`Error fetching vehicle state for ${vehicleId}:`, error.message);
    return null;
  }
}

/**
 * Stop charging via Tessie API
 */
async function stopCharging(vehicleId) {
  const apiKey = functions.config().tessie?.api_key;

  if (!apiKey) {
    console.error('Tessie API key not configured');
    return;
  }

  try {
    await axios.post(
      `https://api.tessie.com/${vehicleId}/command/stop_charging`,
      {},
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
        },
      }
    );
    console.log(`Successfully stopped charging for ${vehicleId}`);
  } catch (error) {
    console.error(`Error stopping charging for ${vehicleId}:`, error.message);
  }
}

/**
 * Send FCM notification
 */
async function sendNotification(fcmToken, payload, highPriority = false, silent = false) {
  if (!fcmToken) {
    console.log('No FCM token provided, skipping notification');
    return;
  }

  const message = {
    token: fcmToken,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: payload.data,
    android: {
      priority: highPriority ? 'high' : 'normal',
      notification: {
        channelId: 'charging_channel',
        sound: silent ? undefined : 'default',
        priority: highPriority ? 'high' : 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: payload.title,
            body: payload.body,
          },
          sound: silent ? undefined : 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log('Successfully sent notification:', response);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

/**
 * HTTP endpoint to manually trigger charging state check for a specific vehicle
 */
exports.checkVehicleChargingState = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to check charging state.'
    );
  }

  const vehicleId = data.vehicleId;

  if (!vehicleId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Vehicle ID is required.'
    );
  }

  try {
    // Get monitor data
    const monitorDoc = await db.collection('charging_monitors').doc(vehicleId).get();

    if (!monitorDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Vehicle monitoring not configured.'
      );
    }

    const data = monitorDoc.data();
    const vehicleState = await getVehicleState(vehicleId);

    if (vehicleState) {
      await processChargingState(
        vehicleId,
        data.fcmToken,
        vehicleState,
        data.maxChargeLimit,
        data
      );
    }

    return { success: true, vehicleState };
  } catch (error) {
    console.error('Error in checkVehicleChargingState:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Trigger when max charge limit is updated
 */
exports.onMaxChargeLimitUpdate = functions.firestore
  .document('charging_monitors/{vehicleId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if max charge limit changed
    if (before.maxChargeLimit !== after.maxChargeLimit) {
      const vehicleId = context.params.vehicleId;
      console.log(`Max charge limit updated for ${vehicleId}: ${before.maxChargeLimit} -> ${after.maxChargeLimit}`);

      // If monitoring is enabled, immediately check charging state
      if (after.enabled) {
        const vehicleState = await getVehicleState(vehicleId);

        if (vehicleState) {
          await processChargingState(
            vehicleId,
            after.fcmToken,
            vehicleState,
            after.maxChargeLimit,
            after
          );
        }
      }
    }

    return null;
  });

/**
 * Scheduled function to fetch Aura electricity prices daily after 17:00 (5 PM CET)
 * Tomorrow's prices are typically released after 17:00 today
 * Runs every day at 17:05 CET (Central European Time)
 */
exports.fetchAuraPrices = functions.pubsub
  .schedule('5 17 * * *')
  .timeZone('Europe/Copenhagen') // CET/CEST timezone
  .onRun(async (context) => {
    console.log('Starting daily Aura price retrieval...');

    const backendUrl = functions.config().backend?.url;

    if (!backendUrl) {
      console.error('Backend URL not configured. Set it with: firebase functions:config:set backend.url="https://your-backend-url"');
      return null;
    }

    try {
      // Calculate tomorrow's date
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const dateString = tomorrow.toISOString().split('T')[0]; // YYYY-MM-DD format

      console.log(`Fetching Aura prices for ${dateString}...`);

      // Call the backend API to fetch and store Aura prices
      // This endpoint should be created in the Laravel backend
      const response = await axios.post(
        `${backendUrl}/api/v1/aura/fetch-prices`,
        {
          date: dateString,
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'X-Scheduled-Task': 'true', // Special header for scheduled tasks
          },
        }
      );

      if (response.data.success) {
        console.log(`Successfully fetched Aura prices for ${dateString}`);
        console.log(`East region hours fetched: ${response.data.east_hours || 0}`);
        console.log(`West region hours fetched: ${response.data.west_hours || 0}`);
      } else {
        console.error(`Failed to fetch Aura prices: ${response.data.message}`);
      }
    } catch (error) {
      console.error('Error fetching Aura prices:', error.message);
      if (error.response) {
        console.error('Response status:', error.response.status);
        console.error('Response data:', error.response.data);
      }
    }

    return null;
  });

/**
 * HTTP endpoint to manually trigger Aura price fetch
 */
exports.fetchAuraPricesManual = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated (optional - can make it admin-only)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to trigger price fetch.'
    );
  }

  const backendUrl = functions.config().backend?.url;

  if (!backendUrl) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Backend URL not configured.'
    );
  }

  const date = data.date; // Optional: specific date to fetch (format: YYYY-MM-DD)

  try {
    const targetDate = date || (() => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      return tomorrow.toISOString().split('T')[0];
    })();

    console.log(`Manually fetching Aura prices for ${targetDate}...`);

    const response = await axios.post(
      `${backendUrl}/api/v1/aura/fetch-prices`,
      { date: targetDate },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-Manual-Trigger': 'true',
        },
      }
    );

    return {
      success: response.data.success || false,
      message: response.data.message || 'Price fetch completed',
      data: response.data,
    };
  } catch (error) {
    console.error('Error in manual price fetch:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
