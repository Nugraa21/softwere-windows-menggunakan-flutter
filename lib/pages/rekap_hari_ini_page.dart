// lib/pages/rekap_hari_ini_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class RekapHariIniPage extends StatefulWidget {
  const RekapHariIniPage({super.key});

  @override
  State<RekapHariIniPage> createState() => _RekapHariIniPageState();
}

class _RekapHariIniPageState extends State<RekapHariIniPage> {
  bool _loading = true;

  int _totalUsers = 0;
  int _masukBiasa = 0;
  int _masukPenugasan = 0;
  int _pulangBiasa = 0;
  int _pulangPenugasan = 0;
  int _penugasanFull = 0;
  int _izin = 0;
  int _pending = 0;
  int _ditolak = 0;

  List<dynamic> _presensiToday = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final allPresensi = await ApiService.getAllPresensi();
      final users = await ApiService.getUsers();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final todayData = allPresensi.where((p) {
        final created = (p['created_at'] ?? '').toString();
        return created.length >= 10 && created.substring(0, 10) == today;
      }).toList();

      _presensiToday = todayData;

      final masukBiasa = todayData.where((p) => p['jenis'] == 'Masuk').toList();
      final masukPenugasan = todayData
          .where((p) => p['jenis'] == 'Penugasan_Masuk')
          .toList();
      final pulangBiasa = todayData
          .where((p) => p['jenis'] == 'Pulang')
          .toList();
      final pulangPenugasan = todayData
          .where((p) => p['jenis'] == 'Penugasan_Pulang')
          .toList();
      final penugasanFull = todayData
          .where((p) => p['jenis'] == 'Penugasan_Full')
          .toList();
      final izinAll = todayData
          .where((p) => p['jenis'] == 'Izin' || p['jenis'] == 'Pulang Cepat')
          .toList();
      final pendingAll = todayData
          .where((p) => p['status'] == 'Waiting')
          .toList();
      final ditolakAll = todayData
          .where((p) => p['status'] == 'Ditolak')
          .toList();

      setState(() {
        _totalUsers = users.length;
        _masukBiasa = masukBiasa.length;
        _masukPenugasan = masukPenugasan.length;
        _pulangBiasa = pulangBiasa.length;
        _pulangPenugasan = pulangPenugasan.length;
        _penugasanFull = penugasanFull.length;
        _izin = izinAll.length;
        _pending = pendingAll.length;
        _ditolak = ditolakAll.length;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(String title, List<dynamic> list) {
    if (list.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak ada data untuk "$title"')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: Colors.white,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${list.length} presensi',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  final nama = p['nama_lengkap'] ?? 'Unknown';
                  final username = p['username'] ?? '-';
                  final jenis = p['jenis'] ?? '-';
                  final status = p['status'] ?? 'Waiting';
                  final waktu =
                      p['created_at']?.toString().substring(11, 19) ?? '';

                  Color statusColor = status == 'Disetujui'
                      ? Colors.green
                      : status == 'Ditolak'
                      ? Colors.red
                      : Colors.orange;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(20),
                      leading: CircleAvatar(
                        radius: 32,
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Text(
                          nama[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      title: Text(
                        nama,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username: $username'),
                          Text('Jenis: $jenis'),
                          Text(
                            'Status: $status',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text('Waktu: $waktu'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: Offset(0, 15),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1200;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Rekap Presensi Hari Ini'),
        centerTitle: true,
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(onPressed: _loadStats, icon: Icon(Icons.refresh_rounded)),
          SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Presensi Hari Ini - ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 40),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 4 : 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 32,
                    mainAxisSpacing: 32,
                    children: [
                      _buildStatCard(
                        'Total Users',
                        '$_totalUsers',
                        Icons.people_rounded,
                        Color(0xFF3B82F6),
                      ),
                      _buildStatCard(
                        'Masuk Biasa',
                        '$_masukBiasa',
                        Icons.login_rounded,
                        Color(0xFF10B981),
                        onTap: () => _showDetail(
                          'Absen Masuk Biasa',
                          _presensiToday
                              .where((p) => p['jenis'] == 'Masuk')
                              .toList(),
                        ),
                      ),
                      _buildStatCard(
                        'Masuk Penugasan',
                        '$_masukPenugasan',
                        Icons.assignment_ind_rounded,
                        Color(0xFF8B5CF6),
                        onTap: () => _showDetail(
                          'Masuk Penugasan',
                          _presensiToday
                              .where((p) => p['jenis'] == 'Penugasan_Masuk')
                              .toList(),
                        ),
                      ),
                      _buildStatCard(
                        'Pulang Biasa',
                        '$_pulangBiasa',
                        Icons.logout_rounded,
                        Color(0xFFF59E0B),
                        onTap: () => _showDetail(
                          'Pulang Biasa',
                          _presensiToday
                              .where((p) => p['jenis'] == 'Pulang')
                              .toList(),
                        ),
                      ),
                      _buildStatCard(
                        'Pulang Penugasan',
                        '$_pulangPenugasan',
                        Icons.assignment_return_rounded,
                        Color(0xFF6366F1),
                        onTap: () => _showDetail(
                          'Pulang Penugasan',
                          _presensiToday
                              .where((p) => p['jenis'] == 'Penugasan_Pulang')
                              .toList(),
                        ),
                      ),
                      _buildStatCard(
                        'Penugasan Full',
                        '$_penugasanFull',
                        Icons.assignment_turned_in_rounded,
                        Color(0xFF8B5CF6),
                        onTap: () => _showDetail(
                          'Penugasan Full',
                          _presensiToday
                              .where((p) => p['jenis'] == 'Penugasan_Full')
                              .toList(),
                        ),
                      ),
                      _buildStatCard(
                        'Izin / Tidak Hadir',
                        '$_izin',
                        Icons.sick_rounded,
                        Color(0xFFEF4444),
                        onTap: () => _showDetail(
                          'Izin / Tidak Hadir',
                          _presensiToday
                              .where(
                                (p) =>
                                    p['jenis'] == 'Izin' ||
                                    p['jenis'] == 'Pulang Cepat',
                              )
                              .toList(),
                        ),
                      ),
                      _buildStatCard(
                        'Menunggu Approval',
                        '$_pending',
                        Icons.pending_actions_rounded,
                        Color(0xFFF59E0B),
                        onTap: () => _showDetail(
                          'Menunggu Approval',
                          _presensiToday
                              .where((p) => p['status'] == 'Waiting')
                              .toList(),
                        ),
                      ),
                      _buildStatCard(
                        'Ditolak Hari Ini',
                        '$_ditolak',
                        Icons.cancel_rounded,
                        Color(0xFFEF4444),
                        onTap: () => _showDetail(
                          'Ditolak Hari Ini',
                          _presensiToday
                              .where((p) => p['status'] == 'Ditolak')
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
