import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/device.dart';
import '../providers/multi_device_provider.dart';
import '../screens/devices/device_detail_screen.dart';

class MultiDeviceView extends StatefulWidget {
  const MultiDeviceView({super.key});

  @override
  State<MultiDeviceView> createState() => _MultiDeviceViewState();
}

class _MultiDeviceViewState extends State<MultiDeviceView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MultiDeviceProvider>();
    _tabController = TabController(
      length: provider.openDevices.length,
      vsync: this,
      initialIndex: provider.activeIndex,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<MultiDeviceProvider>();
    if (_tabController.length != provider.openDevices.length) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: provider.openDevices.length,
        vsync: this,
        initialIndex: oldIndex < provider.openDevices.length ? oldIndex : provider.openDevices.length - 1,
      );
      _tabController.addListener(_onTabChanged);
    }
    if (_tabController.index != provider.activeIndex) {
      _tabController.animateTo(provider.activeIndex);
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<MultiDeviceProvider>().setActiveIndex(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MultiDeviceProvider>();
    
    if (!provider.hasOpenDevices) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                    tabs: provider.openDevices.map((device) {
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              device.model.length > 15 
                                  ? '${device.model.substring(0, 15)}...' 
                                  : device.model,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                provider.closeDevice(device.deviceId);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => provider.closeAll(),
                  tooltip: 'Close all',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: provider.openDevices.map((device) {
                return DeviceDetailScreen(device: device);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

