// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bottle_box.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BottleBox {

 double get x1; double get y1; double get x2; double get y2;
/// Create a copy of BottleBox
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<BottleBox> get copyWith => _$BottleBoxCopyWithImpl<BottleBox>(this as BottleBox, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BottleBox&&(identical(other.x1, x1) || other.x1 == x1)&&(identical(other.y1, y1) || other.y1 == y1)&&(identical(other.x2, x2) || other.x2 == x2)&&(identical(other.y2, y2) || other.y2 == y2));
}


@override
int get hashCode => Object.hash(runtimeType,x1,y1,x2,y2);

@override
String toString() {
  return 'BottleBox(x1: $x1, y1: $y1, x2: $x2, y2: $y2)';
}


}

/// @nodoc
abstract mixin class $BottleBoxCopyWith<$Res>  {
  factory $BottleBoxCopyWith(BottleBox value, $Res Function(BottleBox) _then) = _$BottleBoxCopyWithImpl;
@useResult
$Res call({
 double x1, double y1, double x2, double y2
});




}
/// @nodoc
class _$BottleBoxCopyWithImpl<$Res>
    implements $BottleBoxCopyWith<$Res> {
  _$BottleBoxCopyWithImpl(this._self, this._then);

  final BottleBox _self;
  final $Res Function(BottleBox) _then;

/// Create a copy of BottleBox
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x1 = null,Object? y1 = null,Object? x2 = null,Object? y2 = null,}) {
  return _then(_self.copyWith(
x1: null == x1 ? _self.x1 : x1 // ignore: cast_nullable_to_non_nullable
as double,y1: null == y1 ? _self.y1 : y1 // ignore: cast_nullable_to_non_nullable
as double,x2: null == x2 ? _self.x2 : x2 // ignore: cast_nullable_to_non_nullable
as double,y2: null == y2 ? _self.y2 : y2 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BottleBox].
extension BottleBoxPatterns on BottleBox {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BottleBox value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BottleBox() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BottleBox value)  $default,){
final _that = this;
switch (_that) {
case _BottleBox():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BottleBox value)?  $default,){
final _that = this;
switch (_that) {
case _BottleBox() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x1,  double y1,  double x2,  double y2)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BottleBox() when $default != null:
return $default(_that.x1,_that.y1,_that.x2,_that.y2);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x1,  double y1,  double x2,  double y2)  $default,) {final _that = this;
switch (_that) {
case _BottleBox():
return $default(_that.x1,_that.y1,_that.x2,_that.y2);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x1,  double y1,  double x2,  double y2)?  $default,) {final _that = this;
switch (_that) {
case _BottleBox() when $default != null:
return $default(_that.x1,_that.y1,_that.x2,_that.y2);case _:
  return null;

}
}

}

/// @nodoc


class _BottleBox extends BottleBox {
  const _BottleBox({required this.x1, required this.y1, required this.x2, required this.y2}): super._();
  

@override final  double x1;
@override final  double y1;
@override final  double x2;
@override final  double y2;

/// Create a copy of BottleBox
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BottleBoxCopyWith<_BottleBox> get copyWith => __$BottleBoxCopyWithImpl<_BottleBox>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BottleBox&&(identical(other.x1, x1) || other.x1 == x1)&&(identical(other.y1, y1) || other.y1 == y1)&&(identical(other.x2, x2) || other.x2 == x2)&&(identical(other.y2, y2) || other.y2 == y2));
}


@override
int get hashCode => Object.hash(runtimeType,x1,y1,x2,y2);

@override
String toString() {
  return 'BottleBox(x1: $x1, y1: $y1, x2: $x2, y2: $y2)';
}


}

/// @nodoc
abstract mixin class _$BottleBoxCopyWith<$Res> implements $BottleBoxCopyWith<$Res> {
  factory _$BottleBoxCopyWith(_BottleBox value, $Res Function(_BottleBox) _then) = __$BottleBoxCopyWithImpl;
@override @useResult
$Res call({
 double x1, double y1, double x2, double y2
});




}
/// @nodoc
class __$BottleBoxCopyWithImpl<$Res>
    implements _$BottleBoxCopyWith<$Res> {
  __$BottleBoxCopyWithImpl(this._self, this._then);

  final _BottleBox _self;
  final $Res Function(_BottleBox) _then;

/// Create a copy of BottleBox
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x1 = null,Object? y1 = null,Object? x2 = null,Object? y2 = null,}) {
  return _then(_BottleBox(
x1: null == x1 ? _self.x1 : x1 // ignore: cast_nullable_to_non_nullable
as double,y1: null == y1 ? _self.y1 : y1 // ignore: cast_nullable_to_non_nullable
as double,x2: null == x2 ? _self.x2 : x2 // ignore: cast_nullable_to_non_nullable
as double,y2: null == y2 ? _self.y2 : y2 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
