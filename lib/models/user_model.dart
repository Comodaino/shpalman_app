import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final int poopCount;
  final DateTime? lastPoopTime;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.poopCount = 0,
    this.lastPoopTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      poopCount: json['poopCount'] ?? 0,
      lastPoopTime: json['lastPoopTime'] != null
          ? (json['lastPoopTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'poopCount': poopCount,
      'lastPoopTime': lastPoopTime,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? poopCount,
    DateTime? lastPoopTime,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      poopCount: poopCount ?? this.poopCount,
      lastPoopTime: lastPoopTime ?? this.lastPoopTime,
    );
  }
}

enum RankingType {
  today,
  week,
  month,
  allTime,
}