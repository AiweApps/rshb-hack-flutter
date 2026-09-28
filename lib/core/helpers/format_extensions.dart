extension DurationFormat on int {
  String get formattedDuration {
    final minutes = this ~/ 60;
    final remainingSeconds = this % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
