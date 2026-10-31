import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// the two bundled fonts' OFL texts, for the licences page in Settings. the
/// OFL wants them to go along with the fonts, the assets are there for that
const bundledFonts = [
  (name: 'DM Sans', file: 'assets/fonts/DM-Sans-OFL.txt'),
  (name: 'Fraunces', file: 'assets/fonts/Fraunces-OFL.txt'),
];

/// read only when the licences page opens
Stream<LicenseEntry> fontLicences() async* {
  for (final font in bundledFonts) {
    final text = await rootBundle.loadString(font.file);
    yield LicenseEntryWithLineBreaks([font.name], text);
  }
}
