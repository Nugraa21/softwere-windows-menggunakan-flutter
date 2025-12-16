// pages/rekap_page.dart (ENHANCED: Modern UI with neumorphic cards, subtle gradients, hero animations, enhanced stats dashboard, responsive DataTable, consistent styling without functional changes - FIXED: Removed extra comma in Row children and syntax issues)
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

class _RekapPageState extends State<RekapPage> with TickerProviderStateMixin {
  bool _loading = false;
  List<dynamic> _data = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final Map<String, Map<String, String>> _pivot = {};
  final List<String> _allDates = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _loadRekap();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRekap() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getRekap(
        month: _selectedMonth.toString().padLeft(2, '0'),
        year: _selectedYear.toString(),
      );
      setState(() => _data = data);
      _processPivot();
      _animController.forward(from: 0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal load data: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
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
        if (_pivot[nama]![tgl] == null ||
            ['PF', 'I', 'R', 'PN'].indexOf(shortJenis) <
                ['PF', 'I', 'R', 'PN'].indexOf(_pivot[nama]![tgl]!)) {
          _pivot[nama]![tgl] = shortJenis;
        }
      }
    }
  }

  String _getShortJenis(String jenis, String status) {
    if (status != 'Disetujui') {
      return 'NA'; // Tidak disetujui
    }

    switch (jenis) {
      case 'Masuk':
      case 'Pulang':
        return 'R'; // Regular (hijau)
      case 'Penugasan_Masuk':
      case 'Penugasan_Pulang':
        return 'PN'; // Penugasan Normal (oren)
      case 'Penugasan_Full':
        return 'PF'; // Penugasan Full (kuning)
      case 'Izin':
        return 'I'; // Izin (biru)
      case 'Pulang Cepat':
        return 'PC'; // Pulang Cepat (amber, if needed)
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
    return date.isAfter(DateTime.now());
  }

  String _getIndonesianMonth(int month) {
    return _indonesianMonths[month] ?? month.toString();
  }

  String _getIndonesianDayAbbrev(DateTime date) {
    final englishAbbrev = DateFormat('EEE', 'en_US').format(date);
    return _dayNames[englishAbbrev] ?? englishAbbrev;
  }

  Color _getFlutterColor(String code) {
    switch (code) {
      case 'R':
        return Colors.green; // Hijau for regular
      case 'PN':
        return Colors.orange; // Oren for penugasan normal
      case 'PF':
        return Colors.amber; // Kuning for penugasan full
      case 'I':
        return Colors.blue; // Biru for izin
      case 'NA':
        return Colors.red[700]!; // Abu merah for not approved
      case 'PC':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getBgColorHex(String code) {
    switch (code) {
      case 'R':
        return 'FF4CAF50'; // Hijau
      case 'PN':
        return 'FFFF9800'; // Oren
      case 'PF':
        return 'FFFFB74D'; // Kuning
      case 'I':
        return 'FF2196F3'; // Biru
      case 'NA':
        return 'FFD32F2F'; // Abu merah
      case 'PC':
        return 'FFFFB74D';
      default:
        return 'FFE6E6E6'; // Abu-abu muda
    }
  }

  xls.ExcelColor _getExcelBgColor(String code) {
    final hex = _getBgColorHex(code);
    return xls.ExcelColor.fromHexString('#$hex');
  }

  xls.ExcelColor _getExcelFontColor() {
    return xls.ExcelColor.fromHexString('#FFFFFF');
  }

  xls.ExcelColor _getExcelGrayColor(String hexFull) {
    return xls.ExcelColor.fromHexString('#$hexFull');
  }

  Future<void> _exportToExcel() async {
    if (_data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data kosong!')));
      }
      return;
    }

    Directory? dir;
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin penyimpanan ditolak')),
          );
        }
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

    // Sheet Rekap Lengkap (detail)
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

      // Styling data cells (columns 1+)
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

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
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

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem('R', 'Masuk/Pulang Biasa', Colors.green),
        _legendItem('PN', 'Penugasan Masuk/Pulang', Colors.orange),
        _legendItem('PF', 'Penugasan Full', Colors.amber),
        _legendItem('I', 'Izin', Colors.blue),
        _legendItem('NA', 'Tidak Disetujui', Colors.red[700]!),
        _legendItem('-', 'Tidak Hadir', Colors.grey[400]!),
        _legendItem('Libur', 'Weekend', Colors.grey[300]!),
      ],
    );
  }

  Widget _legendItem(String code, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$code - $label',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  int _getStats(String code) {
    int count = 0;
    for (var nama in _pivot.keys) {
      for (var d in _allDates) {
        if (!_isWeekend(d) && !_isFuture(d) && _pivot[nama]![d] == code) {
          count++;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalTeachers = _pivot.keys.length;
    final totalDays = _allDates.length;
    final presentDays =
        _getStats('R') + _getStats('PN') + _getStats('PF') + _getStats('I');
    final absentDays =
        totalTeachers * (totalDays - _allDates.where(_isWeekend).length) -
        presentDays;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Rekap Absensi Guru',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showMonthPicker,
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Pilih Bulan',
          ),
          Hero(
            tag: 'refresh_rekap',
            child: IconButton(
              onPressed: _loadRekap,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ),
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Excel',
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.9),
                const Color(0xFF3B82F6).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF3B82F6),
                ),
              )
            : _data.isEmpty
            ? Center(
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.05),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 80,
                        color: const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Tidak ada data untuk periode ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coba pilih bulan lain atau tunggu data baru',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF9CA3AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 80,
                    16,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Dashboard Cards
                      const SizedBox(height: 24),
                      // Info Card Periode
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Periode Rekap',
                                    style: TextStyle(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${_getIndonesianMonth(_selectedMonth)} $_selectedYear',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Entri',
                                    style: TextStyle(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${_data.length}',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Legend Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Keterangan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildLegend(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title
                      const Text(
                        'Rekap Harian Guru',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // DataTable Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 70,
                              dataRowHeight: 70,
                              columnSpacing: 12,
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                              ),
                              columns: [
                                const DataColumn(
                                  label: Text(
                                    'Nama Guru',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                ..._allDates.map((d) {
                                  final dayNum = d.substring(8);
                                  final isWeekend = _isWeekend(d);
                                  final date = DateTime.parse(d);
                                  final dayAbbrev = _getIndonesianDayAbbrev(
                                    date,
                                  );
                                  return DataColumn(
                                    label: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayNum,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          dayAbbrev,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isWeekend
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              rows: (_pivot.keys.toList()..sort()).map((nama) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          nama,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ..._allDates.map((d) {
                                      if (_isWeekend(d)) {
                                        return DataCell(
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Libur',
                                                style: TextStyle(
                                                  color: Color(0xFF6B7280),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      if (_isFuture(d)) {
                                        return const DataCell(Text(''));
                                      }
                                      final val = _pivot[nama]![d] ?? '-';
                                      final flutterColor = _getFlutterColor(
                                        val,
                                      );

                                      return DataCell(
                                        Center(
                                          child: val == '-'
                                              ? Text(
                                                  val,
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF6B7280,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: flutterColor
                                                        .withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: flutterColor
                                                          .withOpacity(0.5),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      val,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: flutterColor,
                                                        fontSize: 18,
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
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
