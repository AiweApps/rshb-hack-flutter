// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recognition_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecognitionView {

@JsonKey(unknownEnumValue: ScanDecision.other) ScanDecision get decision;@JsonKey(name: 'decision_text') String? get decisionText;@JsonKey(name: 'raw_slug') String? get rawSlug;@JsonKey(name: 'best_slug') String? get bestSlug;@JsonKey(name: 'published_card') WineCard? get publishedCard;@JsonKey(unknownEnumValue: ScanMode.unknown) ScanMode get mode;@BottleBoxConverter() BottleBox? get roi;@JsonKey(name: 'bottle_count') int get bottleCount;@JsonKey(name: 'primary_instance_id') String? get primaryInstanceId;@JsonKey(name: 'primary_basis') String? get primaryBasis;@JsonKey(name: 'frame_size') List<int>? get frameSize; ImageInfo? get image; List<RecognizedBottle> get bottles; List<String> get reasons;@JsonKey(name: 'profile_checksum') String? get profileChecksum;@JsonKey(name: 'backend_ms') int? get backendMs;
/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecognitionViewCopyWith<RecognitionView> get copyWith => _$RecognitionViewCopyWithImpl<RecognitionView>(this as RecognitionView, _$identity);

  /// Serializes this RecognitionView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecognitionView&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.decisionText, decisionText) || other.decisionText == decisionText)&&(identical(other.rawSlug, rawSlug) || other.rawSlug == rawSlug)&&(identical(other.bestSlug, bestSlug) || other.bestSlug == bestSlug)&&(identical(other.publishedCard, publishedCard) || other.publishedCard == publishedCard)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.roi, roi) || other.roi == roi)&&(identical(other.bottleCount, bottleCount) || other.bottleCount == bottleCount)&&(identical(other.primaryInstanceId, primaryInstanceId) || other.primaryInstanceId == primaryInstanceId)&&(identical(other.primaryBasis, primaryBasis) || other.primaryBasis == primaryBasis)&&const DeepCollectionEquality().equals(other.frameSize, frameSize)&&(identical(other.image, image) || other.image == image)&&const DeepCollectionEquality().equals(other.bottles, bottles)&&const DeepCollectionEquality().equals(other.reasons, reasons)&&(identical(other.profileChecksum, profileChecksum) || other.profileChecksum == profileChecksum)&&(identical(other.backendMs, backendMs) || other.backendMs == backendMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,decision,decisionText,rawSlug,bestSlug,publishedCard,mode,roi,bottleCount,primaryInstanceId,primaryBasis,const DeepCollectionEquality().hash(frameSize),image,const DeepCollectionEquality().hash(bottles),const DeepCollectionEquality().hash(reasons),profileChecksum,backendMs);

@override
String toString() {
  return 'RecognitionView(decision: $decision, decisionText: $decisionText, rawSlug: $rawSlug, bestSlug: $bestSlug, publishedCard: $publishedCard, mode: $mode, roi: $roi, bottleCount: $bottleCount, primaryInstanceId: $primaryInstanceId, primaryBasis: $primaryBasis, frameSize: $frameSize, image: $image, bottles: $bottles, reasons: $reasons, profileChecksum: $profileChecksum, backendMs: $backendMs)';
}


}

/// @nodoc
abstract mixin class $RecognitionViewCopyWith<$Res>  {
  factory $RecognitionViewCopyWith(RecognitionView value, $Res Function(RecognitionView) _then) = _$RecognitionViewCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: ScanDecision.other) ScanDecision decision,@JsonKey(name: 'decision_text') String? decisionText,@JsonKey(name: 'raw_slug') String? rawSlug,@JsonKey(name: 'best_slug') String? bestSlug,@JsonKey(name: 'published_card') WineCard? publishedCard,@JsonKey(unknownEnumValue: ScanMode.unknown) ScanMode mode,@BottleBoxConverter() BottleBox? roi,@JsonKey(name: 'bottle_count') int bottleCount,@JsonKey(name: 'primary_instance_id') String? primaryInstanceId,@JsonKey(name: 'primary_basis') String? primaryBasis,@JsonKey(name: 'frame_size') List<int>? frameSize, ImageInfo? image, List<RecognizedBottle> bottles, List<String> reasons,@JsonKey(name: 'profile_checksum') String? profileChecksum,@JsonKey(name: 'backend_ms') int? backendMs
});


