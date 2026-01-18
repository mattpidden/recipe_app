import 'package:purchases_flutter/purchases_flutter.dart';

Future<bool> hasEntitlement() async {
  CustomerInfo customerInfo = await Purchases.getCustomerInfo();
  final hasPro = customerInfo.entitlements.active.containsKey('RecipeApp Pro');
  return hasPro;
}
