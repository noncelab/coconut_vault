import 'dart:async';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/data/vault_list_item_base.dart';
import 'package:coconut_vault/utils/text_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/model/state/vault_model.dart';
import 'package:coconut_vault/screens/vault_detail/qrcode_bottom_sheet_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:provider/provider.dart';

class AddressListScreen extends StatefulWidget {
  final int id;

  const AddressListScreen({super.key, required this.id});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  static const int FIRST_COUNT = 20;
  int _receivingAddressPage = 0;
  int _changeAddressPage = 0;
  final int _limit = 5;
  bool _isFirstLoadRunning = true;
  bool _isLoadMoreRunning = false;
  List<Address> _receivingAddressList = [];
  List<Address> _changeAddressList = [];
  late ScrollController _controller;
  late VaultListItemBase _vaultListItem;
  late WalletBase _coconutVault;
  bool isReceivingSelected = true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_nextLoad);
    _vaultListItem =
        Provider.of<VaultModel>(context, listen: false).getVaultById(widget.id);
    _coconutVault = _vaultListItem.coconutVault;
    _receivingAddressList = _coconutVault.getAddressList(0, FIRST_COUNT, false);
    _changeAddressList = _coconutVault.getAddressList(0, FIRST_COUNT, true);
    _isFirstLoadRunning = false;
  }

  void _nextLoad() {
    if (!_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _controller.position.extentAfter < 100) {
      setState(() {
        _isLoadMoreRunning = true;
      });

      try {
        final newAddresses = _coconutVault.getAddressList(
            FIRST_COUNT +
                (isReceivingSelected
                        ? _receivingAddressPage
                        : _changeAddressPage) *
                    _limit,
            _limit,
            !isReceivingSelected);
        setState(() {
          if (isReceivingSelected) {
            _receivingAddressList.addAll(newAddresses);
            _receivingAddressPage += 1;
          } else {
            _changeAddressList.addAll(newAddresses);
            _changeAddressPage += 1;
          }
        });
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

  void scrollToTop() {
    _controller.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  @override
  Widget build(BuildContext context) {
    var addressList =
        isReceivingSelected ? _receivingAddressList : _changeAddressList;

    return Scaffold(
      backgroundColor: MyColors.white,
      appBar: CustomAppBar.build(
        title: t.address_list_screen.title(name: _vaultListItem.name),
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
                              setState(() {
                                isReceivingSelected = true;
                              });
                              scrollToTop();
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: isReceivingSelected
                                    ? MyColors.transparentBlack_50
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  t.receiving,
                                  style: Styles.label.merge(TextStyle(
                                    color: isReceivingSelected
                                        ? MyColors.white
                                        : MyColors.transparentBlack_50,
                                    fontWeight: isReceivingSelected
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
                              setState(() {
                                isReceivingSelected = false;
                              });
                              scrollToTop();
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: !isReceivingSelected
                                    ? MyColors.transparentBlack_50
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  t.change,
                                  style: Styles.label.merge(TextStyle(
                                    color: !isReceivingSelected
                                        ? MyColors.white
                                        : MyColors.transparentBlack_50,
                                    fontWeight: !isReceivingSelected
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
                                child: QrcodeBottomSheetScreen(
                                  qrData: addressList[index].address,
                                  title: t.address_list_screen
                                      .address_index(index: index),
                                  qrcodeTopWidget: Text(
                                    addressList[index].derivationPath,
                                    style: Styles.body2.merge(const TextStyle(
                                        color: MyColors.darkgrey)),
                                  ),
                                ),
                              );
                            },
                            address: addressList[index].address,
                            derivationPath: addressList[index].derivationPath,
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.onPressed,
    required this.address,
    required this.derivationPath,
  });

  final VoidCallback onPressed;
  final String address;
  final String derivationPath;

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
