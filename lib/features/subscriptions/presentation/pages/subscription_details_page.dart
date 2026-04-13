import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../auth/di/auth_injection.dart';
import '../../domain/usecases/get_subscription_details_usecase.dart';
import '../../data/models/subscription_purchase_model.dart';
import 'subscription_usage_logs_page.dart';

class SubscriptionDetailsPage extends StatefulWidget {
  final String purchaseId;

  const SubscriptionDetailsPage({super.key, required this.purchaseId});

  @override
  State<SubscriptionDetailsPage> createState() =>
      _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> {
  SubscriptionPurchaseModel? _purchase;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await sl<GetSubscriptionDetailsUseCase>()(widget.purchaseId);
      setState(() {
        _purchase = p;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('subscription_details'.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _purchase == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _purchase!.planTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${'status'.tr()}: ${_purchase!.status}'),
                Text('${'payment_status'.tr()}: ${_purchase!.paymentStatus}'),
                if (_purchase!.remainingHours != null)
                  Text(
                    '${'subscriptions_remaining_hours'.tr()}: ${_purchase!.remainingHours}',
                  ),
                if (_purchase!.qrData != null &&
                    _purchase!.qrData!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: QrImageView(
                      data: _purchase!.qrData!,
                      size: 200,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'do_not_share_qr_warning'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubscriptionUsageLogsPage(
                        purchaseId: widget.purchaseId,
                      ),
                    ),
                  ),
                  child: Text('subscription_usage_logs'.tr()),
                ),
              ],
            ),
    );
  }
}
