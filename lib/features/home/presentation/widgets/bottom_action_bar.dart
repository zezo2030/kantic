import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../auth/presentation/widgets/custom_button.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onShare;
  final VoidCallback? onBook;

  const BottomActionBar({
    super.key,
    this.onCall,
    this.onDirections,
    this.onShare,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: const Border(top: BorderSide(color: Color(0x11000000))),
      ),
      child: Row(
        children: [
          _IconButton(icon: Iconsax.call, onPressed: onCall),
          const SizedBox(width: 10),
          _IconButton(icon: Iconsax.location, onPressed: onDirections),
          const SizedBox(width: 10),
          _IconButton(icon: Iconsax.export_1, onPressed: onShare),
          const Spacer(),
          CustomButton(
            onPressed: onBook,
            text: 'book_now',
            width: 130,
            height: 44,
            showShadow: false,
            useGradient: true,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _IconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0x11000000)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black87),
      ),
    );
  }
}
