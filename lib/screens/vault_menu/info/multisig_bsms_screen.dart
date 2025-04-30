import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/vault_menu/multisig_bsms_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/copy_text_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MultisigBsmsScreen extends StatelessWidget {
  final int id;

  const MultisigBsmsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          MultisigBsmsViewModel(Provider.of<WalletProvider>(context, listen: false), id),
      child: Consumer<MultisigBsmsViewModel>(builder: (context, viewModel, child) {
        final qrWidth = MediaQuery.of(context).size.width * 0.76;

        return Scaffold(
          backgroundColor: MyColors.white,
          appBar: CustomAppBar.build(
            title: t.multi_sig_bsms_screen.title,
            context: context,
            hasRightIcon: false,
            isBottom: false,
            onBackPressed: () {
              Navigator.pop(context);
            },
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Description
                _buildDescriptionBsms(viewModel),
                Center(
                    child: Container(
                        width: qrWidth,
                        decoration: BoxDecorations.shadowBoxDecoration,
                        child: QrImageView(
                          data: viewModel.qrData,
                        ))),
                const SizedBox(
                  height: 30,
                ),
                // TODO: 상세 정보 보기
                GestureDetector(
                  onTap: () => _showMultisigDetail(context, viewModel.qrData),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: MyColors.borderGrey,
                    ),
                    child: Text(
                      t.multi_sig_bsms_screen.view_detail,
                      style: Styles.body2.copyWith(color: MyColors.white),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 100,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDescriptionBsms(MultisigBsmsViewModel viewModel) {
    return Container(
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
          _description(t.multi_sig_bsms_screen.guide.text1),
          const SizedBox(height: 4),
          if (viewModel.outsideWalletIdList.isEmpty) ...[
            _description(t.multi_sig_bsms_screen.guide.text2),
            const SizedBox(height: 4),
            _description(t.multi_sig_bsms_screen.guide.text3),
          ] else ...{
            _description(
              t.multi_sig_bsms_screen.guide
                  .text4(gen: viewModel.generateOutsideWalletDescription(isAnd: true)),
            ),
            const SizedBox(height: 4),
            _description(
              t.multi_sig_bsms_screen.guide
                  .text5(gen: viewModel.generateOutsideWalletDescription()),
            ),
          }
        ],
      ),
    );
  }

  Widget _description(String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '•',
          style: Styles.body1.copyWith(
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Styles.body1.copyWith(
                fontSize: 14,
              ),
              children: _parseDescription(description),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _parseDescription(String description) {
    // ** 로 감싸져 있는 문구 볼트체 적용
    List<TextSpan> spans = [];
    description.split("**").asMap().forEach((index, part) {
      spans.add(
        TextSpan(
          text: part,
          style: index.isEven
              ? Styles.body1.copyWith(fontSize: 14)
              : Styles.body1.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    });
    return spans;
  }

  // TODO: 재사용 컴포넌트로 만들어야 하는지 검토
  void _showMultisigDetail(BuildContext context, String qrData) {
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: ClipRRect(
        borderRadius: MyBorder.defaultRadius,
        child: Scaffold(
          backgroundColor: MyColors.white,
          appBar: AppBar(
            title: Text(t.multi_sig_bsms_screen.bottom_sheet.title),
            centerTitle: true,
            backgroundColor: MyColors.white,
            titleTextStyle: Styles.body1Bold,
            toolbarTextStyle: Styles.body1Bold,
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
            child: CopyTextContainer(
              text: qrData,
              toastMsg: t.multi_sig_bsms_screen.bottom_sheet.info_copied,
            ),
          ),
        ),
      ),
    );
  }
}
