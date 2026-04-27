import 'package:duitku/firestore.dart';
import 'package:duitku/services/duit_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:duitku/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  void logout(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  // get current user
  String get userUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // idk what this is twin
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final labelTextController = TextEditingController();
  final typeTextController = TextEditingController();
  final amountTextController = TextEditingController();

  // get current user
  String get userUid => FirebaseAuth.instance.currentUser!.uid;
  String? get userEmail => FirebaseAuth.instance.currentUser!.email;

  // init services
  final FirestoreService firestoreService = FirestoreService();
  final DuitService duitService = DuitService();

  void openNoteBox({
    String? docId,
    String? existingTitle,
    String? existingNote,
    String? existingLabel,
  }) async {
    // new track
    if (docId != null) {
      titleTextController.text = existingTitle ?? '';
      contentTextController.text = existingNote ?? '';
      labelTextController.text = existingLabel ?? '';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? "Create new Note" : "Edit Note"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Title"),
                controller: titleTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Content"),
                controller: contentTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Label"),
                controller: labelTextController,
              ),
            ],
          ),
          actions: [
            MaterialButton(
              onPressed: () async {
                if (docId == null) {
                  firestoreService.addNote(
                    titleTextController.text,
                    contentTextController.text,
                    labelTextController.text,
                  );
                  await NotificationService.createNotification(
                    id: 1,
                    title: 'Successfully created record',
                    body: 'A record for your transaction has been created.',
                    summary: 'Duitku',
                  );
                } else {
                  firestoreService.updateNote(
                    docId,
                    titleTextController.text,
                    contentTextController.text,
                    labelTextController.text,
                  );
                  await NotificationService.createNotification(
                    id: 2,
                    title: 'Successfully edited record',
                    body: 'The record in your transaction has been modified.',
                    summary: 'Duitku',
                  );
                }
                titleTextController.clear();
                contentTextController.clear();
                labelTextController.clear();

                Navigator.pop(context);
              },
              child: Text(docId == null ? "Create" : "Update"),
            ),
          ],
        );
      },
    );
  }

  void openDuitBox({
    String? docId,
    String? existingTitle,
    String? existingNote,
    int? existingAmount,
    String? existingType,
  }) async {
    // new track
    if (docId != null) {
      titleTextController.text = existingTitle ?? '';
      contentTextController.text = existingNote ?? '';
      amountTextController.text = "${existingAmount}";
      typeTextController.text = existingType ?? ''; // INCOME or EXPENSE
    }
    String selectedType = 'INCOME'; // The variable to track the choice

    // pop up the thingy
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            docId == null ? "Create new Transaction" : "Edit Transaction",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Title"),
                controller: titleTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Content"),
                controller: contentTextController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Amount"),
                controller: amountTextController,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(labelText: "Type"),
                items: ['INCOME', 'EXPENSE'].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedType =
                        newValue!; // Update the UI when the user picks a new type
                  });
                },
              ),
            ],
          ),
          actions: [
            MaterialButton(
              onPressed: () async {
                if (typeTextController.text != "INCOME" &&
                    typeTextController.text != "EXPENSE") {
                  showTimedPopup(
                    context,
                    "Invalid Type",
                    "Type must either be INCOME or EXPENSE!",
                  );
                  return;
                }
                int amt = int.tryParse(amountTextController.text) ?? 0;
                if (amt <= 0) {
                  showTimedPopup(
                    context,
                    "Invalid Amount",
                    "PLEASE put a valid AMOUNT!",
                  );
                  return;
                }
                if (docId == null) {
                  duitService.addDuit(
                    titleTextController.text,
                    contentTextController.text,
                    amt,
                    typeTextController.text,
                  );
                  await NotificationService.createNotification(
                    id: 4,
                    title: 'Successfully created record',
                    body: 'A record for your transaction has been created.',
                    summary: 'Duitku',
                  );
                } else {
                  duitService.updateDuit(
                    docId,
                    titleTextController.text,
                    contentTextController.text,
                    amt,
                    typeTextController.text,
                  );
                  await NotificationService.createNotification(
                    id: 2,
                    title: 'Successfully edited record',
                    body: 'The record in your transaction has been modified.',
                    summary: 'Duitku',
                  );
                }
                titleTextController.clear();
                contentTextController.clear();
                amountTextController.clear();
                typeTextController.clear();

                Navigator.pop(context);
              },
              child: Text(docId == null ? "Create" : "Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transactions for ${userEmail}")),
      floatingActionButton: FloatingActionButton(
        onPressed: openDuitBox, // new note, hence no docId nor other params
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          StreamBuilder<Balance>(
            stream: duitService.getBalance(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                Balance myBalance = snapshot.data!;
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "Total Balance",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          "${myBalance.balance}",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              "Income",
                              "${myBalance.income}",
                              Colors.green,
                            ),
                            _buildStatColumn(
                              "Expense",
                              "${myBalance.expense}",
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                // return Text("youre rich! gg");
                /*
                return Row(
                  children: [
                    Text("Income: ${myBalance.income}"),
                    Text("Expense: ${myBalance.expense}"),
                    Text("Balance: ${myBalance.balance}"),
                  ],
                );
                */
              } else {
                return Text("youre broke lol (jk its still loading probably)");
              }
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: duitService.getDuits(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List duitList = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: duitList.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = duitList[index];
                      String docId = document.id;

                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      String noteTitle = data['title'];
                      String noteContent = data['content'];
                      int noteAmount = data['amount'];
                      String noteType = data['type'];

                      return ListTile(
                        title: Text(noteTitle),
                        subtitle: Text(noteContent),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${noteAmount}"),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                openDuitBox(
                                  // edit note
                                  docId: docId,
                                  existingNote: noteContent,
                                  existingTitle: noteTitle,
                                  existingAmount: noteAmount,
                                  existingType: noteType,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                duitService.deleteDuit(docId);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return const Text("No data");
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// HELPERS
Widget _buildStatColumn(String label, String value, Color color) {
  return Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}

// for invalid type
void showTimedPopup(BuildContext context, String title, String msg) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      // Start a timer to close the dialog after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });

      return AlertDialog(title: Text(title), content: Text(msg));
    },
  );
}
