// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wine_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WineCard {

 String get slug; String get title;@JsonKey(name: 'in_catalog') bool get inCatalog; String? get name; String? get producer; String? get category; String? get region; String? get grapes;@JsonKey(name: 'page_url') String? get pageUrl;@JsonKey(name: 'page_source') String? get pageSource;@JsonKey(name: 'page_in_site_snapshot') bool? get pageInSiteSnapshot;/// Relative path of the reference thumbnail (`/api/reference/<slug>.jpg`),
/// resolved against the API origin by the repository.
 String? get reference;
/// Create a copy of WineCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WineCardCopyWith<WineCard> get copyWith => _$WineCardCopyWithImpl<WineCard>(this as WineCard, _$identity);

  /// Serializes this WineCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WineCard&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.inCatalog, inCatalog) || other.inCatalog == inCatalog)&&(identical(other.name, name) || other.name == name)&&(identical(other.producer, producer) || other.producer == producer)&&(identical(other.category, category) || other.category == category)&&(identical(other.region, region) || other.region == region)&&(identical(other.grapes, grapes) || other.grapes == grapes)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl)&&(identical(other.pageSource, pageSource) || other.pageSource == pageSource)&&(identical(other.pageInSiteSnapshot, pageInSiteSnapshot) || other.pageInSiteSnapshot == pageInSiteSnapshot)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,title,inCatalog,name,producer,category,region,grapes,pageUrl,pageSource,pageInSiteSnapshot,reference);

@override
String toString() {
  return 'WineCard(slug: $slug, title: $title, inCatalog: $inCatalog, name: $name, producer: $producer, category: $category, region: $region, grapes: $grapes, pageUrl: $pageUrl, pageSource: $pageSource, pageInSiteSnapshot: $pageInSiteSnapshot, reference: $reference)';
}


}

