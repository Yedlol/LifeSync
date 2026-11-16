import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool get _isPhone =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Light tap, e.g. picking a card up to drag it. Phone only.
void hapticLight() {
  if (_isPhone) HapticFeedback.lightImpact();
}

/// Confirmation tap: drop, mark paid, add saving. Phone only.
void hapticSuccess() {
  if (_isPhone) HapticFeedback.mediumImpact();
}
