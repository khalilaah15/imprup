import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/services/applications_service.dart';
import 'package:intl/intl.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage>
    with SingleTickerProviderStateMixin {
  final ApplicationsService _service = ApplicationsService();
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String _selectedFilter = 'Semua';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadApplications() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getMyApplications();
      setState(() {
        _applications = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApplications {
    if (_selectedFilter == 'Semua') return _applications;
    return _applications
        .where((app) => app['status'] == _selectedFilter)
        .toList();
  }

  int _getCountByStatus(String status) {
    if (status == 'Semua') return _applications.length;
    return _applications.where((app) => app['status'] == status).length;
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final parsed = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(parsed);

      if (diff.inDays == 0) {
        return 'Hari ini, ${DateFormat('HH:mm').format(parsed)}';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} hari lalu';
      } else {
        return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
      }
    } catch (e) {
      return '-';
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Diterima':
        return {
          'color': Colors.green[700]!,
          'bgColor': Colors.green[50]!,
          'icon': Icons.check_circle,
          'label': 'Diterima',
          'progress': 1.0,
        };
      case 'Ditolak':
        return {
          'color': Colors.red[700]!,
          'bgColor': Colors.red[50]!,
          'icon': Icons.cancel,
          'label': 'Ditolak',
          'progress': 1.0,
        };
      case 'Proses':
        return {
          'color': Colors.orange[700]!,
          'bgColor': Colors.orange[50]!,
          'icon': Icons.hourglass_empty,
          'label': 'Dalam Proses',
          'progress': 0.5,
        };
      default:
        return {
          'color': Colors.blue[700]!,
          'bgColor': Colors.blue[50]!,
          'icon': Icons.send,
          'label': 'Terkirim',
          'progress': 0.3,
        };
    }
  }

  void _showApplicationDetail(Map<String, dynamic> application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApplicationDetailSheet(
        application: application,
        onRefresh: loadApplications,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lamaran Saya',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_applications.isNotEmpty)
              Text(
                '${_applications.length} Lamaran Terkirim',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : _applications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: loadApplications,
                  color: const Color(0xFF1565C0),
                  child: Column(
                    children: [
                      _buildFilterTabs(),
                      _buildStatsOverview(),
                      Expanded(child: _buildApplicationsList()),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 100.sp,
              color: Colors.grey[300],
            ),
            SizedBox(height: 24.h),
            Text(
              'Belum Ada Lamaran',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Anda belum mengirim lamaran ke proyek manapun.\nMulai lamar proyek yang sesuai dengan keahlian Anda!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to projects list
                Navigator.pop(context);
              },
              icon: const Icon(Icons.search),
              label: const Text('Cari Proyek'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Semua', _getCountByStatus('Semua')),
            SizedBox(width: 8.w),
            _buildFilterChip('Proses', _getCountByStatus('Proses')),
            SizedBox(width: 8.w),
            _buildFilterChip('Diterima', _getCountByStatus('Diterima')),
            SizedBox(width: 8.w),
            _buildFilterChip('Ditolak', _getCountByStatus('Ditolak')),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final prosesCount = _getCountByStatus('Proses');
    final diterimaCount = _getCountByStatus('Diterima');
    final ditolakCount = _getCountByStatus('Ditolak');

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.hourglass_empty,
              prosesCount.toString(),
              'Proses',
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              Icons.check_circle,
              diterimaCount.toString(),
              'Diterima',
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              Icons.cancel,
              ditolakCount.toString(),
              'Ditolak',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28.sp),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsList() {
    final filtered = _filteredApplications;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off,
                size: 64.sp,
                color: Colors.grey[300],
              ),
              SizedBox(height: 16.h),
              Text(
                'Tidak ada lamaran dengan status "$_selectedFilter"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildApplicationCard(filtered[index]);
      },
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final project = application['projects'];
    final status = application['status'] ?? 'Proses';
    final statusInfo = _getStatusInfo(status);
    final hasMessage = application['message'] != null &&
        application['message'].toString().isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _showApplicationDetail(application),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project['title'] ?? 'Project',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (project['category'] != null) ...[
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                project['category'],
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF1565C0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        statusInfo['icon'],
                        size: 24.sp,
                        color: statusInfo['color'],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: ${statusInfo['label']}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: statusInfo['color'],
                          ),
                        ),
                        Text(
                          _formatDate(application['created_at']),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: LinearProgressIndicator(
                        value: statusInfo['progress'],
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          statusInfo['color'],
                        ),
                        minHeight: 6.h,
                      ),
                    ),
                  ],
                ),
                if (hasMessage) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.message,
                          size: 16.sp,
                          color: Colors.amber[900],
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Ada pesan dari perusahaan',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.amber[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12.sp,
                          color: Colors.amber[900],
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(Icons.business, size: 14.sp, color: Colors.grey[600]),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        project['company_name'] ?? 'Company',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showApplicationDetail(application),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
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

class _ApplicationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> application;
  final VoidCallback onRefresh;

  const _ApplicationDetailSheet({
    required this.application,
    required this.onRefresh,
  });

  String _formatBudget(num? min, num? max) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    if (min != null && max != null) {
      return '${formatter.format(min)} - ${formatter.format(max)}';
    }
    return 'Negosiasi';
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(parsed);
    } catch (e) {
      return '-';
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Diterima':
        return {
          'color': Colors.green[700]!,
          'bgColor': Colors.green[50]!,
          'icon': Icons.check_circle,
          'label': 'Diterima',
        };
      case 'Ditolak':
        return {
          'color': Colors.red[700]!,
          'bgColor': Colors.red[50]!,
          'icon': Icons.cancel,
          'label': 'Ditolak',
        };
      case 'Proses':
        return {
          'color': Colors.orange[700]!,
          'bgColor': Colors.orange[50]!,
          'icon': Icons.hourglass_empty,
          'label': 'Dalam Proses Review',
        };
      default:
        return {
          'color': Colors.blue[700]!,
          'bgColor': Colors.blue[50]!,
          'icon': Icons.send,
          'label': 'Terkirim',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = application['projects'];
    final status = application['status'] ?? 'Proses';
    final statusInfo = _getStatusInfo(status);
    final message = application['message'];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(24.w),
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Detail Lamaran',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Status Card
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: (statusInfo['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              statusInfo['icon'],
                              size: 32.sp,
                              color: statusInfo['color'],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Lamaran',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  statusInfo['label'],
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: statusInfo['color'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Project Info
                    _buildSectionTitle('Informasi Proyek'),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project['title'] ?? 'Project',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          if (project['category'] != null)
                            _buildInfoRow(
                              Icons.category,
                              'Kategori',
                              project['category'],
                            ),
                          SizedBox(height: 8.h),
                          _buildInfoRow(
                            Icons.account_balance_wallet,
                            'Budget',
                            _formatBudget(
                              project['budget_min'],
                              project['budget_max'],
                            ),
                          ),
                          if (project['deadline'] != null) ...[
                            SizedBox(height: 8.h),
                            _buildInfoRow(
                              Icons.event,
                              'Deadline',
                              DateFormat('dd MMMM yyyy', 'id_ID')
                                  .format(DateTime.parse(project['deadline'])),
                            ),
                          ],
                          if (project['description'] != null) ...[
                            SizedBox(height: 16.h),
                            Text(
                              'Deskripsi:',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              project['description'],
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Application Timeline
                    _buildSectionTitle('Timeline'),
                    SizedBox(height: 12.h),
                    _buildTimeline(application),
                    SizedBox(height: 24.h),

                    // Company Message
                    if (message != null && message.toString().isNotEmpty) ...[
                      _buildSectionTitle('Pesan dari Perusahaan'),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.message,
                                  size: 20.sp,
                                  color: const Color(0xFF1565C0),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Pesan',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],

                    // Action Buttons
                    if (status == 'Diterima') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to chat or project detail
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Hubungi Perusahaan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: Colors.grey[900],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.grey[600]),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(Map<String, dynamic> application) {
    final status = application['status'] ?? 'Proses';
    final createdAt = application['created_at'];
    final updatedAt = application['updated_at'];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _buildTimelineItem(
            Icons.send,
            'Lamaran Dikirim',
            _formatDate(createdAt),
            true,
            Colors.blue[700]!,
          ),
          _buildTimelineDivider(true),
          _buildTimelineItem(
            Icons.hourglass_empty,
            'Dalam Review',
            status == 'Proses' ? 'Sedang direview' : _formatDate(updatedAt),
            status != 'Proses',
            Colors.orange[700]!,
          ),
          _buildTimelineDivider(status == 'Diterima' || status == 'Ditolak'),
          _buildTimelineItem(
            status == 'Diterima' ? Icons.check_circle : Icons.cancel,
            status == 'Diterima'
                ? 'Lamaran Diterima'
                : status == 'Ditolak'
                    ? 'Lamaran Ditolak'
                    : 'Menunggu Keputusan',
            status == 'Diterima' || status == 'Ditolak'
                ? _formatDate(updatedAt)
                : 'Belum ada keputusan',
            status == 'Diterima' || status == 'Ditolak',
            status == 'Diterima'
                ? Colors.green[700]!
                : status == 'Ditolak'
                    ? Colors.red[700]!
                    : Colors.grey[400]!,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    IconData icon,
    String title,
    String subtitle,
    bool isCompleted,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isCompleted ? color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.grey[900] : Colors.grey[500],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isCompleted ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isCompleted) {
    return Container(
      margin: EdgeInsets.only(left: 19.w, top: 4.h, bottom: 4.h),
      width: 2.w,
      height: 32.h,
      color: isCompleted ? Colors.grey[400] : Colors.grey[300],
    );
  }
}