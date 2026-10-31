abstract final class AppInfo {
  static const name = 'ColorMix Studio';
  static const version = '0.1.0';
}

abstract final class Breakpoints {
  /// below this the app uses the bottom bar, above it the side rail
  static const double rail = 600;

  /// side rail shows labels from here
  static const double sidebar = 1100;

  /// the editor and the weighing screen go two columns from here
  static const double twoPane = 900;

  static const double contentMaxWidth = 1080;

  /// the editor and the weighing screen, two columns
  static const double workbenchMaxWidth = 1240;

  /// one column to read: a session's record
  static const double readingMaxWidth = 880;

  /// one step at a time: calibration
  static const double wizardMaxWidth = 680;
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

  static String weigh(String formulaId) => '/weigh/$formulaId';

  /// one past weighing session
  static String session(String id) => '/history/$id';

  static const calibrate = '/calibrate';

  /// read a hair color off a photo, from Color Studio
  static const camera = '/camera';
}
