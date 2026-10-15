import 'account.dart';
import 'category.dart';

// Lo que el bottom sheet necesita para llenar sus listas desplegables.
// Un record basta: no tiene comportamiento, solo agrupa dos listas.
typedef MovementFormOptions = ({
  List<Account> accounts,
  List<Category> categories,
});
