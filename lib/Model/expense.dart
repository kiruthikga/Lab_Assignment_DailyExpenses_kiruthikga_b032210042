import '../Controller/request_controller.dart';
import '../Controller/sqlite_db.dart';


class Expense {
  static const String SQLiteTable = "expense";
  int? id;
  String desc;
  double amount;
  String dateTime;
  Expense(this.amount, this.desc, this.dateTime);

  Expense.fromJson(Map<String, dynamic> json)
      : desc = json['desc'] as String,
        amount = double.parse(json['amount'] as dynamic),
        dateTime = json['dateTime'] as String,
        id = json['id'] as int?;

  Map<String, dynamic> toJson() =>
      {'desc': desc, 'amount': amount, 'dateTime': dateTime};

  //add save
  Future<bool> save() async {
    //save to local SQLite
    await SQLiteDB().insert(SQLiteTable, toJson());
    //API OPERATION
    RequestController req = RequestController(path: "/api/expenses.php");
    req.setBody(toJson());
    await req.post();
    if (req.status() == 200) {
      return true;
    }
    else {
      if (await SQLiteDB().insert(SQLiteTable, toJson()) != 0) {
        return true;
      } else {
        return false;
      }
    }
  }

  // edit section
  Future<bool> update() async {
    RequestController req = RequestController(path: "/api/expenses.php");
    req.setBody(toJson());

    // Update in remote database
    await req.put();
    if (req.status() != 200) {
      // Error handling for remote update
      print("Error updating expense remotely: ${req.status()}, ${req.result()}");
      return false;
    }

    // Update in local SQLite database
    if (dateTime != null && desc != null && amount != null) {
      print("Updating locally: dateTime=$dateTime, desc=$desc, amount=$amount");

      // Identify the record based on dateTime
      Map<String, dynamic> updateRow = {
        'desc': desc,
        'amount': amount,
        'dateTime': dateTime,
      };

      int rowsAffected = await SQLiteDB().update(SQLiteTable, 'dateTime', updateRow);

      if (rowsAffected > 0) {
        print("Successfully updated locally. Rows affected: $rowsAffected");
        return true;
      } else {
        // Error handling for local update
        print("Error updating expense locally. Rows affected: $rowsAffected");
        return false;
      }
    } else {
      // Handle the case where dateTime, desc, or amount is null
      print("Error: dateTime=$dateTime, desc=$desc, amount=$amount");
      return false;
    }
  }

  Future<bool> delete(Map<String, dynamic> requestBody) async {
    RequestController req = RequestController(path: "/api/expenses.php");

    // Include the request body
    req.setBody(toJson());

    // Delete from remote database
    await req.delete(requestBody);
    if (req.status() != 200) {
      print("Error deleting expense remotely: ${req.status()}, ${req.result()}");
      return false;
    }

    // Delete from local SQLite database
    int rowsAffected = await SQLiteDB().delete(SQLiteTable, 'dateTime', dateTime);

    if (rowsAffected > 0) {
      print("Successfully deleted locally. Rows affected: $rowsAffected");
      return true;
    } else {
      print("Error deleting expense locally. Rows affected: $rowsAffected");
      return false;
    }
  }

  static Future<List<Expense>> loadAll() async {
    //Api operation
    List<Expense> result = [];
    RequestController req = RequestController(path: "/api/expenses.php");
    await req.get();
    if (req.status() == 200 && req.result() != null) {
      for (var item in req.result()) {
        result.add(Expense.fromJson(item));
      }
    }
    else {
      List<Map<String, dynamic>> result = await SQLiteDB().queryAll(SQLiteTable);
      List<Expense> expenses = [];
      for (var item in result) {
        result.add(Expense.fromJson(item) as Map<String, dynamic>);
      }
    }
    return result;
  }
}