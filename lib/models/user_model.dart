import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final int actionCount;
  final DateTime? lastActionTime;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.actionCount = 0,
    this.lastActionTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      actionCount: json['actionCount'] ?? 0,
      lastActionTime: json['lastActionTime'] != null
          ? (json['lastActionTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'actionCount': actionCount,
      'lastActionTime': lastActionTime,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? actionCount,
    DateTime? lastActionTime,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      actionCount: actionCount ?? this.actionCount,
      lastActionTime: lastActionTime ?? this.lastActionTime,
    );
  }
}