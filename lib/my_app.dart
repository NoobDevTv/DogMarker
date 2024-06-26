import 'package:dog_marker/add_location_page.dart';
import 'package:dog_marker/custom_scroll_behavior.dart';
import 'package:dog_marker/options_page.dart';
import 'package:dog_marker/pages/about_page.dart';
import 'package:dog_marker/pages/third_party_license_page.dart';
import 'package:dog_marker/walking_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'main_page.dart';

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      scrollBehavior: CustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      routes: {
        "/walking": (c) => const WalkingPage(),
        "/add": (c) => const AddLocationPage(),
        "/options": (c) => const OptionsPage(),
        "/about": (c) => const AboutPage(),
        "/third_party_licenses": (c) => const ThirdPartyLicensePage()
      },
      title: 'Dog Marker',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
          useMaterial3: true,
          brightness: Brightness.dark),
      home: const MainPage(),
      debugShowMaterialGrid: false,
    );
  }
}