$WineCardCopyWith<$Res>? get publishedCard;$BottleBoxCopyWith<$Res>? get roi;$ImageInfoCopyWith<$Res>? get image;

}
/// @nodoc
class _$RecognitionViewCopyWithImpl<$Res>
    implements $RecognitionViewCopyWith<$Res> {
  _$RecognitionViewCopyWithImpl(this._self, this._then);

  final RecognitionView _self;
  final $Res Function(RecognitionView) _then;

/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decision = null,Object? decisionText = freezed,Object? rawSlug = freezed,Object? bestSlug = freezed,Object? publishedCard = freezed,Object? mode = null,Object? roi = freezed,Object? bottleCount = null,Object? primaryInstanceId = freezed,Object? primaryBasis = freezed,Object? frameSize = freezed,Object? image = freezed,Object? bottles = null,Object? reasons = null,Object? profileChecksum = freezed,Object? backendMs = freezed,}) {
  return _then(_self.copyWith(
decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as ScanDecision,decisionText: freezed == decisionText ? _self.decisionText : decisionText // ignore: cast_nullable_to_non_nullable
as String?,rawSlug: freezed == rawSlug ? _self.rawSlug : rawSlug // ignore: cast_nullable_to_non_nullable
as String?,bestSlug: freezed == bestSlug ? _self.bestSlug : bestSlug // ignore: cast_nullable_to_non_nullable
as String?,publishedCard: freezed == publishedCard ? _self.publishedCard : publishedCard // ignore: cast_nullable_to_non_nullable
as WineCard?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ScanMode,roi: freezed == roi ? _self.roi : roi // ignore: cast_nullable_to_non_nullable
as BottleBox?,bottleCount: null == bottleCount ? _self.bottleCount : bottleCount // ignore: cast_nullable_to_non_nullable
as int,primaryInstanceId: freezed == primaryInstanceId ? _self.primaryInstanceId : primaryInstanceId // ignore: cast_nullable_to_non_nullable
as String?,primaryBasis: freezed == primaryBasis ? _self.primaryBasis : primaryBasis // ignore: cast_nullable_to_non_nullable
as String?,frameSize: freezed == frameSize ? _self.frameSize : frameSize // ignore: cast_nullable_to_non_nullable
as List<int>?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ImageInfo?,bottles: null == bottles ? _self.bottles : bottles // ignore: cast_nullable_to_non_nullable
as List<RecognizedBottle>,reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,profileChecksum: freezed == profileChecksum ? _self.profileChecksum : profileChecksum // ignore: cast_nullable_to_non_nullable
as String?,backendMs: freezed == backendMs ? _self.backendMs : backendMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WineCardCopyWith<$Res>? get publishedCard {
    if (_self.publishedCard == null) {
    return null;
  }

  return $WineCardCopyWith<$Res>(_self.publishedCard!, (value) {
    return _then(_self.copyWith(publishedCard: value));
  });
}/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get roi {
    if (_self.roi == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.roi!, (value) {
    return _then(_self.copyWith(roi: value));
  });
}/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageInfoCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $ImageInfoCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecognitionView].
extension RecognitionViewPatterns on RecognitionView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecognitionView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecognitionView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecognitionView value)  $default,){
final _that = this;
switch (_that) {
case _RecognitionView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecognitionView value)?  $default,){
final _that = this;
switch (_that) {
case _RecognitionView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: ScanDecision.other)  ScanDecision decision, @JsonKey(name: 'decision_text')  String? decisionText, @JsonKey(name: 'raw_slug')  String? rawSlug, @JsonKey(name: 'best_slug')  String? bestSlug, @JsonKey(name: 'published_card')  WineCard? publishedCard, @JsonKey(unknownEnumValue: ScanMode.unknown)  ScanMode mode, @BottleBoxConverter()  BottleBox? roi, @JsonKey(name: 'bottle_count')  int bottleCount, @JsonKey(name: 'primary_instance_id')  String? primaryInstanceId, @JsonKey(name: 'primary_basis')  String? primaryBasis, @JsonKey(name: 'frame_size')  List<int>? frameSize,  ImageInfo? image,  List<RecognizedBottle> bottles,  List<String> reasons, @JsonKey(name: 'profile_checksum')  String? profileChecksum, @JsonKey(name: 'backend_ms')  int? backendMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecognitionView() when $default != null:
return $default(_that.decision,_that.decisionText,_that.rawSlug,_that.bestSlug,_that.publishedCard,_that.mode,_that.roi,_that.bottleCount,_that.primaryInstanceId,_that.primaryBasis,_that.frameSize,_that.image,_that.bottles,_that.reasons,_that.profileChecksum,_that.backendMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: ScanDecision.other)  ScanDecision decision, @JsonKey(name: 'decision_text')  String? decisionText, @JsonKey(name: 'raw_slug')  String? rawSlug, @JsonKey(name: 'best_slug')  String? bestSlug, @JsonKey(name: 'published_card')  WineCard? publishedCard, @JsonKey(unknownEnumValue: ScanMode.unknown)  ScanMode mode, @BottleBoxConverter()  BottleBox? roi, @JsonKey(name: 'bottle_count')  int bottleCount, @JsonKey(name: 'primary_instance_id')  String? primaryInstanceId, @JsonKey(name: 'primary_basis')  String? primaryBasis, @JsonKey(name: 'frame_size')  List<int>? frameSize,  ImageInfo? image,  List<RecognizedBottle> bottles,  List<String> reasons, @JsonKey(name: 'profile_checksum')  String? profileChecksum, @JsonKey(name: 'backend_ms')  int? backendMs)  $default,) {final _that = this;
switch (_that) {
case _RecognitionView():
return $default(_that.decision,_that.decisionText,_that.rawSlug,_that.bestSlug,_that.publishedCard,_that.mode,_that.roi,_that.bottleCount,_that.primaryInstanceId,_that.primaryBasis,_that.frameSize,_that.image,_that.bottles,_that.reasons,_that.profileChecksum,_that.backendMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: ScanDecision.other)  ScanDecision decision, @JsonKey(name: 'decision_text')  String? decisionText, @JsonKey(name: 'raw_slug')  String? rawSlug, @JsonKey(name: 'best_slug')  String? bestSlug, @JsonKey(name: 'published_card')  WineCard? publishedCard, @JsonKey(unknownEnumValue: ScanMode.unknown)  ScanMode mode, @BottleBoxConverter()  BottleBox? roi, @JsonKey(name: 'bottle_count')  int bottleCount, @JsonKey(name: 'primary_instance_id')  String? primaryInstanceId, @JsonKey(name: 'primary_basis')  String? primaryBasis, @JsonKey(name: 'frame_size')  List<int>? frameSize,  ImageInfo? image,  List<RecognizedBottle> bottles,  List<String> reasons, @JsonKey(name: 'profile_checksum')  String? profileChecksum, @JsonKey(name: 'backend_ms')  int? backendMs)?  $default,) {final _that = this;
switch (_that) {
case _RecognitionView() when $default != null:
return $default(_that.decision,_that.decisionText,_that.rawSlug,_that.bestSlug,_that.publishedCard,_that.mode,_that.roi,_that.bottleCount,_that.primaryInstanceId,_that.primaryBasis,_that.frameSize,_that.image,_that.bottles,_that.reasons,_that.profileChecksum,_that.backendMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecognitionView extends RecognitionView {
  const _RecognitionView({@JsonKey(unknownEnumValue: ScanDecision.other) this.decision = ScanDecision.other, @JsonKey(name: 'decision_text') this.decisionText, @JsonKey(name: 'raw_slug') this.rawSlug, @JsonKey(name: 'best_slug') this.bestSlug, @JsonKey(name: 'published_card') this.publishedCard, @JsonKey(unknownEnumValue: ScanMode.unknown) this.mode = ScanMode.unknown, @BottleBoxConverter() this.roi, @JsonKey(name: 'bottle_count') this.bottleCount = 0, @JsonKey(name: 'primary_instance_id') this.primaryInstanceId, @JsonKey(name: 'primary_basis') this.primaryBasis, @JsonKey(name: 'frame_size') final  List<int>? frameSize, this.image, final  List<RecognizedBottle> bottles = const <RecognizedBottle>[], final  List<String> reasons = const <String>[], @JsonKey(name: 'profile_checksum') this.profileChecksum, @JsonKey(name: 'backend_ms') this.backendMs}): _frameSize = frameSize,_bottles = bottles,_reasons = reasons,super._();
  factory _RecognitionView.fromJson(Map<String, dynamic> json) => _$RecognitionViewFromJson(json);

@override@JsonKey(unknownEnumValue: ScanDecision.other) final  ScanDecision decision;
@override@JsonKey(name: 'decision_text') final  String? decisionText;
@override@JsonKey(name: 'raw_slug') final  String? rawSlug;
@override@JsonKey(name: 'best_slug') final  String? bestSlug;
@override@JsonKey(name: 'published_card') final  WineCard? publishedCard;
@override@JsonKey(unknownEnumValue: ScanMode.unknown) final  ScanMode mode;
@override@BottleBoxConverter() final  BottleBox? roi;
@override@JsonKey(name: 'bottle_count') final  int bottleCount;
@override@JsonKey(name: 'primary_instance_id') final  String? primaryInstanceId;
@override@JsonKey(name: 'primary_basis') final  String? primaryBasis;
 final  List<int>? _frameSize;
@override@JsonKey(name: 'frame_size') List<int>? get frameSize {
  final value = _frameSize;
  if (value == null) return null;
  if (_frameSize is EqualUnmodifiableListView) return _frameSize;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  ImageInfo? image;
 final  List<RecognizedBottle> _bottles;
@override@JsonKey() List<RecognizedBottle> get bottles {
  if (_bottles is EqualUnmodifiableListView) return _bottles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bottles);
}

 final  List<String> _reasons;
@override@JsonKey() List<String> get reasons {
  if (_reasons is EqualUnmodifiableListView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reasons);
}

@override@JsonKey(name: 'profile_checksum') final  String? profileChecksum;
@override@JsonKey(name: 'backend_ms') final  int? backendMs;

/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecognitionViewCopyWith<_RecognitionView> get copyWith => __$RecognitionViewCopyWithImpl<_RecognitionView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecognitionViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecognitionView&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.decisionText, decisionText) || other.decisionText == decisionText)&&(identical(other.rawSlug, rawSlug) || other.rawSlug == rawSlug)&&(identical(other.bestSlug, bestSlug) || other.bestSlug == bestSlug)&&(identical(other.publishedCard, publishedCard) || other.publishedCard == publishedCard)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.roi, roi) || other.roi == roi)&&(identical(other.bottleCount, bottleCount) || other.bottleCount == bottleCount)&&(identical(other.primaryInstanceId, primaryInstanceId) || other.primaryInstanceId == primaryInstanceId)&&(identical(other.primaryBasis, primaryBasis) || other.primaryBasis == primaryBasis)&&const DeepCollectionEquality().equals(other._frameSize, _frameSize)&&(identical(other.image, image) || other.image == image)&&const DeepCollectionEquality().equals(other._bottles, _bottles)&&const DeepCollectionEquality().equals(other._reasons, _reasons)&&(identical(other.profileChecksum, profileChecksum) || other.profileChecksum == profileChecksum)&&(identical(other.backendMs, backendMs) || other.backendMs == backendMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,decision,decisionText,rawSlug,bestSlug,publishedCard,mode,roi,bottleCount,primaryInstanceId,primaryBasis,const DeepCollectionEquality().hash(_frameSize),image,const DeepCollectionEquality().hash(_bottles),const DeepCollectionEquality().hash(_reasons),profileChecksum,backendMs);

