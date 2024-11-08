import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/clipboard_button.dart';
import 'package:flutter/material.dart';

class MultiSigBsmsScreen extends StatefulWidget {
  final String exportDetail;
  const MultiSigBsmsScreen({super.key, required this.exportDetail});

  @override
  State<MultiSigBsmsScreen> createState() => _MultiSigBsmsScreenState();
}

class _MultiSigBsmsScreenState extends State<MultiSigBsmsScreen> {
  _showMultiSigDetail() {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: ClipRRect(
        borderRadius: MyBorder.defaultRadius,
        child: Scaffold(
          backgroundColor: MyColors.white,
          appBar: AppBar(
            title: Text(
              '자갑 상세 정보',
              style: Styles.body1.copyWith(
                fontSize: 18,
              ),
            ),
            backgroundColor: MyColors.white,
            leading: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: MyColors.darkgrey,
                size: 22,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: SingleChildScrollView(
            child: ClipboardButton(
              text: widget.exportDetail,
              toastMessage: '지갑 상세 정보가 복사됐어요',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrWidth = MediaQuery.of(context).size.width - 80;
    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.build(
        title: '지갑 설정 정보',
        context: context,
        hasRightIcon: false,
        isBottom: false,
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          // Description
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 4,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _description(
                    '안전한 다중 서명 지갑 관리를 위한 표준에 따라 지갑 설정 정보를 관리하고 공유합니다.'),
                const SizedBox(height: 4),
                _description(
                    '가져오기를 통해 추가된 지갑은 자신의 키가 다른 다중 서명 지갑에 사용되고 있는지 알 수 없습니다.'),
                const SizedBox(height: 4),
                _description('따라서, 2번 키를 보관한 볼트에서 아래 QR을 읽어 주세요.'),
              ],
            ),
          ),

          // TODO: QR
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 36),
              color: MyColors.borderLightgrey,
              width: qrWidth,
              height: qrWidth,
            ),
          ),

          // TODO: 상세 정보 보기
          GestureDetector(
            onTap: _showMultiSigDetail,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: MyColors.borderGrey,
              ),
              child: Text(
                '상세 정보 보기',
                style: Styles.body2.copyWith(color: MyColors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _description(String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: Styles.body1.copyWith(
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: Styles.body1.copyWith(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}