import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompanyJobDetailPage extends StatelessWidget {
  final Map<String, dynamic> job;

  const CompanyJobDetailPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> tasks = job['job_tasks'] ?? [];
    final List<dynamic> qualifications = job['job_qualifications'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          job['title'] ?? 'Detail Lowongan',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    job['category'] ?? 'Tanpa Kategori',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF42A5F5),
                ),
                Chip(
                  label: Text(
                    job['status'] ?? 'Open',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: job['status'] == 'Closed'
                      ? Colors.redAccent
                      : Colors.green,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Deskripsi Pekerjaan
            Text(
              'Deskripsi Pekerjaan',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              job['job_description'] ?? job['description'] ?? '-',
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),

            SizedBox(height: 24.h),

            // Hal-hal yang perlu dilakukan
            Text(
              'Hal-hal yang perlu dilakukan',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            tasks.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(tasks.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Text(
                          '${index + 1}. ${tasks[index]}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      );
                    }),
                  )
                : Text(
                    'Belum ada daftar tugas.',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
                  ),

            SizedBox(height: 24.h),

            // Kualifikasi
            Text(
              'Kualifikasi',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            qualifications.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(qualifications.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Text(
                          '${index + 1}. ${qualifications[index]}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      );
                    }),
                  )
                : Text(
                    'Belum ada kualifikasi khusus.',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
                  ),

            SizedBox(height: 24.h),

            // Informasi Tambahan
            Divider(thickness: 1.2, color: Colors.grey.shade300),
            SizedBox(height: 12.h),
            _buildInfoRow('Budget', job['budget'] != null ? 'Rp${job['budget']}' : '-'),
            _buildInfoRow(
                'Batas Waktu',
                job['deadline'] != null
                    ? job['deadline'].toString().split('T')[0]
                    : '-'),
            _buildInfoRow(
                'Dibuat pada',
                job['created_at'] != null
                    ? job['created_at'].toString().split('T')[0]
                    : '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
