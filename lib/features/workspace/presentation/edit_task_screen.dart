import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/task.dart';
import '../providers/workspace_detail_provider.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  final Task? task; // null for Create Mode, non-null for Edit Mode

  const EditTaskScreen({
    super.key,
    required this.workspaceId,
    this.task,
  });

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _selectedDate;
  String? _selectedAssigneeId;
  String _selectedStatus = 'todo';
  String _selectedPriority = 'medium';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.deadline;
    _selectedAssigneeId = widget.task?.assigneeId;
    _selectedStatus = widget.task?.status ?? 'todo';
    
    // Set priority based on mockup mappings
    if (widget.task != null) {
      final titleLower = widget.task!.title.toLowerCase();
      if (titleLower.contains('report') || titleLower.contains('laporan') || titleLower.contains('db') || titleLower.contains('database')) {
        _selectedPriority = 'high';
      } else if (titleLower.contains('ai') || titleLower.contains('presentation') || titleLower.contains('presentasi')) {
        _selectedPriority = 'medium';
      } else {
        _selectedPriority = 'low';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTask() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        if (widget.task == null) {
          // Create Mode
          final newTask = Task(
            id: '', // Supabase generates this
            workspaceId: widget.workspaceId,
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            deadline: _selectedDate,
            status: _selectedStatus,
            assigneeId: _selectedAssigneeId,
            createdAt: DateTime.now(),
          );
          await ref.read(tasksProvider(widget.workspaceId).notifier).createTask(newTask);
        } else {
          // Edit Mode
          final updatedTask = widget.task!.copyWith(
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            deadline: _selectedDate,
            status: _selectedStatus,
            assigneeId: _selectedAssigneeId,
          );
          await ref.read(tasksProvider(widget.workspaceId).notifier).updateTask(updatedTask);
        }

        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(widget.task == null ? 'Tugas berhasil dibuat!' : 'Tugas berhasil diperbarui!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan tugas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(workspaceMembersProvider(widget.workspaceId));
    final isEditMode = widget.task != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? 'Edit Task' : 'Create Task',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Task Title
                const Text(
                  'Task Title',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Complete Physics Lab Report',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Judul tugas tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Description
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Add detailed instructions or notes...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Due Date
                const Text(
                  'Due Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'mm/dd/yyyy'
                              : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedDate == null ? Colors.grey : AppColors.textDark,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.textLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Assignee
                const Text(
                  'Assignee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                membersState.when(
                  data: (members) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        fillColor: Color(0xFFF8FAFC),
                        filled: true,
                      ),
                      initialValue: _selectedAssigneeId,
                      hint: const Text('Select Assignee'),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: members.map((member) {
                        return DropdownMenuItem(
                          value: member.id,
                          child: Text(member.fullName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAssigneeId = val;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const Text('Gagal memuat anggota'),
                ),
                const SizedBox(height: 20),

                // 5. Status
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    fillColor: Color(0xFFF8FAFC),
                    filled: true,
                  ),
                  initialValue: _selectedStatus,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: const [
                    DropdownMenuItem(value: 'todo', child: Text('TODO')),
                    DropdownMenuItem(value: 'doing', child: Text('DOING')),
                    DropdownMenuItem(value: 'done', child: Text('DONE')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 6. Priority
                const Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildPrioritySegment('low', 'Low')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPrioritySegment('medium', 'Medium')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPrioritySegment('high', 'High')),
                  ],
                ),
                const SizedBox(height: 40),

                // 7. Save and Cancel Buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF3B82F6), // Vibrant blue
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveTask,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Save Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySegment(String priority, String label) {
    final isSelected = _selectedPriority == priority;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = priority;
        });
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
