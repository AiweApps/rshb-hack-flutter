// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {

 ScreenStatus get screenStatus; ErrorType? get errorType; AppThemeMode get themeMode; String get languageCode; ServiceState get serviceState;/// Size of the wine catalogue on the server, when the status told it.
 int? get catalogCards;/// Pull-to-refresh of the service status is in flight.
 bool get isRefreshing;/// The history is being wiped; a second confirm is ignored meanwhile.
 bool get isClearingHistory;/// "1.0.0" and "12" from the package info, once read.
 String? get version; String? get buildNumber;
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateCopyWith<SettingsState> get copyWith => _$SettingsStateCopyWithImpl<SettingsState>(this as SettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.serviceState, serviceState) || other.serviceState == serviceState)&&(identical(other.catalogCards, catalogCards) || other.catalogCards == catalogCards)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isClearingHistory, isClearingHistory) || other.isClearingHistory == isClearingHistory)&&(identical(other.version, version) || other.version == version)&&(identical(other.buildNumber, buildNumber) || other.buildNumber == buildNumber));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,errorType,themeMode,languageCode,serviceState,catalogCards,isRefreshing,isClearingHistory,version,buildNumber);

@override
String toString() {
  return 'SettingsState(screenStatus: $screenStatus, errorType: $errorType, themeMode: $themeMode, languageCode: $languageCode, serviceState: $serviceState, catalogCards: $catalogCards, isRefreshing: $isRefreshing, isClearingHistory: $isClearingHistory, version: $version, buildNumber: $buildNumber)';
}


}

/// @nodoc
abstract mixin class $SettingsStateCopyWith<$Res>  {
  factory $SettingsStateCopyWith(SettingsState value, $Res Function(SettingsState) _then) = _$SettingsStateCopyWithImpl;
@useResult
$Res call({
 ScreenStatus screenStatus, ErrorType? errorType, AppThemeMode themeMode, String languageCode, ServiceState serviceState, int? catalogCards, bool isRefreshing, bool isClearingHistory, String? version, String? buildNumber
});




}
/// @nodoc
class _$SettingsStateCopyWithImpl<$Res>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._self, this._then);

  final SettingsState _self;
  final $Res Function(SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenStatus = null,Object? errorType = freezed,Object? themeMode = null,Object? languageCode = null,Object? serviceState = null,Object? catalogCards = freezed,Object? isRefreshing = null,Object? isClearingHistory = null,Object? version = freezed,Object? buildNumber = freezed,}) {
  return _then(_self.copyWith(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,errorType: freezed == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as ErrorType?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,serviceState: null == serviceState ? _self.serviceState : serviceState // ignore: cast_nullable_to_non_nullable
as ServiceState,catalogCards: freezed == catalogCards ? _self.catalogCards : catalogCards // ignore: cast_nullable_to_non_nullable
as int?,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isClearingHistory: null == isClearingHistory ? _self.isClearingHistory : isClearingHistory // ignore: cast_nullable_to_non_nullable
as bool,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,buildNumber: freezed == buildNumber ? _self.buildNumber : buildNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsState value)  $default,){
final _that = this;
switch (_that) {
case _SettingsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  ErrorType? errorType,  AppThemeMode themeMode,  String languageCode,  ServiceState serviceState,  int? catalogCards,  bool isRefreshing,  bool isClearingHistory,  String? version,  String? buildNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.screenStatus,_that.errorType,_that.themeMode,_that.languageCode,_that.serviceState,_that.catalogCards,_that.isRefreshing,_that.isClearingHistory,_that.version,_that.buildNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  ErrorType? errorType,  AppThemeMode themeMode,  String languageCode,  ServiceState serviceState,  int? catalogCards,  bool isRefreshing,  bool isClearingHistory,  String? version,  String? buildNumber)  $default,) {final _that = this;
switch (_that) {
case _SettingsState():
return $default(_that.screenStatus,_that.errorType,_that.themeMode,_that.languageCode,_that.serviceState,_that.catalogCards,_that.isRefreshing,_that.isClearingHistory,_that.version,_that.buildNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScreenStatus screenStatus,  ErrorType? errorType,  AppThemeMode themeMode,  String languageCode,  ServiceState serviceState,  int? catalogCards,  bool isRefreshing,  bool isClearingHistory,  String? version,  String? buildNumber)?  $default,) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.screenStatus,_that.errorType,_that.themeMode,_that.languageCode,_that.serviceState,_that.catalogCards,_that.isRefreshing,_that.isClearingHistory,_that.version,_that.buildNumber);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsState implements SettingsState {
  const _SettingsState({required this.screenStatus, required this.errorType, required this.themeMode, required this.languageCode, required this.serviceState, required this.catalogCards, required this.isRefreshing, required this.isClearingHistory, required this.version, required this.buildNumber});
  

@override final  ScreenStatus screenStatus;
@override final  ErrorType? errorType;
@override final  AppThemeMode themeMode;
@override final  String languageCode;
@override final  ServiceState serviceState;
/// Size of the wine catalogue on the server, when the status told it.
@override final  int? catalogCards;
/// Pull-to-refresh of the service status is in flight.
@override final  bool isRefreshing;
/// The history is being wiped; a second confirm is ignored meanwhile.
@override final  bool isClearingHistory;
/// "1.0.0" and "12" from the package info, once read.
@override final  String? version;
@override final  String? buildNumber;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsStateCopyWith<_SettingsState> get copyWith => __$SettingsStateCopyWithImpl<_SettingsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.serviceState, serviceState) || other.serviceState == serviceState)&&(identical(other.catalogCards, catalogCards) || other.catalogCards == catalogCards)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isClearingHistory, isClearingHistory) || other.isClearingHistory == isClearingHistory)&&(identical(other.version, version) || other.version == version)&&(identical(other.buildNumber, buildNumber) || other.buildNumber == buildNumber));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,errorType,themeMode,languageCode,serviceState,catalogCards,isRefreshing,isClearingHistory,version,buildNumber);