@override
String toString() {
  return 'RecognitionView(decision: $decision, decisionText: $decisionText, rawSlug: $rawSlug, bestSlug: $bestSlug, publishedCard: $publishedCard, mode: $mode, roi: $roi, bottleCount: $bottleCount, primaryInstanceId: $primaryInstanceId, primaryBasis: $primaryBasis, frameSize: $frameSize, image: $image, bottles: $bottles, reasons: $reasons, profileChecksum: $profileChecksum, backendMs: $backendMs)';
}


}

/// @nodoc
abstract mixin class _$RecognitionViewCopyWith<$Res> implements $RecognitionViewCopyWith<$Res> {
  factory _$RecognitionViewCopyWith(_RecognitionView value, $Res Function(_RecognitionView) _then) = __$RecognitionViewCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: ScanDecision.other) ScanDecision decision,@JsonKey(name: 'decision_text') String? decisionText,@JsonKey(name: 'raw_slug') String? rawSlug,@JsonKey(name: 'best_slug') String? bestSlug,@JsonKey(name: 'published_card') WineCard? publishedCard,@JsonKey(unknownEnumValue: ScanMode.unknown) ScanMode mode,@BottleBoxConverter() BottleBox? roi,@JsonKey(name: 'bottle_count') int bottleCount,@JsonKey(name: 'primary_instance_id') String? primaryInstanceId,@JsonKey(name: 'primary_basis') String? primaryBasis,@JsonKey(name: 'frame_size') List<int>? frameSize, ImageInfo? image, List<RecognizedBottle> bottles, List<String> reasons,@JsonKey(name: 'profile_checksum') String? profileChecksum,@JsonKey(name: 'backend_ms') int? backendMs
});


