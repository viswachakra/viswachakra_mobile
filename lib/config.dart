// Supabase connection for the Viswachakra mobile app.
// The anon (publishable) key is safe to ship in the app — Row Level Security + login
// protect the data. The service_role secret key is NEVER used in the app.
class Config {
  static const String supabaseUrl = 'https://lxeuvxkhieszizdclivg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4ZXV2eGtoaWVzeml6ZGNsaXZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3NjUxNjQsImV4cCI6MjEwMjM0MTE2NH0.XEJ7Kc7IR-0suBeHFiLWhq_4PTgAXoVIIvFB9o2DkjU';
}
