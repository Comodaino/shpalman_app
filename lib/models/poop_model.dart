import 'package:cloud_firestore/cloud_firestore.dart';

class PoopModel {
  final String id;
  final String userId;
  final String userDisplayName;
  final DateTime timestamp;
  final String description;
  final String url;
  final String? lat;
  final String? long;
  final List<String> groups;

  PoopModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.timestamp,
    this.description = '',
    required this.url,
    this.lat,
    this.long,
    required this.groups
  });

  factory PoopModel.fromJson(Map<String, dynamic> json, String docId) {
    return PoopModel(
      id: docId,
      userId: json['userId'] ?? '',
      userDisplayName: json['userDisplayName'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      lat: json['lat'],
      long: json['lat'],
      groups: json['groups'] != null
          ? List<String>.from(json['groups'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'url': url,
      'lat': lat,
      'long': long,
      'groups' : groups
    };
  }
}