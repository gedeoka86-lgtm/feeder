import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
//  FIREBASE CONFIG  ← change these URLs to yours
// ─────────────────────────────────────────────
class FirebaseConfig {
  // Dashboard tab  – reads/writes "jadwal" node
  static String dashboardUrl =
      'https://okamakan-01-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Volume tab  – reads "jarakMakanan" node
  static String volumeUrl =
      'https://okamakan-01-default-rtdb.asia-southeast1.firebasedatabase.app';

  // History tab  – reads "history" + "jarakMakanan" nodes
  static String historyUrl =
      'https://okamakan-01-default-rtdb.asia-southeast1.firebasedatabase.app';
}

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
class Jadwal {
  String key;
  int jam;
  int menit;
  bool aktif;

  Jadwal({
    required this.key,
    required this.jam,
    required this.menit,
    this.aktif = true,
  });

  String get waktu =>
      '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}';
}

class LogPakan {
  final String judul;
  final String tanggal;
  final String level;

  LogPakan({required this.judul, required this.tanggal, required this.level});
}

// ─────────────────────────────────────────────
//  FIREBASE REST HELPERS
// ─────────────────────────────────────────────
Future<Map<String, dynamic>?> fbGet(String baseUrl, String path) async {
  final url = Uri.parse('$baseUrl/$path.json');
  final res = await http.get(url);
  if (res.statusCode == 200 && res.body != 'null') {
    return json.decode(res.body) as Map<String, dynamic>;
  }
  return null;
}

Future<dynamic> fbGetValue(String baseUrl, String path) async {
  final url = Uri.parse('$baseUrl/$path.json');
  final res = await http.get(url);
  if (res.statusCode == 200 && res.body != 'null') {
    return json.decode(res.body);
  }
  return null;
}

Future<void> fbPut(String baseUrl, String path, Map<String, dynamic> data) async {
  final url = Uri.parse('$baseUrl/$path.json');
  await http.put(url, body: json.encode(data));
}

Future<void> fbPatch(String baseUrl, String path, Map<String, dynamic> data) async {
  final url = Uri.parse('$baseUrl/$path.json');
  await http.patch(url, body: json.encode(data));
}

Future<void> fbDelete(String baseUrl, String path) async {
  final url = Uri.parse('$baseUrl/$path.json');
  await http.delete(url);
}

Future<String?> fbPost(String baseUrl, String path, Map<String, dynamic> data) async {
  final url = Uri.parse('$baseUrl/$path.json');
  final res = await http.post(url, body: json.encode(data));
  if (res.statusCode == 200) {
    final body = json.decode(res.body);
    return body['name'] as String?;
  }
  return null;
}

// ─────────────────────────────────────────────
//  MAIN
// ─────────────────────────────────────────────
void main() {
  runApp(const PakanIkanApp());
}

class PakanIkanApp extends StatelessWidget {
  const PakanIkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pakan Ikan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0077B6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────
//  SPLASH / MAIN SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF023E8A), Color(0xFF0077B6), Color(0xFF00B4D8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.set_meal_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const Text(
                'Pakan Ikan',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Automatic Fish Feeder',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeShell()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF023E8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Mulai',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HOME SHELL  (bottom nav with 3 tabs)
// ─────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    VolumeTab(),
    HistoryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop_rounded),
            label: 'Volume',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DASHBOARD TAB  (jadwal / schedule list)
