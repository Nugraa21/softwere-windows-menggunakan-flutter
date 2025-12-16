// lib/pages/user_management_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../api/api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
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
            (u) => [
              'user',
              'admin',
              'superadmin',
            ].contains(u['role']?.toString().toLowerCase()),
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
                    final status = (u['status'] ?? '').toString().toLowerCase();
                    return nama.contains(query) ||
                        username.contains(query) ||
                        nip.contains(query) ||
                        status.contains(query);
                  }).toList()
            ..sort(
              (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
                b['nama_lengkap'] ?? '',
              ),
            );
    });
  }

  Future<void> _deleteUser(String id, String role) async {
    if (role.toLowerCase() == 'superadmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak boleh menghapus Super Admin'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          size: 64,
          color: Colors.red,
        ),
        title: const Text(
          'Hapus User?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Aksi ini permanen dan tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Permanen', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.deleteUser(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'User berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final usernameC = TextEditingController(text: user['username']);
    final namaC = TextEditingController(text: user['nama_lengkap'] ?? '');
    final nipC = TextEditingController(text: user['nip_nisn'] ?? '');
    final passC = TextEditingController();

    String selectedRole = (user['role'] ?? 'user').toString().toLowerCase();
    String selectedStatus = (user['status'] ?? 'Karyawan').toString();

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit User',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: usernameC,
                    decoration: _inputDecoration('Username', Icons.person),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: namaC,
                    decoration: _inputDecoration(
                      'Nama Lengkap',
                      Icons.account_circle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nipC,
                    decoration: _inputDecoration(
                      'NIP/NISN ${selectedStatus != 'Karyawan' ? '(wajib)' : '(opsional)'}',
                      Icons.badge,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: _inputDecoration('Role', Icons.shield),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'superadmin',
                        child: Text('Super Admin'),
                      ),
                    ],
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: _inputDecoration('Status Pegawai', Icons.work),
                    items: const [
                      DropdownMenuItem(
                        value: 'Karyawan',
                        child: Text('Karyawan'),
                      ),
                      DropdownMenuItem(value: 'Guru', child: Text('Guru')),
                      DropdownMenuItem(
                        value: 'Staff Lain',
                        child: Text('Staff Lain'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => selectedStatus = val!);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passC,
                    obscureText: true,
                    decoration: _inputDecoration(
                      'Password Baru (kosongkan jika tidak ubah)',
                      Icons.lock,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          // Validasi NIP wajib jika bukan Karyawan
                          if (selectedStatus != 'Karyawan' &&
                              (nipC.text.trim().isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'NIP/NISN wajib diisi untuk Guru/Staff Lain',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          try {
                            final res = await ApiService.updateUser(
                              id: user['id'].toString(),
                              username: usernameC.text.trim(),
                              namaLengkap: namaC.text.trim(),
                              nipNisn: nipC.text.trim(),
                              role: selectedRole,
                              status: selectedStatus,
                              password: passC.text.isEmpty
                                  ? null
                                  : passC.text.trim(),
                            );

                            if (res['status'] == 'success' ||
                                res['status'] == true) {
                              if (mounted) Navigator.pop(context, true);
                              _loadUsers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User berhasil diperbarui'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res['message'] ?? 'Gagal update',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved == true) _loadUsers();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return const Color(0xFFEF4444);
      case 'admin':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'SUPER ADMIN';
      case 'admin':
        return 'ADMIN';
      default:
        return 'USER';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Guru':
        return Colors.orange;
      case 'Staff Lain':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar Kiri (sama seperti sebelumnya)
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
                        ),
                        child: const Icon(
                          Icons.manage_accounts_rounded,
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
                              'Admin & Staff',
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
                        'Total Akun',
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
                // Header (tetap sama)
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
                      const Text(
                        'Manajemen User & Admin',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 450,
                        child: TextField(
                          controller: _searchC,
                          decoration: InputDecoration(
                            hintText:
                                'Cari nama, username, NIP/NISN, atau status...',
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
                      ElevatedButton.icon(
                        onPressed: _loadUsers,
                        icon: const Icon(Icons.refresh_rounded, size: 26),
                        label: const Text(
                          'Refresh',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                // List User
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
                                    : Icons.manage_accounts_outlined,
                                size: 140,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 40),
                              Text(
                                _searchC.text.isNotEmpty
                                    ? 'Tidak ditemukan user'
                                    : 'Belum ada akun terdaftar',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchC.text.isNotEmpty
                                    ? 'Coba kata kunci lain'
                                    : 'Tambahkan user/admin baru',
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
                            final role = (u['role'] ?? 'user')
                                .toString()
                                .toLowerCase();
                            final status = (u['status'] ?? 'Karyawan')
                                .toString();
                            final roleColor = _getRoleColor(role);
                            final statusColor = _getStatusColor(status);

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 28),
                                child: Card(
                                  elevation: 12,
                                  shadowColor: roleColor.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    hoverColor: roleColor.withOpacity(0.08),
                                    child: Padding(
                                      padding: const EdgeInsets.all(36),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  roleColor,
                                                  roleColor.withOpacity(0.7),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: roleColor.withOpacity(
                                                    0.4,
                                                  ),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                (u['username'] ?? '?')[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 56,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 48),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  u['nama_lengkap'] ??
                                                      'Tanpa Nama',
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                if (u['username'] != null)
                                                  _infoRow(
                                                    Icons
                                                        .alternate_email_rounded,
                                                    'Username: ${u['username']}',
                                                  ),
                                                if (u['nip_nisn']
                                                        ?.toString()
                                                        .isNotEmpty ==
                                                    true)
                                                  _infoRow(
                                                    Icons.badge_rounded,
                                                    'NIP/NISN: ${u['nip_nisn']}',
                                                  ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: roleColor
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                        border: Border.all(
                                                          color: roleColor
                                                              .withOpacity(0.5),
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _getRoleLabel(role),
                                                        style: TextStyle(
                                                          color: roleColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: statusColor
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                        border: Border.all(
                                                          color: statusColor
                                                              .withOpacity(0.5),
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        status,
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () => _editUser(u),
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                  size: 32,
                                                ),
                                                color: const Color(0xFF3B82F6),
                                                tooltip: 'Edit User',
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue[50],
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              IconButton(
                                                onPressed: () => _deleteUser(
                                                  u['id'].toString(),
                                                  role,
                                                ),
                                                icon: const Icon(
                                                  Icons.delete_rounded,
                                                  size: 32,
                                                ),
                                                color: Colors.red,
                                                tooltip: 'Hapus User',
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red[50],
                                                  padding: const EdgeInsets.all(
                                                    16,
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

  Widget _infoRow(IconData icon, String text) {
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
