import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class RekapPage extends StatefulWidget {
  const RekapPage({super.key});
  @override
  State<RekapPage> createState() => _RekapPageState();
}

class _RekapPageState extends State<RekapPage> {
  bool _loading = false;
  List<dynamic> _data = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final Map<String, Map<String, String>> _pivot = {};
  final List<String> _allDates = [];
  final TextEditingController _searchC = TextEditingController();
  List<String> _filteredNames = [];

  final Map<int, String> _indonesianMonths = {
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

  final Map<String, String> _dayNames = {
    'Mon': 'Sen',
    'Tue': 'Sel',
    'Wed': 'Rab',
    'Thu': 'Kam',
    'Fri': 'Jum',
    'Sat': 'Sab',
    'Sun': 'Min',
  };

  @override
  void initState() {
    super.initState();
    _loadRekap();
    _searchC.addListener(_filterNames);
  }

  @override
  void dispose() {
    _searchC.removeListener(_filterNames);
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadRekap() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getRekap(
        month: _selectedMonth.toString().padLeft(2, '0'),
        year: _selectedYear.toString(),
      );
      setState(() {
        _data = data;
        _processPivot();
        _filteredNames = List.from(_pivot.keys);
        _filterNames();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal load data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _processPivot() {
    _pivot.clear();
    _generateAllDates();
    for (var item in _data) {
      final nama = item['nama_lengkap'] ?? 'Tanpa Nama';
      final rawDate = item['created_at'] ?? '';
      final tgl = rawDate.length >= 10 ? rawDate.substring(0, 10) : '';
      final jenis = item['jenis'] ?? '-';
      final status = item['status'] ?? 'Pending';
      final shortJenis = _getShortJenis(jenis, status);

      _pivot.putIfAbsent(nama, () => {});

      if (tgl.isNotEmpty && _allDates.contains(tgl)) {
        // Prioritas: PF > I > R > PN
        final priority = {'PF': 0, 'I': 1, 'R': 2, 'PN': 3, 'PC': 4};
        final current = _pivot[nama]![tgl];
        if (current == null ||
            (priority[shortJenis] ?? 99) < (priority[current] ?? 99)) {
          _pivot[nama]![tgl] = shortJenis;
        }
      }
    }
  }

  String _getShortJenis(String jenis, String status) {
    if (status != 'Disetujui') return 'NA';
    switch (jenis) {
      case 'Masuk':
      case 'Pulang':
        return 'R';
      case 'Penugasan_Masuk':
      case 'Penugasan_Pulang':
        return 'PN';
      case 'Penugasan_Full':
        return 'PF';
      case 'Izin':
        return 'I';
      case 'Pulang Cepat':
        return 'PC';
      default:
        return '-';
    }
  }

  void _generateAllDates() {
    _allDates.clear();
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      _allDates.add(DateFormat('yyyy-MM-dd').format(date));
    }
  }

  bool _isWeekend(String dateStr) {
    final date = DateTime.parse(dateStr);
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  bool _isFuture(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day));
  }

  String _getIndonesianMonth(int month) =>
      _indonesianMonths[month] ?? month.toString();

  String _getIndonesianDayAbbrev(DateTime date) {
    final english = DateFormat('EEE', 'en_US').format(date);
    return _dayNames[english] ?? english;
  }

  Color _getFlutterColor(String code) {
    switch (code) {
      case 'R':
        return const Color(0xFF10B981);
      case 'PN':
        return const Color(0xFFF59E0B);
      case 'PF':
        return const Color(0xFFFFB74D);
      case 'I':
        return const Color(0xFF2196F3);
      case 'NA':
        return const Color(0xFFD32F2F);
      case 'PC':
        return const Color(0xFFFFB74D);
      default:
        return Colors.grey;
    }
  }

  String _getBgColorHex(String code) {
    switch (code) {
      case 'R':
        return 'FF4CAF50';
      case 'PN':
        return 'FFFF9800';
      case 'PF':
        return 'FFFFB74D';
      case 'I':
        return 'FF2196F3';
      case 'NA':
        return 'FFD32F2F';
      case 'PC':
        return 'FFFFB74D';
      default:
        return 'FFE6E6E6';
    }
  }

  xls.ExcelColor _getExcelBgColor(String code) {
    return xls.ExcelColor.fromHexString('#${_getBgColorHex(code)}');
  }

  xls.ExcelColor _getExcelFontColor() =>
      xls.ExcelColor.fromHexString('#FFFFFF');

  xls.ExcelColor _getExcelGrayColor(String hexFull) =>
      xls.ExcelColor.fromHexString('#$hexFull');

  Future<void> _exportToExcel() async {
    if (_data.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data kosong!')));
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
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getTemporaryDirectory();
    }

    final fileName =
        'Rekap_Absensi_${_getIndonesianMonth(_selectedMonth)} $_selectedYear.xlsx';
    final path = '${dir.path}/$fileName';

    var excel = xls.Excel.createExcel();
    excel.delete('Sheet1');
    xls.Sheet lengkapSheet = excel['Rekap Lengkap'];
    xls.Sheet harianSheet = excel['Rekap Harian'];

    // Sheet Rekap Lengkap
    lengkapSheet.appendRow([
      xls.TextCellValue('No'),
      xls.TextCellValue('Nama'),
      xls.TextCellValue('Tanggal'),
      xls.TextCellValue('Jenis'),
      xls.TextCellValue('Status'),
      xls.TextCellValue('Keterangan'),
    ]);

    int no = 1;
    for (var item in _data) {
      final jenis = item['jenis'] ?? '-';
      final status = item['status'] ?? 'Pending';
      final keterangan = status != 'Disetujui'
          ? 'Tidak Disetujui'
          : (item['keterangan'] ?? '-');
      lengkapSheet.appendRow([
        xls.TextCellValue(no.toString()),
        xls.TextCellValue(item['nama_lengkap'] ?? '-'),
        xls.TextCellValue(item['created_at']?.substring(0, 10) ?? '-'),
        xls.TextCellValue(jenis),
        xls.TextCellValue(status),
        xls.TextCellValue(keterangan),
      ]);
      no++;
    }

    // Sheet Rekap Harian
    List<xls.CellValue> header = [xls.TextCellValue('Nama')];
    for (var d in _allDates) {
      header.add(xls.TextCellValue(d.substring(8, 10)));
    }
    harianSheet.appendRow(header);

    // Styling header
    for (int i = 0; i < header.length; i++) {
      final cell = harianSheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = xls.CellStyle(
        bold: true,
        backgroundColorHex: _getExcelGrayColor('FFE6E6E6'),
        horizontalAlign: xls.HorizontalAlign.Center,
      );
    }

    List<String> names = _pivot.keys.toList()..sort();
    int rowIndex = 1;
    for (var nama in names) {
      List<xls.CellValue> row = [xls.TextCellValue(nama)];
      List<String> values = [];
      for (var d in _allDates) {
        String value;
        if (_isWeekend(d)) {
          value = 'Libur';
        } else if (_isFuture(d)) {
          value = '';
        } else {
          value = _pivot[nama]![d] ?? '-';
        }
        row.add(xls.TextCellValue(value));
        values.add(value);
      }
      harianSheet.appendRow(row);

      // Styling cells
      for (int i = 0; i < values.length; i++) {
        final value = values[i];
        final cell = harianSheet.cell(
          xls.CellIndex.indexByColumnRow(
            columnIndex: i + 1,
            rowIndex: rowIndex,
          ),
        );
        if (value == 'Libur') {
          cell.cellStyle = xls.CellStyle(
            backgroundColorHex: _getExcelGrayColor('FFD9D9D9'),
          );
        } else if (value != '' && value != '-') {
          cell.cellStyle = xls.CellStyle(
            backgroundColorHex: _getExcelBgColor(value),
            fontColorHex: _getExcelFontColor(),
            bold: true,
            horizontalAlign: xls.HorizontalAlign.Center,
          );
        }
      }
      rowIndex++;
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

  Future<void> _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF3B82F6)),
        ),
        child: child!,
      ),
    );
    if (picked != null &&
        (picked.month != _selectedMonth || picked.year != _selectedYear)) {
      setState(() {
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
      _loadRekap();
    }
  }

  void _filterNames() {
    final query = _searchC.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredNames = List.from(_pivot.keys);
      } else {
        _filteredNames = _pivot.keys
            .where((nama) => nama.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  int _getStats(String code) {
    int count = 0;
    for (var nama in _pivot.keys) {
      for (var d in _allDates) {
        if (!_isWeekend(d) && !_isFuture(d) && _pivot[nama]![d] == code)
          count++;
      }
    }
    return count;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 20,
      runSpacing: 12,
      children: [
        _legendItem('R', 'Masuk/Pulang Biasa', const Color(0xFF10B981)),
        _legendItem('PN', 'Penugasan Masuk/Pulang', const Color(0xFFF59E0B)),
        _legendItem('PF', 'Penugasan Full', const Color(0xFFFFB74D)),
        _legendItem('I', 'Izin', const Color(0xFF2196F3)),
        _legendItem('NA', 'Tidak Disetujui', const Color(0xFFD32F2F)),
        _legendItem('-', 'Tidak Hadir', Colors.grey),
        _legendItem('Libur', 'Weekend', Colors.grey[300]!),
      ],
    );
  }

  Widget _legendItem(String code, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.6), width: 3),
          ),
        ),
        const SizedBox(width: 12),
        Text('$code - $label', style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 40,
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
    final totalTeachers = _pivot.keys.length;
    final workDays = _allDates.where((d) => !_isWeekend(d)).length;
    final presentDays =
        _getStats('R') + _getStats('PN') + _getStats('PF') + _getStats('I');
    final absentDays = totalTeachers * workDays - presentDays;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
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
                          Icons.summarize_rounded,
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
                              'Rekap Absensi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bulanan',
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
                          'Periode',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_getIndonesianMonth(_selectedMonth)} $_selectedYear',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Total Guru',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        Text(
                          '$totalTeachers',
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
                      const Text(
                        'Rekap Absensi Bulanan',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          controller: _searchC,
                          decoration: InputDecoration(
                            hintText: 'Cari nama guru...',
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
                        onPressed: _showMonthPicker,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Pilih Bulan'),
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
                        onPressed: _loadRekap,
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

                // Body
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : _data.isEmpty
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
                                'Tidak ada data rekap',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.grey,
                                ),
                              ),
                              Text('Pilih periode lain atau refresh'),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Statistik Bulanan',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 24,
                                runSpacing: 24,
                                children: [
                                  _buildStatCard(
                                    'Total Guru',
                                    '$totalTeachers',
                                    Icons.people_rounded,
                                    const Color(0xFF3B82F6),
                                  ),
                                  _buildStatCard(
                                    'Hari Kerja',
                                    '$workDays',
                                    Icons.calendar_today_rounded,
                                    const Color(0xFF10B981),
                                  ),
                                  _buildStatCard(
                                    'Hadir',
                                    '$presentDays',
                                    Icons.check_circle_rounded,
                                    const Color(0xFF10B981),
                                  ),
                                  _buildStatCard(
                                    'Absen',
                                    '$absentDays',
                                    Icons.cancel_rounded,
                                    const Color(0xFFEF4444),
                                  ),
                                  _buildStatCard(
                                    'Izin',
                                    '${_getStats('I')}',
                                    Icons.sick_rounded,
                                    const Color(0xFF2196F3),
                                  ),
                                  _buildStatCard(
                                    'Penugasan',
                                    '${_getStats('PN') + _getStats('PF')}',
                                    Icons.assignment_rounded,
                                    const Color(0xFF8B5CF6),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),
                              const Text(
                                'Keterangan',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: _buildLegend(),
                                ),
                              ),
                              const SizedBox(height: 48),
                              const Text(
                                'Rekap Harian',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Card(
                                elevation: 12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowHeight: 80,
                                    dataRowHeight: 80,
                                    columnSpacing: 20,
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    columns: [
                                      const DataColumn(
                                        label: Text('Nama Guru'),
                                      ),
                                      ..._allDates.map((d) {
                                        final day = int.parse(d.substring(8));
                                        final date = DateTime.parse(d);
                                        final abbrev = _getIndonesianDayAbbrev(
                                          date,
                                        );
                                        return DataColumn(
                                          label: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$day',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                abbrev,
                                                style: TextStyle(
                                                  color: _isWeekend(d)
                                                      ? Colors.red
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                    rows: (_filteredNames..sort()).map((nama) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              child: Text(
                                                nama,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ..._allDates.map((d) {
                                            if (_isWeekend(d)) {
                                              return const DataCell(
                                                Center(
                                                  child: Text(
                                                    'Libur',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            if (_isFuture(d))
                                              return const DataCell(Text(''));
                                            final val = _pivot[nama]![d] ?? '-';
                                            final color = _getFlutterColor(val);
                                            return DataCell(
                                              Center(
                                                child: val == '-'
                                                    ? const Text(
                                                        '-',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      )
                                                    : Container(
                                                        width: 50,
                                                        height: 50,
                                                        decoration: BoxDecoration(
                                                          color: color
                                                              .withOpacity(0.2),
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color: color
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                            width: 3,
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            val,
                                                            style: TextStyle(
                                                              color: color,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 20,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            );
                                          }),
                                        ],
                                      );
                                    }).toList(),
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
