import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../models/poop_model.dart';
import '../models/poop_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Future<void> addPoop(String userId, String userDisplayName, String url, List<String> groups, {String description = '', Position? position}) async {
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

  // Update user's Poop count in a transPoop
  Future<void> _updateUserPoopCount(String userId) async {
    // Get the current date (midnight)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _firestore.runTransaction((transPoop) async {
      // Get user document reference
      final userDocRef = usersCollection.doc(userId);

      // Get today's Poops count for the user
      final todayPoopsQuery = await PoopsCollection
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .count()
          .get();

      // Update user document
      transPoop.update(userDocRef, {
        'poopCount': todayPoopsQuery.count,
        'lastPoopTime': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<UserModel> getUserFromMail(String email){
    return usersCollection.where('email', isEqualTo: email).get().then((value) {
      if(value.docs.isNotEmpty){
        return UserModel.fromJson(value.docs.first.data() as Map<String, dynamic>);
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
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      if (data == null) return null; // Handle potential null data
      return PoopModel.fromJson(data as Map<String, dynamic>, doc.id);
    }).whereType<PoopModel>() // Remove nulls safely
        .toList());
  }

  // Get user's Poops for today
  Stream<List<PoopModel>> getPoops() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return PoopsCollection
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      if (data == null) return null; // Handle potential null data
      return PoopModel.fromJson(data as Map<String, dynamic>, doc.id);
    }).whereType<PoopModel>() // Remove nulls safely
        .toList());
  }



  Stream<List<Map<UserModel, int>>> getTopUsers({int limit = 3, RankingType rankingType = RankingType.today}) {
    // Get the current date (midnight)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // This is the improved version that performs a "join" between collections
    return usersCollection.snapshots().asyncMap((usersSnapshot) async {
      List<Future<Map<UserModel, int>>> userPoopCounts = [];

      for (var userDoc in usersSnapshot.docs) {
        userPoopCounts.add( _getUserWithPoopCount(userDoc, today, rankingType));
      }

      List<Map<UserModel, int>> usersWithCount = await Future.wait(userPoopCounts);

      // Filter out users with no poops today, sort by poop count, and limit the results
      return usersWithCount
        ..sort((a, b) => b.values.last.compareTo(a.values.last))
        ..take(limit);
    });
  }


  Future<Map<UserModel, int>> _getUserWithPoopCount(
      DocumentSnapshot userDoc,
      DateTime today,
      RankingType rankingType,
      ) async {
    final user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
    final userId = userDoc.id;
    Timestamp limit = Timestamp.fromDate(today);

    switch(rankingType){
      case RankingType.today:
        limit = Timestamp.fromDate(today);
        break;
      case RankingType.week:
        limit = Timestamp.fromDate(today.subtract(Duration(days: today.weekday - 1)));
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

  Future<void> updatePoop(String poopId, String imageUrl, {required String description}) {
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

  Future<String?> createGroup(String groupName) async {
    String groupId = generateRandomString(10); // Generate a random ID for the group
    return await GroupsCollection.add({
      'name': groupName,
      'groupId': groupId,
    }).then((value) {
      print("What the hell??? $groupId");
      return groupId; // Return the new group's ID
    }).catchError((error) {
      print("Failed to create group: $error");
      return null; // Return null if creation fails
    });
  }

  Future<List<String>> getGroupsFromUserId(String userId) async {
    return await GroupsUserPairCollection.where('userId', isEqualTo: userId).get().then((value) async {
      List<String> groupIds = [];
      List<String> groupNames = [];
      for (var doc in value.docs) {
        groupIds.add(doc['groupId'] as String); // Collect group IDs
      }
      for (var id in groupIds){
        groupNames.add(await getGroupName(id));
      }
      return groupIds; // Return the list of group IDs
    }).catchError((error) {
      print("Failed to get groups for user: $error");
      return []; // Return an empty list if there's an error
    });
  }

  Future<String> getGroupName(String groupId) async {
    return await GroupsCollection.where('groupId', isEqualTo: groupId).get().then((value) async {
      return value.docs[0]['name'] as String;
    }).catchError((error) {
      print("Failed to get group name: $error");
      return '';
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