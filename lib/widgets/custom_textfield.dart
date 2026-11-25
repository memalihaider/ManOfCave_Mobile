import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class CustomTextfield extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool isPass;
  final Icon prefixIcon;
  final TextInputType textInputType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function()? onTap;
  final bool readOnly;
  final int? maxLines;
  final bool enabled;

  const CustomTextfield({
    super.key,
    required this.hintText,
    required this.controller,
    this.isPass = false,
    this.suffixIcon,
    required this.prefixIcon,
    this.textInputType = TextInputType.text,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<CustomTextfield> createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  bool isObscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPass ? isObscure : false,
      keyboardType: widget.textInputType,
      validator: widget.validator,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      style: TextStyle(
        fontSize: AppSizes.font(16),
      ),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: widget.prefixIcon,
        labelStyle: TextStyle(
          color: AppColors.primaryGold,
          fontSize: AppSizes.font(16),
        ),
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontSize: AppSizes.font(16),
          color: Colors.grey[600],
        ),
        suffixIcon: widget.isPass
            ? IconButton(
          onPressed: () {
            setState(() {
              isObscure = !isObscure;
            });
          },
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.surfaceLight,
            size: AppSizes.iconSmall18,
          ),
          padding: EdgeInsets.zero,
          iconSize: AppSizes.iconSmall18,
        )
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryGold, width: AppSizes.width(1.5)),
          borderRadius: BorderRadius.all(
            Radius.circular(AppSizes.radius(8)),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border, width: AppSizes.width(1.5)),
          borderRadius: BorderRadius.all(
            Radius.circular(AppSizes.radius(8)),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}