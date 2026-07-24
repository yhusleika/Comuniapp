import 'package:flutter/material.dart';
import '../../core/services/sync_manager.dart';
import '../../core/di/injection_container.dart';

class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner>
    with SingleTickerProviderStateMixin {
  late final SyncManager _syncManager;
  late final AnimationController _animController;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _syncManager = sl<SyncManager>();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _syncManager.addListener(_onSyncStateChanged);
    _checkInitialState();
  }

  void _checkInitialState() {
    if (_syncManager.state != SyncStateEnum.idle &&
        _syncManager.message.isNotEmpty) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _syncManager.removeListener(_onSyncStateChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onSyncStateChanged() {
    if (!mounted) return;

    if (_syncManager.state != SyncStateEnum.idle &&
        _syncManager.message.isNotEmpty) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _syncManager.state;
    final message = _syncManager.message;

    Color backgroundColor;
    Widget iconWidget;

    switch (state) {
      case SyncStateEnum.syncing:
        backgroundColor = const Color(0xFF1E88E5); // Azul brillante
        iconWidget = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
        break;

      case SyncStateEnum.synced:
        backgroundColor = const Color(0xFF2E7D32); // Verde esmeralda
        iconWidget = const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 18);
        break;

      case SyncStateEnum.offline:
        backgroundColor = const Color(0xFFE65100); // Ámbar/Naranja intenso
        iconWidget = const Icon(Icons.wifi_off_rounded,
            color: Colors.white, size: 18);
        break;

      case SyncStateEnum.idle:
        backgroundColor = Colors.transparent;
        iconWidget = const SizedBox.shrink();
        break;
    }

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 4.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      iconWidget,
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
