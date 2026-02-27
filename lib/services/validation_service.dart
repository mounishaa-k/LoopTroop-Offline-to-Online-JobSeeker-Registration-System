class ValidationService {
  static final RegExp _emailRegex =
      RegExp(r'^[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}$');

  static final RegExp _phoneRegex = RegExp(r'^\+?[\d\s\-().]{7,20}$');

  static bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());

  static bool isValidPhone(String phone) => _phoneRegex.hasMatch(phone.trim());

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    return isValidEmail(value) ? null : 'Invalid email format';
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    return isValidPhone(value) ? null : 'Invalid phone format';
  }

  static String? validateRequired(String? value, [String field = 'Field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }
}
