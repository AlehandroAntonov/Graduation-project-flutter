import 'package:flutter/material.dart';
import 'package:src/models/requests.dart';
import 'package:src/models/users.dart';
import 'package:src/services/request_service.dart';

class AssignRequestScreen extends StatefulWidget {
  final Requests request;
  const AssignRequestScreen({super.key, required this.request});

  @override
  State<StatefulWidget> createState() => _AssignRequestState();
}

class _AssignRequestState extends State<AssignRequestScreen> {
  List<Users> staffList = [];
  String? selectedStaffId;
  String currentStaffName = '';
  bool _isLoading = false;

  // Для смены приоритета
  late Priority _selectedPriority;
  bool _isChangingPriority = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем текущим приоритетом
    _selectedPriority = widget.request.priority;
    _loadStaffList();
    _loadCurrentStaff();
  }

  Future<void> _loadStaffList() async {
    try {
      List<Users> staff = await RequestService().getStaffList();
      if (mounted) {
        setState(() {
          staffList = staff;
        });
      }
    } catch (e) {
      print("Error loading staff list: $e");
    }
  }

  Future<void> _loadCurrentStaff() async {
    if (widget.request.staffId != null && widget.request.staffId!.isNotEmpty) {
      try {
        String name = await RequestService().getUsernameById(
          widget.request.staffId!,
        );
        if (mounted) {
          setState(() {
            currentStaffName = name;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            currentStaffName = 'Неизвестно';
          });
        }
      }
    } else {
      setState(() {
        currentStaffName = 'Не назначено';
      });
    }
  }

  Future<void> _changePriority() async {
    if (_selectedPriority == widget.request.priority) {
      return;
    }

    setState(() {
      _isChangingPriority = true;
    });

    try {
      await RequestService().updateRequestPriority(
        widget.request.id!,
        _selectedPriority,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("✅ Приоритет изменён на ${_selectedPriority.ruName}"),
          ),
        );
        // Обновляем объект запроса
        widget.request.priority = _selectedPriority;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Ошибка изменения приоритета: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPriority = false;
        });
      }
    }
  }

  Future<void> _assignStaff() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String staffId = selectedStaffId ?? '';
      String newStatus = staffId.isNotEmpty ? 'in_progress' : 'newly_created';

      await RequestService().updateRequestStaff(
        widget.request.id!,
        staffId,
        newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("✅ Сотрудник успешно назначен"),
          ),
        );
        await _loadCurrentStaff();
        Navigator.pop(context, true);
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

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Управление заявкой"),
        backgroundColor: Colors.blue[400],
        actions: [
          if (_selectedPriority != widget.request.priority)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _isChangingPriority
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : ElevatedButton(
                  onPressed: _changePriority,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Сохранить"),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о заявке
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Информация о заявке",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: "Заявитель",
                      value: widget.request.username ?? 'Неизвестно',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.description,
                      label: "Описание",
                      value: widget.request.content,
                      isLongText: true,
                    ),
                    const SizedBox(height: 12),

                    // Изменяемый приоритет
                    _buildPrioritySelector(),

                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.assessment,
                      label: "Статус",
                      value: widget.request.status.ruNameWithEmoji,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: "Дата создания",
                      value: _formatDate(widget.request.submissionTime),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.assignment_ind,
                      label: "Назначена на",
                      value: currentStaffName,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Выбор сотрудника
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Назначение сотрудника",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStaffId,
                      decoration: const InputDecoration(
                        labelText: "Сотрудник поддержки",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("-- Не назначено --"),
                        ),
                        ...staffList.map((staff) {
                          return DropdownMenuItem(
                            value: staff.userId,
                            child: Text(staff.username),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStaffId = value;
                        });
                      },
                      hint: const Text("Выберите сотрудника"),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _assignStaff,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          _isLoading ? "Назначение..." : "Назначить сотрудника",
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    // Цвета для опций приоритета
    Color getPriorityColor(Priority priority) {
      switch (priority) {
        case Priority.low:
          return Colors.green;
        case Priority.medium:
          return Colors.orange;
        case Priority.high:
          return Colors.red;
      }
    }

    IconData getPriorityIcon(Priority priority) {
      switch (priority) {
        case Priority.low:
          return Icons.trending_down;
        case Priority.medium:
          return Icons.trending_flat;
        case Priority.high:
          return Icons.trending_up;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, size: 20, color: Colors.blue[600]),
              const SizedBox(width: 12),
              const Text(
                "Приоритет",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: Priority.values.map((priority) {
              bool isSelected = _selectedPriority == priority;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getPriorityIcon(priority),
                      size: 18,
                      color: isSelected ? Colors.white : getPriorityColor(priority),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      priority.ruName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : getPriorityColor(priority),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPriority = priority;
                    });
                  }
                },
                selectedColor: getPriorityColor(priority),
                backgroundColor: getPriorityColor(priority).withOpacity(0.1),
                side: BorderSide(
                  color: getPriorityColor(priority).withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
          if (_selectedPriority != widget.request.priority)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Приоритет изменён. Нажмите «Сохранить» в верхнем меню.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLongText = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isLongText ? 14 : 16,
                  fontWeight: isLongText ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}