import 'package:flutter/material.dart';

class HouseholdIdProvider extends InheritedWidget {
  final String householdId;

  const HouseholdIdProvider({
    super.key,
    required this.householdId,
    required super.child,
  });

  static String? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HouseholdIdProvider>()
        ?.householdId;
  }

  @override
  bool updateShouldNotify(HouseholdIdProvider oldWidget) =>
      householdId != oldWidget.householdId;
}