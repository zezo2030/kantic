import 'package:equatable/equatable.dart';
import 'banner_entity.dart';
import 'offer_entity.dart';
import 'branch_entity.dart';
import 'activity_entity.dart';
import 'organizing_branch_entity.dart';
import 'intro_video_entity.dart';

class HomeDataEntity extends Equatable {
  final List<BannerEntity> banners;
  final List<OfferEntity> offers;
  final List<BranchEntity> featuredBranches;
  final List<ActivityEntity> activities;
  final List<OrganizingBranchEntity> organizingBranches;
  final IntroVideoEntity? introVideo;

  const HomeDataEntity({
    required this.banners,
    required this.offers,
    required this.featuredBranches,
    required this.activities,
    required this.organizingBranches,
    this.introVideo,
  });

  @override
  List<Object?> get props =>
      [banners, offers, featuredBranches, activities, organizingBranches, introVideo];
}
