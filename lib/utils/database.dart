import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poop_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference PoopsCollection =
  FirebaseFirestore.instance.collection('poops');

  // Add a new Poop
  Future<void> addPoop(String userId, String userDisplayName, {String description = ''}) async {
    // Create Poop document
    final PoopData = PoopModel(
      id: '',
      userId: userId,
      userDisplayName: userDisplayName,
      timestamp: DateTime.now(),
      description: description,
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



  Stream<List<Map<UserModel, int>>> getTopUsers({int limit = 10}) {
    // Get the current date (midnight)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // This is the improved version that performs a "join" between collections
    return usersCollection.snapshots().asyncMap((usersSnapshot) async {
      List<Future<Map<UserModel, int>>> userPoopCounts = [];

      for (var userDoc in usersSnapshot.docs) {
        userPoopCounts.add( _getUserWithPoopCount(userDoc, today));
      }

      List<Map<UserModel, int>> usersWithCount = await Future.wait(userPoopCounts);
      usersWithCount.sort((a, b) => b.values.last.compareTo(a.values.last));

      // Filter out users with no poops today, sort by poop count, and limit the results
      return usersWithCount
        ..sort((a, b) => b.values.last.compareTo(a.values.last))
        ..take(limit);
    });
  }
  Future<Map<UserModel, int>> _getUserWithPoopCount(
      DocumentSnapshot userDoc,
      DateTime today
      ) async {
    final user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
    final userId = userDoc.id;

    // Query poops collection to get accurate count for today
    final poopsQuery = await PoopsCollection
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .count()
        .get();

    return {user: poopsQuery.count ?? 5};
  }
}