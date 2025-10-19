import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({Key? key}) : super(key: key);

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _deadline;

  // Job details
  final _jobDescriptionController = TextEditingController();
  final List<TextEditingController> _tasksControllers = [];
  final List<TextEditingController> _qualificationsControllers = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _budgetController.dispose();
    _jobDescriptionController.dispose();
    for (var c in _tasksControllers) {
      c.dispose();
    }
    for (var c in _qualificationsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTaskField() {
    setState(() => _tasksControllers.add(TextEditingController()));
  }

  void _removeTaskField(int index) {
    setState(() => _tasksControllers.removeAt(index));
  }

  void _addQualificationField() {
    setState(() => _qualificationsControllers.add(TextEditingController()));
  }

  void _removeQualificationField(int index) {
    setState(() => _qualificationsControllers.removeAt(index));
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    try {
      await supabase.from('projects').insert({
        'company_id': user!.id,
        'title': _titleController.text,
        'description': _jobDescriptionController.text,
        'category': _categoryController.text,
        'budget': double.tryParse(_budgetController.text),
        'deadline': _deadline?.toIso8601String(),
        'job_description': _jobDescriptionController.text,
        'job_tasks': _tasksControllers.map((c) => c.text).toList(),
        'job_qualifications':
            _qualificationsControllers.map((c) => c.text).toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lowongan berhasil dibuat!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat lowongan: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDynamicFieldList({
    required String title,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1565C0),
            ),
          ),
          SizedBox(height: 8.h),
          ...List.generate(controllers.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controllers[index],
                      decoration: InputDecoration(
                        hintText: '${title.split(' ').last} ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                      ),
                      validator:
                          (v) => v!.isEmpty ? 'Isi poin ${index + 1}' : null,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () => onRemove(index),
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                  ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: Color(0xFF1565C0)),
              label: const Text(
                'Tambah',
                style: TextStyle(color: Color(0xFF1565C0)),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Lowongan Baru'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Basic Information =====
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Lowongan'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: 'Budget (Rp)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _deadline == null
                      ? 'Pilih Deadline'
                      : 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
              ),
              Divider(height: 30.h, thickness: 1),

              // ===== Job Description =====
              Text(
                'Deskripsi Pekerjaan',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1565C0),
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _jobDescriptionController,
                decoration: InputDecoration(
                  hintText: 'Tuliskan deskripsi pekerjaan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                maxLines: 4,
                validator:
                    (v) =>
                        v!.isEmpty ? 'Deskripsi pekerjaan wajib diisi' : null,
              ),

              // ===== Dynamic Lists =====
              _buildDynamicFieldList(
                title: 'Hal-hal yang perlu dilakukan',
                controllers: _tasksControllers,
                onAdd: _addTaskField,
                onRemove: _removeTaskField,
              ),
              _buildDynamicFieldList(
                title: 'Kualifikasi',
                controllers: _qualificationsControllers,
                onAdd: _addQualificationField,
                onRemove: _removeQualificationField,
              ),

              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitJob,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Menyimpan...' : 'Simpan Lowongan',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
