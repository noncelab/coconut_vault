import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/icon_util.dart';
import 'package:coconut_vault/widgets/indicator/gradient_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

enum BackupRecoveryStep { ready, progressing, completion }

class BackupRecoveryScreen extends StatefulWidget {
  const BackupRecoveryScreen({super.key});

  @override
  State<BackupRecoveryScreen> createState() => _BackupRecoveryScreenState();
}

class _BackupRecoveryScreenState extends State<BackupRecoveryScreen>
    with TickerProviderStateMixin {
  BackupRecoveryStep _step = BackupRecoveryStep.ready;
  String _title = t.backup_recovery.found_title;
  String _desc = t.backup_recovery.found_description;

  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> nextStep() async {
    if (_step == BackupRecoveryStep.ready) {
      _step = BackupRecoveryStep.progressing;
      _title = t.backup_recovery.in_progress_title;
      _desc = t.backup_recovery.in_progress_description;
      _startProgress();
    } else if (_step == BackupRecoveryStep.progressing) {
      _step = BackupRecoveryStep.completion;
      _title = t.backup_recovery.completed_title;
      _desc = t.backup_recovery.completed_description(count: 3);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (Route<dynamic> route) => false,
      );
    }

    setState(() {});
  }

  void _startProgress() {
    if (_progressController.isAnimating) {
      _progressController.stop();
      return;
    }

    // 실제 복구 처리 연동
    _progressController.duration = const Duration(seconds: 3);
    _progressController.forward();
    _progressController.addListener(() {
      setState(() {});
    });
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        nextStep();
      }
    });
  }

  Widget walletRow() {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.18),
            spreadRadius: 4,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
              width: 22,
              height: 22,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: BackgroundColorPalette[0],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: SvgPicture.asset(
                CustomIcons.getPathByIndex(0),
                colorFilter: ColorFilter.mode(ColorPalette[0], BlendMode.srcIn),
              )),
          const SizedBox(width: 4),
          const Text('일반 지갑', style: CoconutTypography.body2_14),
          const Spacer(),
          Text('0000000', style: CoconutTypography.body3_12_Number)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          body: Container(
            width: MediaQuery.sizeOf(context).width,
            padding: const EdgeInsets.symmetric(
              horizontal: CoconutLayout.defaultPadding,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: kToolbarHeight + 100),
                      Text(
                        _title,
                        style: CoconutTypography.heading4_18_Bold,
                      ),
                      CoconutLayout.spacing_500h,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _desc,
                          style: _step == BackupRecoveryStep.ready
                              ? CoconutTypography.body2_14
                              : CoconutTypography.body2_14_Bold,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity:
                            _step == BackupRecoveryStep.completion ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              walletRow(),
                              const SizedBox(height: 16),
                              walletRow(),
                              const SizedBox(height: 16),
                              walletRow(),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                if (_step == BackupRecoveryStep.progressing)
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GradientCircularProgressIndicator(
                          radius: 90,
                          gradientColors: const [
                            Colors.white,
                            Color.fromARGB(255, 164, 214, 250),
                          ],
                          strokeWidth: 36.0,
                          progress: _progressController.value > 0
                              ? _progressController.value
                              : 0.01,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (_progressController.value * 100)
                                  .toStringAsFixed(0),
                              style: CoconutTypography.heading1_32_Bold
                                  .setColor(const Color(0xFF1E88E5))
                                  .merge(const TextStyle(
                                      fontWeight: FontWeight.w900)),
                            ),
                            CoconutLayout.spacing_100w,
                            Text(
                              '%',
                              style: CoconutTypography.body1_16_Bold
                                  .setColor(const Color(0xFF42A5F5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (_step != BackupRecoveryStep.progressing)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: CoconutButton(
                      disabledBackgroundColor: CoconutColors.gray400,
                      width: double.infinity,
                      text: _step == BackupRecoveryStep.ready
                          ? t.restore
                          : t.backup_recovery.start_vault,
                      onPressed: () {
                        nextStep();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ));
  }
}
