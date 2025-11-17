import 'package:flutter/foundation.dart';
import 'view_state.dart';

/// Base ViewModel class that all ViewModels should extend
/// Provides common functionality for state management and error handling
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  ViewError? _error;
  String? _successMessage;

  /// Current state of the view
  ViewState get state => _state;

  /// Current error if state is error
  ViewError? get error => _error;

  /// Success message if any
  String? get successMessage => _successMessage;

  /// Convenience getters for state checks
  bool get isIdle => _state == ViewState.idle;
  bool get isBusy => _state == ViewState.busy;
  bool get isError => _state == ViewState.error;
  bool get isSuccess => _state == ViewState.success;
  bool get hasError => _error != null;

  /// Set the view state
  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Set busy state
  void setBusy() {
    setState(ViewState.busy);
  }

  /// Set idle state
  void setIdle() {
    _error = null;
    _successMessage = null;
    setState(ViewState.idle);
  }

  /// Set error state with error information
  void setError(String message, {dynamic error, StackTrace? stackTrace}) {
    _error = ViewError(
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    setState(ViewState.error);
    
    // Log error in debug mode
    if (kDebugMode) {
      print('ViewModel Error: $message');
      if (error != null) print('Error details: $error');
      if (stackTrace != null) print('Stack trace: $stackTrace');
    }
  }

  /// Set success state with optional message
  void setSuccess([String? message]) {
    _error = null;
    _successMessage = message;
    setState(ViewState.success);
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_state == ViewState.error) {
      setIdle();
    }
  }

  /// Clear success message
  void clearSuccess() {
    _successMessage = null;
    if (_state == ViewState.success) {
      setIdle();
    }
  }

  /// Execute an async operation with automatic state management
  /// Handles busy state, error catching, and state updates
  Future<T?> runBusyFuture<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool setIdleOnSuccess = true,
  }) async {
    try {
      setBusy();
      final result = await operation();
      if (setIdleOnSuccess) {
        setIdle();
      }
      return result;
    } catch (e, stackTrace) {
      setError(
        errorMessage ?? 'An error occurred',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Execute an async operation with success message
  Future<T?> runBusyFutureWithSuccess<T>(
    Future<T> Function() operation, {
    required String successMessage,
    String? errorMessage,
  }) async {
    try {
      setBusy();
      final result = await operation();
      setSuccess(successMessage);
      return result;
    } catch (e, stackTrace) {
      setError(
        errorMessage ?? 'An error occurred',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
