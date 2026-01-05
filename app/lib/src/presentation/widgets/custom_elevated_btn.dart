import "package:flutter/material.dart";
import "package:social_stream_next/src/core/theme/app_colors.dart";

class CustomElevatedBtn extends StatelessWidget {

  final String btnText;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomElevatedBtn({
    super.key,
    required this.btnText,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.brandBlue.withOpacity(0.6),
          elevation: 0,
          shadowColor: AppColors.brandBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                btnText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

}