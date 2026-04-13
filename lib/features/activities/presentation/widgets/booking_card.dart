import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart'
    as easy_localization;
import 'package:iconsax/iconsax.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../home/data/datasources/home_remote_datasource.dart';
import '../../../home/data/models/branch_model.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../../tickets/data/datasources/tickets_remote_datasource.dart';
import 'ticket_shape.dart';
import 'dashed_divider.dart';
import '../../../../core/theme/app_colors.dart';

class BookingCard extends StatefulWidget {
  final BookingModel booking;
  final TicketsRemoteDataSource ticketsDs;
  final VoidCallback onDetails;

  const BookingCard({
    super.key,
    required this.booking,
    required this.ticketsDs,
    required this.onDetails,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  late final Future<String?> _imageFuture;
  late final Future<BranchModel?> _branchFuture;

  // Simple in-memory cache for branch images per session
  static final Map<String, String?> _branchImageCache = <String, String?>{};
  static final Map<String, BranchModel?> _branchCache =
      <String, BranchModel?>{};

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadBranchImage();
    _branchFuture = _loadBranch();
  }

  // Helper method to get status info
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'color': Colors.orange,
          'icon': Iconsax.clock,
          'text': easy_localization.tr('pending'),
        };
      case 'confirmed':
        return {
          'color': Colors.green,
          'icon': Iconsax.tick_circle,
          'text': easy_localization.tr('confirmed'),
        };
      case 'cancelled':
        return {
          'color': Colors.red,
          'icon': Iconsax.close_circle,
          'text': easy_localization.tr('cancelled'),
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Iconsax.info_circle,
          'text': status,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 132;
    const double imageWidth = 132;
    const double borderRadius = 16;
    const double notchRadius = 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        elevation: 2,
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onDetails,
          child: ClipPath(
            clipper: const TicketClipper(
              borderRadius: borderRadius,
              notchRadius: notchRadius,
            ),
            child: SizedBox(
              height: cardHeight,
              child: Row(
                textDirection: TextDirection.rtl, // image on the right in RTL
                children: [
                  // Image
                  SizedBox(
                    width: imageWidth,
                    height: double.infinity,
                    child: _buildImageWithOverlay(),
                  ),
                  // Dashed divider
                  SizedBox(
                    width: 14,
                    child: Center(
                      child: SizedBox(
                        width: 1,
                        height: cardHeight - 24,
                        child: const DashedDivider(),
                      ),
                    ),
                  ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12,
                        end: 12,
                        top: 12,
                        bottom: 12,
                      ),
                      child: _buildInfoSection(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithOverlay() {
    return FutureBuilder<String?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final imageUrl = snapshot.data;
        final imageChild = loading
            ? const Center(child: CircularProgressIndicator())
            : (imageUrl != null && imageUrl.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Iconsax.gallery_slash),
                ),
              )
            : Container(
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Iconsax.gallery, size: 40)),
              );

        return Stack(
          fit: StackFit.expand,
          children: [
            imageChild,
            PositionedDirectional(
              top: 10,
              start: 10,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.people, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.booking.persons}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return FutureBuilder<BranchModel?>(
      future: _branchFuture,
      builder: (context, snapshot) {
        final branch = snapshot.data;
        final branchName = branch != null && branch.nameAr.isNotEmpty
            ? branch.nameAr
            : easy_localization.tr('entertainment_center_title');
        final location =
            branch?.location ?? easy_localization.tr('madinah_al_salam_location');

        final statusInfo = _getStatusInfo(widget.booking.status);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    branchName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusInfo['color'].withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusInfo['icon'],
                        size: 12,
                        color: statusInfo['color'],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo['text'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusInfo['color'],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Date row
            Row(
              children: [
                _smallRedDot(),
                const SizedBox(width: 6),
                const Icon(Iconsax.calendar_1, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  _formatDate(widget.booking.startTime),
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                ),
              ],
            ),
            // Location row
            Row(
              children: [
                const Icon(
                  Iconsax.map_1,
                  size: 14,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            // Button
            _gradientButton(
              label: easy_localization.tr('booking_details'),
              onPressed: widget.onDetails,
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }

  Widget _smallRedDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.35),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppColors.primaryGradient,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Future<String?> _loadBranchImage() async {
    final branchId = widget.booking.branchId;
    if (_branchImageCache.containsKey(branchId)) {
      return _branchImageCache[branchId];
    }
    final ds = HomeRemoteDataSourceImpl(dio: DioClient.instance);
    try {
      final branch = await ds.getBranchDetails(branchId);

      // Try cover image first (main branch image)
      String? imagePath;
      if (branch.coverImage != null && branch.coverImage!.isNotEmpty) {
        imagePath = branch.coverImage;
      } else if (branch.images != null && branch.images!.isNotEmpty) {
        imagePath = branch.images!.first;
      } else if (branch.hallImages != null && branch.hallImages!.isNotEmpty) {
        imagePath = branch.hallImages!.first;
      }

      final imageUrl = resolveFileUrl(imagePath);
      final resolvedImage = imageUrl.isNotEmpty ? imageUrl : null;
      _branchImageCache[branchId] = resolvedImage;
      return resolvedImage;
    } catch (_) {
      _branchImageCache[branchId] = null;
      return null;
    }
  }

  Future<BranchModel?> _loadBranch() async {
    final branchId = widget.booking.branchId;
    if (_branchCache.containsKey(branchId)) {
      return _branchCache[branchId];
    }
    final ds = HomeRemoteDataSourceImpl(dio: DioClient.instance);
    try {
      final b = await ds.getBranchDetails(branchId);
      _branchCache[branchId] = b;
      return b;
    } catch (_) {
      _branchCache[branchId] = null;
      return null;
    }
  }
}
