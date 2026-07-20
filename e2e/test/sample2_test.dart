import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helper.dart';

void main() {
  patrolTest('sample test 2', ($) async {
    await setUpServer(
      debugLabel: 'sample test2',
      scenarioId: 'sample_test_scenario_2',
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
  });
}
