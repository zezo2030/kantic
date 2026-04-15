import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../auth/di/auth_injection.dart';
import '../../domain/usecases/get_subscription_usage_logs_usecase.dart';
import '../../data/models/subscription_usage_log_model.dart';
import '../../../../core/theme/app_colors.dart';

class SubscriptionUsageLogsPage extends StatefulWidget {
  final String purchaseId;

  const SubscriptionUsageLogsPage({super.key, required this.purchaseId});

  @override
  State<SubscriptionUsageLogsPage> createState() =>
      _SubscriptionUsageLogsPageState();
}

class _SubscriptionUsageLogsPageState extends State<SubscriptionUsageLogsPage> {
  final List<SubscriptionUsageLogModel> _logs = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool append = false}) async {
    setState(() => _loading = true);
    try {
      final r = await sl<GetSubscriptionUsageLogsUseCase>()(
        widget.purchaseId,
        page: _page,
      );
      setState(() {
        if (append) {
          _logs.addAll(r.logs);
        } else {
          _logs
            ..clear()
            ..addAll(r.logs);
        }
        _totalPages = r.totalPages;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'subscription_usage_logs'.tr(),
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading && _logs.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _logs.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.document_text,
              size: 64,
              color: AppColors.primaryRed,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'no_usage_logs_yet'.tr(),
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'usage_logs_description'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _logs.length + 1,
      itemBuilder: (context, i) {
        if (i == _logs.length) {
          if (_page >= _totalPages) return const SizedBox(height: 40);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: TextButton(
              onPressed: () {
                _page++;
                _fetch(append: true);
              },
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryRed,
                      ),
                    )
                  : Text(
                      'load_more'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
            ),
          );
        }
        final l = _logs[i];
        return _UsageLogCard(log: l, index: i);
      },
    );
  }
}

class _UsageLogCard extends StatelessWidget {
  final SubscriptionUsageLogModel log;
  final int index;

  const _UsageLogCard({required this.log, required this.index});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd · HH:mm');
    final dateStr = dateFormat.format(log.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: AppColors.primaryRed,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Iconsax.calendar_1,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontFamily: 'MontserratArabic',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '-${log.deductedHours.toStringAsFixed(log.deductedHours % 1 == 0 ? 0 : 1)} h',
                              style: const TextStyle(
                                fontFamily: 'MontserratArabic',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Iconsax.note,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log.notes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'MontserratArabic',
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(
                            'remaining_before'.tr(),
                            '${log.remainingHoursBefore.toStringAsFixed(log.remainingHoursBefore % 1 == 0 ? 0 : 1)} h',
                          ),
                          const Icon(Iconsax.arrow_right_1,
                              size: 14, color: Color(0xFFD1D5DB)),
                          _buildMiniStat(
                            'remaining_after'.tr(),
                            '${log.remainingHoursAfter.toStringAsFixed(log.remainingHoursAfter % 1 == 0 ? 0 : 1)} h',
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildMiniStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment:
          isHighlight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