/// @nodoc
abstract mixin class $WineCardCopyWith<$Res>  {
  factory $WineCardCopyWith(WineCard value, $Res Function(WineCard) _then) = _$WineCardCopyWithImpl;
@useResult
$Res call({
 String slug, String title,@JsonKey(name: 'in_catalog') bool inCatalog, String? name, String? producer, String? category, String? region, String? grapes,@JsonKey(name: 'page_url') String? pageUrl,@JsonKey(name: 'page_source') String? pageSource,@JsonKey(name: 'page_in_site_snapshot') bool? pageInSiteSnapshot, String? reference
});




}
/// @nodoc
class _$WineCardCopyWithImpl<$Res>
    implements $WineCardCopyWith<$Res> {
  _$WineCardCopyWithImpl(this._self, this._then);

  final WineCard _self;
  final $Res Function(WineCard) _then;

/// Create a copy of WineCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? title = null,Object? inCatalog = null,Object? name = freezed,Object? producer = freezed,Object? category = freezed,Object? region = freezed,Object? grapes = freezed,Object? pageUrl = freezed,Object? pageSource = freezed,Object? pageInSiteSnapshot = freezed,Object? reference = freezed,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,inCatalog: null == inCatalog ? _self.inCatalog : inCatalog // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,producer: freezed == producer ? _self.producer : producer // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,grapes: freezed == grapes ? _self.grapes : grapes // ignore: cast_nullable_to_non_nullable
as String?,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,pageSource: freezed == pageSource ? _self.pageSource : pageSource // ignore: cast_nullable_to_non_nullable
as String?,pageInSiteSnapshot: freezed == pageInSiteSnapshot ? _self.pageInSiteSnapshot : pageInSiteSnapshot // ignore: cast_nullable_to_non_nullable
as bool?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WineCard].
extension WineCardPatterns on WineCard {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WineCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WineCard() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WineCard value)  $default,){
final _that = this;
switch (_that) {
case _WineCard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WineCard value)?  $default,){
final _that = this;
switch (_that) {
case _WineCard() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String title, @JsonKey(name: 'in_catalog')  bool inCatalog,  String? name,  String? producer,  String? category,  String? region,  String? grapes, @JsonKey(name: 'page_url')  String? pageUrl, @JsonKey(name: 'page_source')  String? pageSource, @JsonKey(name: 'page_in_site_snapshot')  bool? pageInSiteSnapshot,  String? reference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WineCard() when $default != null:
return $default(_that.slug,_that.title,_that.inCatalog,_that.name,_that.producer,_that.category,_that.region,_that.grapes,_that.pageUrl,_that.pageSource,_that.pageInSiteSnapshot,_that.reference);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String title, @JsonKey(name: 'in_catalog')  bool inCatalog,  String? name,  String? producer,  String? category,  String? region,  String? grapes, @JsonKey(name: 'page_url')  String? pageUrl, @JsonKey(name: 'page_source')  String? pageSource, @JsonKey(name: 'page_in_site_snapshot')  bool? pageInSiteSnapshot,  String? reference)  $default,) {final _that = this;
switch (_that) {
case _WineCard():
return $default(_that.slug,_that.title,_that.inCatalog,_that.name,_that.producer,_that.category,_that.region,_that.grapes,_that.pageUrl,_that.pageSource,_that.pageInSiteSnapshot,_that.reference);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String title, @JsonKey(name: 'in_catalog')  bool inCatalog,  String? name,  String? producer,  String? category,  String? region,  String? grapes, @JsonKey(name: 'page_url')  String? pageUrl, @JsonKey(name: 'page_source')  String? pageSource, @JsonKey(name: 'page_in_site_snapshot')  bool? pageInSiteSnapshot,  String? reference)?  $default,) {final _that = this;
switch (_that) {
case _WineCard() when $default != null:
return $default(_that.slug,_that.title,_that.inCatalog,_that.name,_that.producer,_that.category,_that.region,_that.grapes,_that.pageUrl,_that.pageSource,_that.pageInSiteSnapshot,_that.reference);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WineCard extends WineCard {
  const _WineCard({required this.slug, required this.title, @JsonKey(name: 'in_catalog') this.inCatalog = true, this.name, this.producer, this.category, this.region, this.grapes, @JsonKey(name: 'page_url') this.pageUrl, @JsonKey(name: 'page_source') this.pageSource, @JsonKey(name: 'page_in_site_snapshot') this.pageInSiteSnapshot, this.reference}): super._();
  factory _WineCard.fromJson(Map<String, dynamic> json) => _$WineCardFromJson(json);

@override final  String slug;
@override final  String title;
@override@JsonKey(name: 'in_catalog') final  bool inCatalog;
@override final  String? name;
@override final  String? producer;
@override final  String? category;
@override final  String? region;
@override final  String? grapes;
@override@JsonKey(name: 'page_url') final  String? pageUrl;
@override@JsonKey(name: 'page_source') final  String? pageSource;
@override@JsonKey(name: 'page_in_site_snapshot') final  bool? pageInSiteSnapshot;
/// Relative path of the reference thumbnail (`/api/reference/<slug>.jpg`),
/// resolved against the API origin by the repository.
@override final  String? reference;

/// Create a copy of WineCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WineCardCopyWith<_WineCard> get copyWith => __$WineCardCopyWithImpl<_WineCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WineCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WineCard&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.inCatalog, inCatalog) || other.inCatalog == inCatalog)&&(identical(other.name, name) || other.name == name)&&(identical(other.producer, producer) || other.producer == producer)&&(identical(other.category, category) || other.category == category)&&(identical(other.region, region) || other.region == region)&&(identical(other.grapes, grapes) || other.grapes == grapes)&&(identical(other.pageUrl, pageUrl) || other.pageUrl == pageUrl)&&(identical(other.pageSource, pageSource) || other.pageSource == pageSource)&&(identical(other.pageInSiteSnapshot, pageInSiteSnapshot) || other.pageInSiteSnapshot == pageInSiteSnapshot)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,title,inCatalog,name,producer,category,region,grapes,pageUrl,pageSource,pageInSiteSnapshot,reference);

@override
String toString() {
  return 'WineCard(slug: $slug, title: $title, inCatalog: $inCatalog, name: $name, producer: $producer, category: $category, region: $region, grapes: $grapes, pageUrl: $pageUrl, pageSource: $pageSource, pageInSiteSnapshot: $pageInSiteSnapshot, reference: $reference)';
}


}

/// @nodoc
abstract mixin class _$WineCardCopyWith<$Res> implements $WineCardCopyWith<$Res> {
  factory _$WineCardCopyWith(_WineCard value, $Res Function(_WineCard) _then) = __$WineCardCopyWithImpl;
@override @useResult
$Res call({
 String slug, String title,@JsonKey(name: 'in_catalog') bool inCatalog, String? name, String? producer, String? category, String? region, String? grapes,@JsonKey(name: 'page_url') String? pageUrl,@JsonKey(name: 'page_source') String? pageSource,@JsonKey(name: 'page_in_site_snapshot') bool? pageInSiteSnapshot, String? reference
});




}
/// @nodoc
class __$WineCardCopyWithImpl<$Res>
    implements _$WineCardCopyWith<$Res> {
  __$WineCardCopyWithImpl(this._self, this._then);

  final _WineCard _self;
  final $Res Function(_WineCard) _then;

/// Create a copy of WineCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? title = null,Object? inCatalog = null,Object? name = freezed,Object? producer = freezed,Object? category = freezed,Object? region = freezed,Object? grapes = freezed,Object? pageUrl = freezed,Object? pageSource = freezed,Object? pageInSiteSnapshot = freezed,Object? reference = freezed,}) {
  return _then(_WineCard(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,inCatalog: null == inCatalog ? _self.inCatalog : inCatalog // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,producer: freezed == producer ? _self.producer : producer // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,grapes: freezed == grapes ? _self.grapes : grapes // ignore: cast_nullable_to_non_nullable
as String?,pageUrl: freezed == pageUrl ? _self.pageUrl : pageUrl // ignore: cast_nullable_to_non_nullable
as String?,pageSource: freezed == pageSource ? _self.pageSource : pageSource // ignore: cast_nullable_to_non_nullable
as String?,pageInSiteSnapshot: freezed == pageInSiteSnapshot ? _self.pageInSiteSnapshot : pageInSiteSnapshot // ignore: cast_nullable_to_non_nullable
as bool?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
