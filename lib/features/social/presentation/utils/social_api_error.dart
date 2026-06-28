import 'package:flutter/material.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/network/api_exception.dart';

/// Handles social API errors per backend contract.
/// Returns `true` when the error was handled.
bool handleSocialApiError(BuildContext context, Object error) {
  if (error is! ApiException) return false;

  switch (error.statusCode) {
    case 401:
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
      return true;
    case 404:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('غير موجود')),
      );
      return true;
    case 400:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.displayMessage)),
      );
      return true;
    default:
      return false;
  }
}

String socialApiFallbackMessage(Object error) {
  if (error is ApiException) return error.displayMessage;
  return error.toString();
}
