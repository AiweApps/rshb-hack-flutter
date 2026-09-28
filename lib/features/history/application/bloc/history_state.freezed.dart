// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryState {

 ScreenStatus get screenStatus;/// Set only while [screenStatus] is [ScreenStatus.error].
 ErrorType? get errorType;/// Rows the list renders: what the database holds minus the rows the
/// user has already swiped away and whose deletion is still in flight.
 List<ScanHistoryItem> get items;/// [items] grouped by calendar day, newest first — what the list draws.
 List<HistoryDaySection> get sections;/// Ids swiped away but not yet gone from the database.
 Set<int> get pendingDeleteIds;
/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryStateCopyWith<HistoryState> get copyWith => _$HistoryStateCopyWithImpl<HistoryState>(this as HistoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.sections, sections)&&const DeepCollectionEquality().equals(other.pendingDeleteIds, pendingDeleteIds));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,errorType,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(sections),const DeepCollectionEquality().hash(pendingDeleteIds));

@override
String toString() {
  return 'HistoryState(screenStatus: $screenStatus, errorType: $errorType, items: $items, sections: $sections, pendingDeleteIds: $pendingDeleteIds)';
}


}

/// @nodoc
abstract mixin class $HistoryStateCopyWith<$Res>  {
  factory $HistoryStateCopyWith(HistoryState value, $Res Function(HistoryState) _then) = _$HistoryStateCopyWithImpl;
@useResult
$Res call({
 ScreenStatus screenStatus, ErrorType? errorType, List<ScanHistoryItem> items, List<HistoryDaySection> sections, Set<int> pendingDeleteIds
});




}
/// @nodoc
class _$HistoryStateCopyWithImpl<$Res>
    implements $HistoryStateCopyWith<$Res> {
  _$HistoryStateCopyWithImpl(this._self, this._then);

  final HistoryState _self;
  final $Res Function(HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenStatus = null,Object? errorType = freezed,Object? items = null,Object? sections = null,Object? pendingDeleteIds = null,}) {
  return _then(_self.copyWith(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,errorType: freezed == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as ErrorType?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ScanHistoryItem>,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<HistoryDaySection>,pendingDeleteIds: null == pendingDeleteIds ? _self.pendingDeleteIds : pendingDeleteIds // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryState].
extension HistoryStatePatterns on HistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryState value)  $default,){
final _that = this;
switch (_that) {
case _HistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  ErrorType? errorType,  List<ScanHistoryItem> items,  List<HistoryDaySection> sections,  Set<int> pendingDeleteIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.screenStatus,_that.errorType,_that.items,_that.sections,_that.pendingDeleteIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  ErrorType? errorType,  List<ScanHistoryItem> items,  List<HistoryDaySection> sections,  Set<int> pendingDeleteIds)  $default,) {final _that = this;
switch (_that) {
case _HistoryState():
return $default(_that.screenStatus,_that.errorType,_that.items,_that.sections,_that.pendingDeleteIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScreenStatus screenStatus,  ErrorType? errorType,  List<ScanHistoryItem> items,  List<HistoryDaySection> sections,  Set<int> pendingDeleteIds)?  $default,) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.screenStatus,_that.errorType,_that.items,_that.sections,_that.pendingDeleteIds);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryState extends HistoryState {
  const _HistoryState({required this.screenStatus, required this.errorType, required final  List<ScanHistoryItem> items, required final  List<HistoryDaySection> sections, required final  Set<int> pendingDeleteIds}): _items = items,_sections = sections,_pendingDeleteIds = pendingDeleteIds,super._();
  

@override final  ScreenStatus screenStatus;
/// Set only while [screenStatus] is [ScreenStatus.error].
@override final  ErrorType? errorType;
/// Rows the list renders: what the database holds minus the rows the
/// user has already swiped away and whose deletion is still in flight.
 final  List<ScanHistoryItem> _items;
/// Rows the list renders: what the database holds minus the rows the
/// user has already swiped away and whose deletion is still in flight.
@override List<ScanHistoryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// [items] grouped by calendar day, newest first — what the list draws.
 final  List<HistoryDaySection> _sections;
/// [items] grouped by calendar day, newest first — what the list draws.
@override List<HistoryDaySection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// Ids swiped away but not yet gone from the database.
 final  Set<int> _pendingDeleteIds;
/// Ids swiped away but not yet gone from the database.
@override Set<int> get pendingDeleteIds {
  if (_pendingDeleteIds is EqualUnmodifiableSetView) return _pendingDeleteIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_pendingDeleteIds);
}


/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryStateCopyWith<_HistoryState> get copyWith => __$HistoryStateCopyWithImpl<_HistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._pendingDeleteIds, _pendingDeleteIds));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,errorType,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_pendingDeleteIds));

@override
String toString() {
  return 'HistoryState(screenStatus: $screenStatus, errorType: $errorType, items: $items, sections: $sections, pendingDeleteIds: $pendingDeleteIds)';
}


}

/// @nodoc
abstract mixin class _$HistoryStateCopyWith<$Res> implements $HistoryStateCopyWith<$Res> {
  factory _$HistoryStateCopyWith(_HistoryState value, $Res Function(_HistoryState) _then) = __$HistoryStateCopyWithImpl;
@override @useResult
$Res call({
 ScreenStatus screenStatus, ErrorType? errorType, List<ScanHistoryItem> items, List<HistoryDaySection> sections, Set<int> pendingDeleteIds
});




}
/// @nodoc
class __$HistoryStateCopyWithImpl<$Res>
    implements _$HistoryStateCopyWith<$Res> {
  __$HistoryStateCopyWithImpl(this._self, this._then);

  final _HistoryState _self;
  final $Res Function(_HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenStatus = null,Object? errorType = freezed,Object? items = null,Object? sections = null,Object? pendingDeleteIds = null,}) {
  return _then(_HistoryState(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,errorType: freezed == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as ErrorType?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ScanHistoryItem>,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<HistoryDaySection>,pendingDeleteIds: null == pendingDeleteIds ? _self._pendingDeleteIds : pendingDeleteIds // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}


}

// dart format on
