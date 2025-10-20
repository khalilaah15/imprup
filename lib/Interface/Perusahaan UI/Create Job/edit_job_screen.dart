import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EditJobPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const EditJobPage({super.key, required this.job});

  @override
  State<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetMinController;
  late TextEditingController _budgetMaxController;
  late TextEditingController _categoryController;
  late TextEditingController _skillController;

  DateTime? _deadline;
  String? _status;
  List<String> _skills = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final job = widget.job;

    _titleController = TextEditingController(text: job['title']);
    _descriptionController = TextEditingController(
      text: job['job_description'] ?? job['description'],
    );
    _budgetMinController = TextEditingController(
      text: job['budget_min']?.toString() ?? '',
    );
    _budgetMaxController = TextEditingController(
      text: job['budget_max']?.toString() ?? '',
    );
    _categoryController = TextEditingController(text: job['category'] ?? '');
    _skillController = TextEditingController();

    _deadline =
        job['deadline'] != null
            ? DateTime.tryParse(job['deadline'].toString())
            : null;

    // Handle skills array
    if (job['skills'] != null && job['skills'] is List) {
      _skills = List<String>.from(job['skills']);
    }

    // Normalize status
    final dbStatus = job['status'] ?? 'Sedang Dibuka';
    if (dbStatus == 'Open') {
      _status = 'Sedang Dibuka';
    } else if (dbStatus == 'Closed') {
      _status = 'Sudah Ditutup';
    } else {
      _status = dbStatus;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _categoryController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate budget
    final budgetMin = double.tryParse(_budgetMinController.text);
    final budgetMax = double.tryParse(_budgetMaxController.text);

    if (budgetMin != null && budgetMax != null && budgetMin > budgetMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Budget minimum tidak boleh lebih besar dari budget maksimum',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap pilih tenggat waktu'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase
          .from('projects')
          .update({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'budget_min': budgetMin,
            'budget_max': budgetMax,
            'category':
                _categoryController.text.trim().isNotEmpty
                    ? _categoryController.text.trim()
                    : null,
            'skills': _skills.isEmpty ? null : _skills,
            'deadline': _deadline!.toIso8601String(),
            'status': _status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.job['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lowongan berhasil diperbarui!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui lowongan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Edit Lowongan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              _buildSectionCard(
                title: 'Informasi Dasar',
                icon: Icons.info_outline,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Judul Pekerjaan',
                    hint: 'Contoh: Frontend Developer',
                    icon: Icons.work_outline,
                    validator:
                        (val) =>
                            val?.trim().isEmpty ?? true
                                ? 'Judul tidak boleh kosong'
                                : null,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _categoryController,
                    label: 'Kategori',
                    hint: 'Contoh: Web Development',
                    icon: Icons.category_outlined,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Deskripsi Pekerjaan',
                    hint: 'Jelaskan detail pekerjaan yang dibutuhkan',
                    icon: Icons.description_outlined,
                    maxLines: 6,
                    validator:
                        (val) =>
                            val?.trim().isEmpty ?? true
                                ? 'Deskripsi tidak boleh kosong'
                                : null,
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Budget Section
              _buildSectionCard(
                title: 'Budget',
                icon: Icons.account_balance_wallet_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _budgetMinController,
                          label: 'Budget Minimum',
                          hint: '1000000',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefix: Text(
                            'Rp ',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTextField(
                          controller: _budgetMaxController,
                          label: 'Budget Maksimum',
                          hint: '5000000',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefix: Text(
                            'Rp ',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_budgetMinController.text.isNotEmpty ||
                      _budgetMaxController.text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        _formatBudgetPreview(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 20.h),

              // Skills Section
              _buildSectionCard(
                title: 'Keterampilan yang Dibutuhkan',
                icon: Icons.stars_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillController,
                          decoration: InputDecoration(
                            hintText: 'Contoh: React, Flutter, UI/UX',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade400,
                            ),
                            prefixIcon: Icon(
                              Icons.add_circle_outline,
                              color: const Color(0xFF1565C0),
                              size: 20.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF1565C0),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                          ),
                          onSubmitted: (_) => _addSkill(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: _addSkill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        child: const Text(
                          'Tambah',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (_skills.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          _skills.map((skill) {
                            return Chip(
                              label: Text(skill),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _removeSkill(skill),
                              backgroundColor: const Color(
                                0xFF1565C0,
                              ).withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: const Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                              deleteIconColor: const Color(0xFF1565C0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                                side: BorderSide(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.3),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ] else
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: Text(
                        'Belum ada keterampilan ditambahkan',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 20.h),

              // Deadline & Status Section
              _buildSectionCard(
                title: 'Tenggat Waktu & Status',
                icon: Icons.schedule_outlined,
                children: [
                  // Deadline Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _deadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF1565C0),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _deadline = picked);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12.r),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: const Color(0xFF1565C0),
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tenggat Waktu',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _deadline != null
                                      ? DateFormat(
                                        'dd MMMM yyyy',
                                        'id_ID',
                                      ).format(_deadline!)
                                      : 'Pilih tanggal deadline',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _deadline != null
                                            ? Colors.black87
                                            : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'Status Lowongan',
                      prefixIcon: Icon(
                        Icons.info_outline,
                        color: const Color(0xFF1565C0),
                        size: 20.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF1565C0),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Sedang Dibuka',
                        child: Text('Sedang Dibuka'),
                      ),
                      DropdownMenuItem(
                        value: 'Sudah Ditutup',
                        child: Text('Sudah Ditutup'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _status = val),
                  ),
                ],
              ),

              SizedBox(height: 30.h),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1565C0), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20.sp),
            prefix: prefix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ],
    );
  }

  String _formatBudgetPreview() {
    final min = double.tryParse(_budgetMinController.text);
    final max = double.tryParse(_budgetMaxController.text);

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (min != null && max != null) {
      return 'Preview: ${formatter.format(min)} - ${formatter.format(max)}';
    } else if (min != null) {
      return 'Preview: Mulai dari ${formatter.format(min)}';
    } else if (max != null) {
      return 'Preview: Hingga ${formatter.format(max)}';
    }

    return '';
  }
}
