// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_result_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScanResultState {

/// `loading` until the photo (or the stored scan) is at hand; `error`
/// only when a stored scan no longer exists.
 ScreenStatus get screenStatus; ErrorType? get errorType; String get photoPath;/// Opened from the history: the answer is shown, not requested, and
/// re-scans are not stored.
 bool get isStored; ResultPhase get phase;/// The request in flight (or the one that failed) was for a frame.
 bool get isRoiRequest;/// The answer on screen.
 RecognitionView? get view;/// The all-bottles answer kept while a frame answer is shown.
 RecognitionView? get overview; String? get selectedInstanceId;/// Frame of the request in flight or the one that failed.
 BottleBox? get pendingRoi; int get retryAttempt; int get retrySecondsLeft; RetryReason get retryReason; ScanFailure? get failure; ReferenceAccess? get referenceAccess; int? get historyId;/// The "what does «Распознать» do" bubble opens by itself once.
 bool get showRescanHint; List<TechRow> get techRows;
/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanResultStateCopyWith<ScanResultState> get copyWith => _$ScanResultStateCopyWithImpl<ScanResultState>(this as ScanResultState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanResultState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.isStored, isStored) || other.isStored == isStored)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.isRoiRequest, isRoiRequest) || other.isRoiRequest == isRoiRequest)&&(identical(other.view, view) || other.view == view)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.selectedInstanceId, selectedInstanceId) || other.selectedInstanceId == selectedInstanceId)&&(identical(other.pendingRoi, pendingRoi) || other.pendingRoi == pendingRoi)&&(identical(other.retryAttempt, retryAttempt) || other.retryAttempt == retryAttempt)&&(identical(other.retrySecondsLeft, retrySecondsLeft) || other.retrySecondsLeft == retrySecondsLeft)&&(identical(other.retryReason, retryReason) || other.retryReason == retryReason)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.referenceAccess, referenceAccess) || other.referenceAccess == referenceAccess)&&(identical(other.historyId, historyId) || other.historyId == historyId)&&(identical(other.showRescanHint, showRescanHint) || other.showRescanHint == showRescanHint)&&const DeepCollectionEquality().equals(other.techRows, techRows));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,errorType,photoPath,isStored,phase,isRoiRequest,view,overview,selectedInstanceId,pendingRoi,retryAttempt,retrySecondsLeft,retryReason,failure,referenceAccess,historyId,showRescanHint,const DeepCollectionEquality().hash(techRows));

@override
String toString() {
  return 'ScanResultState(screenStatus: $screenStatus, errorType: $errorType, photoPath: $photoPath, isStored: $isStored, phase: $phase, isRoiRequest: $isRoiRequest, view: $view, overview: $overview, selectedInstanceId: $selectedInstanceId, pendingRoi: $pendingRoi, retryAttempt: $retryAttempt, retrySecondsLeft: $retrySecondsLeft, retryReason: $retryReason, failure: $failure, referenceAccess: $referenceAccess, historyId: $historyId, showRescanHint: $showRescanHint, techRows: $techRows)';
}


}

