import 'dart:async';
import 'dart:io' as io;

import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

final storageControllerProvider =
    Provider.autoDispose<StorageController>((ref) {
  return StorageController(ref.read);
});

class StorageController {
  StorageController(this._read);

  final Reader _read;
  final log = Logger();

  ValueListenable<Box<bool>> get downloadedBooksValueListenable =>
      _read(storageServiceProvider).downloadedBooksValueListenable;

  void downloadFile(
    Book book, {
    required FutureOr<void> Function(String) whenDone,
  }) {
    final appBookAdaptPath =
        _read(storageServiceProvider).appBookAdaptDirectory.path;
    final task = _read(firebaseControllerProvider)
        .downloadFile(book.filepath, '$appBookAdaptPath/${book.filepath}');
    // ignore: unawaited_futures
    task.whenComplete(() async {
      await _read(storageServiceProvider).setFileDownloaded(book.filename);
      await whenDone(book.filename);
    });
  }

  Future<void> setFileDownloaded(String filename) async {
    await _read(storageServiceProvider).setFileDownloaded(filename);
    _read(userModelProvider.notifier).addDownloadedFilename(filename);
  }

  Future<void> setFileNotDownloaded(String filename) async {
    await _read(storageServiceProvider).setFileNotDownloaded(filename);
    _read(userModelProvider.notifier).removeDownloadedFilename(filename);
  }

  List<String> updateDownloadedFiles() {
    _read(storageServiceProvider).clearDownloadedBooksCache();
    final downloadedFiles = getDownloadedFilenames();
    downloadedFiles.forEach(_read(storageServiceProvider).setFileDownloaded);
    return downloadedFiles;
  }

  /// Get the list of files on downloaded to the device
  ///
  /// Returns a list of string filenames
  List<String> getDownloadedFilenames() {
    final String? userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    try {
      final filesPaths =
          _read(storageServiceProvider).listFiles(userId: userId);
      return filesPaths.map((file) => file.path.split('/').last).toList();
    } on io.FileSystemException catch (e, st) {
      log.e(e.message, e, st);
      return [];
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      return [];
    }
  }

  /// Delete a library item permamently
  ///
  /// Arguments
  /// `items` - Items to be deleted
  Future<void> deleteItemsPermanently({
    required List<Item> itemsToDelete,
    required List<Book> allBooks,
  }) async {
    final String? userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }
    final deletedBooks =
        await _read(firebaseControllerProvider).deleteItemsPermanently(
      itemsToDelete: itemsToDelete,
      allBooks: allBooks,
    );
    await deleteFiles(deletedBooks.map((item) => item.filename).toList());
  }

  // Delete downloaded books files from device if they are removed from Firebase Storage
  Future<List<String>> deleteFiles(List<String> filenames) async {
    final String? userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }
    final deletedFilenames = <String>[];
    for (final filename in filenames) {
      final fullFilePath = _read(storageServiceProvider)
          .getPathFromFilename(userId: userId, filename: filename);
      final exists =
          await _read(storageServiceProvider).fileExists(fullFilePath);
      if (exists) {
        await io.File(fullFilePath).delete();
        deletedFilenames.add(filename);
        await setFileNotDownloaded(filename);
      }
    }
    return deletedFilenames;
  }

  Future<List<int>> getBookData(Book book) async {
    final bookPath =
        _read(storageServiceProvider).getAppFilePath(book.filepath);

    return await _read(storageServiceProvider).getFileInMemory(bookPath);
  }

  Future<bool?> isBookDownloaded(String filename) async {
    final isDownloaded =
        _read(storageServiceProvider).isBookDownloaded(filename);
    if (isDownloaded == null) {
      await _read(storageServiceProvider).setFileNotDownloaded(filename);
    }
    return isDownloaded ?? false;
  }
}
