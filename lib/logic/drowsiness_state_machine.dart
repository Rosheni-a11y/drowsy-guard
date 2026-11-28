enum DrowsinessState { alert, warning, danger, noFace }

class DrowsinessStateMachine {
  DrowsinessState _state = DrowsinessState.alert;
  DrowsinessState get state => _state;

  DateTime? _eyesClosedSince;
  DateTime? _headDownSince;
  DateTime? _noFaceSince;
  DateTime? _eyesOpenSince;
  DateTime? _headTiltSince;
  DateTime? _headTurnSince;
  List<DateTime> _yawnTimestamps = [];
  bool _wasYawning = false;

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
  static const double headTiltAngle = 20.0;
  static const double headTurnAngle = 30.0;
  static const double yawnThreshold = 3;
  static const double yawnWindowSeconds = 60;

  void update({
    required bool faceDetected,
    double? leftEyeOpen,
    double? rightEyeOpen,
    double? headX,
    double? headY,
    double? headZ,
    bool isMouthOpen = false,
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

    // Track head tilt (sideways)
    final headTilted = (headZ ?? 0).abs() > headTiltAngle;
    if (headTilted) {
      _headTiltSince ??= time;
    } else {
      _headTiltSince = null;
    }

    // Track head turn (left or right)
    final headTurned = (headY ?? 0).abs() > headTurnAngle;
    if (headTurned) {
      _headTurnSince ??= time;
    } else {
      _headTurnSince = null;
    }

    // Track yawns - count each yawn once, remove old ones
    if (isMouthOpen && !_wasYawning) {
      _yawnTimestamps.add(time);
    }
    _wasYawning = isMouthOpen;
    _yawnTimestamps.removeWhere(
      (t) => time.difference(t).inSeconds > yawnWindowSeconds,
    );

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

    final headTiltDuration = _headTiltSince != null
        ? time.difference(_headTiltSince!).inMilliseconds / 1000
        : 0.0;

    final headTurnDuration = _headTurnSince != null
        ? time.difference(_headTurnSince!).inMilliseconds / 1000
        : 0.0;

    final yawningFrequently = _yawnTimestamps.length >= yawnThreshold;

    // State transitions
    if (eyesClosedDuration >= dangerThreshold) {
      _state = DrowsinessState.danger;
    } else if (eyesClosedDuration >= warningThreshold ||
        headDownDuration >= headDownThreshold ||
        headTiltDuration >= headDownThreshold ||
        headTurnDuration >= headDownThreshold ||
        yawningFrequently) {
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
    _headTiltSince = null;
    _headTurnSince = null;
    _yawnTimestamps = [];
    _wasYawning = false;
  }
}
