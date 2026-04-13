// Booking Wizard Page - Multi-step booking flow
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../../core/routes/app_route_generator.dart';
import '../widgets/date_time_selector.dart';
import '../widgets/duration_selector.dart';
import '../widgets/persons_input.dart';
import '../widgets/booking_summary_card.dart';
import '../widgets/coupon_input.dart';
import '../widgets/addons_selector.dart';
import '../widgets/special_requests_input.dart';
import '../widgets/contact_phone_input.dart';
import '../widgets/price_breakdown_card.dart';
import '../widgets/slot_selector.dart';
import '../../domain/entities/addon_entity.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/entities/time_slot_entity.dart';
import 'booking_details_page.dart';
import '../../di/booking_injection.dart' as booking_di;

class BookingWizardPage extends StatefulWidget {
  final String branchId;
  final String branchName;

  const BookingWizardPage({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  State<BookingWizardPage> createState() => _BookingWizardPageState();
}

class _BookingWizardPageState extends State<BookingWizardPage> {
  // Current step (0-3)
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 1: Date, Time, Slot
  DateTime? selectedDate;
  TimeSlotEntity? selectedSlot;
  int durationHours = 2;
  int slotMinutes = 60;
  List<TimeSlotEntity> availableSlots = [];
  bool isLoadingSlots = false;
  String? slotsError;
  int? maxDurationForSlot;

  // Step 2: Add-ons
  List<String> selectedAddOnIds = [];
  List<Map<String, dynamic>> selectedAddOns = [];
  List<AddOnEntity> availableAddOns = [];

  // Step 3: Persons
  int personsCount = 10;
  String? contactPhone;

  // Step 4: Review & Confirm
  String? couponCode;
  String? specialRequests;
  QuoteEntity? currentQuote;
  bool isLoadingQuote = false;
  
  // BookingCubit instance
  late BookingCubit _bookingCubit;

  @override
  void initState() {
    super.initState();
    _bookingCubit = booking_di.sl<BookingCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if user is guest
      final authState = context.read<AuthCubit>().state;
      if (authState is Guest) {
        // Redirect to login
        Navigator.of(context).pop();
        Navigator.pushNamed(context, AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('login_required'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      _loadAddOns();
    });
  }
  
  @override
  void dispose() {
    _bookingCubit.close();
    super.dispose();
  }

  Future<void> _loadAddOns() async {
    try {
      final response = await DioClient.instance.get(
        '${ApiConstants.baseUrl}/content/branches/${widget.branchId}/addons',
      );
      final data = response.data;
      if (data is List) {
        setState(() {
          availableAddOns = data
              .map(
                (e) => AddOnEntity(
                  id: e['id'] as String,
                  name: (e['name'] ?? '') as String,
                  price: (e['price'] as num?)?.toDouble() ?? 0.0,
                  quantity: (e['defaultQuantity'] as int?) ?? 1,
                ),
              )
              .toList();
        });
      }
    } catch (_) {
      // Fallback to mock data if API fails
      setState(() {
        availableAddOns = [
          const AddOnEntity(
            id: '11111111-1111-1111-1111-111111111111',
            name: 'Decoration Package',
            price: 150.0,
            quantity: 1,
          ),
          const AddOnEntity(
            id: '22222222-2222-2222-2222-222222222222',
            name: 'Sound System',
            price: 100.0,
            quantity: 1,
          ),
          const AddOnEntity(
            id: '33333333-3333-3333-3333-333333333333',
            name: 'Lighting Package',
            price: 80.0,
            quantity: 1,
          ),
        ];
      });
    }
  }

  void _fetchSlotsForDate() {
    final date = selectedDate;
    if (date == null) {
      setState(() {
        availableSlots = [];
        slotsError = null;
        selectedSlot = null;
      });
      return;
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);
    _bookingCubit.fetchBranchSlots(
          branchId: widget.branchId,
          date: normalizedDate,
          durationHours: durationHours,
          persons: personsCount,
        );
  }

  void _onSlotSelected(TimeSlotEntity slot) {
    setState(() {
      selectedSlot = slot;
      selectedDate = DateTime(slot.start.year, slot.start.month, slot.start.day);
      
      // Calculate max duration from consecutive slots
      var maxHours = (slot.consecutiveSlots * slotMinutes) ~/ 60;
      if (maxHours == 0 && slot.consecutiveSlots > 0) {
        maxHours = 1;
      }
      maxDurationForSlot = maxHours > 0 ? maxHours : null;
      
      // Adjust duration if it exceeds max
      if (maxDurationForSlot != null && durationHours > maxDurationForSlot!) {
        durationHours = maxDurationForSlot!;
      }
    });
    _requestQuote();
  }

  void _requestQuote() async {
    if (selectedSlot == null) return;

    // #region agent log
    final clientNow = DateTime.now();
    final clientNowUtc = clientNow.toUtc();
    final clientNowIso = clientNow.toIso8601String();
    final clientNowUtcIso = clientNowUtc.toIso8601String();
    // #endregion

    // نضيف هامش زمني صغير (دقيقة واحدة) لتجنب مشاكل التوقيت
    final now = DateTime.now().add(const Duration(minutes: 1));
    final start = selectedSlot!.start;
    
    // #region agent log
    final startUtc = start.toUtc();
    final startIso = start.toIso8601String();
    final startUtcIso = startUtc.toIso8601String();
    final isBeforeCheck = start.isBefore(now);
    final isAtSameMomentCheck = start.isAtSameMomentAs(now);
    final timeDiffMs = start.difference(now).inMilliseconds;
    // #endregion
    
    if (start.isBefore(now) || start.isAtSameMomentAs(now)) {
      // #region agent log
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'A',
        'location': 'booking_wizard_page.dart:199',
        'message': 'Client validation failed - slot in past',
        'data': {
          'clientNow': clientNowIso,
          'clientNowUtc': clientNowUtcIso,
          'slotStart': startIso,
          'slotStartUtc': startUtcIso,
          'nowWithBuffer': now.toIso8601String(),
          'isBefore': isBeforeCheck,
          'isAtSameMoment': isAtSameMomentCheck,
          'timeDiffMs': timeDiffMs,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      try {
        final file = await File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log').open(mode: FileMode.append);
        await file.writeString('${jsonEncode(logData)}\n');
        await file.close();
      } catch (e) {}
      // #endregion
      setState(() => isLoadingQuote = false);
      return;
    }

    // #region agent log
    final logData2 = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'B',
      'location': 'booking_wizard_page.dart:206',
      'message': 'Client validation passed - sending quote request',
      'data': {
        'clientNow': clientNowIso,
        'clientNowUtc': clientNowUtcIso,
        'slotStart': startIso,
        'slotStartUtc': startUtcIso,
        'nowWithBuffer': now.toIso8601String(),
        'timeDiffMs': timeDiffMs,
        'timezoneOffset': start.timeZoneOffset.inHours,
        'isUtc': start.isUtc,
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

    setState(() => isLoadingQuote = true);

    _bookingCubit.getQuote(
          branchId: widget.branchId,
          startTime: start,
          durationHours: durationHours,
          persons: personsCount,
          addOns: selectedAddOns,
          couponCode: couponCode,
        );
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0: // Date & Time
        return selectedDate != null && selectedSlot != null;
      case 1: // Add-ons (optional, always can proceed)
        return true;
      case 2: // Persons
        return personsCount >= 1;
      case 3: // Review (always can proceed if reached)
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1 && _canProceedFromStep(_currentStep)) {
      setState(() => _currentStep++);
      
      // Request quote when moving to review step
      if (_currentStep == 3) {
        _requestQuote();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _confirmBooking() {
    if (selectedSlot == null) return;

    // تحقق نهائي قبل الإرسال
    // نضيف هامش زمني صغير (دقيقة واحدة) لتجنب مشاكل التوقيت
    final now = DateTime.now().add(const Duration(minutes: 1));
    final start = selectedSlot!.start;
    if (start.isBefore(now) || start.isAtSameMomentAs(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cannot_book_past_time'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _bookingCubit.createBooking(
          branchId: widget.branchId,
          startTime: start,
          durationHours: durationHours,
          persons: personsCount,
          couponCode: couponCode,
          addOns: selectedAddOns,
          specialRequests: specialRequests,
          contactPhone: contactPhone,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bookingCubit,
      child: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingSuccessWithData) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('booking_success'.tr()),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsPage(
                  booking: state.booking,
                  quote: state.quote,
                ),
              ),
            );
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is QuoteLoaded) {
            setState(() {
              currentQuote = state.quote;
              isLoadingQuote = false;
            });
          } else if (state is QuoteError) {
            setState(() => isLoadingQuote = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SlotsLoading) {
            setState(() {
              isLoadingSlots = true;
              slotsError = null;
            });
          } else if (state is SlotsLoaded) {
            setState(() {
              isLoadingSlots = false;
              slotsError = null;
              slotMinutes = state.branchSlots.slotMinutes;
              availableSlots = state.branchSlots.slots;
            });
            
            // Auto-select first available slot if none selected
            if (selectedSlot == null && availableSlots.isNotEmpty) {
              TimeSlotEntity? firstAvailable;
              for (final slot in availableSlots) {
                if (slot.available) {
                  firstAvailable = slot;
                  break;
                }
              }
              firstAvailable ??= availableSlots.first;
              _onSlotSelected(firstAvailable);
            }
          } else if (state is SlotsError) {
            setState(() {
              isLoadingSlots = false;
              slotsError = state.message;
              availableSlots = [];
            });
          }
        },
        builder: (context, state) {
          final isBooking = state is BookingLoading;
          
          return Scaffold(
            appBar: AppBar(
              title: Text('booking_wizard_title'.tr()),
              centerTitle: true,
            ),
            body: Column(
              children: [
                // Progress Indicator
                _buildProgressIndicator(),
                
                // Step Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildStepContent(),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(isBooking),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step titles
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: Column(
                  children: [
                    // Circle indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? const Color(0xFFFF5CAB)
                            : Colors.grey.shade300,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Step title
                    Text(
                      _getStepTitle(index),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? const Color(0xFFFF5CAB)
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: List.generate(_totalSteps - 1, (index) {
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFFF5CAB)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'booking_step_date_time'.tr();
      case 1:
        return 'booking_step_addons'.tr();
      case 2:
        return 'booking_step_persons'.tr();
      case 3:
        return 'booking_step_review'.tr();
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1DateTimeSlot();
      case 1:
        return _buildStep2AddOns();
      case 2:
        return _buildStep3Persons();
      case 3:
        return _buildStep4Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1DateTimeSlot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hall Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Iconsax.home_2, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.branchName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'booking_subtitle'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Date Selector
        DateTimeSelector(
          selectedDate: selectedDate,
          selectedTime: null,
          onDateChanged: (date) {
            setState(() {
              selectedDate = date;
              selectedSlot = null;
            });
            _fetchSlotsForDate();
          },
          onTimeChanged: null,
          showTimeSelector: false,
        ),
        const SizedBox(height: 16),

        // Slot Selector
        SlotSelector(
          slots: availableSlots,
          selectedSlot: selectedSlot,
          slotMinutes: slotMinutes,
          selectedDurationHours: durationHours,
          isLoading: isLoadingSlots,
          errorMessage: slotsError,
          onSlotSelected: _onSlotSelected,
        ),
        const SizedBox(height: 16),

        // Duration Selector
        if (selectedSlot != null)
          DurationSelector(
            selectedDuration: durationHours,
            maxDuration: maxDurationForSlot,
            onDurationChanged: (duration) {
              setState(() => durationHours = duration);
              _requestQuote();
            },
          ),
      ],
    );
  }

  Widget _buildStep2AddOns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_addons'.tr(),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'no_addons_available'.tr(),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        AddOnsSelector(
          availableAddOns: availableAddOns,
          selectedAddOnIds: selectedAddOnIds,
          onAddOnsChanged: (addOnIds) {
            setState(() {
              selectedAddOnIds = addOnIds;
              selectedAddOns = availableAddOns
                  .where((addOn) => addOnIds.contains(addOn.id))
                  .map((addOn) => {'id': addOn.id, 'quantity': 1})
                  .toList();
            });
            _requestQuote();
          },
        ),
      ],
    );
  }

  Widget _buildStep3Persons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enter_persons_count'.tr(),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'min_persons'.tr(),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        PersonsInput(
          personsCount: personsCount,
          onPersonsChanged: (persons) {
            setState(() => personsCount = persons);
            _requestQuote();
          },
        ),
        const SizedBox(height: 16),

        ContactPhoneInput(
          onPhoneChanged: (phone) {
            setState(() => contactPhone = phone);
          },
        ),
      ],
    );
  }

  Widget _buildStep4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'review_booking'.tr(),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Booking Summary
        BookingSummaryCard(
          hallName: widget.branchName,
          selectedDate: selectedDate,
          selectedTime: selectedSlot != null
              ? TimeOfDay(
                  hour: selectedSlot!.start.hour,
                  minute: selectedSlot!.start.minute,
                )
              : null,
          durationHours: durationHours,
          personsCount: personsCount,
          quote: currentQuote,
          couponCode: couponCode,
          selectedAddOns: selectedAddOns,
          specialRequests: specialRequests,
          contactPhone: contactPhone,
        ),
        const SizedBox(height: 16),

        // Price Breakdown
        PriceBreakdownCard(
          quote: currentQuote,
          isLoading: isLoadingQuote,
          durationHours: durationHours,
        ),
        const SizedBox(height: 16),

        // Coupon Input
        CouponInputWidget(
          onCouponChanged: (coupon) {
            setState(() => couponCode = coupon);
            _requestQuote();
          },
          isLoading: isLoadingQuote,
        ),
        const SizedBox(height: 16),

        // Special Requests
        SpecialRequestsInput(
          onRequestsChanged: (requests) {
            setState(() => specialRequests = requests);
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isBooking) {
    final canProceed = _canProceedFromStep(_currentStep);
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isBooking ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'previous'.tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 12),

            // Next/Confirm button
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: canProceed && !isBooking
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFFF5CAB),
                            Color(0xFFFF6A00),
                          ],
                        )
                      : null,
                  color: canProceed && !isBooking
                      ? null
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: canProceed && !isBooking
                      ? (isLastStep ? _confirmBooking : _nextStep)
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isLastStep
                              ? 'confirm_booking'.tr()
                              : 'continue_step'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

