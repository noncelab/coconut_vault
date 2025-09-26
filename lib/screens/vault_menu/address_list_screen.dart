import 'dart:async';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/providers/view_model/address_list_view_model.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/screens/common/qrcode_bottom_sheet.dart';
import 'package:coconut_vault/screens/home/select_vault_bottom_sheet.dart';
import 'package:coconut_vault/utils/logger.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/card/address_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddressListScreen extends StatefulWidget {
  final int id;
  final bool isSpecificVault; // (true) 볼트 상세화면으로 진입 -> 다른 볼트 주소 조회 불가

  const AddressListScreen({super.key, required this.id, required this.isSpecificVault});

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
    return ChangeNotifierProvider<AddressListViewModel>(
      create: (BuildContext context) {
        return _viewModel;
      },
      child: Consumer<AddressListViewModel>(
        builder: (context, viewModel, child) {
          var addressList =
              viewModel.isReceivingSelected ? viewModel.receivingAddressList : viewModel.changeAddressList;

          return Scaffold(
            backgroundColor: CoconutColors.white,
            appBar: CoconutAppBar.build(
              context: context,
              actionButtonList: [
                // title center 배치용
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded, color: CoconutColors.white),
                  ),
                ),
              ],
              customTitle: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.address_list_screen.title(
                      name: viewModel.name.length > 6 ? '${viewModel.name.substring(0, 6)}...' : viewModel.name,
                    ),
                    style: CoconutTypography.heading4_18,
                  ),
                  if (!widget.isSpecificVault && viewModel.vaultCount > 1) ...[
                    CoconutLayout.spacing_50w,
                    const Icon(Icons.keyboard_arrow_down_sharp, color: CoconutColors.black, size: 16),
                  ],
                ],
              ),
              onTitlePressed: () {
                if (widget.isSpecificVault || viewModel.vaultCount <= 1) return;
                MyBottomSheet.showDraggableBottomSheet(
                  context: context,
                  childBuilder: (scrollController) => SelectVaultBottomSheet(
                    isNextIconVisible: false,
                    vaultList: context.read<WalletProvider>().vaultList,
                    selectedId: viewModel.vaultId,
                    onVaultSelected: (id) async {
                      Navigator.pop(context);
                      setState(() {
                        _isFirstLoadRunning = true;
                      });
                      await viewModel.changeVaultById(id);
                      setState(() {
                        _isFirstLoadRunning = false;
                      });
                    },
                    scrollController: scrollController,
                  ),
                );
              },
            ),
            body: _isFirstLoadRunning
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 12, left: 16, right: 16),
                        decoration: BoxDecoration(
                          borderRadius: CoconutBorder.defaultRadius,
                          color: CoconutColors.black.withValues(alpha: 0.06),
                        ),
                        child: CoconutSegmentedControl(
                          labels: [t.receiving, t.change],
                          isSelected: [viewModel.isReceivingSelected, !viewModel.isReceivingSelected],
                          onPressed: (index) {
                            viewModel.setReceivingSelected(index == 0);
                            scrollToTop();
                          },
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
                                itemCount: addressList!.length,
                                itemBuilder: (context, index) => AddressCard(
                                  onPressed: () {
                                    MyBottomSheet.showBottomSheet_90(
                                      context: context,
                                      child: QrcodeBottomSheet(
                                        qrData: addressList[index].address,
                                        title: t.address_list_screen.address_index(index: index),
                                        qrcodeTopWidget: Text(
                                          addressList[index].derivationPath,
                                          style: CoconutTypography.body2_14.setColor(CoconutColors.gray800),
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
                                  child: const Center(child: CircularProgressIndicator(color: CoconutColors.gray800)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
    _viewModel = AddressListViewModel(Provider.of<WalletProvider>(context, listen: false), widget.id);
    _viewModel.initializeAddress().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isFirstLoadRunning = false;
        });
      });
    });
    _controller = ScrollController()..addListener(_nextLoad);
  }

  void scrollToTop() {
    _controller.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  Future<void> _nextLoad() async {
    if (!_isFirstLoadRunning && !_isLoadMoreRunning && _controller.position.extentAfter < 50) {
      setState(() {
        _isLoadMoreRunning = true;
      });

      try {
        await _viewModel.nextLoad();
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
