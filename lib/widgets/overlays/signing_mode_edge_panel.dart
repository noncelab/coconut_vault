import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/enums/vault_mode_enum.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class SigningModeEdgePanel extends StatefulWidget {
  const SigningModeEdgePanel({
    super.key,
    required this.navigatorKey,
    required this.routeVisibilityListenable,
    required this.onResetCompleted,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final ValueListenable<bool> routeVisibilityListenable;
  final VoidCallback onResetCompleted;

  @override
  State<SigningModeEdgePanel> createState() => _SigningModeEdgePanelState();
}

class _SigningModeEdgePanelState extends State<SigningModeEdgePanel> with SingleTickerProviderStateMixin {
  static const double _minWidth = 20.0;
  static const double _maxWidth = 100.0;

  double _panelWidth = _minWidth;
  double? _horizontalPos;
  double? _verticalPos;
  bool _isDraggingManually = false;
  bool _isPanningEdgePanel = false;
  bool _isResetDialogOpen = false;

  Timer? _longPressTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey _indicatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.addListener(() {
      setState(() {
        _horizontalPos = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.routeVisibilityListenable,
      builder: (context, hasShow, _) {
        return Consumer<PreferenceProvider>(
          builder: (context, prefProvider, child) {
            final walletProvider = context.watch<WalletProvider>();
            final hasWallets = walletProvider.vaultList.isNotEmpty;
            final isSigningOnly = prefProvider.getVaultMode() == VaultMode.signingOnly;
            final isVisible = hasShow && isSigningOnly && hasWallets;

            _initializePanelPositionIfNeeded(context, prefProvider);
            if (_horizontalPos == null || _verticalPos == null) {
              return const SizedBox.shrink();
            }

            final children = <Widget>[];

            if (isVisible && _panelWidth == _maxWidth) {
              children.add(
                Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) => _handlePointerDownOutside(event, context),
                  child: const SizedBox.expand(),
                ),
              );
            }

            children.add(
              Positioned(
                top: _verticalPos!,
                left: _horizontalPos! <= MediaQuery.sizeOf(context).width / 2 ? _horizontalPos : null,
                right: _horizontalPos! > MediaQuery.sizeOf(context).width / 2 ? _calculateRightOffset(context) : null,
                child: _buildPanel(context, prefProvider, isVisible),
              ),
            );

            if (!isVisible) {
              return const SizedBox.shrink();
            }

            return Stack(children: children);
          },
        );
      },
    );
  }

  void _initializePanelPositionIfNeeded(BuildContext context, PreferenceProvider prefProvider) {
    if (_isDraggingManually || _isPanningEdgePanel) return;

    final savedPos = prefProvider.signingModeEdgePanelPos;
    final savedPosX = savedPos.$1;
    final savedPosY = savedPos.$2;
    final screenWidth = MediaQuery.sizeOf(context).width;

    _horizontalPos ??= savedPosX ?? (screenWidth - _panelWidth - 20);
    _verticalPos ??= savedPosY ?? (kToolbarHeight + 50);
  }

  Widget _buildPanel(BuildContext context, PreferenceProvider prefProvider, bool isVisible) {
    final halfScreenWidth = MediaQuery.sizeOf(context).width / 2;

    return Listener(
      onPointerDown: (details) {
        _longPressTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isDraggingManually = true;
            });
            HapticFeedback.mediumImpact();
          }
        });
      },
      onPointerUp: (details) {
        _longPressTimer?.cancel();
        if (_isDraggingManually) {
          setState(() {
            _horizontalPos = details.position.dx;
          });
          _movePanelToEdge(details, prefProvider);
        }
      },
      onPointerCancel: (details) {
        _longPressTimer?.cancel();
        if (_isDraggingManually) {
          _movePanelToEdge(details, prefProvider);
        }
      },
      onPointerMove: (details) {
        if (_isDraggingManually) {
          setState(() {
            final screenHeight = MediaQuery.of(context).size.height;
            final topPadding = MediaQuery.of(context).padding.top;
            _verticalPos = details.position.dy - (topPadding + kToolbarHeight);
            _verticalPos = _verticalPos!.clamp(topPadding + kToolbarHeight, screenHeight - 100.0);
            _horizontalPos = details.position.dx;
          });
        }
      },
      child: GestureDetector(
        onPanStart: (details) {
          if (!_isDraggingManually) {
            setState(() {
              _isPanningEdgePanel = true;
            });
          }
        },
        onPanUpdate: (details) {
          if (!_isDraggingManually) {
            setState(() {
              _panelWidth -= details.delta.dx;
              _panelWidth = _panelWidth.clamp(_minWidth, _maxWidth);
            });
          }
        },
        onPanEnd: (details) {
          if (!_isDraggingManually) {
            setState(() {
              final isRightSide = _horizontalPos! > MediaQuery.sizeOf(context).width / 2;
              final velocity = details.velocity.pixelsPerSecond.dx;
              if (isRightSide) {
                if (velocity.abs() > 500) {
                  _panelWidth = velocity < 0 ? _maxWidth : _minWidth;
                } else {
                  _panelWidth = _panelWidth > 70 ? _maxWidth : _minWidth;
                }
              } else {
                if (velocity.abs() > 500) {
                  _panelWidth = velocity > 0 ? _maxWidth : _minWidth;
                } else {
                  _panelWidth = _panelWidth > 70 ? _maxWidth : _minWidth;
                }
              }
              _isPanningEdgePanel = false;
            });
          }
        },
        child: AnimatedContainer(
          key: _indicatorKey,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width:
              isVisible
                  ? _isDraggingManually
                      ? 50
                      : _panelWidth + 20 + (_isDraggingManually ? 4 : 0)
                  : 0,
          height: _isDraggingManually ? 50 : 100,
          decoration: BoxDecoration(
            color: _panelWidth != _maxWidth ? CoconutColors.black.withValues(alpha: 0.8) : CoconutColors.black,
            borderRadius: _getBorderRadius(halfScreenWidth),
            border: _isDraggingManually ? Border.all(color: CoconutColors.white, width: 2) : null,
          ),
          child:
              _isDraggingManually
                  ? SizedBox(
                    width: 40,
                    height: double.infinity,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SvgPicture.asset(
                        'assets/svg/eraser.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(CoconutColors.white, BlendMode.srcIn),
                      ),
                    ),
                  )
                  : GestureDetector(
                    onTap: () {
                      if (_panelWidth != _maxWidth) {
                        setState(() {
                          _panelWidth = _maxWidth;
                        });
                      } else {
                        _showResetDialog(context);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          left:
                              _horizontalPos! > halfScreenWidth
                                  ? _panelWidth == _maxWidth
                                      ? (_panelWidth + 20) / 2 - 12
                                      : 10
                                  : null,
                          right:
                              _horizontalPos! <= halfScreenWidth
                                  ? _panelWidth == _maxWidth
                                      ? (_panelWidth + 20) / 2 - 12
                                      : 10
                                  : null,
                          top: _panelWidth == _maxWidth ? 20 : 50 - 12,
                          child: SvgPicture.asset(
                            'assets/svg/eraser.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(CoconutColors.white, BlendMode.srcIn),
                          ),
                        ),
                        if (_panelWidth == _maxWidth)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 30,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _panelWidth == _maxWidth ? 1.0 : 0.0,
                              child: MediaQuery(
                                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      t.delete_vault,
                                      style: CoconutTypography.body2_14_Bold.copyWith(color: CoconutColors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  void _handlePointerDownOutside(PointerDownEvent event, BuildContext context) {
    if (_panelWidth != _maxWidth) return;

    final RenderBox? box = _indicatorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final indicatorArea = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

    if (!indicatorArea.contains(event.position) && mounted) {
      setState(() {
        _panelWidth = _minWidth;
        _isResetDialogOpen = false;
      });
    }
  }

  double? _calculateRightOffset(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (_horizontalPos == null) return null;

    return _panelWidth == _minWidth
        ? screenWidth - _horizontalPos! - (_panelWidth + 20)
        : screenWidth - _horizontalPos! - 40;
  }

  BorderRadius _getBorderRadius(double halfScreenWidth) {
    if (_isDraggingManually) {
      return const BorderRadius.all(Radius.circular(10));
    }

    return _horizontalPos! <= halfScreenWidth
        ? const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))
        : const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10));
  }

  void _movePanelToEdge(PointerEvent details, PreferenceProvider prefProvider) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetPosition = details.position.dx <= screenWidth / 2 ? 0.0 : screenWidth - _minWidth - 20;

    _panelWidth = _minWidth;
    _animation = Tween<double>(
      begin: _horizontalPos ?? targetPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController
      ..reset()
      ..forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _isDraggingManually = false;
        _horizontalPos = targetPosition;
      });
      if (_horizontalPos != null && _verticalPos != null) {
        prefProvider.setSigningModeEdgePanelPos(_horizontalPos!, _verticalPos!);
      }
    });
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final navContext = widget.navigatorKey.currentContext;
    if (navContext == null || _isResetDialogOpen) return;

    final walletProvider = context.read<WalletProvider>();
    _isResetDialogOpen = true;

    if (walletProvider.vaultList.isEmpty) {
      await showDialog<void>(
        context: navContext,
        builder:
            (dialogContext) => CoconutPopup(
              insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(navContext).size.width * 0.15),
              title: t.wallet_delete_failed,
              description: t.wallet_delete_failed_description,
              backgroundColor: CoconutColors.white,
              rightButtonText: t.confirm,
              rightButtonColor: CoconutColors.black,
              onTapRight: () {
                Navigator.pop(dialogContext);
              },
            ),
      );
      _isResetDialogOpen = false;
      return;
    }

    await showDialog<void>(
      context: navContext,
      builder:
          (dialogContext) => CoconutPopup(
            insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(navContext).size.width * 0.15),
            title: t.delete_vault,
            description: t.delete_vault_description,
            backgroundColor: CoconutColors.white,
            leftButtonText: t.cancel,
            rightButtonText: t.confirm,
            rightButtonColor: CoconutColors.black,
            onTapLeft: () {
              Navigator.pop(dialogContext);
            },
            onTapRight: () async {
              Navigator.pop(dialogContext);
              await walletProvider.deleteAllWallets();
              await context.read<PreferenceProvider>().resetVaultOrderAndFavorites();
              widget.onResetCompleted();
            },
          ),
    );

    _isResetDialogOpen = false;
  }
}
