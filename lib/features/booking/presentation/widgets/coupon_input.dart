// Coupon Input Widget - Presentation Layer
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';

class CouponInputWidget extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onCouponChanged;
  final bool isLoading;

  const CouponInputWidget({
    super.key,
    this.initialValue,
    required this.onCouponChanged,
    this.isLoading = false,
  });

  @override
  State<CouponInputWidget> createState() => _CouponInputWidgetState();
}

class _CouponInputWidgetState extends State<CouponInputWidget> {
  late TextEditingController _controller;
  bool _isValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateCoupon(String value) {
    setState(() {
      if (value.isEmpty) {
        _isValid = false;
        _errorMessage = null;
      } else if (value.length < 3) {
        _isValid = false;
        _errorMessage = 'coupon_too_short'.tr();
      } else {
        _isValid = true;
        _errorMessage = null;
      }
    });

    widget.onCouponChanged(_isValid ? value : null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'coupon_code'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'enter_coupon'.tr(),
                      prefixIcon: const Icon(Iconsax.discount_shape),
                      suffixIcon: _isValid
                          ? const Icon(Iconsax.tick_circle, color: Colors.green)
                          : _errorMessage != null
                          ? const Icon(Iconsax.close_circle, color: Colors.red)
                          : null,
                      errorText: _errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _validateCoupon,
                    enabled: !widget.isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_isValid)
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      _validateCoupon('');
                    },
                    icon: const Icon(Iconsax.close_circle),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                    ),
                  ),
              ],
            ),
            if (_isValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Iconsax.tick_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'coupon_applied'.tr(),
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
