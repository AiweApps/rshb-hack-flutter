// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceStatus {

@JsonKey(name: 'dev_mode') bool get devMode; String? get message;@JsonKey(name: 'backend_reachable') bool get backendReachable;@JsonKey(name: 'profile_match') bool get profileMatch; bool get ready; ServiceQueue? get queue; ServiceLimits? get limits;@JsonKey(name: 'expected_profile') String? get expectedProfile;@JsonKey(name: 'runtime_descriptor') String? get runtimeDescriptor; CatalogSummary? get catalog;
/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceStatusCopyWith<ServiceStatus> get copyWith => _$ServiceStatusCopyWithImpl<ServiceStatus>(this as ServiceStatus, _$identity);

  /// Serializes this ServiceStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceStatus&&(identical(other.devMode, devMode) || other.devMode == devMode)&&(identical(other.message, message) || other.message == message)&&(identical(other.backendReachable, backendReachable) || other.backendReachable == backendReachable)&&(identical(other.profileMatch, profileMatch) || other.profileMatch == profileMatch)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.queue, queue) || other.queue == queue)&&(identical(other.limits, limits) || other.limits == limits)&&(identical(other.expectedProfile, expectedProfile) || other.expectedProfile == expectedProfile)&&(identical(other.runtimeDescriptor, runtimeDescriptor) || other.runtimeDescriptor == runtimeDescriptor)&&(identical(other.catalog, catalog) || other.catalog == catalog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,devMode,message,backendReachable,profileMatch,ready,queue,limits,expectedProfile,runtimeDescriptor,catalog);

@override
String toString() {
  return 'ServiceStatus(devMode: $devMode, message: $message, backendReachable: $backendReachable, profileMatch: $profileMatch, ready: $ready, queue: $queue, limits: $limits, expectedProfile: $expectedProfile, runtimeDescriptor: $runtimeDescriptor, catalog: $catalog)';
}


}

/// @nodoc
abstract mixin class $ServiceStatusCopyWith<$Res>  {
  factory $ServiceStatusCopyWith(ServiceStatus value, $Res Function(ServiceStatus) _then) = _$ServiceStatusCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'dev_mode') bool devMode, String? message,@JsonKey(name: 'backend_reachable') bool backendReachable,@JsonKey(name: 'profile_match') bool profileMatch, bool ready, ServiceQueue? queue, ServiceLimits? limits,@JsonKey(name: 'expected_profile') String? expectedProfile,@JsonKey(name: 'runtime_descriptor') String? runtimeDescriptor, CatalogSummary? catalog
});


