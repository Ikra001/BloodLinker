import 'package:flutter/material.dart';

class Constants {
  static const String appName = 'BloodLinker';
  static const Color primaryColor = Color(0xFFB71C1C); // dark red
  static const Color secondaryColor = Color(0xFFE57373); // light red
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static const List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Common InputDecoration for rounded form fields
  static InputDecoration roundedInputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  // Common ElevatedButton style
  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  // Common validation: Required field
  static String? requiredValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Common validation: Email
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email';
    }
    return null;
  }
}
