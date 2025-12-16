// lib/pages/user_management_page.dart (VERSI FINAL - ERROR DIPERBAIKI + CARD HANYA TAMPILKAN ROLE SAJA)

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

  // Status yang diizinkan untuk dropdown edit (sesuai backend PHP)
  final List<String> _allowedStatuses = ['Karyawan', 'Guru', 'Staff Lain'];

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        elevation: 20,
        icon: Icon(Icons.warning_amber_rounded, size: 64, color: Colors.red),
        title: Text(
          'Hapus Akun?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Akun ini akan dihapus secara permanen.',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Hapus',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
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
    String currentStatus = user['status']?.toString().trim() ?? 'Karyawan';
    String selectedStatus = _allowedStatuses.contains(currentStatus)
        ? currentStatus
        : _allowedStatuses[0];

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Colors.white,
        elevation: 20,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: EdgeInsets.all(40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 40,
                        color: Color(0xFF3B82F6),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Edit Akun',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  _modernTextField(usernameC, 'Username', Icons.person_rounded),
                  SizedBox(height: 20),
                  _modernTextField(
                    namaC,
                    'Nama Lengkap',
                    Icons.account_circle_rounded,
                  ),
                  SizedBox(height: 20),
                  StatefulBuilder(
                    builder: (context, setStateDialog) => Column(
                      children: [
                        _modernTextField(
                          nipC,
                          selectedStatus == 'Karyawan'
                              ? 'NIP/NISN (akan dihapus jika Karyawan)'
                              : 'NIP/NISN (wajib)',
                          Icons.badge_rounded,
                          enabled: selectedStatus != 'Karyawan',
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: _dropdownDecoration(
                            'Role Akun',
                            Icons.shield_rounded,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'user',
                              child: _dropdownItem('User', Colors.green),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: _dropdownItem('Admin', Colors.blue),
                            ),
                            DropdownMenuItem(
                              value: 'superadmin',
                              child: _dropdownItem('Super Admin', Colors.red),
                            ),
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => selectedRole = val!),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: _dropdownDecoration(
                            'Status Pegawai',
                            Icons.work_rounded,
                          ),
                          items: _allowedStatuses
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: _dropdownItem(s, _getStatusColor(s)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setStateDialog(() {
                              selectedStatus = val!;
                              if (selectedStatus == 'Karyawan') {
                                nipC.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  _modernTextField(
                    passC,
                    'Password Baru (kosongkan jika tidak ubah)',
                    Icons.lock_rounded,
                    obscureText: true,
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Batal', style: TextStyle(fontSize: 18)),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedStatus != 'Karyawan' &&
                              nipC.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'NIP/NISN wajib diisi untuk Guru atau Staff Lain',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final nipToSend = selectedStatus == 'Karyawan'
                              ? ''
                              : nipC.text.trim();

                          try {
                            final res = await ApiService.updateUser(
                              id: user['id'].toString(),
                              username: usernameC.text.trim(),
                              namaLengkap: namaC.text.trim(),
                              nipNisn: nipToSend,
                              role: selectedRole,
                              status: selectedStatus,
                              password: passC.text.isEmpty
                                  ? null
                                  : passC.text.trim(),
                            );

                            if (res['status'] == 'success' ||
                                res['status'] == true) {
                              Navigator.pop(context, true);
                              _loadUsers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Akun berhasil diperbarui'),
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
                          backgroundColor: Color(0xFF3B82F6),
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'Simpan',
                          style: TextStyle(fontSize: 18, color: Colors.white),
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

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 28, color: Color(0xFF3B82F6)),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _dropdownItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 14),
        Text(text, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _modernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      style: TextStyle(fontSize: 16, color: enabled ? null : Colors.grey[500]),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 28,
          color: enabled ? Color(0xFF3B82F6) : Colors.grey[400],
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return Color(0xFFEF4444);
      case 'admin':
        return Color(0xFF3B82F6);
      default:
        return Color(0xFF10B981);
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

  // DIPINDAHKAN KEMBALI KARENA DIPAKAI DI DROPDOWN EDIT
  Color _getStatusColor(String status) {
    switch (status.trim()) {
      case 'Guru':
        return Colors.orange;
      case 'Staff Lain':
        return Colors.purple;
      case 'Karyawan':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 300,
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
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.manage_accounts_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 24),
                      Expanded(
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
                Divider(color: Colors.white12),
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        '${_filteredUsers.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Akun',
                        style: TextStyle(color: Colors.white70, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Spacer(),
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
                        icon: Icon(Icons.arrow_back_rounded, size: 32),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.all(16),
                        ),
                      ),
                      SizedBox(width: 32),
                      Text(
                        'Manajemen User & Admin',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          controller: _searchC,
                          decoration: InputDecoration(
                            hintText: 'Cari nama, username, NIP/NISN...',
                            prefixIcon: Icon(Icons.search_rounded, size: 28),
                            suffixIcon: _searchC.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded),
                                    onPressed: _searchC.clear,
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                          ),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(width: 32),
                      ElevatedButton.icon(
                        onPressed: _loadUsers,
                        icon: Icon(Icons.refresh_rounded, size: 24),
                        label: Text('Refresh', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          padding: EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List User
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
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
                                size: 120,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 32),
                              Text(
                                _searchC.text.isNotEmpty
                                    ? 'Tidak ditemukan user'
                                    : 'Belum ada akun terdaftar',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(40, 32, 40, 60),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (ctx, i) {
                            final u = _filteredUsers[i];
                            final role = (u['role'] ?? 'user')
                                .toString()
                                .toLowerCase();
                            final roleColor = _getRoleColor(role);

                            return Container(
                              margin: EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: roleColor.withOpacity(0.12),
                                    blurRadius: 25,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                                border: Border.all(
                                  color: roleColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            roleColor,
                                            roleColor.withOpacity(0.7),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (u['username'] ?? '?')[0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 40),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u['nama_lengkap'] ?? 'Tanpa Nama',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          if (u['username'] != null)
                                            _infoRow(
                                              Icons.alternate_email_rounded,
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
                                          SizedBox(height: 20),
                                          // HANYA TAMPILKAN ROLE SAJA
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: roleColor.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(40),
                                              border: Border.all(
                                                color: roleColor.withOpacity(
                                                  0.6,
                                                ),
                                                width: 3,
                                              ),
                                            ),
                                            child: Text(
                                              _getRoleLabel(role),
                                              style: TextStyle(
                                                color: roleColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _editUser(u),
                                          icon: Icon(
                                            Icons.edit_rounded,
                                            size: 32,
                                          ),
                                          color: Color(0xFF3B82F6),
                                          tooltip: 'Edit',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.blue[50],
                                            padding: EdgeInsets.all(16),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        IconButton(
                                          onPressed: () => _deleteUser(
                                            u['id'].toString(),
                                            role,
                                          ),
                                          icon: Icon(
                                            Icons.delete_rounded,
                                            size: 32,
                                          ),
                                          color: Colors.red,
                                          tooltip: 'Hapus',
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.red[50],
                                            padding: EdgeInsets.all(16),
                                          ),
                                        ),
                                      ],
                                    ),
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
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Color(0xFF3B82F6)),
          SizedBox(width: 16),
          Text(text, style: TextStyle(fontSize: 18, color: Colors.black87)),
        ],
      ),
    );
  }
}