$ServiceQueueCopyWith<$Res>? get queue;$ServiceLimitsCopyWith<$Res>? get limits;$CatalogSummaryCopyWith<$Res>? get catalog;

}
/// @nodoc
class _$ServiceStatusCopyWithImpl<$Res>
    implements $ServiceStatusCopyWith<$Res> {
  _$ServiceStatusCopyWithImpl(this._self, this._then);

  final ServiceStatus _self;
  final $Res Function(ServiceStatus) _then;

/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? devMode = null,Object? message = freezed,Object? backendReachable = null,Object? profileMatch = null,Object? ready = null,Object? queue = freezed,Object? limits = freezed,Object? expectedProfile = freezed,Object? runtimeDescriptor = freezed,Object? catalog = freezed,}) {
  return _then(_self.copyWith(
devMode: null == devMode ? _self.devMode : devMode // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,backendReachable: null == backendReachable ? _self.backendReachable : backendReachable // ignore: cast_nullable_to_non_nullable
as bool,profileMatch: null == profileMatch ? _self.profileMatch : profileMatch // ignore: cast_nullable_to_non_nullable
as bool,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,queue: freezed == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as ServiceQueue?,limits: freezed == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as ServiceLimits?,expectedProfile: freezed == expectedProfile ? _self.expectedProfile : expectedProfile // ignore: cast_nullable_to_non_nullable
as String?,runtimeDescriptor: freezed == runtimeDescriptor ? _self.runtimeDescriptor : runtimeDescriptor // ignore: cast_nullable_to_non_nullable
as String?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CatalogSummary?,
  ));
}
/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceQueueCopyWith<$Res>? get queue {
    if (_self.queue == null) {
    return null;
  }

  return $ServiceQueueCopyWith<$Res>(_self.queue!, (value) {
    return _then(_self.copyWith(queue: value));
  });
}/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceLimitsCopyWith<$Res>? get limits {
    if (_self.limits == null) {
    return null;
  }

  return $ServiceLimitsCopyWith<$Res>(_self.limits!, (value) {
    return _then(_self.copyWith(limits: value));
  });
}/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogSummaryCopyWith<$Res>? get catalog {
    if (_self.catalog == null) {
    return null;
  }

  return $CatalogSummaryCopyWith<$Res>(_self.catalog!, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}


/// Adds pattern-matching-related methods to [ServiceStatus].
extension ServiceStatusPatterns on ServiceStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceStatus value)  $default,){
final _that = this;
switch (_that) {
case _ServiceStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'dev_mode')  bool devMode,  String? message, @JsonKey(name: 'backend_reachable')  bool backendReachable, @JsonKey(name: 'profile_match')  bool profileMatch,  bool ready,  ServiceQueue? queue,  ServiceLimits? limits, @JsonKey(name: 'expected_profile')  String? expectedProfile, @JsonKey(name: 'runtime_descriptor')  String? runtimeDescriptor,  CatalogSummary? catalog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceStatus() when $default != null:
return $default(_that.devMode,_that.message,_that.backendReachable,_that.profileMatch,_that.ready,_that.queue,_that.limits,_that.expectedProfile,_that.runtimeDescriptor,_that.catalog);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'dev_mode')  bool devMode,  String? message, @JsonKey(name: 'backend_reachable')  bool backendReachable, @JsonKey(name: 'profile_match')  bool profileMatch,  bool ready,  ServiceQueue? queue,  ServiceLimits? limits, @JsonKey(name: 'expected_profile')  String? expectedProfile, @JsonKey(name: 'runtime_descriptor')  String? runtimeDescriptor,  CatalogSummary? catalog)  $default,) {final _that = this;
switch (_that) {
case _ServiceStatus():
return $default(_that.devMode,_that.message,_that.backendReachable,_that.profileMatch,_that.ready,_that.queue,_that.limits,_that.expectedProfile,_that.runtimeDescriptor,_that.catalog);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'dev_mode')  bool devMode,  String? message, @JsonKey(name: 'backend_reachable')  bool backendReachable, @JsonKey(name: 'profile_match')  bool profileMatch,  bool ready,  ServiceQueue? queue,  ServiceLimits? limits, @JsonKey(name: 'expected_profile')  String? expectedProfile, @JsonKey(name: 'runtime_descriptor')  String? runtimeDescriptor,  CatalogSummary? catalog)?  $default,) {final _that = this;
switch (_that) {
case _ServiceStatus() when $default != null:
return $default(_that.devMode,_that.message,_that.backendReachable,_that.profileMatch,_that.ready,_that.queue,_that.limits,_that.expectedProfile,_that.runtimeDescriptor,_that.catalog);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceStatus extends ServiceStatus {
  const _ServiceStatus({@JsonKey(name: 'dev_mode') this.devMode = false, this.message, @JsonKey(name: 'backend_reachable') this.backendReachable = false, @JsonKey(name: 'profile_match') this.profileMatch = false, this.ready = false, this.queue, this.limits, @JsonKey(name: 'expected_profile') this.expectedProfile, @JsonKey(name: 'runtime_descriptor') this.runtimeDescriptor, this.catalog}): super._();
  factory _ServiceStatus.fromJson(Map<String, dynamic> json) => _$ServiceStatusFromJson(json);

@override@JsonKey(name: 'dev_mode') final  bool devMode;
@override final  String? message;
@override@JsonKey(name: 'backend_reachable') final  bool backendReachable;
@override@JsonKey(name: 'profile_match') final  bool profileMatch;
@override@JsonKey() final  bool ready;
@override final  ServiceQueue? queue;
@override final  ServiceLimits? limits;
@override@JsonKey(name: 'expected_profile') final  String? expectedProfile;
@override@JsonKey(name: 'runtime_descriptor') final  String? runtimeDescriptor;
@override final  CatalogSummary? catalog;

/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceStatusCopyWith<_ServiceStatus> get copyWith => __$ServiceStatusCopyWithImpl<_ServiceStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceStatus&&(identical(other.devMode, devMode) || other.devMode == devMode)&&(identical(other.message, message) || other.message == message)&&(identical(other.backendReachable, backendReachable) || other.backendReachable == backendReachable)&&(identical(other.profileMatch, profileMatch) || other.profileMatch == profileMatch)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.queue, queue) || other.queue == queue)&&(identical(other.limits, limits) || other.limits == limits)&&(identical(other.expectedProfile, expectedProfile) || other.expectedProfile == expectedProfile)&&(identical(other.runtimeDescriptor, runtimeDescriptor) || other.runtimeDescriptor == runtimeDescriptor)&&(identical(other.catalog, catalog) || other.catalog == catalog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,devMode,message,backendReachable,profileMatch,ready,queue,limits,expectedProfile,runtimeDescriptor,catalog);

@override
String toString() {
  return 'ServiceStatus(devMode: $devMode, message: $message, backendReachable: $backendReachable, profileMatch: $profileMatch, ready: $ready, queue: $queue, limits: $limits, expectedProfile: $expectedProfile, runtimeDescriptor: $runtimeDescriptor, catalog: $catalog)';
}


}

