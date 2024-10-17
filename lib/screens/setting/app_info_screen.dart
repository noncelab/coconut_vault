import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:coconut_vault/constants/app_info.dart';
import 'package:coconut_vault/screens/setting/license_screen.dart';
import 'package:coconut_vault/screens/vault_detail/qrcode_bottom_sheet_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/button_group.dart';
import 'package:coconut_vault/widgets/button/single_button.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  late ScrollController _scrollController;
  double topPadding = 0;
  bool _isScrollOverTitleHeight = false;
  bool _appbarTitleVisible = false;
  late Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _packageInfoFuture = _initPackageInfo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_scrollListener);
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= 30) {
      if (!_isScrollOverTitleHeight) {
        setState(() {
          _isScrollOverTitleHeight = true;
        });
      }
    } else {
      if (_isScrollOverTitleHeight) {
        setState(() {
          _isScrollOverTitleHeight = false;
        });
      }
    }

    if (_scrollController.position.pixels >= 15) {
      if (!_appbarTitleVisible) {
        setState(() {
          _appbarTitleVisible = true;
        });
      }
    } else {
      if (_appbarTitleVisible) {
        setState(() {
          _appbarTitleVisible = false;
        });
      }
    }
  }

  Future<String> _getDeviceInfo(Future<PackageInfo> packageInfoFuture) async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String info = "";

    try {
      PackageInfo packageInfo = await packageInfoFuture;

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        return info = 'Android Device Info:\n'
            'Brand: ${androidInfo.brand}\n'
            'Model: ${androidInfo.model}\n'
            'Android Version: ${androidInfo.version.release}\n'
            'SDK: ${androidInfo.version.sdkInt}\n'
            'Manufacturer: ${androidInfo.manufacturer}\n'
            'App Version: ${packageInfo.appName} ver.${packageInfo.version}\n'
            'Build Number: ${packageInfo.buildNumber}\n\n'
            '------------------------------------------------------------\n'
            '문의 내용: \n\n\n\n\n';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        return info = 'iOS Device Info:\n'
            'Name: ${iosInfo.name}\n'
            'Model: ${iosInfo.model}\n'
            'System Name: ${iosInfo.systemName}\n'
            'System Version: ${iosInfo.systemVersion}\n'
            'Identifier For Vendor: ${iosInfo.identifierForVendor}\n'
            'App Version: ${packageInfo.appName} ver.${packageInfo.version}\n'
            'Build Number: ${packageInfo.buildNumber}\n\n'
            '------------------------------------------------------------\n'
            '문의 내용: \n\n';
      }
    } catch (e) {
      throw '디바이스 정보를 불러올 수 없음 : $e';
    }
    return info;
  }

  Future<PackageInfo> _initPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    topPadding = kToolbarHeight + MediaQuery.of(context).padding.top + 30;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: MyColors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: _isScrollOverTitleHeight
            ? MyColors.transparentWhite_20
            : MyColors.white,
        toolbarHeight: kToolbarHeight,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded,
                color: MyColors.darkgrey, size: 22)),
        flexibleSpace: _isScrollOverTitleHeight
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: MyColors.transparentWhite_06,
                  ),
                ),
              )
            : null,
        title: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _appbarTitleVisible ? 1 : 0,
          child: const Text(
            '앱 정보',
            style: Styles.appbarTitle,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          controller: _scrollController,
          child: Column(
            children: [
              Container(
                height: topPadding,
              ),
              headerWidget(_packageInfoFuture),
              Container(
                height: 50,
              ),
              socialMediaWidget(),
              Container(
                height: 50,
              ),
              githubWidget(),
              Container(
                height: 50,
              ),
              footerWidget(_packageInfoFuture),
            ],
          )),
    );
  }

  Widget headerWidget(Future<PackageInfo> packageInfoFuture) {
    return FutureBuilder<PackageInfo>(
        future: packageInfoFuture,
        builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: MyColors.darkgrey,
            ));
          } else if (snapshot.hasError) {
            return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('데이터가 없습니다.'));
          }

          PackageInfo packageInfo = snapshot.data!;

          return Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 80.0,
                  height: 80.0,
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: MyColors.borderLightgrey,
                      width: 2.0,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/png/splash_logo.png',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 30,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packageInfo.appName,
                      style: Styles.body1Bold.merge(
                        const TextStyle(
                          fontSize: 24,
                        ),
                      ),
                    ),
                    Text(
                      'ver.${packageInfo.version}',
                      style: Styles.body2Bold.merge(
                        const TextStyle(
                          color: MyColors.transparentBlack_70,
                        ),
                      ),
                    ),
                    Text(
                      '포우팀이 만듭니다.',
                      style: Styles.body2.merge(
                        const TextStyle(
                          color: MyColors.transparentBlack_70,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }

  Widget socialMediaWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _category('궁금한 점이 있으신가요?'),
          ButtonGroup(buttons: [
            SingleButton(
              title: 'POW 커뮤니티 바로가기',
              leftElement: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/jpg/pow-full-logo.jpg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: const QrcodeBottomSheetScreen(
                      qrData: POW_URL,
                      title: 'POW 커뮤니티 바로가기',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              title: '텔레그램 채널로 문의하기',
              leftElement: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/png/telegram-circle-logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: const QrcodeBottomSheetScreen(
                      qrData: TELEGRAM_POW,
                      title: '텔레그램 채널로 문의하기',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              title: 'X로 문의하기',
              leftElement: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/jpg/x-logo.jpg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: const QrcodeBottomSheetScreen(
                      qrData: X_POW,
                      title: 'X로 문의하기',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
                title: '이메일로 문의하기',
                leftElement: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    'assets/png/mail-icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                onPressed: () async {
                  String info = await _getDeviceInfo(_packageInfoFuture);
                  MyBottomSheet.showBottomSheet_90(
                      context: context,
                      child: QrcodeBottomSheetScreen(
                        qrData:
                            'mailto:$CONTACT_EMAIL_ADDRESS?subject=$EMAIL_SUBJECT&body=$info',
                        title: '이메일로 문의하기',
                        fromAppInfo: true,
                      ));
                }),
          ]),
        ],
      ),
    );
  }

  Widget githubWidget() {
    Widget githubLogo = SvgPicture.asset(
      'assets/svg/github-logo.svg',
      width: 24,
      height: 24,
      fit: BoxFit.cover,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _category('Coconut Vault는 오픈소스입니다'),
          ButtonGroup(buttons: [
            SingleButton(
              title: 'coconut_lib',
              leftElement: githubLogo,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: const QrcodeBottomSheetScreen(
                      qrData: GITHUB_URL_COCONUT_LIBRARY,
                      title: 'coconut_lib Github',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              title: 'coconut_wallet',
              leftElement: githubLogo,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: const QrcodeBottomSheetScreen(
                      qrData: GITHUB_URL_WALLET,
                      title: 'coconut_wallet Github',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              title: 'coconut_vault',
              leftElement: githubLogo,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: const QrcodeBottomSheetScreen(
                      qrData: GITHUB_URL_VAULT,
                      title: 'coconut_vault Github',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              title: '라이선스 안내',
              onPressed: () {
                MyBottomSheet.showBottomSheet_95(
                    context: context, child: const LicenseScreen());
              },
            ),
            SingleButton(
              title: '오픈소스 개발 참여하기',
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: const QrcodeBottomSheetScreen(
                      qrData: CONTRIBUTING_URL,
                      title: 'MIT License',
                      fromAppInfo: true,
                    ));
              },
            )
          ]),
        ],
      ),
    );
  }

  Widget footerWidget(Future<PackageInfo> packageInfoFuture) {
    return FutureBuilder<PackageInfo>(
        future: packageInfoFuture,
        builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: MyColors.defaultBackground,
            ));
          } else if (snapshot.hasError) {
            return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('데이터가 없습니다.'));
          }

          PackageInfo packageInfo = snapshot.data!;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 50),
            color: MyColors.transparentBlack_03,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'CoconutVault ver.${packageInfo.version}\n(released $RELEASE_DATE)\nCoconut.onl',
                      style: Styles.body2.merge(
                        const TextStyle(
                          color: MyColors.transparentBlack_50,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    COPYRIGHT_TEXT,
                    style: Styles.body2.merge(
                      const TextStyle(
                        color: MyColors.transparentBlack_50,
                        decoration: TextDecoration.underline,
                        decorationColor: MyColors.transparentBlack_50,
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }

  Widget _category(String label) => Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 0, 12),
      child: Text(label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            color: MyColors.darkgrey,
            fontSize: 16,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.bold,
          )));
}
