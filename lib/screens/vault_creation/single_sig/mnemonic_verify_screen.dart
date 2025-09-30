import 'dart:convert';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/utils/vibration_util.dart';
import 'package:coconut_vault/widgets/button/shrink_animation_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MnemonicVerifyScreen extends StatefulWidget {
  const MnemonicVerifyScreen({super.key});

  @override
  State<MnemonicVerifyScreen> createState() => _MnemonicVerifyScreenState();
}

class _MnemonicVerifyScreenState extends State<MnemonicVerifyScreen> {
  late WalletCreationProvider _walletCreationProvider;

  // 퀴즈 관련 변수
  int _currentQuizIndex = 0; // 현재 퀴즈 인덱스
  final int _totalQuizzes = 5; // 총 퀴즈 개수
  List<int> _selectedWordPositions = []; // 퀴즈로 선택된 니모닉 인덱스
  List<String> _correctAnswers = []; // 정답 단어들
  List<String> _userAnswers = []; // 사용자가 선택한 답들
  List<List<String>> _quizOptions = []; // 각 퀴즈의 선택지들 (4개씩, 중복 없이)

  // UI 상태 변수
  bool _isAnswerCorrect = false; // 현재 퀴즈 정답 여부
  bool _showResult = false; // 결과 표시 여부
  int _selectedOptionIndex = -1; // 선택한 옵션의 인덱스

  List<String> _mnemonic = [];

