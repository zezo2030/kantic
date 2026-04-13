import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/home_response_model.dart';
import '../models/branch_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeResponseModel> getHomeData();
  Future<BranchModel> getBranchDetails(String branchId);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSourceImpl({required this.dio});

  @override
  Future<HomeResponseModel> getHomeData() async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.homeEndpoint}',
      );

      if (response.data == null) {
        throw Exception('Response data is null');
      }

      return HomeResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<BranchModel> getBranchDetails(String branchId) async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.branchDetailsEndpoint}/$branchId',
      );

      if (response.data == null) {
        throw Exception('Branch details response data is null');
      }

      return BranchModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return Exception('Bad request. Please try again.');
          case 401:
            return Exception('Unauthorized. Please login again.');
          case 403:
            return Exception('Forbidden. You don\'t have permission to access this resource.');
          case 404:
            return Exception('Resource not found.');
          case 500:
            return Exception('Server error. Please try again later.');
          default:
            return Exception('Server error with status code: $statusCode');
        }
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
