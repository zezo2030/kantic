import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/branch_entity.dart';
import '../../../branches/presentation/pages/branches_map_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NearbyBranchesSection extends StatefulWidget {
  final List<BranchEntity> branches;
  final VoidCallback? onViewAll;

  const NearbyBranchesSection({
    super.key,
    required this.branches,
    this.onViewAll,
  });

  @override
  State<NearbyBranchesSection> createState() => _NearbyBranchesSectionState();
}

class _NearbyBranchesSectionState extends State<NearbyBranchesSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<BranchEntity> _sortedBranches;
  final Map<String, double> _branchDistances = {};
  bool _isLoadingLocation = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _sortedBranches = List.from(widget.branches);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _fetchNearbyBranches();
  }

  @override
  void didUpdateWidget(covariant NearbyBranchesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branches != widget.branches) {
      _sortedBranches = List.from(widget.branches);
      _branchDistances.clear();
      _fetchNearbyBranches();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.branches.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  _buildSectionHeader(),

                  const SizedBox(height: 20),

                  if (_isLoadingLocation)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'detecting_location'.tr(),
                              style: TextStyle(
                                color: AppColors.luxuryTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_locationMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _locationMessage!,
                        style: TextStyle(
                          color: AppColors.luxuryTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Branches List
                  _buildBranchesList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title with Icon is now wrapped in a Flexible to allow View All to stay on the far end
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.luxuryRedGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.luxuryDeepRed.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.near_me,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'nearby_branches'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.luxuryTextPrimary,
                              fontSize: 18,
                            ),
                      ),
                      Text(
                        'closest_to_you'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.luxuryTextSecondary,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // View All Button - Pushed to the far end
          if (widget.onViewAll != null)
            TextButton(
              onPressed: widget.onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'view_all'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBranchesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sortedBranches.length,
      itemBuilder: (context, index) {
        final branch = _sortedBranches[index];
        final distance = _branchDistances[branch.id];

        return _buildNearbyBranchCard(branch, distance, index);
      },
    );
  }

  Widget _buildNearbyBranchCard(
    BranchEntity branch,
    double? distance,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.luxuryShadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _onBranchTap(branch),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildBranchThumb(branch),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.locale.languageCode == 'ar'
                                  ? branch.nameAr
                                  : branch.nameEn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.luxuryTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.place,
                                  size: 14,
                                  color: AppColors.luxuryTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    branch.location,
                                    style: TextStyle(
                                      color: AppColors.luxuryTextSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (distance != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primaryRed.withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.navigation,
                                          size: 10,
                                          color: AppColors.primaryRed,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${distance.toStringAsFixed(1)} ${'km'.tr()}',
                                          style: TextStyle(
                                            color: AppColors.primaryRed,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: branch.status == 'active'
                                        ? AppColors.successColor
                                            .withOpacity(0.1)
                                        : AppColors.warningColor
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    branch.status == 'active'
                                        ? 'active'.tr()
                                        : 'inactive'.tr(),
                                    style: TextStyle(
                                      color: branch.status == 'active'
                                          ? AppColors.successColor
                                          : AppColors.warningColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (branch.capacity > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 12,
                                        color: AppColors.luxuryTextSecondary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${'capacity'.tr()}: ${branch.capacity}',
                                        style: TextStyle(
                                          color: AppColors.luxuryTextSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openMapsForBranch(branch),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.luxuryRedGradient.colors.first
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.directions,
                          color: AppColors.luxuryDeepRed,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onBranchTap(branch),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.cardGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.book_online,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchNearbyBranches() async {
    if (_sortedBranches.isEmpty) return;
    setState(() {
      _isLoadingLocation = true;
      _locationMessage = null;
    });

    final permissionGranted = await _ensurePermission();
    if (!mounted) return;
    if (!permissionGranted) {
      setState(() {
        _isLoadingLocation = false;
        _locationMessage = 'location_permission_required'.tr();
      });
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
        _locationMessage = 'enable_location_services'.tr();
      });
      return;
    }

    LocationPermission geoPerm = await Geolocator.checkPermission();
    if (!mounted) return;
    if (geoPerm == LocationPermission.denied) {
      geoPerm = await Geolocator.requestPermission();
      if (!mounted) return;
    }
    if (geoPerm == LocationPermission.denied ||
        geoPerm == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingLocation = false;
        _locationMessage = 'location_permission_required'.tr();
      });
      return;
    }

    try {
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 25),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition() ?? Position(
            longitude: 0,
            latitude: 0,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
        );
      }
      if (!mounted) return;

      final branchesWithCoords = _sortedBranches
          .where((b) => b.latitude != null && b.longitude != null)
          .toList();

      final branchesWithoutCoords = _sortedBranches
          .where((b) => b.latitude == null || b.longitude == null)
          .toList();

      for (final branch in branchesWithCoords) {
        final distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          branch.latitude!,
          branch.longitude!,
        );
        _branchDistances[branch.id] = distanceMeters / 1000.0;
      }

      branchesWithCoords.sort((a, b) {
        final distA = _branchDistances[a.id] ?? double.infinity;
        final distB = _branchDistances[b.id] ?? double.infinity;
        return distA.compareTo(distB);
      });

      if (!mounted) return;
      setState(() {
        _sortedBranches = [...branchesWithCoords, ...branchesWithoutCoords];
        _isLoadingLocation = false;
        _locationMessage = _branchDistances.isEmpty
            ? 'no_location_data'.tr()
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationMessage = 'location_error'.tr();
      });
    }
  }

  Future<bool> _ensurePermission() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted || status == PermissionStatus.limited) {
      return true;
    }

    status = await Permission.location.request();

    if (status.isGranted || status == PermissionStatus.limited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  Widget _buildBranchThumb(BranchEntity branch) {
    final img =
        branch.coverImage ??
        (branch.images?.isNotEmpty == true ? branch.images!.first : null);
    if (img == null || img.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.location_on,
            size: 30,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: resolveFileUrl(img),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorWidget: (c, url, e) => Container(
          width: 80,
          height: 80,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 28, color: Colors.grey),
        ),
      ),
    );
  }

  void _onBranchTap(BranchEntity branch) {
    Navigator.of(
      context,
    ).pushNamed('/branch-details', arguments: {'branchId': branch.id});
  }

  void _openMapsForBranch(BranchEntity branch) {
    if (branch.latitude == null || branch.longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('branch_coordinates_unavailable'.tr())),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BranchesMapPage(
          branches: widget.branches,
          focusBranchId: branch.id,
        ),
      ),
    );
  }
}
