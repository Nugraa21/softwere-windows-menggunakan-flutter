// lib/pages/rekap_hari_ini_page.dart (VERSI FINAL + KALENDER TANGGAL)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class RekapHariIniPage extends StatefulWidget {
  const RekapHariIniPage({super.key});

  @override
  State<RekapHariIniPage> createState() => _RekapHariIniPageState();
}

class _RekapHariIniPageState extends State<RekapHariIniPage> {
  bool _loading = true;

  DateTime _selectedDate = DateTime.now(); // Tanggal yang sedang ditampilkan

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
      final selectedDay = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final todayData = allPresensi.where((p) {
        final created = (p['created_at'] ?? '').toString();
        return created.length >= 10 && created.substring(0, 10) == selectedDay;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF3B82F6)),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadStats();
    }
  }

  String _getBgColorHex(String status) {
    switch (status) {
      case 'Disetujui':
        return 'FFDCFCE7'; // Hijau muda
      case 'Ditolak':
        return 'FFFEE2E2'; // Merah muda
      default:
        return 'FFFFFBEB'; // Orange muda
    }
  }

  xls.ExcelColor _getExcelBgColor(String status) {
    return xls.ExcelColor.fromHexString('#${_getBgColorHex(status)}');
  }

  xls.ExcelColor _getExcelHeaderColor() =>
      xls.ExcelColor.fromHexString('#FF3B82F6'); // Biru header

  xls.ExcelColor _getExcelFontColor() =>
      xls.ExcelColor.fromHexString('#FFFFFFFF'); // Putih teks

  Future<void> _exportToExcel() async {
    if (_presensiToday.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data presensi untuk tanggal ini!'),
        ),
      );
      return;
    }

    Directory? dir;
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin penyimpanan ditolak')),
        );
        return;
      }
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate);
    final fileName = 'Rekap_Presensi_$dateStr.xlsx';
    final path = '${dir.path}/$fileName';

    var excel = xls.Excel.createExcel();
    excel.delete('Sheet1');
    xls.Sheet sheet = excel['Rekap Tanggal Ini'];

    // Header
    sheet.appendRow([
      xls.TextCellValue('No'),
      xls.TextCellValue('Nama Lengkap'),
      xls.TextCellValue('Username'),
      xls.TextCellValue('Jenis Absen'),
      xls.TextCellValue('Status'),
      xls.TextCellValue('Waktu'),
      xls.TextCellValue('Keterangan'),
    ]);

    // Styling header
    for (int i = 0; i < 7; i++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = xls.CellStyle(
        bold: true,
        backgroundColorHex: _getExcelHeaderColor(),
        fontColorHex: _getExcelFontColor(),
        horizontalAlign: xls.HorizontalAlign.Center,
      );
    }

    // Data
    int no = 1;
    for (var p in _presensiToday) {
      final nama = p['nama_lengkap'] ?? '-';
      final username = p['username'] ?? '-';
      final jenis = p['jenis'] ?? '-';
      final status = p['status'] ?? 'Waiting';
      final waktu = p['created_at']?.toString().substring(11, 19) ?? '-';
      final keterangan = status != 'Disetujui'
          ? 'Tidak Disetujui'
          : (p['keterangan'] ?? '-');

      sheet.appendRow([
        xls.TextCellValue(no.toString()),
        xls.TextCellValue(nama),
        xls.TextCellValue(username),
        xls.TextCellValue(jenis),
        xls.TextCellValue(status),
        xls.TextCellValue(waktu),
        xls.TextCellValue(keterangan),
      ]);

      // Styling baris berdasarkan status
      for (int i = 0; i < 7; i++) {
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: no),
        );
        cell.cellStyle = xls.CellStyle(
          backgroundColorHex: _getExcelBgColor(status),
        );
      }

      no++;
    }

    await File(path).writeAsBytes(excel.encode()!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil diexport: $fileName'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'BUKA',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(path),
          ),
        ),
      );
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
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
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
                      p['created_at']?.toString().substring(11, 19) ?? '-';

                  Color statusColor = status == 'Disetujui'
                      ? Colors.green
                      : status == 'Ditolak'
                      ? Colors.red
                      : Colors.orange;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 8,
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
                          Text(
                            'Username: $username',
                            style: TextStyle(fontSize: 15),
                          ),
                          Text('Jenis: $jenis', style: TextStyle(fontSize: 15)),
                          Text(
                            'Status: $status',
                            style: TextStyle(
                              fontSize: 15,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text('Waktu: $waktu', style: TextStyle(fontSize: 15)),
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
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: Offset(0, 15),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
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
    final selectedDayStr = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar Kiri
          Container(
            width: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: const Icon(
                          Icons.today_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekap Presensi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Harian',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tanggal',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selectedDayStr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Total User',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        Text(
                          '$_totalUsers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  decoration: const BoxDecoration(
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
                        icon: const Icon(Icons.arrow_back_rounded, size: 36),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.all(20),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Text(
                        'Rekap Presensi Harian - $selectedDayStr',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: const Text('Pilih Tanggal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B82F6),
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B82F6),
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _exportToExcel,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Export Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : _presensiToday.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 140,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 40),
                              Text(
                                'Belum ada presensi pada tanggal ini',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Tunggu karyawan melakukan absen atau pilih tanggal lain',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(48),
                          child: GridView.count(
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
                                      .where(
                                        (p) => p['jenis'] == 'Penugasan_Masuk',
                                      )
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
                                      .where(
                                        (p) => p['jenis'] == 'Penugasan_Pulang',
                                      )
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
                                      .where(
                                        (p) => p['jenis'] == 'Penugasan_Full',
                                      )
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
                                'Ditolak',
                                '$_ditolak',
                                Icons.cancel_rounded,
                                Color(0xFFEF4444),
                                onTap: () => _showDetail(
                                  'Ditolak',
                                  _presensiToday
                                      .where((p) => p['status'] == 'Ditolak')
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
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
