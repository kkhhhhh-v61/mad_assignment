import 'package:mad_assignment/models.dart';

import '../main.dart';

Future<List<States>> fetchStates() async {
  try {
    final response = await supabase.from('states').select();
    return response.map((e) => States.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
}
