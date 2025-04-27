import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/models/profile.dart'; // Nhớ import lớp Profile
import 'dart:developer' as developer;

class PrefData {
  static String prefName = "com.example.shopping";

  static String introAvailable = prefName + "isIntroAvailable";
  static String isLoggedIn = prefName + "isLoggedIn";
  static String token = prefName + "token";
  static String profile =
      prefName + "profile"; // Khóa lưu trữ thông tin profile

  // Token caching system
  static String? _cachedToken;
  static DateTime? _tokenCacheTime;
  static const Duration _tokenCacheExpiry = Duration(minutes: 5);

  // Authentication status caching
  static bool? _cachedAuthStatus;
  static DateTime? _authStatusCacheTime;
  static const Duration _authStatusCacheExpiry = Duration(seconds: 30);

  static Future<SharedPreferences> getPrefInstance() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences;
  }

  static Future<bool> isIntroAvailable() async {
    SharedPreferences preferences = await getPrefInstance();
    bool isIntroAvailable = preferences.getBool(introAvailable) ?? true;
    return isIntroAvailable;
  }

  static setIntroAvailable(bool avail) async {
    SharedPreferences preferences = await getPrefInstance();
    await preferences.setBool(introAvailable, avail);
  }

  static Future<bool> setLogIn(bool avail) async {
    try {
      SharedPreferences preferences = await getPrefInstance();
      bool result = await preferences.setBool(isLoggedIn, avail);
      developer.log('Setting login status to $avail, result: $result',
          name: 'PrefData');
      return result;
    } catch (e) {
      developer.log('Error setting login status: $e', name: 'PrefData');
      return false;
    }
  }

  static Future<bool> isLogIn() async {
    try {
      SharedPreferences preferences = await getPrefInstance();
      bool loginStatus = preferences.getBool(isLoggedIn) ?? false;
      developer.log('Retrieved login status: $loginStatus', name: 'PrefData');
      return loginStatus;
    } catch (e) {
      developer.log('Error getting login status: $e', name: 'PrefData');
      return false;
    }
  }

  // Lưu token vào SharedPreferences
  static Future<bool> setToken(String mtoken) async {
    try {
      SharedPreferences preferences = await getPrefInstance();
      bool result = await preferences.setString(token, mtoken);
      developer.log('Setting token, success: $result', name: 'PrefData');

      // Update cache when token is set
      _cachedToken = mtoken;
      _tokenCacheTime = DateTime.now();

      // Clear auth status cache when token changes
      _cachedAuthStatus = null;

      return result;
    } catch (e) {
      developer.log('Error setting token: $e', name: 'PrefData');
      return false;
    }
  }

  static Future<String> getToken() async {
    try {
      // Use cached token if available and not expired
      final now = DateTime.now();
      if (_cachedToken != null &&
          _tokenCacheTime != null &&
          now.difference(_tokenCacheTime!) < _tokenCacheExpiry) {
        // Use cached token
        return _cachedToken!;
      }

      // Otherwise get from SharedPreferences
      SharedPreferences preferences = await getPrefInstance();
      String tokenvalue = preferences.getString(token) ?? '';

      // Cache the token for future use
      _cachedToken = tokenvalue;
      _tokenCacheTime = now;

      // Only log when debugging needed
      // developer.log('Retrieved token length: ${tokenvalue.length}', name: 'PrefData');
      return tokenvalue;
    } catch (e) {
      developer.log('Error getting token: $e', name: 'PrefData');
      return '';
    }
  }

  /// Utility method to check authentication status (token AND login flag)
  static Future<bool> isAuthenticated() async {
    try {
      // Use cached auth status if available and not expired
      final now = DateTime.now();
      if (_cachedAuthStatus != null &&
          _authStatusCacheTime != null &&
          now.difference(_authStatusCacheTime!) < _authStatusCacheExpiry) {
        // Use cached auth status
        return _cachedAuthStatus!;
      }

      // Get token from cache if possible
      String tokenValue = _cachedToken ?? '';
      if (tokenValue.isEmpty) {
        // Not in cache, get from storage
        tokenValue = await getToken();
      }

      bool hasToken = tokenValue.isNotEmpty;

      // Quick check - if no token, definitely not authenticated
      if (!hasToken) {
        _cachedAuthStatus = false;
        _authStatusCacheTime = now;
        return false;
      }

      // Check login flags from SharedPreferences
      SharedPreferences preferences = await getPrefInstance();
      bool loginStatus1 = preferences.getBool(isLoggedIn) ?? false;
      bool loginStatus2 = preferences.getBool('isLoggedIn') ?? false;
      bool loginStatus3 =
          preferences.getBool('com.example.shoppingisLoggedIn') ?? false;
      bool currentSessionLoggedIn =
          preferences.getBool('currentSessionLoggedIn') ?? false;

      // Consider logged in if ANY of the keys are set to true
      bool loginStatus = loginStatus1 ||
          loginStatus2 ||
          loginStatus3 ||
          currentSessionLoggedIn;

      // Reduce excessive logging - only log when debugging is needed
      // developer.log('Authentication check details:', name: 'PrefData');
      // developer.log('- Token exists: $hasToken (length: ${tokenValue.length})',
      //     name: 'PrefData');
      // developer.log('- Login flag standard key: $loginStatus1',
      //     name: 'PrefData');
      // developer.log('- Login flag simple key: $loginStatus2', name: 'PrefData');
      // developer.log('- Login flag full key: $loginStatus3', name: 'PrefData');
      // developer.log('- Current session login flag: $currentSessionLoggedIn',
      //     name: 'PrefData');
      // developer.log('- Final login status: $loginStatus', name: 'PrefData');

      bool isAuth = loginStatus && hasToken;

      // Cache the result
      _cachedAuthStatus = isAuth;
      _authStatusCacheTime = now;

      // Only log final result when needed
      // developer.log('Final authentication result: $isAuth', name: 'PrefData');
      return isAuth;
    } catch (e) {
      developer.log('Error checking authentication: $e', name: 'PrefData');
      return false;
    }
  }

  /// Completely clear authentication state
  static Future<bool> logout() async {
    try {
      SharedPreferences preferences = await getPrefInstance();

      // Clear ALL authentication flags
      await preferences.setBool(isLoggedIn, false);
      await preferences.setBool('isLoggedIn', false);
      await preferences.setBool('com.example.shoppingisLoggedIn', false);
      await preferences.setBool('currentSessionLoggedIn', false);

      // Clear token
      await preferences.setString(token, '');
      await preferences.remove('token');

      // Clear user data
      await preferences.remove('userId');
      await preferences.remove('userName');
      await preferences.remove('userEmail');
      await preferences.remove('userRole');
      await preferences.remove('userPhoto');
      await preferences.remove('googleId');
      await preferences.remove('isGoogleAccount');

      // Clear caches
      _cachedToken = null;
      _tokenCacheTime = null;
      _cachedAuthStatus = false;
      _authStatusCacheTime = DateTime.now();

      developer.log('Logout completed - all auth flags cleared',
          name: 'PrefData');
      return true;
    } catch (e) {
      developer.log('Error during logout: $e', name: 'PrefData');
      return false;
    }
  }

  // Lưu thông tin profile vào SharedPreferences
  static Future<void> setProfile(Profile profile) async {
    SharedPreferences preferences = await getPrefInstance();
    String profileJson =
        jsonEncode(profile.toJson()); // Chuyển Profile thành JSON
    await preferences.setString(
        PrefData.profile, profileJson); // Lưu vào SharedPreferences
  }

  // Lấy thông tin profile từ SharedPreferences
  static Future<Profile?> getProfile() async {
    SharedPreferences preferences = await getPrefInstance();
    String? profileJson = preferences
        .getString(PrefData.profile); // Lấy dữ liệu từ SharedPreferences
    if (profileJson != null) {
      Map<String, dynamic> profileMap =
          jsonDecode(profileJson); // Chuyển JSON thành Map
      return Profile.fromJson(profileMap); // Trả về đối tượng Profile
    }
    return null; // Trả về null nếu không tìm thấy profile
  }
}
