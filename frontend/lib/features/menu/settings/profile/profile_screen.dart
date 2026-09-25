import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/features/posts/screens/posts_screen.dart';
import 'package:nodo/features/rating/logic/rating_service.dart';
import 'package:nodo/shared/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double? _workerAvg;
  int _workerCount = 0;
  double? _clientAvg;
  int _clientCount = 0;
  bool _loadingRatings = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRatings());
  }

  Future<void> _loadRatings() async {
    final userId =
        Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
    if (userId.isEmpty) {
      setState(() => _loadingRatings = false);
      return;
    }
    final data = await RatingService.getUserRatings(userId);
    if (!mounted) return;
    setState(() {
      _loadingRatings = false;
      if (data != null) {
        final w = data['asWorker'] as Map<String, dynamic>?;
        final c = data['asClient'] as Map<String, dynamic>?;
        _workerAvg = (w?['avg'] as num?)?.toDouble();
        _workerCount = (w?['count'] as num?)?.toInt() ?? 0;
        _clientAvg = (c?['avg'] as num?)?.toDouble();
        _clientCount = (c?['count'] as num?)?.toInt() ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    final esTrabajador = user.tipoUsuario == 'trabajador';

    return Scaffold(
      backgroundColor:
          Color.alphaBlend(AppColors.blue.withValues(alpha: 0.03), Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, user),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameCard(user, esTrabajador),
                  SizedBox(height: 14.h),

                  _buildCard(
                    title: "Información de contacto",
                    icon: Icons.contact_mail_outlined,
                    child: Column(
                      children: [
                        _buildInfoRow(
                            Icons.email_outlined, "Correo", user.email),
                        _buildInfoRow(Icons.phone_outlined,
                            "Número de contacto", user.telefono),
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          "Ubicación",
                          (user.ubicacion is String &&
                                  (user.ubicacion as String).isNotEmpty)
                              ? user.ubicacion
                              : 'No especificada',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  _buildCard(
                    title: "Descripción",
                    icon: Icons.notes_outlined,
                    child: Text(
                      (user.descripcion is String &&
                              (user.descripcion as String).isNotEmpty)
                          ? user.descripcion
                          : "No hay descripción disponible",
                      style: AppTypography.label
                          .copyWith(color: AppColors.blue.withValues(alpha: 0.85)),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                  if (esTrabajador && user.categorias.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    _buildCard(
                      title: "Rubros",
                      icon: Icons.work_outline,
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: user.categorias
                            .map(
                              (categoria) => Chip(
                                label: Text(
                                  categoria.name,
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.blue),
                                ),
                                backgroundColor:
                                    AppColors.blue.withValues(alpha: 0.06),
                                side: BorderSide(
                                    color: AppColors.blue.withValues(alpha: 0.3)),
                                shape: const StadiumBorder(),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],

                  SizedBox(height: 14.h),
                  _buildCard(
                    title: "Estadísticas",
                    icon: Icons.bar_chart_outlined,
                    child: Column(
                      children: [
                        if (esTrabajador) ...[
                          _buildStatRow(
                            Icons.assignment_outlined,
                            "Publicaciones en las que te has postulado",
                            null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const PostsScreen()),
                              );
                            },
                          ),
                          _buildStatRow(
                            Icons.task_alt_outlined,
                            "Trabajos completados",
                            (user.trabajosCompletados ?? 0).toString(),
                          ),
                        ],
                        _buildStatRow(
                          Icons.calendar_today_outlined,
                          "Miembro desde",
                          formatDate(user.fechaRegistro),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _buildCard(
                    title: "Insignias",
                    icon: Icons.military_tech_outlined,
                    child: Text(
                      "Las insignias son un modo de reconocer los logros de nuestros usuarios. Otros usuarios podrán verlas. Será una función que agregaremos próximamente ;)",
                      style: AppTypography.caption
                          .copyWith(color: AppColors.blue.withValues(alpha: 0.7)),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Container(height: 110.h, width: double.infinity, color: AppColors.blue),
                  Container(height: 10.h, width: double.infinity, color: AppColors.orange),
                ],
              ),
              Positioned(
                top: 12.h,
                left: 5.w,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: AppColors.blue, shape: BoxShape.circle),
                    padding: EdgeInsets.all(8.r),
                    child: Icon(Icons.arrow_back_sharp,
                        color: AppColors.white, size: 20.r),
                  ),
                ),
              ),
              Positioned(
                top: 12.h,
                right: 5.w,
                child: IconButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    elevation: 1,
                  ),
                  icon: Icon(Icons.edit_outlined, color: AppColors.white, size: 18.r),
                  onPressed: () => Navigator.pushNamed(context, '/editProfile'),
                ),
              ),
              Positioned(
                top: 80.h,
                left: 16.w,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                      color: AppColors.white, shape: BoxShape.circle),
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final fotoPerfil = userProvider.user?.fotoPerfil;
                      return CircleAvatar(
                        radius: 40.r,
                        backgroundColor: AppColors.blue.withValues(alpha: 0.06),
                        backgroundImage:
                            (fotoPerfil != null && fotoPerfil.isNotEmpty)
                                ? NetworkImage(fotoPerfil)
                                : null,
                        child: (fotoPerfil == null || fotoPerfil.isEmpty)
                            ? Padding(
                                padding: EdgeInsets.all(20.r),
                                child: Image.asset('assets/icons/iconNodoBlue.png',
                                    fit: BoxFit.contain),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 64.h),
      ],
    );
  }

  // ── Name card con calificaciones por rol ──────────────────────────────────

  Widget _buildNameCard(dynamic user, bool esTrabajador) {
    final nombreCompleto =
        '${user.nombres} ${user.primerApellido} ${user.segundoApellido}'.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombreCompleto,
              style: AppTypography.subtitle.copyWith(color: AppColors.blue)),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              esTrabajador ? 'Trabajador' : 'Cliente',
              style: AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ),
          SizedBox(height: 14.h),
          Divider(color: AppColors.slateGrey.withValues(alpha: 0.2), height: 1),
          SizedBox(height: 12.h),
          _loadingRatings
              ? Center(
                  child: SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.blue),
                  ),
                )
              : Column(
                  children: [
                    // Solo mostrar "como trabajador" si es trabajador
                    if (esTrabajador)
                      _buildRatingRow(
                        icon: Icons.construction_outlined,
                        label: 'Como trabajador',
                        avg: _workerAvg,
                        count: _workerCount,
                      ),
                    if (esTrabajador) SizedBox(height: 8.h),
                    _buildRatingRow(
                      icon: Icons.person_outline,
                      label: 'Como cliente',
                      avg: _clientAvg,
                      count: _clientCount,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildRatingRow({
    required IconData icon,
    required String label,
    required double? avg,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.blue.withValues(alpha: 0.6)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(label,
              style: AppTypography.caption.copyWith(color: AppColors.slateGrey)),
        ),
        if (avg != null) ...[
          Icon(Icons.star_rounded, color: AppColors.orange, size: 14.sp),
          SizedBox(width: 3.w),
          Text(
            avg.toStringAsFixed(1),
            style: AppTypography.label.copyWith(color: AppColors.blue),
          ),
          SizedBox(width: 4.w),
          Text(
            '($count)',
            style: AppTypography.caption.copyWith(color: AppColors.slateGrey),
          ),
        ] else
          Text(
            'Sin calificaciones',
            style: AppTypography.caption.copyWith(color: AppColors.slateGrey),
          ),
      ],
    );
  }

  // ── Helpers reutilizables ─────────────────────────────────────────────────

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.r, color: AppColors.blue),
              SizedBox(width: 6.w),
              Text(title,
                  style: AppTypography.label.copyWith(color: AppColors.blue)),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.r, color: AppColors.orange),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.slateGrey)),
                Text(value,
                    style: AppTypography.body.copyWith(color: AppColors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String? value,
      {bool isLast = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(icon, size: 18.r, color: AppColors.orange),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(label,
                  style: AppTypography.label.copyWith(color: AppColors.blue)),
            ),
            if (value != null)
              Text(value,
                  style: AppTypography.body.copyWith(color: AppColors.blue)),
            if (onTap != null)
              Icon(Icons.chevron_right,
                  size: 18.r, color: AppColors.slateGrey),
          ],
        ),
      ),
    );
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('d MMMM y', 'es').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