@override $WineCardCopyWith<$Res>? get publishedCard;@override $BottleBoxCopyWith<$Res>? get roi;@override $ImageInfoCopyWith<$Res>? get image;

}
/// @nodoc
class __$RecognitionViewCopyWithImpl<$Res>
    implements _$RecognitionViewCopyWith<$Res> {
  __$RecognitionViewCopyWithImpl(this._self, this._then);

  final _RecognitionView _self;
  final $Res Function(_RecognitionView) _then;

/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decision = null,Object? decisionText = freezed,Object? rawSlug = freezed,Object? bestSlug = freezed,Object? publishedCard = freezed,Object? mode = null,Object? roi = freezed,Object? bottleCount = null,Object? primaryInstanceId = freezed,Object? primaryBasis = freezed,Object? frameSize = freezed,Object? image = freezed,Object? bottles = null,Object? reasons = null,Object? profileChecksum = freezed,Object? backendMs = freezed,}) {
  return _then(_RecognitionView(
decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as ScanDecision,decisionText: freezed == decisionText ? _self.decisionText : decisionText // ignore: cast_nullable_to_non_nullable
as String?,rawSlug: freezed == rawSlug ? _self.rawSlug : rawSlug // ignore: cast_nullable_to_non_nullable
as String?,bestSlug: freezed == bestSlug ? _self.bestSlug : bestSlug // ignore: cast_nullable_to_non_nullable
as String?,publishedCard: freezed == publishedCard ? _self.publishedCard : publishedCard // ignore: cast_nullable_to_non_nullable
as WineCard?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ScanMode,roi: freezed == roi ? _self.roi : roi // ignore: cast_nullable_to_non_nullable
as BottleBox?,bottleCount: null == bottleCount ? _self.bottleCount : bottleCount // ignore: cast_nullable_to_non_nullable
as int,primaryInstanceId: freezed == primaryInstanceId ? _self.primaryInstanceId : primaryInstanceId // ignore: cast_nullable_to_non_nullable
as String?,primaryBasis: freezed == primaryBasis ? _self.primaryBasis : primaryBasis // ignore: cast_nullable_to_non_nullable
as String?,frameSize: freezed == frameSize ? _self._frameSize : frameSize // ignore: cast_nullable_to_non_nullable
as List<int>?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ImageInfo?,bottles: null == bottles ? _self._bottles : bottles // ignore: cast_nullable_to_non_nullable
as List<RecognizedBottle>,reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,profileChecksum: freezed == profileChecksum ? _self.profileChecksum : profileChecksum // ignore: cast_nullable_to_non_nullable
as String?,backendMs: freezed == backendMs ? _self.backendMs : backendMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WineCardCopyWith<$Res>? get publishedCard {
    if (_self.publishedCard == null) {
    return null;
  }

  return $WineCardCopyWith<$Res>(_self.publishedCard!, (value) {
    return _then(_self.copyWith(publishedCard: value));
  });
}/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get roi {
    if (_self.roi == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.roi!, (value) {
    return _then(_self.copyWith(roi: value));
  });
}/// Create a copy of RecognitionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageInfoCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $ImageInfoCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// @nodoc
mixin _$RecognizedBottle {

 int get number;@JsonKey(name: 'instance_id') String get instanceId;@BottleBoxConverter() BottleBox? get geometry;@JsonKey(name: 'label_bbox')@BottleBoxConverter() BottleBox? get labelBbox;@JsonKey(name: 'select_roi')@BottleBoxConverter() BottleBox? get selectRoi; String? get selectable; bool get primary; bool get addressed;@JsonKey(unknownEnumValue: ScanDecision.other) ScanDecision get decision;@JsonKey(name: 'decision_text') String? get decisionText; List<String> get reasons; WineCard? get best; List<WineCard> get alternatives;
/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecognizedBottleCopyWith<RecognizedBottle> get copyWith => _$RecognizedBottleCopyWithImpl<RecognizedBottle>(this as RecognizedBottle, _$identity);

  /// Serializes this RecognizedBottle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecognizedBottle&&(identical(other.number, number) || other.number == number)&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&(identical(other.geometry, geometry) || other.geometry == geometry)&&(identical(other.labelBbox, labelBbox) || other.labelBbox == labelBbox)&&(identical(other.selectRoi, selectRoi) || other.selectRoi == selectRoi)&&(identical(other.selectable, selectable) || other.selectable == selectable)&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.addressed, addressed) || other.addressed == addressed)&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.decisionText, decisionText) || other.decisionText == decisionText)&&const DeepCollectionEquality().equals(other.reasons, reasons)&&(identical(other.best, best) || other.best == best)&&const DeepCollectionEquality().equals(other.alternatives, alternatives));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,instanceId,geometry,labelBbox,selectRoi,selectable,primary,addressed,decision,decisionText,const DeepCollectionEquality().hash(reasons),best,const DeepCollectionEquality().hash(alternatives));

@override
String toString() {
  return 'RecognizedBottle(number: $number, instanceId: $instanceId, geometry: $geometry, labelBbox: $labelBbox, selectRoi: $selectRoi, selectable: $selectable, primary: $primary, addressed: $addressed, decision: $decision, decisionText: $decisionText, reasons: $reasons, best: $best, alternatives: $alternatives)';
}


}

/// @nodoc
abstract mixin class $RecognizedBottleCopyWith<$Res>  {
  factory $RecognizedBottleCopyWith(RecognizedBottle value, $Res Function(RecognizedBottle) _then) = _$RecognizedBottleCopyWithImpl;
@useResult
$Res call({
 int number,@JsonKey(name: 'instance_id') String instanceId,@BottleBoxConverter() BottleBox? geometry,@JsonKey(name: 'label_bbox')@BottleBoxConverter() BottleBox? labelBbox,@JsonKey(name: 'select_roi')@BottleBoxConverter() BottleBox? selectRoi, String? selectable, bool primary, bool addressed,@JsonKey(unknownEnumValue: ScanDecision.other) ScanDecision decision,@JsonKey(name: 'decision_text') String? decisionText, List<String> reasons, WineCard? best, List<WineCard> alternatives
});


$BottleBoxCopyWith<$Res>? get geometry;$BottleBoxCopyWith<$Res>? get labelBbox;$BottleBoxCopyWith<$Res>? get selectRoi;$WineCardCopyWith<$Res>? get best;

}
/// @nodoc
class _$RecognizedBottleCopyWithImpl<$Res>
    implements $RecognizedBottleCopyWith<$Res> {
  _$RecognizedBottleCopyWithImpl(this._self, this._then);

  final RecognizedBottle _self;
  final $Res Function(RecognizedBottle) _then;

/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? instanceId = null,Object? geometry = freezed,Object? labelBbox = freezed,Object? selectRoi = freezed,Object? selectable = freezed,Object? primary = null,Object? addressed = null,Object? decision = null,Object? decisionText = freezed,Object? reasons = null,Object? best = freezed,Object? alternatives = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as String,geometry: freezed == geometry ? _self.geometry : geometry // ignore: cast_nullable_to_non_nullable
as BottleBox?,labelBbox: freezed == labelBbox ? _self.labelBbox : labelBbox // ignore: cast_nullable_to_non_nullable
as BottleBox?,selectRoi: freezed == selectRoi ? _self.selectRoi : selectRoi // ignore: cast_nullable_to_non_nullable
as BottleBox?,selectable: freezed == selectable ? _self.selectable : selectable // ignore: cast_nullable_to_non_nullable
as String?,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as bool,addressed: null == addressed ? _self.addressed : addressed // ignore: cast_nullable_to_non_nullable
as bool,decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as ScanDecision,decisionText: freezed == decisionText ? _self.decisionText : decisionText // ignore: cast_nullable_to_non_nullable
as String?,reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,best: freezed == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as WineCard?,alternatives: null == alternatives ? _self.alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<WineCard>,
  ));
}
/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get geometry {
    if (_self.geometry == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.geometry!, (value) {
    return _then(_self.copyWith(geometry: value));
  });
}/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get labelBbox {
    if (_self.labelBbox == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.labelBbox!, (value) {
    return _then(_self.copyWith(labelBbox: value));
  });
}/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get selectRoi {
    if (_self.selectRoi == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.selectRoi!, (value) {
    return _then(_self.copyWith(selectRoi: value));
  });
}/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WineCardCopyWith<$Res>? get best {
    if (_self.best == null) {
    return null;
  }

  return $WineCardCopyWith<$Res>(_self.best!, (value) {
    return _then(_self.copyWith(best: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecognizedBottle].
extension RecognizedBottlePatterns on RecognizedBottle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecognizedBottle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecognizedBottle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecognizedBottle value)  $default,){
final _that = this;
switch (_that) {
case _RecognizedBottle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecognizedBottle value)?  $default,){
final _that = this;
switch (_that) {
case _RecognizedBottle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number, @JsonKey(name: 'instance_id')  String instanceId, @BottleBoxConverter()  BottleBox? geometry, @JsonKey(name: 'label_bbox')@BottleBoxConverter()  BottleBox? labelBbox, @JsonKey(name: 'select_roi')@BottleBoxConverter()  BottleBox? selectRoi,  String? selectable,  bool primary,  bool addressed, @JsonKey(unknownEnumValue: ScanDecision.other)  ScanDecision decision, @JsonKey(name: 'decision_text')  String? decisionText,  List<String> reasons,  WineCard? best,  List<WineCard> alternatives)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecognizedBottle() when $default != null:
return $default(_that.number,_that.instanceId,_that.geometry,_that.labelBbox,_that.selectRoi,_that.selectable,_that.primary,_that.addressed,_that.decision,_that.decisionText,_that.reasons,_that.best,_that.alternatives);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number, @JsonKey(name: 'instance_id')  String instanceId, @BottleBoxConverter()  BottleBox? geometry, @JsonKey(name: 'label_bbox')@BottleBoxConverter()  BottleBox? labelBbox, @JsonKey(name: 'select_roi')@BottleBoxConverter()  BottleBox? selectRoi,  String? selectable,  bool primary,  bool addressed, @JsonKey(unknownEnumValue: ScanDecision.other)  ScanDecision decision, @JsonKey(name: 'decision_text')  String? decisionText,  List<String> reasons,  WineCard? best,  List<WineCard> alternatives)  $default,) {final _that = this;
switch (_that) {
case _RecognizedBottle():
return $default(_that.number,_that.instanceId,_that.geometry,_that.labelBbox,_that.selectRoi,_that.selectable,_that.primary,_that.addressed,_that.decision,_that.decisionText,_that.reasons,_that.best,_that.alternatives);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number, @JsonKey(name: 'instance_id')  String instanceId, @BottleBoxConverter()  BottleBox? geometry, @JsonKey(name: 'label_bbox')@BottleBoxConverter()  BottleBox? labelBbox, @JsonKey(name: 'select_roi')@BottleBoxConverter()  BottleBox? selectRoi,  String? selectable,  bool primary,  bool addressed, @JsonKey(unknownEnumValue: ScanDecision.other)  ScanDecision decision, @JsonKey(name: 'decision_text')  String? decisionText,  List<String> reasons,  WineCard? best,  List<WineCard> alternatives)?  $default,) {final _that = this;
switch (_that) {
case _RecognizedBottle() when $default != null:
return $default(_that.number,_that.instanceId,_that.geometry,_that.labelBbox,_that.selectRoi,_that.selectable,_that.primary,_that.addressed,_that.decision,_that.decisionText,_that.reasons,_that.best,_that.alternatives);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecognizedBottle implements RecognizedBottle {
  const _RecognizedBottle({required this.number, @JsonKey(name: 'instance_id') required this.instanceId, @BottleBoxConverter() this.geometry, @JsonKey(name: 'label_bbox')@BottleBoxConverter() this.labelBbox, @JsonKey(name: 'select_roi')@BottleBoxConverter() this.selectRoi, this.selectable, this.primary = false, this.addressed = false, @JsonKey(unknownEnumValue: ScanDecision.other) this.decision = ScanDecision.other, @JsonKey(name: 'decision_text') this.decisionText, final  List<String> reasons = const <String>[], this.best, final  List<WineCard> alternatives = const <WineCard>[]}): _reasons = reasons,_alternatives = alternatives;
  factory _RecognizedBottle.fromJson(Map<String, dynamic> json) => _$RecognizedBottleFromJson(json);

@override final  int number;
@override@JsonKey(name: 'instance_id') final  String instanceId;
@override@BottleBoxConverter() final  BottleBox? geometry;
@override@JsonKey(name: 'label_bbox')@BottleBoxConverter() final  BottleBox? labelBbox;
@override@JsonKey(name: 'select_roi')@BottleBoxConverter() final  BottleBox? selectRoi;
@override final  String? selectable;
@override@JsonKey() final  bool primary;
@override@JsonKey() final  bool addressed;
@override@JsonKey(unknownEnumValue: ScanDecision.other) final  ScanDecision decision;
@override@JsonKey(name: 'decision_text') final  String? decisionText;
 final  List<String> _reasons;
@override@JsonKey() List<String> get reasons {
  if (_reasons is EqualUnmodifiableListView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reasons);
}

@override final  WineCard? best;
 final  List<WineCard> _alternatives;
@override@JsonKey() List<WineCard> get alternatives {
  if (_alternatives is EqualUnmodifiableListView) return _alternatives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alternatives);
}


/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecognizedBottleCopyWith<_RecognizedBottle> get copyWith => __$RecognizedBottleCopyWithImpl<_RecognizedBottle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecognizedBottleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecognizedBottle&&(identical(other.number, number) || other.number == number)&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&(identical(other.geometry, geometry) || other.geometry == geometry)&&(identical(other.labelBbox, labelBbox) || other.labelBbox == labelBbox)&&(identical(other.selectRoi, selectRoi) || other.selectRoi == selectRoi)&&(identical(other.selectable, selectable) || other.selectable == selectable)&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.addressed, addressed) || other.addressed == addressed)&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.decisionText, decisionText) || other.decisionText == decisionText)&&const DeepCollectionEquality().equals(other._reasons, _reasons)&&(identical(other.best, best) || other.best == best)&&const DeepCollectionEquality().equals(other._alternatives, _alternatives));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,instanceId,geometry,labelBbox,selectRoi,selectable,primary,addressed,decision,decisionText,const DeepCollectionEquality().hash(_reasons),best,const DeepCollectionEquality().hash(_alternatives));

