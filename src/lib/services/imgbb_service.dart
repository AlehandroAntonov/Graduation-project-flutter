import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ImgBBService {
  static const String _apiKey = '4e9c5c1bcee48519d42386e55f04fd10';

  final ImagePicker _picker = ImagePicker();

  // Выбор изображения из галереи
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        print("✅ Image picked from gallery: ${image.path}");
        return File(image.path);
      }
      return null;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // Выбор изображения с камеры
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (image != null) {
        print("✅ Image taken from camera: ${image.path}");
        return File(image.path);
      }
      return null;
    } catch (e) {
      print("Error taking photo: $e");
      return null;
    }
  }

  // Загрузка изображения на ImgBB через multipart/form-data
  Future<String?> uploadToImgBB(File image) async {
    try {
      print("📤 Starting upload...");

      // Проверяем, существует ли файл
      if (!await image.exists()) {
        print("❌ File does not exist: ${image.path}");
        return null;
      }

      // Получаем размер файла
      final fileSize = await image.length();
      print("📏 Image size: $fileSize bytes");

      if (fileSize == 0) {
        print("❌ Image file is empty");
        return null;
      }

      // Определяем MIME тип
      String mimeType = _getMimeType(image.path);
      print("📷 MIME type: $mimeType");

      // Создаем multipart запрос
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload'),
      );

      // Добавляем параметры
      request.fields['key'] = _apiKey;
      request.fields['expiration'] = '0'; // 0 = никогда не истекает

      // Добавляем файл
      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      // Отправляем запрос
      print("📡 Sending request to ImgBB...");
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("📡 Response status: ${response.statusCode}");
      print("📡 Response body: $responseBody");

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          String imageUrl = data['data']['url'];
          String displayUrl = data['data']['display_url'] ?? imageUrl;
          print("✅ Image uploaded successfully!");
          print("🔗 URL: $imageUrl");
          return imageUrl;
        } else {
          print("❌ Upload failed: ${data['error']['message']}");
          return null;
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error uploading to ImgBB: $e");
      return null;
    }
  }

  // Определение MIME типа файла
  String _getMimeType(String path) {
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (path.endsWith('.png')) {
      return 'image/png';
    } else if (path.endsWith('.gif')) {
      return 'image/gif';
    } else if (path.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg'; // по умолчанию
  }

  // Загрузка нескольких изображений
  Future<List<String>> uploadMultipleImages(List<File> images) async {
    List<String> urls = [];
    int successCount = 0;

    print("📸 Starting upload of ${images.length} images");

    for (int i = 0; i < images.length; i++) {
      print("📸 Uploading image ${i + 1}/${images.length}");
      String? url = await uploadToImgBB(images[i]);
      if (url != null) {
        urls.add(url);
        successCount++;
      }
      // Небольшая задержка между загрузками
      if (i < images.length - 1) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    print("✅ Uploaded $successCount of ${images.length} images");
    return urls;
  }
}