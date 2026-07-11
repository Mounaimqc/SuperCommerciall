import '../utils/constants.dart';

class ChargeModel {
  final String idCharge;
  final String date;
  final String heure;
  final double montant;
  final String modeReglement;
  final String ajoutePar;
  final String modifiePar;
  final String type;
  final int paye;
  final String observation;
  final String motif;

  ChargeModel({
    required this.idCharge,
    required this.date,
    required this.heure,
    required this.montant,
    required this.modeReglement,
    required this.ajoutePar,
    required this.modifiePar,
    required this.type,
    required this.paye,
    required this.observation,
    required this.motif,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    final str = value.toString().trim();
    if (str.isEmpty) return 0;
    return int.tryParse(str) ?? (str.toLowerCase() == 'true' || str == '1' ? 1 : 0);
  }

  factory ChargeModel.fromJson(Map<String, dynamic> json) {
    return ChargeModel(
      idCharge: json['IDcharge']?.toString() ?? json['idCharge']?.toString() ?? json['id']?.toString() ?? '0',
      date: json['Date']?.toString() ?? json['date']?.toString() ?? '',
      heure: json['Heure']?.toString() ?? json['heure']?.toString() ?? '',
      montant: _parseDouble(json['Montant'] ?? json['montant']),
      modeReglement: json['ModeReglement']?.toString() ?? json['modeReglement']?.toString() ?? '1',
      ajoutePar: json['AjoutePar']?.toString() ?? json['ajoutePar']?.toString() ?? '',
      modifiePar: json['ModifiePar']?.toString() ?? json['modifiePar']?.toString() ?? '',
      type: json['Type']?.toString() ?? json['type']?.toString() ?? 'Dépense',
      paye: _parseInt(json['Paye'] ?? json['paye']),
      observation: json['Observation']?.toString() ?? json['observation']?.toString() ?? '',
      motif: json['Motif']?.toString() ?? json['motif']?.toString() ?? 'Charge sans motif',
    );
  }

  String get formattedMontant => AppConstants.formatMoney(montant);
  bool get isPaye => paye == 1;

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return motif.toLowerCase().contains(lowerQuery) ||
        observation.toLowerCase().contains(lowerQuery) ||
        type.toLowerCase().contains(lowerQuery) ||
        montant.toString().contains(lowerQuery);
  }
}
