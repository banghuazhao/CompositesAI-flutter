import 'package:swiftcomp/util/others.dart';

class FeedbackIdCache {
  static String _key(String chatId, String messageId) =>
      'feedbackId:$chatId:$messageId';

  static String? getFeedbackId(String chatId, String messageId) {
    return SharedPreferencesHelper.localStorage
        .getString(_key(chatId, messageId));
  }

  static Future<void> setFeedbackId(
    String chatId,
    String messageId,
    String feedbackId,
  ) async {
    await SharedPreferencesHelper.localStorage.setString(
      _key(chatId, messageId),
      feedbackId,
    );
  }
}

