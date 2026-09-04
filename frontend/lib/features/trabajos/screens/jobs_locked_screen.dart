import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';

class JobsLockedScreen extends StatelessWidget {
  const JobsLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color.alphaBlend(AppColors.blue.withValues(alpha: 0.03), Colors.white),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildEmptyState()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20.w, MediaQuery.of(context).padding.top + 16.h, 16.w, 20.h),
      decoration: const BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trabajos',
            style: AppTypography.title.copyWith(color: AppColors.white),
          ),
          SizedBox(height: 4.h),
          Text(
            'Encuentra oportunidades cerca de ti',
            style: AppTypography.caption
                .copyWith(color: AppColors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 52.r,
                color: AppColors.blue.withValues(alpha: 0.3),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Sección exclusiva para trabajadores',
              style:
                  AppTypography.subtitle.copyWith(color: AppColors.orange),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            Text(
              'Aquí podrás gestionar los trabajos en los que te hayas postulado. Conviértete en trabajador y accede a oportunidades laborales.',
              style: AppTypography.body.copyWith(color: AppColors.slateGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
