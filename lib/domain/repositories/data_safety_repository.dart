import 'package:internsfe/domain/entities/data_safety_result.dart';

abstract class DataSafetyRepository {
  Future<DataSafetyResult> analyze({
    required List<String> requestedData,
    required String stage,
  });
}
