import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';

class OTPInputField extends StatefulWidget {
  final Function(String) onCompleted;
  final int length;
  final TextEditingController? controller;

  const OTPInputField({
    super.key,
    required this.onCompleted,
    this.length = 4,
    this.controller,
  });

  @override
  State<OTPInputField> createState() => _OTPInputFieldState();
}

class _OTPInputFieldState extends State<OTPInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );

    // Listen to external controller if provided
    widget.controller?.addListener(_updateFromExternalController);
  }

  void _updateFromExternalController() {
    final text = widget.controller?.text ?? '';
    for (int i = 0; i < widget.length && i < text.length; i++) {
      _controllers[i].text = text[i];
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updateFromExternalController);
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field - unfocus and check if complete
        _focusNodes[index].unfocus();
      }
    }

    // Update external controller
    final otp = _controllers.map((c) => c.text).join();
    widget.controller?.text = otp;

    // Check if all fields are filled
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  void _onKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // Move to previous field on backspace
          _focusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => _buildOTPBox(index),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 60,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? AppColors.brandBlue
              : Colors.grey[300]!,
          width: _focusNodes[index].hasFocus ? 2 : 1.5,
        ),
        boxShadow: _focusNodes[index].hasFocus
            ? [
                BoxShadow(
                  color: AppColors.brandBlue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onKeyEvent(event, index),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) => _onChanged(value, index),
        ),
      ),
    );
  }
}

