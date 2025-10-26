import 'package:dartz/dartz.dart';
import '../entities/alert_rule_entity.dart';
import '../failures/failure.dart';

/// Repository interface for alert rule operations
abstract class AlertRuleRepository {
  /// Get all alert rules for the user
  Future<Either<Failure, List<AlertRuleEntity>>> getAlertRules();

  /// Get alert rules for a specific vehicle
  Future<Either<Failure, List<AlertRuleEntity>>> getVehicleRules(String vehicleId);

  /// Get a single alert rule
  Future<Either<Failure, AlertRuleEntity>> getRule(String id);

  /// Get rule templates
  Future<Either<Failure, List<Map<String, dynamic>>>> getTemplates();

  /// Create a new alert rule
  Future<Either<Failure, AlertRuleEntity>> createRule(Map<String, dynamic> data);

  /// Update an existing alert rule
  Future<Either<Failure, AlertRuleEntity>> updateRule(String id, Map<String, dynamic> data);

  /// Delete an alert rule
  Future<Either<Failure, void>> deleteRule(String id);

  /// Toggle enable/disable
  Future<Either<Failure, AlertRuleEntity>> toggleRule(String id);

  /// Test an alert rule
  Future<Either<Failure, Map<String, dynamic>>> testRule(String id);
}
