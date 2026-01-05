import 'package:flutter/material.dart';
import 'app_colors.dart';

class LightAppTheme {
    static final lightTheme = ThemeData(

        splashFactory: InkRipple.splashFactory,
        splashColor: AppColors.brandBlue.withOpacity(0.3),

        colorScheme: const ColorScheme.light(
          primary: AppColors.brandBlue,
          onPrimary: AppColors.white,
          surface: AppColors.white,
          error: AppColors.errorRed,
        ),
        useMaterial3: true,

       
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(  
          unselectedItemColor: AppColors.grey,
          selectedItemColor: AppColors.brandBlue,
          showUnselectedLabels: true,
          
        ),
        

        elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 46),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            
          ),
        ),
      ),
      );


      
}