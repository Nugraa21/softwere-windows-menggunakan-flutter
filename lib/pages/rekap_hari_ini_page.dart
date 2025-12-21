// lib/pages/rekap_hari_ini_page.dart
// REKAP HARIAN - TAMPILAN SUPER ELEGAN, PROFESIONAL, TANPA BUG & OVERFLOW

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

  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _allPresensi = [];
  List<dynamic> _users = [];

  List<Map<String, dynamic>> _rekapData = [];

  final TextEditingController _searchC = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _searchC.addListener(_filterData);
    _loadData();
  }

  @override
  void dispose() {
    _searchC.removeListener(_filterData);
    _searchC.dispose();
    super.dispose();
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

    final filteredPresensi = _allPresensi.where((p) {
      final dateStr = (p['created_at'] ?? '').toString();
      if (dateStr.length < 10) return false;
      final presensiDate = DateTime.tryParse(dateStr.substring(0, 10));
      return presensiDate != null &&
          presensiDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          presensiDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();

    int no = 1;
    for (var user in _users) {
      final userId = user['id'].toString();
      final nama = user['nama_lengkap'] ?? '-';
      final nip = user['nip_nisn'] ?? '';

      final userPresensi = filteredPresensi
          .where((p) => p['user_id'].toString() == userId)
          .toList();

      final masukBiasa = userPresensi.firstWhere(
        (p) => p['jenis'] == 'Masuk',
        orElse: () => null,
      );
      final pulangBiasa = userPresensi.firstWhere(
        (p) => p['jenis'] == 'Pulang',
        orElse: () => null,
      );

      final approvalRecord = userPresensi.firstWhere(
        (p) =>
            p['jenis'] == 'Izin' ||
            p['jenis'] == 'Pulang Cepat' ||
            p['jenis'] == 'Penugasan_Masuk' ||
            p['jenis'] == 'Penugasan_Pulang' ||
            p['jenis'] == 'Penugasan_Full',
        orElse: () => null,
      );

      String jenisAbsen = 'absen biasa';
      String keterangan = '';

      if (approvalRecord != null) {
        if (approvalRecord['jenis'] == 'Izin') {
          jenisAbsen = 'izin';
        } else if (approvalRecord['jenis'] == 'Pulang Cepat') {
          jenisAbsen = 'pulang cepat';
        } else if (approvalRecord['jenis'] == 'Penugasan_Full') {
          jenisAbsen = 'penugasan full';
        } else {
          jenisAbsen = 'penugasan';
        }

        final status = approvalRecord['status'] ?? 'Waiting';
        if (status == 'Disetujui') {
          keterangan = 'di terima';
        } else if (status == 'Ditolak') {
          keterangan = 'di tolak';
        } else {
          keterangan = 'di terima / di tolak';
        }
      } else {
        if (masukBiasa != null && pulangBiasa != null) {
          keterangan = 'di setujui';
        } else {
          keterangan = 'sangsi 3 jam tidak masuk';
        }
      }

      rekapMap[userId] = {
        'no': no++,
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
        'absen_pulang': pulangBiasa != null ? 'pulang' : '',
        'keterangan': keterangan,
      };
    }

    final sortedList = rekapMap.values.toList()
      ..sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));

    setState(() {
      _rekapData = sortedList;
      _filteredData = List.from(sortedList);
    });
  }

  void _filterData() {
    final query = _searchC.text.toLowerCase().trim();
    setState(() {
      _filteredData = query.isEmpty
          ? List.from(_rekapData)
          : _rekapData
                .where(
                  (item) =>
                      (item['nama'] as String).toLowerCase().contains(query),
                )
                .toList();
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
        '${DateFormat('dd-MM-yyyy').format(_startDate!)} sd ${DateFormat('dd-MM-yyyy').format(_endDate!)}';
    final fileName = 'Rekap_Presensi_$dateRange.xlsx';
    final path = '${dir!.path}/$fileName';

    var excel = xls.Excel.createExcel();
    excel.delete('Sheet1');
    xls.Sheet sheet = excel['Rekap Harian'];

    sheet.appendRow([
      xls.TextCellValue('No'),
      xls.TextCellValue('Nama'),
      xls.TextCellValue('NIP'),
      xls.TextCellValue('Jenis Absen'),
      xls.TextCellValue('Waktu Masuk'),
      xls.TextCellValue('Absen Masuk'),
      xls.TextCellValue('Waktu Pulang'),
      xls.TextCellValue('Absen Pulang'),
      xls.TextCellValue('Keterangan'),
    ]);

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

  Widget _buildLegend() {
    final legends = [
      ('di setujui', 'Absen biasa lengkap', Colors.green),
      ('sangsi 3 jam tidak masuk', 'Lupa masuk/pulang', Colors.red),
      ('di terima', 'Disetujui (Izin/Penugasan)', Colors.green),
      ('di tolak', 'Ditolak (Izin/Penugasan)', Colors.red),
      ('di terima / di tolak', 'Menunggu approval', Colors.orange),
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 20,
      children: legends
          .map(
            (e) => Chip(
              avatar: CircleAvatar(backgroundColor: e.$3, radius: 14),
              label: Text(
                e.$1,
                style: TextStyle(
                  color: e.$3,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              backgroundColor: e.$3.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: e.$3.withOpacity(0.6), width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 6,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeStr = _startDate == null || _endDate == null
        ? 'Pilih Rentang Tanggal'
        : '${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_startDate!)} - ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_endDate!)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // Sidebar Kiri - Super Elegan
          Container(
            width: 320,
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
                  padding: const EdgeInsets.fromLTRB(32, 80, 32, 40),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        child: const Icon(
                          Icons.summarize_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekap Presensi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Harian',
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
                const Divider(color: Colors.white12, thickness: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Periode',
                          style: TextStyle(color: Colors.white70, fontSize: 20),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          dateRangeStr.split(' - ')[0],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_startDate != _endDate)
                          Text(
                            's/d\n${dateRangeStr.split(' - ')[1]}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 60),
                        const Text(
                          'Total Record',
                          style: TextStyle(color: Colors.white70, fontSize: 20),
                        ),
                        Text(
                          '${_filteredData.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
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
                // Header - Responsif & Tidak Overflow
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 36,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              padding: EdgeInsets.all(20),
                            ),
                          ),
                          const SizedBox(width: 32),
                          const Text(
                            'Rekap Presensi Harian',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 400,
                              child: TextField(
                                controller: _searchC,
                                decoration: InputDecoration(
                                  hintText: 'Cari nama karyawan...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchC.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: _searchC.clear,
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            ElevatedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.date_range_rounded),
                              label: const Text('Pilih Rentang Tanggal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                padding: const EdgeInsets.symmetric(
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
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                padding: const EdgeInsets.symmetric(
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
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(
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
                      : _rekapData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 140,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 40),
                              const Text(
                                'Belum ada data presensi',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Colors.grey,
                                ),
                              ),
                              const Text(
                                'Pilih rentang tanggal yang sesuai',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Legend
                              const Text(
                                'Keterangan Status Absen',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Card(
                                elevation: 16,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(48),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    gradient: LinearGradient(
                                      colors: [Colors.white, Colors.grey[50]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: _buildLegend(),
                                ),
                              ),
                              const SizedBox(height: 80),

                              // Tabel Rekap
                              const Text(
                                'Rekap Harian',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Card(
                                elevation: 20,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowHeight: 90,
                                      dataRowHeight: 90,
                                      columnSpacing: 40,
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                        color: Color(0xFF0F172A),
                                      ),
                                      dataTextStyle: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('No')),
                                        DataColumn(label: Text('Nama')),
                                        DataColumn(label: Text('NIP')),
                                        DataColumn(label: Text('Jenis Absen')),
                                        DataColumn(label: Text('Waktu Masuk')),
                                        DataColumn(label: Text('Absen Masuk')),
                                        DataColumn(label: Text('Waktu Pulang')),
                                        DataColumn(label: Text('Absen Pulang')),
                                        DataColumn(label: Text('Keterangan')),
                                      ],
                                      rows: _filteredData.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final item = entry.value;
                                        final String ket = item['keterangan'];
                                        final bool isTerima =
                                            ket == 'di terima';
                                        final bool isTolak = ket == 'di tolak';
                                        final bool isWaiting =
                                            ket == 'di terima / di tolak';
                                        final bool isSangsi =
                                            ket == 'sangsi 3 jam tidak masuk';

                                        return DataRow(
                                          color: MaterialStatePropertyAll(
                                            index % 2 == 0
                                                ? Colors.blueGrey[50]!
                                                      .withOpacity(0.3)
                                                : Colors.white,
                                          ),
                                          cells: [
                                            DataCell(
                                              Text(
                                                item['no'].toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                item['nama'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(item['nip'])),
                                            DataCell(Text(item['jenis_absen'])),
                                            DataCell(Text(item['waktu_masuk'])),
                                            DataCell(
                                              Text(
                                                item['absen_masuk'],
                                                style: TextStyle(
                                                  color:
                                                      item['absen_masuk']
                                                          .isEmpty
                                                      ? Colors.red
                                                      : Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(item['waktu_pulang']),
                                            ),
                                            DataCell(
                                              Text(
                                                item['absen_pulang'],
                                                style: TextStyle(
                                                  color:
                                                      item['absen_pulang']
                                                          .isEmpty
                                                      ? Colors.red
                                                      : Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSangsi || isTolak
                                                      ? Colors.red
                                                      : isTerima
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                child: Text(
                                                  ket,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
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
