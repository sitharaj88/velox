import 'dart:typed_data';

/// Represents a file to be uploaded as part of a multipart request.
///
/// ```dart
/// final file = VeloxMultipartFile(
///   field: 'avatar',
///   filename: 'photo.jpg',
///   bytes: imageBytes,
///   contentType: 'image/jpeg',
/// );
/// ```
class VeloxMultipartFile {
  /// Creates a [VeloxMultipartFile].
  ///
  /// [field] is the form field name. [filename] is the file name.
  /// [bytes] is the file content. [contentType] is the MIME type.
  VeloxMultipartFile({
    required this.field,
    required this.filename,
    required this.bytes,
    this.contentType = 'application/octet-stream',
  });

  /// The form field name.
  final String field;

  /// The file name.
  final String filename;

  /// The file content as bytes.
  final Uint8List bytes;

  /// The MIME type of the file.
  final String contentType;

  @override
  String toString() =>
      'VeloxMultipartFile($field: $filename, '
      '${bytes.length} bytes, $contentType)';
}
