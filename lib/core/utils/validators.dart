import 'package:campus_connect/core/constants/app_constants.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    if (!value.trim().toLowerCase().endsWith(AppConstants.allowedEmailDomain)) {
      return 'Only ${AppConstants.allowedEmailDomain} emails are allowed';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
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

  static String? budget(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Budget is required';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Enter a valid amount';
    }
    if (amount < AppConstants.minBudget) {
      return 'Minimum budget is ₹${AppConstants.minBudget.toInt()}';
    }
    if (amount > AppConstants.maxBudget) {
      return 'Maximum budget is ₹${AppConstants.maxBudget.toInt()}';
    }
    return null;
  }

  static String? bidAmount(String? value, double gigBudget) {
    if (value == null || value.trim().isEmpty) {
      return 'Bid amount is required';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Enter a valid amount';
    }
    if (amount < AppConstants.minBudget) {
      return 'Minimum bid is ₹${AppConstants.minBudget.toInt()}';
    }
    if (amount > gigBudget * 1.5) {
      return 'Bid cannot exceed 150% of the gig budget';
    }
    return null;
  }

  static String? deliveryDays(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Delivery days is required';
    }
    final days = int.tryParse(value.trim());
    if (days == null || days < 1) {
      return 'Enter a valid number of days (min 1)';
    }
    if (days > 90) {
      return 'Delivery cannot exceed 90 days';
    }
    return null;
  }

  static String? hourlyRate(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final rate = double.tryParse(value.trim());
    if (rate == null) {
      return 'Enter a valid hourly rate';
    }
    if (rate < 0) {
      return 'Rate cannot be negative';
    }
    if (rate > 10000) {
      return 'Rate seems too high. Max ₹10,000/hr';
    }
    return null;
  }
}
