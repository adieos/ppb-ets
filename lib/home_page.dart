import 'package:duitku/firestore.dart';
import 'package:duitku/services/duit_service.dart';
import 'package:duitku/services/io_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:duitku/services/notification_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final amountTextController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final FirestoreService firestoreService = FirestoreService();
  final DuitService duitService = DuitService();
  final IOService ioservice = IOService();

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  void openDuitBox({
    String? docId,
    String? existingTitle,
    String? existingNote,
    int? existingAmount,
    String? existingType,
    String? existingURL,
  }) async {
    // Reset image state for new dialogs
    _selectedImage = null;

    if (docId != null) {
      titleTextController.text = existingTitle ?? '';
      contentTextController.text = existingNote ?? '';
      amountTextController.text = "${existingAmount}";
    } else {
      titleTextController.clear();
      contentTextController.clear();
      amountTextController.clear();
    }

    String selectedType = existingType ?? 'INCOME';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                docId == null ? "New Transaction" : "Edit Transaction",
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleTextController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: contentTextController,
                      decoration: const InputDecoration(
                        labelText: "Content",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountTextController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Type",
                        border: OutlineInputBorder(),
                      ),
                      items: ['INCOME', 'EXPENSE']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedType = v!),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null)
                          setStateDialog(
                            () => _selectedImage = File(picked.path),
                          );
                      },
                      icon: const Icon(Icons.image),
                      label: const Text("Pick Image"),
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Image.file(_selectedImage!, height: 100),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    int amt = int.tryParse(amountTextController.text) ?? 0;
                    if (amt <= 0) return;

                    // Upload new image if exists, otherwise keep existing
                    String finalImageUrl = existingURL ?? '';
                    if (_selectedImage != null) {
                      finalImageUrl =
                          await ioservice.uploadImage(_selectedImage!) ?? '';
                    }

                    if (docId == null) {
                      // ADD LOGIC
                      duitService.addDuit(
                        titleTextController.text,
                        contentTextController.text,
                        amt,
                        selectedType,
                        finalImageUrl,
                      );
                      await NotificationService.createNotification(
                        id: 4,
                        title: 'Created',
                        body: 'Record added successfully',
                        summary: 'Duitku',
                      );
                    } else {
                      // UPDATE LOGIC
                      duitService.updateDuit(
                        docId,
                        titleTextController.text,
                        contentTextController.text,
                        amt,
                        selectedType,
                        finalImageUrl,
                      );
                      await NotificationService.createNotification(
                        id: 2,
                        title: 'Updated',
                        body: 'Record modified successfully',
                        summary: 'Duitku',
                      );
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(docId == null ? "Create" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Duitku"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openDuitBox,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Header / Stats Card
          StreamBuilder<Balance>(
            stream: duitService.getBalance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              Balance b = snapshot.data!;
              return Card(
                elevation: 2,
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
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "${b.balance}",
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
                            "${b.income}",
                            Colors.green,
                          ),
                          _buildStatColumn(
                            "Expense",
                            "${b.expense}",
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // List of Transactions
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: duitService.getDuits(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: Text("No records yet"));
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isIncome = data['type'] == 'INCOME';
                    String imgUrl = data['imgUrl'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        // Renders the image if URL exists, else fallback icon
                        leading: imgUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imgUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                ),
                              ),

                        title: Text(
                          data['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['content']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Amount text
                            Text(
                              "${isIncome ? '+' : '-'}${data['amount']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),

                            // Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => openDuitBox(
                                docId: docs[index].id,
                                existingTitle: data['title'],
                                existingNote: data['content'],
                                existingAmount: data['amount'],
                                existingType: data['type'],
                                existingURL: imgUrl,
                              ),
                            ),

                            // Delete Button (The one you were missing!)
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                duitService.deleteDuit(docs[index].id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
