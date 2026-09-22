import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/create_post/logic/create_post_controller.dart';
import 'package:nodo/features/create_post/logic/create_post_service.dart';
import 'package:nodo/features/home/screens/home_screen.dart';
import 'package:nodo/features/menu/about/about_screen.dart';
import 'package:nodo/features/menu/about/credits_screen.dart';
import 'package:nodo/features/menu/settings/Security/security_screen.dart';
import 'package:nodo/features/menu/settings/account_profile_screen.dart';
import 'package:nodo/features/menu/settings/notifications_settings_screen.dart';
import 'package:nodo/features/menu/settings/payments%20and%20billings/commission_calculator_screen.dart';
import 'package:nodo/features/menu/settings/payments%20and%20billings/commissions_fees_screen.dart';
import 'package:nodo/features/menu/settings/payments%20and%20billings/payments_billings_screen.dart';
import 'package:nodo/features/menu/settings/payments%20and%20billings/payments_methods_screen.dart';
import 'package:nodo/features/menu/settings/payments%20and%20billings/your_income_screen.dart';
import 'package:nodo/features/menu/settings/preferences_screen.dart';
import 'package:nodo/features/menu/settings/profile/edit_profile_screen.dart';
import 'package:nodo/features/menu/settings/profile/profile_screen.dart';
import 'package:nodo/features/menu/settings/settings_screen.dart';
import 'package:nodo/features/menu/work_wt_nodo_screen.dart';
import 'package:nodo/features/posts/logic/posts_controller.dart';
import 'package:nodo/features/posts/logic/posts_service.dart';
import 'package:nodo/features/register/logic/profile_picture_controller.dart';
import 'package:nodo/features/register/logic/register_controller.dart';
import 'package:nodo/features/trabajos/screens/jobs_dashboard_screen.dart';
import 'package:nodo/features/trabajos/screens/thanks_screen.dart';
import 'package:nodo/core/services/notification_service.dart';
import 'package:nodo/shared/providers/categorie_provider.dart';
import 'package:nodo/shared/providers/general_category_provider.dart';
import 'package:nodo/shared/providers/location_provider.dart';
import 'package:nodo/shared/providers/register_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/features/login/screens/login_screen.dart';
import 'package:nodo/features/welcome/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/providers/user_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Configuración de rutas nombradas
abstract class AppRoutes {
  static const welcome = '/welcome';
  static const login = '/login';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Configura la clave global antes de inicializar NotificationService
  NotificationService.navigatorKey = GlobalKey<NavigatorState>();
  await NotificationService.requestPermissions();
  await NotificationService.initialize();
  //await NotificacionService.instance.initialize();
  // Inicialización para Android y iOS
  final firstTime = await isFirstTime();
  //Firebase Cloud Messaging para las notificaciones push

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(
            create: (_) =>
                CreatePostController(CreatePostService())),
        ChangeNotifierProvider(
          create: (context) => PostsController(
            PostsService(
              Provider.of<UserProvider>(context, listen: false),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterController(),
        ),
        ChangeNotifierProvider(create: (_) => ProfilePictureController()),
        ChangeNotifierProvider(create: (_) => CategorieProvider()),
        ChangeNotifierProvider(create: (_) => GeneralCategoryProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),

      ],
      child: MyApp(firstTime: firstTime),
    ),
  );
}

Future<bool> isFirstTime() async {
  //return true; // Temporalmente para pruebas
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool('seen_welcome') ?? false);
}

class MyApp extends StatelessWidget {
  final bool firstTime;
  const MyApp({super.key, required this.firstTime});
  //const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategorieProvider>(context, listen: false).cargarCategorias();
      Provider.of<GeneralCategoryProvider>(context, listen: false).cargarCategorias();
      Provider.of<LocationProvider>(context, listen: false).cargarUbicaciones();
    });

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: NotificationService.navigatorKey, // Usa la misma clave
          debugShowCheckedModeBanner: false,
          title: 'Nodo App',

          //idioma de la app
          locale: const Locale('es', 'ES'),
          supportedLocales: const [
            Locale('es', 'MX'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme: /*ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
            useMaterial3: true,
          ),*/
              appTheme,
          // home: const Welcome1Screen(),
          // Lógica firstTime mantenida
          initialRoute: firstTime ? AppRoutes.welcome : AppRoutes.login,
          //home: firstTime ? const Welcome1Screen() : const LoginScreen(),
          // Sistema de rutas combinado
          routes: {
            AppRoutes.welcome: (context) => const WelcomeScreen(),
            AppRoutes.login: (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/trabajos2': (context) => const JobsDashboardScreen(),
            '/trabajos5': (context) => const ThanksScreen(),
            '/gracias': (context) => ThanksScreen(),
            '/workWNodo': (context) => const WorkWtNodo(),
            '/SettingsScreen': (context) => const SettingsScreen(),
            '/AccountProfileScreen': (context) => const AccountProfileScreen(),
            '/PreferencesScreen': (context) => const PreferencesScreen(),
            '/ProfileScreen': (context) => const ProfileScreen(),
            '/editProfile': (context) => const EditProfileScreen(),
            '/NotificationSettingsScreen': (context) =>
                const NotificationSettingsScreen(),
            '/SecuritysScreen': (context) => const SecuritysScreen(),
            '/PaymentsBillings': (context) => const PaymentsBillings(),
            '/YourIncome': (context) => const YourIncome(),
            '/CommissionsFeesScreen': (context) =>
                const CommissionsFeesScreen(),
            '/PaymentsMethods': (context) => const PaymentsMethods(),
            '/CommissionCalculatorScreen': (context) =>
                const CommissionCalculatorScreen(),
            '/About': (context) => const About(),
            '/Credits': (context) => const Credits(),
          },
        );
      },
    );
  }
}
