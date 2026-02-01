// ignore_for_file: constant_identifier_names

class SystemConstants {
  // Contract Type IDs (Matches Backend Database)
  static const int CONTRACT_TYPE_MARRIAGE = 1;
  static const int CONTRACT_TYPE_SALE_MOVABLE = 2; // Not used as primary category usually?
  static const int CONTRACT_TYPE_SALE_IMMOVABLE = 3; // Not used as primary category usually?
  static const int CONTRACT_TYPE_AGENCY = 4;
  static const int CONTRACT_TYPE_DISPOSITION = 5;
  static const int CONTRACT_TYPE_DIVISION = 6;
  static const int CONTRACT_TYPE_DIVORCE = 7;
  static const int CONTRACT_TYPE_RECONCILIATION = 8;
  static const int CONTRACT_TYPE_SALE = 10; // "عقد مبيع" generic

  // Constraint Type IDs (Distinct from Contract Types - نوع القيد)
  static const int CONSTRAINT_TYPE_SALE_IMMOVABLE = 1;
  static const int CONSTRAINT_TYPE_SALE_MOVABLE = 2;
  static const int CONSTRAINT_TYPE_DISPOSITION = 3;
  static const int CONSTRAINT_TYPE_AGENCY = 4;
  static const int CONSTRAINT_TYPE_DIVISION = 5;
  static const int CONSTRAINT_TYPE_MARRIAGE = 6;
  static const int CONSTRAINT_TYPE_DIVORCE = 7;
  static const int CONSTRAINT_TYPE_RECONCILIATION = 8;
  static const int CONSTRAINT_TYPE_SALE = 19;

  // Lists for categorization
  static const List<int> SALES_TYPES = [CONTRACT_TYPE_SALE, CONTRACT_TYPE_SALE_MOVABLE, CONTRACT_TYPE_SALE_IMMOVABLE];
}