  @override
  void initState() {
    super.initState();
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false);
    _initializeQuiz();
  }

  @override
  void dispose() {
    _resetData();
    super.dispose();
  }

  void _initializeQuiz() {
    _mnemonic = utf8.decode(_walletCreationProvider.secret).split(' ');
    if (_mnemonic.isEmpty) return;

    // 랜덤하게 n개의 단어 선택 (중복 없이)
    _selectedWordPositions = _generateRandomPositions();

    // 정답 단어들 저장
    _correctAnswers = _selectedWordPositions.map((index) => _mnemonic[index]).toList();

    // 각 퀴즈의 선택지 생성
    _quizOptions =
        _selectedWordPositions.map((position) {
          return _generateQuizOptions(position);
        }).toList();

    // Answers 초기화
    _userAnswers = List.filled(_totalQuizzes, '');
  }

  List<int> _generateRandomPositions() {
    final random = List<int>.generate(_mnemonic.length, (i) => i);
    random.shuffle();
    return random.take(_totalQuizzes).toList();
  }

  List<String> _generateQuizOptions(int correctPosition) {
    final correctWord = _mnemonic[correctPosition];
    final options = [correctWord];

    // 다른 위치의 단어들을 랜덤하게 선택해서 선택지에 추가
    final otherWords = _mnemonic.where((word) => word != correctWord).toList();
    otherWords.shuffle();

    // 3개의 틀린 답 추가 (총 4개 선택지)
    for (int i = 0; i < 3 && i < otherWords.length; i++) {
      options.add(otherWords[i]);
    }

    // 선택지 순서 섞기
    options.shuffle();
    return options;
  }

  void _onAnswerSelected(String selectedAnswer, int optionIndex) {
    setState(() {
      _userAnswers[_currentQuizIndex] = selectedAnswer;
      _selectedOptionIndex = optionIndex;
      _isAnswerCorrect = selectedAnswer == _correctAnswers[_currentQuizIndex];
      _showResult = true;
    });

    // 잠시 후 처리
    if (mounted) {
      if (_isAnswerCorrect) {
        vibrateExtraLight();
        // 정답이면 다음 퀴즈로
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _nextQuiz();
          }
        });
      } else {
        vibrateExtraLightDouble();
        // 틀렸으면 같은 위치에 다른 퀴즈로 변경
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _changeCurrentQuiz();
          }
        });
      }
    }
  }

  void _nextQuiz() {
    setState(() {
      _showResult = false;
      _isAnswerCorrect = false;
      _selectedOptionIndex = -1; // 선택한 옵션 인덱스 리셋

      if (_currentQuizIndex < _totalQuizzes - 1) {
        _currentQuizIndex++;
      } else {
        // 마지막 퀴즈 정답 시 화면 이동
        _onVerificationSuccess();
      }
    });
  }

  void _changeCurrentQuiz() {
    if (_mnemonic.isEmpty) return;

    // 현재 사용 중인 위치들을 제외한 새로운 위치 선택
    final availablePositions =
        List<int>.generate(
          _mnemonic.length,
          (i) => i,
        ).where((position) => !_selectedWordPositions.contains(position)).toList();

    if (availablePositions.isEmpty) return;

    // 랜덤하게 새로운 위치 선택
    availablePositions.shuffle();
    final newPosition = availablePositions.first;

    setState(() {
      // 현재 퀴즈 위치 변경
      _selectedWordPositions[_currentQuizIndex] = newPosition;

      // 정답 변경
      _correctAnswers[_currentQuizIndex] = _mnemonic[newPosition];

      // 선택지 변경
      _quizOptions[_currentQuizIndex] = _generateQuizOptions(newPosition);

      // 사용자 답변 초기화
      _userAnswers[_currentQuizIndex] = '';

      // UI 상태 초기화
      _showResult = false;
      _isAnswerCorrect = false;
      _selectedOptionIndex = -1; // 선택한 옵션 인덱스 리셋
    });
  }

  void _onVerificationSuccess() {
    // 성공 시 MnemonicConfirmation(final check) 화면으로 이동
    Navigator.pushReplacementNamed(context, AppRoutes.mnemonicConfirmation);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: t.mnemonic_verify_screen.title,
          context: context,
          backgroundColor: CoconutColors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 진행률 표시
              _buildProgressBar(),
              CoconutLayout.spacing_1200h,
              // '일치하지 않아요' 문구
              _buildAnswerExplanation(),
              // 퀴즈 내용
              Expanded(child: _buildQuizScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    int correctAnswers = 0;
    for (int i = 0; i < _userAnswers.length; i++) {
      if (_userAnswers[i] == _correctAnswers[i]) {
        correctAnswers++;
      }
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          ClipRRect(child: Container(height: 6, color: CoconutColors.black.withValues(alpha: 0.06))),
          ClipRRect(
            borderRadius:
                correctAnswers / _totalQuizzes == 1
                    ? BorderRadius.zero
                    : const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              height: 6,
              width: MediaQuery.of(context).size.width * (correctAnswers / _totalQuizzes),
              color: CoconutColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerExplanation() {
    return _showResult && !_isAnswerCorrect
        ? CoconutShakeAnimation(
          autoStart: true,
          curve: Curves.easeInOut,
          child: Text(
            t.mnemonic_verify_screen.not_correct,
            style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.warningText),
          ),
        )
        : Text('ㅣ', style: CoconutTypography.body2_14_Bold.setColor(CoconutColors.white));
  }

  Widget _buildQuizScreen() {
    if (_selectedWordPositions.isEmpty) {
      return const Center(child: CoconutCircularIndicator());
    }

    final currentPosition = _selectedWordPositions[_currentQuizIndex];
    final currentOptions = _quizOptions[_currentQuizIndex];

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      child: Column(
        children: [
          // 퀴즈 질문
          Text(
            t.mnemonic_verify_screen.select_word(index: currentPosition + 1),
            style: CoconutTypography.body1_16_Bold,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // 선택지 버튼들
          ...currentOptions.asMap().entries.map((entry) => _buildOptionButton(entry.value, entry.key)),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, int optionIndex) {
    final isSelected = _selectedOptionIndex == optionIndex;

    Color buttonColor = CoconutColors.white;
    Color borderColor = CoconutColors.black.withValues(alpha: 0.08);

    if (_showResult) {
      if (isSelected) {
        buttonColor = CoconutColors.gray200;
        borderColor = CoconutColors.black;
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 66, right: 66, bottom: 20),
      child: ShrinkAnimationButton(
        onPressed: () => _showResult ? null : _onAnswerSelected(option, optionIndex),
        defaultColor: buttonColor,
        pressedColor: buttonColor,
        borderWidth: 1,
        borderGradientColors: [borderColor, borderColor],
        borderRadius: 100,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: Text(option, style: CoconutTypography.body1_16.setColor(CoconutColors.black)),
        ),
      ),
    );
  }

  void _resetData() {
    if (_mnemonic.isNotEmpty) {
      for (int i = 0; i < _mnemonic.length; i++) {
        _mnemonic[i] = '';
      }
    }

    for (int i = 0; i < _quizOptions.length; i++) {
      for (int j = 0; j < _quizOptions[i].length; j++) {
        _quizOptions[i][j] = '';
      }
    }
    _userAnswers = List<String>.filled(_totalQuizzes, '');
    _correctAnswers = List<String>.filled(_totalQuizzes, '');
    _selectedWordPositions = List<int>.filled(_totalQuizzes, 0);
  }
}
