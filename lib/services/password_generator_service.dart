import 'dart:math';

class PasswordGeneratorService {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  String generatePassword({
    required int length,
    required bool includeUppercase,
    required bool includeLowercase,
    required bool includeNumbers,
    required bool includeSpecial,
  }) {
    if (length < 4) {
      throw Exception('Password length must be at least 4 characters');
    }

    if (!includeUppercase &&
        !includeLowercase &&
        !includeNumbers &&
        !includeSpecial) {
      throw Exception('At least one character type must be selected');
    }

    String chars = '';
    if (includeLowercase) chars += _lowercase;
    if (includeUppercase) chars += _uppercase;
    if (includeNumbers) chars += _numbers;
    if (includeSpecial) chars += _special;

    final random = Random.secure();
    List<String> password = [];

    // Ensure at least one character of each selected type
    if (includeLowercase) {
      password.add(_lowercase[random.nextInt(_lowercase.length)]);
    }
    if (includeUppercase) {
      password.add(_uppercase[random.nextInt(_uppercase.length)]);
    }
    if (includeNumbers) password.add(_numbers[random.nextInt(_numbers.length)]);
    if (includeSpecial) password.add(_special[random.nextInt(_special.length)]);

    // Fill the rest randomly
    while (password.length < length) {
      password.add(chars[random.nextInt(chars.length)]);
    }

    // Shuffle the password
    password.shuffle(random);

    return password.join();
  }
}
