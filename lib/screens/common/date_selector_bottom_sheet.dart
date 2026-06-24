import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:coconut_vault/widgets/button/fixed_bottom_button.dart';
import 'package:flutter/material.dart';

class DateSelectorBottomSheet {
  DateSelectorBottomSheet._();

  static void show({
    required BuildContext context,
    required DateTime today,
    required DateTime? initialDateTime,
    required ValueChanged<DateTime> onDateTimeSelected,
  }) {
    DateTime? selectedDate = initialDateTime;
    var selectedTime =
        initialDateTime == null
            ? TimeOfDay.now()
            : TimeOfDay(hour: initialDateTime.hour, minute: initialDateTime.minute);

    MyBottomSheet.showBottomSheet(
      title: t.bottom_sheet.date_picker.select_date,
      context: context,
      isCloseButton: true,
      child: StatefulBuilder(
        builder: (context, setBottomSheetState) {
          final mediaQuery = MediaQuery.of(context);
          final keyboardHeight = mediaQuery.viewInsets.bottom;
          final isKeyboardVisible = keyboardHeight > 0;
          final bottomButtonAreaHeight =
              FixedBottomButton.fixedBottomButtonDefaultHeight + mediaQuery.padding.bottom + 20;

          final screenHeight = mediaQuery.size.height;
          final defaultMaxHeight = (screenHeight * 0.7).clamp(480.0, 650.0).toDouble();
          final keyboardVisibleMaxHeight = (screenHeight - keyboardHeight - 96).clamp(260.0, 650.0).toDouble();
          final maxHeight = isKeyboardVisible ? keyboardVisibleMaxHeight : defaultMaxHeight;

          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(bottom: isKeyboardVisible ? bottomButtonAreaHeight : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: CoconutDatePicker(
                                amLabel: t.am,
                                pmLabel: t.pm,
                                timeLabel: t.bottom_sheet.date_picker.time,
                                initialDate: selectedDate ?? today,
                                currentDate: today,
                                onDateChanged: (date) {
                                  debugPrint(date.toIso8601String());
                                  selectedDate = date;
                                },
                                firstDate: today,
                                lastDate: DateTime(today.year + 100, today.month, today.day),
                                showTimeSelector: true,
                                selectedTime: selectedTime,
                                onTimeChanged: (time) {
                                  setBottomSheetState(() {
                                    selectedTime = time;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: bottomButtonAreaHeight,
                      child: FixedBottomButton(
                        isVisibleAboveKeyboard: false,
                        onButtonClicked: () {
                          final date = selectedDate ?? today;
                          final selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          onDateTimeSelected(selectedDateTime);
                          Navigator.pop(context);
                        },
                        text: t.next,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
