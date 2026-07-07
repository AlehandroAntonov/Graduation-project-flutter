import 'dart:io';
import 'package:flutter/material.dart';
import 'package:src/models/requests.dart';
import 'package:src/services/request_service.dart';
import 'package:src/services/imgbb_service.dart';

class AddRequestScreen extends StatefulWidget {
  const AddRequestScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AddRequestState();
}

class _AddRequestState extends State<AddRequestScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImgBBService _imgService = ImgBBService();
  final RequestService _requestService = RequestService();

  Priority _selectedPriority = Priority.low;
  bool _isLoading = false;
  List<File> _selectedImages = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool _validateInput() {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Опишите, что у Вас произошло")),
      );
      return false;
    }
    return true;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text("Выбрать из галереи"),
                onTap: () async {
                  Navigator.pop(context);
                  File? image = await _imgService.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text("Сделать фото"),
                onTap: () async {
                  Navigator.pop(context);
                  File? image = await _imgService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createRequest() async {
    if (!_validateInput()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String result = await _requestService.createRequests(
        _contentController.text,
        _selectedPriority,
      );

      if (result == "Requests created successfully") {
        List<Requests> userRequests = await _requestService.loadUserRequest();
        if (userRequests.isNotEmpty) {
          Requests latestRequest = userRequests.first;

          if (_selectedImages.isNotEmpty) {
            List<String> imageUrls = await _imgService.uploadMultipleImages(_selectedImages);
            if (imageUrls.isNotEmpty) {
              await _requestService.addImageUrlsToRequest(latestRequest.id!, imageUrls);
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text("Заявка успешно создана!"),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Ошибка: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Создание заявки"),
        backgroundColor: Colors.blue[400],
        actions: [
          if (_selectedImages.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                });
              },
              child: const Text(
                "Очистить",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Что у Вас произошло?",
                hintText: "Опишите проблему подробнее...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<Priority>(
              value: _selectedPriority,
              decoration: InputDecoration(
                labelText: "Приоритет",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: Priority.values.map((priority) {
                return DropdownMenuItem<Priority>(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(
                        priority == Priority.low
                            ? Icons.trending_down
                            : priority == Priority.medium
                            ? Icons.trending_flat
                            : Icons.trending_up,
                        color: priority == Priority.low
                            ? Colors.green
                            : priority == Priority.medium
                            ? Colors.orange
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        priority.ruName,
                        style: TextStyle(
                          fontSize: 16,
                          color: priority == Priority.low
                              ? Colors.green
                              : priority == Priority.medium
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text("Добавить фото"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                "Выбранные фото:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, size: 12, color: Colors.white),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Отправить заявку",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}