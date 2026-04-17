import 'package:flutter/material.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.submittedAgo,
    required this.fullDescription,
    required this.reportType,
    required this.imagePath,
    required this.progressIndex,
    required this.statusLabel,
    required this.statusColor,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
  });

  final String id;
  final String title;
  final String description;
  final String submittedAgo;
  final String fullDescription;
  final String reportType;
  final String imagePath;
  final int progressIndex;
  final String statusLabel;
  final Color statusColor;
  final double latitude;
  final double longitude;
  final String? locationAddress;

  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? submittedAgo,
    String? fullDescription,
    String? reportType,
    String? imagePath,
    int? progressIndex,
    String? statusLabel,
    Color? statusColor,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      submittedAgo: submittedAgo ?? this.submittedAgo,
      fullDescription: fullDescription ?? this.fullDescription,
      reportType: reportType ?? this.reportType,
      imagePath: imagePath ?? this.imagePath,
      progressIndex: progressIndex ?? this.progressIndex,
      statusLabel: statusLabel ?? this.statusLabel,
      statusColor: statusColor ?? this.statusColor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'submittedAgo': submittedAgo,
      'fullDescription': fullDescription,
      'reportType': reportType,
      'imagePath': imagePath,
      'progressIndex': progressIndex,
      'statusLabel': statusLabel,
      'statusColor': statusColor.toARGB32(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      submittedAgo: json['submittedAgo']?.toString() ?? '',
      fullDescription: json['fullDescription']?.toString() ?? '',
      reportType: json['reportType']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      progressIndex: int.tryParse(json['progressIndex']?.toString() ?? '') ?? 0,
      statusLabel: json['statusLabel']?.toString() ?? '',
      statusColor: Color(
        int.tryParse(json['statusColor']?.toString() ?? '') ??
            const Color(0xFF2A9AF4).toARGB32(),
      ),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      locationAddress: json['locationAddress']?.toString(),
    );
  }
}
