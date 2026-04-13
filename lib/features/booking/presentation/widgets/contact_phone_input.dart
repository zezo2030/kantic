// Contact Phone Input Widget - Presentation Layer
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';

class ContactPhoneInput extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onPhoneChanged;

  const ContactPhoneInput({
    super.key,
    this.initialValue,
    required this.onPhoneChanged,
  });

  @override
  State<ContactPhoneInput> createState() => _ContactPhoneInputState();
}

class _ContactPhoneInputState extends State<ContactPhoneInput> {
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

  void _validatePhone(String value) {
    setState(() {
      if (value.isEmpty) {
        _isValid = false;
        _errorMessage = null;
      } else if (value.length < 10) {
        _isValid = false;
        _errorMessage = 'phone_too_short'.tr();
      } else if (!RegExp(r'^[+]?[0-9\s\-\(\)]+$').hasMatch(value)) {
        _isValid = false;
        _errorMessage = 'phone_invalid_format'.tr();
      } else {
        _isValid = true;
        _errorMessage = null;
      }
    });

    widget.onPhoneChanged(_isValid ? value : null);
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
            Row(
              children: [
                const Icon(Iconsax.call, size: 20),
                const SizedBox(width: 8),
                Text(
                  'contact_phone'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${'optional'.tr()})',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '+966501234567',
                prefixIcon: const Icon(Iconsax.call),
                suffixIcon: _isValid
                    ? const Icon(Iconsax.tick_circle, color: Colors.green)
                    : _errorMessage != null
                    ? const Icon(Iconsax.close_circle, color: Colors.red)
                    : null,
                errorText: _errorMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'contact_phone_helper'.tr(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: _validatePhone,
            ),
          ],
        ),
      ),
    );
  }
}