@override
String toString() {
  return 'RecognizedBottle(number: $number, instanceId: $instanceId, geometry: $geometry, labelBbox: $labelBbox, selectRoi: $selectRoi, selectable: $selectable, primary: $primary, addressed: $addressed, decision: $decision, decisionText: $decisionText, reasons: $reasons, best: $best, alternatives: $alternatives)';
}


}

/// @nodoc
abstract mixin class _$RecognizedBottleCopyWith<$Res> implements $RecognizedBottleCopyWith<$Res> {
  factory _$RecognizedBottleCopyWith(_RecognizedBottle value, $Res Function(_RecognizedBottle) _then) = __$RecognizedBottleCopyWithImpl;
@override @useResult
$Res call({
 int number,@JsonKey(name: 'instance_id') String instanceId,@BottleBoxConverter() BottleBox? geometry,@JsonKey(name: 'label_bbox')@BottleBoxConverter() BottleBox? labelBbox,@JsonKey(name: 'select_roi')@BottleBoxConverter() BottleBox? selectRoi, String? selectable, bool primary, bool addressed,@JsonKey(unknownEnumValue: ScanDecision.other) ScanDecision decision,@JsonKey(name: 'decision_text') String? decisionText, List<String> reasons, WineCard? best, List<WineCard> alternatives
});


@override $BottleBoxCopyWith<$Res>? get geometry;@override $BottleBoxCopyWith<$Res>? get labelBbox;@override $BottleBoxCopyWith<$Res>? get selectRoi;@override $WineCardCopyWith<$Res>? get best;

}
/// @nodoc
class __$RecognizedBottleCopyWithImpl<$Res>
    implements _$RecognizedBottleCopyWith<$Res> {
  __$RecognizedBottleCopyWithImpl(this._self, this._then);

  final _RecognizedBottle _self;
  final $Res Function(_RecognizedBottle) _then;

/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? instanceId = null,Object? geometry = freezed,Object? labelBbox = freezed,Object? selectRoi = freezed,Object? selectable = freezed,Object? primary = null,Object? addressed = null,Object? decision = null,Object? decisionText = freezed,Object? reasons = null,Object? best = freezed,Object? alternatives = null,}) {
  return _then(_RecognizedBottle(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as String,geometry: freezed == geometry ? _self.geometry : geometry // ignore: cast_nullable_to_non_nullable
as BottleBox?,labelBbox: freezed == labelBbox ? _self.labelBbox : labelBbox // ignore: cast_nullable_to_non_nullable
as BottleBox?,selectRoi: freezed == selectRoi ? _self.selectRoi : selectRoi // ignore: cast_nullable_to_non_nullable
as BottleBox?,selectable: freezed == selectable ? _self.selectable : selectable // ignore: cast_nullable_to_non_nullable
as String?,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as bool,addressed: null == addressed ? _self.addressed : addressed // ignore: cast_nullable_to_non_nullable
as bool,decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as ScanDecision,decisionText: freezed == decisionText ? _self.decisionText : decisionText // ignore: cast_nullable_to_non_nullable
as String?,reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,best: freezed == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as WineCard?,alternatives: null == alternatives ? _self._alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<WineCard>,
  ));
}

