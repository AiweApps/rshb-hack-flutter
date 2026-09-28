import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String _scansDirectoryName = 'scans';
const String _photoExtension = '.jpg';

/// Where the photos of the scan history live: the app's support directory,
/// out of the gallery and removed with the app.
///
/// The store deals in file names, never absolute paths: on iOS the app's
/// container moves on every update, so a stored absolute path stops pointing
/// at the file. The database keeps the name from [keep]; [pathFor] turns it
/// back into a path at read time.
class ScanPhotoStore {
  Directory? _directory;

  /// Moves the picked photo (a file in the picker's cache) into the store
  /// under [id] and returns the file name to keep.
  Future<String> keep(String sourcePath, {required String id}) async {
    final directory = await _scansDirectory();
    final String name = '$id$_photoExtension';
    final String target = p.join(directory.path, name);
    final source = File(sourcePath);
    try {
      await source.rename(target);
    } on FileSystemException {
      // rename() cannot cross file systems (iOS keeps the picker cache on
      // another volume); a copy does the same job.
      await source.copy(target);
      await source.delete();
    }
    return name;
  }

  Future<String> pathFor(String name) async {
    final directory = await _scansDirectory();
    return p.join(directory.path, name);
  }

  Future<void> delete(String name) async {
    final file = File(await pathFor(name));
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteAll() async {
    final directory = await _scansDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    _directory = null;
  }

  Future<Directory> _scansDirectory() async {
    final cached = _directory;
    if (cached != null && await cached.exists()) return cached;
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, _scansDirectoryName));
    await directory.create(recursive: true);
    return _directory = directory;
  }
}
