import 'package:flutter/foundation.dart';
import '../../data/models/device.dart';

class MultiDeviceProvider extends ChangeNotifier {
  final List<Device> _openDevices = [];
  int _activeIndex = 0;

  List<Device> get openDevices => _openDevices;
  int get activeIndex => _activeIndex;
  bool get hasOpenDevices => _openDevices.isNotEmpty;

  void openDevice(Device device) {
    if (!_openDevices.any((d) => d.deviceId == device.deviceId)) {
      _openDevices.add(device);
      _activeIndex = _openDevices.length - 1;
      notifyListeners();
    } else {
      _activeIndex = _openDevices.indexWhere((d) => d.deviceId == device.deviceId);
      notifyListeners();
    }
  }

  void closeDevice(String deviceId) {
    final index = _openDevices.indexWhere((d) => d.deviceId == deviceId);
    if (index != -1) {
      _openDevices.removeAt(index);
      if (_activeIndex >= _openDevices.length && _openDevices.isNotEmpty) {
        _activeIndex = _openDevices.length - 1;
      } else if (_openDevices.isEmpty) {
        _activeIndex = 0;
      }
      notifyListeners();
    }
  }

  void setActiveIndex(int index) {
    if (index >= 0 && index < _openDevices.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void closeAll() {
    _openDevices.clear();
    _activeIndex = 0;
    notifyListeners();
  }
}


