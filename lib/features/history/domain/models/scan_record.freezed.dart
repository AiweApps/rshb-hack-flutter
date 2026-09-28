// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScanRecord {

 int get id; DateTime get createdAt; String get photoPath; RecognitionView get view;
/// Create a copy of ScanRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanRecordCopyWith<ScanRecord> get copyWith => _$ScanRecordCopyWithImpl<ScanRecord>(this as ScanRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,id,createdAt,photoPath,view);

@override
String toString() {
  return 'ScanRecord(id: $id, createdAt: $createdAt, photoPath: $photoPath, view: $view)';
}


}

/// @nodoc
abstract mixin class $ScanRecordCopyWith<$Res>  {
  factory $ScanRecordCopyWith(ScanRecord value, $Res Function(ScanRecord) _then) = _$ScanRecordCopyWithImpl;
@useResult
$Res call({
 int id, DateTime createdAt, String photoPath, RecognitionView view
});


$RecognitionViewCopyWith<$Res> get view;

}
/// @nodoc
class _$ScanRecordCopyWithImpl<$Res>
    implements $ScanRecordCopyWith<$Res> {
  _$ScanRecordCopyWithImpl(this._self, this._then);

  final ScanRecord _self;
  final $Res Function(ScanRecord) _then;

/// Create a copy of ScanRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? photoPath = null,Object? view = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,photoPath: null == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String,view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as RecognitionView,
  ));
}
/// Create a copy of ScanRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecognitionViewCopyWith<$Res> get view {
  
  return $RecognitionViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScanRecord].
extension ScanRecordPatterns on ScanRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanRecord value)  $default,){
final _that = this;
switch (_that) {
case _ScanRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ScanRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DateTime createdAt,  String photoPath,  RecognitionView view)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanRecord() when $default != null:
return $default(_that.id,_that.createdAt,_that.photoPath,_that.view);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DateTime createdAt,  String photoPath,  RecognitionView view)  $default,) {final _that = this;
switch (_that) {
case _ScanRecord():
return $default(_that.id,_that.createdAt,_that.photoPath,_that.view);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DateTime createdAt,  String photoPath,  RecognitionView view)?  $default,) {final _that = this;
switch (_that) {
case _ScanRecord() when $default != null:
return $default(_that.id,_that.createdAt,_that.photoPath,_that.view);case _:
  return null;

}
}

}

/// @nodoc


class _ScanRecord implements ScanRecord {
  const _ScanRecord({required this.id, required this.createdAt, required this.photoPath, required this.view});
  

@override final  int id;
@override final  DateTime createdAt;
@override final  String photoPath;
@override final  RecognitionView view;

/// Create a copy of ScanRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanRecordCopyWith<_ScanRecord> get copyWith => __$ScanRecordCopyWithImpl<_ScanRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,id,createdAt,photoPath,view);

@override
String toString() {
  return 'ScanRecord(id: $id, createdAt: $createdAt, photoPath: $photoPath, view: $view)';
}


}

/// @nodoc
abstract mixin class _$ScanRecordCopyWith<$Res> implements $ScanRecordCopyWith<$Res> {
  factory _$ScanRecordCopyWith(_ScanRecord value, $Res Function(_ScanRecord) _then) = __$ScanRecordCopyWithImpl;
@override @useResult
$Res call({
 int id, DateTime createdAt, String photoPath, RecognitionView view
});


@override $RecognitionViewCopyWith<$Res> get view;

}
/// @nodoc
class __$ScanRecordCopyWithImpl<$Res>
    implements _$ScanRecordCopyWith<$Res> {
  __$ScanRecordCopyWithImpl(this._self, this._then);

  final _ScanRecord _self;
  final $Res Function(_ScanRecord) _then;

/// Create a copy of ScanRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? photoPath = null,Object? view = null,}) {
  return _then(_ScanRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,photoPath: null == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String,view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as RecognitionView,
  ));
}

/// Create a copy of ScanRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecognitionViewCopyWith<$Res> get view {
  
  return $RecognitionViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc
mixin _$ScanHistoryItem {

 int get id; DateTime get createdAt; String get photoPath; String? get bestTitle; String? get bestProducer; String? get bestReference; int get bottleCount;
/// Create a copy of ScanHistoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanHistoryItemCopyWith<ScanHistoryItem> get copyWith => _$ScanHistoryItemCopyWithImpl<ScanHistoryItem>(this as ScanHistoryItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanHistoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.bestTitle, bestTitle) || other.bestTitle == bestTitle)&&(identical(other.bestProducer, bestProducer) || other.bestProducer == bestProducer)&&(identical(other.bestReference, bestReference) || other.bestReference == bestReference)&&(identical(other.bottleCount, bottleCount) || other.bottleCount == bottleCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,createdAt,photoPath,bestTitle,bestProducer,bestReference,bottleCount);

@override
String toString() {
  return 'ScanHistoryItem(id: $id, createdAt: $createdAt, photoPath: $photoPath, bestTitle: $bestTitle, bestProducer: $bestProducer, bestReference: $bestReference, bottleCount: $bottleCount)';
}


}

