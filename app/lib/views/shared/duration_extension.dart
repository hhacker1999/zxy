extension DurationFormat on Duration {
  String toHourMinutes() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(inMinutes.remainder(60));
    // Use inHours to get total hours (even if > 24)
    return "${inHours}hr ${twoDigitMinutes}min";
  }
}
