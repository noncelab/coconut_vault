import 'dart:io';
import 'dart:ui';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/constants/external_links.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/screens/home/tutorial_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:coconut_vault/constants/app_info.dart';
import 'package:coconut_vault/screens/settings/app_info_license_screen.dart';
import 'package:coconut_vault/screens/common/qrcode_bottom_sheet.dart';
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
            '${t.inquiry_details}: \n\n\n\n\n';
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
            '${t.inquiry_details}: \n\n';
      }
    } catch (e) {
      throw t.errors.device_info_unavailable_error(error: e);
    }
    return info;
  }

  Future<PackageInfo> _initPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: CoconutColors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor:
            _isScrollOverTitleHeight ? CoconutColors.white.withOpacity(0.2) : CoconutColors.white,
        toolbarHeight: kToolbarHeight,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded, color: CoconutColors.gray800, size: 22)),
        flexibleSpace: _isScrollOverTitleHeight
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: CoconutColors.white.withOpacity(0.06),
                  ),
                ),
              )
            : null,
        title: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _appbarTitleVisible ? 1 : 0,
          child: Text(
            t.app_info,
            style: CoconutTypography.heading4_18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          controller: _scrollController,
          child: Column(
            children: [
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top + 30),
              headerWidget(_packageInfoFuture),
              CoconutLayout.spacing_600h,
              githubWidget(),
              CoconutLayout.spacing_1200h,
              termsOfServiceWidget(),
              CoconutLayout.spacing_1200h,
              socialMediaWidget(),
              CoconutLayout.spacing_1200h,
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
              color: CoconutColors.gray800,
            ));
          } else if (snapshot.hasError) {
            return Center(child: Text(t.errors.data_loading_error));
          } else if (!snapshot.hasData) {
            return Center(child: Text(t.errors.data_not_found_error));
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
                      color: CoconutColors.borderLightGray,
                      width: 2.0,
                    ),
                  ),
                  child: Image.asset(
                    'assets/png/splash_logo_${NetworkType.currentNetworkType.isTestnet ? "regtest" : "mainnet"}.png',
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
                      style: CoconutTypography.body1_16_Bold.merge(
                        const TextStyle(
                          fontSize: 24,
                        ),
                      ),
                    ),
                    Text(
                      'ver.${packageInfo.version}',
                      style: CoconutTypography.body2_14_Bold.setColor(
                        CoconutColors.black.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      t.app_info_screen.made_by_team_pow,
                      style: CoconutTypography.body2_14.setColor(
                        CoconutColors.black.withOpacity(0.7),
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
          _category(t.app_info_screen.category1_ask),
          SingleButton(
            buttonPosition: SingleButtonPosition.none,
            title: t.tutorial,
            onPressed: () {
              MyBottomSheet.showBottomSheet_90(
                context: context,
                child: const TutorialScreen(
                  screenStatus: TutorialScreenStatus.modal,
                ),
              );
            },
          ),
          CoconutLayout.spacing_400h,
          ButtonGroup(buttons: [
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.top,
              title: t.app_info_screen.go_to_pow,
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
                    child: QrcodeBottomSheet(
                      qrData: POW_URL,
                      title: t.app_info_screen.go_to_pow,
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.middle,
              title: t.app_info_screen.ask_to_discord,
              leftElement: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/png/discord-full-logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: QrcodeBottomSheet(
                      qrData: DISCORD_COCONUT,
                      title: t.app_info_screen.ask_to_discord,
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.middle,
              title: t.app_info_screen.ask_to_x,
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
                    child: QrcodeBottomSheet(
                      qrData: X_POW,
                      title: t.app_info_screen.ask_to_x,
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
                enableShrinkAnim: true,
                buttonPosition: SingleButtonPosition.bottom,
                title: t.app_info_screen.ask_to_email,
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
                      child: QrcodeBottomSheet(
                        qrData:
                            'mailto:$CONTACT_EMAIL_ADDRESS?subject=${t.email_subject}}&body=$info',
                        title: t.app_info_screen.ask_to_email,
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
          _category(t.app_info_screen.category2_opensource),
          ButtonGroup(buttons: [
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.top,
              title: t.app_info_screen.coconut_lib,
              leftElement: githubLogo,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: QrcodeBottomSheet(
                      qrData: GITHUB_URL_COCONUT_LIBRARY,
                      title: '${t.app_info_screen.coconut_lib} ${t.app_info_screen.github}',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.middle,
              title: t.app_info_screen.coconut_wallet,
              leftElement: githubLogo,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: QrcodeBottomSheet(
                      qrData: GITHUB_URL_WALLET,
                      title: '${t.app_info_screen.coconut_wallet} ${t.app_info_screen.github}',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.middle,
              title: t.app_info_screen.coconut_vault,
              leftElement: githubLogo,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: QrcodeBottomSheet(
                      qrData: GITHUB_URL_VAULT,
                      title: '${t.app_info_screen.coconut_vault} ${t.app_info_screen.github}',
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.bottom,
              title: t.app_info_screen.contribution,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: QrcodeBottomSheet(
                      qrData: CONTRIBUTING_URL,
                      title: t.app_info_screen.mit_license,
                      fromAppInfo: true,
                    ));
              },
            )
          ]),
        ],
      ),
    );
  }

  Widget termsOfServiceWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: const BoxDecoration(
        color: CoconutColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _category(t.app_info_screen.tos_and_policy),
          ButtonGroup(buttons: [
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.top,
              title: t.app_info_screen.terms_of_service,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: QrcodeBottomSheet(
                      qrData: TERMS_OF_SERVICE_URL,
                      title: t.app_info_screen.terms_of_service,
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.middle,
              title: t.app_info_screen.privacy_policy,
              onPressed: () {
                MyBottomSheet.showBottomSheet_90(
                    context: context,
                    child: QrcodeBottomSheet(
                      qrData: PRIVACY_POLICY_URL,
                      title: t.app_info_screen.privacy_policy,
                      fromAppInfo: true,
                    ));
              },
            ),
            SingleButton(
              enableShrinkAnim: true,
              buttonPosition: SingleButtonPosition.bottom,
              title: t.app_info_screen.license,
              onPressed: () {
                MyBottomSheet.showBottomSheet_95(context: context, child: const LicenseScreen());
              },
            ),
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
            return Center(
                child: CircularProgressIndicator(
              color: CoconutColors.white.withOpacity(0.06),
            ));
          } else if (snapshot.hasError) {
            return Center(child: Text(t.errors.data_loading_error));
          } else if (!snapshot.hasData) {
            return Center(child: Text(t.errors.data_not_found_error));
          }

          PackageInfo packageInfo = snapshot.data!;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 50),
            color: CoconutColors.black.withOpacity(0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      t.app_info_screen
                          .version_and_date(version: packageInfo.version, releasedAt: RELEASE_DATE),
                      style: CoconutTypography.body2_14.setColor(
                        CoconutColors.black.withOpacity(0.5),
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
                    style: CoconutTypography.body2_14.merge(
                      TextStyle(
                        color: CoconutColors.black.withOpacity(0.5),
                        decoration: TextDecoration.underline,
                        decorationColor: CoconutColors.black.withOpacity(0.5),
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
            color: CoconutColors.gray800,
            fontSize: 16,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.bold,
          )));
}
