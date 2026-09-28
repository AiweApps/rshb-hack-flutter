// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScanFailure {

 ScanFailureKind get kind; int? get statusCode;/// Whether "retry" makes sense: a rejected file or frame will be
/// rejected again, a busy service will not.
 bool get retryable;
/// Create a copy of ScanFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanFailureCopyWith<ScanFailure> get copyWith => _$ScanFailureCopyWithImpl<ScanFailure>(this as ScanFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanFailure&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.retryable, retryable) || other.retryable == retryable));
}


@override
int get hashCode => Object.hash(runtimeType,kind,statusCode,retryable);

@override
String toString() {
  return 'ScanFailure(kind: $kind, statusCode: $statusCode, retryable: $retryable)';
}


}

/// @nodoc
abstract mixin class $ScanFailureCopyWith<$Res>  {
  factory $ScanFailureCopyWith(ScanFailure value, $Res Function(ScanFailure) _then) = _$ScanFailureCopyWithImpl;
@useResult
$Res call({
 ScanFailureKind kind, int? statusCode, bool retryable
});




}
/// @nodoc
class _$ScanFailureCopyWithImpl<$Res>
    implements $ScanFailureCopyWith<$Res> {
  _$ScanFailureCopyWithImpl(this._self, this._then);

  final ScanFailure _self;
  final $Res Function(ScanFailure) _then;

/// Create a copy of ScanFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? statusCode = freezed,Object? retryable = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ScanFailureKind,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,retryable: null == retryable ? _self.retryable : retryable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanFailure].
extension ScanFailurePatterns on ScanFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanFailure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanFailure() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanFailure value)  $default,){
final _that = this;
switch (_that) {
case _ScanFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanFailure value)?  $default,){
final _that = this;
switch (_that) {
case _ScanFailure() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScanFailureKind kind,  int? statusCode,  bool retryable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanFailure() when $default != null:
return $default(_that.kind,_that.statusCode,_that.retryable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScanFailureKind kind,  int? statusCode,  bool retryable)  $default,) {final _that = this;
switch (_that) {
case _ScanFailure():
return $default(_that.kind,_that.statusCode,_that.retryable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScanFailureKind kind,  int? statusCode,  bool retryable)?  $default,) {final _that = this;
switch (_that) {
case _ScanFailure() when $default != null:
return $default(_that.kind,_that.statusCode,_that.retryable);case _:
  return null;

}
}

}

/// @nodoc


class _ScanFailure implements ScanFailure {
  const _ScanFailure({required this.kind, required this.statusCode, required this.retryable});
  

@override final  ScanFailureKind kind;
@override final  int? statusCode;
/// Whether "retry" makes sense: a rejected file or frame will be
/// rejected again, a busy service will not.
@override final  bool retryable;

/// Create a copy of ScanFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanFailureCopyWith<_ScanFailure> get copyWith => __$ScanFailureCopyWithImpl<_ScanFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanFailure&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.retryable, retryable) || other.retryable == retryable));
}


@override
int get hashCode => Object.hash(runtimeType,kind,statusCode,retryable);

@override
String toString() {
  return 'ScanFailure(kind: $kind, statusCode: $statusCode, retryable: $retryable)';
}


}

/// @nodoc
abstract mixin class _$ScanFailureCopyWith<$Res> implements $ScanFailureCopyWith<$Res> {
  factory _$ScanFailureCopyWith(_ScanFailure value, $Res Function(_ScanFailure) _then) = __$ScanFailureCopyWithImpl;
@override @useResult
$Res call({
 ScanFailureKind kind, int? statusCode, bool retryable
});




}
/// @nodoc
class __$ScanFailureCopyWithImpl<$Res>
    implements _$ScanFailureCopyWith<$Res> {
  __$ScanFailureCopyWithImpl(this._self, this._then);

  final _ScanFailure _self;
  final $Res Function(_ScanFailure) _then;

/// Create a copy of ScanFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? statusCode = freezed,Object? retryable = null,}) {
  return _then(_ScanFailure(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ScanFailureKind,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,retryable: null == retryable ? _self.retryable : retryable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
