// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wine_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WineCard _$WineCardFromJson(Map<String, dynamic> json) => _WineCard(
  slug: json['slug'] as String,
  title: json['title'] as String,
  inCatalog: json['in_catalog'] as bool? ?? true,
  name: json['name'] as String?,
  producer: json['producer'] as String?,
  category: json['category'] as String?,
  region: json['region'] as String?,
  grapes: json['grapes'] as String?,
  pageUrl: json['page_url'] as String?,
  pageSource: json['page_source'] as String?,
  pageInSiteSnapshot: json['page_in_site_snapshot'] as bool?,
  reference: json['reference'] as String?,
);

Map<String, dynamic> _$WineCardToJson(_WineCard instance) => <String, dynamic>{
  'slug': instance.slug,
  'title': instance.title,
  'in_catalog': instance.inCatalog,
  'name': instance.name,
  'producer': instance.producer,
  'category': instance.category,
  'region': instance.region,
  'grapes': instance.grapes,
  'page_url': instance.pageUrl,
  'page_source': instance.pageSource,
  'page_in_site_snapshot': instance.pageInSiteSnapshot,
  'reference': instance.reference,
};
