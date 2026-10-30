import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewHelper {
  static String openCount = "openCount";
  static InAppReview inAppReview = InAppReview.instance;

  static Future<void> incrementOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(openCount) ?? 0;
    if (!await prefs.setInt(openCount, count + 1)) {
      throw StateError('The app open count could not be saved.');
    }
  }

  static Future<void> checkAndAskForReview() async {
    try {
      await incrementOpenCount();
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(openCount);
      if (count == 3 || count == 15 || count == 100) {
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        }
      }
    } catch (_) {
      // Review availability, window readiness and storage are best effort.
      // None of them may interrupt app startup.
    }
  }
}
