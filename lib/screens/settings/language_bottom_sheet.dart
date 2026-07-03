import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/constants/app_language.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class LanguageBottomSheet extends StatefulWidget {
  const LanguageBottomSheet({super.key});

  @override
  State<LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<LanguageBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Selector<VisibilityProvider, AppLanguage>(
      selector: (_, viewModel) => viewModel.appLanguage,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: CoconutColors.white,
          appBar: CoconutAppBar.build(
            title: t.language.language,
            context: context,
            onBackPressed: null,
            isBottom: true,
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: Sizes.size16, right: Sizes.size16),
            child: Column(
              children: [
                _buildUnitItem(t.language.korean, t.language.korean, language == AppLanguage.ko, () async {
                  // 언어 변경 전에 BottomSheet를 먼저 닫기
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }

                  // 언어 변경은 BottomSheet가 닫힌 후에 실행 (UI 블락 방지)
                  await context.read<VisibilityProvider>().changeLanguage(AppLanguage.ko);
                }),
                Divider(color: CoconutColors.black.withValues(alpha: 0.12), height: 1),
                _buildUnitItem(t.language.english, t.language.english, language == AppLanguage.en, () async {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                  // 언어 변경은 BottomSheet가 닫힌 후에 실행
                  await context.read<VisibilityProvider>().changeLanguage(AppLanguage.en);
                }),
                Divider(color: CoconutColors.black.withValues(alpha: 0.12), height: 1),
                _buildUnitItem(t.language.japanese, t.language.japanese, language == AppLanguage.ja, () async {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                  await context.read<VisibilityProvider>().changeLanguage(AppLanguage.ja);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitItem(String title, String subtitle, bool isChecked, VoidCallback onPress) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: Sizes.size20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(title, style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.black))],
              ),
            ),
            if (isChecked)
              Padding(
                padding: const EdgeInsets.only(right: Sizes.size8),
                child: SvgPicture.asset(
                  'assets/svg/check.svg',
                  colorFilter: const ColorFilter.mode(CoconutColors.black, BlendMode.srcIn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
