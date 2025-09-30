import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final stagesProvider = FutureProvider<List<String>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/stages.json');
  final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
  final stages = decoded['stages'];
  if (stages is List) {
    return stages.map((item) => item.toString()).toList();
  }
  return const <String>[];
});
