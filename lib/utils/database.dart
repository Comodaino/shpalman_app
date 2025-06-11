import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../models/poop_model.dart';
import '../models/poop_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  // Collections
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference PoopsCollection =
  FirebaseFirestore.instance.collection('poops');
  final CollectionReference GroupsUserPairCollection =
  FirebaseFirestore.instance.collection('groupsUserPair');
  final CollectionReference GroupsCollection =
  FirebaseFirestore.instance.collection('groups');

  // Add a new Poop
  Future<void> addPoop(String userId, String userDisplayName, String url,
      List<String> groups,
      {String description = '', Position? position}) async {
    // Create Poop document
    final PoopData = PoopModel(
        id: '',
        userId: userId,
        userDisplayName: userDisplayName,
        timestamp: DateTime.now(),
        description: description,
        url: url,
        lat: position?.latitude.toString(),
        long: position?.longitude.toString(),
        groups: []
    ).toJson();
    // Add to Poops collection
    await PoopsCollection.add(PoopData);
  }

  Future<UserModel> getUserFromMail(String email) {
    return usersCollection.where('email', isEqualTo: email).get().then((value) {
      if (value.docs.isNotEmpty) {
        return UserModel.fromJson(
            value.docs.first.data() as Map<String, dynamic>);
      } else {
        return UserModel(uid: '', email: '', displayName: '');
      }
    });
  }

  // Get user's Poops for today
  Stream<List<PoopModel>> getUserPoops(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return PoopsCollection
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data();
          if (data == null) return null; // Handle potential null data
          return PoopModel.fromJson(data as Map<String, dynamic>, doc.id);
        }).whereType<PoopModel>() // Remove nulls safely
            .toList());
  }
  Future<List<PoopModel>> getFilteredPoops(String userId) async {
    List<Map<String, dynamic>> groups = await getGroupsFromUserId(userId);
    //extract ids from the list of groups
    List<String> groupIds = groups.map((group) => group['groupId'] as String).toList();
    List<PoopModel> poops = await getPoops();
    return poops.where((poop) {
      // Check if the poop belongs to the user or is in one of the user's groups
      return poop.userId == userId || poop.groups.any((group) => groupIds.contains(group));
    }).toList();
  }

  // Get user's Poops for today
  Future<List<PoopModel>> getPoops() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await PoopsCollection
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      if (data == null) return null; // Handle potential null data
      return PoopModel.fromJson(data as Map<String, dynamic>, doc.id);
    }).whereType<PoopModel>().toList(); // Remove nulls safely
  }



  Stream<List<Map<UserModel, int>>> getTopUsers(
      {int limit = 3, RankingType rankingType = RankingType.today}) {
    // Get the current date (midnight)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // This is the improved version that performs a "join" between collections
    return usersCollection.snapshots().asyncMap((usersSnapshot) async {
      List<Future<Map<UserModel, int>>> userPoopCounts = [];

      for (var userDoc in usersSnapshot.docs) {
        userPoopCounts.add(_getUserWithPoopCount(userDoc, today, rankingType));
      }

      List<Map<UserModel, int>> usersWithCount = await Future.wait(
          userPoopCounts);

      // Filter out users with no poops today, sort by poop count, and limit the results
      return usersWithCount
        ..sort((a, b) => b.values.last.compareTo(a.values.last))
        ..take(limit);
    });
  }


  Future<Map<UserModel, int>> _getUserWithPoopCount(DocumentSnapshot userDoc,
      DateTime today,
      RankingType rankingType,) async {
    final user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
    final userId = userDoc.id;
    Timestamp limit = Timestamp.fromDate(today);

    switch (rankingType) {
      case RankingType.today:
        limit = Timestamp.fromDate(today);
        break;
      case RankingType.week:
        limit = Timestamp.fromDate(
            today.subtract(Duration(days: today.weekday - 1)));
        break;
      case RankingType.month:
        limit = Timestamp.fromDate(DateTime(today.year, today.month, 1));
        break;
      case RankingType.allTime:
        limit = Timestamp.fromDate(DateTime(1970));
        break;
    }

    // Query poops collection to get accurate count for today
    final poopsQuery = await PoopsCollection
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: limit)
        .count()
        .get();

    return {user: poopsQuery.count ?? 5};
  }

  Future<void> updatePoop(String poopId, String imageUrl,
      {required String description}) {
    // Update the poop document with the new description
    return PoopsCollection.doc(poopId).update({
      'url': imageUrl,
      'description': description,
    });
  }

  Future<bool> addToGroup(String groupId, String userId) async {
    return await GroupsUserPairCollection.add({
      'groupId': groupId,
      'userId': userId,
    }).then((value) {
      return true;
    }).catchError((error) {
      print("Failed to add user to group: $error");
      return false;
    });
  }

  Future<String> createGroup(String groupName, String userId) async {
    String groupId = generateRandomString(10);
    return await GroupsCollection.add({
      'name': groupName,
      'groupId': groupId,
    }).then((value) async {
      // Automatically add creator to the group
      await addToGroup(groupId, userId);
      print("Group created with ID: $groupId");
      return groupId;
    }).catchError((error) {
      print("Failed to create group: $error");
      throw Exception('Failed to create group');
    });
  }

  Future<List<Map<String,dynamic>>> getGroupsFromUserId(String userId) async {
    List<Map<String,dynamic>> groupIds = [];
    return await GroupsUserPairCollection.where('userId', isEqualTo: userId)
        .get()
        .then((value) async {
      for (var doc in value.docs) {
        groupIds.add(doc.data() as Map<String, dynamic>);
      }

      for (var group in groupIds) {
        // Fetch group details
        String groupId = group['groupId'] as String;
        String groupName = await getGroupName(groupId);
        group['name'] = groupName; // Add name to the map
      }
      return groupIds;
    }).catchError((error) {
      print("Failed to get groups for user: $error");
      return [];
    });
  }

  Future<String> getGroupName(String groupId) async {
    return await GroupsCollection.where('groupId', isEqualTo: groupId)
        .get()
        .then((value) {
      if (value.docs.isEmpty) {
        throw Exception('Group not found');
      }
      return value.docs[0]['name'] as String;
    }).catchError((error) {
      print("Failed to get group name: $error");
      throw Exception('Failed to get group name');
    });
  }

  void leaveGroup(Map<String,dynamic> group, String userId) {
    String groupId = group['groupId'].toString();
    GroupsUserPairCollection
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .get()
        .then((value) {
      for (var doc in value.docs) {
        doc.reference.delete();
      }
    }).catchError((error) {
      print("Failed to leave group: $error");
    });
    GroupsUserPairCollection
        .where('groupId', isEqualTo: groupId)
        .get().then((value) {
      if (value.docs.isEmpty) {
        GroupsCollection.where('groupId', isEqualTo: groupId).get().then((value) {
          for (var doc in value.docs) {
            doc.reference.delete();
          }
        }).catchError((error) {
          print("Failed to delete group: $error");
        });
      }
    });
  }
}

String generateRandomString(int lengthOfString){
  final random = Random();
  const allChars='AaBbCcDdlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1EeFfGgHhIiJjKkL234567890';
  final randomString = List.generate(lengthOfString,
          (index) => allChars[random.nextInt(allChars.length)]).join();
  return randomString;    // return the generated string
}