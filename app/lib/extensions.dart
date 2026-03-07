import 'package:zxy_app/usecase/resource/models.dart';

extension Logo on List<Backdrop> {
  Backdrop? getLogo() {
    final logos = this;
    if (logos.isNotEmpty) {
      // Prefer English logo
      final englishLogo = logos.firstWhere(
        (logo) =>
            logo.iso6391 == 'en' &&
            logo.filePath != null &&
            !logo.filePath!.endsWith(".svg"),
        orElse: () => logos.first,
      );
      return englishLogo;
    }
    return null;
  }
}
