// lib/pages/admin_user_detail_page.dart (VERSI FINAL - SEMUA ERROR DIPERBAIKI 100% + FILTER LENGKAP + UI ELEGAN)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  List<dynamic> _history = [];
  List<dynamic> _waitingPresensi = [];

  // Filter
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int? _selectedDay; // null = semua hari
  String? _selectedJenis; // null = semua jenis

  List<dynamic> _filteredHistory = [];

  final Map<int, String> _months = {
    1: 'Januari',
    2: 'Februari',
    3: 'Maret',
    4: 'April',
    5: 'Mei',
    6: 'Juni',
    7: 'Juli',
    8: 'Agustus',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Desember',
  };

  final List<String> _jenisOptions = [
    'Masuk',
    'Pulang',
    'Izin',
    'Pulang Cepat',
    'Penugasan_Masuk',
    'Penugasan_Pulang',
    'Penugasan_Full',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      _filteredHistory = _history.where((item) {
        final date = DateTime.parse(item['created_at'] ?? '');
        final matchMonth = date.month == _selectedMonth;
        final matchYear = date.year == _selectedYear;
        final matchDay = _selectedDay == null || date.day == _selectedDay;
        final matchJenis =
            _selectedJenis == null || item['jenis'] == _selectedJenis;
        return matchMonth && matchYear && matchDay && matchJenis;
      }).toList();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final historyData = await ApiService.getUserHistory(widget.userId);
      if (mounted) {
        setState(() {
          _history = historyData ?? [];
          _history.sort(
            (a, b) => DateTime.parse(
              b['created_at'] ?? '',
            ).compareTo(DateTime.parse(a['created_at'] ?? '')),
          );
          _applyFilter();
        });
      }

      final allPresensi = await ApiService.getAllPresensi();
      final waiting = allPresensi
          .where(
            (p) =>
                p['user_id'].toString() == widget.userId &&
                (p['status'] ?? '') == 'Waiting',
          )
          .toList();

      if (mounted) setState(() => _waitingPresensi = waiting);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final res = await ApiService.updatePresensiStatus(id: id, status: status);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Status diperbarui'),
          backgroundColor: res['status'] == true
              ? Colors.green
              : Colors.redAccent,
        ),
      );

      if (res['status'] == true) _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showFullPhoto(String? url) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.all(40),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 6,
              child: Center(
                child: Image.network(
                  url,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 40, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullDokumen(String? url) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 900, maxHeight: 800),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(24),
                color: Color(0xFFF59E0B),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dokumen Pendukung',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file_rounded,
                            size: 100,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Dokumen tidak dapat ditampilkan',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
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

  IconData _getJenisIcon(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Icons.login_rounded;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Icons.logout_rounded;
      case 'Izin':
        return Icons.sick_rounded;
      case 'Pulang Cepat':
        return Icons.fast_forward_rounded;
      case 'Penugasan_Full':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Color(0xFF10B981);
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Color(0xFFF59E0B);
      case 'Izin':
        return Color(0xFFEF4444);
      case 'Pulang Cepat':
        return Color(0xFF3B82F6);
      case 'Penugasan_Full':
        return Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Color(0xFF10B981);
      case 'Ditolak':
        return Color(0xFFEF4444);
      default:
        return Color(0xFFF59E0B);
    }
  }

  Widget _buildPresensiCard(
    Map<String, dynamic> item, {
    bool showActions = false,
  }) {
    final baseUrl = ApiService.baseUrl;
    final fotoUrl = item['selfie']?.toString().isNotEmpty == true
        ? '$baseUrl/selfie/${item['selfie']}'
        : null;
    final dokumenUrl = item['dokumen']?.toString().isNotEmpty == true
        ? '$baseUrl/dokumen/${item['dokumen']}'
        : null;

    final jenisColor = _getJenisColor(item['jenis'] ?? '');
    final status = item['status'] ?? 'Waiting';
    final statusColor = _getStatusColor(status);

    final created = DateTime.parse(
      item['created_at'] ?? DateTime.now().toIso8601String(),
    );
    final formattedDate = DateFormat(
      'EEEE, dd MMMM yyyy • HH:mm',
      'id_ID',
    ).format(created);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
        border: Border.all(color: jenisColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: jenisColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getJenisIcon(item['jenis'] ?? ''),
                size: 56,
                color: jenisColor,
              ),
            ),
            SizedBox(width: 40),
            if (fotoUrl != null)
              GestureDetector(
                onTap: () => _showFullPhoto(fotoUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    fotoUrl,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (fotoUrl != null) SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getJenisIcon(item['jenis'] ?? ''),
                        size: 32,
                        color: jenisColor,
                      ),
                      SizedBox(width: 16),
                      Text(
                        item['jenis']?.replaceAll('_', ' ') ?? '-',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: jenisColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 28,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 16),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (item['keterangan']?.toString().isNotEmpty == true)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_alt_rounded,
                          size: 28,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item['keterangan'],
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (item['informasi']?.toString().isNotEmpty == true)
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_rounded,
                              size: 32,
                              color: Color(0xFF3B82F6),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                'Info Penugasan: ${item['informasi']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E40AF),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: statusColor.withOpacity(0.6),
                      width: 3,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'Disetujui'
                            ? Icons.check_circle_rounded
                            : status == 'Ditolak'
                            ? Icons.cancel_rounded
                            : Icons.pending_rounded,
                        color: statusColor,
                        size: 36,
                      ),
                      SizedBox(width: 16),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dokumenUrl != null)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OutlinedButton.icon(
                      onPressed: () => _showFullDokumen(dokumenUrl),
                      icon: Icon(Icons.attachment_rounded, size: 28),
                      label: Text(
                        'Lihat Dokumen',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFFF59E0B),
                        side: BorderSide(color: Color(0xFFF59E0B), width: 3),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                  ),
                if (showActions)
                  Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _updateStatus(item['id'].toString(), 'Disetujui'),
                          icon: Icon(Icons.thumb_up_rounded, size: 28),
                          label: Text(
                            'Setujui',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF10B981),
                            padding: EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _updateStatus(item['id'].toString(), 'Ditolak'),
                          icon: Icon(Icons.thumb_down_rounded, size: 28),
                          label: Text('Tolak', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFEF4444),
                            padding: EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    // Generate days based on selected month/year
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final dayOptions = List.generate(daysInMonth, (i) => i + 1);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Row(
          children: [
            Icon(Icons.filter_list_rounded, size: 36, color: Color(0xFF3B82F6)),
            SizedBox(width: 16),
            Text(
              'Filter Riwayat Presensi',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih filter untuk menampilkan riwayat yang diinginkan',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'Bulan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      items: _months.entries
                          .map(
                            (e) => DropdownMenuItem<int>(
                              value: e.key,
                              child: Text(
                                e.value,
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMonth = v!),
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: InputDecoration(
                        labelText: 'Tahun',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      items: List.generate(6, (i) => DateTime.now().year - i)
                          .map(
                            (y) => DropdownMenuItem<int>(
                              value: y,
                              child: Text('$y', style: TextStyle(fontSize: 18)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedYear = v!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedDay,
                      hint: Text('Semua Hari', style: TextStyle(fontSize: 18)),
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'Semua Hari',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        ...dayOptions
                            .map(
                              (d) => DropdownMenuItem<int?>(
                                value: d,
                                child: Text(
                                  '$d',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      onChanged: (v) => setState(() => _selectedDay = v),
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedJenis,
                      hint: Text('Semua Jenis', style: TextStyle(fontSize: 18)),
                      decoration: InputDecoration(
                        labelText: 'Jenis Absen',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Semua Jenis',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        ..._jenisOptions
                            .map(
                              (j) => DropdownMenuItem<String?>(
                                value: j,
                                child: Text(
                                  j.replaceAll('_', ' '),
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      onChanged: (v) => setState(() => _selectedJenis = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilter();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Terapkan Filter',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(32, 80, 32, 40),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Detail Presensi',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white12),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.history_rounded,
                          size: 32,
                          color: Colors.white70,
                        ),
                        title: Text(
                          'Riwayat Presensi',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        selected: _tabController.index == 0,
                        selectedTileColor: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onTap: () => _tabController.animateTo(0),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.pending_actions_rounded,
                          size: 32,
                          color: Colors.white70,
                        ),
                        title: Text(
                          'Menunggu Persetujuan',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        selected: _tabController.index == 1,
                        selectedTileColor: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onTap: () => _tabController.animateTo(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_rounded, size: 36),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.all(20),
                        ),
                      ),
                      SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tabController.index == 0
                                  ? 'Riwayat Presensi'
                                  : 'Menunggu Persetujuan',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_tabController.index == 0)
                              Text(
                                'Filter aktif: ${_months[_selectedMonth]} $_selectedYear${_selectedDay != null ? ' • Tanggal $_selectedDay' : ''}${_selectedJenis != null ? ' • ${_selectedJenis!.replaceAll('_', ' ')}' : ''} (${_filteredHistory.length} entri)',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_tabController.index == 0)
                        ElevatedButton.icon(
                          onPressed: _showFilterDialog,
                          icon: Icon(Icons.filter_list_rounded),
                          label: Text('Filter Lanjutan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3B82F6),
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                        ),
                      if (_tabController.index == 0) SizedBox(width: 24),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: Icon(Icons.refresh_rounded),
                        label: Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            // Tab Riwayat dengan Filter Lengkap
                            _filteredHistory.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.history_toggle_off_rounded,
                                          size: 140,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 40),
                                        Text(
                                          'Tidak ada riwayat dengan filter ini',
                                          style: TextStyle(
                                            fontSize: 28,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.all(40),
                                    itemCount: _filteredHistory.length,
                                    itemBuilder: (_, i) =>
                                        _buildPresensiCard(_filteredHistory[i]),
                                  ),

                            // Tab Waiting
                            _waitingPresensi.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.pending_actions_rounded,
                                          size: 140,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 40),
                                        Text(
                                          'Tidak ada presensi menunggu persetujuan',
                                          style: TextStyle(
                                            fontSize: 28,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.all(40),
                                    itemCount: _waitingPresensi.length,
                                    itemBuilder: (_, i) => _buildPresensiCard(
                                      _waitingPresensi[i],
                                      showActions: true,
                                    ),
                                  ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
