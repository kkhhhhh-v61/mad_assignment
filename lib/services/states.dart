import 'package:mad_assignment/models.dart';

import '../main.dart';

const Map<String, String> stateEnglishToMalay = {
  'penang': 'Pulau Pinang',
  'pulau pinang': 'Pulau Pinang',
  'malacca': 'Melaka',
  'melaka': 'Melaka',
  'johor': 'Johor',
  'kedah': 'Kedah',
  'kelantan': 'Kelantan',
  'negeri sembilan': 'Negeri Sembilan',
  'pahang': 'Pahang',
  'perak': 'Perak',
  'perlis': 'Perlis',
  'sabah': 'Sabah',
  'sarawak': 'Sarawak',
  'selangor': 'Selangor',
  'terengganu': 'Terengganu',
  'kuala lumpur': 'Kuala Lumpur',
  'kl': 'Kuala Lumpur',
  'wilayah persekutuan kuala lumpur': 'Kuala Lumpur',
  'wp kuala lumpur': 'Kuala Lumpur',
  'labuan': 'Labuan',
  'wilayah persekutuan labuan': 'Labuan',
  'wp labuan': 'Labuan',
  'putrajaya': 'Putrajaya',
  'wilayah persekutuan putrajaya': 'Putrajaya',
  'wp putrajaya': 'Putrajaya',
};

String normalizeStateToDbName(String rawState) {
  final clean = rawState.trim().toLowerCase();
  if (stateEnglishToMalay.containsKey(clean)) {
    return stateEnglishToMalay[clean]!;
  }
  for (final entry in stateEnglishToMalay.entries) {
    if (clean.contains(entry.key)) {
      return entry.value;
    }
  }
  return rawState.trim();
}

String extractStateFromAddress(String address) {
  final lower = address.toLowerCase();
  final sortedEntries = stateEnglishToMalay.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));

  for (final entry in sortedEntries) {
    if (lower.contains(entry.key)) {
      return entry.value;
    }
  }
  return 'Pulau Pinang';
}

bool isSameState(String stateA, String stateB) {
  if (stateA.trim().isEmpty || stateB.trim().isEmpty) return false;
  return normalizeStateToDbName(stateA).toLowerCase() ==
      normalizeStateToDbName(stateB).toLowerCase();
}

Future<List<States>> fetchStates() async {
  try {
    final response = await supabase.from('states').select();
    return response.map((e) => States.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
}
