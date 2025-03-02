import 'package:shared_preferences/shared_preferences.dart';

class ChatLimiter {
  static const String _keyChatCount = 'chat_count';
  static const String _keyLastReset = 'chat_last_reset';
  static const int dailyLimit = 50;

  // Retrieve the current chat count, resetting if a new day has started.
  Future<int> getChatCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNeeded(prefs);
    return prefs.getInt(_keyChatCount) ?? 0;
  }

  // Increments the chat count.
  Future<void> incrementChatCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNeeded(prefs);
    int currentCount = prefs.getInt(_keyChatCount) ?? 0;
    await prefs.setInt(_keyChatCount, currentCount + 1);
  }

  // Checks whether the user can still chat today.
  Future<bool> canChat() async {
    int count = await getChatCount();
    return count < dailyLimit;
  }

  Future<bool> reachChatLimit() async {
    int count = await getChatCount();
    return count >= dailyLimit;
  }

  // Private method to reset the counter if it's a new day.
  Future<void> _resetIfNeeded(SharedPreferences prefs) async {
    final String? lastReset = prefs.getString(_keyLastReset);
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastReset != today) {
      await prefs.setString(_keyLastReset, today);
      await prefs.setInt(_keyChatCount, 0);
    }
  }

  // Resets the daily chat count (used for testing).
  Future<void> resetDailyChatCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_keyLastReset, today);
    await prefs.setInt(_keyChatCount, 0);
  }
}
