import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'activation_screen.dart';
import 'app_state.dart';
import 'courier_screens.dart';
import 'customer_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.init();
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سريع ديليفري',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
      ),
      home: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (!appState.activated) return const ActivationScreen();
          return appState.role == 'courier'
              ? const CourierHome()
              : const CustomerHome();
        },
      ),
    );
  }
}
