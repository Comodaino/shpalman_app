import 'package:cloud_firestore/cloud_firestore.dart';

class PoopModel {
  final String id;
  final String userId;
  final String userDisplayName;
  final DateTime timestamp;
  final String description;
  final String url;

  PoopModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.timestamp,
    this.description = '',
    required this.url,
  });

  factory PoopModel.fromJson(Map<String, dynamic> json, String docId) {
    return PoopModel(
      id: docId,
      userId: json['userId'] ?? '',
      userDisplayName: json['userDisplayName'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      description: json['description'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'url': url,
    };
  }
}