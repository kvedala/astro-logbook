import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Main sign in page
class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();

  // static void signOut(BuildContext context) async {
  //   await FirebaseAuth.instance.signOut();

  // }
}

class _SignInPageState extends State<SignInPage> {
  bool isWebPlatform = false;
  FirebaseAuth authInstance;
  GoogleSignIn googleSignIn;

  void _initFirebaseAuth() async {
    if (authInstance == null) {
      authInstance = FirebaseAuth.instance;
      authInstance.authStateChanges().listen(
            (user) => setState(() {}),
            onDone: () => setState(() {}),
            // onError: () => setState(() {}),
            // cancelOnError: () => setState(() {}),
          );
      try {
        await authInstance.setPersistence(Persistence.SESSION);
        // setState(() {
        isWebPlatform = true;
        // });

      } on UnimplementedError catch (e) {
        print(e);
        return;
      }
    }
  }

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

  void _googleSignIn(BuildContext context) async {
    if (isWebPlatform) {
      try {
        final provider = GoogleAuthProvider();
        scopes.forEach((scope) => provider.addScope(scope));
        await authInstance.signInWithPopup(provider);
        setState(() {});
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Text("Logged In - User Profile"),
            ));
      } catch (e) {
        print(e);
      }

      return;
    }

    try {
      final account = await googleSignIn.signIn();
      final googleAuth = await account.authentication;
      final credentials = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await authInstance.signInWithCredential(credentials);

      // final List<String> names = _user.user.displayName.split(' ');
      // addUsertoDB(
      //     email: _user.user.email,
      //     phoneNumber: _user.user.phoneNumber,
      //     firstName: names[0],
      //     lastName: names.length == 2 ? names[1] : " ");
      setState(() {});
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Text("Signed In - Google Sign In"),
          ));
    } catch (error) {
      print(error);
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    final charset =
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

  void _appleSignIn() async {
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
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'ca.ahainc.health-login',
          redirectUri:
              Uri.parse('https://health-ocr.firebaseapp.com/__/auth/handler'),
        ),
        nonce: nonce,
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // inspect(oauthCredential);
      await authInstance.signInWithCredential(oauthCredential);

      setState(() {});
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Text("Signed In - Apple"),
          ));
    } catch (error) {
      print(error);
    }
  }

  Widget _signInPage(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SignInButton(
          Buttons.Google,
          text: 'Sign in with Google',
          onPressed: () => _googleSignIn(context),
          padding: EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        !isWebPlatform
            ? Padding(
                padding: EdgeInsets.only(top: 10),
                child: SignInButton(
                  Buttons.Apple,
                  text: 'Sign in with Apple',
                  // shape: ShapeBorder,
                  onPressed: _appleSignIn,
                  padding: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              )
            : SizedBox(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign In Page"),
        actions: [
          // IconButton(icon: Icon(Icons.logout), onPressed: () => {}),
        ],
      ),
      body: Center(
          child: authInstance == null
              ? CircularProgressIndicator()
              : authInstance.currentUser == null
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
            minimumSize: MaterialStateProperty.all(Size(150, 50)),
            textStyle: MaterialStateProperty.all(TextStyle(fontSize: 20)),
          ),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Text("Signed In - Generic"),
              )),
          icon: Icon(
            Icons.person_pin,
            size: 30,
          ),
          label: Text("User Profile"),
        ),
        SizedBox.fromSize(
          size: Size(30, 30),
        ),
        TextButton.icon(
          style: ButtonStyle(
            minimumSize: MaterialStateProperty.all(Size(150, 50)),
            textStyle: MaterialStateProperty.all(TextStyle(fontSize: 20)),
          ),
          onPressed: () {
            signOut(context);
            setState(() {});
          },
          icon: Icon(
            Icons.logout,
            size: 30,
          ),
          label: Text("Sign Out"),
        ),
      ],
    );
  }

  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (googleSignIn != null) {
      if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();
    }
    if (Navigator.canPop(context)) {
      Navigator.popUntil(
        context,
        ModalRoute.withName(Navigator.defaultRouteName),
      );
    }
  }
}
