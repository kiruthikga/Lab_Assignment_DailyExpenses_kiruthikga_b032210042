import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Model/expense.dart';

void main() {
  runApp(DailyExpensesApp(username: ''));
}

class DailyExpensesApp extends StatelessWidget {
  final String username;

  DailyExpensesApp({required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExpenseList(username: username),
    );
  }
}

class ExpenseList extends StatefulWidget {
  final String username;

  ExpenseList({required this.username});

  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final List<Expense> expenses = [];
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController txtDateController = TextEditingController();
  double totalAmount = 0;

  Future<void> _addExpense() async {
    String description = descriptionController.text.trim();
    String amount = amountController.text.trim();

    if (description.isNotEmpty && amount.isNotEmpty) {
      Expense exp = Expense(double.parse(amount), description, txtDateController.text);
      if (await exp.save()) {
        setState(() {
          expenses.add(exp);
          descriptionController.clear();
          amountController.clear();
          calculateTotalAmount();  // Update the totalAmount here
        });
      } else {
        _showMessage("Failed to save Expense data");
      }
    }
  }

  void calculateTotalAmount() {
    totalAmount = 0;
    for (Expense ex in expenses) {
      totalAmount += ex.amount;
    }
    totalAmountController.text = totalAmount.toString();
  }

  Future<void> _removeExpense(int index) async {
    try {
      // Retrieve the expense to be deleted
      Expense expenseToDelete = expenses[index];

      // Debugging: Print the expense details before deletion
      _showMessage("Deleting expense: ${expenseToDelete.toJson()}");

      // Delete from the remote database
      Map<String, dynamic> requestBody = {'desc': expenseToDelete.desc}; // Include 'desc' field
      if (await expenseToDelete.delete(requestBody)) {
        // If the remote deletion is successful, update the local list
        setState(() {
          expenses.removeAt(index);
          calculateTotalAmount();
        });
      } else {
        // Handle remote deletion failure
        _showMessage("Failed to delete Expense data");
      }
    } catch (e) {
      // Handle any unexpected errors during the deletion process
      print("Error during deletion: $e");
      _showMessage("An unexpected error occurred");
    }
  }

  // function display error message
  void _showMessage(String msg) {
    if (mounted) {
      // make sure this context is still mounted/exist
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
        ),
      );
    }
  }

  void _editExpense(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpensesScreen(
          expense: expenses[index],
          onSave: (editedExpense) {
            setState(() {
              totalAmount = totalAmount - expenses[index].amount + editedExpense.amount;
              expenses[index] = editedExpense;
              totalAmountController.text = totalAmount.toString();
            });
          },
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedDate != null && pickedTime != null) {
      DateTime localDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Convert to UTC before formatting
      DateTime utcDateTime = localDateTime.toUtc();

      // Format the date and time
      String formattedDateTime = "${utcDateTime.year}-${utcDateTime.month.toString().padLeft(2, '0')}-${utcDateTime.day.toString().padLeft(2, '0')} "
          "${utcDateTime.hour.toString().padLeft(2, '0')}:${utcDateTime.minute.toString().padLeft(2, '0')}:${utcDateTime.second.toString().padLeft(2, '0')}";

      setState(() {
        txtDateController.text = formattedDateTime;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {

      final prefs = await SharedPreferences.getInstance();

      final strUsernameDebug = prefs.getString("username");
      _showMessage("Welcome ${widget.username}  !!");

      // Fetch current date and time from the device
      DateTime now = DateTime.now();
      txtDateController.text = now.toLocal().toString().substring(0, 19).replaceAll('T', '');

      expenses.addAll(await Expense.loadAll());

      setState(() {
        calculateTotalAmount();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Expenses'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Welcome, ${widget.username}'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (RM)',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                keyboardType: TextInputType.datetime,
                controller: txtDateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: totalAmountController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Total Spend (RM)',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _addExpense(),
              child: Text('Add Expense'),
            ),
            Container(
              child: _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key(expenses[index].amount.toString()), // Convert double to String
          background: Container(
            color: Colors.red,
            child: Center(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          onDismissed: (direction) {
            _removeExpense(index);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Item dismissed')));
          },
          child: Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(expenses[index].desc),
              subtitle: Row(children: [
                Text('Amount: ${expenses[index].amount.toString()}'), // Convert double to String
                const Spacer(),
                Text('Date: ${expenses[index].dateTime}')
              ]),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _removeExpense(index),
              ),
              onLongPress: () {
                _editExpense(index);
              },
            ),
          ),
        );
      },
    );
  }
}

class EditExpensesScreen extends StatefulWidget {
  final Expense expense;
  final Function(Expense) onSave;

  EditExpensesScreen({required this.expense, required this.onSave});

  @override
  _EditExpensesScreenState createState() => _EditExpensesScreenState();
}

class _EditExpensesScreenState extends State<EditExpensesScreen> {
  final TextEditingController descController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    descController.text = widget.expense.desc;
    amountController.text = widget.expense.amount.toString();
    dateTimeController.text = widget.expense.dateTime;
  }

  _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedDate != null && pickedTime != null) {
      DateTime localDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      DateTime utcDateTime = localDateTime.toUtc();

      setState(() {
        dateTimeController.text = utcDateTime.toString().substring(0, 19).replaceAll('T', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Expense'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: dateTimeController,
              readOnly: true,
              onTap: _selectDateTime,
              decoration: const InputDecoration(labelText: 'Date'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              double editedAmount = double.parse(amountController.text);

              // Update date and time in the Expense object
              Expense editedExpense = Expense(
                editedAmount,
                descController.text,
                dateTimeController.text,
              );

              // Call the onSave callback to update the expense in the parent widget
              widget.onSave(editedExpense);

              // Perform the update to the remote MySQL database
              if (await editedExpense.update()) {
                Navigator.pop(context); // Navigate back after successful update
              } else {
                // Handle update failure
                // You can show an error message or handle it as needed
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update Expense data'),
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
