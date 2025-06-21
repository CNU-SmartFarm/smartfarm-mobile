import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/api_service.dart';
import '../helpers/cache_helper.dart';
import '../helpers/network_helper.dart';
import '../helpers/database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  Settings? _settings;
  bool _isLoading = false;
  String? _error;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Getters
  Settings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get pushNotificationEnabled => _settings?.pushNotificationEnabled ?? true;
  String get language => _settings?.language ?? 'ko';
  String get theme => _settings?.theme ?? 'light';

  // 로딩 상태 관리
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // 에러 상태 관리
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  // 설정 초기화
  Future<void> initializeSettings() async {
    _setLoading(true);
    _setError(null);

    try {
      // 1. 먼저 캐시에서 로드 (빠른 UI 응답)
      await _loadCachedSettings();

      // 2. 네트워크가 연결되어 있으면 서버에서 최신 설정 로드
      if (NetworkHelper.isOnline) {
        await _loadServerSettings();
      } else {
        // 3. 오프라인일 경우 로컬 DB에서 로드
        await _loadLocalSettings();
      }

      // 4. 설정이 없으면 기본 설정 생성
      if (_settings == null) {
        await _createDefaultSettings();
      }

      notifyListeners();
    } catch (e) {
      _setError('설정을 불러오는데 실패했습니다: $e');

      // 에러 발생 시에도 기본 설정은 제공
      if (_settings == null) {
        await _createDefaultSettings();
        notifyListeners();
      }

      print('Error initializing settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 캐시에서 설정 로드
  Future<void> _loadCachedSettings() async {
    try {
      final cachedSettings = CacheHelper.getJson(CacheHelper.USER_SETTINGS);
      if (cachedSettings != null) {
        _settings = Settings.fromJson(cachedSettings);
        print('Settings loaded from cache');
      }
    } catch (e) {
      print('Error loading cached settings: $e');
    }
  }

  // 서버에서 설정 로드
  Future<void> _loadServerSettings() async {
    try {
      Settings? serverSettings = await ApiService.getSettings();
      if (serverSettings != null) {
        _settings = serverSettings;

        // 캐시와 로컬 DB에 저장
        await _saveSettingsLocally(serverSettings);

        print('Settings loaded from server');
      }
    } catch (e) {
      print('Error loading server settings: $e');
      // 서버 로드 실패는 치명적이지 않음 (캐시나 기본값 사용)
    }
  }

  // 로컬 DB에서 설정 로드
  Future<void> _loadLocalSettings() async {
    try {
      final localSettings = await _dbHelper.getSettings('user_default');
      if (localSettings != null) {
        _settings = Settings.fromJson(localSettings);
        print('Settings loaded from local DB');
      }
    } catch (e) {
      print('Error loading local settings: $e');
    }
  }

  // 기본 설정 생성
  Future<void> _createDefaultSettings() async {
    try {
      _settings = Settings(
        userId: 'user_default',
        pushNotificationEnabled: true,
        language: 'ko',
        theme: 'light',
      );

      // 기본 설정을 로컬에 저장
      await _saveSettingsLocally(_settings!);

      print('Default settings created');
    } catch (e) {
      print('Error creating default settings: $e');
    }
  }

  // 설정을 로컬에 저장 (캐시 + DB)
  Future<void> _saveSettingsLocally(Settings settings) async {
    try {
      // 캐시에 저장
      await CacheHelper.setJson(CacheHelper.USER_SETTINGS, settings.toJson());

      // 로컬 DB에 저장
      final settingsData = settings.toJson();
      settingsData['lastSynced'] = NetworkHelper.isOnline ? DateTime.now().millisecondsSinceEpoch : 0;
      await _dbHelper.insertOrUpdateSettings(settingsData);
    } catch (e) {
      print('Error saving settings locally: $e');
    }
  }

  // 설정 업데이트
  Future<bool> updateSettings(Settings newSettings) async {
    _setLoading(true);
    _setError(null);

    try {
      Settings? result;

      if (NetworkHelper.isOnline) {
        // 온라인 모드: 서버에 업데이트
        try {
          result = await ApiService.updateSettings(newSettings);
          if (result != null) {
            _settings = result;
            await _saveSettingsLocally(result);
            print('Settings updated on server');
          }
        } catch (e) {
          print('Server update failed: $e');
          // 서버 업데이트 실패 시 로컬에만 저장
          _settings = newSettings;
          await _saveSettingsLocally(newSettings);
          result = newSettings;
          print('Settings updated locally only');
        }
      } else {
        // 오프라인 모드: 로컬에만 저장
        _settings = newSettings;
        await _saveSettingsLocally(newSettings);
        result = newSettings;
        print('Settings updated offline');
      }

      if (result != null) {
        notifyListeners();
        return true;
      } else {
        _setError('설정 업데이트에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('설정 업데이트 중 오류가 발생했습니다: $e');
      print('Error updating settings: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 푸시 알림 토글
  Future<bool> togglePushNotification() async {
    if (_settings == null) return false;

    final updatedSettings = _settings!.copyWith(
      pushNotificationEnabled: !_settings!.pushNotificationEnabled,
    );

    return await updateSettings(updatedSettings);
  }

  // 언어 변경
  Future<bool> changeLanguage(String language) async {
    if (_settings == null) return false;

    if (_settings!.language == language) {
      return true; // 이미 같은 언어
    }

    final updatedSettings = _settings!.copyWith(language: language);
    return await updateSettings(updatedSettings);
  }

  // 테마 변경
  Future<bool> changeTheme(String theme) async {
    if (_settings == null) return false;

    if (_settings!.theme == theme) {
      return true; // 이미 같은 테마
    }

    final updatedSettings = _settings!.copyWith(theme: theme);
    return await updateSettings(updatedSettings);
  }

  // 설정 리셋
  Future<bool> resetSettings() async {
    try {
      final defaultSettings = Settings(
        userId: _settings?.userId ?? 'user_default',
        pushNotificationEnabled: true,
        language: 'ko',
        theme: 'light',
      );

      bool success = await updateSettings(defaultSettings);

      if (success) {
        print('Settings reset to default');
      }

      return success;
    } catch (e) {
      _setError('설정 초기화 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  // 서버와 동기화
  Future<bool> syncWithServer() async {
    if (!NetworkHelper.isOnline) {
      _setError('네트워크 연결을 확인해주세요.');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // 1. 서버에서 최신 설정 가져오기
      Settings? serverSettings = await ApiService.getSettings();

      if (serverSettings != null) {
        // 2. 로컬 설정과 비교하여 더 최신 것 사용
        if (_settings != null) {
          // 로컬에 동기화되지 않은 변경사항이 있는지 확인
          final localData = await _dbHelper.getSettings(_settings!.userId);
          if (localData != null && localData['lastSynced'] == 0) {
            // 로컬 변경사항을 서버로 업로드
            serverSettings = await ApiService.updateSettings(_settings!);
          }
        }

        if (serverSettings != null) {
          _settings = serverSettings;
          await _saveSettingsLocally(serverSettings);
          notifyListeners();
          print('Settings synchronized with server');
          return true;
        }
      }

      _setError('서버 동기화에 실패했습니다.');
      return false;
    } catch (e) {
      _setError('동기화 중 오류가 발생했습니다: $e');
      print('Error syncing settings: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 동기화 상태 확인
  Future<bool> hasUnsyncedChanges() async {
    if (_settings == null) return false;

    try {
      final localData = await _dbHelper.getSettings(_settings!.userId);
      return localData != null && localData['lastSynced'] == 0;
    } catch (e) {
      print('Error checking sync status: $e');
      return false;
    }
  }

  // 네트워크 상태 변경 시 호출
  Future<void> onNetworkStateChanged(bool isOnline) async {
    if (isOnline && _settings != null) {
      // 온라인이 되면 동기화되지 않은 변경사항 확인
      final hasUnsynced = await hasUnsyncedChanges();
      if (hasUnsynced) {
        // 자동으로 동기화 시도
        await syncWithServer();
      }
    }
  }

  // 설정 내보내기 (백업용)
  Map<String, dynamic>? exportSettings() {
    return _settings?.toJson();
  }

  // 설정 가져오기 (복원용)
  Future<bool> importSettings(Map<String, dynamic> settingsData) async {
    try {
      final importedSettings = Settings.fromJson(settingsData);
      return await updateSettings(importedSettings);
    } catch (e) {
      _setError('설정 가져오기에 실패했습니다: $e');
      return false;
    }
  }

  // 설정 검증
  bool validateSettings(Settings settings) {
    // 언어 검증
    final validLanguages = ['ko', 'en'];
    if (!validLanguages.contains(settings.language)) {
      return false;
    }

    // 테마 검증
    final validThemes = ['light', 'dark', 'system'];
    if (!validThemes.contains(settings.theme)) {
      return false;
    }

    // 사용자 ID 검증
    if (settings.userId.isEmpty) {
      return false;
    }

    return true;
  }

  // 설정 통계
  Map<String, dynamic> getSettingsStats() {
    if (_settings == null) {
      return {'error': 'No settings available'};
    }

    return {
      'userId': _settings!.userId,
      'pushNotificationEnabled': _settings!.pushNotificationEnabled,
      'language': _settings!.language,
      'theme': _settings!.theme,
      'lastCacheUpdate': getCacheAge(),
      'hasUnsyncedChanges': false, // 비동기라서 실시간으로는 체크 안함
    };
  }

  // 캐시 나이 확인
  DateTime? getCacheAge() {
    try {
      final cachedSettings = CacheHelper.getJson(CacheHelper.USER_SETTINGS);
      if (cachedSettings != null && cachedSettings['lastUpdated'] != null) {
        return DateTime.parse(cachedSettings['lastUpdated']);
      }
    } catch (e) {
      print('Error getting cache age: $e');
    }
    return null;
  }

  // 에러 클리어
  void clearError() {
    _setError(null);
  }
}