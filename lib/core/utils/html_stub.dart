// Stub file for non-web platforms
// This file provides empty implementations for web-only functionality

library html_stub;

class WindowLocation {
  String get href => '';
  String get hash => '';
  set hash(String value) {}
  
  String get origin => '';
  String get pathname => '';
}

class Window {
  static final Window _instance = Window._();
  factory Window() => _instance;
  Window._();
  
  static WindowLocation get location => WindowLocation();
  
  void open(String url, String target) {}
  
  Stream<Event> get onHashChange => const Stream<Event>.empty();
}

class Event {}
