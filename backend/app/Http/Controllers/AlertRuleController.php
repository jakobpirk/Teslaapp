<?php

namespace App\Http\Controllers;

use App\Models\AlertRule;
use App\Services\AlertRuleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class AlertRuleController extends Controller
{
    private AlertRuleService $service;

    public function __construct(AlertRuleService $service)
    {
        $this->service = $service;
    }

    /**
     * Get all alert rules for the authenticated user.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $rules = $this->service->getUserRules($user->id);

        return response()->json([
            'success' => true,
            'data' => $rules,
        ]);
    }

    /**
     * Get alert rules for a specific vehicle.
     */
    public function byVehicle(Request $request, string $vehicleId): JsonResponse
    {
        $user = $request->user();

        // Verify vehicle belongs to user
        $vehicle = $user->vehicles()->findOrFail($vehicleId);

        $rules = $this->service->getVehicleRules($vehicleId);

        return response()->json([
            'success' => true,
            'data' => $rules,
        ]);
    }

    /**
     * Get a specific alert rule.
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $rule = AlertRule::where('user_id', $user->id)
            ->with('vehicle')
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $rule,
        ]);
    }

    /**
     * Create a new alert rule.
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'vehicle_id' => 'nullable|uuid|exists:vehicles,id',
            'name' => 'required|string|max:100',
            'description' => 'nullable|string',
            'rule_type' => [
                'required',
                'string',
                Rule::in([
                    AlertRule::TYPE_NOT_PLUGGED_IN,
                    AlertRule::TYPE_BATTERY_LOW,
                    AlertRule::TYPE_CHARGE_COMPLETE,
                    AlertRule::TYPE_LEFT_UNLOCKED,
                    AlertRule::TYPE_SENTRY_TRIGGERED,
                    AlertRule::TYPE_UNUSUAL_ENERGY,
                    AlertRule::TYPE_CLIMATE_ON,
                    AlertRule::TYPE_SOFTWARE_UPDATE,
                    AlertRule::TYPE_CUSTOM,
                ]),
            ],
            'conditions' => 'required|array',
            'notification_channels' => 'array',
            'notification_channels.*' => 'string|in:push,email,sms',
            'notification_title' => 'nullable|string|max:100',
            'notification_message' => 'nullable|string',
            'is_enabled' => 'boolean',
            'cooldown_minutes' => 'integer|min:1|max:1440',
            'priority' => 'integer|min:1|max:3',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        // Verify vehicle belongs to user if vehicle_id is provided
        if ($request->vehicle_id) {
            $vehicle = $user->vehicles()->findOrFail($request->vehicle_id);
        }

        $data = $validator->validated();
        $data['user_id'] = $user->id;

        $rule = $this->service->createRule($data);

        return response()->json([
            'success' => true,
            'message' => 'Alert rule created successfully',
            'data' => $rule->load('vehicle'),
        ], 201);
    }

    /**
     * Update an alert rule.
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:100',
            'description' => 'nullable|string',
            'conditions' => 'sometimes|array',
            'notification_channels' => 'sometimes|array',
            'notification_channels.*' => 'string|in:push,email,sms',
            'notification_title' => 'nullable|string|max:100',
            'notification_message' => 'nullable|string',
            'is_enabled' => 'sometimes|boolean',
            'cooldown_minutes' => 'sometimes|integer|min:1|max:1440',
            'priority' => 'sometimes|integer|min:1|max:3',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $rule = AlertRule::where('user_id', $user->id)->findOrFail($id);

        $data = $validator->validated();
        $rule = $this->service->updateRule($rule, $data);

        return response()->json([
            'success' => true,
            'message' => 'Alert rule updated successfully',
            'data' => $rule->load('vehicle'),
        ]);
    }

    /**
     * Delete an alert rule.
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $rule = AlertRule::where('user_id', $user->id)->findOrFail($id);

        $this->service->deleteRule($rule);

        return response()->json([
            'success' => true,
            'message' => 'Alert rule deleted successfully',
        ]);
    }

    /**
     * Toggle enable/disable an alert rule.
     */
    public function toggle(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $rule = AlertRule::where('user_id', $user->id)->findOrFail($id);

        $rule->is_enabled = !$rule->is_enabled;
        $rule->save();

        return response()->json([
            'success' => true,
            'message' => 'Alert rule ' . ($rule->is_enabled ? 'enabled' : 'disabled'),
            'data' => $rule->load('vehicle'),
        ]);
    }

    /**
     * Test an alert rule.
     */
    public function test(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $rule = AlertRule::where('user_id', $user->id)->findOrFail($id);

        $result = $this->service->testRule($rule);

        return response()->json([
            'success' => true,
            'message' => 'Alert rule test completed',
            'data' => $result,
        ]);
    }

    /**
     * Get rule templates for creating common alert types.
     */
    public function templates(): JsonResponse
    {
        $templates = [
            [
                'name' => 'Not Plugged In at Home',
                'rule_type' => AlertRule::TYPE_NOT_PLUGGED_IN,
                'conditions' => [
                    'time_after' => '21:00',
                    'days' => [1, 2, 3, 4, 5], // Mon-Fri
                ],
                'notification_title' => 'Vehicle Not Plugged In',
                'notification_message' => 'Your vehicle is not plugged in at home.',
                'cooldown_minutes' => 60,
                'priority' => 2,
            ],
            [
                'name' => 'Low Battery Alert',
                'rule_type' => AlertRule::TYPE_BATTERY_LOW,
                'conditions' => [
                    'threshold' => 20,
                    'when_unplugged' => true,
                ],
                'notification_title' => 'Low Battery',
                'notification_message' => 'Your battery is below 20%.',
                'cooldown_minutes' => 120,
                'priority' => 3,
            ],
            [
                'name' => 'Charging Complete',
                'rule_type' => AlertRule::TYPE_CHARGE_COMPLETE,
                'conditions' => [
                    'notify_at_percentage' => 80,
                ],
                'notification_title' => 'Charging Complete',
                'notification_message' => 'Your vehicle has finished charging.',
                'cooldown_minutes' => 30,
                'priority' => 1,
            ],
            [
                'name' => 'Left Unlocked',
                'rule_type' => AlertRule::TYPE_LEFT_UNLOCKED,
                'conditions' => [
                    'duration_minutes' => 10,
                ],
                'notification_title' => 'Vehicle Unlocked',
                'notification_message' => 'Your vehicle has been left unlocked.',
                'cooldown_minutes' => 30,
                'priority' => 2,
            ],
        ];

        return response()->json([
            'success' => true,
            'data' => $templates,
        ]);
    }
}
