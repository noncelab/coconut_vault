enum MultisigExportFormat {
  bsms('BSMS', 'BSMS'),
  blueWallet('BlueWallet Vault Multisig', 'BlueWallet'),
  coldcard('Coldcard Multisig', 'Coldcard'),
  keystone('Keystone Multisig', 'Keystone'),
  descriptor('Output Descriptor', 'Descriptor'),
  specter('Specter Desktop', 'Specter');

  final String key;
  final String displayTitle;

  const MultisigExportFormat(this.key, this.displayTitle);
}
