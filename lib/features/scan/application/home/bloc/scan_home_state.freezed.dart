// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScanHomeState {

 ScreenStatus get screenStatus; ErrorType? get errorType;/// The live preview itself is not here: `CameraService.preview` feeds
/// the widget, this only says which view the tab shows.
 CameraStatus get cameraStatus; bool get isFlashOn; bool get isCapturing; ServiceState get serviceState;/// Shown while the camera is not available, so the tab is not empty.
 List<ScanHistoryItem> get recent;/// The system picker is open; the buttons are disabled meanwhile.
 bool get isPicking;
/// Create a copy of ScanHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanHomeStateCopyWith<ScanHomeState> get copyWith => _$ScanHomeStateCopyWithImpl<ScanHomeState>(this as ScanHomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanHomeState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.cameraStatus, cameraStatus) || other.cameraStatus == cameraStatus)&&(identical(other.isFlashOn, isFlashOn) || other.isFlashOn == isFlashOn)&&(identical(other.isCapturing, isCapturing) || other.isCapturing == isCapturing)&&(identical(other.serviceState, serviceState) || other.serviceState == serviceState)&&const DeepCollectionEquality().equals(other.recent, recent)&&(identical(other.isPicking, isPicking) || other.isPicking == isPicking));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,errorType,cameraStatus,isFlashOn,isCapturing,serviceState,const DeepCollectionEquality().hash(recent),isPicking);

@override
String toString() {
  return 'ScanHomeState(screenStatus: $screenStatus, errorType: $errorType, cameraStatus: $cameraStatus, isFlashOn: $isFlashOn, isCapturing: $isCapturing, serviceState: $serviceState, recent: $recent, isPicking: $isPicking)';
}


}

/// @nodoc
abstract mixin class $ScanHomeStateCopyWith<$Res>  {
  factory $ScanHomeStateCopyWith(ScanHomeState value, $Res Function(ScanHomeState) _then) = _$ScanHomeStateCopyWithImpl;
@useResult
$Res call({
 ScreenStatus screenStatus, ErrorType? errorType, CameraStatus cameraStatus, bool isFlashOn, bool isCapturing, ServiceState serviceState, List<ScanHistoryItem> recent, bool isPicking
});




}
/// @nodoc
class _$ScanHomeStateCopyWithImpl<$Res>
    implements $ScanHomeStateCopyWith<$Res> {
  _$ScanHomeStateCopyWithImpl(this._self, this._then);

  final ScanHomeState _self;
  final $Res Function(ScanHomeState) _then;

/// Create a copy of ScanHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenStatus = null,Object? errorType = freezed,Object? cameraStatus = null,Object? isFlashOn = null,Object? isCapturing = null,Object? serviceState = null,Object? recent = null,Object? isPicking = null,}) {
  return _then(_self.copyWith(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,errorType: freezed == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as ErrorType?,cameraStatus: null == cameraStatus ? _self.cameraStatus : cameraStatus // ignore: cast_nullable_to_non_nullable
as CameraStatus,isFlashOn: null == isFlashOn ? _self.isFlashOn : isFlashOn // ignore: cast_nullable_to_non_nullable
as bool,isCapturing: null == isCapturing ? _self.isCapturing : isCapturing // ignore: cast_nullable_to_non_nullable
as bool,serviceState: null == serviceState ? _self.serviceState : serviceState // ignore: cast_nullable_to_non_nullable
as ServiceState,recent: null == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as List<ScanHistoryItem>,isPicking: null == isPicking ? _self.isPicking : isPicking // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanHomeState].
extension ScanHomeStatePatterns on ScanHomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanHomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanHomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanHomeState value)  $default,){
final _that = this;
switch (_that) {
case _ScanHomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanHomeState value)?  $default,){
final _that = this;
switch (_that) {
case _ScanHomeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  ErrorType? errorType,  CameraStatus cameraStatus,  bool isFlashOn,  bool isCapturing,  ServiceState serviceState,  List<ScanHistoryItem> recent,  bool isPicking)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanHomeState() when $default != null:
return $default(_that.screenStatus,_that.errorType,_that.cameraStatus,_that.isFlashOn,_that.isCapturing,_that.serviceState,_that.recent,_that.isPicking);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  ErrorType? errorType,  CameraStatus cameraStatus,  bool isFlashOn,  bool isCapturing,  ServiceState serviceState,  List<ScanHistoryItem> recent,  bool isPicking)  $default,) {final _that = this;
switch (_that) {
case _ScanHomeState():
return $default(_that.screenStatus,_that.errorType,_that.cameraStatus,_that.isFlashOn,_that.isCapturing,_that.serviceState,_that.recent,_that.isPicking);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScreenStatus screenStatus,  ErrorType? errorType,  CameraStatus cameraStatus,  bool isFlashOn,  bool isCapturing,  ServiceState serviceState,  List<ScanHistoryItem> recent,  bool isPicking)?  $default,) {final _that = this;
switch (_that) {
case _ScanHomeState() when $default != null:
return $default(_that.screenStatus,_that.errorType,_that.cameraStatus,_that.isFlashOn,_that.isCapturing,_that.serviceState,_that.recent,_that.isPicking);case _:
  return null;

}
}

}