/// @nodoc
abstract mixin class $ScanResultStateCopyWith<$Res>  {
  factory $ScanResultStateCopyWith(ScanResultState value, $Res Function(ScanResultState) _then) = _$ScanResultStateCopyWithImpl;
@useResult
$Res call({
 ScreenStatus screenStatus, ErrorType? errorType, String photoPath, bool isStored, ResultPhase phase, bool isRoiRequest, RecognitionView? view, RecognitionView? overview, String? selectedInstanceId, BottleBox? pendingRoi, int retryAttempt, int retrySecondsLeft, RetryReason retryReason, ScanFailure? failure, ReferenceAccess? referenceAccess, int? historyId, bool showRescanHint, List<TechRow> techRows
});


$RecognitionViewCopyWith<$Res>? get view;$RecognitionViewCopyWith<$Res>? get overview;$BottleBoxCopyWith<$Res>? get pendingRoi;$ScanFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$ScanResultStateCopyWithImpl<$Res>
    implements $ScanResultStateCopyWith<$Res> {
  _$ScanResultStateCopyWithImpl(this._self, this._then);

  final ScanResultState _self;
  final $Res Function(ScanResultState) _then;

/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenStatus = null,Object? errorType = freezed,Object? photoPath = null,Object? isStored = null,Object? phase = null,Object? isRoiRequest = null,Object? view = freezed,Object? overview = freezed,Object? selectedInstanceId = freezed,Object? pendingRoi = freezed,Object? retryAttempt = null,Object? retrySecondsLeft = null,Object? retryReason = null,Object? failure = freezed,Object? referenceAccess = freezed,Object? historyId = freezed,Object? showRescanHint = null,Object? techRows = null,}) {
  return _then(_self.copyWith(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,errorType: freezed == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as ErrorType?,photoPath: null == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String,isStored: null == isStored ? _self.isStored : isStored // ignore: cast_nullable_to_non_nullable
as bool,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ResultPhase,isRoiRequest: null == isRoiRequest ? _self.isRoiRequest : isRoiRequest // ignore: cast_nullable_to_non_nullable
as bool,view: freezed == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as RecognitionView?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as RecognitionView?,selectedInstanceId: freezed == selectedInstanceId ? _self.selectedInstanceId : selectedInstanceId // ignore: cast_nullable_to_non_nullable
as String?,pendingRoi: freezed == pendingRoi ? _self.pendingRoi : pendingRoi // ignore: cast_nullable_to_non_nullable
as BottleBox?,retryAttempt: null == retryAttempt ? _self.retryAttempt : retryAttempt // ignore: cast_nullable_to_non_nullable
as int,retrySecondsLeft: null == retrySecondsLeft ? _self.retrySecondsLeft : retrySecondsLeft // ignore: cast_nullable_to_non_nullable
as int,retryReason: null == retryReason ? _self.retryReason : retryReason // ignore: cast_nullable_to_non_nullable
as RetryReason,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ScanFailure?,referenceAccess: freezed == referenceAccess ? _self.referenceAccess : referenceAccess // ignore: cast_nullable_to_non_nullable
as ReferenceAccess?,historyId: freezed == historyId ? _self.historyId : historyId // ignore: cast_nullable_to_non_nullable
as int?,showRescanHint: null == showRescanHint ? _self.showRescanHint : showRescanHint // ignore: cast_nullable_to_non_nullable
as bool,techRows: null == techRows ? _self.techRows : techRows // ignore: cast_nullable_to_non_nullable
as List<TechRow>,
  ));
}
/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecognitionViewCopyWith<$Res>? get view {
    if (_self.view == null) {
    return null;
  }

  return $RecognitionViewCopyWith<$Res>(_self.view!, (value) {
    return _then(_self.copyWith(view: value));
  });
}/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecognitionViewCopyWith<$Res>? get overview {
    if (_self.overview == null) {
    return null;
  }

  return $RecognitionViewCopyWith<$Res>(_self.overview!, (value) {
    return _then(_self.copyWith(overview: value));
  });
}/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get pendingRoi {
    if (_self.pendingRoi == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.pendingRoi!, (value) {
    return _then(_self.copyWith(pendingRoi: value));
  });
}/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScanFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $ScanFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScanResultState].
extension ScanResultStatePatterns on ScanResultState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanResultState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanResultState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanResultState value)  $default,){
final _that = this;
switch (_that) {
case _ScanResultState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanResultState value)?  $default,){
final _that = this;
switch (_that) {
case _ScanResultState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  ErrorType? errorType,  String photoPath,  bool isStored,  ResultPhase phase,  bool isRoiRequest,  RecognitionView? view,  RecognitionView? overview,  String? selectedInstanceId,  BottleBox? pendingRoi,  int retryAttempt,  int retrySecondsLeft,  RetryReason retryReason,  ScanFailure? failure,  ReferenceAccess? referenceAccess,  int? historyId,  bool showRescanHint,  List<TechRow> techRows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanResultState() when $default != null:
return $default(_that.screenStatus,_that.errorType,_that.photoPath,_that.isStored,_that.phase,_that.isRoiRequest,_that.view,_that.overview,_that.selectedInstanceId,_that.pendingRoi,_that.retryAttempt,_that.retrySecondsLeft,_that.retryReason,_that.failure,_that.referenceAccess,_that.historyId,_that.showRescanHint,_that.techRows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScreenStatus screenStatus,  ErrorType? errorType,  String photoPath,  bool isStored,  ResultPhase phase,  bool isRoiRequest,  RecognitionView? view,  RecognitionView? overview,  String? selectedInstanceId,  BottleBox? pendingRoi,  int retryAttempt,  int retrySecondsLeft,  RetryReason retryReason,  ScanFailure? failure,  ReferenceAccess? referenceAccess,  int? historyId,  bool showRescanHint,  List<TechRow> techRows)  $default,) {final _that = this;
switch (_that) {
case _ScanResultState():
return $default(_that.screenStatus,_that.errorType,_that.photoPath,_that.isStored,_that.phase,_that.isRoiRequest,_that.view,_that.overview,_that.selectedInstanceId,_that.pendingRoi,_that.retryAttempt,_that.retrySecondsLeft,_that.retryReason,_that.failure,_that.referenceAccess,_that.historyId,_that.showRescanHint,_that.techRows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScreenStatus screenStatus,  ErrorType? errorType,  String photoPath,  bool isStored,  ResultPhase phase,  bool isRoiRequest,  RecognitionView? view,  RecognitionView? overview,  String? selectedInstanceId,  BottleBox? pendingRoi,  int retryAttempt,  int retrySecondsLeft,  RetryReason retryReason,  ScanFailure? failure,  ReferenceAccess? referenceAccess,  int? historyId,  bool showRescanHint,  List<TechRow> techRows)?  $default,) {final _that = this;
switch (_that) {
case _ScanResultState() when $default != null:
return $default(_that.screenStatus,_that.errorType,_that.photoPath,_that.isStored,_that.phase,_that.isRoiRequest,_that.view,_that.overview,_that.selectedInstanceId,_that.pendingRoi,_that.retryAttempt,_that.retrySecondsLeft,_that.retryReason,_that.failure,_that.referenceAccess,_that.historyId,_that.showRescanHint,_that.techRows);case _:
  return null;

}
}

}

/// @nodoc


class _ScanResultState extends ScanResultState {
  const _ScanResultState({required this.screenStatus, required this.errorType, required this.photoPath, required this.isStored, required this.phase, required this.isRoiRequest, required this.view, required this.overview, required this.selectedInstanceId, required this.pendingRoi, required this.retryAttempt, required this.retrySecondsLeft, required this.retryReason, required this.failure, required this.referenceAccess, required this.historyId, required this.showRescanHint, required final  List<TechRow> techRows}): _techRows = techRows,super._();
  

/// `loading` until the photo (or the stored scan) is at hand; `error`
/// only when a stored scan no longer exists.
@override final  ScreenStatus screenStatus;
@override final  ErrorType? errorType;
@override final  String photoPath;
/// Opened from the history: the answer is shown, not requested, and
/// re-scans are not stored.
@override final  bool isStored;
@override final  ResultPhase phase;
/// The request in flight (or the one that failed) was for a frame.
@override final  bool isRoiRequest;
/// The answer on screen.
@override final  RecognitionView? view;
/// The all-bottles answer kept while a frame answer is shown.
@override final  RecognitionView? overview;
@override final  String? selectedInstanceId;
/// Frame of the request in flight or the one that failed.
@override final  BottleBox? pendingRoi;
@override final  int retryAttempt;
@override final  int retrySecondsLeft;
@override final  RetryReason retryReason;
@override final  ScanFailure? failure;
@override final  ReferenceAccess? referenceAccess;
@override final  int? historyId;
/// The "what does «Распознать» do" bubble opens by itself once.
@override final  bool showRescanHint;
 final  List<TechRow> _techRows;
@override List<TechRow> get techRows {
  if (_techRows is EqualUnmodifiableListView) return _techRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_techRows);
}


/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanResultStateCopyWith<_ScanResultState> get copyWith => __$ScanResultStateCopyWithImpl<_ScanResultState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanResultState&&(identical(other.screenStatus, screenStatus) || other.screenStatus == screenStatus)&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.isStored, isStored) || other.isStored == isStored)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.isRoiRequest, isRoiRequest) || other.isRoiRequest == isRoiRequest)&&(identical(other.view, view) || other.view == view)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.selectedInstanceId, selectedInstanceId) || other.selectedInstanceId == selectedInstanceId)&&(identical(other.pendingRoi, pendingRoi) || other.pendingRoi == pendingRoi)&&(identical(other.retryAttempt, retryAttempt) || other.retryAttempt == retryAttempt)&&(identical(other.retrySecondsLeft, retrySecondsLeft) || other.retrySecondsLeft == retrySecondsLeft)&&(identical(other.retryReason, retryReason) || other.retryReason == retryReason)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.referenceAccess, referenceAccess) || other.referenceAccess == referenceAccess)&&(identical(other.historyId, historyId) || other.historyId == historyId)&&(identical(other.showRescanHint, showRescanHint) || other.showRescanHint == showRescanHint)&&const DeepCollectionEquality().equals(other._techRows, _techRows));
}


