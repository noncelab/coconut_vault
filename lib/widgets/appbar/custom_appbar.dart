// import 'dart:ui';

// import 'package:coconut_design_system/coconut_design_system.dart';
// import 'package:coconut_lib/coconut_lib.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:coconut_vault/widgets/label_testnet.dart';

// class CustomAppBar {
//   ValueNotifier<bool> isButtonActiveNotifier = ValueNotifier<bool>(false);

//   static AppBar build({
//     required String title,
//     required BuildContext context,
//     required bool hasRightIcon,
//     VoidCallback? onRightIconPressed,
//     VoidCallback? onBackPressed,
//     IconButton? rightIconButton,
//     bool isBottom = false,
//     Color? backgroundColor = CoconutColors.white,
//     bool showTestnetLabel = false,
//     bool? setSearchBar = false,
//   }) {
//     Widget? titleWidget = Column(
//       children: [
//         Text(title),
//         showTestnetLabel
//             ? Column(
//                 children: [
//                   const SizedBox(
//                     height: 3,
//                   ),
//                   if (NetworkType.currentNetworkType.isTestnet) const TestnetLabelWidget(),
//                 ],
//               )
//             : Container(
//                 width: 1,
//               ),
//       ],
//     );

//     return AppBar(
//         title: titleWidget,
//         centerTitle: true,
//         backgroundColor: backgroundColor,
//         titleTextStyle: CoconutTypography.body1_16.merge(
//           const TextStyle(
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         toolbarTextStyle: CoconutTypography.heading4_18,
//         leading: Navigator.canPop(context)
//             ? IconButton(
//                 icon: isBottom
//                     ? const Icon(Icons.close_rounded)
//                     : SvgPicture.asset('assets/svg/back.svg'),
//                 onPressed: () {
//                   if (onBackPressed != null) {
//                     onBackPressed();
//                   } else {
//                     Navigator.pop(context);
//                   }
//                 },
//               )
//             : null,
//         actions: [
//           if (hasRightIcon && rightIconButton == null)
//             IconButton(
//               color: CoconutColors.black,
//               focusColor: CoconutColors.black.withOpacity(0.15),
//               icon: const Icon(CupertinoIcons.ellipsis_vertical, size: 22),
//               onPressed: () {
//                 if (onRightIconPressed != null) {
//                   onRightIconPressed();
//                 }
//               },
//             )
//           else if (hasRightIcon && rightIconButton != null)
//             rightIconButton
//         ],
//         flexibleSpace: ClipRect(
//             child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                 child: Container(
//                   color: Colors.transparent,
//                 ))));
//   }

