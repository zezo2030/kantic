import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../di/home_injection.dart';
import '../../domain/usecases/get_branch_details_usecase.dart';
import '../../domain/entities/branch_entity.dart';
import '../cubit/branch_details_cubit.dart';
import '../cubit/branch_details_state.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../widgets/gallery_carousel_widget.dart';
import '../widgets/ratings_section.dart';
import '../widgets/offers_section.dart';
import '../widgets/branch_commerce_section.dart';
import '../widgets/hall_video_player.dart';
import '../../../../core/utils/url_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../events/presentation/pages/create_event_request_page.dart';
import '../../../trips/presentation/pages/trip_request_wizard_page.dart';
import '../../../../core/routes/app_route_generator.dart';

class BranchDetailsPage extends StatelessWidget {
  final String branchId;

  const BranchDetailsPage({super.key, required this.branchId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BranchDetailsCubit(
            getBranchDetailsUseCase: sl<GetBranchDetailsUseCase>(),
          )..loadBranchDetails(branchId),
        ),
      ],
      child: BranchDetailsView(branchId: branchId),
    );
  }
}

class BranchDetailsView extends StatefulWidget {
  final String branchId;

  const BranchDetailsView({super.key, required this.branchId});

  @override
  State<BranchDetailsView> createState() => _BranchDetailsViewState();
}

class _BranchDetailsViewState extends State<BranchDetailsView> {
  bool _isWorkingHoursExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BranchDetailsCubit, BranchDetailsState>(
      builder: (context, state) {
        if (state is BranchDetailsLoading) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          );
        }

