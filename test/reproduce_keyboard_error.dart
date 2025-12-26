import  'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Reproduce keyboard assertions', (WidgetTester tester) async {
    // This test aims to reproduce: "A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed."

    // Simulate KeyDown for ArrowUp
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);

    // Simulate KeyDown for ArrowUp AGAIN without KeyUp.
    // This is expected to trigger the assertion failure in HardwareKeyboard.
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowUp);
  });
}
