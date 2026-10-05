import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:voicepin/models/voice_note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Database getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('voicepin.db');
    return _database!;
  }

  // Database başlatma
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Tablo oluşturma ve İndeksleme (Sorgu Hızlandırma)
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE voice_notes (
        id $idType,
        title $textType,
        latitude $realType,
        longitude $realType,
        audioPath $textType,
        category $textType,
        radius $realType,
        createdAt $textType,
        isActive $intType
      )
    ''');

    // SQLite İndeksleri: Kategori ve Aktiflik sorgularını milisaniyelik seviyeye indirir
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_category ON voice_notes (category)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_active ON voice_notes (isActive)');
  }

  // CREATE - Yeni ses notu ekle
  Future<VoiceNote> create(VoiceNote note) async {
    final db = await instance.database;
    final id = await db.insert('voice_notes', note.toMap());
    return note.copyWith(id: id);
  }

  // READ - Tek bir ses notu getir
  Future<VoiceNote?> readNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'voice_notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return VoiceNote.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // READ - Tüm ses notlarını getir
  Future<List<VoiceNote>> readAllNotes() async {
    final db = await instance.database;
    const orderBy = 'createdAt DESC';
    final result = await db.query('voice_notes', orderBy: orderBy);
    return result.map((json) => VoiceNote.fromMap(json)).toList();
  }

  // READ - Kategoriye göre notları getir
  Future<List<VoiceNote>> readNotesByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(
      'voice_notes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => VoiceNote.fromMap(json)).toList();
  }

  // READ - Aktif notları getir
  Future<List<VoiceNote>> readActiveNotes() async {
    final db = await instance.database;
    final result = await db.query(
      'voice_notes',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => VoiceNote.fromMap(json)).toList();
  }

  // UPDATE - Ses notunu güncelle
  Future<int> update(VoiceNote note) async {
    final db = await instance.database;
    return db.update(
      'voice_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // DELETE - Ses notunu sil (Veritabanı + Fiziksel Ses Dosyası Temizliği)
  Future<int> delete(int id) async {
    final db = await instance.database;
    final note = await readNote(id);
    if (note != null && note.audioPath.isNotEmpty) {
      try {
        final file = File(note.audioPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Ses dosyası fiziksel olarak silinirken hata: $e');
      }
    }
    return await db.delete(
      'voice_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE ALL - Tüm notları ve fiziksel ses dosyalarını sil
  Future<int> deleteAll() async {
    final db = await instance.database;
    final notes = await readAllNotes();
    for (var note in notes) {
      if (note.audioPath.isNotEmpty) {
        try {
          final file = File(note.audioPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
    return await db.delete('voice_notes');
  }

  // Veritabanını kapat
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // NOT SAYISI - Toplam not sayısı
  Future<int> getNotesCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM voice_notes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ARAMA - Başlığa göre arama
  Future<List<VoiceNote>> searchNotes(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'voice_notes',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => VoiceNote.fromMap(json)).toList();
  }
}