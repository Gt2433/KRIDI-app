import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'finance_service.dart';
import 'settings_service.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<DateTime?> lastSyncNotifier = ValueNotifier<DateTime?>(null);

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return null;
    try {
      return _firestore.collection('users').doc(uid);
    } catch (_) {
      return null;
    }
  }

  /// Upload all local financial data to Firestore cloud
  Future<bool> uploadToCloud() async {
    final doc = _userDoc;
    if (doc == null) return false;

    try {
      isSyncingNotifier.value = true;
      final finance = FinanceService.instance;

      final data = {
        'lastUpdated': FieldValue.serverTimestamp(),
        'wallets': finance.wallets.map((w) => w.toMap()).toList(),
        'transactions': finance.transactions.map((t) => t.toMap()).toList(),
        'debts': finance.debts.map((d) => d.toMap()).toList(),
        'budgets': finance.budgets.map((b) => b.toMap()).toList(),
        'settings': SettingsService.exportSettingsMap(),
      };

      await doc.set(data, SetOptions(merge: true));
      lastSyncNotifier.value = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Sync upload error: $e');
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Download cloud data and update local storage
  Future<bool> downloadFromCloud() async {
    final doc = _userDoc;
    if (doc == null) return false;

    try {
      isSyncingNotifier.value = true;
      final snapshot = await doc.get();

      if (!snapshot.exists || snapshot.data() == null) {
        // No remote backup exists yet for this user: back up current local data
        await uploadToCloud();
        return true;
      }

      final data = snapshot.data()!;
      await FinanceService.instance.loadFromCloudData(data);
      if (data['settings'] is Map) {
        await SettingsService.importSettingsMap(Map<String, dynamic>.from(data['settings'] as Map));
      }
      lastSyncNotifier.value = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Sync download error: $e');
      return false;
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  /// Save user settings to Firestore under current account
  Future<void> saveSettingsToCloud(Map<String, dynamic> settings) async {
    final doc = _userDoc;
    if (doc == null) return;
    try {
      await doc.set({
        'settings': settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving settings to cloud: $e');
    }
  }

  /// Auto sync when user signs in or connects
  Future<void> sync() async {
    if (!AuthService.instance.isAuthenticated) return;
    await downloadFromCloud();
  }

  /// Helper to fire an asynchronous background cloud update after any local change
  void scheduleCloudSync() {
    try {
      if (AuthService.instance.isAuthenticated) {
        Future.microtask(() => uploadToCloud());
      }
    } catch (_) {}
  }
}
