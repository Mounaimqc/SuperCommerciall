/// Model representing a Supplier (Fournisseur) from SAGE API
class FournisseurModel {
  final String id; // IDTiers
  final String name; // Nom
  final String phone; // Téléphone
  final String address; // Adresse
  final String city; // Extracted or default
  final String email; // Email (default to N/A if not present)
  final double solde; // Solde (Outstanding Balance / Purchases Total)
  final double ancienSolde; // AncienSolde
  
  // Fiscal & legal fields (if available)
  final String taxNumber; // MF / Matricule Fiscale
  final String commercialRegister; // RC / Registre de Commerce
  final String nif; // NIF
  final String nis; // NIS

  FournisseurModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.email,
    required this.solde,
    required this.ancienSolde,
    this.taxNumber = '',
    this.commercialRegister = '',
    this.nif = '',
    this.nis = '',
  });

  /// Helper to safely clean dynamic values to strings
  static String _cleanString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    String str = value.toString().trim();
    while (str.startsWith('.')) {
      str = str.substring(1).trim();
    }
    return str.isEmpty ? defaultValue : str;
  }

  /// Helper to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  /// Factory constructor to parse JSON maps from API response
  factory FournisseurModel.fromJson(Map<String, dynamic> json) {
    final rawAddress = _cleanString(json['Adresse']);
    final rawEmail = _cleanString(json['Email'] ?? json['Courriel'] ?? json['Note']); // Fallback to Note or empty
    final email = rawEmail.contains('@') ? rawEmail : 'non-renseigné@fournisseur.com';

    // City extraction logic similar to ClientModel
    String extractedCity = 'Algeria';
    String extractedAddress = rawAddress.isEmpty ? 'Aucune adresse' : rawAddress;

    if (rawAddress.isNotEmpty && rawAddress.length <= 15 && !rawAddress.contains(' ')) {
      extractedCity = rawAddress;
      extractedAddress = 'Wilaya de $rawAddress';
    }

    final mfVal = _cleanString(json['MF'] ?? json['MatriculeFiscale'] ?? json['NumFiscal']);
    final rcVal = _cleanString(json['RC'] ?? json['RegistreCommerce']);
    final nifVal = _cleanString(json['NIF']);
    final nisVal = _cleanString(json['NIS']);

    return FournisseurModel(
      id: _cleanString(json['IDTiers'], defaultValue: '0'),
      name: _cleanString(json['Nom'], defaultValue: 'Fournisseur Inconnu'),
      phone: _cleanString(json['Téléphone']),
      address: extractedAddress,
      city: extractedCity,
      email: email,
      solde: _parseDouble(json['Solde']),
      ancienSolde: _parseDouble(json['AncienSolde']),
      taxNumber: (mfVal == '0' || mfVal == '0.0') ? '' : mfVal,
      commercialRegister: (rcVal == '0' || rcVal == '0.0') ? '' : rcVal,
      nif: (nifVal == '0' || nifVal == '0.0') ? '' : nifVal,
      nis: (nisVal == '0' || nisVal == '0.0') ? '' : nisVal,
    );
  }

  /// Formatted solde string with DZD currency
  String get formattedSolde => '${solde.toStringAsFixed(2)} DZD';

  /// Helper to check if the supplier has a valid phone number
  bool get hasPhone => phone.isNotEmpty && phone.length >= 8;
}