/// @nodoc


class _ScanHomeState implements ScanHomeState {
  const _ScanHomeState({required this.screenStatus, required this.errorType, required this.cameraStatus, required this.isFlashOn, required this.isCapturing, required this.serviceState, required final  List<ScanHistoryItem> recent, required this.isPicking}): _recent = recent;
  

@override final  ScreenStatus screenStatus;
@override final  ErrorType? errorType;
/// The live preview itself is not here: `CameraService.preview` feeds
/// the widget, this only says which view the tab shows.
@override final  CameraStatus cameraStatus;
@override final  bool isFlashOn;
@override final  bool isCapturing;
@override final  ServiceState serviceState;
/// Shown while the camera is not available, so the tab is not empty.
 final  List<ScanHistoryItem> _recent;
/// Shown while the camera is not available, so the tab is not empty.
@override List<ScanHistoryItem> get recent {
  if (_recent is EqualUnmodifiableListView) return _recent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recent);
}

/// The system picker is open; the buttons are disabled meanwhile.
@override final  bool isPicking;

/// Create a copy of ScanHomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanHomeStateCopyWith<_ScanHomeState> get copyWith => __$ScanHomeStateCopyWithImpl<_ScanHomeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanHomeState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.cameraStatus, cameraStatus) || other.cameraStatus == cameraStatus)&&(identical(other.isFlashOn, isFlashOn) || other.isFlashOn == isFlashOn)&&(identical(other.isCapturing, isCapturing) || other.isCapturing == isCapturing)&&(identical(other.serviceState, serviceState) || other.serviceState == serviceState)&&const DeepCollectionEquality().equals(other._recent, _recent)&&(identical(other.isPicking, isPicking) || other.isPicking == isPicking));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,errorType,cameraStatus,isFlashOn,isCapturing,serviceState,const DeepCollectionEquality().hash(_recent),isPicking);

@override
String toString() {
  return 'ScanHomeState(screenStatus: $screenStatus, errorType: $errorType, cameraStatus: $cameraStatus, isFlashOn: $isFlashOn, isCapturing: $isCapturing, serviceState: $serviceState, recent: $recent, isPicking: $isPicking)';
}


}

/// @nodoc
abstract mixin class _$ScanHomeStateCopyWith<$Res> implements $ScanHomeStateCopyWith<$Res> {
  factory _$ScanHomeStateCopyWith(_ScanHomeState value, $Res Function(_ScanHomeState) _then) = __$ScanHomeStateCopyWithImpl;
@override @useResult
$Res call({
 ScreenStatus screenStatus, ErrorType? errorType, CameraStatus cameraStatus, bool isFlashOn, bool isCapturing, ServiceState serviceState, List<ScanHistoryItem> recent, bool isPicking
});




}
/// @nodoc
class __$ScanHomeStateCopyWithImpl<$Res>
    implements _$ScanHomeStateCopyWith<$Res> {
  __$ScanHomeStateCopyWithImpl(this._self, this._then);

  final _ScanHomeState _self;
  final $Res Function(_ScanHomeState) _then;

/// Create a copy of ScanHomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenStatus = null,Object? errorType = freezed,Object? cameraStatus = null,Object? isFlashOn = null,Object? isCapturing = null,Object? serviceState = null,Object? recent = null,Object? isPicking = null,}) {
  return _then(_ScanHomeState(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,errorType: freezed == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as ErrorType?,cameraStatus: null == cameraStatus ? _self.cameraStatus : cameraStatus // ignore: cast_nullable_to_non_nullable
as CameraStatus,isFlashOn: null == isFlashOn ? _self.isFlashOn : isFlashOn // ignore: cast_nullable_to_non_nullable
as bool,isCapturing: null == isCapturing ? _self.isCapturing : isCapturing // ignore: cast_nullable_to_non_nullable
as bool,serviceState: null == serviceState ? _self.serviceState : serviceState // ignore: cast_nullable_to_non_nullable
as ServiceState,recent: null == recent ? _self._recent : recent // ignore: cast_nullable_to_non_nullable
as List<ScanHistoryItem>,isPicking: null == isPicking ? _self.isPicking : isPicking // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
