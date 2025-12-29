import 'package:flutter/material.dart';
import 'package:blood_linker/core/exceptions/app_exceptions.dart';

class FormValidator {
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    if (!RegExp(emailRegex).hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? bloodType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Blood type is required';
    }
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }

    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 18 || age > 100) {
      return 'Age must be between 18 and 100';
    }
    return null;
  }

  static String? bagsNeeded(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number of bags is required';
    }

    final bags = int.tryParse(value.trim());
    if (bags == null) {
      return 'Please enter a valid number';
    }
    if (bags < 1 || bags > 50) {
      return 'Number of bags must be between 1 and 50';
    }
    return null;
  }
}

class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException(String message, {this.fieldErrors = const {}})
    : super(message);

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (fieldErrors.isNotEmpty) {
      buffer.writeln();
      for (final entry in fieldErrors.entries) {
        buffer.writeln('• ${entry.key}: ${entry.value}');
      }
    }
    return buffer.toString();
  }
}

class FormFieldValidator<T> {
  final String? Function(T?) validator;
  final String? fieldName;

  const FormFieldValidator(this.validator, {this.fieldName});

  String? call(T? value) {
    return validator(value);
  }
}
