import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabaseClient = Supabase.instance.client;

  Future <UserSB> signInWithEmail(String email, String password) async {
    AuthResponse authResponse = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (authResponse.user != null) {
      UserSB user = UserSB(
        id: authResponse.user!.id,
        nome: authResponse.user!.userMetadata?['display_name'] ?? '',
      );
      return user;
    } else {
      throw Exception('Failed to sign in');
    }
  }

  Future <AuthResponse> signUp(String email, String password, String name) async {
    AuthResponse authResponse = await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': name,
      },
    );
    await signOut();

    try {
      await supabaseClient.from('users').insert({
        'id': authResponse.user!.id,
        'name': name,
      });
    } on Exception catch (e) {
      if(kDebugMode){
        print("Error inserting user: $e");
      }
    }
    return authResponse;
  }


  Future <void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  UserSB getCurrentUser() {
    final user = supabaseClient.auth.currentUser;
    if (user != null) {
      return UserSB(
        id: user.id,
        nome: user.userMetadata?['display_name'] ?? user.userMetadata?['name'] ?? '',
      );
    } else {
      throw Exception('No user is currently signed in');
    }
  }

  Future <void> resetPassword(String email) async {
    await supabaseClient.auth.resetPasswordForEmail(email);
  }

  Future<void> nativeGoogleSignIn() async {

    var webClientId = dotenv.env['GOOGLE_CLIENT_ID']!;

    var iosClientId = dotenv.env['IOS_CLIENT_ID']!;
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      throw Exception('Google sign-in was canceled');
    }
    
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;
    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }
    await supabaseClient.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    UserSB user = getCurrentUser();

    try {
      await supabaseClient.from('users').upsert({
        'id': user.id,
        'name': user.nome,
      },onConflict: 'id',);
    } on Exception catch (e) {
      if(kDebugMode) {
        print("Error inserting user: $e");
      }
    }
  }

  Future<void> signInWithFacebook() async {
    await supabaseClient.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.madsafebox://login-callback',
      authScreenLaunchMode: LaunchMode.platformDefault,
    );

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final user = session.user;

        try {
          await supabaseClient.from('users').upsert({
            'id': user.id,
            'name': user.userMetadata?['name'],
          }, onConflict: 'id');
        } catch (e) {
          if(kDebugMode){
            print("Error inserting user: $e");
          }
        }
      }
    });
  }

}