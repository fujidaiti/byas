import 'dart:io';

import 'package:e2e/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'counter state is the same after going to home and switching apps',
    ($) async {
      await setUpServer(
        debugLabel: 'sample test',
        scenarioId: 'sample_test_scenario',
      );
      // Replace later with your app's main widget
      await $.pumpWidgetAndSettle(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('app')),
            backgroundColor: Colors.blue,
          ),
        ),
      );

      expect($('app'), findsOneWidget);
      if (!Platform.isMacOS) {
        await $.platform.mobile.pressHome();
      }
    },
  );
}
