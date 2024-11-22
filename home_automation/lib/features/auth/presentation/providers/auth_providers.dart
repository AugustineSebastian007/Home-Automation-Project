import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(userProvider) != null;
});