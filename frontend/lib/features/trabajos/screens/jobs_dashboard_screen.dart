import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/trabajos/screens/job_detail_screen.dart';
import 'package:nodo/features/trabajos/screens/category_filter_screen.dart';
import 'package:nodo/features/posts/utils/post_format_utils.dart';
import 'package:nodo/features/trabajos/logic/job_filter.dart';
import 'package:nodo/features/trabajos/logic/job_service.dart';
import 'package:nodo/features/trabajos/widgets/joblist.dart';
import 'package:nodo/features/trabajos/widgets/postulacion_list.dart';
import 'package:nodo/shared/providers/user_provider.dart';
import 'package:provider/provider.dart';

class JobsDashboardScreen extends StatefulWidget {
  const JobsDashboardScreen({super.key});

  @override
  State<JobsDashboardScreen> createState() => _JobsDashboardScreenState();
}

class _JobsDashboardScreenState extends State<JobsDashboardScreen> {
  List<dynamic> _publicaciones = [];
  Map<String, String> _nombresClientes = {};
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _postulaciones = [];
  bool _isLoadingPostulaciones = true;
  String _errorMessagePostulaciones = '';
  int _selectedTab = 0;
  JobFilter _filter = const JobFilter();

  static const _tabs = [
    (label: 'Disponibles', icon: Icons.search_rounded),
    (label: 'Postulaciones', icon: Icons.send_outlined),
    (label: 'Mis trabajos', icon: Icons.construction_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadData();
    await _loadPostulaciones();
  }

  Future<void> _loadData() async {
    final currentId =
        Provider.of<UserProvider>(context, listen: false).user?.id;
    if (currentId == null) return;
    try {
      final publicaciones =
          await JobService.fetchPostsForWorker(currentId);
      final nombres = await JobService.fetchClientNames(publicaciones);
      if (!mounted) return;
      setState(() {
        _publicaciones = publicaciones;
        _nombresClientes = nombres;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _loadPostulaciones() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentId = userProvider.user?.id;
    if (currentId == null) return;
    try {
      final postulaciones =
          await JobService.fetchApplicationsByUser(currentId);
      if (!mounted) return;
      setState(() {
        _postulaciones = postulaciones;
        _isLoadingPostulaciones = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPostulaciones = false;
        _errorMessagePostulaciones = 'Error: $e';
      });
    }
  }

  List<dynamic> _applyFilter(List<dynamic> posts) {
    if (!_filter.isActive) return posts;
    return posts.where((pub) {
      // Categoría
      if (_filter.categoryIds.isNotEmpty) {
        final cats = (pub['categories'] as List?) ?? [];
        final ids = cats
            .map((c) => c['specificCategoryId'].toString())
            .toSet();
        if (!_filter.categoryIds.any((id) => ids.contains(id))) return false;
      }
      // Ubicación
      if (_filter.location != null) {
        final loc = (pub['location'] ?? '').toString().toLowerCase();
        if (!loc.contains(_filter.location!.toLowerCase())) return false;
      }
      // Precio
      final budget = (pub['budget'] as num?)?.toDouble() ?? 0;
      if (_filter.minPrice != null && budget < _filter.minPrice!) return false;
      if (_filter.maxPrice != null &&
          _filter.maxPrice! > 0 &&
          budget > _filter.maxPrice!) {
        return false;
      }
      // Tiempo de publicación
      if (_filter.timeFilter != null) {
        final postDate = DateTime.tryParse(pub['postDate'] ?? '');
        if (postDate != null) {
          final now = DateTime.now();
          switch (_filter.timeFilter) {
            case 'Última Hora':
              if (now.difference(postDate).inHours >= 1) return false;
              break;
            case 'Hoy':
              if (!_isSameDay(postDate, now)) return false;
              break;
            case 'Esta semana':
              if (now.difference(postDate).inDays >= 7) return false;
              break;
          }
        }
      }
      // Fecha límite
      if (_filter.dateRange != null) {
        final deadline = DateTime.tryParse(pub['deadline'] ?? '');
        if (deadline == null) return false;
        if (deadline.isBefore(_filter.dateRange!.start)) return false;
        if (deadline.isAfter(
            _filter.dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _mostrarDetalleTrabajo(dynamic publicacion, String nombreCliente,
      Map<String, dynamic>? postulacion, bool desdePostulaciones) {
    final categories = (publicacion['categories'] as List?) ?? [];
    final firstCategoryId = categories.isNotEmpty
        ? categories[0]['specificCategoryId'].toString()
        : '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(
          job: {
            "id": publicacion['id'],
            "title": publicacion['title'],
            "description": publicacion['description'],
            "price": "\$${formatBudget(publicacion['budget'])}",
            "location": "${publicacion['location']}",
            "user": "Nombre del cliente: $nombreCliente",
            "time":
                "${JobService.formatTimeAgo(publicacion['postDate'])} · ${publicacion['status']}",
            "image": JobService.getIconForCategory(firstCategoryId),
            "images": _parseImages(publicacion['photos']),
          },
          postulacion: postulacion,
          desdePostulaciones: desdePostulaciones,
          onPostulacionCambiada: _loadAllData,
        ),
      ),
    );
  }

  void _mostrarDetalleDesdePostulacion(dynamic publicacion, String _) {
    final idCliente = publicacion['clientId'];
    final postulacion = _postulaciones.firstWhere(
      (p) => p['postId'] == publicacion['id'],
      orElse: () => null,
    );
    final nombreCliente =
        _nombresClientes[idCliente.toString()] ?? 'Cliente';
    _mostrarDetalleTrabajo(publicacion, nombreCliente, postulacion, true);
  }

  List<String> _parseImages(dynamic photos) {
    if (photos is List && photos.isNotEmpty) {
      return photos.map((url) => url.toString()).toList();
    }
    return ['assets/images/diomedes_joven.jpg'];
  }

  @override
  Widget build(BuildContext context) {
    final disponiblesRaw = _publicaciones
        .where((pub) => !_postulaciones.any((p) => p['postId'] == pub['id']))
        .toList();
    final disponiblesCount = _applyFilter(disponiblesRaw).length;
    // Salen de las mismas listas que se muestran, sin contar las que ya no
    // están disponibles: así el número siempre coincide con lo que se ve.
    final postulacionesCount =
        _contarDisponibles(_postulacionItems((s) => !_esTrabajo(s)));
    final misTrabajosCount = _contarDisponibles(_postulacionItems(_esTrabajo));
    final counts = [disponiblesCount, postulacionesCount, misTrabajosCount];

    return Scaffold(
      backgroundColor: Color.alphaBlend(
          AppColors.blue.withValues(alpha: 0.03), Colors.white),
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabs(counts),
          Expanded(child: _buildTabBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isLoadingAny = _isLoading || _isLoadingPostulaciones;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20.w, MediaQuery.of(context).padding.top + 16.h, 16.w, 20.h),
      decoration: const BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trabajos',
                    style:
                        AppTypography.title.copyWith(color: AppColors.white)),
                SizedBox(height: 4.h),
                Text(
                  'Encuentra oportunidades cerca de ti',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.filter_alt_outlined,
                    color: AppColors.white, size: 22.r),
                onPressed: () async {
                  final result =
                      await showModalBottomSheet<JobFilter>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CategoryFilterScreen(
                      initialFilter: _filter,
                    ),
                  );
                  if (result != null && mounted) {
                    setState(() => _filter = result);
                  }
                },
              ),
              if (_filter.isActive)
                Positioned(
                  top: 8.r,
                  right: 8.r,
                  child: Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: isLoadingAny
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded,
                    color: AppColors.white, size: 22.r),
            onPressed: isLoadingAny ? null : _loadAllData,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(List<int> counts) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedTab == i;
          final count = counts[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          _tabs[i].icon,
                          size: 18.r,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.blue.withValues(alpha: 0.5),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -4,
                            right: -8,
                            child: Container(
                              padding: EdgeInsets.all(2.r),
                              constraints: BoxConstraints(
                                  minWidth: 14.r, minHeight: 14.r),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.orange
                                    : AppColors.blue.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontFamily: 'GothamBold',
                                  fontSize: 8.sp,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.blue,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _tabs[i].label,
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.blue.withValues(alpha: 0.6),
                        fontFamily:
                            isSelected ? 'GothamMedium' : 'GothamBook',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabBody() {
    return IndexedStack(
      index: _selectedTab,
      children: [
        _buildJobList(),
        _buildPostulacionesList(),
        _buildMisTrabajosList(),
      ],
    );
  }

  Widget _buildJobList() {
    final disponibles = _applyFilter(
      _publicaciones
          .where((pub) =>
              !_postulaciones.any((p) => p['postId'] == pub['id']))
          .toList(),
    );

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.orange,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _errorState(_errorMessage)
              : disponibles.isEmpty
                  ? _emptyState(
                      Icons.search_off_outlined,
                      _filter.isActive
                          ? 'Sin resultados'
                          : 'Sin trabajos disponibles',
                      _filter.isActive
                          ? 'Ningún trabajo coincide con los filtros aplicados. Prueba ajustándolos.'
                          : 'No hay solicitudes publicadas en este momento. Vuelve más tarde.',
                    )
                  : JobList(
                      publicaciones: disponibles,
                      nombresClientes: _nombresClientes,
                      onVerDetalles: (pub, nombre) =>
                          _mostrarDetalleTrabajo(pub, nombre, null, false),
                    ),
    );
  }

  static bool _esTrabajo(String status) =>
      status == 'accepted' || status == 'finished';

  static bool _disponible(Map<String, dynamic> item) =>
      item['pub']['available'] != false;

  static int _contarDisponibles(List<Map<String, dynamic>> items) =>
      items.where(_disponible).length;

  /// Cada postulación trae su publicación en `post`. No se buscan en
  /// `_publicaciones`: ese feed solo tiene los rubros actuales del trabajador
  /// y las publicaciones de cuentas activas, y lo que no aparece ahí se perdía.
  /// Las que ya no están disponibles van al final.
  List<Map<String, dynamic>> _postulacionItems(
      bool Function(String status) incluir) {
    final items = _postulaciones
        .where((p) =>
            p['post'] != null && incluir(p['status']?.toString() ?? ''))
        .map((p) => <String, dynamic>{'pub': p['post'], 'postulacion': p})
        .toList();
    final disponibles = items.where(_disponible);
    final noDisponibles = items.where((i) => !_disponible(i));
    return [...disponibles, ...noDisponibles];
  }

  Widget _buildPostulacionesList() {
    final items = _postulacionItems((s) => !_esTrabajo(s));

    return RefreshIndicator(
      onRefresh: _loadPostulaciones,
      color: AppColors.orange,
      child: _isLoadingPostulaciones
          ? const Center(child: CircularProgressIndicator())
          : _errorMessagePostulaciones.isNotEmpty
              ? _errorState(_errorMessagePostulaciones)
              : items.isEmpty
                  ? _emptyState(
                      Icons.send_outlined,
                      'Aún no te has postulado',
                      'Explora los trabajos disponibles y postúlate para comenzar.',
                    )
                  : PostulacionList(
                      items: items,
                      onVerDetalles: (pub, postulacion, nombre) =>
                          _mostrarDetalleTrabajo(
                              pub, nombre, postulacion, true),
                    ),
    );
  }

  Widget _buildMisTrabajosList() {
    final items = _postulacionItems(_esTrabajo);

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.orange,
      child: _isLoadingPostulaciones
          ? const Center(child: CircularProgressIndicator())
          : _errorMessagePostulaciones.isNotEmpty
              ? _errorState(_errorMessagePostulaciones)
              : items.isEmpty
                  ? _emptyState(
                      Icons.construction_outlined,
                      'Sin trabajos asignados',
                      'Cuando un cliente te acepte, el trabajo aparecerá aquí.',
                    )
                  : PostulacionList(
                      items: items,
                      onVerDetalles: (pub, postulacion, nombre) =>
                          _mostrarDetalleTrabajo(
                              pub, nombre, postulacion, true),
                    ),
    );
  }

  Widget _emptyState(IconData icon, String title, String description) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 60.h),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      size: 52.r,
                      color: AppColors.blue.withValues(alpha: 0.3)),
                ),
                SizedBox(height: 20.h),
                Text(title,
                    style: AppTypography.subtitle
                        .copyWith(color: AppColors.blue.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center),
                SizedBox(height: 10.h),
                Text(description,
                    style:
                        AppTypography.body.copyWith(color: AppColors.slateGrey),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 60.h),
        Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 48.r, color: AppColors.slateGrey),
                SizedBox(height: 12.h),
                Text(message,
                    style: AppTypography.body
                        .copyWith(color: AppColors.slateGrey),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
