import 'dart:typed_data';

import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/service/base_firebase_service.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:epubx/epubx.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/src/logger.dart';

final fakeFirebaseServiceProvider = Provider<MockFirebaseService>((ref) {
  return MockFirebaseService(firebaseAuth: MockFirebaseAuth());
});

class MockFirebaseService implements FirebaseService {
  MockFirebaseService({required this.firebaseAuth});
  final FirebaseAuth firebaseAuth;

  @override
  Stream<User?> get authStateChange => firebaseAuth.authStateChanges();

  // Mock get list of books
  @override
  Future<Either<Failure, List<Book>>> getBooks() async {
    try {
      const List<Book> books = [
        // Book(title: 'Book 0', id: '0'),
        // Book(title: 'Book 1', id: '1'),
        // Book(title: 'Book 2', id: '2'),
      ];

      // Return our books to the caller in case they care
      // ignore: prefer_const_constructors
      return Right(books);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Refresh Books',
          e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Refresh Books'));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> signIn(
      {required String email, required String password}) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      // Return the data incase the caller needs it
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Login Unsuccessful', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Login'));
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<Either<Failure, UserCredential>> signUp(
      {required String email, required String password}) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Return the data incase the caller needs it
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(
          FirebaseFailure(e.message ?? 'Signup Not Successful', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not SignUp'));
    }
  }

  /// Get the current user
  @override
  User? get currentUser => firebaseAuth.currentUser;

  /// Send reset password email
  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Send Reset Email',
          e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Send Reset Email'));
    }
  }

  @override
  Future<bool> setDisplayName(String name) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      return false;
    }
    await user.updateDisplayName(name);
    return true;
  }

  @override
  Future<bool> setProfilePhoto(String photoURL) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      return false;
    }
    await user.updatePhotoURL(photoURL);
    return true;
  }

  @override
  Future<Either<Failure, BookCollection>> addCollection(String shelfName) {
    // TODO: implement addShelf
    throw UnimplementedError();
  }

  @override
  // TODO: implement userChanges
  Stream<User?> get userChanges => throw UnimplementedError();

  @override
  Future<Series> addSeries(String name,
      {required String imageUrl,
      String description = '',
      Set<String>? collectionIds}) {
    // TODO: implement addSeries
    throw UnimplementedError();
  }

  @override
  Future<void> addBookToSeries(
      {required String bookId,
      required String seriesId,
      required Set<String> collectionIds}) {
    // TODO: implement addBookToSeries
    throw UnimplementedError();
  }

  @override
  Future<void> removeSeries(String seriesId) {
    // TODO: implement removeSeries
    throw UnimplementedError();
  }

  @override
  Future<void> setBookCollections(
      {required String bookId, required Set<String> collectionIds}) {
    // TODO: implement addBookToCollections
    throw UnimplementedError();
  }

  @override
  Future<void> setSeriesCollections(
      {required String seriesId, required Set<String> collectionIds}) {
    // TODO: implement setSeriesCollections
    throw UnimplementedError();
  }

  @override
  // TODO: implement booksStream
  Stream<QuerySnapshot<Book>> get booksStream => throw UnimplementedError();

  @override
  // TODO: implement collectionsStream
  Stream<QuerySnapshot<BookCollection>> get collectionsStream =>
      throw UnimplementedError();

  @override
  // TODO: implement seriesStream
  Stream<QuerySnapshot<Series>> get seriesStream => throw UnimplementedError();


  @override
  Future<bool> fileExists(String firebaseFilePath) {
    // TODO: implement fileExists
    throw UnimplementedError();
  }

  @override
  DownloadTask downloadFile({required String firebaseFilePath, required String downloadToLocation}) {
    // TODO: implement downloadFile
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Book>> addBookToFirestore({required Book book}) {
    // TODO: implement addBookToFirestore
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> uploadBookToFirebaseStorage({required String firebaseFilePath, required String localFilePath}) {
    // TODO: implement uploadBookToFirebaseStorage
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> uploadBytes({required String contentType, required String firebaseFilePath, required Uint8List bytes}) {
    // TODO: implement uploadBytes
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> uploadCoverPhoto({required EpubBookRef openedBook, required String uploadToPath}) {
    // TODO: implement uploadCoverPhoto
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> uploadFile({required String contentType, required String firebaseFilePath, required String localFilePath}) {
    // TODO: implement uploadFile
    throw UnimplementedError();
  }

  @override
  // TODO: implement log
  Logger get log => throw UnimplementedError();
}
