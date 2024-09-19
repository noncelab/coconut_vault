import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/high-lighted-text.dart';

class IosBluetoothAuthNotificationScreen extends StatefulWidget {
  const IosBluetoothAuthNotificationScreen({super.key});

  @override
  State<IosBluetoothAuthNotificationScreen> createState() =>
      _IosBluetoothAuthNotificationScreenState();
}

class _IosBluetoothAuthNotificationScreenState
    extends State<IosBluetoothAuthNotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/bluetooth.svg',
              width: 48,
            ),
            const SizedBox(height: 20),
            const Text("코코넛 볼트에 블루투스 권한을 허용해 주세요", style: Styles.body2Bold),
            const SizedBox(height: 20),
            Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: MyColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 4,
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Text('안전한 사용을 위해', style: Styles.subLabel),
                    Text('지금 바로 앱을 종료하신 후', style: Styles.subLabel),
                    Text('설정 화면에서', style: Styles.subLabel),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('코코넛 볼트의 ', style: Styles.subLabel),
                        HighLightedText('블루투스 권한', color: MyColors.darkgrey),
                        Text('을', style: Styles.subLabel),
                      ],
                    ),
                    Text('허용해 주세요', style: Styles.subLabel),
                  ],
                )),
            const SizedBox(
              height: 100,
            ),
          ],
        ),
      )),
    );
  }
}
