import 'package:flutter/services.dart';

/// Tactile feedback for touches, one call per gesture kind.
///
/// Haptics are part of how a control feels, like its ink ripple, so widgets
/// call these from their gesture handlers directly; a bloc is not involved
/// any more than it is for a ripple.
class AppHaptics {
  const AppHaptics._();

  /// A tap on a button or a card.
  static Future<void> tap() => HapticFeedback.lightImpact();

  /// A choice among several: a tab, a bottle frame, a segment.
  static Future<void> select() => HapticFeedback.selectionClick();

  /// The camera fired, a frame was drawn, a result arrived.
  static Future<void> confirm() => HapticFeedback.mediumImpact();

  /// A destructive or failed action.
  static Future<void> warn() => HapticFeedback.heavyImpact();
}