@override
String toString() {
  return 'SettingsState(screenStatus: $screenStatus, errorType: $errorType, themeMode: $themeMode, languageCode: $languageCode, serviceState: $serviceState, catalogCards: $catalogCards, isRefreshing: $isRefreshing, isClearingHistory: $isClearingHistory, version: $version, buildNumber: $buildNumber)';
}


}

/// @nodoc
abstract mixin class _$SettingsStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory _$SettingsStateCopyWith(_SettingsState value, $Res Function(_SettingsState) _then) = __$SettingsStateCopyWithImpl;
@override @useResult
$Res call({
 ScreenStatus screenStatus, ErrorType? errorType, AppThemeMode themeMode, String languageCode, ServiceState serviceState, int? catalogCards, bool isRefreshing, bool isClearingHistory, String? version, String? buildNumber
});




}
/// @nodoc
class __$SettingsStateCopyWithImpl<$Res>
    implements _$SettingsStateCopyWith<$Res> {
  __$SettingsStateCopyWithImpl(this._self, this._then);

  final _SettingsState _self;
  final $Res Function(_SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenStatus = null,Object? errorType = freezed,Object? themeMode = null,Object? languageCode = null,Object? serviceState = null,Object? catalogCards = freezed,Object? isRefreshing = null,Object? isClearingHistory = null,Object? version = freezed,Object? buildNumber = freezed,}) {
  return _then(_SettingsState(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,errorType: freezed == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as ErrorType?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,languageCode: null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,serviceState: null == serviceState ? _self.serviceState : serviceState // ignore: cast_nullable_to_non_nullable
as ServiceState,catalogCards: freezed == catalogCards ? _self.catalogCards : catalogCards // ignore: cast_nullable_to_non_nullable
as int?,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isClearingHistory: null == isClearingHistory ? _self.isClearingHistory : isClearingHistory // ignore: cast_nullable_to_non_nullable
as bool,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,buildNumber: freezed == buildNumber ? _self.buildNumber : buildNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
