import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yfc_app_v3.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS members');
        await db.execute('DROP TABLE IF EXISTS chat_messages');
        await db.execute('DROP TABLE IF EXISTS prayer_requests');
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS members (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        phone_number TEXT NOT NULL UNIQUE,
        date_of_birth TEXT,
        marital_status TEXT,
        anniversary_date TEXT,
        preferred_language TEXT,
        avatar_url TEXT,
        role TEXT DEFAULT 'member',
        registered_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        sender_name TEXT NOT NULL,
        sender_avatar TEXT,
        text_content TEXT,
        message_type TEXT DEFAULT 'text',
        media_url TEXT,
        audio_duration INTEGER DEFAULT 0,
        reactions TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS prayer_requests (
        id TEXT PRIMARY KEY,
        author_name TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        pray_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Wipes all local SQLite app tables to reset local state if requested
  Future<void> wipeAllLocalData() async {
    final db = await database;
    await db.execute('DELETE FROM members');
    await db.execute('DELETE FROM chat_messages');
    await db.execute('DELETE FROM prayer_requests');
  }
}
