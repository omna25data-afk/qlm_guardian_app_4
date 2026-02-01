import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/core/config/app_config.dart';
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/providers/auth_provider.dart';
import 'package:guardian_app/providers/dashboard_provider.dart';
import 'package:guardian_app/providers/record_book_provider.dart';
import 'package:guardian_app/providers/registry_entry_provider.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';
import 'package:guardian_app/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:guardian_app/features/records/data/repositories/records_repository.dart';
import 'package:guardian_app/features/registry/data/repositories/registry_repository.dart';
import 'package:guardian_app/screens/login_screen.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_dashboard_repository.dart';
import 'package:guardian_app/providers/admin_dashboard_provider.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_guardian_repository.dart';
import 'package:guardian_app/providers/admin_guardians_provider.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_renewals_repository.dart';
import 'package:guardian_app/providers/admin_renewals_provider.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_areas_repository.dart';
import 'package:guardian_app/providers/admin_areas_provider.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_assignments_repository.dart';
import 'package:guardian_app/providers/admin_assignments_provider.dart';
import 'package:provider/provider.dart';

void mainCommon(AppConfig config) {
  // Initialize API Constants with the environment-specific URL
  ApiConstants.init(config.apiBaseUrl);

  // Create repositories
  final authRepository = AuthRepository();
  final dashboardRepository = DashboardRepository(authRepository: authRepository);
  final recordsRepository = RecordsRepository(authRepository: authRepository);
  final registryRepository = RegistryRepository(authRepository: authRepository);
  final adminDashboardRepository = AdminDashboardRepository(authRepository);

  runApp(MyApp(
    config: config,
    authRepository: authRepository,
    dashboardRepository: dashboardRepository,
    recordsRepository: recordsRepository,
    registryRepository: registryRepository,
    adminDashboardRepository: adminDashboardRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AppConfig config;
  final AuthRepository authRepository;
  final DashboardRepository dashboardRepository;
  final RecordsRepository recordsRepository;
  final RegistryRepository registryRepository;
  final AdminDashboardRepository adminDashboardRepository;

  const MyApp({
    super.key, 
    required this.config,
    required this.authRepository,
    required this.dashboardRepository,
    required this.recordsRepository,
    required this.registryRepository,
    required this.adminDashboardRepository,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(dashboardRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordBookProvider(recordsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => RegistryEntryProvider(registryRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminDashboardProvider(adminDashboardRepository),
        ),
        Provider<AdminGuardianRepository>(
          create: (_) => AdminGuardianRepository(authRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => AdminGuardiansProvider(
            Provider.of<AdminGuardianRepository>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminRenewalsProvider(
            AdminRenewalsRepository(authRepository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminAreasProvider(
            AdminAreasRepository(baseUrl: config.apiBaseUrl),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminAssignmentsProvider(
            AdminAssignmentsRepository(baseUrl: config.apiBaseUrl),
          ),
        ),
      ],
      child: MaterialApp(
        title: config.appName, // Use dynamic App Name
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006400),
            primary: const Color(0xFF006400),
            secondary: const Color(0xFF004d00),
          ),
          scaffoldBackgroundColor: Colors.grey[50],
          fontFamily: GoogleFonts.tajawal().fontFamily,
          textTheme: GoogleFonts.tajawalTextTheme(textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF006400),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          useMaterial3: true,
        ),
        // Add a Banner for Dev Mode
        builder: (context, child) {
          child = Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
          
          if (config.isDev) {
            return Banner(
              message: 'تجريـــب',
              location: BannerLocation.topStart,
              color: Colors.red,
              child: child,
            );
          }
          return child;
        },
        home: const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}
