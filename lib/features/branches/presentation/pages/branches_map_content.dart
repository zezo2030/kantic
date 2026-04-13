import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../../home/domain/entities/branch_entity.dart';
import '../../../../core/constants/maps_constants.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/services/location_service_prompt.dart';

/// Map content view without AppBar
/// Used inside HomeTabsPage
class BranchesMapContent extends StatefulWidget {
  final List<BranchEntity> branches;

  const BranchesMapContent({super.key, required this.branches});

  @override
  State<BranchesMapContent> createState() => _BranchesMapContentState();
}

class _BranchesMapContentState extends State<BranchesMapContent> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  Set<Marker> _markers = {};
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
    // Filter branches with coordinates
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

    // Try to get user location
    await _getUserLocation();

    // Create markers
    await _createMarkers(branchesWithLocation);

    // Set initial camera position
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
            onTap: () {
              Navigator.pushNamed(
                context,
                '/branch-details',
                arguments: {'branchId': branch.id},
              );
            },
          ),
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!),
          ],
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

    return Stack(
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
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            Future.delayed(const Duration(milliseconds: 500), () {
              _setInitialCameraPosition(branchesWithLocation);
            });
          },
        ),

        // My Location Button
        if (_userPosition != null || _isLoadingLocation)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              onPressed: _isLoadingLocation ? null : _centerOnUserLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 20),
            ),
          ),
      ],
    );
  }
}
