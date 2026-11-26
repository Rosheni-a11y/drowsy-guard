enum DrowsinessState { alert, warning, danger, noFace }

class DrowsinessStateMachine {
  DrowsinessState _state = DrowsinessState.alert;
  DrowsinessState get state => _state;

  DateTime? _eyesClosedSince;
  DateTime? _headDownSince;
  DateTime? _noFaceSince;
  DateTime? _eyesOpenSince;

  // Thresholds (in seconds)
  static const double warningThreshold = 1.0;
  static const double dangerThreshold = 2.0;
  static const double headDownThreshold = 2.0;
  static const double noFaceThreshold = 3.0;
  static const double recoveryThreshold = 1.0;

  // Eye is closed when probability is below this
  static const double eyeClosedLimit = 0.3;

  // Head is tilted down when X angle is below this (negative = looking down)
  static const double headDownAngle = -15.0;

  void update({
    required bool faceDetected,
    double? leftEyeOpen,
    double? rightEyeOpen,
    double? headX,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();

    // No face detected
    if (!faceDetected) {
      _eyesClosedSince = null;
      _headDownSince = null;
      _eyesOpenSince = null;

      _noFaceSince ??= time;
      final noFaceDuration = time.difference(_noFaceSince!).inMilliseconds / 1000;

      if (noFaceDuration >= noFaceThreshold) {
        _state = DrowsinessState.noFace;
      }
      return;
    }

    // Face is detected
    _noFaceSince = null;

    final leftOpen = leftEyeOpen ?? 1.0;
    final rightOpen = rightEyeOpen ?? 1.0;
    final bothEyesClosed = leftOpen < eyeClosedLimit && rightOpen < eyeClosedLimit;

    final headDown = (headX ?? 0) < headDownAngle;

    // Track eyes closed duration
    if (bothEyesClosed) {
      _eyesClosedSince ??= time;
      _eyesOpenSince = null;
    } else {
      _eyesClosedSince = null;
      _eyesOpenSince ??= time;
    }

    // Track head down duration
    if (headDown) {
      _headDownSince ??= time;
    } else {
      _headDownSince = null;
    }

    // Calculate durations
    final eyesClosedDuration = _eyesClosedSince != null
        ? time.difference(_eyesClosedSince!).inMilliseconds / 1000
        : 0.0;

    final headDownDuration = _headDownSince != null
        ? time.difference(_headDownSince!).inMilliseconds / 1000
        : 0.0;

    final eyesOpenDuration = _eyesOpenSince != null
        ? time.difference(_eyesOpenSince!).inMilliseconds / 1000
        : 0.0;

    // State transitions
    if (eyesClosedDuration >= dangerThreshold) {
      _state = DrowsinessState.danger;
    } else if (eyesClosedDuration >= warningThreshold || headDownDuration >= headDownThreshold) {
      _state = DrowsinessState.warning;
    } else if (eyesOpenDuration >= recoveryThreshold) {
      _state = DrowsinessState.alert;
    }
  }

  void reset() {
    _state = DrowsinessState.alert;
    _eyesClosedSince = null;
    _headDownSince = null;
    _noFaceSince = null;
    _eyesOpenSince = null;
  }
}
