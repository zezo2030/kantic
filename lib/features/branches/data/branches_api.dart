import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../home/data/models/branch_model.dart';

class BranchesApi {
  final Dio _dio;

  BranchesApi({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<List<BranchModel>> fetchAllBranches({
    bool includeInactive = false,
  }) async {
    final Response response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.branchesEndpoint}',
      queryParameters: includeInactive ? {'includeInactive': '1'} : null,
    );

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((j) => BranchModel.fromJson(j))
          .toList();
    }
    // Some backends wrap list in { items: [] }
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((j) => BranchModel.fromJson(j))
          .toList();
    }
    return <BranchModel>[];
  }
}
