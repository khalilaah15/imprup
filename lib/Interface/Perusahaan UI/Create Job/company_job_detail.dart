import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Create%20Job/edit_job_screen.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyJobDetailPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const CompanyJobDetailPage({super.key, required this.job});

  @override
  State<CompanyJobDetailPage> createState() => _CompanyJobDetailPageState();
}

class _CompanyJobDetailPageState extends State<CompanyJobDetailPage> {
  late Map<String, dynamic> job;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    job = Map<String, dynamic>.from(widget.job);
    _autoCloseIfDeadlinePassed();
  }

  Future<void> _autoCloseIfDeadlinePassed() async {
    if (job['deadline'] == null) return;

    final DateTime deadline = DateTime.parse(job['deadline'].toString());
    final DateTime now = DateTime.now();

    if (now.isAfter(deadline) && job['status'] != 'Sudah Ditutup') {
      await _updateJobStatus('Sudah Ditutup');
    }
  }

  Future<void> _updateJobStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    final supabase = Supabase.instance.client;

    try {
      await supabase
          .from('projects')
          .update({'status': newStatus})
          .eq('id', job['id']);

      setState(() {
        job['status'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status lowongan diubah menjadi "$newStatus"'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  String _formatBudget(dynamic budgetMin, dynamic budgetMax) {
    if (budgetMin == null && budgetMax == null) {
      return 'Tidak ditentukan';
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (budgetMin != null && budgetMax != null) {
      return '${formatter.format(budgetMin)} - ${formatter.format(budgetMax)}';
    } else if (budgetMin != null) {
      return 'Mulai dari ${formatter.format(budgetMin)}';
    } else {
      return 'Hingga ${formatter.format(budgetMax)}';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      final formatter = DateFormat('dd MMMM yyyy', 'id_ID');
      return formatter.format(dateTime);
    } catch (e) {
      return date.toString().split('T')[0];
    }
  }

  int _getDaysRemaining() {
    if (job['deadline'] == null) return 0;
    try {
      final DateTime deadline = DateTime.parse(job['deadline'].toString());
      final DateTime now = DateTime.now();
      return deadline.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> tasks = (job['job_tasks'] ?? []) is String
        ? [job['job_tasks']]
        : (job['job_tasks'] ?? []);

    final List<dynamic> qualifications =
        (job['job_qualifications'] ?? []) is String
            ? [job['job_qualifications']]
            : (job['job_qualifications'] ?? []);

    final status = (job['status'] ?? 'Sedang Dibuka').toString();
    final bool isClosed = status == 'Sudah Ditutup';
    final int daysRemaining = _getDaysRemaining();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Detail Lowongan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1565C0),
                    const Color(0xFF1976D2),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isClosed ? Colors.red.shade400 : Colors.green.shade400,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          status,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Job Title
                  Text(
                    job['title'] ?? 'Detail Lowongan',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Category
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: Colors.white70,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        job['category'] ?? 'Tanpa Kategori',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Info Cards
            Transform.translate(
              offset: Offset(0, -20.h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickInfoCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Gaji',
                        value: _formatBudget(job['budget_min'], job['budget_max']),
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildQuickInfoCard(
                        icon: Icons.schedule_outlined,
                        label: 'Deadline',
                        value: daysRemaining > 0
                            ? '$daysRemaining hari lagi'
                            : daysRemaining == 0
                                ? 'Hari ini'
                                : 'Lewat',
                        color: daysRemaining > 7
                            ? const Color(0xFF2196F3)
                            : daysRemaining >= 0
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Section
                  _buildSection(
                    title: 'Deskripsi Pekerjaan',
                    icon: Icons.description_outlined,
                    child: Text(
                      job['job_description'] ?? job['description'] ?? '-',
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Skills Section
                  _buildSection(
                    title: 'Keterampilan Dibutuhkan',
                    icon: Icons.stars_outlined,
                    child: job['skills'] != null && (job['skills'] as List).isNotEmpty
                        ? Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: (job['skills'] as List).map((skill) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: const Color(0xFF1565C0).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  skill.toString(),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF1565C0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : Text(
                            'Belum ada keterampilan spesifik.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                  ),

                  SizedBox(height: 20.h),

                  // Additional Info Section
                  _buildSection(
                    title: 'Informasi Tambahan',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        _buildInfoItem(
                          icon: Icons.attach_money,
                          label: 'Gaji',
                          value: _formatBudget(job['budget_min'], job['budget_max']),
                        ),
                        Divider(height: 20.h, color: Colors.grey.shade300),
                        _buildInfoItem(
                          icon: Icons.event,
                          label: 'Batas Waktu',
                          value: _formatDate(job['deadline']),
                        ),
                        Divider(height: 20.h, color: Colors.grey.shade300),
                        _buildInfoItem(
                          icon: Icons.calendar_today,
                          label: 'Dibuat pada',
                          value: _formatDate(job['created_at']),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Action Buttons
                  _buildActionButtons(isClosed),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
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
          child,
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.sp, color: Colors.grey.shade700),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isClosed) {
    return Column(
      children: [
        // Edit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditJobPage(job: job),
                ),
              );
              if (updated == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Data lowongan diperbarui'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: Text(
              'Edit Lowongan',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF1565C0),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Toggle Status Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUpdatingStatus
                ? null
                : () => _updateJobStatus(
                      isClosed ? 'Sedang Dibuka' : 'Sudah Ditutup',
                    ),
            icon: Icon(
              isClosed ? Icons.lock_open_outlined : Icons.lock_outline,
              color: isClosed ? Colors.green.shade600 : Colors.red.shade600,
              size: 20,
            ),
            label: Text(
              _isUpdatingStatus
                  ? 'Memproses...'
                  : isClosed
                      ? 'Buka Kembali Lowongan'
                      : 'Tutup Lowongan',
              style: TextStyle(
                color: isClosed ? Colors.green.shade600 : Colors.red.shade600,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isClosed ? Colors.green.shade600 : Colors.red.shade600,
                width: 2,
              ),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}