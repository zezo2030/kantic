// Special Requests Input Widget - Presentation Layer
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';

class SpecialRequestsInput extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onRequestsChanged;

  const SpecialRequestsInput({
    super.key,
    this.initialValue,
    required this.onRequestsChanged,
  });

  @override
  State<SpecialRequestsInput> createState() => _SpecialRequestsInputState();
}

class _SpecialRequestsInputState extends State<SpecialRequestsInput> {
  late TextEditingController _controller;

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
                const Icon(Iconsax.document_text, size: 20),
                const SizedBox(width: 8),
                Text(
                  'special_requests'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'special_requests_hint'.tr(),
                prefixIcon: const Icon(Iconsax.note_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'special_requests_helper'.tr(),
              ),
              maxLines: 3,
              maxLength: 500,
              onChanged: (value) =>
                  widget.onRequestsChanged(value.isEmpty ? null : value),
            ),
          ],
        ),
      ),
    );
  }
}
