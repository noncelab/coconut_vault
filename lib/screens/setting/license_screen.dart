import 'package:coconut_vault/constants/external_links.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
          title: t.license_details,
          context: context,
        ),
        body: SafeArea(
          child: ListView.builder(
            itemCount: dependencies.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                String mitFullTextLink = 'https://mit-license.org';

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
                        t.coconut_vault,
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
                          text: t.license_screen.text1,
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
                                          title:
                                              t.bottom_sheet.view_mit_license,
                                          fromAppInfo: true,
                                        ));
                                  }),
                            TextSpan(text: t.license_screen.text2),
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
                                        child: QrcodeBottomSheetScreen(
                                          qrData:
                                              'mailto:$CONTACT_EMAIL_ADDRESS?subject=${t.bottom_sheet.ask_about_license}',
                                          title:
                                              t.bottom_sheet.contact_by_email,
                                          fromAppInfo: true,
                                        ));
                                  }),
                            TextSpan(
                              text: t.license_screen.text3,
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
