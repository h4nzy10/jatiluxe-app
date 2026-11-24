class CurrencyFormat {
  static String toRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final numValue = num.tryParse(amount.toString()) ?? 0;
    final isNegative = numValue < 0;
    final absValue = numValue.abs().toInt();

    final digits = absValue.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return '${isNegative ? '- ' : ''}Rp $buffer';
  }
}

class DateFormatHelper {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static String toReadable(dynamic dateInput) {
    if (dateInput == null) return '-';
    DateTime? dt;
    if (dateInput is DateTime) {
      dt = dateInput;
    } else {
      dt = DateTime.tryParse(dateInput.toString());
    }

    if (dt == null) return dateInput.toString();

    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$min';
  }

  static String toDateOnly(dynamic dateInput) {
    if (dateInput == null) return '-';
    DateTime? dt;
    if (dateInput is DateTime) {
      dt = dateInput;
    } else {
      dt = DateTime.tryParse(dateInput.toString());
    }

    if (dt == null) return dateInput.toString();

    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;

    return '$day $month $year';
  }
}
