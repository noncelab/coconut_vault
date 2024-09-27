import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/constants/app_info.dart';
import 'package:coconut_vault/oss_licenses.dart';
import 'package:coconut_vault/screens/vault_detail/qrcode_bottom_sheet_screen.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  late List<bool> licenseExplanationVisible =
      List.filled(dependencies.length, false);
  String? identifyLicense(String licenseText) {
    final Map<String, String> licenseKeywords = {
      'MIT License': 'Permission is hereby granted,',
      'Apache License': 'Apache License',
      'BSD License': 'Redistribution and use in source and binary forms,',
      'GPL License': 'This program is free software:',
      'EPL License': 'Eclipse Public License - v 2.0',
      'Creative Commons License':
          'This work is licensed under a Creative Commons Attribution',
      'Proprietary License': 'This software is proprietary and confidential',
      'Public Domain': 'The person who associated a work with this',
      'LGPL License': 'This library is free software; you can redistribute it',
    };

    for (var license in licenseKeywords.keys) {
      if (licenseText.contains(licenseKeywords[license]!)) {
        return license;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: MyBorder.defaultRadius,
      child: Scaffold(
        backgroundColor: MyColors.white,
        appBar: CustomAppBar.buildWithClose(
          title: '라이선스 안내',
          context: context,
        ),
        body: SafeArea(
          child: ListView.builder(
            itemCount: dependencies.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                String copyrightText =
                    '코코넛 볼트는 MIT 라이선스를 따르며 저작권은 대한민국의 논스랩 주식회사에 있습니다. MIT 라이선스 전문은 ';
                String copyrightTextMiddle =
                    '에서 확인해 주세요.\n\n이 애플리케이션에 포함된 타사 소프트웨어에 대한 저작권을 다음과 같이 명시합니다. 이에 대해 궁금한 사항이 있으시면 ';
                String mitFullTextLink = 'https://mit-license.org';
                String copyrightTextLast = '으로 문의해 주시기 바랍니다.';

                return Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: MyColors.darkgrey,
                      ),
                      child: Text(
                        'Coconut Vault',
                        style: Styles.body2Bold.merge(
                          const TextStyle(
                            color: MyColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: copyrightText,
                          style: Styles.caption,
                          children: <TextSpan>[
                            TextSpan(
                                text: mitFullTextLink, // 색상을 다르게 할 텍스트
                                style: Styles.caption.merge(
                                  const TextStyle(
                                    color: MyColors.oceanBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    MyBottomSheet.showBottomSheet_95(
                                        context: context,
                                        child: QrcodeBottomSheetScreen(
                                          qrData: mitFullTextLink,
                                          title: 'MIT 라이선스 전문 보기',
                                          fromAppInfo: true,
                                        ));
                                  }),
                            TextSpan(text: copyrightTextMiddle),
                            TextSpan(
                                text: CONTACT_EMAIL_ADDRESS, // 색상을 다르게 할 텍스트
                                style: Styles.caption.merge(
                                  const TextStyle(
                                    color: MyColors.oceanBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    MyBottomSheet.showBottomSheet_95(
                                        context: context,
                                        child: const QrcodeBottomSheetScreen(
                                          qrData:
                                              'mailto:$CONTACT_EMAIL_ADDRESS?subject=[볼트] 라이선스 문의',
                                          title: '이메일 문의',
                                          fromAppInfo: true,
                                        ));
                                  }),
                            TextSpan(
                              text: copyrightTextLast,
                              style: Styles.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Divider(),
                  ],
                );
              } else {
                final license = dependencies[index - 1];
                final licenseName = license.name;
                String copyRight = '';
                List<String>? licenseClassExplanation =
                    license.license?.split('\n');
                String? licenseClass = '';

                /// License 종류 찾기
                licenseClass = identifyLicense(license.license!);

                /// CopyRight 문구 찾기
                if (licenseClassExplanation != null) {
                  for (String line in licenseClassExplanation) {
                    if (line.startsWith('Copyright')) {
                      copyRight = line;
                      if (copyRight.contains('All rights reserved')) {
                        copyRight = copyRight.split('.')[0];
                      }
                      break;
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 10, bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (licenseClass != null && licenseClass.isNotEmpty) {
                          setState(() {
                            licenseExplanationVisible[index - 1] =
                                !licenseExplanationVisible[index - 1];
                          });
                        }
                      },
                      child: Ink(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              licenseName,
                              style: Styles.body1Bold,
                            ),
                            if (copyRight.isNotEmpty)
                              Text(
                                copyRight,
                                style: Styles.body2Grey.merge(
                                  const TextStyle(
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                licenseClass ?? 'Unknown License',
                                style: Styles.body2.merge(
                                  const TextStyle(
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            ),
                            if (licenseExplanationVisible[index - 1])
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 8,
                                ),
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 1, color: MyColors.borderGrey),
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: Text(
                                    license.license!,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
