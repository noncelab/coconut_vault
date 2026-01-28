import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/adaptive_qr_image.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:flutter/material.dart';

class QrWithCopyTextScreen extends StatefulWidget {
  final String title;
  final Widget? tooltipDescription;
  final String qrData;
  final Map<String, String>? qrDataMap;
  final Map<String, String>? textDataMap;
  final RichText? textRichText;
  final Widget? footer;
  final bool showPulldownMenu;

  const QrWithCopyTextScreen({
    super.key,
    required this.title,
    this.tooltipDescription,
    required this.qrData,
    this.qrDataMap,
    this.textDataMap,
    this.textRichText,
    this.footer,
    this.showPulldownMenu = false,
  });

  @override
  State<QrWithCopyTextScreen> createState() => _QrWithCopyTextScreenState();
}

class _QrWithCopyTextScreenState extends State<QrWithCopyTextScreen> {
  final GlobalKey _pulldownKey = GlobalKey();

  bool _isPulldownOpen = false;

  String _selectedKey = "BSMS";

  final Map<String, String> _optionMap = {
    "BSMS": "BSMS",
    "BlueWallet Vault Multisig": "BlueWallet",
    "Coldcard Multisig": "Coldcard",
    "Keystone Multisig": "Keystone",
    "Output Descriptor": "Descriptor",
    "Specter Desktop": "Specter",
  };

  List<String> get _optionTitles => _optionMap.keys.toList();

  int get _selectedIndex => _optionTitles.indexOf(_selectedKey);

  String get _displayTitle => _optionMap[_selectedKey] ?? _selectedKey;

  double _calcQrWidth(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.76;
  }

  String get _currentQrData {
    if (!widget.showPulldownMenu) {
      return widget.qrData;
    }

    if (widget.qrDataMap == null) {
      return widget.qrData;
    }

    return widget.qrDataMap![_selectedKey] ?? widget.qrData;
  }

  String get _currentTextData {
    if (!widget.showPulldownMenu) {
      return widget.qrData;
    }

    if (widget.textDataMap != null && widget.textDataMap!.containsKey(_selectedKey)) {
      return widget.textDataMap![_selectedKey]!;
    }

    if (widget.qrDataMap != null && widget.qrDataMap!.containsKey(_selectedKey)) {
      return widget.qrDataMap![_selectedKey]!;
    }

    return widget.qrData;
  }

  void _showDropdownMenu() {
    final RenderBox? renderBox = _pulldownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.transparent,
            transitionDuration: Duration.zero,
            pageBuilder: (context, _, __) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.translucent,
                      child: const SizedBox.expand(),
                    ),
                    Positioned(
                      top: offset.dy + size.height,
                      right: screenWidth - (offset.dx + size.width),
                      child: CoconutPulldownMenu(
                        entries:
                            _optionTitles.map((key) {
                              return CoconutPulldownMenuItem(title: key);
                            }).toList(),

                        selectedIndex: _selectedIndex,

                        onSelected: (index, title) {
                          setState(() {
                            _selectedKey = _optionTitles[index];
                          });
                          Navigator.pop(context);
                        },

                        backgroundColor: CoconutColors.white,
                        borderRadius: 8,
                        shadowColor: CoconutColors.black.withOpacity(0.1),
                        isSelectedItemBold: true,
                        buttonPadding: const EdgeInsets.only(right: 16, left: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
        .then((_) {
          setState(() {
            _isPulldownOpen = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final qrWidth = _calcQrWidth(context);
    final displayQrData = _currentQrData;
    final displayTextData = _currentTextData;

    return Scaffold(
      backgroundColor: CoconutColors.white,
      appBar: CoconutAppBar.build(
        title: widget.title,
        context: context,
        isBottom: false,
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.tooltipDescription != null) ...[widget.tooltipDescription!],
              if (widget.showPulldownMenu)
                Align(
                  alignment: Alignment.centerRight,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                    child: Container(
                      key: _pulldownKey,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: CoconutColors.gray150, borderRadius: BorderRadius.circular(8)),
                      child: CoconutPulldown(
                        title: _displayTitle,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isOpen: _isPulldownOpen,
                        fontSize: CoconutTypography.body2_14.fontSize,
                        onChanged: (isOpen) {
                          setState(() {
                            _isPulldownOpen = true;
                          });
                          _showDropdownMenu();
                        },
                      ),
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CoconutLayout.spacing_300h,
                    AdaptiveQrImage(qrData: displayQrData),
                    CoconutLayout.spacing_500h,
                    _buildCopyButton(displayTextData, qrWidth),
                    CoconutLayout.spacing_1500h,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyButton(String textData, double qrWidth) {
    return SizedBox(
      width: qrWidth,
      child: CopyTextContainer(
        text: textData,
        textStyle: CoconutTypography.body2_14_Number,
        toastMsg: t.toast.clipboard_copied,
        textRichText: widget.textRichText,
      ),
    );
  }
}
