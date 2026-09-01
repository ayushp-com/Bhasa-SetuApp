import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:translator/translator.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final GoogleTranslator _googleTranslator = GoogleTranslator();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sih_dictionary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dictionary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hindi_word TEXT,
        english_word TEXT,
        santhali_word TEXT,
        mundari_word TEXT,
        ho_word TEXT
      )
    ''');
    await _seedData(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS dictionary');
    await _createDB(db, newVersion);
  }

  Future _seedData(Database db) async {
    await db.transaction((txn) async {
      try {
        final String response = await rootBundle.loadString('assets/dictionary_data.json');
        final List<dynamic> data = json.decode(response);
        for (var word in data) {
          txn.insert('dictionary', {
            'hindi_word': word['hindi_word'],
            'english_word': word['english_word'],
            'santhali_word': word['santhali_word'],
            'mundari_word': word['mundari_word'],
            'ho_word': word['ho_word'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (e) {
        print("Error general JSON: $e");
      }

      try {
        final String santhaliResponse = await rootBundle.loadString('assets/santhali_comprehensive.json');
        final List<dynamic> santhaliData = json.decode(santhaliResponse);
        for (var word in santhaliData) {
          txn.insert('dictionary', {
            'hindi_word': word['hindi_word'],
            'english_word': word['english_word'],
            'santhali_word': word['santhali_word'],
            'mundari_word': word['santhali_word'],
            'ho_word': word['santhali_word'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (e) {
        print("Error Santhali JSON: $e");
      }
    });
  }

  Future<String?> translateWord(String sourceText, String targetLang, String sourceLang) async {
    final db = await instance.database;
    
    final sourceColumn = sourceLang == 'English' ? 'english_word' : 'hindi_word';
    final targetColumn = '${targetLang.toLowerCase()}_word';

    List<String> words = sourceText.trim().split(RegExp(r'\s+'));
    List<String> translatedWords = [];

    for (var word in words) {
      String cleanWord = sourceLang == 'English' ? word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '') : word.trim();

      // 1. Check local SQLite database first
      final maps = await db.query(
        'dictionary',
        columns: [targetColumn],
        where: '$sourceColumn = ?',
        whereArgs: [cleanWord],
      );

      if (maps.isNotEmpty && maps.first[targetColumn] != null) {
        translatedWords.add(maps.first[targetColumn].toString());
      } else {
        // 2. Active Fallback: Dynamically translate missing words via the translator package
        try {
          Translation translation = await _googleTranslator.translate(
            word, 
            from: sourceLang == 'English' ? 'en' : 'hi', 
            to: 'bn'
          );
          translatedWords.add("${translation.text}");
        } catch (e) {
          print("Translation fallback error: $e");
          translatedWords.add(word);
        }
      }
    }

    return translatedWords.join(' ');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}