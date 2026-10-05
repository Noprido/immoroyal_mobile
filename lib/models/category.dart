import 'package:flutter/widgets.dart';

class CategoryModel {
  final String value;
  final String label;
  final IconData icon;
  final bool venteParDefaut;
  final List<String> champsCaracteristiques;
  final bool afficheDimension;
  final String titreFormat;

  const CategoryModel({
    required this.value,
    required this.label,
    required this.icon,
    required this.venteParDefaut,
    required this.champsCaracteristiques,
    required this.afficheDimension,
    required this.titreFormat,
  });

  bool get supporteStanding => champsCaracteristiques.contains('standing');

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      value: json['value'],
      label: json['label'],
      icon: IconData(
        int.parse((json['iconCodePoint'] as String).substring(2), radix: 16),
        fontFamily: json['iconFont'],
      ),
      venteParDefaut: json['venteParDefaut'] ?? false,
      champsCaracteristiques: List<String>.from(json['champsCaracteristiques'] ?? []),
      afficheDimension: json['afficheDimension'] ?? false,
      titreFormat: json['titreFormat'] ?? 'simple',
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'iconCodePoint': '0x${icon.codePoint.toRadixString(16)}',
        'iconFont': icon.fontFamily,
        'venteParDefaut': venteParDefaut,
        'champsCaracteristiques': champsCaracteristiques,
        'afficheDimension': afficheDimension,
        'titreFormat': titreFormat,
      };
}