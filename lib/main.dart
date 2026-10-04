import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/parent_app_provider.dart';
import 'presentation/main_navigation_screen.dart';
import 'presentation/screens/auth/parent_login_screen.dart';
import 'presentation/screens/auth/link_child_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Flutter SDK safely before runApp
  await SupabaseService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ParentApplication());
}

class ParentApplication extends StatelessWidget {
  const ParentApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ParentAppProvider()),
      ],
      child: Consumer<ParentAppProvider>(
        builder: (context, provider, child) {
          Widget homeWidget;
          if (provider.isSessionChecking) {
            homeWidget = const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.brandIndigo),
              ),
            );
          } else if (provider.isLoggedIn) {
            if (provider.children.isEmpty) {
              homeWidget = const LinkChildScreen(isFirstTimeSetup: true);
            } else {
              homeWidget = const MainNavigationScreen();
            }
          } else {
            homeWidget = const ParentLoginScreen();
          }

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode,
            home: homeWidget,
          );
        },
      ),
    );
  }
}
