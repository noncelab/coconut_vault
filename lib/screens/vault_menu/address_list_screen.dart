import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/address_list_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/qrcode_bottom_sheet.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/card/address_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  AddressListViewModel? _viewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddressListViewModel>(
      create: (BuildContext context) => _viewModel =
          AddressListViewModel(Provider.of<WalletProvider>(context, listen: false), widget.id),
      child: Consumer<AddressListViewModel>(
        builder: (context, viewModel, child) {
          var addressList = viewModel.isReceivingSelected
              ? viewModel.receivingAddressList
              : viewModel.changeAddressList;

          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CustomAppBar.build(
              title: t.address_list_screen.title(name: viewModel.name),
              context: context,
              hasRightIcon: false,
              isBottom: true,
            ),
            body: SafeArea(
              child: _isFirstLoadRunning
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Container(
                          height: 36,
                          margin: const EdgeInsets.only(
                            top: 10,
                            bottom: 12,
                            left: 16,
                            right: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: CoconutBorder.defaultRadius,
                            color: CoconutColors.black.withOpacity(0.06),
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
                                          ? CoconutColors.black.withOpacity(0.5)
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        t.receiving,
                                        style: Styles.label.merge(TextStyle(
                                          color: viewModel.isReceivingSelected
                                              ? CoconutColors.white
                                              : CoconutColors.black.withOpacity(0.5),
                                          fontWeight: viewModel.isReceivingSelected
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
                                          ? CoconutColors.black.withOpacity(0.5)
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        t.change,
                                        style: Styles.label.merge(TextStyle(
                                          color: !viewModel.isReceivingSelected
                                              ? CoconutColors.white
                                              : CoconutColors.black.withOpacity(0.5),
                                          fontWeight: !viewModel.isReceivingSelected
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
                              Scrollbar(
                                controller: _controller,
                                radius: const Radius.circular(12),
                                child: ListView.builder(
                                  controller: _controller,
                                  itemCount: addressList.length,
                                  itemBuilder: (context, index) => AddressCard(
                                    onPressed: () {
                                      MyBottomSheet.showBottomSheet_90(
                                        context: context,
                                        child: QrcodeBottomSheet(
                                          qrData: addressList[index].address,
                                          title: t.address_list_screen.address_index(index: index),
                                          qrcodeTopWidget: Text(
                                            addressList[index].derivationPath,
                                            style: Styles.body2.merge(
                                                const TextStyle(color: CoconutColors.gray800)),
                                          ),
                                        ),
                                      );
                                    },
                                    address: addressList[index].address,
                                    derivationPath: addressList[index].derivationPath,
                                  ),
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
                                      child:
                                          CircularProgressIndicator(color: CoconutColors.gray800),
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
    _controller = ScrollController()..addListener(_nextLoad);
    _isFirstLoadRunning = false;
  }

  void scrollToTop() {
    _controller.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _nextLoad() {
    if (!_isFirstLoadRunning && !_isLoadMoreRunning && _controller.position.extentAfter < 50) {
      setState(() {
        _isLoadMoreRunning = true;
      });

      try {
        if (_viewModel == null) return;
        _viewModel!.nextLoad();
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
