import 'package:flutter/material.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/login/screens/login_screen.dart';
import 'package:nodo/shared/widgets/barra_navegacion_widget.dart';
import 'package:nodo/features/create_post/screens/create_post_screen.dart';
import 'package:nodo/features/notifications/screens/notifications_screen.dart';
import 'package:nodo/features/posts/screens/posts_screen.dart';
import 'package:nodo/features/trabajos/screens/jobs_dashboard_screen.dart';
import 'package:nodo/features/trabajos/screens/jobs_locked_screen.dart';
import 'package:nodo/features/posts/logic/posts_controller.dart';
import 'package:nodo/shared/providers/user_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPageIndex = 0;
  late List<Widget> _screens;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeScreens();
      _initialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  void _initializeScreens() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final Widget trabajosScreen =
        userProvider.isWorker ? const JobsDashboardScreen() : const JobsLockedScreen();

    _screens = [
      const PostsScreen(),
      trabajosScreen,
      const NotificationsScreen(),
    ];
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final postsController = Provider.of<PostsController>(context);
    final requestedTab = postsController.requestedHomeTab;
    if (requestedTab != null) {
      postsController.consumeHomeTab();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => currentPageIndex = requestedTab);
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: currentPageIndex,
        children: _screens,
      ),

      //Boton flotante para crear publicación
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75,
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/ProfileScreen');
              },

              //Header
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                  ),
                ),
                child: Row(
                  //Avatar
                  children: [
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final fotoPerfil = userProvider.user?.fotoPerfil;
                        // Si no hay foto de perfil, muestra un icono por defecto
                        return CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.white,
                          backgroundImage:
                              (fotoPerfil != null && fotoPerfil.isNotEmpty)
                                  ? NetworkImage(fotoPerfil)
                                  : null,
                          child: (fotoPerfil == null || fotoPerfil.isEmpty)
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Image.asset(
                                    'assets/icons/iconNodoBlue.png',
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 15),

                    //Datos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("${user?.nombres.split(' ').first}",
                                  style: AppTypography.subtitle
                                      .copyWith(color: AppColors.white)),
                              Text(' ${user?.primerApellido}',
                                  style: AppTypography.subtitle
                                      .copyWith(color: AppColors.white)),
                            ],
                          ),
                          Text(user?.tipoUsuario ?? "Sin tipo",
                              style: AppTypography.label
                                  .copyWith(color: AppColors.white)),
                          const SizedBox(height: 4),
                          if (user?.tipoUsuario == 'trabajador')
                            Text(
                                "${user?.trabajosCompletados ?? 0} trabajos completados",
                                style: AppTypography.label
                                    .copyWith(color: AppColors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            drawerTile(Icons.settings_outlined, "Ajustes", '/SettingsScreen'),
            if (user?.tipoUsuario != 'trabajador')
              drawerTile(Icons.work_outline_sharp, "Trabajar con NODO", '/workWNodo'),
            drawerTile(Icons.info_outlined, "Acerca de", '/About'),
            const Spacer(),
            Divider(color: Colors.grey.shade300),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                onTap: () async {
                  // 1. Cerrar el drawer primero
                  Navigator.of(context).pop();
                  //Navigator.pushNamed(context, '/logout');
                  // 2. Mostrar diálogo de confirmación
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content:
                          const Text('¿Estás seguro que deseas cerrar sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sí, cerrar sesión'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!context.mounted) return;
                    // Muestra un indicador de carga
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => PopScope(
                        canPop: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );

                    // Ejecuta el logout (que ahora incluye toda la limpieza)
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    await userProvider.logout();
                    debugPrint("Usuario desloggeado");
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.power_settings_new_rounded,
                        color: AppColors.blue, size: 20),
                    const SizedBox(width: 5),
                    Text("Cerrar sesión",
                        style: AppTypography.caption
                            .copyWith(color: AppColors.blue)),
                    const Spacer(),
                    Text("Versión 1.0",
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BarraNavegacionWidget(
        currentIndex: currentPageIndex,
        onIndexChanged: (index) {
          setState(() {
            currentPageIndex = index;
          });
        },
      ),
    );
  }

  Widget drawerTile(IconData icon, String title, String routeName) {
    return ListTile(
      horizontalTitleGap: 8,
      leading: Icon(icon, color: AppColors.blue),
      title: Text(title, style: AppTypography.body),
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}
