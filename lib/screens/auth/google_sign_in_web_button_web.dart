import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleSignInWebButton() {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: google_web.renderButton(
      configuration: google_web.GSIButtonConfiguration(
        type: google_web.GSIButtonType.standard,
        theme: google_web.GSIButtonTheme.outline,
        size: google_web.GSIButtonSize.large,
        text: google_web.GSIButtonText.continueWith,
        shape: google_web.GSIButtonShape.pill,
        logoAlignment: google_web.GSIButtonLogoAlignment.left,
        minimumWidth: 320,
        locale: 'vi',
      ),
    ),
  );
}
