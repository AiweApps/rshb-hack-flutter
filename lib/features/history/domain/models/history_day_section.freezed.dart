// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_day_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryDaySection {

/// Midnight of the day, in local time.
 DateTime get day; List<ScanHistoryItem> get items;
/// Create a copy of HistoryDaySection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryDaySectionCopyWith<HistoryDaySection> get copyWith => _$HistoryDaySectionCopyWithImpl<HistoryDaySection>(this as HistoryDaySection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryDaySection&&(identical(other.day, day) || other.day == day)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,day,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'HistoryDaySection(day: $day, items: $items)';
}


}

/// @nodoc
abstract mixin class $HistoryDaySectionCopyWith<$Res>  {
  factory $HistoryDaySectionCopyWith(HistoryDaySection value, $Res Function(HistoryDaySection) _then) = _$HistoryDaySectionCopyWithImpl;
@useResult
$Res call({
 DateTime day, List<ScanHistoryItem> items
});




}
/// @nodoc
class _$HistoryDaySectionCopyWithImpl<$Res>
    implements $HistoryDaySectionCopyWith<$Res> {
  _$HistoryDaySectionCopyWithImpl(this._self, this._then);

  final HistoryDaySection _self;
  final $Res Function(HistoryDaySection) _then;

/// Create a copy of HistoryDaySection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? items = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ScanHistoryItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryDaySection].
extension HistoryDaySectionPatterns on HistoryDaySection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryDaySection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryDaySection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryDaySection value)  $default,){
final _that = this;
switch (_that) {
case _HistoryDaySection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryDaySection value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryDaySection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  List<ScanHistoryItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryDaySection() when $default != null:
return $default(_that.day,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  List<ScanHistoryItem> items)  $default,) {final _that = this;
switch (_that) {
case _HistoryDaySection():
return $default(_that.day,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  List<ScanHistoryItem> items)?  $default,) {final _that = this;
switch (_that) {
case _HistoryDaySection() when $default != null:
return $default(_that.day,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryDaySection implements HistoryDaySection {
  const _HistoryDaySection({required this.day, required final  List<ScanHistoryItem> items}): _items = items;
  

/// Midnight of the day, in local time.
@override final  DateTime day;
 final  List<ScanHistoryItem> _items;
@override List<ScanHistoryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of HistoryDaySection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryDaySectionCopyWith<_HistoryDaySection> get copyWith => __$HistoryDaySectionCopyWithImpl<_HistoryDaySection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryDaySection&&(identical(other.day, day) || other.day == day)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,day,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'HistoryDaySection(day: $day, items: $items)';
}


}

/// @nodoc
abstract mixin class _$HistoryDaySectionCopyWith<$Res> implements $HistoryDaySectionCopyWith<$Res> {
  factory _$HistoryDaySectionCopyWith(_HistoryDaySection value, $Res Function(_HistoryDaySection) _then) = __$HistoryDaySectionCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, List<ScanHistoryItem> items
});




}
/// @nodoc
class __$HistoryDaySectionCopyWithImpl<$Res>
    implements _$HistoryDaySectionCopyWith<$Res> {
  __$HistoryDaySectionCopyWithImpl(this._self, this._then);

  final _HistoryDaySection _self;
  final $Res Function(_HistoryDaySection) _then;

/// Create a copy of HistoryDaySection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? items = null,}) {
  return _then(_HistoryDaySection(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ScanHistoryItem>,
  ));
}


}

// dart format on
