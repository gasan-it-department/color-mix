abstract final class AppInfo {
  static const name = 'ColorMix Studio';
  static const version = '0.1.0';
}

abstract final class Breakpoints {
  /// below this the app uses the bottom bar, above it the side rail
  static const double rail = 600;

  /// side rail shows labels from here
  static const double sidebar = 1100;

  static const double contentMaxWidth = 1080;
}

abstract final class Routes {
  static const home = '/';
  static const colors = '/colors';
  static const formulas = '/formulas';
  static const scale = '/scale';
  static const settings = '/settings';

  /// editor for the color picked in Color Studio
  static const formulaNew = '/formula/new';

  static String formula(String id) => '/formula/$id';
}