/// @nodoc
abstract mixin class _$ServiceStatusCopyWith<$Res> implements $ServiceStatusCopyWith<$Res> {
  factory _$ServiceStatusCopyWith(_ServiceStatus value, $Res Function(_ServiceStatus) _then) = __$ServiceStatusCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'dev_mode') bool devMode, String? message,@JsonKey(name: 'backend_reachable') bool backendReachable,@JsonKey(name: 'profile_match') bool profileMatch, bool ready, ServiceQueue? queue, ServiceLimits? limits,@JsonKey(name: 'expected_profile') String? expectedProfile,@JsonKey(name: 'runtime_descriptor') String? runtimeDescriptor, CatalogSummary? catalog
});


@override $ServiceQueueCopyWith<$Res>? get queue;@override $ServiceLimitsCopyWith<$Res>? get limits;@override $CatalogSummaryCopyWith<$Res>? get catalog;

}
/// @nodoc
class __$ServiceStatusCopyWithImpl<$Res>
    implements _$ServiceStatusCopyWith<$Res> {
  __$ServiceStatusCopyWithImpl(this._self, this._then);

  final _ServiceStatus _self;
  final $Res Function(_ServiceStatus) _then;

/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? devMode = null,Object? message = freezed,Object? backendReachable = null,Object? profileMatch = null,Object? ready = null,Object? queue = freezed,Object? limits = freezed,Object? expectedProfile = freezed,Object? runtimeDescriptor = freezed,Object? catalog = freezed,}) {
  return _then(_ServiceStatus(
devMode: null == devMode ? _self.devMode : devMode // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,backendReachable: null == backendReachable ? _self.backendReachable : backendReachable // ignore: cast_nullable_to_non_nullable
as bool,profileMatch: null == profileMatch ? _self.profileMatch : profileMatch // ignore: cast_nullable_to_non_nullable
as bool,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,queue: freezed == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as ServiceQueue?,limits: freezed == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as ServiceLimits?,expectedProfile: freezed == expectedProfile ? _self.expectedProfile : expectedProfile // ignore: cast_nullable_to_non_nullable
as String?,runtimeDescriptor: freezed == runtimeDescriptor ? _self.runtimeDescriptor : runtimeDescriptor // ignore: cast_nullable_to_non_nullable
as String?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CatalogSummary?,
  ));
}

