import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewHelper {
  static String openCount = "openCount";
  static InAppReview inAppReview = InAppReview.instance;

  static Future<void> incrementOpenCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? count = prefs.getInt(openCount);
    if (count != null) {
      count += 1;
      prefs.setInt(openCount, count);
    } else {
      prefs.setInt(openCount, 1);
    }
  }

  static Future<void> checkAndAskForReview() async {
    await incrementOpenCount();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? count = prefs.getInt(openCount);

    print("App open count: $count");
    if (count == 3 || count == 15 || count == 100) {
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }
}
