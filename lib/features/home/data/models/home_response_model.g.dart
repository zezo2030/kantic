// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeResponseModel _$HomeResponseModelFromJson(Map<String, dynamic> json) =>
    HomeResponseModel(
      banners: (json['banners'] as List<dynamic>)
          .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      offers: (json['offers'] as List<dynamic>)
          .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      featuredBranches: (json['featuredBranches'] as List<dynamic>)
          .map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      activities: (json['activities'] as List<dynamic>)
          .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      organizingBranches: (json['organizingBranches'] as List<dynamic>)
          .map((e) => OrganizingBranchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      introVideo: json['introVideo'] == null
          ? null
          : IntroVideoModel.fromJson(
              json['introVideo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HomeResponseModelToJson(HomeResponseModel instance) =>
    <String, dynamic>{
      'banners': instance.banners,
      'offers': instance.offers,
      'featuredBranches': instance.featuredBranches,
      'activities': instance.activities,
      'organizingBranches': instance.organizingBranches,
      'introVideo': instance.introVideo,
    };