/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceQueueCopyWith<$Res>? get queue {
    if (_self.queue == null) {
    return null;
  }

  return $ServiceQueueCopyWith<$Res>(_self.queue!, (value) {
    return _then(_self.copyWith(queue: value));
  });
}/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceLimitsCopyWith<$Res>? get limits {
    if (_self.limits == null) {
    return null;
  }

  return $ServiceLimitsCopyWith<$Res>(_self.limits!, (value) {
    return _then(_self.copyWith(limits: value));
  });
}/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogSummaryCopyWith<$Res>? get catalog {
    if (_self.catalog == null) {
    return null;
  }

  return $CatalogSummaryCopyWith<$Res>(_self.catalog!, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}


/// @nodoc
mixin _$ServiceQueue {

@JsonKey(name: 'in_flight') int get inFlight; int get waiting;
/// Create a copy of ServiceQueue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceQueueCopyWith<ServiceQueue> get copyWith => _$ServiceQueueCopyWithImpl<ServiceQueue>(this as ServiceQueue, _$identity);

  /// Serializes this ServiceQueue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceQueue&&(identical(other.inFlight, inFlight) || other.inFlight == inFlight)&&(identical(other.waiting, waiting) || other.waiting == waiting));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inFlight,waiting);

@override
String toString() {
  return 'ServiceQueue(inFlight: $inFlight, waiting: $waiting)';
}


}

/// @nodoc
abstract mixin class $ServiceQueueCopyWith<$Res>  {
  factory $ServiceQueueCopyWith(ServiceQueue value, $Res Function(ServiceQueue) _then) = _$ServiceQueueCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'in_flight') int inFlight, int waiting
});




}
/// @nodoc
class _$ServiceQueueCopyWithImpl<$Res>
    implements $ServiceQueueCopyWith<$Res> {
  _$ServiceQueueCopyWithImpl(this._self, this._then);

  final ServiceQueue _self;
  final $Res Function(ServiceQueue) _then;

/// Create a copy of ServiceQueue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inFlight = null,Object? waiting = null,}) {
  return _then(_self.copyWith(
inFlight: null == inFlight ? _self.inFlight : inFlight // ignore: cast_nullable_to_non_nullable
as int,waiting: null == waiting ? _self.waiting : waiting // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceQueue].
extension ServiceQueuePatterns on ServiceQueue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceQueue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceQueue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceQueue value)  $default,){
final _that = this;
switch (_that) {
case _ServiceQueue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceQueue value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceQueue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'in_flight')  int inFlight,  int waiting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceQueue() when $default != null:
return $default(_that.inFlight,_that.waiting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'in_flight')  int inFlight,  int waiting)  $default,) {final _that = this;
switch (_that) {
case _ServiceQueue():
return $default(_that.inFlight,_that.waiting);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'in_flight')  int inFlight,  int waiting)?  $default,) {final _that = this;
switch (_that) {
case _ServiceQueue() when $default != null:
return $default(_that.inFlight,_that.waiting);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceQueue implements ServiceQueue {
  const _ServiceQueue({@JsonKey(name: 'in_flight') this.inFlight = 0, this.waiting = 0});
  factory _ServiceQueue.fromJson(Map<String, dynamic> json) => _$ServiceQueueFromJson(json);

@override@JsonKey(name: 'in_flight') final  int inFlight;
@override@JsonKey() final  int waiting;

/// Create a copy of ServiceQueue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceQueueCopyWith<_ServiceQueue> get copyWith => __$ServiceQueueCopyWithImpl<_ServiceQueue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceQueueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceQueue&&(identical(other.inFlight, inFlight) || other.inFlight == inFlight)&&(identical(other.waiting, waiting) || other.waiting == waiting));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inFlight,waiting);

@override
String toString() {
  return 'ServiceQueue(inFlight: $inFlight, waiting: $waiting)';
}


}

/// @nodoc
abstract mixin class _$ServiceQueueCopyWith<$Res> implements $ServiceQueueCopyWith<$Res> {
  factory _$ServiceQueueCopyWith(_ServiceQueue value, $Res Function(_ServiceQueue) _then) = __$ServiceQueueCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'in_flight') int inFlight, int waiting
});




}
/// @nodoc
class __$ServiceQueueCopyWithImpl<$Res>
    implements _$ServiceQueueCopyWith<$Res> {
  __$ServiceQueueCopyWithImpl(this._self, this._then);

  final _ServiceQueue _self;
  final $Res Function(_ServiceQueue) _then;

/// Create a copy of ServiceQueue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inFlight = null,Object? waiting = null,}) {
  return _then(_ServiceQueue(
inFlight: null == inFlight ? _self.inFlight : inFlight // ignore: cast_nullable_to_non_nullable
as int,waiting: null == waiting ? _self.waiting : waiting // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ServiceLimits {

@JsonKey(name: 'max_bytes') int? get maxBytes;@JsonKey(name: 'max_pixels') int? get maxPixels;
/// Create a copy of ServiceLimits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceLimitsCopyWith<ServiceLimits> get copyWith => _$ServiceLimitsCopyWithImpl<ServiceLimits>(this as ServiceLimits, _$identity);

  /// Serializes this ServiceLimits to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceLimits&&(identical(other.maxBytes, maxBytes) || other.maxBytes == maxBytes)&&(identical(other.maxPixels, maxPixels) || other.maxPixels == maxPixels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxBytes,maxPixels);

@override
String toString() {
  return 'ServiceLimits(maxBytes: $maxBytes, maxPixels: $maxPixels)';
}


}

/// @nodoc
abstract mixin class $ServiceLimitsCopyWith<$Res>  {
  factory $ServiceLimitsCopyWith(ServiceLimits value, $Res Function(ServiceLimits) _then) = _$ServiceLimitsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'max_bytes') int? maxBytes,@JsonKey(name: 'max_pixels') int? maxPixels
});




}
/// @nodoc
class _$ServiceLimitsCopyWithImpl<$Res>
    implements $ServiceLimitsCopyWith<$Res> {
  _$ServiceLimitsCopyWithImpl(this._self, this._then);

  final ServiceLimits _self;
  final $Res Function(ServiceLimits) _then;

/// Create a copy of ServiceLimits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxBytes = freezed,Object? maxPixels = freezed,}) {
  return _then(_self.copyWith(
maxBytes: freezed == maxBytes ? _self.maxBytes : maxBytes // ignore: cast_nullable_to_non_nullable
as int?,maxPixels: freezed == maxPixels ? _self.maxPixels : maxPixels // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceLimits].
extension ServiceLimitsPatterns on ServiceLimits {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceLimits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceLimits() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceLimits value)  $default,){
final _that = this;
switch (_that) {
case _ServiceLimits():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceLimits value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceLimits() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'max_bytes')  int? maxBytes, @JsonKey(name: 'max_pixels')  int? maxPixels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceLimits() when $default != null:
return $default(_that.maxBytes,_that.maxPixels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'max_bytes')  int? maxBytes, @JsonKey(name: 'max_pixels')  int? maxPixels)  $default,) {final _that = this;
switch (_that) {
case _ServiceLimits():
return $default(_that.maxBytes,_that.maxPixels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'max_bytes')  int? maxBytes, @JsonKey(name: 'max_pixels')  int? maxPixels)?  $default,) {final _that = this;
switch (_that) {
case _ServiceLimits() when $default != null:
return $default(_that.maxBytes,_that.maxPixels);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceLimits implements ServiceLimits {
  const _ServiceLimits({@JsonKey(name: 'max_bytes') this.maxBytes, @JsonKey(name: 'max_pixels') this.maxPixels});
  factory _ServiceLimits.fromJson(Map<String, dynamic> json) => _$ServiceLimitsFromJson(json);

@override@JsonKey(name: 'max_bytes') final  int? maxBytes;
@override@JsonKey(name: 'max_pixels') final  int? maxPixels;

/// Create a copy of ServiceLimits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceLimitsCopyWith<_ServiceLimits> get copyWith => __$ServiceLimitsCopyWithImpl<_ServiceLimits>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceLimitsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceLimits&&(identical(other.maxBytes, maxBytes) || other.maxBytes == maxBytes)&&(identical(other.maxPixels, maxPixels) || other.maxPixels == maxPixels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxBytes,maxPixels);

@override
String toString() {
  return 'ServiceLimits(maxBytes: $maxBytes, maxPixels: $maxPixels)';
}


}

/// @nodoc
abstract mixin class _$ServiceLimitsCopyWith<$Res> implements $ServiceLimitsCopyWith<$Res> {
  factory _$ServiceLimitsCopyWith(_ServiceLimits value, $Res Function(_ServiceLimits) _then) = __$ServiceLimitsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'max_bytes') int? maxBytes,@JsonKey(name: 'max_pixels') int? maxPixels
});




}
/// @nodoc
class __$ServiceLimitsCopyWithImpl<$Res>
    implements _$ServiceLimitsCopyWith<$Res> {
  __$ServiceLimitsCopyWithImpl(this._self, this._then);

  final _ServiceLimits _self;
  final $Res Function(_ServiceLimits) _then;

/// Create a copy of ServiceLimits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxBytes = freezed,Object? maxPixels = freezed,}) {
  return _then(_ServiceLimits(
maxBytes: freezed == maxBytes ? _self.maxBytes : maxBytes // ignore: cast_nullable_to_non_nullable
as int?,maxPixels: freezed == maxPixels ? _self.maxPixels : maxPixels // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CatalogSummary {

 int? get cards;
/// Create a copy of CatalogSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogSummaryCopyWith<CatalogSummary> get copyWith => _$CatalogSummaryCopyWithImpl<CatalogSummary>(this as CatalogSummary, _$identity);

  /// Serializes this CatalogSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogSummary&&(identical(other.cards, cards) || other.cards == cards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cards);

@override
String toString() {
  return 'CatalogSummary(cards: $cards)';
}


}

/// @nodoc
abstract mixin class $CatalogSummaryCopyWith<$Res>  {
  factory $CatalogSummaryCopyWith(CatalogSummary value, $Res Function(CatalogSummary) _then) = _$CatalogSummaryCopyWithImpl;
@useResult
$Res call({
 int? cards
});




}
/// @nodoc
class _$CatalogSummaryCopyWithImpl<$Res>
    implements $CatalogSummaryCopyWith<$Res> {
  _$CatalogSummaryCopyWithImpl(this._self, this._then);

  final CatalogSummary _self;
  final $Res Function(CatalogSummary) _then;

/// Create a copy of CatalogSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cards = freezed,}) {
  return _then(_self.copyWith(
cards: freezed == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogSummary].
extension CatalogSummaryPatterns on CatalogSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogSummary value)  $default,){
final _that = this;
switch (_that) {
case _CatalogSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? cards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogSummary() when $default != null:
return $default(_that.cards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? cards)  $default,) {final _that = this;
switch (_that) {
case _CatalogSummary():
return $default(_that.cards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? cards)?  $default,) {final _that = this;
switch (_that) {
case _CatalogSummary() when $default != null:
return $default(_that.cards);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogSummary implements CatalogSummary {
  const _CatalogSummary({this.cards});
  factory _CatalogSummary.fromJson(Map<String, dynamic> json) => _$CatalogSummaryFromJson(json);

@override final  int? cards;

/// Create a copy of CatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogSummaryCopyWith<_CatalogSummary> get copyWith => __$CatalogSummaryCopyWithImpl<_CatalogSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogSummary&&(identical(other.cards, cards) || other.cards == cards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cards);

@override
String toString() {
  return 'CatalogSummary(cards: $cards)';
}


}

/// @nodoc
abstract mixin class _$CatalogSummaryCopyWith<$Res> implements $CatalogSummaryCopyWith<$Res> {
  factory _$CatalogSummaryCopyWith(_CatalogSummary value, $Res Function(_CatalogSummary) _then) = __$CatalogSummaryCopyWithImpl;
@override @useResult
$Res call({
 int? cards
});




}
/// @nodoc
class __$CatalogSummaryCopyWithImpl<$Res>
    implements _$CatalogSummaryCopyWith<$Res> {
  __$CatalogSummaryCopyWithImpl(this._self, this._then);

  final _CatalogSummary _self;
  final $Res Function(_CatalogSummary) _then;

/// Create a copy of CatalogSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cards = freezed,}) {
  return _then(_CatalogSummary(
cards: freezed == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
