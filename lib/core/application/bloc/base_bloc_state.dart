import 'screen_status.dart';

/// Contract every screen state must satisfy.
///
/// [BaseBloc] accepts only states implementing this, so a screen physically
/// cannot be built without a [ScreenStatus] — the UI always has a single,
/// unambiguous answer to "loader, content or error?".
///
/// Implement it from a freezed state and declare the field in the factory:
/// ```dart
/// @freezed
/// abstract class CatalogState with _$CatalogState implements BaseBlocState {
///   const factory CatalogState({
///     required ScreenStatus screenStatus,
///     required ErrorType? errorType,
///     required List<Item> items,
///   }) = _CatalogState;
/// }
/// ```
abstract interface class BaseBlocState {
  /// Which of the three screen widgets the page renders right now.
  ScreenStatus get screenStatus;
}
