import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poop_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference PoopsCollection =
  FirebaseFirestore.instance.collection('Poops');

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

    // Update user's Poop count
    await _updateUserPoopCount(userId);
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
        'PoopCount': todayPoopsQuery.count,
        'lastPoopTime': FieldValue.serverTimestamp(),
      });
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


  // Get top users for today's Poops
  Stream<List<UserModel>> getTopUsers({int limit = 10}) {
    // Get the current date (midnight)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return usersCollection
        .where('lastPoopTime', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('lastPoopTime', descending: true)
        .orderBy('PoopCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}