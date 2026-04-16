import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../../home/domain/entities/branch_entity.dart';
import '../../../../core/constants/maps_constants.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/location_service_prompt.dart';
import 'package:url_launcher/url_launcher.dart';

class BranchesMapPage extends StatefulWidget {
  final List<BranchEntity> branches;

  final String? focusBranchId;

  const BranchesMapPage({
    super.key,
    required this.branches,
    this.focusBranchId,
  });

  @override
  State<BranchesMapPage> createState() => _BranchesMapPageState();
}

class _BranchesMapPageState extends State<BranchesMapPage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _userPosition;
  Set<Marker> _markers = {};
  BranchEntity? _selectedBranch;
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  bool _locationPermissionGranted = false;
  String? _errorMessage;
  late AnimationController _cardController;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutQuart),
        );
    _cardFadeAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );
    _initializeMap();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    final branchesWithLocation = widget.branches
        .where((b) => b.latitude != null && b.longitude != null)
        .toList();

    if (branchesWithLocation.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'no_branches_with_location'.tr();
      });
      return;
    }

    await _getUserLocation();
    await _createMarkers(branchesWithLocation);
    _setInitialCameraPosition(branchesWithLocation);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showSnackBar(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Future<bool> _requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.status;

    if (status.isGranted || status == PermissionStatus.limited) {
      return true;
    }

    status = await Permission.locationWhenInUse.request();

    if (status.isGranted || status == PermissionStatus.limited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      final message = 'location_permission_permanently_denied'.tr();
      await _showSnackBar(message);
    }

    return false;
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final permissionGranted = await _requestLocationPermission();
      if (!permissionGranted) {
        if (!mounted) return;
        setState(() {
          _locationPermissionGranted = false;
          _isLoadingLocation = false;
        });
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final message = 'location_services_disabled_enable_gps'.tr();
        await _showSnackBar(message);
        await promptEnableLocationServiceIfDisabled(context);
        if (!mounted) return;
        setState(() {
          _locationPermissionGranted = false;
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationPermissionGranted = false;
          _isLoadingLocation = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _locationPermissionGranted = true;
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _locationPermissionGranted = true;
        _userPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationPermissionGranted = false;
        _isLoadingLocation = false;
      });
      final message = 'failed_get_current_location'.tr();
      await _showSnackBar(message);
    }
  }

  Future<void> _createMarkers(List<BranchEntity> branches) async {
    final Set<Marker> markers = {};

    for (final branch in branches) {
      BitmapDescriptor icon = BitmapDescriptor.defaultMarker;

      if (branch.coverImage != null && branch.coverImage!.isNotEmpty) {
        try {
          icon = await _createMarkerIconFromNetwork(branch.coverImage!);
        } catch (e) {
          // fallback to default
        }
      }

      markers.add(
        Marker(
          markerId: MarkerId(branch.id),
          position: LatLng(branch.latitude!, branch.longitude!),
          icon: icon,
          infoWindow: InfoWindow(
            title: context.locale.languageCode == 'ar'
                ? branch.nameAr
                : branch.nameEn,
            snippet: branch.location,
          ),
          onTap: () {
            setState(() {
              _selectedBranch = branch;
            });
            _animateToBranch(branch);
            _cardController.forward(from: 0);
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<BitmapDescriptor> _createMarkerIconFromNetwork(String imageUrl) async {
    try {
      final String fullUrl = resolveFileUrl(imageUrl);
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        final Uint8List imageBytes = response.bodyBytes;
        return await _buildCustomMarker(imageBytes);
      }
    } catch (e) {
      // fallback
    }

    return BitmapDescriptor.defaultMarker;
  }

  Future<BitmapDescriptor> _buildCustomMarker(Uint8List imageBytes) async {
    const double markerWidth = 160;
    const double markerHeight = 190;
    const double circleRadius = 56;
    const double circleCenterY = 70;
    const double borderWidth = 6;

    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetHeight: 180,
      targetWidth: 180,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image branchImage = frameInfo.image;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final Path markerPath = Path()
      ..moveTo(markerWidth / 2, markerHeight)
      ..quadraticBezierTo(12, markerHeight * 0.75, 18, circleCenterY + 8)
      ..arcToPoint(
        Offset(markerWidth - 18, circleCenterY + 8),
        radius: const Radius.circular(circleRadius + 32),
        clockwise: false,
      )
      ..quadraticBezierTo(
        markerWidth - 12,
        markerHeight * 0.75,
        markerWidth / 2,
        markerHeight,
      )
      ..close();

    canvas.drawPath(markerPath, shadowPaint);

    final Paint backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryOrange, AppColors.primaryRed],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, markerWidth, markerHeight));

    canvas.drawPath(markerPath, backgroundPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final Offset circleCenter = Offset(markerWidth / 2, circleCenterY);
    canvas.drawCircle(
      circleCenter,
      circleRadius + borderWidth / 2,
      borderPaint,
    );

    final Path clipPath = Path()
      ..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius));

    canvas.save();
    canvas.clipPath(clipPath);

    paintImage(
      canvas: canvas,
      rect: Rect.fromCircle(center: circleCenter, radius: circleRadius),
      image: branchImage,
      fit: BoxFit.cover,
    );

    canvas.restore();

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image markerAsImage = await picture.toImage(
      markerWidth.toInt(),
      markerHeight.toInt(),
    );
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  BranchEntity? _branchMatchingFocus(List<BranchEntity> branches) {
    final id = widget.focusBranchId;
    if (id == null || id.isEmpty) return null;
    for (final b in branches) {
      if (b.id == id) return b;
    }
    return null;
  }

  void _setInitialCameraPosition(List<BranchEntity> branches) {
    if (_userPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          MapsConstants.defaultZoom,
        ),
      );
    } else if (branches.isNotEmpty) {
      final avgLat =
          branches.map((b) => b.latitude!).reduce((a, b) => a + b) /
          branches.length;
      final avgLng =
          branches.map((b) => b.longitude!).reduce((a, b) => a + b) /
          branches.length;

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(avgLat, avgLng),
          branches.length == 1
              ? MapsConstants.singleBranchZoom
              : MapsConstants.defaultZoom,
        ),
      );
    }
  }

  void _animateToBranch(BranchEntity branch) {
    if (branch.latitude == null || branch.longitude == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(branch.latitude!, branch.longitude!),
        MapsConstants.singleBranchZoom,
      ),
    );
  }

  Future<void> _openBranchDirections(BranchEntity branch) async {
    final lat = branch.latitude;
    final lng = branch.longitude;
    if (lat == null || lng == null) {
      await _showSnackBar('branch_coordinates_unavailable'.tr());
      return;
    }

    final destination = '$lat,$lng';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await _showSnackBar('could_not_open_maps'.tr());
    }
  }

  void _centerOnUserLocation() async {
    if (_userPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          MapsConstants.defaultZoom,
        ),
      );
    } else {
      await _getUserLocation();
      if (_userPosition != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_userPosition!.latitude, _userPosition!.longitude),
            MapsConstants.defaultZoom,
          ),
        );
      }
    }
  }

  void _navigateToHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(title: Text('branches_map'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'loading_map'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(title: Text('branches_map'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.map_1,
                    size: 48,
                    color: AppColors.primaryRed.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 180,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializeMap();
                    },
                    icon: const Icon(Iconsax.refresh, size: 18),
                    label: Text('retry'.tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final branchesWithLocation = widget.branches
        .where((b) => b.latitude != null && b.longitude != null)
        .toList();

    final defaultLat =
        branchesWithLocation.map((b) => b.latitude!).reduce((a, b) => a + b) /
        branchesWithLocation.length;
    final defaultLng =
        branchesWithLocation.map((b) => b.longitude!).reduce((a, b) => a + b) /
        branchesWithLocation.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('branches_map'.tr()),
        elevation: 0,
        backgroundColor: AppColors.primaryRed.withValues(alpha: 0.95),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            context.locale.languageCode == 'ar'
                ? Iconsax.arrow_right_3
                : Iconsax.arrow_left_2,
          ),
          onPressed: _navigateToHome,
        ),
        actions: [
          if (_userPosition != null || _isLoadingLocation)
            IconButton(
              icon: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location),
              onPressed: _centerOnUserLocation,
              tooltip: 'my_location'.tr(),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(defaultLat, defaultLng),
              zoom: branchesWithLocation.length == 1
                  ? MapsConstants.singleBranchZoom
                  : MapsConstants.defaultZoom,
            ),
            markers: _markers,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            padding: EdgeInsets.only(bottom: _selectedBranch != null ? 220 : 0),
            onTap: (_) {
              if (_selectedBranch != null) {
                _cardController.reverse().then((_) {
                  setState(() => _selectedBranch = null);
                });
              }
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 500), () async {
                if (!mounted) return;
                final focus = _branchMatchingFocus(branchesWithLocation);
                if (focus != null) {
                  setState(() => _selectedBranch = focus);
                  _animateToBranch(focus);
                  _cardController.forward();
                  try {
                    await controller.showMarkerInfoWindow(MarkerId(focus.id));
                  } catch (_) {}
                  return;
                }
                _setInitialCameraPosition(branchesWithLocation);
              });
            },
          ),
          if (_selectedBranch != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: FadeTransition(
                  opacity: _cardFadeAnimation,
                  child: SlideTransition(
                    position: _cardSlideAnimation,
                    child: BranchMapCard(
                      branch: _selectedBranch!,
                      onClose: () {
                        _cardController.reverse().then((_) {
                          setState(() => _selectedBranch = null);
                        });
                      },
                      onDetails: () {
                        Navigator.pushNamed(
                          context,
                          '/branch-details',
                          arguments: {'branchId': _selectedBranch!.id},
                        );
                      },
                      onDirections: () =>
                          _openBranchDirections(_selectedBranch!),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BranchMapCard extends StatelessWidget {
  final BranchEntity branch;
  final VoidCallback onClose;
  final VoidCallback onDetails;
  final VoidCallback onDirections;

  const BranchMapCard({
    super.key,
    required this.branch,
    required this.onClose,
    required this.onDetails,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveFileUrl(
      branch.coverImage ??
          ((branch.images != null && branch.images!.isNotEmpty)
              ? branch.images!.first
              : null),
    );

    final isOpen = branch.status == 'active';
    final displayName = context.locale.languageCode == 'ar'
        ? branch.nameAr
        : branch.nameEn;

    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradient,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryRed.withValues(alpha: 0.3),
                                  AppColors.primaryOrange.withValues(
                                    alpha: 0.2,
                                  ),
                                ],
                              ),
                            ),
                            child: Icon(
                              Iconsax.gallery,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                          ),
                          child: Icon(
                            Iconsax.gallery,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 40,
                          ),
                        ),
                ),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: context.locale.languageCode == 'ar' ? null : 8,
                  left: context.locale.languageCode == 'ar' ? 8 : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(Iconsax.close_circle, size: 22),
                      color: Colors.white,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (branch.rating != null && branch.rating! > 0)
                  Positioned(
                    top: 8,
                    left: context.locale.languageCode == 'ar' ? null : 8,
                    right: context.locale.languageCode == 'ar' ? 8 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.luxuryGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.star1,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            branch.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if ((branch.reviewsCount ?? 0) > 0) ...[
                            const SizedBox(width: 3),
                            Text(
                              '(${branch.reviewsCount})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 52,
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (branch.location.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Iconsax.location5,
                            size: 14,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            branch.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isOpen) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'open'.tr(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDetails,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          icon: const Icon(Iconsax.document_text, size: 18),
                          label: Text(
                            'view_details'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDirections,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            foregroundColor: AppColors.primaryRed,
                          ),
                          icon: const Icon(Iconsax.map_1, size: 18),
                          label: Text(
                            'view_on_map'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
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
