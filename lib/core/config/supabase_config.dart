import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL']?.trim();
    final key =
        (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
                dotenv.env['SUPABASE_ANON_KEY'])
            ?.trim();
    if (url == null ||
        Uri.tryParse(url)?.host.isNotEmpty != true ||
        key == null ||
        key.isEmpty) {
      throw StateError(
        'Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in .env.',
      );
    }
    if (key.startsWith('sb_secret_')) {
      throw StateError('Use a publishable key in the app, never a secret key.');
    }
    await Supabase.initialize(url: url, publishableKey: key);
  }
}
