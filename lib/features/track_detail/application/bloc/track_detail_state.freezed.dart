// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackDetailState {

 ScreenStatus get screenStatus; Track? get track;
/// Create a copy of TrackDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackDetailStateCopyWith<TrackDetailState> get copyWith => _$TrackDetailStateCopyWithImpl<TrackDetailState>(this as TrackDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackDetailState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.track, track) || other.track == track));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,track);

@override
String toString() {
  return 'TrackDetailState(screenStatus: $screenStatus, track: $track)';
}


}

/// @nodoc
abstract mixin class $TrackDetailStateCopyWith<$Res>  {
  factory $TrackDetailStateCopyWith(TrackDetailState value, $Res Function(TrackDetailState) _then) = _$TrackDetailStateCopyWithImpl;
@useResult
$Res call({
 ScreenStatus screenStatus, Track? track
});




}
/// @nodoc
class _$TrackDetailStateCopyWithImpl<$Res>
    implements $TrackDetailStateCopyWith<$Res> {
  _$TrackDetailStateCopyWithImpl(this._self, this._then);

  final TrackDetailState _self;
  final $Res Function(TrackDetailState) _then;

/// Create a copy of TrackDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenStatus = null,Object? track = freezed,}) {
  return _then(_self.copyWith(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as Track?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackDetailState].
extension TrackDetailStatePatterns on TrackDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackDetailState value)  $default,){
final _that = this;
switch (_that) {
case _TrackDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _TrackDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  Track? track)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackDetailState() when $default != null:
return $default(_that.screenStatus,_that.track);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  Track? track)  $default,) {final _that = this;
switch (_that) {
case _TrackDetailState():
return $default(_that.screenStatus,_that.track);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScreenStatus screenStatus,  Track? track)?  $default,) {final _that = this;
switch (_that) {
case _TrackDetailState() when $default != null:
return $default(_that.screenStatus,_that.track);case _:
  return null;

}
}

}

/// @nodoc


class _TrackDetailState implements TrackDetailState {
  const _TrackDetailState({required this.screenStatus, required this.track});
  

@override final  ScreenStatus screenStatus;
@override final  Track? track;

/// Create a copy of TrackDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackDetailStateCopyWith<_TrackDetailState> get copyWith => __$TrackDetailStateCopyWithImpl<_TrackDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackDetailState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.track, track) || other.track == track));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,track);

@override
String toString() {
  return 'TrackDetailState(screenStatus: $screenStatus, track: $track)';
}


}

/// @nodoc
abstract mixin class _$TrackDetailStateCopyWith<$Res> implements $TrackDetailStateCopyWith<$Res> {
  factory _$TrackDetailStateCopyWith(_TrackDetailState value, $Res Function(_TrackDetailState) _then) = __$TrackDetailStateCopyWithImpl;
@override @useResult
$Res call({
 ScreenStatus screenStatus, Track? track
});




}
/// @nodoc
class __$TrackDetailStateCopyWithImpl<$Res>
    implements _$TrackDetailStateCopyWith<$Res> {
  __$TrackDetailStateCopyWithImpl(this._self, this._then);

  final _TrackDetailState _self;
  final $Res Function(_TrackDetailState) _then;

/// Create a copy of TrackDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenStatus = null,Object? track = freezed,}) {
  return _then(_TrackDetailState(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as Track?,
  ));
}


}

// dart format on
