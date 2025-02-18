import 'dart:async';

import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/address_list_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/qrcode_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddressCard extends StatelessWidget {
  final VoidCallback onPressed;

  final String address;
  final String derivationPath;
  const AddressCard({
    super.key,
    required this.onPressed,
    required this.address,
    required this.derivationPath,
  });

  @override
  Widget build(BuildContext context) {
    var path = derivationPath.split('/');
    var index = path[path.length - 1];

    return CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          borderRadius: MyBorder.defaultRadius,
          color: MyColors.lightgrey,
        ),
        padding: Paddings.widgetContainer,
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: MyColors.transparentBlack_30,
              ),
              child: Text(
                index,
                style: Styles.caption
                    .merge(const TextStyle(color: MyColors.white)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TextUtils.truncateNameMax25(address),
                  style: Styles.body1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddressListScreen extends StatefulWidget {
  final int id;

  const AddressListScreen({super.key, required this.id});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  bool _isFirstLoadRunning = true;
  bool _isLoadMoreRunning = false;

  late ScrollController _controller;
  late AddressListViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<WalletProvider, AddressListViewModel>(
      create: (BuildContext context) => _viewModel,
      update: (_, walletProvider, viewModel) {
        return viewModel!;
      },
      child: Consumer<AddressListViewModel>(
        builder: (context, viewModel, child) {
          var addressList = viewModel.isReceivingSelected
              ? viewModel.receivingAddressList
              : viewModel.changeAddressList;

          return Scaffold(
            backgroundColor: MyColors.white,
            appBar: CustomAppBar.build(
              title: t.address_list_screen.title(name: _viewModel),
              context: context,
              hasRightIcon: false,
              isBottom: true,
            ),
            body: SafeArea(
              minimum: const EdgeInsets.symmetric(horizontal: 16),
              child: _isFirstLoadRunning
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Container(
                          height: 36,
                          margin: const EdgeInsets.only(top: 10, bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: MyBorder.defaultRadius,
                            color: MyColors.transparentBlack_06,
                          ),
                          child: Row(
                            children: [
                              // Choose Receiving or Change
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    viewModel.setReceivingSelected(true);
                                    scrollToTop();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      color: viewModel.isReceivingSelected
                                          ? MyColors.transparentBlack_50
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        t.receiving,
                                        style: Styles.label.merge(TextStyle(
                                          color: viewModel.isReceivingSelected
                                              ? MyColors.white
                                              : MyColors.transparentBlack_50,
                                          fontWeight:
                                              viewModel.isReceivingSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        )),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    viewModel.setReceivingSelected(false);
                                    scrollToTop();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: !viewModel.isReceivingSelected
                                          ? MyColors.transparentBlack_50
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        t.change,
                                        style: Styles.label.merge(TextStyle(
                                          color: !viewModel.isReceivingSelected
                                              ? MyColors.white
                                              : MyColors.transparentBlack_50,
                                          fontWeight:
                                              !viewModel.isReceivingSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        )),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              ListView.builder(
                                controller: _controller,
                                itemCount: addressList.length,
                                itemBuilder: (context, index) => AddressCard(
                                  onPressed: () {
                                    MyBottomSheet.showBottomSheet_90(
                                      context: context,
                                      child: QrcodeBottomSheet(
                                        qrData: addressList[index].address,
                                        title: t.address_list_screen
                                            .address_index(index: index),
                                        qrcodeTopWidget: Text(
                                          addressList[index].derivationPath,
                                          style: Styles.body2.merge(
                                              const TextStyle(
                                                  color: MyColors.darkgrey)),
                                        ),
                                      ),
                                    );
                                  },
                                  address: addressList[index].address,
                                  derivationPath:
                                      addressList[index].derivationPath,
                                ),
                              ),
                              if (_isLoadMoreRunning)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 40,
                                  child: Container(
                                    padding: const EdgeInsets.all(30),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: MyColors.darkgrey),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _viewModel = AddressListViewModel(
        Provider.of<WalletProvider>(context, listen: false), widget.id);
    _controller = ScrollController()..addListener(_nextLoad);
    _isFirstLoadRunning = false;
  }

  void scrollToTop() {
    _controller.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _nextLoad() {
    if (!_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _controller.position.extentAfter < 100) {
      setState(() {
        _isLoadMoreRunning = true;
      });

      try {
        _viewModel.nextLoad();
      } catch (e) {
        Logger.log(e.toString());
      } finally {
        Timer(const Duration(seconds: 1), () {
          setState(() {
            _isLoadMoreRunning = false;
          });
        });
      }
    }
  }
}
