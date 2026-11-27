const kChatFastPoll = Duration(seconds: 1);
const kChatSlowPoll = Duration(seconds: 5);
const kChatActiveWindow = Duration(seconds: 30);

Duration nextChatPollDelay({
  required DateTime now,
  required DateTime? lastActivity,
  required bool lastPollFailed,
}) {
  if (lastPollFailed) return kChatSlowPoll;
  if (lastActivity != null && now.difference(lastActivity) < kChatActiveWindow) {
    return kChatFastPoll;
  }
  return kChatSlowPoll;
}

