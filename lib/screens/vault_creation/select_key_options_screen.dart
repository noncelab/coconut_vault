import 'package:coconut_vault/widgets/button/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';

class SelectKeyOptionsScreen extends StatefulWidget {
  const SelectKeyOptionsScreen({super.key});

  @override
  State<SelectKeyOptionsScreen> createState() => _SelectKeyOptionsScreenState();
}

class _SelectKeyOptionsScreenState extends State<SelectKeyOptionsScreen> {
  late int mCount; // 필요한 서명 수
  late int nCount; // 전체 키의 수
  bool nextButtonEnabled = false;
  @override
  void initState() {
    super.initState();
    mCount = 1;
    nCount = 2;
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          nextButtonEnabled = true;
        });
      }
    });
  }

  bool _checkNextButtonActiveState() {
    if (!nextButtonEnabled) return false;
    if (mCount > 0 && mCount <= nCount && nCount > 1 && nCount <= 3) {
      return true;
    }
    return false;
  }

  void onCountButtonClicked(ChangeCountButtonType buttonType) {
    if (!nextButtonEnabled) {
      setState(() {
        nextButtonEnabled = true;
      });
    }
    switch (buttonType) {
      case ChangeCountButtonType.mCountMinus:
        {
          if (mCount == 1) return;

          setState(() {
            mCount--;
          });
          break;
        }
      case ChangeCountButtonType.mCountPlus:
        {
          if (mCount == nCount) return;
          setState(() {
            mCount++;
          });
          break;
        }

      case ChangeCountButtonType.nCountMinus:
        {
          if (nCount == 2) return;
          setState(() {
            if (nCount == mCount) {
              mCount--;
            }
            nCount--;
          });
          break;
        }
      case ChangeCountButtonType.nCountPlus:
        {
          if (nCount == 3) return;
          setState(() {
            nCount++;
          });
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.buildWithNext(
        title: '다중 서명 지갑',
        context: context,
        onNextPressed: () => Navigator.pushNamed(context, '/assign-key',
            arguments: {'nKeyCount': nCount, 'mKeyCount': mCount}),
        isActive: _checkNextButtonActiveState(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      '전체 키의 수',
                      style: Styles.body2Bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CountingRowButton(
                  onMinusPressed: () =>
                      onCountButtonClicked(ChangeCountButtonType.nCountMinus),
                  onPlusPressed: () =>
                      onCountButtonClicked(ChangeCountButtonType.nCountPlus),
                  countText: nCount.toString(),
                  isMinusButtonDisabled: nCount <= 2,
                  isPlusButtonDisabled: nCount >= 3,
                ),
                const SizedBox(
                  width: 18,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      '필요한 서명 수',
                      style: Styles.body2Bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CountingRowButton(
                  onMinusPressed: () =>
                      onCountButtonClicked(ChangeCountButtonType.mCountMinus),
                  onPlusPressed: () =>
                      onCountButtonClicked(ChangeCountButtonType.mCountPlus),
                  countText: mCount.toString(),
                  isMinusButtonDisabled: mCount <= 1,
                  isPlusButtonDisabled: mCount == nCount,
                ),
                const SizedBox(
                  width: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum ChangeCountButtonType { nCountMinus, nCountPlus, mCountMinus, mCountPlus }
