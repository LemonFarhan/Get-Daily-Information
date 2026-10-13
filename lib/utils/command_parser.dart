class CommandParser {
  String parse(String command) {
    final text = command.toLowerCase().trim();

    if (text.contains('ulangi')) {
      return 'repeat';
    }

    if (text.contains('hari ini hari apa') ||
        text.contains('hari apa') ||
        text == 'hari') {
      return 'day';
    }

    if (text.contains('tanggal') ||
        text.contains('tanggal berapa')) {
      return 'date';
    }

    if (text.contains('jam berapa') ||
        text.contains('jam sekarang') ||
        text.contains('waktu sekarang')) {
      return 'time';
    }

    if (text.contains('cuaca')) {
      return 'weather';
    }

    if (text.contains('keluar') ||
        text.contains('logout')) {
      return 'logout';
    }

    return 'unknown';
  }
}