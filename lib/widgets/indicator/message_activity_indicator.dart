import 'package:coconut_vault/styles.dart';
import 'package:flutter/material.dart';

class MessageActivityIndicator extends StatelessWidget {
  final String? message;

  const MessageActivityIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: MyBorder.defaultRadius,
        color: message != null ? MyColors.white : null,
      ),
      width: MediaQuery.of(context).size.width / 2 + 30,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: MyColors.darkgrey,
          ),
          Visibility(
              visible: message != null,
              child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    message ?? '',
                    style: Styles.body1,
                    textAlign: TextAlign.center,
                  )))
        ],
      ),
    );
  }
}
