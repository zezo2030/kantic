// Booking Repository Implementation - Data Layer
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/entities/hall_slots_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_request_model.dart';
import '../models/quote_request_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<BookingEntity> createBooking({
    required String branchId,
    required DateTime startTime,
    required int durationHours,
    required int persons,
    String? couponCode,
    List<Map<String, dynamic>>? addOns,
    String? specialRequests,
    String? contactPhone,
  }) async {
    try {
      // Convert to UTC before sending to ensure consistent timezone handling
      final startTimeUtc = startTime.isUtc ? startTime : startTime.toUtc();
      final request = BookingRequestModel(
        branchId: branchId,
        startTime: startTimeUtc.toIso8601String(),
        durationHours: durationHours,
        persons: persons,
        couponCode: couponCode,
        addOns: addOns,
        specialRequests: specialRequests,
        contactPhone: contactPhone,
      );

      final bookingModel = await remoteDataSource.createBooking(request);
      return bookingModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuoteEntity> getQuote({
    required String branchId,
    required DateTime startTime,
    required int durationHours,
    required int persons,
    List<Map<String, dynamic>>? addOns,
    String? couponCode,
  }) async {
    try {
      // #region agent log
      final startIso = startTime.toIso8601String();
      final startUtc = startTime.isUtc ? startTime : startTime.toUtc();
      final startUtcIso = startUtc.toIso8601String();
      final now = DateTime.now();
      final nowUtc = now.toUtc();
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'C',
        'location': 'booking_repository_impl.dart:58',
        'message': 'Converting DateTime to ISO8601 string (UTC)',
        'data': {
          'startTimeLocal': startIso,
          'startTimeUtc': startUtcIso,
          'nowLocal': now.toIso8601String(),
          'nowUtc': nowUtc.toIso8601String(),
          'isUtc': startTime.isUtc,
          'timezoneOffset': startTime.timeZoneOffset.inHours,
          'timeDiffMs': startTime.difference(now).inMilliseconds,
          'sendingUtc': startUtcIso,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      try {
        final file = await File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log').open(mode: FileMode.append);
        await file.writeString('${jsonEncode(logData)}\n');
        await file.close();
      } catch (e) {
      }
      // #endregion
      
      // Convert to UTC before sending to ensure consistent timezone handling
      final startTimeUtc = startTime.isUtc ? startTime : startTime.toUtc();
      final request = QuoteRequestModel(
        branchId: branchId,
        startTime: startTimeUtc.toIso8601String(),
        durationHours: durationHours,
        persons: persons,
        addOns: addOns,
        couponCode: couponCode,
      );

      // #region agent log
      final requestJson = request.toJson();
      final logData2 = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'D',
        'location': 'booking_repository_impl.dart:65',
        'message': 'Request JSON being sent to server',
        'data': {
          'requestJson': requestJson,
          'startTimeInRequest': requestJson['startTime'],
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      try {
        final file2 = await File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log').open(mode: FileMode.append);
        await file2.writeString('${jsonEncode(logData2)}\n');
        await file2.close();
      } catch (e) {
      }
      // #endregion

      final quoteModel = await remoteDataSource.getQuote(request);
      return quoteModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> checkAvailability({
    required String branchId,
    required DateTime startTime,
    required int durationHours,
  }) async {
    try {
      // Convert to UTC before sending to ensure consistent timezone handling
      final startTimeUtc = startTime.isUtc ? startTime : startTime.toUtc();
      return await remoteDataSource.checkAvailability(
        branchId,
        startTimeUtc.toIso8601String(),
        durationHours,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> checkServerHealth() async {
    try {
      return await remoteDataSource.checkServerHealth();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<BranchSlotsEntity> getBranchSlots({
    required String branchId,
    required DateTime date,
    int durationHours = 1,
    int? slotMinutes,
    int? persons,
  }) async {
    try {
      final response = await remoteDataSource.getBranchSlots(
        branchId: branchId,
        date: date.toIso8601String(),
        durationHours: durationHours,
        slotMinutes: slotMinutes,
        persons: persons,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
