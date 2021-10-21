import 'dart:typed_data';

import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:dartz/dartz.dart';
import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A utility class to handle all Firebase calls
abstract class BaseFirebaseService {
  BaseFirebaseService();

  // Authentication

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  Stream<User?> get authStateChange;

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// You should not use this getter to determine the users current state,
  /// instead use [authStateChanges], [idTokenChanges] or [userChanges] to
  /// subscribe to updates.
  User? get currentUser;

  /// Notifies about changes to any user updates.
  ///
  /// This is a superset of both [authStateChanges] and [idTokenChanges]. It
  /// provides events on all user changes, such as when credentials are linked,
  /// unlinked and when updates to the user profile are made. The purpose of
  /// this Stream is for listening to realtime updates to the user state
  /// (signed-in, signed-out, different user & token refresh) without
  /// manually having to call [reload] and then rehydrating changes to your
  /// application.
  Stream<User?> get userChanges;

  /// Attempts to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the stream [authStateChange]
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  ///
  /// Returns an [Either]
  ///
  /// Right [UserCredential] is returned if successful
  ///
  /// Left [Failure] maybe returned with the following error code:
  /// - **invalid-email**:
  ///  - Returned if the email address is not valid.
  /// - **user-disabled**:
  ///  - Returned if the user corresponding to the given email has been disabled.
  /// - **user-not-found**:
  ///  - Returned if there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Returned if the password is invalid for the given email, or the account
  ///    corresponding to the email does not have a password set.
  Future<Either<Failure, UserCredential>> signIn(
      {required String email, required String password});

  /// Tries to create a new user account with the given email address and
  /// password.
  ///
  /// Returns an [Either]
  ///
  /// Right [UserCredential] is returned if successful
  ///
  /// Left [Failure] maybe returned with the following error code:
  /// - **email-already-in-use**:
  ///  - Returned if there already exists an account with the given email address.
  /// - **invalid-email**:
  ///  - Returned if the email address is not valid.
  /// - **operation-not-allowed**:
  ///  - Returned if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  /// - **weak-password**:
  ///  - Returned if the password is not strong enough.
  Future<Either<Failure, UserCredential>> signUp(
      {required String email, required String password});

  /// Signs out the current user.
  ///
  /// If successful, it also update the stream [authStateChange]
  Future<void> signOut();

  /// Send reset password email
  Future<void> resetPassword(String email);

  /// Set display name
  ///
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  Future<bool> setDisplayName(String name);

  /// Set profile photo
  ///
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  Future<bool> setProfilePhoto(String photoURL);

  // Database

  /// Get a list of books from the user's database
  Future<Either<Failure, List<Book>>> getBooks();

  /// Add a book to Firebase Database
  Future<Either<Failure, Book>> addBookToFirestore(
      PlatformFile file, EpubBookRef openedBook,
      {String collection = 'Default'});

  /// Upload a book to Firebase Storage
  Future<Either<Failure, void>> uploadBookToFirebaseStorage(PlatformFile file,
      {required String title, required String authors});

  /// Upload a book cover photo to Firebase Storage
  Future<Either<Failure, void>> uploadCoverPhoto(
      {required PlatformFile file,
      required EpubBookRef openedBook,
      required String title,
      required String authors});

  /// Upload bytes to Firebase Storage
  Future<Either<Failure, String>> uploadBytes(
      {required String userId,
      required Uint8List bytes,
      required String filename,
      required String contentType,
      required String title,
      required String authors});

  /// Upload a file to Firebase Storage
  Future<void> uploadFile(
      {required String userId,
      required PlatformFile file,
      required String contentType,
      required String title,
      required String authors});

  /// Create a shelf
  Future<Either<Failure, BookCollection>> addCollection(String name);

  /// Create a series
  Future<Series> addSeries(String name,
      {required String imageUrl,
      String description = '',
      Set<String>? collectionIds});

  /// Add book to series
  Future<void> addBookToSeries(
      {required String bookId,
      required String seriesId,
      required Set<String> collectionIds});

  /// Add book to collections
  ///
  /// Takes a book and adds the series id to it
  Future<void> setBookCollections(
      {required String bookId, required Set<String> collectionIds});

  /// Add series to collections
  ///
  /// Takes a series and adds the series id to it
  ///
  /// Throws [AppException] if it fails.
  Future<void> setSeriesCollections(
      {required String seriesId, required Set<String> collectionIds});

  /// Download a file into memory
  Future<Uint8List?> downloadFile(String filename);
}
