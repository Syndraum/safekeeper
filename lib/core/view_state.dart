/// Represents the different states a view can be in
enum ViewState {
  idle,
  busy,
  error,
  success,
}

/// A class to hold error information
class ViewError {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  ViewError({
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() => message;
}
