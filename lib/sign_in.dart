import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'generated/l10n.dart';
import 'routes.dart';

/// Main sign in page
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();

  // static void signOut(BuildContext context) async {
  //   await FirebaseAuth.instance.signOut();

  // }
}

class _SignInPageState extends State<SignInPage> {
  FirebaseAuth? authInstance;
  bool appleSignInAvailable = false;
  bool _isInitialized = false;

  // Loading states for each provider
  bool _isGoogleSigningIn = false;
  bool _isAppleSigningIn = false;
  bool _isFacebookSigningIn = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Only initialize on native platforms; web is handled by main.dart
    if (!kIsWeb) {
      _initializeApp();
    } else {
      // On web, Firebase is already initialized by main.dart
      // Just get the instance and set up listeners
      _initFirebaseAuthWeb();
    }
  }

  Future<void> _initFirebaseAuthWeb() async {
    if (authInstance == null) {
      authInstance = FirebaseAuth.instance;

      // Listen to auth state changes
      authInstance!.authStateChanges().listen((User? user) {
        if (mounted) {
          setState(() {});
          if (user != null) {
            debugPrint('Firebase auth state: User signed in - ${user.email}');
          } else {
            debugPrint('Firebase auth state: User signed out');
          }
        }
      });
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeApp() async {
    await _initFirebaseAuth();
    await _initGoogleSignIn();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initFirebaseAuth() async {
    if (authInstance == null) {
      try {
        authInstance = FirebaseAuth.instance;
        if (kIsWeb) await authInstance!.setPersistence(Persistence.SESSION);

        // Listen to auth state changes
        authInstance!.authStateChanges().listen((User? user) {
          if (mounted) {
            setState(() {});
            if (user != null) {
              debugPrint('Firebase auth state: User signed in - ${user.email}');
            } else {
              debugPrint('Firebase auth state: User signed out');
            }
          }
        });

        try {
          appleSignInAvailable = await SignInWithApple.isAvailable();
        } catch (e) {
          debugPrint('Apple Sign-In not available: $e');
          appleSignInAvailable = false;
        }
      } catch (e) {
        debugPrint('FirebaseAuth initialization error: $e');
        // Retry after delay
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _initFirebaseAuth();
          }
        }
      }
    }
  }

  /// google sign-in scopes
  final scopes = <String>['email', 'profile'];

  Future<void> _initGoogleSignIn() async {
    // Do not initialize on web; we use FirebaseAuth.signInWithPopup for web
    if (kIsWeb) return;

    // V7 API: Must call initialize() exactly once before other methods
    await GoogleSignIn.instance.initialize();
    debugPrint('Google Sign-In ready (v7 API)');
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Helper methods for state management
  void _setLoadingState({bool? google, bool? apple, bool? facebook}) {
    if (mounted) {
      setState(() {
        if (google != null) _isGoogleSigningIn = google;
        if (apple != null) _isAppleSigningIn = apple;
        if (facebook != null) _isFacebookSigningIn = facebook;
      });
    }
  }

  void _showError(String title, String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (mounted) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _logSignIn(String method) async {
    try {
      await FirebaseAnalytics.instance.logLogin(
        loginMethod: method,
        parameters: {
          "uid": authInstance!.currentUser!.uid,
          "name": authInstance!.currentUser!.displayName ?? "",
          "email": authInstance!.currentUser!.email ?? "",
          "phone": authInstance!.currentUser!.phoneNumber ?? "",
        },
      );
    } catch (e) {
      debugPrint('Failed to log analytics: $e');
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(MyRoutes.homePage);
    }
  }

  /// perform sign-in by google
  Future<void> _googleSignIn(BuildContext context) async {
    if (_isGoogleSigningIn) return;

    if (kIsWeb) {
      _setLoadingState(google: true);
      try {
        final provider = GoogleAuthProvider();
        for (var scope in scopes) {
          provider.addScope(scope);
        }
        await authInstance!.signInWithPopup(provider);
        await _logSignIn("Google-Web");
        if (mounted) {
          _setLoadingState(google: false);
        }
      } catch (e) {
        debugPrint('Web Google sign-in error: $e');
        _setLoadingState(google: false);
        _showError('Google Sign-In Error', e.toString());
      }
      return;
    }

    _setLoadingState(google: true);

    try {
      // V7 API: Use singleton and authenticate() method
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      // Get authentication tokens (idToken only, synchronous in v7)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Get access token via authorization client
      final GoogleSignInClientAuthorization authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);

      // Create Firebase credential
      final credentials = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      await authInstance!.signInWithCredential(credentials);

      // Log analytics
      await _logSignIn('Google');

      if (mounted) {
        _setLoadingState(google: false);
        _navigateToHome();
      }
    } on GoogleSignInException catch (error) {
      debugPrint('Google sign-in error: $error');
      _setLoadingState(google: false);
      if (error.code != GoogleSignInExceptionCode.canceled) {
        _showError('Google Sign-In Error', error.toString());
      }
    } catch (error) {
      debugPrint('Google sign-in error: $error');
      _setLoadingState(google: false);
      _showError('Google Sign-In Error', error.toString());
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Perform signin with apple ID
  Future<void> _appleSignIn(BuildContext context) async {
    if (_isAppleSigningIn) return;

    _setLoadingState(apple: true);

    if (!appleSignInAvailable) {
      // Web platform Apple Sign-In
      try {
        final provider = OAuthProvider("apple.com")
          ..addScope('email')
          ..addScope('name');

        await authInstance!.signInWithPopup(provider);
        await _logSignIn("Apple-Web");
        _setLoadingState(apple: false);
      } catch (e) {
        debugPrint('Web Apple sign-in error: $e');
        _setLoadingState(apple: false);
        _showError('Apple Sign-In Error', e.toString());
      }
      return;
    }

    // Native platform Apple Sign-In
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      await authInstance!.signInWithCredential(oauthCredential);

      // Update display name if provided
      if (appleCredential.givenName != null) {
        await authInstance!.currentUser!.updateDisplayName(
          "${appleCredential.givenName} ${appleCredential.familyName}",
        );
      }

      await _logSignIn("Apple");

      if (mounted) {
        _setLoadingState(apple: false);
        _navigateToHome();
      }
    } catch (error) {
      debugPrint('Apple sign-in error: $error');
      _setLoadingState(apple: false);
      _showError('Apple Sign-In Error', error.toString());
    }
  }

  /// signin with facebook
  Future<void> _facebookSignIn(BuildContext context) async {
    if (_isFacebookSigningIn) return;

    _setLoadingState(facebook: true);

    try {
      if (kIsWeb) {
        // Web platform Facebook Sign-In
        FacebookAuthProvider facebookProvider = FacebookAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'display': 'popup'});

        await authInstance!.signInWithPopup(facebookProvider);
        await _logSignIn("Facebook-Web");
      } else {
        // Native platform Facebook Sign-In
        final accessToken = await FacebookAuth.instance.login(
          permissions: const ['email', 'public_profile'],
        );

        if (accessToken.accessToken == null) {
          throw Exception('Facebook login returned no access token');
        }

        final FacebookAuthCredential credential =
            FacebookAuthProvider.credential(
                  accessToken.accessToken!.tokenString,
                )
                as FacebookAuthCredential;

        await authInstance!.signInWithCredential(credential);
        await _logSignIn("Facebook");
      }

      if (mounted) {
        _setLoadingState(facebook: false);
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Facebook Firebase auth error: ${e.code} - ${e.message}');
      _setLoadingState(facebook: false);
      _showError(
        'Facebook Sign-In Error',
        e.message ?? 'Authentication failed',
      );
    } catch (error) {
      debugPrint('Facebook sign-in error: $error');
      _setLoadingState(facebook: false);
      _showError('Facebook Sign-In Error', error.toString());
    }
  }

  Widget _signInPage(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FilledButton.icon(
          onPressed: _isGoogleSigningIn ? null : () => _googleSignIn(context),
          icon: const Icon(Icons.login),
          label: Text(S.current.signInWithGoogle),
          style: FilledButton.styleFrom(
            minimumSize: const Size(280, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_isGoogleSigningIn)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: FilledButton.icon(
            onPressed: _isAppleSigningIn ? null : () => _appleSignIn(context),
            icon: const Icon(Icons.apple),
            label: Text(S.current.signInWithApple),
            style: FilledButton.styleFrom(
              minimumSize: const Size(280, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (_isAppleSigningIn)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: FilledButton.icon(
            onPressed: _isFacebookSigningIn
                ? null
                : () => _facebookSignIn(context),
            icon: const Icon(Icons.facebook),
            label: Text(S.current.signInWithFacebook),
            style: FilledButton.styleFrom(
              minimumSize: const Size(280, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (_isFacebookSigningIn)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.signInPage),
        actions: const [
          // IconButton(icon: Icon(Icons.logout), onPressed: () => {}),
        ],
      ),
      body: Center(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    // On web, use authInstance set during initialization
    if (kIsWeb) {
      return authInstance == null
          ? const CircularProgressIndicator()
          : authInstance!.currentUser == null
          ? _signInPage(context)
          : _signedInWidget(context);
    }

    // On native, use stored authInstance
    return authInstance == null
        ? const CircularProgressIndicator()
        : authInstance!.currentUser == null
        ? _signInPage(context)
        : _signedInWidget(context);
  }

  Widget _signedInWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(const Size(150, 50)),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 20)),
          ),
          onPressed: () {
            Navigator.popAndPushNamed(context, MyRoutes.homePage);
          },
          icon: const Icon(Icons.book_rounded, size: 30),
          label: Text(S.current.myLogbook),
        ),
        SizedBox.fromSize(size: const Size(30, 30)),
        TextButton.icon(
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(const Size(150, 50)),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 20)),
          ),
          onPressed: () {
            signOut(context);
            setState(() {});
          },
          icon: const Icon(Icons.logout, size: 30),
          label: Text(S.current.signOut),
        ),
      ],
    );
  }

  /// signout the current user from both google and Firebase
  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) {
        // V6 API: Create instance and sign out
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
