import 'package:flutter/material.dart';
import '../main.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/project_service.dart';

class KanbanScreen extends StatefulWidget {
  final Project project;

  const KanbanScreen({Key? key, required this.project}) : super(key: key);

  @override
  _KanbanScreenState createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<List<Task>> _tasksFuture;

  String _searchQuery = '';
  String _filterPriority = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasksFuture = _projectService.getTasks(widget.project.id);
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Low':
        return const Color(0xFF10B981);
      case 'Medium':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool _isOverdue(String? dueDateStr, String status) {
    if (dueDateStr == null || dueDateStr.isEmpty || status == 'Done') return false;
    try {
      final due = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return due.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleTaskDropped(Task task, String newStatus) async {
    if (task.status == newStatus) return;

    bool success = await _projectService.updateTaskStatus(task.id, newStatus);
    if (success) {
      _loadTasks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Görev güncellenirken hata oluştu.")),
      );
    }
  }

  void _showAddTaskDialog({String initialStatus = 'To Do'}) {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    String _selectedStatus = initialStatus;
    String _selectedPriority = 'Medium';
    String? _selectedDueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Yeni Görev Oluştur",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Görev Başlığı',
                          hintText: 'Örn: ALU Modülünü Yaz',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama',
                          hintText: 'Görev detaylarını buraya yazın...',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(labelText: 'Öncelik'),
                              items: ['Low', 'Medium', 'High']
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _selectedPriority = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(labelText: 'Durum'),
                              items: ['To Do', 'In Progress', 'Done']
                                  .map((status) => DropdownMenuItem(
                                      value: status, child: Text(status)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _selectedStatus = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _selectedDueDate = _formatDate(picked);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 18,
                                    color: Color(0xFF4F46E5),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedDueDate ??
                                        'Son Teslim Tarihi Seç (Opsiyonel)',
                                    style: const TextStyle(fontSize: 13.5),
                                  ),
                                ],
                              ),
                              if (_selectedDueDate != null)
                                GestureDetector(
                                  onTap: () =>
                                      setDialogState(() => _selectedDueDate = null),
                                  child: const Icon(Icons.clear,
                                      size: 18, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isNotEmpty) {
                      bool success = await _projectService.createTask(
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        status: _selectedStatus,
                        priority: _selectedPriority,
                        dueDate: _selectedDueDate,
                        projectId: widget.project.id,
                      );
                      Navigator.pop(context);
                      if (success) {
                        _loadTasks();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Görev panoya eklendi!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Görevi Ekle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTaskDialog(Task task) {
    final _titleController = TextEditingController(text: task.title);
    final _descController = TextEditingController(text: task.description);
    String _selectedStatus = task.status;
    String _selectedPriority = task.priority;
    String? _selectedDueDate =
        (task.dueDate != null && task.dueDate!.isNotEmpty) ? task.dueDate : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "TSK-${task.id}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Görevi Düzenle",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    tooltip: 'Görevi Sil',
                    onPressed: () async {
                      bool confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Görevi Sil"),
                              content: const Text(
                                  "Bu görevi panodan silmek istediğinize emin misiniz?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Vazgeç"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("Sil"),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (confirm) {
                        bool deleted = await _projectService.deleteTask(task.id);
                        Navigator.pop(context);
                        if (deleted) {
                          _loadTasks();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Görev silindi."),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration:
                            const InputDecoration(labelText: 'Görev Başlığı'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descController,
                        decoration:
                            const InputDecoration(labelText: 'Açıklama'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration:
                                  const InputDecoration(labelText: 'Öncelik'),
                              items: ['Low', 'Medium', 'High']
                                  .map((p) =>
                                      DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _selectedPriority = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration:
                                  const InputDecoration(labelText: 'Durum'),
                              items: ['To Do', 'In Progress', 'Done']
                                  .map((status) => DropdownMenuItem(
                                      value: status, child: Text(status)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _selectedStatus = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _selectedDueDate = _formatDate(picked);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 18,
                                    color: Color(0xFF4F46E5),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedDueDate ?? 'Son Teslim Tarihi Seç',
                                    style: const TextStyle(fontSize: 13.5),
                                  ),
                                ],
                              ),
                              if (_selectedDueDate != null)
                                GestureDetector(
                                  onTap: () =>
                                      setDialogState(() => _selectedDueDate = null),
                                  child: const Icon(Icons.clear,
                                      size: 18, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isNotEmpty) {
                      bool success = await _projectService.updateTask(
                        taskId: task.id,
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        status: _selectedStatus,
                        priority: _selectedPriority,
                        dueDate: _selectedDueDate,
                      );
                      Navigator.pop(context);
                      if (success) {
                        _loadTasks();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Görev güncellendi!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  tooltip: 'Projelere Dön',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  "Projelerim",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "/",
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "PRJ-${widget.project.id}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.project.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddTaskDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Yeni Görev",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Panoyu Yenile',
                  onPressed: _loadTasks,
                ),
                IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                  tooltip: isDark ? 'Aydınlık Mod' : 'Karanlık Mod',
                  onPressed: toggleTheme,
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final allTasks = snapshot.data ?? [];
          final totalCount = allTasks.length;
          final doneCount = allTasks.where((t) => t.status == 'Done').length;
          final progressPercent =
              totalCount > 0 ? (doneCount / totalCount) : 0.0;

          final filteredTasks = allTasks.where((t) {
            final matchesQuery = _searchQuery.isEmpty ||
                t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
            final matchesPriority =
                _filterPriority == 'All' || t.priority == _filterPriority;
            return matchesQuery && matchesPriority;
          }).toList();

          final todoTasks =
              filteredTasks.where((t) => t.status == 'To Do').toList();
          final inProgressTasks =
              filteredTasks.where((t) => t.status == 'In Progress').toList();
          final doneTasks =
              filteredTasks.where((t) => t.status == 'Done').toList();

          return Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withOpacity(0.6)
                      : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Görev başlığı veya içerik ara...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 12),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              ['All', 'High', 'Medium', 'Low'].map((priority) {
                            final isSelected = _filterPriority == priority;
                            final Color activeColor = priority == 'All'
                                ? const Color(0xFF4F46E5)
                                : _getPriorityColor(priority);

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  priority == 'All' ? 'Tümü' : priority,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[800]),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: activeColor,
                                showCheckmark: false,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _filterPriority = priority);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 210,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "İlerleme",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                "%${(progressPercent * 100).toInt()} ($doneCount/$totalCount)",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressPercent,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildKanbanColumn(
                          "To Do",
                          todoTasks,
                          const Color(0xFFF59E0B),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _buildKanbanColumn(
                          "In Progress",
                          inProgressTasks,
                          const Color(0xFF3B82F6),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _buildKanbanColumn(
                          "Done",
                          doneTasks,
                          const Color(0xFF10B981),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKanbanColumn(
    String title,
    List<Task> tasks,
    Color accentColor,
    bool isDark,
  ) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != title,
      onAcceptWithDetails: (details) {
        _handleTaskDropped(details.data, title);
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovered = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovered
                ? accentColor.withOpacity(0.08)
                : (isDark
                    ? const Color(0xFF1E293B).withOpacity(0.45)
                    : const Color(0xFFE2E8F0).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovered
                  ? accentColor
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1)),
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
                    border: Border(
                      top: BorderSide(color: accentColor, width: 3.5),
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.6,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: accentColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              '${tasks.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: Icon(Icons.add_rounded,
                            size: 20, color: accentColor),
                        tooltip: '$title sütununa görev ekle',
                        onPressed: () =>
                            _showAddTaskDialog(initialStatus: title),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          "Görev bulunmuyor",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Draggable<Task>(
                            data: task,
                            feedback: Material(
                              elevation: 10,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 290,
                                child: _buildTaskCard(task, isDark),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.25,
                              child: _buildTaskCard(task, isDark),
                            ),
                            child: _buildTaskCard(task, isDark),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task, bool isDark) {
    final priorityColor = _getPriorityColor(task.priority);
    final hasDueDate = task.dueDate != null && task.dueDate!.isNotEmpty;
    final overdue = _isOverdue(task.dueDate, task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showEditTaskDialog(task),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: priorityColor, width: 4.5),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TSK-${task.id}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    decoration: task.status == 'Done'
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.status == 'Done'
                        ? (isDark ? Colors.grey[500] : Colors.grey[500])
                        : null,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.priority,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: priorityColor,
                            ),
                          ),
                        ),
                        if (hasDueDate)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: overdue
                                  ? Colors.red.withOpacity(0.15)
                                  : (isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 11,
                                  color: overdue
                                      ? Colors.redAccent
                                      : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700]),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.dueDate!,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: overdue
                                        ? Colors.redAccent
                                        : (isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: const Color(0xFF4F46E5).withOpacity(0.15),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 13,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}