// ─────────────────────────────────────────────
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final List<Jadwal> _jadwalList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    setState(() => _loading = true);
    try {
      final data = await fbGet(FirebaseConfig.dashboardUrl, 'jadwal');
      final list = <Jadwal>[];
      if (data != null) {
        data.forEach((key, val) {
          list.add(Jadwal(
            key: key,
            jam: (val['jam'] as num?)?.toInt() ?? 0,
            menit: (val['menit'] as num?)?.toInt() ?? 0,
            aktif: val['aktif'] as bool? ?? true,
          ));
        });
        list.sort((a, b) {
          final aNum = int.tryParse(a.key.replaceFirst('j', '')) ?? 0;
          final bNum = int.tryParse(b.key.replaceFirst('j', '')) ?? 0;
          return aNum.compareTo(bNum);
        });
      }
      setState(() {
        _jadwalList
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Gagal memuat jadwal');
    }
  }

  Future<void> _tambahJadwal() async {
    var maxNum = 0;
    for (final j in _jadwalList) {
      final n = int.tryParse(j.key.replaceFirst('j', '')) ?? 0;
      if (n > maxNum) maxNum = n;
    }
    final newKey = 'j${maxNum + 1}';
    try {
      await fbPut(FirebaseConfig.dashboardUrl, 'jadwal/$newKey', {
        'jam': 0,
        'menit': 0,
        'aktif': true,
      });
      setState(() {
        _jadwalList.add(Jadwal(key: newKey, jam: 0, menit: 0));
      });
      _showSnack('Jadwal $newKey ditambahkan');
    } catch (_) {
      _showSnack('Gagal menambah jadwal');
    }
  }

  Future<void> _hapusJadwal(int index) async {
    final jadwal = _jadwalList[index];
    try {
      await fbDelete(FirebaseConfig.dashboardUrl, 'jadwal/${jadwal.key}');
      setState(() => _jadwalList.removeAt(index));
      _showSnack('Jadwal ${jadwal.key} dihapus');
    } catch (_) {
      _showSnack('Gagal menghapus jadwal');
    }
  }

  Future<void> _editJadwal(Jadwal jadwal) async {
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => _TimePickerDialog(
        initial: TimeOfDay(hour: jadwal.jam, minute: jadwal.menit),
      ),
    );
    if (result == null) return;
    try {
      await fbPatch(FirebaseConfig.dashboardUrl, 'jadwal/${jadwal.key}', {
        'jam': result.hour,
        'menit': result.minute,
      });
      setState(() {
        jadwal.jam = result.hour;
        jadwal.menit = result.minute;
      });
      _showSnack('Jadwal ${jadwal.key} diupdate');
    } catch (_) {
      _showSnack('Gagal update jadwal');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pakan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadJadwal,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jadwalList.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jadwalList.length,
                  itemBuilder: (ctx, i) {
                    final j = _jadwalList[i];
                    return _JadwalCard(
                      jadwal: j,
                      onEdit: () => _editJadwal(j),
                      onDelete: () => _hapusJadwal(i),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahJadwal,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Tambah Jadwal'),
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Belum ada jadwal', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tekan + untuk menambah jadwal', style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final Jadwal jadwal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JadwalCard({
    required this.jadwal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(jadwal.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.access_alarm_rounded, color: Color(0xFF0077B6)),
          ),
          title: Text(
            jadwal.waktu,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          subtitle: Text(jadwal.key, style: TextStyle(color: Colors.grey.shade500)),
          trailing: IconButton(
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF0077B6)),
            onPressed: onEdit,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TIME PICKER DIALOG
// ─────────────────────────────────────────────
class _TimePickerDialog extends StatefulWidget {
  final TimeOfDay initial;
  const _TimePickerDialog({required this.initial});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Waktu Pakan'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NumberPicker(
            value: _hour,
            min: 0,
            max: 23,
            onChanged: (v) => setState(() => _hour = v),
            label: 'Jam',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          _NumberPicker(
            value: _minute,
            min: 0,
            max: 59,
            onChanged: (v) => setState(() => _minute = v),
            label: 'Menit',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;

  const _NumberPicker({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  VOLUME TAB
// ─────────────────────────────────────────────
class VolumeTab extends StatefulWidget {
  const VolumeTab({super.key});

  @override
  State<VolumeTab> createState() => _VolumeTabState();
}

class _VolumeTabState extends State<VolumeTab> {
  int _persen = 0;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchVolume();
    // Poll every 5 seconds for live-ish updates
    _timer = Timer.periodic(const Duration(seconds: 0), (_) => _fetchVolume());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchVolume() async {
    try {
      final value = await fbGetValue(FirebaseConfig.volumeUrl, 'jarakMakanan');
      int persen = 0;
      if (value is num) persen = value.toInt();
      if (value is String) persen = double.tryParse(value)?.toInt() ?? 0;
      persen = persen.clamp(0, 100);
      if (mounted) setState(() { _persen = persen; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _levelColor {
    if (_persen < 15) return Colors.red.shade400;
    if (_persen < 40) return Colors.orange.shade400;
    return const Color(0xFF0077B6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volume Pakan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchVolume,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Percentage circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _levelColor.withOpacity(0.15),
                          _levelColor.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(color: _levelColor, width: 4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_persen%',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: _levelColor,
                          ),
                        ),
                        Text(
                          'Level Pakan',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Vertical bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Labels
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _levelLabel('100%'),
                          SizedBox(height: 180 * (100 - _persen) / 100 - 10),
                          _levelLabel('$_persen%'),
                          SizedBox(height: 180 * _persen / 100),
                          _levelLabel('0%'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Tank
                      Container(
                        width: 80,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 100 - _persen,
                              child: Container(color: Colors.transparent),
                            ),
                            Expanded(
                              flex: _persen == 0 ? 1 : _persen,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _levelColor.withOpacity(0.7),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: const Radius.circular(6),
                                    bottomRight: const Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _levelColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _levelColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _persen < 15
                          ? '⚠️  Level pakan rendah!'
                          : _persen < 40
                              ? '🔶  Level pakan sedang'
                              : '✅  Level pakan normal',
                      style: TextStyle(color: _levelColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _levelLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 10, color: Colors.grey.shade500));
  }
}

// ─────────────────────────────────────────────
//  HISTORY TAB
// ─────────────────────────────────────────────
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final List<LogPakan> _logs = [];
  bool _loading = true;
  bool _sudahDicatat = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _monitorLevel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _monitorLevel());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final data = await fbGet(FirebaseConfig.historyUrl, 'history');
      final list = <LogPakan>[];
      if (data != null) {
        data.forEach((key, val) {
          list.add(LogPakan(
            judul: val['judul'] as String? ?? '',
            tanggal: val['tanggal'] as String? ?? '',
            level: val['level'] as String? ?? '',
          ));
        });
        list.reversed; // Firebase key order is ascending; we reverse below
      }
      if (mounted) {
        setState(() {
          _logs
            ..clear()
            ..addAll(list.reversed.toList());
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _monitorLevel() async {
    try {
      final value = await fbGetValue(FirebaseConfig.historyUrl, 'jarakMakanan');
      int persen = 0;
      if (value is num) persen = value.toInt();
      if (value is String) persen = double.tryParse(value)?.toInt() ?? 0;
      persen = persen.clamp(0, 100);

      if (persen < 15 && !_sudahDicatat) {
        await _catatLog(persen);
        setState(() => _sudahDicatat = true);
      } else if (persen >= 15 && _sudahDicatat) {
        setState(() => _sudahDicatat = false);
      }
    } catch (_) {}
  }

  Future<void> _catatLog(int persen) async {
    try {
      final data = await fbGet(FirebaseConfig.historyUrl, 'history');
      final count = data?.length ?? 0;
      final nomor = count + 1;
      final now = DateTime.now();
      final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final day = days[now.weekday % 7];
      final tanggal =
          '$day, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      await fbPost(FirebaseConfig.historyUrl, 'history', {
        'judul': 'Log $nomor',
        'tanggal': tanggal,
        'level': '$persen%',
      });

      await _loadHistory();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pakan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded,
                          size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Belum ada riwayat',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) {
                    final log = _logs[i];
                    return _LogCard(log: log);
                  },
                ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final LogPakan log;
  const _LogCard({required this.log});

  Color get _levelColor {
    final persen = int.tryParse(log.level.replaceAll('%', '')) ?? 0;
    if (persen < 15) return Colors.red.shade400;
    if (persen < 40) return Colors.orange.shade400;
    return const Color(0xFF0077B6);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _levelColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.warning_amber_rounded, color: _levelColor),
        ),
        title: Text(log.judul,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Hari: ${log.tanggal}', style: TextStyle(color: Colors.grey.shade600)),
            Text('Level Pakan: ${log.level}',
                style: TextStyle(color: _levelColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}