import '../utils/constants.dart';

/// Données pour le graphique des ventes mensuelles
class MonthlySalesData {
  final String month; // 'Jan', 'Fév', etc.
  final double amount;
  final int count;

  const MonthlySalesData({
    required this.month,
    required this.amount,
    required this.count,
  });
}

/// Produit le plus vendu (Top Product)
class TopProductData {
  final String code;
  final String name;
  final double quantitySold;
  final double totalRevenue;

  const TopProductData({
    required this.code,
    required this.name,
    required this.quantitySold,
    required this.totalRevenue,
  });

  String get formattedRevenue => AppConstants.formatMoney(totalRevenue);
}

/// Meilleur client (Top Client)
class TopClientData {
  final String id;
  final String name;
  final String code;
  final double totalSpent;
  final int invoicesCount;

  const TopClientData({
    required this.id,
    required this.name,
    required this.code,
    required this.totalSpent,
    required this.invoicesCount,
  });

  String get formattedTotalSpent => AppConstants.formatMoney(totalSpent);
}

/// Modèle global agrégé des statistiques de l'application
class StatisticsModel {
  final double totalSalesAmount;
  final double totalPurchasesAmount;
  final int invoicesCount;
  final int clientsCount;
  final int productsCount;
  final double totalStockValue;
  final List<MonthlySalesData> monthlySales;
  final List<TopProductData> topProducts;
  final List<TopClientData> topClients;

  const StatisticsModel({
    required this.totalSalesAmount,
    required this.totalPurchasesAmount,
    required this.invoicesCount,
    required this.clientsCount,
    required this.productsCount,
    required this.totalStockValue,
    required this.monthlySales,
    required this.topProducts,
    required this.topClients,
  });

  factory StatisticsModel.empty() {
    return const StatisticsModel(
      totalSalesAmount: 0.0,
      totalPurchasesAmount: 0.0,
      invoicesCount: 0,
      clientsCount: 0,
      productsCount: 0,
      totalStockValue: 0.0,
      monthlySales: [],
      topProducts: [],
      topClients: [],
    );
  }

  String get formattedTotalSales => AppConstants.formatMoney(totalSalesAmount);
  String get formattedTotalPurchases => AppConstants.formatMoney(totalPurchasesAmount);
  String get formattedTotalStockValue => AppConstants.formatMoney(totalStockValue);
  double get netProfit => totalSalesAmount - totalPurchasesAmount;
  String get formattedNetProfit => AppConstants.formatMoney(netProfit);
}
