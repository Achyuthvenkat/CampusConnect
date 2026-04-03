class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    if (!value.endsWith('.edu') &&
        !value.contains('college') &&
        !value.contains('university') &&
        !value.contains('ac.in')) {
      return 'Please use your college email address (.edu or college/university domain)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    return null;
  }

  static String? validateBudget(String? value) {
    if (value == null || value.isEmpty) return 'Budget is required';
    final budget = double.tryParse(value);
    if (budget == null) return 'Enter a valid number';
    if (budget < 5) return 'Minimum budget is \$5';
    return null;
  }
}
