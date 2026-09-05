import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import '../settings/widgets/settings_sub_header.dart';

final List<TeamMember> team = [
  TeamMember(
    name: 'Kehiber Leandro Morelo Ricardo',
    role: 'Ingeniero Informático',
    image: 'assets/icons/iconNodoBlue.png',
  ),
  TeamMember(
    name: 'Luis Felipe Salgado Manco',
    role: 'Ingeniero Informático',
    image: 'assets/icons/iconNodoBlue.png',
  ),
  TeamMember(
    name: 'Mauricio Martínez Martínez',
    role: 'Ingeniero Informático',
    image: 'assets/icons/iconNodoBlue.png',
  ),
  TeamMember(
    name: 'Tomás Muñoz Galvez',
    role: 'Ingeniero Informático',
    image: 'assets/icons/iconNodoBlue.png',
  ),
];

class TeamMember {
  final String name;
  final String role;
  final String image;
  TeamMember({required this.name, required this.role, required this.image});
}

class Credits extends StatelessWidget {
  const Credits({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color.alphaBlend(AppColors.blue.withValues(alpha: 0.03), Colors.white),
      body: Column(
        children: [
          const SettingsSubHeader(
            title: 'Créditos',
            subtitle: 'Equipo de desarrollo de NODO',
            icon: Icons.people_outline_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.blue,
                          AppColors.blue.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Image.asset('assets/icons/iconNodoBlue.png',
                            width: 48.r, height: 48.r),
                        SizedBox(height: 10.h),
                        Text('NODO',
                            style: AppTypography.title
                                .copyWith(color: Colors.white)),
                        SizedBox(height: 4.h),
                        Text(
                          'Creamos esta plataforma con pasión, propósito y compromiso para ayudarte a conectar y crecer.',
                          style: AppTypography.body
                              .copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _sectionLabel('EQUIPO DE DESARROLLO'),
                  SizedBox(height: 10.h),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(team.length, (i) {
                        final isLast = i == team.length - 1;
                        return Column(
                          children: [
                            _memberTile(team[i]),
                            if (!isLast)
                              Divider(
                                height: 1,
                                indent: 70.w,
                                color: AppColors.slateGrey
                                    .withValues(alpha: 0.15),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _sectionLabel('AGRADECIMIENTOS'),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'A todas las personas que han probado, aportado ideas y creído en NODO desde el inicio.',
                      style: AppTypography.body
                          .copyWith(color: AppColors.slateGrey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Hecho con 🧡 desde las bananeras de Urabá',
                    style: AppTypography.label.copyWith(color: AppColors.blue),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Versión NODO 2025 · Todos los derechos reservados.',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.slateGrey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 4.w),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.slateGrey,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _memberTile(TeamMember member) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              member.image,
              width: 44.r,
              height: 44.r,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: AppTypography.label.copyWith(
                        color: AppColors.blue, fontFamily: 'GothamMedium')),
                SizedBox(height: 2.h),
                Text(member.role,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.slateGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
