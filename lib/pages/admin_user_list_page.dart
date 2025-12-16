// lib/pages/admin_user_list_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../api/api_service.dart';
import 'admin_user_detail_page.dart';

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({super.key});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  bool _loading = true;
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  final TextEditingController _searchC = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchC.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.removeListener(_onSearchChanged);
    _searchC.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsers();
      final filtered = data
          .where(
            (u) =>
                (u['role']?.toString().toLowerCase() ?? '') == 'user' &&
                (u['id']?.toString().isNotEmpty ?? false),
          )
          .toList();

      setState(() {
        _users = filtered;
        _filteredUsers = List.from(filtered)
          ..sort(
            (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
              b['nama_lengkap'] ?? '',
            ),
          );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat user: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterUsers() {
    final query = _searchC.text.toLowerCase().trim();
    setState(() {
      _filteredUsers =
          query.isEmpty
                ? List.from(_users)
                : _users.where((u) {
                    final nama = (u['nama_lengkap'] ?? u['nama'] ?? '')
                        .toString()
                        .toLowerCase();
                    final username = (u['username'] ?? '')
                        .toString()
                        .toLowerCase();
                    final nip = (u['nip_nisn']?.toString() ?? '').toLowerCase();
                    return nama.contains(query) ||
                        username.contains(query) ||
                        nip.contains(query);
                  }).toList()
            ..sort(
              (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
                b['nama_lengkap'] ?? '',
              ),
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar Kiri (elegan gelap)
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
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.people_rounded,
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
                              'Kelola User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Sistem Presensi',
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
                const Divider(color: Colors.white12, height: 1),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        '${_filteredUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Pengguna',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Konten Utama
          Expanded(
            child: Column(
              children: [
                // Header Atas dengan Tombol Back
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Tombol Kembali
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 36),
                        tooltip: 'Kembali',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),

                      // Judul
                      const Text(
                        'Daftar Pengguna Presensi',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const Spacer(),

                      // Search Bar
                      SizedBox(
                        width: 450,
                        child: TextField(
                          controller: _searchC,
                          decoration: InputDecoration(
                            hintText: 'Cari nama, username, atau NIP/NIK...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 28,
                            ),
                            suffixIcon: _searchC.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: _searchC.clear,
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 20,
                            ),
                          ),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),

                      const SizedBox(width: 32),

                      // Tombol Refresh
                      ElevatedButton.icon(
                        onPressed: _loadUsers,
                        icon: const Icon(Icons.refresh_rounded, size: 26),
                        label: const Text(
                          'Refresh',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body List User
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchC.text.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.people_alt_outlined,
                                size: 140,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 40),
                              Text(
                                _searchC.text.isNotEmpty
                                    ? 'Tidak ditemukan hasil pencarian'
                                    : 'Belum ada pengguna terdaftar',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchC.text.isNotEmpty
                                    ? 'Coba gunakan kata kunci lain'
                                    : 'Tambahkan user baru untuk memulai',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(40, 32, 40, 60),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (ctx, i) {
                            final u = _filteredUsers[i];
                            final nama =
                                u['nama_lengkap'] ?? u['nama'] ?? 'Unknown';
                            final username = u['username'] ?? '';
                            final nip = u['nip_nisn']?.toString() ?? '';
                            final userId = u['id'].toString();

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.only(bottom: 28),
                                child: Card(
                                  elevation: 10,
                                  shadowColor: const Color(
                                    0xFF3B82F6,
                                  ).withOpacity(0.15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    hoverColor: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.08),
                                    splashColor: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.15),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminUserDetailPage(
                                            userId: userId,
                                            userName: nama,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(36),
                                      child: Row(
                                        children: [
                                          // Avatar Premium
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF3B82F6),
                                                  Color(0xFF1E40AF),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF3B82F6,
                                                  ).withOpacity(0.3),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                username.isNotEmpty
                                                    ? username[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontSize: 56,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 48),

                                          // Info User
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nama,
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                if (username.isNotEmpty)
                                                  _buildInfoRow(
                                                    Icons
                                                        .alternate_email_rounded,
                                                    'Username: $username',
                                                  ),
                                                if (nip.isNotEmpty)
                                                  _buildInfoRow(
                                                    Icons.badge_rounded,
                                                    'NIP/NIK: $nip',
                                                  ),
                                                const SizedBox(height: 20),
                                                const Text(
                                                  'Klik untuk melihat riwayat & detail presensi',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Arrow Icon
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 36,
                                            color: Colors.grey[500],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(fontSize: 20, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
