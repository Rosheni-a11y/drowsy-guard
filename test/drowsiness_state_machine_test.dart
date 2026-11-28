import 'package:flutter_test/flutter_test.dart';
import 'package:drowsy_guard/logic/drowsiness_state_machine.dart';

void main() {
  late DrowsinessStateMachine sm;
  late DateTime now;

  setUp(() {
    sm = DrowsinessStateMachine();
    now = DateTime(2026, 1, 1, 12, 0, 0);
  });

  test('starts in alert state', () {
    expect(sm.state, DrowsinessState.alert);
  });

  test('stays alert when eyes are open', () {
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, now: now);
    expect(sm.state, DrowsinessState.alert);
  });

  test('goes to warning after eyes closed for 1 second', () {
    // Eyes close
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.1, headX: 0, now: now);
    expect(sm.state, DrowsinessState.alert);

    // 1 second later, still closed
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.1, headX: 0, now: now.add(const Duration(seconds: 1)));
    expect(sm.state, DrowsinessState.warning);
  });

  test('goes to danger after eyes closed for 2 seconds', () {
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.1, headX: 0, now: now);
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.1, headX: 0, now: now.add(const Duration(seconds: 2)));
    expect(sm.state, DrowsinessState.danger);
  });

  test('recovers to alert when eyes open for 1 second', () {
    // Go to danger
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.1, headX: 0, now: now);
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.1, headX: 0, now: now.add(const Duration(seconds: 2)));
    expect(sm.state, DrowsinessState.danger);

    // Open eyes for 1 second
    final openTime = now.add(const Duration(seconds: 3));
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, now: openTime);
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, now: openTime.add(const Duration(seconds: 1)));
    expect(sm.state, DrowsinessState.alert);
  });

  test('goes to warning when head is down for 2 seconds', () {
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: -20, now: now);
    expect(sm.state, DrowsinessState.alert);

    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: -20, now: now.add(const Duration(seconds: 2)));
    expect(sm.state, DrowsinessState.warning);
  });

  test('goes to noFace when no face for 3 seconds', () {
    sm.update(faceDetected: false, now: now);
    expect(sm.state, DrowsinessState.alert);

    sm.update(faceDetected: false, now: now.add(const Duration(seconds: 3)));
    expect(sm.state, DrowsinessState.noFace);
  });

  test('only one eye closed does not trigger warning', () {
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.9, headX: 0, now: now);
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.9, headX: 0, now: now.add(const Duration(seconds: 2)));
    expect(sm.state, DrowsinessState.alert);
  });

  test('reset returns to alert', () {
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.1, headX: 0, now: now);
    sm.update(faceDetected: true, leftEyeOpen: 0.1, rightEyeOpen: 0.1, headX: 0, now: now.add(const Duration(seconds: 2)));
    expect(sm.state, DrowsinessState.danger);

    sm.reset();
    expect(sm.state, DrowsinessState.alert);
  });

  test('goes to warning when head tilts sideways for 2 seconds', () {
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, headZ: 25, now: now);
    expect(sm.state, DrowsinessState.alert);

    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, headZ: 25, now: now.add(const Duration(seconds: 2)));
    expect(sm.state, DrowsinessState.warning);
  });

  test('goes to warning when head turns far left for 2 seconds', () {
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, headY: 35, now: now);
    expect(sm.state, DrowsinessState.alert);

    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, headY: 35, now: now.add(const Duration(seconds: 2)));
    expect(sm.state, DrowsinessState.warning);
  });

  test('goes to warning after 3 yawns in 60 seconds', () {
    // Yawn 1: mouth opens then closes
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, isMouthOpen: true, now: now);
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, isMouthOpen: false, now: now.add(const Duration(seconds: 5)));
    expect(sm.state, DrowsinessState.alert);

    // Yawn 2
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, isMouthOpen: true, now: now.add(const Duration(seconds: 20)));
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, isMouthOpen: false, now: now.add(const Duration(seconds: 25)));
    expect(sm.state, DrowsinessState.alert);

    // Yawn 3 — this should trigger warning
    sm.update(faceDetected: true, leftEyeOpen: 0.9, rightEyeOpen: 0.9, headX: 0, isMouthOpen: true, now: now.add(const Duration(seconds: 40)));
    expect(sm.state, DrowsinessState.warning);
  });
}
