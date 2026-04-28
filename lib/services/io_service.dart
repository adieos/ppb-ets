import 'dart:io';
import 'package:minio/minio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class IOService {
  final minio = Minio(
    endPoint: dotenv.env['MINIO_HOST'] ?? 'localhost',
    port: int.tryParse(dotenv.env['MINIO_PORT'] ?? '9000') ?? 9000,
    accessKey: dotenv.env['MINIO_USER'] ?? 'GioccoviDodo',
    secretKey: dotenv.env['MINIO_PASS'] ?? 'superSecurePassword',
    useSSL: false,
  );

  final String bucketName = 'duitku';

  Future<String?> uploadImage(File image) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileData = await image.readAsBytes();

      await minio.putObject(bucketName, fileName, Stream.value(fileData));

      final url = await minio.presignedGetObject(bucketName, fileName);

      return url;
    } catch (e) {
      print("MinIO Error: $e");
      return null;
    }
  }
}
