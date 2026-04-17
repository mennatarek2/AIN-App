import 'dart:math';

import '../../domain/report_model.dart';

class ReportRemoteDataSource {
  Future<void> submitReport(ReportModel report) async {
    await Future.delayed(const Duration(milliseconds: 450));

    final random = Random();
    if (random.nextDouble() < 0.2) {
      throw Exception('Temporary network failure while submitting report.');
    }
  }
}
