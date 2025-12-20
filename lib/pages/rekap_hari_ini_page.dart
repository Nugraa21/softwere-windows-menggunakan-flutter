// lib/pages/rekap_hari_ini_page.dart (REKAP HARIAN + RANGE TANGGAL + TABEL LENGKAP)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import 'package:intl/intl.dart';

class RekapHariIniPage extends StatefulWidget {
  const RekapHariIniPage({super.key});

  @override
  State<RekapHariIniPage> createState() => _RekapHariIniPageState();
}

class _RekapHariIniPageState extends State<RekapHariIniPage> {
  bool _loading = true;

  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _allPresensi = [];
  List<dynamic> _users = [];

  // Data rekap per user
  List<Map<String, dynamic>> _rekapData = [];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final presensi = await ApiService.getAllPresensi();
      final users = await ApiService.getUsers();

      setState(() {
        _allPresensi = presensi;
        _users = users;
        _processRekap();
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

  void _processRekap() {
    if (_startDate == null || _endDate == null) return;

    final Map<String, Map<String, dynamic>> rekapMap = {};

    // Filter presensi dalam rentang tanggal
    final filteredPresensi = _allPresensi.where((p) {
      final dateStr = (p['created_at'] ?? '').toString();
      if (dateStr.length < 10) return false;
      final presensiDate = DateTime.tryParse(dateStr.substring(0, 10));
      return presensiDate != null &&
          presensiDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          presensiDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();

    // Kelompokkan per user
    for (var user in _users) {
      final userId = user['id'].toString();
      final nama = user['nama_lengkap'] ?? '-';
      final nip = user['nip_nisn'] ?? '';
      final username = user['username'] ?? '-';

      final userPresensi = filteredPresensi
          .where((p) => p['user_id'].toString() == userId)
          .toList();

      // Cari absen masuk & pulang biasa
      final masukBiasa = userPresensi.firstWhere(
        (p) => p['jenis'] == 'Masuk',
        orElse: () => null,
      );
      final pulangBiasa = userPresensi.firstWhere(
        (p) => p['jenis'] == 'Pulang',
        orElse: () => null,
      );

      // Jenis absen utama
      String jenisAbsen = 'absen biasa';
      String keterangan = '';

      if (userPresensi.any(
        (p) => p['jenis'] == 'Izin' || p['jenis'] == 'Pulang Cepat',
      )) {
        jenisAbsen = 'izin';
        keterangan = 'sakit / dari inputan form';
      } else if (userPresensi.any(
        (p) =>
            p['jenis'] == 'Penugasan_Masuk' || p['jenis'] == 'Penugasan_Pulang',
      )) {
        if (userPresensi.any((p) => p['jenis'] == 'Penugasan_Full')) {
          jenisAbsen = 'penugasan full';
          keterangan = masukBiasa?['status'] == 'Disetujui'
              ? 'di terima'
              : 'di tolak';
        } else {
          jenisAbsen = 'penugasan';
          keterangan = 'di terima / di tolak';
        }
      } else if (userPresensi.any((p) => p['jenis'] == 'Pulang Cepat')) {
        jenisAbsen = 'pulang cepat';
        keterangan = 'di terima / di tolak';
      } else if (masukBiasa != null && pulangBiasa != null) {
        keterangan = 'di setujui';
      } else {
        keterangan = 'sangsi 3 jam tidak masuk';
      }

      rekapMap[userId] = {
        'no': rekapMap.length + 1,
        'nama': nama,
        'nip': nip,
        'jenis_absen': jenisAbsen,
        'waktu_masuk': masukBiasa != null
            ? masukBiasa['created_at'].substring(11, 16)
            : '',
        'absen_masuk': masukBiasa != null ? 'masuk' : '',
        'waktu_pulang': pulangBiasa != null
            ? pulangBiasa['created_at'].substring(11, 16)
            : '',
        'absen_pulang': pulangBiasa != null
            ? (pulangBiasa['jenis'] == 'Pulang Cepat'
                  ? 'pulang cepat'
                  : 'pulang')
            : '',
        'keterangan': keterangan,
      };
    }

    // Urutkan berdasarkan nama
    final sortedList = rekapMap.values.toList()
      ..sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));

    setState(() {
      _rekapData = sortedList;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF3B82F6)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _processRekap();
    }
  }

  Future<void> _exportToExcel() async {
    if (_rekapData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diexport!')),
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
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final dateRange =
        '${DateFormat('dd-MM-yyyy').format(_startDate!)} sampai ${DateFormat('dd-MM-yyyy').format(_endDate!)}';
    final fileName = 'Rekap_Presensi_$dateRange.xlsx';
    final path = '${dir!.path}/$fileName';

    var excel = xls.Excel.createExcel();
    excel.delete('Sheet1');
    xls.Sheet sheet = excel['Rekap Harian'];

    // Header
    sheet.appendRow([
      xls.TextCellValue('No'),
      xls.TextCellValue('Nama'),
      xls.TextCellValue('NIP'),
      xls.TextCellValue('Jenis Absen'),
      xls.TextCellValue('Waktu Absen Masuk'),
      xls.TextCellValue('Absen Masuk'),
      xls.TextCellValue('Waktu Pulang'),
      xls.TextCellValue('Absen Pulang'),
      xls.TextCellValue('Keterangan'),
    ]);

    // Styling header
    final headerColor = xls.ExcelColor.fromHexString('#FF3B82F6');
    final headerFont = xls.ExcelColor.fromHexString('#FFFFFFFF');
    for (int i = 0; i < 9; i++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = xls.CellStyle(
        bold: true,
        backgroundColorHex: headerColor,
        fontColorHex: headerFont,
        horizontalAlign: xls.HorizontalAlign.Center,
      );
    }

    // Isi data
    for (var item in _rekapData) {
      sheet.appendRow([
        xls.TextCellValue(item['no'].toString()),
        xls.TextCellValue(item['nama']),
        xls.TextCellValue(item['nip']),
        xls.TextCellValue(item['jenis_absen']),
        xls.TextCellValue(item['waktu_masuk']),
        xls.TextCellValue(item['absen_masuk']),
        xls.TextCellValue(item['waktu_pulang']),
        xls.TextCellValue(item['absen_pulang']),
        xls.TextCellValue(item['keterangan']),
      ]);
    }

    final bytes = excel.encode()!;
    await File(path).writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil diexport: $fileName'),
          backgroundColor: const Color(0xFF10B981),
          action: SnackBarAction(
            label: 'BUKA',
            onPressed: () => OpenFile.open(path),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeStr = _startDate == null || _endDate == null
        ? 'Pilih Rentang Tanggal'
        : '${DateFormat('dd MMM yyyy', 'id_ID').format(_startDate!)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_endDate!)}';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(32),
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
                    padding: EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(width: 32),
                const Text(
                  'Rekap Presensi Harian',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  dateRangeStr,
                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: const Text('Pilih Rentang Tanggal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                ),
              ],
            ),
          ),

          // Tabel Rekap
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  )
                : _rekapData.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_chart_outlined,
                          size: 120,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 32),
                        Text(
                          'Tidak ada data presensi',
                          style: TextStyle(fontSize: 28, color: Colors.grey),
                        ),
                        Text(
                          'Pilih rentang tanggal yang sesuai',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: DataTable(
                        headingRowHeight: 60,
                        dataRowHeight: 70,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        headingRowColor: MaterialStatePropertyAll(
                          Color(0xFF3B82F6),
                        ),
                        columns: const [
                          DataColumn(label: Text('No')),
                          DataColumn(label: Text('Nama')),
                          DataColumn(label: Text('NIP')),
                          DataColumn(label: Text('Jenis Absen')),
                          DataColumn(label: Text('Waktu Absen Masuk')),
                          DataColumn(label: Text('Absen Masuk')),
                          DataColumn(label: Text('Waktu Pulang')),
                          DataColumn(label: Text('Absen Pulang')),
                          DataColumn(label: Text('Keterangan')),
                        ],
                        rows: _rekapData.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(Text(item['no'].toString())),
                              DataCell(Text(item['nama'])),
                              DataCell(Text(item['nip'])),
                              DataCell(Text(item['jenis_absen'])),
                              DataCell(Text(item['waktu_masuk'])),
                              DataCell(Text(item['absen_masuk'])),
                              DataCell(Text(item['waktu_pulang'])),
                              DataCell(Text(item['absen_pulang'])),
                              DataCell(
                                Text(
                                  item['keterangan'],
                                  style: TextStyle(
                                    color:
                                        item['keterangan'].contains('sangsi') ||
                                            item['keterangan'].contains('tolak')
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