/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get geometry {
    if (_self.geometry == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.geometry!, (value) {
    return _then(_self.copyWith(geometry: value));
  });
}/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get labelBbox {
    if (_self.labelBbox == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.labelBbox!, (value) {
    return _then(_self.copyWith(labelBbox: value));
  });
}/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get selectRoi {
    if (_self.selectRoi == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.selectRoi!, (value) {
    return _then(_self.copyWith(selectRoi: value));
  });
}/// Create a copy of RecognizedBottle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WineCardCopyWith<$Res>? get best {
    if (_self.best == null) {
    return null;
  }

  return $WineCardCopyWith<$Res>(_self.best!, (value) {
    return _then(_self.copyWith(best: value));
  });
}
}


/// @nodoc
mixin _$ImageInfo {

 String? get format; String? get mime; List<int>? get size; int? get bytes;
/// Create a copy of ImageInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageInfoCopyWith<ImageInfo> get copyWith => _$ImageInfoCopyWithImpl<ImageInfo>(this as ImageInfo, _$identity);

  /// Serializes this ImageInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageInfo&&(identical(other.format, format) || other.format == format)&&(identical(other.mime, mime) || other.mime == mime)&&const DeepCollectionEquality().equals(other.size, size)&&(identical(other.bytes, bytes) || other.bytes == bytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,format,mime,const DeepCollectionEquality().hash(size),bytes);

@override
String toString() {
  return 'ImageInfo(format: $format, mime: $mime, size: $size, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $ImageInfoCopyWith<$Res>  {
  factory $ImageInfoCopyWith(ImageInfo value, $Res Function(ImageInfo) _then) = _$ImageInfoCopyWithImpl;
@useResult
$Res call({
 String? format, String? mime, List<int>? size, int? bytes
});




}
/// @nodoc
class _$ImageInfoCopyWithImpl<$Res>
    implements $ImageInfoCopyWith<$Res> {
  _$ImageInfoCopyWithImpl(this._self, this._then);

  final ImageInfo _self;
  final $Res Function(ImageInfo) _then;

/// Create a copy of ImageInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? format = freezed,Object? mime = freezed,Object? size = freezed,Object? bytes = freezed,}) {
  return _then(_self.copyWith(
format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as List<int>?,bytes: freezed == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageInfo].
extension ImageInfoPatterns on ImageInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageInfo value)  $default,){
final _that = this;
switch (_that) {
case _ImageInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ImageInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? format,  String? mime,  List<int>? size,  int? bytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageInfo() when $default != null:
return $default(_that.format,_that.mime,_that.size,_that.bytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? format,  String? mime,  List<int>? size,  int? bytes)  $default,) {final _that = this;
switch (_that) {
case _ImageInfo():
return $default(_that.format,_that.mime,_that.size,_that.bytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? format,  String? mime,  List<int>? size,  int? bytes)?  $default,) {final _that = this;
switch (_that) {
case _ImageInfo() when $default != null:
return $default(_that.format,_that.mime,_that.size,_that.bytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImageInfo implements ImageInfo {
  const _ImageInfo({this.format, this.mime, final  List<int>? size, this.bytes}): _size = size;
  factory _ImageInfo.fromJson(Map<String, dynamic> json) => _$ImageInfoFromJson(json);

@override final  String? format;
@override final  String? mime;
 final  List<int>? _size;
@override List<int>? get size {
  final value = _size;
  if (value == null) return null;
  if (_size is EqualUnmodifiableListView) return _size;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? bytes;

/// Create a copy of ImageInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageInfoCopyWith<_ImageInfo> get copyWith => __$ImageInfoCopyWithImpl<_ImageInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageInfo&&(identical(other.format, format) || other.format == format)&&(identical(other.mime, mime) || other.mime == mime)&&const DeepCollectionEquality().equals(other._size, _size)&&(identical(other.bytes, bytes) || other.bytes == bytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,format,mime,const DeepCollectionEquality().hash(_size),bytes);

@override
String toString() {
  return 'ImageInfo(format: $format, mime: $mime, size: $size, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class _$ImageInfoCopyWith<$Res> implements $ImageInfoCopyWith<$Res> {
  factory _$ImageInfoCopyWith(_ImageInfo value, $Res Function(_ImageInfo) _then) = __$ImageInfoCopyWithImpl;
@override @useResult
$Res call({
 String? format, String? mime, List<int>? size, int? bytes
});




}
/// @nodoc
class __$ImageInfoCopyWithImpl<$Res>
    implements _$ImageInfoCopyWith<$Res> {
  __$ImageInfoCopyWithImpl(this._self, this._then);

  final _ImageInfo _self;
  final $Res Function(_ImageInfo) _then;

/// Create a copy of ImageInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? format = freezed,Object? mime = freezed,Object? size = freezed,Object? bytes = freezed,}) {
  return _then(_ImageInfo(
format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self._size : size // ignore: cast_nullable_to_non_nullable
as List<int>?,bytes: freezed == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
