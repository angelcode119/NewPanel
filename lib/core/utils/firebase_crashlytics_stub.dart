class FirebaseCrashlytics {
  static final FirebaseCrashlytics instance = FirebaseCrashlytics._();

  FirebaseCrashlytics._();

  Future<void> recordFlutterFatalError(dynamic details) async {}

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
    Iterable<Object> information = const [],
  }) async {}
}

