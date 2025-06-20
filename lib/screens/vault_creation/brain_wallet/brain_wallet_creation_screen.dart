import 'dart:math';

import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/constants/app_routes.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:coconut_vault/model/multisig/multisig_signer.dart';
import 'package:coconut_vault/model/single_sig/single_sig_wallet.dart';
import 'package:coconut_vault/providers/visibility_provider.dart';
import 'package:coconut_vault/providers/wallet_creation_provider.dart';
import 'package:coconut_vault/screens/vault_creation/brain_wallet/brain_wallet_backup_bottom_sheet.dart';
import 'package:coconut_vault/screens/vault_creation/vault_name_and_icon_setup_screen.dart';
import 'package:coconut_vault/widgets/bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/styles.dart';
import 'package:coconut_vault/widgets/appbar/custom_appbar.dart';
import 'package:coconut_vault/widgets/textfield/custom_textfield.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BrainWalletCreationScreen extends StatefulWidget {
  const BrainWalletCreationScreen({super.key});

  @override
  State<BrainWalletCreationScreen> createState() => _BrainWalletCreationScreenState();
}

class _BrainWalletCreationScreenState extends State<BrainWalletCreationScreen> {
  late WalletProvider _walletProvider;
  late WalletCreationProvider _walletCreationProvider;
  int _numPhrases = 3;
  List<String> _phrases = [];
  List<String> _mnemonic = [];
  List<TextEditingController> _phraseControllers = [];
  List<FocusNode> _phraseFocusNodes = [];

  // final FocusNode _phraseFocusNode = FocusNode();

  // final TextEditingController _passphraseConfirmController =
  //     TextEditingController();
  // final FocusNode _fcnodePassphrase = FocusNode();

  @override
  void initState() {
    super.initState();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletCreationProvider = Provider.of<WalletCreationProvider>(context, listen: false)
      ..resetAll();

    // Initialize lists
    _phrases = List.filled(_numPhrases, '');
    _phraseControllers = List.generate(_numPhrases, (_) => TextEditingController());
    _phraseFocusNodes = List.generate(_numPhrases, (_) => FocusNode());

    assert(_phraseFocusNodes.length == _numPhrases, 'Focus nodes not properly initialized');
    assert(_phraseControllers.length == _numPhrases, 'Controllers not properly initialized');
    assert(_phrases.length == _numPhrases, 'Phrases not properly initialized');

    _initListeners();
  }