@override
int get hashCode => Object.hash(runtimeType,screenStatus,errorType,photoPath,isStored,phase,isRoiRequest,view,overview,selectedInstanceId,pendingRoi,retryAttempt,retrySecondsLeft,retryReason,failure,referenceAccess,historyId,showRescanHint,const DeepCollectionEquality().hash(_techRows));

@override
String toString() {
  return 'ScanResultState(screenStatus: $screenStatus, errorType: $errorType, photoPath: $photoPath, isStored: $isStored, phase: $phase, isRoiRequest: $isRoiRequest, view: $view, overview: $overview, selectedInstanceId: $selectedInstanceId, pendingRoi: $pendingRoi, retryAttempt: $retryAttempt, retrySecondsLeft: $retrySecondsLeft, retryReason: $retryReason, failure: $failure, referenceAccess: $referenceAccess, historyId: $historyId, showRescanHint: $showRescanHint, techRows: $techRows)';
}


}

/// @nodoc
abstract mixin class _$ScanResultStateCopyWith<$Res> implements $ScanResultStateCopyWith<$Res> {
  factory _$ScanResultStateCopyWith(_ScanResultState value, $Res Function(_ScanResultState) _then) = __$ScanResultStateCopyWithImpl;
@override @useResult
$Res call({
 ScreenStatus screenStatus, ErrorType? errorType, String photoPath, bool isStored, ResultPhase phase, bool isRoiRequest, RecognitionView? view, RecognitionView? overview, String? selectedInstanceId, BottleBox? pendingRoi, int retryAttempt, int retrySecondsLeft, RetryReason retryReason, ScanFailure? failure, ReferenceAccess? referenceAccess, int? historyId, bool showRescanHint, List<TechRow> techRows
});


@override $RecognitionViewCopyWith<$Res>? get view;@override $RecognitionViewCopyWith<$Res>? get overview;@override $BottleBoxCopyWith<$Res>? get pendingRoi;@override $ScanFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$ScanResultStateCopyWithImpl<$Res>
    implements _$ScanResultStateCopyWith<$Res> {
  __$ScanResultStateCopyWithImpl(this._self, this._then);

  final _ScanResultState _self;
  final $Res Function(_ScanResultState) _then;

/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenStatus = null,Object? errorType = freezed,Object? photoPath = null,Object? isStored = null,Object? phase = null,Object? isRoiRequest = null,Object? view = freezed,Object? overview = freezed,Object? selectedInstanceId = freezed,Object? pendingRoi = freezed,Object? retryAttempt = null,Object? retrySecondsLeft = null,Object? retryReason = null,Object? failure = freezed,Object? referenceAccess = freezed,Object? historyId = freezed,Object? showRescanHint = null,Object? techRows = null,}) {
  return _then(_ScanResultState(
screenStatus: null == screenStatus ? _self.screenStatus : screenStatus // ignore: cast_nullable_to_non_nullable
as ScreenStatus,errorType: freezed == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as ErrorType?,photoPath: null == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String,isStored: null == isStored ? _self.isStored : isStored // ignore: cast_nullable_to_non_nullable
as bool,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ResultPhase,isRoiRequest: null == isRoiRequest ? _self.isRoiRequest : isRoiRequest // ignore: cast_nullable_to_non_nullable
as bool,view: freezed == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as RecognitionView?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as RecognitionView?,selectedInstanceId: freezed == selectedInstanceId ? _self.selectedInstanceId : selectedInstanceId // ignore: cast_nullable_to_non_nullable
as String?,pendingRoi: freezed == pendingRoi ? _self.pendingRoi : pendingRoi // ignore: cast_nullable_to_non_nullable
as BottleBox?,retryAttempt: null == retryAttempt ? _self.retryAttempt : retryAttempt // ignore: cast_nullable_to_non_nullable
as int,retrySecondsLeft: null == retrySecondsLeft ? _self.retrySecondsLeft : retrySecondsLeft // ignore: cast_nullable_to_non_nullable
as int,retryReason: null == retryReason ? _self.retryReason : retryReason // ignore: cast_nullable_to_non_nullable
as RetryReason,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ScanFailure?,referenceAccess: freezed == referenceAccess ? _self.referenceAccess : referenceAccess // ignore: cast_nullable_to_non_nullable
as ReferenceAccess?,historyId: freezed == historyId ? _self.historyId : historyId // ignore: cast_nullable_to_non_nullable
as int?,showRescanHint: null == showRescanHint ? _self.showRescanHint : showRescanHint // ignore: cast_nullable_to_non_nullable
as bool,techRows: null == techRows ? _self._techRows : techRows // ignore: cast_nullable_to_non_nullable
as List<TechRow>,
  ));
}

/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecognitionViewCopyWith<$Res>? get view {
    if (_self.view == null) {
    return null;
  }

  return $RecognitionViewCopyWith<$Res>(_self.view!, (value) {
    return _then(_self.copyWith(view: value));
  });
}/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecognitionViewCopyWith<$Res>? get overview {
    if (_self.overview == null) {
    return null;
  }

  return $RecognitionViewCopyWith<$Res>(_self.overview!, (value) {
    return _then(_self.copyWith(overview: value));
  });
}/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BottleBoxCopyWith<$Res>? get pendingRoi {
    if (_self.pendingRoi == null) {
    return null;
  }

  return $BottleBoxCopyWith<$Res>(_self.pendingRoi!, (value) {
    return _then(_self.copyWith(pendingRoi: value));
  });
}/// Create a copy of ScanResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScanFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $ScanFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
