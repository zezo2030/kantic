import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/di/auth_injection.dart';
import '../../domain/usecases/get_subscription_usage_logs_usecase.dart';
import '../../data/models/subscription_usage_log_model.dart';

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
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('subscription_usage_logs'.tr())),
      body: _loading && _logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _logs.length + 1,
              itemBuilder: (context, i) {
                if (i == _logs.length) {
                  if (_page >= _totalPages) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () {
                      _page++;
                      _fetch(append: true);
                    },
                    child: Text('load_more'.tr()),
                  );
                }
                final l = _logs[i];
                return ListTile(
                  title: Text(
                    '-${l.deductedHours} h · ${l.staffName ?? ''}',
                  ),
                  subtitle: Text(l.createdAt.toString()),
                );
              },
            ),
    );
  }
}