  void _initListeners() {
    for (int i = 0; i < _numPhrases; i++) {
      _phraseControllers[i].addListener(() {
        if (mounted) {
          setState(() {
            _phrases[i] = _phraseControllers[i].text;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _phraseControllers) {
      controller.dispose();
    }
    for (var focusNode in _phraseFocusNodes) {
      focusNode.dispose();
    }
    // _phraseFocusNode.dispose();
    // _passphraseConfirmController.dispose();
    // _fcnodePassphrase.dispose();

    super.dispose();
  }

  void _addMorePhrase() {
    setState(() {
      final oldPhrases = List<String>.from(_phrases); // Save existing phrases
      _numPhrases++;

      // Recreate lists with new size while preserving existing values
      _phrases =
          List.generate(_numPhrases, (index) => index < oldPhrases.length ? oldPhrases[index] : '');
      _phraseControllers.add(TextEditingController());
      _phraseFocusNodes.add(FocusNode());

      // Add listener for the new controller
      // _phraseControllers.last.addListener(() {
      //   if (mounted) {
      //     setState(() {
      //       _phrases[_numPhrases - 1] = _phraseControllers.last.text;
      //     });
      //   }
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure lists are initialized before building
    if (_phraseFocusNodes.isEmpty) {
      _phraseFocusNodes = List.generate(_numPhrases, (_) => FocusNode());
    }
    if (_phraseControllers.isEmpty) {
      _phraseControllers = List.generate(_numPhrases, (_) => TextEditingController());
    }
    if (_phrases.isEmpty) {
      _phrases = List.generate(_numPhrases, (_) => '');
    }

    // Ensure all lists have the same length
    assert(_phraseFocusNodes.length == _numPhrases, 'Focus nodes length mismatch');
    assert(_phraseControllers.length == _numPhrases, 'Controllers length mismatch');
    assert(_phrases.length == _numPhrases, 'Phrases length mismatch');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _handleBackNavigation();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: CustomAppBar.buildWithNext(
              title: t.brain_wallet_creation_screen.title,
              context: context,
              onBackPressed: _handleBackNavigation,
              onNextPressed: _handleNextButton,
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      children: <Widget>[
                        Text(t.brain_wallet_creation_screen.insert_phrase_more_than_three,
                            style: Styles.body1Bold),
                        const SizedBox(height: 30),
                        Column(
                          children: [
                            for (int i = 0; i < _numPhrases; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  children: [
                                    Text("${t.brain_wallet_creation_screen.phrase} ${i + 1}"),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CustomTextField(
                                        focusNode: _phraseFocusNodes[i],
                                        controller: _phraseControllers[i],
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(
                                              RegExp(r'[^a-zA-Z\u0080-\uFFFF ]'))
                                        ],
                                        placeholder: i < 3
                                            ? (i == 0
                                                ? t.brain_wallet_creation_screen.example_0
                                                : i == 1
                                                    ? t.brain_wallet_creation_screen.example_1
                                                    : t.brain_wallet_creation_screen.example_2)
                                            : '',
                                        onChanged: (text) {
                                          if (mounted) {
                                            setState(() {
                                              _phrases[i] = text;
                                            });
                                          }
                                        },
                                        valid: _phrases[i].isNotEmpty && _phrases[i].length > 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CoconutUnderlinedButton(
                          text: t.brain_wallet_creation_screen.add_more_phrase,
                          onTap: _addMorePhrase,
                          textStyle: CoconutTypography.body3_12,
                          brightness: Brightness.light,
                          padding: const EdgeInsets.symmetric(vertical: Sizes.size16),
                        ),
                        const SizedBox(height: 20), // Add some bottom spacing
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // TODO: isolate
          Visibility(
            visible: false,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(color: MyColors.transparentBlack_30),
              child: const Center(
                child: CircularProgressIndicator(
                  color: MyColors.darkgrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  void _handleNextButton() {
    final List<String> phrases = _phrases.where((phrase) => phrase.isNotEmpty).toList();
    _mnemonic = [];
    for (int i = 0; i < phrases.length; i++) {
      String entropy = Hash.sha256(phrases[i].trim());
      Seed seed = Seed.fromHexadecimalEntropy(entropy);
      _mnemonic.add(seed.mnemonic);
    }
    MyBottomSheet.showBottomSheet_90(
      context: context,
      child: BrainWalletBackupBottomSheet(
        onConfirmPressed: () async {
          List<SinglesigWallet> singleSigWallets = [];
          for (int i = 0; i < _mnemonic.length; i++) {
            SinglesigWallet singleSigWallet = SinglesigWallet(
                null, phrases[i], Random().nextInt(9), Random().nextInt(9), _mnemonic[i], '');
            singleSigWallets.add(singleSigWallet);
            await _walletProvider.addSingleSigVault(singleSigWallet);
            //TODO: Add singleSigWallet to walletList
          }
          List<MultisigSigner> signers = [];
          for (int i = 0; i < singleSigWallets.length; i++) {
            SingleSignatureVault singleSignatureVault =
                SingleSignatureVault.fromMnemonic(singleSigWallets[i].mnemonic!);
            signers.add(MultisigSigner(
              id: i,
              innerVaultId: singleSigWallets[i].id,
              name: singleSigWallets[i].name,
              iconIndex: singleSigWallets[i].icon,
              colorIndex: singleSigWallets[i].color,
              signerBsms: singleSignatureVault.getSignerBsms(AddressType.p2trMuSig2, ""),
              keyStore: singleSignatureVault.keyStore,
            ));
          }
          _walletCreationProvider.setQuorumRequirement(signers.length, signers.length);
          _walletCreationProvider.setSigners(signers);
          _walletCreationProvider.setAddressType("p2trMuSig2");
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const VaultNameAndIconSetupScreen()));
        },
        onCancelPressed: () => Navigator.pop(context),
        mnemonic: _mnemonic,
        phrases: phrases,
      ),
    );
  }
}
