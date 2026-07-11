/// Client Model representing a customer from the SAGE API
class ClientModel {
  final String id;
  final String databaseId;
  final String code;
  final String name;
  final String address;
  final String city;
  final String phone;
  final double solde;
  final String representant;

  ClientModel({
    required this.id,
    required this.databaseId,
    required this.code,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.solde,
    required this.representant,
  });

  /// Helper method to clean string values by trimming and removing leading dots
  static String _cleanString(dynamic value) {
    if (value == null) return '';
    String str = value.toString().trim();
    while (str.startsWith('.')) {
      str = str.substring(1).trim();
    }
    return str;
  }

  /// Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  /// Factory method to create a [ClientModel] from a JSON map
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    final rawAddress = _cleanString(json['ADRESSE']);
    final rawRep = _cleanString(json['REPRESENTANT']);

    // Extract City: if ADRESSE is just a city name (like ALGER, SETIF), use it.
    // Otherwise use representant or default to 'Algeria'.
    String extractedCity = 'Algeria';
    String extractedAddress = rawAddress.isEmpty ? 'No address provided' : rawAddress;

    if (rawAddress.isNotEmpty && rawAddress.length <= 15 && !rawAddress.contains(' ')) {
      extractedCity = rawAddress;
      extractedAddress = 'Wilaya de $rawAddress';
    } else if (rawRep.isNotEmpty) {
      extractedCity = rawRep;
    }

    return ClientModel(
      id: json['id']?.toString() ?? '',
      databaseId: json['ID']?.toString() ?? '',
      code: json['CODE']?.toString().trim() ?? 'N/A',
      name: json['NOM']?.toString().trim() ?? 'Unknown Client',
      address: extractedAddress,
      city: extractedCity,
      phone: json['TEL']?.toString().trim() ?? '',
      solde: _parseDouble(json['SOLDE']),
      representant: rawRep,
    );
  }

  /// Check if the client has a valid phone number for calls/whatsapp
  bool get hasPhone => phone.isNotEmpty && phone.length >= 8;

  /// Formatted solde string with DZD currency
  String get formattedSolde {
    return '${solde.toStringAsFixed(2)} DZD';
  }
}