//   static AppBar buildWithNext({
//     required String title,
//     required BuildContext context,
//     required VoidCallback onNextPressed,
//     VoidCallback? onBackPressed,
//     bool hasBackdropFilter = true,
//     bool isActive = true,
//     bool isBottom = false,
//     String buttonName = '다음',
//     Color backgroundColor = CoconutColors.white,
//   }) {
//     return AppBar(
//         title: Text(title),
//         centerTitle: true,
//         backgroundColor: backgroundColor,
//         titleTextStyle: CoconutTypography.body1_16.merge(
//           const TextStyle(
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         toolbarTextStyle: CoconutTypography.heading4_18,
//         leading: Navigator.canPop(context)
//             ? IconButton(
//                 icon: isBottom
//                     ? const Icon(Icons.close_rounded, size: 22)
//                     : SvgPicture.asset('assets/svg/back.svg'),
//                 onPressed: () {
//                   if (onBackPressed != null) {
//                     onBackPressed();
//                   } else {
//                     Navigator.pop(context);
//                   }
//                 },
//               )
//             : null,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//             child: GestureDetector(
//               onTap: isActive ? onNextPressed : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(14.0),
//                   border: Border.all(
//                       color: isActive ? Colors.transparent : CoconutColors.black.withOpacity(0.06)),
//                   color: isActive ? CoconutColors.gray800 : CoconutColors.gray150,
//                 ),
//                 child: Center(
//                   child: Text(
//                     buttonName,
//                     style: CoconutTypography.body2_14.merge(
//                       TextStyle(
//                         fontSize: 11,
//                         color:
//                             isActive ? CoconutColors.white : CoconutColors.black.withOpacity(0.3),
//                         fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//         flexibleSpace: hasBackdropFilter
//             ? ClipRect(
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                   child: Container(
//                     color: Colors.transparent,
//                   ),
//                 ),
//               )
//             : Container());
//   }

//   static AppBar buildWithSave(
//       {required String title,
//       required BuildContext context,
//       required VoidCallback onPressedSave,
//       bool isActive = true,
//       bool isBottom = false}) {
//     return AppBar(
//         title: Text(
//           title,
//         ),
//         centerTitle: true,
//         backgroundColor: CoconutColors.white,
//         titleTextStyle: CoconutTypography.body1_16.merge(
//           const TextStyle(
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         toolbarTextStyle: CoconutTypography.heading4_18,
//         leading: Navigator.canPop(context)
//             ? IconButton(
//                 icon: isBottom
//                     ? const Icon(Icons.close_rounded, size: 22)
//                     : SvgPicture.asset('assets/svg/back.svg'),
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//               )
//             : null,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//             child: GestureDetector(
//               onTap: isActive ? onPressedSave : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16.0),
//                   border: Border.all(
//                       color: isActive ? Colors.transparent : CoconutColors.black.withOpacity(0.06)),
//                   color: isActive ? CoconutColors.gray800 : CoconutColors.gray150,
//                 ),
//                 child: Center(
//                   child: Text(
//                     '저장',
//                     style: CoconutTypography.body2_14.merge(
//                       TextStyle(
//                         color:
//                             isActive ? CoconutColors.white : CoconutColors.black.withOpacity(0.3),
//                         fontSize: 11,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//         flexibleSpace: ClipRect(
//             child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                 child: Container(
//                   color: Colors.transparent,
//                 ))));
//   }

//   static AppBar buildWithClose({
//     required String title,
//     required BuildContext context,
//     Color? backgroundColor,
//     VoidCallback? onBackPressed,
//     bool hasNextButton = false,
//     bool isNextButtonActive = false,
//     String nextButtonText = '선택',
//     VoidCallback? onNextPressed,
//   }) {
//     return AppBar(
//       centerTitle: true,
//       backgroundColor: backgroundColor ?? Colors.transparent,
//       title: Text(title),
//       titleTextStyle:
//           CoconutTypography.body1_16.merge(const TextStyle(fontWeight: FontWeight.w500)),
//       toolbarTextStyle: CoconutTypography.heading4_18,
//       leading: IconButton(
//         onPressed: onBackPressed ??
//             () {
//               Navigator.pop(context);
//             },
//         icon: const Icon(
//           Icons.close_rounded,
//           color: CoconutColors.black,
//           size: 22,
//         ),
//       ),
//       actions: [
//         if (hasNextButton && onNextPressed != null)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//             child: GestureDetector(
//               onTap: isNextButtonActive ? onNextPressed : null,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16.0),
//                   border: Border.all(
//                     color: isNextButtonActive
//                         ? Colors.transparent
//                         : CoconutColors.black.withOpacity(0.06),
//                   ),
//                   color: isNextButtonActive ? CoconutColors.gray800 : CoconutColors.gray150,
//                 ),
//                 child: Center(
//                   child: Text(
//                     nextButtonText,
//                     style: CoconutTypography.body2_14.merge(
//                       TextStyle(
//                         fontSize: 11,
//                         color: isNextButtonActive
//                             ? Colors.white
//                             : CoconutColors.black.withOpacity(0.3),
//                         fontWeight: isNextButtonActive ? FontWeight.bold : FontWeight.normal,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
