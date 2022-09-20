// ignore_for_file: avoid_print

class Utils {
  static const String _printColorBlack = '\x1B[30m';
  static const String _printColorRed = '\x1B[31m';
  static const String _printColorGreen = '\x1B[32m';
  static const String _printColorYellow = '\x1B[33m';
  static const String _printColorBlue = '\x1B[34m';
  static const String _printColorMagenta = '\x1B[35m';
  static const String _printColorCyan = '\x1B[36m';
  static const String _printColorWhite = '\x1B[37m';
  static const String _printColorReset = '\x1B[0m';

  static void printBlack(String str) => print('$_printColorBlack$str$_printColorReset');
  static void printRed(String str) => print('$_printColorRed$str$_printColorReset');
  static void printGreen(String str) => print('$_printColorGreen$str$_printColorReset');
  static void printYellow(String str) => print('$_printColorYellow$str$_printColorReset');
  static void printBlue(String str) => print('$_printColorBlue$str$_printColorReset');
  static void printMagenta(String str) => print('$_printColorMagenta$str$_printColorReset');
  static void printCyan(String str) => print('$_printColorCyan$str$_printColorReset');
  static void printWhite(String str) => print('$_printColorWhite$str$_printColorReset');
  static void printReset(String str) => print('$_printColorReset$str$_printColorReset');
}
