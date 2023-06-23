import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
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

/// variable to store google-signin state
GoogleSignIn? googleSignIn;

class _SignInPageState extends State<SignInPage> {
  FirebaseAuth? authInstance;
  bool appleSignInAvailable = false;

  void _initFirebaseAuth() async {
    if (authInstance == null) {
      authInstance = FirebaseAuth.instance;
      // authInstance.authStateChanges().listen(
      //       (user) => mounted ? setState(() {}) : null,
      //       onDone: () => mounted ? setState(() {}) : null,
      //       // onError: () => setState(() {}),
      //       // cancelOnError: () => setState(() {}),
      //     );
      if (kIsWeb) await authInstance!.setPersistence(Persistence.SESSION);

      try {
        appleSignInAvailable = await SignInWithApple.isAvailable();
      } catch (e) {
        debugPrint(e.toString());
        appleSignInAvailable = false;
      }
    }
  }

  /// google sign-in scopes
  final scopes = <String>['email', 'profile'];

  @override
  void initState() {
    super.initState();
    _initFirebaseAuth();

    googleSignIn = GoogleSignIn(scopes: scopes);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// perform sign-in by google
  void _googleSignIn(BuildContext context) async {
    if (kIsWeb) {
      try {
        final provider = GoogleAuthProvider();
        for (var scope in scopes) {
          provider.addScope(scope);
        }
        await authInstance!.signInWithPopup(provider);
        setState(() {});
        // Navigator.popAndPushNamed(context, HomePageRoute);
      } catch (e) {
        debugPrint(e.toString());
      }

      return;
    }

    try {
      final account = await googleSignIn!.signIn();
      final googleAuth = await account!.authentication;
      final credentials = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await authInstance!.signInWithCredential(credentials);

      // final List<String> names = _user.user.displayName.split(' ');
      // addUsertoDB(
      //     email: _user.user.email,
      //     phoneNumber: _user.user.phoneNumber,
      //     firstName: names[0],
      //     lastName: names.length == 2 ? names[1] : " ");
      setState(() {});
      // Navigator.popAndPushNamed(context, HomePageRoute);
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Perform signin with apple ID
  void _appleSignIn() async {
    if (!appleSignInAvailable) {
      try {
        // Create and configure an OAuthProvider for Sign In with Apple.
        final provider = OAuthProvider("apple.com")
          ..addScope('email')
          ..addScope('name');

        // Sign in the user with Firebase.
        await FirebaseAuth.instance.signInWithPopup(provider);
        setState(() {});
      } catch (e) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
                  title: Text(S.of(context).errorWithAppleSignIn),
                  content: Text(e.toString()),
                ));
        Future.delayed(
            const Duration(seconds: 2), () => Navigator.pop(context));
      }
      return;
    }

    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // webAuthenticationOptions: WebAuthenticationOptions(
        //   clientId: 'com.vedalaholdings.astrologbook',
        //   redirectUri: Uri.parse(
        //       'https://astronomy-log-book.firebaseapp.com/__/auth/handler'),
        // ),
        nonce: nonce,
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // inspect(oauthCredential);

      await authInstance!.signInWithCredential(oauthCredential);

      if (appleCredential.givenName != null) {
        await FirebaseAuth.instance.currentUser!.updateDisplayName(
            "${appleCredential.givenName} ${appleCredential.familyName}");
      }

      setState(() {});
      // Navigator.popAndPushNamed(context, HomePageRoute);
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  /// signin with facebook
  void _facebookSignIn() async {
    try {
      if (kIsWeb) {
        // Create a new provider
        FacebookAuthProvider facebookProvider = FacebookAuthProvider();

        facebookProvider.addScope('email');
        facebookProvider.setCustomParameters({
          'display': 'popup',
        });

        // Once signed in, return the UserCredential
        await FirebaseAuth.instance.signInWithPopup(facebookProvider);
      } else {
        final accessToken = await FacebookAuth.instance
            .login(permissions: const ['email', 'public_profile']);

        // Create a credential from the access token
        final FacebookAuthCredential credential =
            FacebookAuthProvider.credential(
          accessToken.accessToken?.token ?? "",
        ) as FacebookAuthCredential;
        // Once signed in, return the UserCredential
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      // } on Facebo catch (e) {
      //   debugPrint(e.message);
      // handle the FacebookAuthException
    } on FirebaseAuthException catch (e) {
      // handle the FirebaseAuthException
      debugPrint(e.message);
    } finally {
      setState(() {});
    }
    return;
  }

  Widget _signInPage(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SignInButton(
          Buttons.Google,
          text: S.of(context).signInWithGoogle,
          onPressed: () => _googleSignIn(context),
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SignInButton(
            Buttons.Apple,
            text: S.of(context).signInWithApple,
            // shape: ShapeBorder,
            onPressed: _appleSignIn,
            padding: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SignInButton(
            Buttons.Facebook,
            text: S.of(context).signInWithFacebook,
            // shape: ShapeBorder,
            onPressed: _facebookSignIn,
            padding: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).signInPage),
        actions: const [
          // IconButton(icon: Icon(Icons.logout), onPressed: () => {}),
        ],
      ),
      body: Center(
          child: authInstance == null
              ? const CircularProgressIndicator()
              : authInstance!.currentUser == null
                  ? _signInPage(context)
                  : _signedIn(context)),
    );
  }

  Widget _signedIn(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          style: ButtonStyle(
            minimumSize: MaterialStateProperty.all(const Size(150, 50)),
            textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
          ),
          onPressed: () {
            Navigator.popAndPushNamed(context, MyRoutes.homePage);
          },
          icon: const Icon(
            Icons.book_rounded,
            size: 30,
          ),
          label: Text(S.of(context).myLogbook),
        ),
        SizedBox.fromSize(
          size: const Size(30, 30),
        ),
        TextButton.icon(
          style: ButtonStyle(
            minimumSize: MaterialStateProperty.all(const Size(150, 50)),
            textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 20)),
          ),
          onPressed: () {
            signOut(context);
            setState(() {});
          },
          icon: const Icon(
            Icons.logout,
            size: 30,
          ),
          label: Text(S.of(context).signOut),
        ),
      ],
    );
  }

  /// signout the current user from both google and Firebase
  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut().then((value) async {
      if (googleSignIn != null) {
        if (await googleSignIn!.isSignedIn()) await googleSignIn!.signOut();
      }
    }).then((value) {
      if (Navigator.canPop(context)) {
        setState(() {});
        // Navigator.popUntil(
        //   context,
        //   ModalRoute.withName(HomePageRoute),
        // );
      }
    });
  }
}
