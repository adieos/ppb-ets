import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final CollectionReference notes = FirebaseFirestore.instance.collection(
    'notes',
  );
  // get current user
  String get userUid => FirebaseAuth.instance.currentUser!.uid;

  //create new note
  Future<void> addNote(String title, String content, String label) {
    return notes.add({
      'uid': userUid,
      'title': title,
      'content': content,
      'createdAt': Timestamp.now(),
      'label': label,
    });
  }

  //fetch all notes
  Stream<QuerySnapshot> getNotes() {
    return notes
        .where('uid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  //update notes
  Future<void> updateNote(
    String id,
    String title,
    String content,
    String label,
  ) {
    return notes.doc(id).update({
      'uid': userUid,

      'title': title,
      'content': content,
      'createdAt': Timestamp.now(),
      'label': label,
    });
  }

  //delete notes
  Future<void> deleteNote(String id) {
    return notes.doc(id).delete();
  }
}