/// @nodoc
abstract mixin class $ScanHistoryItemCopyWith<$Res>  {
  factory $ScanHistoryItemCopyWith(ScanHistoryItem value, $Res Function(ScanHistoryItem) _then) = _$ScanHistoryItemCopyWithImpl;
@useResult
$Res call({
 int id, DateTime createdAt, String photoPath, String? bestTitle, String? bestProducer, String? bestReference, int bottleCount
});




}
/// @nodoc
class _$ScanHistoryItemCopyWithImpl<$Res>
    implements $ScanHistoryItemCopyWith<$Res> {
  _$ScanHistoryItemCopyWithImpl(this._self, this._then);

  final ScanHistoryItem _self;
  final $Res Function(ScanHistoryItem) _then;

/// Create a copy of ScanHistoryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? photoPath = null,Object? bestTitle = freezed,Object? bestProducer = freezed,Object? bestReference = freezed,Object? bottleCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,photoPath: null == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String,bestTitle: freezed == bestTitle ? _self.bestTitle : bestTitle // ignore: cast_nullable_to_non_nullable
as String?,bestProducer: freezed == bestProducer ? _self.bestProducer : bestProducer // ignore: cast_nullable_to_non_nullable
as String?,bestReference: freezed == bestReference ? _self.bestReference : bestReference // ignore: cast_nullable_to_non_nullable
as String?,bottleCount: null == bottleCount ? _self.bottleCount : bottleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanHistoryItem].
extension ScanHistoryItemPatterns on ScanHistoryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanHistoryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanHistoryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanHistoryItem value)  $default,){
final _that = this;
switch (_that) {
case _ScanHistoryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanHistoryItem value)?  $default,){
final _that = this;
switch (_that) {
case _ScanHistoryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DateTime createdAt,  String photoPath,  String? bestTitle,  String? bestProducer,  String? bestReference,  int bottleCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanHistoryItem() when $default != null:
return $default(_that.id,_that.createdAt,_that.photoPath,_that.bestTitle,_that.bestProducer,_that.bestReference,_that.bottleCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DateTime createdAt,  String photoPath,  String? bestTitle,  String? bestProducer,  String? bestReference,  int bottleCount)  $default,) {final _that = this;
switch (_that) {
case _ScanHistoryItem():
return $default(_that.id,_that.createdAt,_that.photoPath,_that.bestTitle,_that.bestProducer,_that.bestReference,_that.bottleCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DateTime createdAt,  String photoPath,  String? bestTitle,  String? bestProducer,  String? bestReference,  int bottleCount)?  $default,) {final _that = this;
switch (_that) {
case _ScanHistoryItem() when $default != null:
return $default(_that.id,_that.createdAt,_that.photoPath,_that.bestTitle,_that.bestProducer,_that.bestReference,_that.bottleCount);case _:
  return null;

}
}

}

/// @nodoc


class _ScanHistoryItem implements ScanHistoryItem {
  const _ScanHistoryItem({required this.id, required this.createdAt, required this.photoPath, required this.bestTitle, required this.bestProducer, required this.bestReference, required this.bottleCount});
  

@override final  int id;
@override final  DateTime createdAt;
@override final  String photoPath;
@override final  String? bestTitle;
@override final  String? bestProducer;
@override final  String? bestReference;
@override final  int bottleCount;

/// Create a copy of ScanHistoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanHistoryItemCopyWith<_ScanHistoryItem> get copyWith => __$ScanHistoryItemCopyWithImpl<_ScanHistoryItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanHistoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.bestTitle, bestTitle) || other.bestTitle == bestTitle)&&(identical(other.bestProducer, bestProducer) || other.bestProducer == bestProducer)&&(identical(other.bestReference, bestReference) || other.bestReference == bestReference)&&(identical(other.bottleCount, bottleCount) || other.bottleCount == bottleCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,createdAt,photoPath,bestTitle,bestProducer,bestReference,bottleCount);

@override
String toString() {
  return 'ScanHistoryItem(id: $id, createdAt: $createdAt, photoPath: $photoPath, bestTitle: $bestTitle, bestProducer: $bestProducer, bestReference: $bestReference, bottleCount: $bottleCount)';
}


}

/// @nodoc
abstract mixin class _$ScanHistoryItemCopyWith<$Res> implements $ScanHistoryItemCopyWith<$Res> {
  factory _$ScanHistoryItemCopyWith(_ScanHistoryItem value, $Res Function(_ScanHistoryItem) _then) = __$ScanHistoryItemCopyWithImpl;
@override @useResult
$Res call({
 int id, DateTime createdAt, String photoPath, String? bestTitle, String? bestProducer, String? bestReference, int bottleCount
});




}
/// @nodoc
class __$ScanHistoryItemCopyWithImpl<$Res>
    implements _$ScanHistoryItemCopyWith<$Res> {
  __$ScanHistoryItemCopyWithImpl(this._self, this._then);

  final _ScanHistoryItem _self;
  final $Res Function(_ScanHistoryItem) _then;

/// Create a copy of ScanHistoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? photoPath = null,Object? bestTitle = freezed,Object? bestProducer = freezed,Object? bestReference = freezed,Object? bottleCount = null,}) {
  return _then(_ScanHistoryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,photoPath: null == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String,bestTitle: freezed == bestTitle ? _self.bestTitle : bestTitle // ignore: cast_nullable_to_non_nullable
as String?,bestProducer: freezed == bestProducer ? _self.bestProducer : bestProducer // ignore: cast_nullable_to_non_nullable
as String?,bestReference: freezed == bestReference ? _self.bestReference : bestReference // ignore: cast_nullable_to_non_nullable
as String?,bottleCount: null == bottleCount ? _self.bottleCount : bottleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
