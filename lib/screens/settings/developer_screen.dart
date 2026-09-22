import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/test_fixtures.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  bool _isLoading = false;
  String? _message;

  Future<void> _loadTestWallets() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final walletProvider = context.read<WalletProvider>();
      await loadTestWallets(walletProvider);
      setState(() => _message = 'Test wallets loaded successfully.');
    } catch (e) {
      setState(() => _message = 'Failed to load test wallets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: _isLoading ? null : _loadTestWallets, child: const Text('Load test wallets')),
            const SizedBox(height: 16),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_message != null)
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _message!.startsWith('Failed') ? Colors.red : Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