        if (state is BranchDetailsError) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.primaryRed),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 64,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.errorColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    onPressed: () {
                      context.read<BranchDetailsCubit>().loadBranchDetails(
                        widget.branchId,
                      );
                    },
                    text: 'retry',
                    width: 150,
                    useGradient: true,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is BranchDetailsLoaded) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: _buildBranchDetails(context, state.branch),
          );
        }

        return const Scaffold(backgroundColor: AppColors.backgroundColor);
      },
    );
  }

  Widget _buildBranchDetails(BuildContext context, BranchEntity branch) {
    final imageUrl = resolveFileUrl(
      branch.coverImage ??
          ((branch.images != null && branch.images!.isNotEmpty)
              ? branch.images!.first
              : null),
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 380,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.primaryRed,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              child: IconButton(
                icon: const Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.notification,
                    color: AppColors.primaryRed,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  },
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'branch_${branch.id}',
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey.shade200),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Iconsax.gallery,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.heroGradient,
                          ),
                        ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                // Premium Content inside the header
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.nameAr ?? '',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (branch.descriptionAr != null &&
                          branch.descriptionAr!.isNotEmpty)
                        Text(
                          branch.descriptionAr!,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Clean curved bottom transition
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Container(
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ),
          ),
        ),

        // Rating and Quick Facts Overlay
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RatingsSection(
                      rating: branch.rating,
                      reviewsCount: branch.reviewsCount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24, top: 12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Branch Details Section
              if (branch.descriptionAr != null || branch.descriptionEn != null)
                Column(
                  children: [
                    _buildSectionLayout(
                      title: 'about_branch'.tr(),
                      icon: Iconsax.info_circle,
                      child: Text(
                        branch.descriptionAr ??
                            branch.descriptionEn ??
                            'no_content_available'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Branch Video Section
              if (branch.videoUrl != null && branch.videoUrl!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: HallVideoPlayer(videoUrl: branch.videoUrl!),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Hall Video Section
              if (branch.hallVideoUrl != null &&
                  branch.hallVideoUrl!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: HallVideoPlayer(videoUrl: branch.hallVideoUrl!),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Offers Section
              if (branch.offers != null && branch.offers!.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final List<dynamic> branchWideOffers = branch.offers ?? [];
                    if (branchWideOffers.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildSectionLayout(
                      title: 'offers'.tr(),
                      icon: Iconsax.discount_shape,
                      child: OffersSection(offers: branchWideOffers),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    );
                  },
                ),
              ],

              // Subscription plans & catalog offer products (API)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: BranchCommerceSection(branchId: branch.id),
              ),

              // Gallery Section
              if (branch.images != null && branch.images!.isNotEmpty) ...[
                _buildSectionTitle('gallery'.tr(), Iconsax.gallery),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 16),
                  child: GalleryCarouselWidget(images: branch.images),
                ),
              ],

              // Branch Amenities Section
              if (branch.amenities != null && branch.amenities!.isNotEmpty)
                _buildSectionLayout(
                  title: 'amenities'.tr(),
                  icon: Iconsax.star,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: branch.amenities!.map((amenity) {
                      return IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.verify,
                                color: AppColors.primaryRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                amenity,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Branch Working Hours Section
              _buildBranchWorkingHoursSection(branch),

              // Branch Contact Section
              if (branch.contactPhone != null &&
                  branch.contactPhone!.isNotEmpty)
                _buildBranchContactSection(branch),

              // Booking Options Section
              _buildBookingOptionsSection(context),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLayout({
    required String title,
    required IconData icon,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, icon),
        const SizedBox(height: 16),
        Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBranchWorkingHoursSection(BranchEntity branch) {
    return _buildSectionLayout(
      title: 'working_hours'.tr(),
      icon: Iconsax.clock,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _buildWorkingHoursContent(branch),
      ),
    );
  }

  Widget _buildWorkingHoursContent(BranchEntity branch) {
    if (branch.workingHours == null || branch.workingHours!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Iconsax.info_circle, size: 24, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'working_hours_all_week'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sortedEntries = _sortWorkingHoursByToday(branch.workingHours!);
    final todayEntry = sortedEntries.first;
    final otherEntries = sortedEntries.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDayHoursCard(todayEntry.key, todayEntry.value, true),

        if (otherEntries.isNotEmpty) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _isWorkingHoursExpanded = !_isWorkingHoursExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isWorkingHoursExpanded
                        ? 'hide_other_days'.tr()
                        : 'show_other_days'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isWorkingHoursExpanded
                        ? Iconsax.arrow_up_2
                        : Iconsax.arrow_down_2,
                    size: 18,
                    color: AppColors.primaryRed,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 16),
                ...otherEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDayHoursCard(entry.key, entry.value, false),
                  ),
                ),
              ],
            ),
            crossFadeState: _isWorkingHoursExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ],
    );
  }

  Widget _buildDayHoursCard(String dayName, dynamic hours, bool isToday) {
    final formattedHours = _formatWorkingHours(hours);
    final isClosed = formattedHours == 'closed'.tr();
    final isOpenNow = isToday && !isClosed && _isCurrentlyOpen(formattedHours);

    Color bgColor = isToday
        ? (isClosed
              ? Colors.red.shade50
              : AppColors.primaryRed.withValues(alpha: 0.05))
        : Colors.transparent;

    Color textColor = isToday
        ? (isClosed ? Colors.red : AppColors.primaryRed)
        : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? (isClosed
                    ? Colors.red.withValues(alpha: 0.2)
                    : AppColors.primaryRed.withValues(alpha: 0.2))
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isToday
                      ? (isClosed ? Colors.red : AppColors.primaryRed)
                      : Colors.grey.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _translateDayName(dayName),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (isToday && isOpenNow)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'open_now'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                isClosed ? Iconsax.close_circle : Iconsax.clock,
                size: 18,
                color: isClosed ? Colors.red : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                formattedHours,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isClosed ? Colors.red : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchContactSection(BranchEntity branch) {
    return _buildSectionLayout(
      title: 'contact_info'.tr(),
      icon: Iconsax.call,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.call,
                    size: 24,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'phone_number'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        branch.contactPhone!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      if (branch.contactPhone != null &&
                          branch.contactPhone!.isNotEmpty) {
                        final Uri telUri = Uri.parse(
                          'tel:${branch.contactPhone}',
                        );
                        try {
                          if (await canLaunchUrl(telUri)) {
                            await launchUrl(telUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('could_not_launch_phone'.tr()),
                                  backgroundColor: AppColors.errorColor,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('error_occurred'.tr()),
                                backgroundColor: AppColors.errorColor,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(
                      Iconsax.call,
                      color: AppColors.primaryRed,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () async {
                  if (branch.contactPhone != null &&
                      branch.contactPhone!.isNotEmpty) {
                    final Uri telUri = Uri.parse('tel:${branch.contactPhone}');
                    try {
                      if (await canLaunchUrl(telUri)) {
                        await launchUrl(telUri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('could_not_launch_phone'.tr()),
                              backgroundColor: AppColors.errorColor,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('error_occurred'.tr()),
                            backgroundColor: AppColors.errorColor,
                          ),
                        );
                      }
                    }
                  }
                },
                text: 'call_now',
                width: double.infinity,
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textHeight: 1.2,
                showShadow: false,
                useGradient: true,
                icon: const Icon(Iconsax.call, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingOptionsSection(BuildContext context) {
    return _buildSectionLayout(
      title: 'booking_options'.tr(),
      icon: Iconsax.calendar_tick,
      child: Column(
        children: [
          _buildBookingOptionButton(
            icon: Iconsax.cake,
            title: 'book_special_events'.tr(),
            description: 'special_events_description'.tr(),
            gradientColors: [const Color(0xFFFF5CAB), const Color(0xFFFF6A00)],
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.specialEventsCreate,
                arguments: {'branchId': widget.branchId},
              );
            },
          ),
          const SizedBox(height: 16),
          _buildBookingOptionButton(
            icon: Iconsax.bus,
            title: 'book_school_trips'.tr(),
            description: 'school_trips_description'.tr(),
            gradientColors: [const Color(0xFF4C83FF), const Color(0xFF2E62FF)],
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.schoolTripsCreate,
                arguments: {'branchId': widget.branchId},
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOptionButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required List<Color> gradientColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradientColors.first.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: gradientColors.first.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.arrow_right_3,
                color: gradientColors.first,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, dynamic>> _sortWorkingHoursByToday(
    Map<String, dynamic> workingHours,
  ) {
    final entries = workingHours.entries.toList();

    // Find today's entry
    final todayEntry = entries.firstWhere(
      (entry) => _isToday(entry.key),
      orElse: () => entries.first,
    );

    // Remove today from the list
    entries.remove(todayEntry);

    // Sort remaining entries by day order
    entries.sort((a, b) {
      final dayOrder = {
        'monday': 1,
        'tuesday': 2,
        'wednesday': 3,
        'thursday': 4,
        'friday': 5,
        'saturday': 6,
        'sunday': 7,
        'Monday': 1,
        'Tuesday': 2,
        'Wednesday': 3,
        'Thursday': 4,
        'Friday': 5,
        'Saturday': 6,
        'Sunday': 7,
        'الاثنين': 1,
        'الثلاثاء': 2,
        'الأربعاء': 3,
        'الخميس': 4,
        'الجمعة': 5,
        'السبت': 6,
        'الأحد': 7,
      };

      final aOrder = dayOrder[a.key.toLowerCase()] ?? 0;
      final bOrder = dayOrder[b.key.toLowerCase()] ?? 0;

      return aOrder.compareTo(bOrder);
    });

    return [todayEntry, ...entries];
  }

  bool _isToday(String dayName) {
    final now = DateTime.now();
    final today = now.weekday;

    final dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
      'الاثنين': 1,
      'الثلاثاء': 2,
      'الأربعاء': 3,
      'الخميس': 4,
      'الجمعة': 5,
      'السبت': 6,
      'الأحد': 7,
    };

    return dayMap[dayName.toLowerCase()] == today;
  }

  String _translateDayName(String dayName) {
    final dayTranslations = {
      'monday': 'monday'.tr(),
      'tuesday': 'tuesday'.tr(),
      'wednesday': 'wednesday'.tr(),
      'thursday': 'thursday'.tr(),
      'friday': 'friday'.tr(),
      'saturday': 'saturday'.tr(),
      'sunday': 'sunday'.tr(),
      'Monday': 'monday'.tr(),
      'Tuesday': 'tuesday'.tr(),
      'Wednesday': 'wednesday'.tr(),
      'Thursday': 'thursday'.tr(),
      'Friday': 'friday'.tr(),
      'Saturday': 'saturday'.tr(),
      'Sunday': 'sunday'.tr(),
    };

    return dayTranslations[dayName] ?? dayName;
  }

  bool _isCurrentlyOpen(String hours) {
    try {
      final timePattern = RegExp(r'(\d{1,2}):(\d{2})');
      final matches = timePattern.allMatches(hours).toList();

      if (matches.length >= 2) {
        final now = DateTime.now();
        final currentTimeInMinutes = now.hour * 60 + now.minute;

        final openTimeInMinutes =
            int.parse(matches[0].group(1)!) * 60 +
            int.parse(matches[0].group(2)!);
        final closeTimeInMinutes =
            int.parse(matches[1].group(1)!) * 60 +
            int.parse(matches[1].group(2)!);

        return currentTimeInMinutes >= openTimeInMinutes &&
            currentTimeInMinutes <= closeTimeInMinutes;
      }
    } catch (e) {
      // Ignore parse failure
    }
    return false;
  }

  String _formatWorkingHours(dynamic hours) {
    if (hours == null) return 'closed'.tr();

    if (hours is Map) {
      if (hours.containsKey('closed') && hours['closed'] == true) {
        return 'closed'.tr();
      }
      if (hours.containsKey('open') && hours.containsKey('close')) {
        final openTime = hours['open']?.toString() ?? '';
        final closeTime = hours['close']?.toString() ?? '';
        if (openTime.isNotEmpty && closeTime.isNotEmpty) {
          return '$openTime - $closeTime';
        }
      }
      hours = hours.toString();
    }

    String cleanHours = hours.toString().trim();

    if (cleanHours.contains('closed') || cleanHours.contains('closed: true')) {
      return 'closed'.tr();
    }

    if (cleanHours.contains('open:') && cleanHours.contains('close:')) {
      final openMatch = RegExp(
        r'open:\s*(\d{1,2}:\d{2})',
      ).firstMatch(cleanHours);
      final closeMatch = RegExp(
        r'close:\s*(\d{1,2}:\d{2})',
      ).firstMatch(cleanHours);
      if (openMatch != null && closeMatch != null) {
        return '${openMatch.group(1)} - ${closeMatch.group(1)}';
      }
    }

    if (cleanHours.contains(' - ') || cleanHours.contains('-')) {
      return cleanHours.replaceAll('-', ' - ');
    }

    final timePattern = RegExp(r'(\d{1,2}:\d{2})');
    final matches = timePattern.allMatches(cleanHours).toList();

    if (matches.length >= 2) {
      return '${matches[0].group(1)} - ${matches[1].group(1)}';
    }
    if (matches.length == 1) {
      return '${matches[0].group(1)} - ${matches[0].group(1)}';
    }

    if (cleanHours.toLowerCase() == 'true') return '24/7';
    if (cleanHours.toLowerCase() == 'false' || cleanHours.isEmpty) {
      return 'closed'.tr();
    }

    if (RegExp(r'^\d+$').hasMatch(cleanHours)) {
      final num = int.tryParse(cleanHours);
      if (num == 0) return 'closed'.tr();
      if (num == 1) return '24/7';
    }

    if (cleanHours.toLowerCase() == 'null' ||
        cleanHours.toLowerCase() == 'undefined') {
      return 'closed'.tr();
    }

    return cleanHours;
  }
}
