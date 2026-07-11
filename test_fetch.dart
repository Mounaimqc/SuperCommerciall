// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/models/client_model.dart';
import 'lib/utils/constants.dart';

void main() async {
  print('📡 Connexion à l\'API SAGE : ${AppConstants.clientsApiUrl}...\n');
  try {
    final response = await http.get(Uri.parse(AppConstants.clientsApiUrl));
    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = json.decode(decodedBody);

      final List<ClientModel> clients = jsonList
          .map((item) => ClientModel.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ SUCCÈS : ${clients.length} clients récupérés depuis la base de données !\n');
      print('=== APERÇU DES 10 PREMIERS CLIENTS ===');
      for (int i = 0; i < 10 && i < clients.length; i++) {
        final c = clients[i];
        print('[$i] CODE: ${c.code} | NOM: "${c.name}" | VILLE: ${c.city} | SOLDE: ${c.formattedSolde}');
      }
      print('======================================\n');
      print('💡 Les données sont prêtes à être affichées dans l\'application Flutter !');
    } else {
      print('❌ Erreur HTTP : ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur lors de la récupération : $e');
  }
}
