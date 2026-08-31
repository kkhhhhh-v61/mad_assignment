import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; //
import '../models.dart'; //

// login
Future<AppUser?> loginUser(String email, String password) async {
  try {
    // verify email and password from supabase
    final AuthResponse res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final User? user = res.user;

    if (user != null) {
      // get the data from profiles table
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single(); // single() mean just get this record

      return AppUser.fromJson(data, user.email ?? '');
    }
  } catch (e) {
    print("Login Error: $e");
    return null;
  }
  return null;
}

// Register - Customer(def)
Future<String?> registerCustomer({
  required String email,
  required String password,
  required String name,
  required String phone,
  required String address,
}) async {
  try {
    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    final User? user = res.user;

    if (user != null) {
      await supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'name': name,
        'phone': phone,
        'address': address,
        'role': 'customer',
      });
      return null;
    }
    return "Unknown error occurred during account creation.";
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return "Database Error: $e";
  }
}