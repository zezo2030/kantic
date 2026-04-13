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
import '../../../../core/services/location_service_prompt.dart';
import 'package:url_launcher/url_launcher.dart';

class BranchesMapPage extends StatefulWidget {
  final List<BranchEntity> branches;

  const BranchesMapPage({super.key, required this.branches});

  @override
  State<BranchesMapPage> createState() => _BranchesMapPageState();
}

class _BranchesMapPageState extends State<BranchesMapPage> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  Set<Marker> _markers = {};
  BranchEntity? _selectedBranch;
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  bool _locationPermissionGranted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // فلترة الفروع التي لها إحداثيات
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

    // محاولة الحصول على موقع المستخدم
    await _getUserLocation();

    // إنشاء الماركرز
    await _createMarkers(branchesWithLocation);

    // تحديد المركز الأولي للخريطة
    _setInitialCameraPosition(branchesWithLocation);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showSnackBar(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

      // التحقق من الأذونات
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

      // الحصول على الموقع
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

      // محاولة تحميل coverImage كلوجو للماركر
      if (branch.coverImage != null && branch.coverImage!.isNotEmpty) {
        try {
          icon = await _createMarkerIconFromNetwork(branch.coverImage!);
        } catch (e) {
          // استخدام الماركر الافتراضي في حالة الخطأ
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
        colors: [Color(0xFFE53935), Color(0xFFE35D5B)],
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

  void _setInitialCameraPosition(List<BranchEntity> branches) {
    if (_userPosition != null) {
      // إذا كان لدينا موقع المستخدم، استخدمه كمركز
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          MapsConstants.defaultZoom,
        ),
      );
    } else if (branches.isNotEmpty) {
      // حساب المركز المتوسط للفروع
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
      await _showSnackBar(
        'branch_coordinates_unavailable'.tr(),
      );
      return;
    }

    final destination = '$lat,$lng';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await _showSnackBar(
        'could_not_open_maps'.tr(),
      );
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
    // الرجوع إلى الصفحة السابقة
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('branches_map'.tr()),
          leading: IconButton(
            icon: Icon(
              context.locale.languageCode == 'ar'
                  ? Iconsax.arrow_right_3
                  : Iconsax.arrow_left_2,
            ),
            onPressed: _navigateToHome,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('branches_map'.tr()),
          leading: IconButton(
            icon: Icon(
              context.locale.languageCode == 'ar'
                  ? Iconsax.arrow_right_3
                  : Iconsax.arrow_left_2,
            ),
            onPressed: _navigateToHome,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!),
            ],
          ),
        ),
      );
    }

    final branchesWithLocation = widget.branches
        .where((b) => b.latitude != null && b.longitude != null)
        .toList();

    // حساب المركز الافتراضي
    final defaultLat =
        branchesWithLocation.map((b) => b.latitude!).reduce((a, b) => a + b) /
        branchesWithLocation.length;
    final defaultLng =
        branchesWithLocation.map((b) => b.longitude!).reduce((a, b) => a + b) /
        branchesWithLocation.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('branches_map'.tr()),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
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
            myLocationButtonEnabled: false, // سنستخدم زر مخصص
            mapType: MapType.normal,
            padding: EdgeInsets.only(bottom: _selectedBranch != null ? 220 : 0),
            onTap: (_) {
              if (_selectedBranch != null) {
                setState(() => _selectedBranch = null);
              }
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // تأخير بسيط لضمان تحميل الماركرز
              Future.delayed(const Duration(milliseconds: 500), () {
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
                child: BranchMapCard(
                  branch: _selectedBranch!,
                  onClose: () => setState(() => _selectedBranch = null),
                  onDetails: () {
                    Navigator.pushNamed(
                      context,
                      '/branch-details',
                      arguments: {'branchId': _selectedBranch!.id},
                    );
                  },
                  onDirections: () => _openBranchDirections(_selectedBranch!),
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

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Iconsax.gallery,
                        color: Colors.grey.shade500,
                        size: 40,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Iconsax.gallery,
                      color: Colors.grey.shade500,
                      size: 40,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        context.locale.languageCode == 'ar'
                            ? branch.nameAr
                            : branch.nameEn,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Iconsax.close_circle, size: 22),
                    ),
                  ],
                ),
                if (branch.location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Iconsax.map_1,
                        size: 16,
                        color: Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          branch.location,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Iconsax.star1,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      branch.rating != null
                          ? branch.rating!.toStringAsFixed(1)
                          : '--',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((branch.reviewsCount ?? 0) > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${branch.reviewsCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDetails,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Iconsax.document_text, size: 18),
                        label: Text('view_details'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDirections,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Iconsax.location, size: 18),
                        label: Text('view_on_map'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
