import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/start_guide/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _accentColor = Color(0x80A364D9);
const _pageBottomInset = 76.0;
const _indicatorBottom = 140.0;
const _indicatorSize = 7.0;
const _imageIndicatorSpacing = 30.0;
const _contentBottomPadding = _indicatorBottom + _indicatorSize + _imageIndicatorSpacing - _pageBottomInset;

class LiteStartGuideScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const LiteStartGuideScreen({super.key, required this.onComplete});

  @override
  State<LiteStartGuideScreen> createState() => _LiteStartGuideScreenState();
}

class _LiteStartGuideScreenState extends State<LiteStartGuideScreen> {
  bool _isLiteOnboardingComplete = false;

  @override
  Widget build(BuildContext context) {
    if (_isLiteOnboardingComplete) {
      return WelcomeScreen(onComplete: widget.onComplete);
    }

    return LiteOnboardingScreen(onComplete: () => setState(() => _isLiteOnboardingComplete = true));
  }
}

class LiteOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const LiteOnboardingScreen({super.key, required this.onComplete});

  @override
  State<LiteOnboardingScreen> createState() => _LiteOnboardingScreenState();
}

class _LiteOnboardingScreenState extends State<LiteOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      label: t.lite_onboarding_screen.page_1.label,
      title: t.lite_onboarding_screen.page_1.title,
      description: t.lite_onboarding_screen.page_1.description,
      iconPath: 'assets/svg/wallet-plus.svg',
      imagePath: 'assets/png/lite-onboarding/load-wallet.png',
    ),
    _OnboardingPageData(
      label: t.lite_onboarding_screen.page_2.label,
      title: t.lite_onboarding_screen.page_2.title,
      description: t.lite_onboarding_screen.page_2.description,
      iconPath: 'assets/svg/signature.svg',
      imagePath: 'assets/png/lite-onboarding/sign-transaction.png',
    ),
    _OnboardingPageData(
      label: t.lite_onboarding_screen.page_3.label,
      title: t.lite_onboarding_screen.page_3.title,
      description: t.lite_onboarding_screen.page_3.description,
      iconPath: 'assets/svg/eraser.svg',
      imagePath: 'assets/png/lite-onboarding/erase-wallet.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _movePage(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                bottom: _pageBottomInset,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: _indicatorBottom,
                child: _PageIndicator(pageCount: _pages.length, currentPage: _currentPage),
              ),
              Positioned(left: 16, right: 16, bottom: 12, child: _buildNavigation()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == _pages.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isFirstPage)
          _TextNavigationButton(text: t.lite_onboarding_screen.skip, onPressed: widget.onComplete)
        else
          _IconNavigationButton(icon: Icons.chevron_left_rounded, onPressed: () => _movePage(_currentPage - 1)),
        if (isLastPage)
          _TextNavigationButton(text: t.lite_onboarding_screen.start, onPressed: widget.onComplete)
        else
          _IconNavigationButton(icon: Icons.chevron_right_rounded, onPressed: () => _movePage(_currentPage + 1)),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, _contentBottomPadding),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: CoconutColors.gray150, shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(11.5),
              child: SvgPicture.asset(
                data.iconPath,
                colorFilter: const ColorFilter.mode(CoconutColors.gray800, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(data.label, style: CoconutTypography.body2_14_Bold.setColor(_accentColor), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(data.title, style: CoconutTypography.heading3_21_Bold, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            data.description,
            style: CoconutTypography.body3_12.setColor(CoconutColors.gray700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240, maxHeight: 200),
                child: Image.asset(data.imagePath, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;

  const _PageIndicator({required this.pageCount, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _indicatorSize,
          height: _indicatorSize,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: index == currentPage ? _accentColor : CoconutColors.gray300,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _TextNavigationButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _TextNavigationButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: CoconutColors.gray900,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        textStyle: CoconutTypography.body2_14,
      ),
      child: Text(text),
    );
  }
}

class _IconNavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconNavigationButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: CoconutColors.gray900),
      iconSize: 26,
      padding: EdgeInsets.zero,
    );
  }
}

class _OnboardingPageData {
  final String label;
  final String title;
  final String description;
  final String iconPath;
  final String imagePath;

  const _OnboardingPageData({
    required this.label,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.imagePath,
  });
}
