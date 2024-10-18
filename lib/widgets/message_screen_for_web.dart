import 'package:flutter/cupertino.dart';

import '../styles.dart';

class MessageScreenForWeb extends StatelessWidget {
  final String message;

  const MessageScreenForWeb({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: MyColors.transparentWhite_20,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 180,
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            borderRadius: MyBorder.boxDecorationRadius,
            color: MyColors.white,
            boxShadow: [
              BoxShadow(
                color: MyColors.grey.withOpacity(0.3),
                spreadRadius: 10,
                blurRadius: 10, // changes position of shadow
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Center(
              child: Text(
            message,
            style: Styles.h3
                .merge(const TextStyle(color: MyColors.darkgrey, height: 1.5)),
            textAlign: TextAlign.center,
          )),
        ),
      ),
    );
  }
}
