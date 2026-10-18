class ScheduledShutdownState {
  final bool isActive;
  final DateTime? targetTime;
  final String? reason;

  const ScheduledShutdownState({
    required this.isActive,
    this.targetTime,
    this.reason,
  });

  const ScheduledShutdownState.inactive()
      : isActive = false,
        targetTime = null,
        reason = null;

  ScheduledShutdownState.active({
    required this.targetTime,
    this.reason,
  }) : isActive = true;

  Duration? get remainingDuration {
    if (!isActive || targetTime == null) return null;
    final diff = targetTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
