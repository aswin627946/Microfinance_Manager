import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../models/borrower_model.dart';
import '../models/loan_model.dart';
import '../models/payments_model.dart';
import '../models/trip_item_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> exportDatabase() async {
    final String path;

    try{
      if (kIsWeb)
        path = 'microfinance.db';
      else {
        final String basePath = await getDatabasesPath();
        path = join(basePath, 'microfinance.db');
      }

      final dbFile = File(path);

      if (await dbFile.exists()){
        await Share.shareXFiles([XFile(path)], text: 'Microfinance Manager Database Backup');
      }
      else {
        print('Database file not found at path: $path');
      }
    } catch (e) {
      print('Error exporting database: $e');
    }

  }

  Future<void> importDatabase() async{
    try{
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
      File selectedFile = File(result.files.single.path!);

      // Basic validation to ensure they picked a database file
      if (!selectedFile.path.endsWith('.db') && !selectedFile.path.endsWith('.sqlite')) {
        print('Please select a valid database file.');
        return;
      }

      // 2. Get the current database path
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'microfinance.db'); // Replace with your DB name

      // 3. CLOSE THE CURRENT DATABASE CONNECTION!
      // If you have a singleton DatabaseHelper, call your close method here.
      
      // 4. Overwrite the existing database file with the new one
      await selectedFile.copy(dbPath);
      
      print('Database successfully imported!');
      
      // 5. Restart your app's state or re-initialize the database connection
      // Example: await DatabaseHelper.instance.initDb();
      
      } else {
        print('User canceled the picker.');
      }
    } catch (e) {
      print('Error importing database: $e');
    }
  }

  Future<Database> _initDatabase() async {
    final String path;
    
    if (kIsWeb) {
      // Web platform - use simple database name
      path = 'microfinance.db';
    } else {
      // Mobile and Desktop platforms - use platform-specific database path
      final String basePath = await getDatabasesPath();
      path = join(basePath, 'microfinance.db');
    }
    
    print('Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Create borrowers table
    await db.execute('''
      CREATE TABLE borrowers (
        borrower_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        status INTEGER NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        city TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        isSynced INTEGER NOT NULL
      )
    ''');

    //Insert Existing Borrowers from JSON
    final String borrowerJsonString  = await rootBundle.loadString('assets/mock/borrowers.json');
    final List<dynamic> borrowerJsonData = json.decode(borrowerJsonString);
    if (borrowerJsonData.isEmpty) {
      print('No borrower data found in JSON. Skipping pre-population.');
      return;
    }
    else{
      for (var borrower in borrowerJsonData){
        await db.insert('borrowers', {
          'name': borrower['name'],
          'status': borrower['status'] ?? 0,
          'phone': borrower['phone'],
          'address': borrower['address'],
          'latitude': borrower['latitude'],
          'longitude': borrower['longitude'],
          'city': borrower['city'] ?? "unknown",
          'created_at': DateTime.now().toString(),
          'updated_at': borrower['updated_at'],
          'isSynced': borrower['isSynced'] ?? 0,
        });
      }
    }

    
    // Create loans table
    await db.execute('''
      CREATE TABLE loans (
        loan_id INTEGER PRIMARY KEY,
        borrower_id INTEGER NOT NULL,
        created_by TEXT NOT NULL,
        principal_amount REAL NOT NULL,
        weekly_amount REAL NOT NULL,
        total_weeks INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        FOREIGN KEY (borrower_id) REFERENCES borrowers (borrower_id)
      )
    ''');


    // Insert existing loans from JSON
    final String loansJsonString  = await rootBundle.loadString('assets/mock/loans.json');
    final List<dynamic> loansJsonData = json.decode(loansJsonString);
    if (loansJsonData.isEmpty) {
      print('No loan data found in JSON. Skipping pre-population.');
      return;
    }
    else{
      for (var loan in loansJsonData){
        await db.insert('loans', {
          'loan_id': loan['loan_id'],
          'borrower_id': loan['borrower_id'],
          'created_by': loan['created_by'],
          'principal_amount': loan['principal_amount'],
          'weekly_amount': loan['weekly_amount'],
          'total_weeks': loan['total_weeks'],
          'start_date': loan['start_date'],
          'status': loan['status'],
          'created_at': DateTime.now().toString(),
          'isSynced': loan['isSynced'] ?? 0,
        });
      }
    }

    //Create Trips table
    await db.execute('''
      CREATE TABLE trips(
        trip_id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_date TEXT NOT NULL,
        agentId INTEGER,
        status INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');


    // Insert existing trips from JSON
    // final String tripsJsonString  = await rootBundle.loadString('assets/mock/trips.json');
    // final List<dynamic> tripsJsonData = json.decode(tripsJsonString);
    // if (tripsJsonData.isEmpty) {
    //   print('No trip data found in JSON. Skipping pre-population.');
    //   return;
    // }
    // else{
    //   for (var trip in tripsJsonData){
    //     await db.insert('trips', {
    //       'trip_date': trip['trip_date'],
    //       'agentId': trip['agentId'],
    //       'status': trip['status'] ?? 0,
    //       'created_at': DateTime.now().toString(),
    //     });
    //   }
    // }

    // Create Trip Items table
    await db.execute('''
      CREATE TABLE trip_items (
        trip_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        loan_id INTEGER NOT NULL,
        borrower_id INTEGER NOT NULL,
        expected_amount REAL NOT NULL,
        collected_amount REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (trip_id),
        FOREIGN KEY (loan_id) REFERENCES loans (loan_id),
        FOREIGN KEY (borrower_id) REFERENCES borrowers (borrower_id)
      )
    ''');

    // Create Payments table
    await db.execute('''
      CREATE TABLE payments (
        payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        borrower_id INTEGER NOT NULL,
        trip_id INTEGER,
        amount_paid REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        isSynced INTEGER NOT NULL,
        FOREIGN KEY (loan_id) REFERENCES loans (loan_id),
        FOREIGN KEY (borrower_id) REFERENCES borrowers (borrower_id),
        FOREIGN KEY (trip_id) REFERENCES trips (trip_id)
      )
    ''');


    // Insert existing payments from JSON
    final String paymentsJsonString  = await rootBundle.loadString('assets/mock/payments.json');
    final List<dynamic> paymentsJsonData = json.decode(paymentsJsonString);
    if (paymentsJsonData.isEmpty) {
      print('No payment data found in JSON. Skipping pre-population.');
      return;
    }
    else{
      for (var payment in paymentsJsonData){
        await db.insert('payments', {
          'loan_id': payment['loan_id'],
          'borrower_id': payment['borrower_id'],
          'trip_id': payment['trip_id'],
          'amount_paid': payment['amount_paid'],
          'payment_date': payment['payment_date'],
          'payment_type': payment['payment_type'],
          'created_at': DateTime.now().toString(),
          'isSynced': payment['isSynced'] ?? 0,
        });
      }
    }
  }

  // CRUD operations for Borrowers
  Future<int> insertBorrower(Borrower borrower) async {
    final db = await database;
    return await db.insert('borrowers', borrower.toMap());
  }
  Future<List<Borrower>> getBorrowers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('borrowers');
    return List.generate(maps.length, (i) => Borrower.fromMap(maps[i]));
  }

  Future<Borrower?> getBorrowerById(int borrowerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'borrowers',
      where: 'borrower_id = ?',
      whereArgs: [borrowerId],
    );
    if (maps.isNotEmpty) {
      return Borrower.fromMap(maps.first);
    }
    return null;
  }


  // CRUD operations for Loans
  Future<int> insertLoan(Loan loan) async {
    final db = await database;
    return await db.insert('loans', loan.toMap());
  }
  Future<List<Loan>> getLoans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('loans');
    return List.generate(maps.length, (i) => Loan.fromMap(maps[i]));
  }

  // Future<List<Loan>> getLoansByStatus(String status) async {
  //   final db = await database;

  //   final maps = await db.query(
  //     'loans',
  //     where: 'status = ?',
  //     whereArgs: [status],
  //   );

  //   return maps.map((e) => Loan.fromMap(e)).toList();
  // }

  Future<List<Loan>> getLoansByBorrowerId(int borrowerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'borrower_id = ?',
      whereArgs: [borrowerId],
    );
    return List.generate(maps.length, (i) => Loan.fromMap(maps[i]));
  }

  //CRUD operations for Trips
  Future<int> createTrip() async{
    final db  = await database;
    final now = DateTime.now().toIso8601String();

    int tripId = await db.insert('trips',{
      'trip_date': now,
      'agentId': null,
      'status': 0,
      'created_at': now,
    });

    final loans = await db.query('Loans', where: 'status = ?', whereArgs: [1]);

    final batch = db.batch();

    for (var loan in loans){
      batch.insert('trip_items', {
        'trip_id': tripId,
        'loan_id': loan['loan_id'],
        'borrower_id': loan['borrower_id'],
        'expected_amount': loan['weekly_amount'],
        'collected_amount': 0,
        'status': 'pending',
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);

    return tripId;
  }

  Future<Map<String, dynamic>> getTripSummary(Database db, int tripId) async {
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_loans,
        SUM(expected_amount) as total_expected,
        SUM(collected_amount) as total_collected
      FROM trip_items
      WHERE trip_id = ?
    ''', [tripId]);

    final data = result.first;

    final query = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN LOWER(payment_type) = 'cash' THEN amount_paid ELSE 0 END) as total_collected_cash,
        SUM(CASE WHEN LOWER(payment_type) = 'upi' THEN amount_paid ELSE 0 END) as total_collected_upi
      FROM payments
      WHERE trip_id = ?
    ''', [tripId]);

    final paymentData = query.first;

    double expected = (data['total_expected'] as num?)?.toDouble() ?? 0;
    double collected = (data['total_collected'] as num?)?.toDouble() ?? 0;
    double collectedCash = (paymentData['total_collected_cash'] as num?)?.toDouble() ?? 0;
    double collectedUpi = (paymentData['total_collected_upi'] as num?)?.toDouble() ?? 0;

    return {
      'totalLoans': data['total_loans'] ?? 0,
      'expected': expected,
      'collected': collected,
      'collectedCash': collectedCash,
      'collectedUpi': collectedUpi,
      'remaining': expected - collected,
    };
  }

  Future<void> closeTrip(int tripId) async {
    final db = await database;

    await db.update(
      'trips',
      {'status': 1}, // 1 = completed
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }

  //CRUD operations for Trip Items
  Future<List<TripItem>> getTripItems(Database db, int tripId, String status) async {
    final result = await db.query(
      'trip_items',
      where: 'trip_id = ? AND status = ?',
      whereArgs: [tripId, status],
    );

    return result.map((e) => TripItem.fromMap(e)).toList();
  }



  // CRUD operations for Payments
    Future<List<Payment>> getPaymentsByLoanId(int loanId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<void> insertPayment({
    required Database db,
    required int tripId,
    required int loanId,
    required int borrowerId,
    required double amountPaid,
    required String paymentType,
  }) async {
    final now = DateTime.now().toIso8601String();

    // 1. Insert payment
    await db.insert('payments', {
      'loan_id': loanId,
      'borrower_id': borrowerId,
      'trip_id': tripId,
      'amount_paid': amountPaid,
      'payment_date': now,
      'payment_type': paymentType,
      'created_at': now,
      'isSynced': 0,
    });

    // 2. Get trip item
    final item = await db.query(
      'trip_items',
      where: 'trip_id = ? AND loan_id = ?',
      whereArgs: [tripId, loanId],
    );

    if (item.isEmpty) return;

    double collected = (item[0]['collected_amount'] as num?)?.toDouble() ?? 0.0;
    double expected = (item[0]['expected_amount'] as num?)?.toDouble() ?? 0.0;

    double newAmount = collected + amountPaid;

    String status;
    if (newAmount >= expected) {
      status = 'completed';
    } else if (newAmount > 0) {
      status = 'partial';
    } else {
      status = 'pending';
    }

    // 3. Update trip item
    await db.update(
      'trip_items',
      {
        'collected_amount': newAmount,
        'status': status,
      },
      where: 'trip_item_id = ?',
      whereArgs: [item[0]['trip_item_id']],
    );
  }

}