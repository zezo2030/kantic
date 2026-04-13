import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/home_data_entity.dart';
import 'banner_model.dart';
import 'offer_model.dart';
import 'branch_model.dart';
import 'activity_model.dart';
import 'organizing_branch_model.dart';

part 'home_response_model.g.dart';

@JsonSerializable()
class HomeResponseModel {
  final List<BannerModel> banners;
  final List<OfferModel> offers;
  final List<BranchModel> featuredBranches;
  final List<ActivityModel> activities;
  final List<OrganizingBranchModel> organizingBranches;

  const HomeResponseModel({
    required this.banners,
    required this.offers,
    required this.featuredBranches,
    required this.activities,
    required this.organizingBranches,
  });

  factory HomeResponseModel.fromJson(Map<String, dynamic> json) =>
      _$HomeResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$HomeResponseModelToJson(this);

  factory HomeResponseModel.fromEntity(HomeDataEntity entity) {
    return HomeResponseModel(
      banners: entity.banners.map((e) => BannerModel.fromEntity(e)).toList(),
      offers: entity.offers.map((e) => OfferModel.fromEntity(e)).toList(),
      featuredBranches: entity.featuredBranches.map((e) => BranchModel.fromEntity(e)).toList(),
      activities: entity.activities.map((e) => ActivityModel.fromEntity(e)).toList(),
      organizingBranches: entity.organizingBranches.map((e) => OrganizingBranchModel.fromEntity(e)).toList(),
    );
  }

  HomeDataEntity toEntity() {
    return HomeDataEntity(
      banners: banners.map((e) => e.toEntity()).toList(),
      offers: offers.map((e) => e.toEntity()).toList(),
      featuredBranches: featuredBranches.map((e) => e.toEntity()).toList(),
      activities: activities.map((e) => e.toEntity()).toList(),
      organizingBranches: organizingBranches.map((e) => e.toEntity()).toList(),
    );
  }
}
