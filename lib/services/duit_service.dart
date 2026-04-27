import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class Balance {
  final int income;
  final int expense;
  final int balance;

  Balance(this.income, this.expense, this.balance);
}

class DuitService {
  final CollectionReference duits = FirebaseFirestore.instance.collection(
    'duit',
  );
  // get current user
  String get userUid => FirebaseAuth.instance.currentUser!.uid;

  //create new duit tracker
  Future<void> addDuit(String title, String content, int amount, String type) {
    return duits.add({
      'uid': userUid,
      'title': title,
      'content': content,
      'amount': amount,
      'createdAt': Timestamp.now(),
      'type': type,
    });
  }

  //fetch all duit trackers
  Stream<QuerySnapshot> getDuits() {
    return duits
        .where('uid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  //update duit tracker
  Future<void> updateDuit(
    String id,
    String title,
    String content,
    int amount,
    String type,
  ) {
    return duits.doc(id).update({
      'uid': userUid,
      'title': title,
      'content': content,
      'amount': amount,
      'updatedAt': Timestamp.now(),
      'type': type,
    });
  }

  //delete duit tracker
  Future<void> deleteDuit(String id) {
    return duits.doc(id).delete();
  }

  // get total money
  Stream<int> getMoney(String type) {
    return duits
        .where('uid', isEqualTo: userUid)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;

            total += (data['amount'] ?? 0) as int;
          }
          return total;
        });
  }

  // get balance (income, expense, income-expense) as stream
  Stream<Balance> getBalance() {
    final income = getMoney('INCOME');
    final expense = getMoney('EXPENSE');

    // CombineLatestStream.combineX takes X+1 arguments. first X arguments are streams, last arg is a combiner func that takes X arguments. Xi arg is i-th stream, and theyre output/newest data of said stream. return of this combiner MUST match the return type of parent function (getBalance()). neat.
    return CombineLatestStream.combine2(income, expense, (int inc, int exp) {
      return Balance(inc, exp, inc - exp);
    });
  }
}
