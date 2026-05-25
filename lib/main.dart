import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
//  FIREBASE CONFIG  (no google-services.json!)
// ─────────────────────────────────────────────
const String _firebaseUrl =
    'https://monika-011-default-rtdb.asia-southeast1.firebasedatabase.app';
const String _firebaseKey = 'AIzaSyDmbTZqKCF4wvm7H8T9x140zepPfywvYVc';

// ─────────────────────────────────────────────
//  PASTEL COLOR PALETTE
// ─────────────────────────────────────────────
class AppColors {
  static const bg = Color(0xFFF0F4FF);
  static const card = Color(0xFFFFFFFF);
  static const navBg = Color(0xFFFFFFFF);

  static const good = Color(0xFF6EC4A7);
  static const goodBg = Color(0xFFE8F8F3);
  static const warn = Color(0xFFFFB347);
  static const warnBg = Color(0xFFFFF5E4);
  static const bad = Color(0xFFFF7B7B);
  static const badBg = Color(0xFFFFEEEE);
  static const neutral = Color(0xFFB0B8D0);
  static const neutralBg = Color(0xFFF0F4FF);

  static const primary = Color(0xFF7B9CFF);
  static const primaryLight = Color(0xFFEEF2FF);
  static const accent = Color(0xFFA78BFA);

  static const textDark = Color(0xFF2D3561);
  static const textMed = Color(0xFF6B7BA4);
  static const textLight = Color(0xFFB0B8D0);

  static const phColor = Color(0xFF7BC8FF);
  static const phBg = Color(0xFFE8F6FF);
  static const nh3Color = Color(0xFF98D8A8);
  static const nh3Bg = Color(0xFFEAF8EE);
  static const ntuColor = Color(0xFFFFD580);
  static const ntuBg = Color(0xFFFFF9E6);
  static const tdsColor = Color(0xFFD4A5F5);
  static const tdsBg = Color(0xFFF5EEFF);
}

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
class SensorLive {
  final double ph;
  final double nh3;
  final double ntu;
  final double tds;

  const SensorLive({
    this.ph = 0,
    this.nh3 = 0,
    this.ntu = 0,
    this.tds = 0,
  });

  factory SensorLive.fromJson(Map<dynamic, dynamic> j) => SensorLive(
        ph: _toDouble(j['ph']),
        nh3: _toDouble(j['nh3_ppm']),
        ntu: _toDouble(j['ntu']),
        tds: _toDouble(j['tds_ppm']),
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class HistoryItem {
  final double ph, nh3, ntu, tds;
  final String timestamp, unsafeReason;

  const HistoryItem({
    required this.ph,
    required this.nh3,
    required this.ntu,
    required this.tds,
    required this.timestamp,
    this.unsafeReason = '',
  });

  factory HistoryItem.fromJson(Map<dynamic, dynamic> j) => HistoryItem(
        ph: SensorLive._toDouble(j['ph']),
        nh3: SensorLive._toDouble(j['nh3_ppm']),
        ntu: SensorLive._toDouble(j['ntu']),
        tds: SensorLive._toDouble(j['tds_ppm']),
        timestamp: j['timestamp']?.toString() ?? '',
        unsafeReason: j['unsafe_reason']?.toString() ?? '',
      );
}

// ─────────────────────────────────────────────
//  STATUS HELPERS
// ─────────────────────────────────────────────
enum WaterStatus { good, warn, bad, loading }

extension WaterStatusX on WaterStatus {
  Color get color {
    switch (this) {
      case WaterStatus.good:
        return AppColors.good;
      case WaterStatus.warn:
        return AppColors.warn;
      case WaterStatus.bad:
        return AppColors.bad;
      case WaterStatus.loading:
        return AppColors.neutral;
    }
  }

  Color get bgColor {
    switch (this) {
      case WaterStatus.good:
        return AppColors.goodBg;
      case WaterStatus.warn:
        return AppColors.warnBg;
      case WaterStatus.bad:
        return AppColors.badBg;
      case WaterStatus.loading:
        return AppColors.neutralBg;
    }
  }

  String get label {
    switch (this) {
      case WaterStatus.good:
        return 'Baik';
      case WaterStatus.warn:
        return 'Waspada';
      case WaterStatus.bad:
        return 'Buruk';
      case WaterStatus.loading:
        return '—';
    }
  }

  String get emoji {
    switch (this) {
      case WaterStatus.good:
        return '✅';
      case WaterStatus.warn:
        return '⚠️';
      case WaterStatus.bad:
        return '🚨';
      case WaterStatus.loading:
        return '⏳';
    }
  }
}

WaterStatus phStatus(double v) {
  if (v >= 6.8 && v <= 8.0) return WaterStatus.good;
  if ((v >= 6.0 && v < 6.8) || (v > 8.0 && v <= 8.5)) return WaterStatus.warn;
  return WaterStatus.bad;
}

WaterStatus nh3Status(double v) {
  if (v >= 0 && v <= 0.02) return WaterStatus.good;
  if (v > 0.02 && v <= 0.05) return WaterStatus.warn;
  return WaterStatus.bad;
}

WaterStatus ntuStatus(double v) {
  if (v < 25) return WaterStatus.good;
  if (v <= 50) return WaterStatus.warn;
  return WaterStatus.bad;
}

WaterStatus tdsStatus(double v) {
  if (v >= 0 && v <= 300) return WaterStatus.good;
  if (v > 300 && v <= 500) return WaterStatus.warn;
  return WaterStatus.bad;
}

WaterStatus overallStatus(SensorLive s) {
  final statuses = [phStatus(s.ph), nh3Status(s.nh3), ntuStatus(s.ntu), tdsStatus(s.tds)];
  if (statuses.any((st) => st == WaterStatus.bad)) return WaterStatus.bad;
  if (statuses.any((st) => st == WaterStatus.warn)) return WaterStatus.warn;
  return WaterStatus.good;
}

// ─────────────────────────────────────────────
//  FIREBASE REST API SERVICE
// ─────────────────────────────────────────────
class FirebaseService {
  static Future<SensorLive?> fetchLive() async {
    try {
      final uri = Uri.parse('$_firebaseUrl/sensorData/live.json?auth=$_firebaseKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data != null && data is Map) return SensorLive.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<HistoryItem>> fetchHistory() async {
    try {
      final uri = Uri.parse(
          '$_firebaseUrl/sensorData/history.json?auth=$_firebaseKey&orderBy="\$key"&limitToLast=50');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data != null && data is Map) {
          final list = data.entries
              .map((e) => HistoryItem.fromJson(e.value as Map))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        }
      }
    } catch (_) {}
    return [];
  }
}

// ─────────────────────────────────────────────
//  RECOMMENDATION ENGINE
// ─────────────────────────────────────────────
List<Map<String, String>> buildRecommendations(SensorLive s) {
  final recs = <Map<String, String>>[];

  final ps = phStatus(s.ph);
  if (ps != WaterStatus.good) {
    recs.add({
      'param': 'pH',
      'value': s.ph.toStringAsFixed(2),
      'status': ps.label,
      'emoji': ps.emoji,
      'action': ps == WaterStatus.bad
          ? 'Segera lakukan pergantian air 30–50%. Jika terlalu asam, tambahkan kapur dolomit/oyster shell. Jika terlalu basa, gunakan daun ketapang.'
          : 'Kadar pH mulai tidak stabil. Periksa penumpukan kotoran di dasar kolam dan kurangi intensitas pemberian pakan.',
    });
  }

  final as = nh3Status(s.nh3);
  if (as != WaterStatus.good) {
    recs.add({
      'param': 'Amonia (NH₃)',
      'value': s.nh3.toStringAsFixed(4),
      'status': as.label,
      'emoji': as.emoji,
      'action': as == WaterStatus.bad
          ? 'Puasakan ikan koi sepenuhnya! Nyalakan aerator ke tingkat maksimal dan bersihkan ruang filtrasi biologis segera.'
          : 'Bakteri pengurai tidak bekerja maksimal. Tambahkan bakteri starter (probiotik) pada filter dan kurangi pakan harian.',
    });
  }

  final ns = ntuStatus(s.ntu);
  if (ns != WaterStatus.good) {
    recs.add({
      'param': 'Kekeruhan (NTU)',
      'value': s.ntu.toStringAsFixed(2),
      'status': ns.label,
      'emoji': ns.emoji,
      'action': ns == WaterStatus.bad
          ? 'Filter mekanik sudah penuh/buntu. Bersihkan japmat atau kapas filter. Kuras sedimen endapan di ruang pompa.'
          : 'Partikel kotoran melayang meningkat. Lakukan backwash pada filter kolam sedikit demi sedikit.',
    });
  }

  final ts = tdsStatus(s.tds);
  if (ts != WaterStatus.good) {
    recs.add({
      'param': 'Kadar Logam (TDS)',
      'value': s.tds.toStringAsFixed(2),
      'status': ts.label,
      'emoji': ts.emoji,
      'action': ts == WaterStatus.bad
          ? 'TDS sangat tinggi. Tambahkan air tawar bersih perlahan-lahan. Hindari obat-obatan kimia berlebih.'
          : 'Kadar zat terlarut mulai pekat. Pastikan sumber air tidak mengandung klorin atau logam berat berlebih.',
    });
  }

  return recs;
}

// ─────────────────────────────────────────────
//  MAIN
// ─────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MonikaApp());
}

class MonikaApp extends StatelessWidget {
  const MonikaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monika',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.water, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Monika',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Monitor Kualitas Air Kolam Koi',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMed,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN SHELL – Bottom Nav
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  SensorLive _live = const SensorLive();
  bool _liveLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLive();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchLive());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLive() async {
    final data = await FirebaseService.fetchLive();
    if (mounted && data != null) {
      setState(() {
        _live = data;
        _liveLoading = false;
      });
    } else if (mounted && _liveLoading) {
      setState(() => _liveLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      MonitoringTab(live: _live, isLoading: _liveLoading),
      TindakanTab(live: _live, isLoading: _liveLoading),
      const HistoryTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_tab), child: tabs[_tab]),
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
        live: _live,
        isLoading: _liveLoading,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAVIGATION BAR  (iOS style)
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.current,
    required this.onTap,
    required this.live,
    required this.isLoading,
  });
  final int current;
  final ValueChanged<int> onTap;
  final SensorLive live;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final overall = isLoading ? WaterStatus.loading : overallStatus(live);
    final items = [
      _NavItem(Icons.water_drop_outlined, Icons.water_drop, 'Monitor'),
      _NavItem(Icons.tips_and_updates_outlined, Icons.tips_and_updates, 'Tindakan'),
      _NavItem(Icons.history_outlined, Icons.history, 'Riwayat'),
    ];
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: bottomPadding > 0 ? 0 : 8,
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = current == i;
              Color iconColor = isActive ? AppColors.primary : AppColors.textLight;
              // Show status dot on monitor tab
              bool showDot = i == 0 && !isLoading;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primaryLight : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                color: iconColor,
                                size: 24,
                              ),
                            ),
                            if (showDot)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: overall.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ─────────────────────────────────────────────
//  TAB 1 – MONITORING
// ─────────────────────────────────────────────
class MonitoringTab extends StatelessWidget {
  const MonitoringTab({
    super.key,
    required this.live,
    required this.isLoading,
  });
  final SensorLive live;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final overall = isLoading ? WaterStatus.loading : overallStatus(live);
    final top = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, top + 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Monika',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _PulseDot(color: overall.color),
                            const SizedBox(width: 6),
                            Text(
                              isLoading ? 'Memuat…' : overall.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Monitor Kolam Koi Real-time',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Overall status card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              overall.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLoading
                                    ? 'Mengambil data…'
                                    : overall == WaterStatus.good
                                        ? 'Kondisi Air Optimal'
                                        : overall == WaterStatus.warn
                                            ? 'Perlu Perhatian'
                                            : 'Kondisi Kritis!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Update setiap 1 detik via Firebase',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              'Parameter Air',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── SENSOR CARDS ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SensorCard(
                        label: 'pH Air',
                        value: isLoading ? '…' : live.ph.toStringAsFixed(2),
                        unit: '',
                        status: isLoading ? WaterStatus.loading : phStatus(live.ph),
                        icon: Icons.science_outlined,
                        iconColor: AppColors.phColor,
                        bgColor: AppColors.phBg,
                        range: '6.8 – 8.0',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SensorCard(
                        label: 'Amonia',
                        value: isLoading ? '…' : live.nh3.toStringAsFixed(3),
                        unit: 'ppm',
                        status: isLoading ? WaterStatus.loading : nh3Status(live.nh3),
                        icon: Icons.bubble_chart_outlined,
                        iconColor: AppColors.nh3Color,
                        bgColor: AppColors.nh3Bg,
                        range: '≤ 0.020',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SensorCard(
                        label: 'Kekeruhan',
                        value: isLoading ? '…' : live.ntu.toStringAsFixed(1),
                        unit: 'NTU',
                        status: isLoading ? WaterStatus.loading : ntuStatus(live.ntu),
                        icon: Icons.opacity_outlined,
                        iconColor: AppColors.ntuColor,
                        bgColor: AppColors.ntuBg,
                        range: '< 25',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SensorCard(
                        label: 'TDS',
                        value: isLoading ? '…' : live.tds.toStringAsFixed(0),
                        unit: 'ppm',
                        status: isLoading ? WaterStatus.loading : tdsStatus(live.tds),
                        icon: Icons.filter_alt_outlined,
                        iconColor: AppColors.tdsColor,
                        bgColor: AppColors.tdsBg,
                        range: '100 – 300',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── RANGE LEGEND ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panduan Nilai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                _RangeCard(
                  label: 'pH',
                  baik: '6.8 – 8.0',
                  waspada: '6.0 – 6.7 | 8.1 – 8.5',
                  buruk: '< 6.0 atau > 8.5',
                  color: AppColors.phColor,
                ),
                _RangeCard(
                  label: 'Amonia (ppm)',
                  baik: '0 – 0.020',
                  waspada: '0.021 – 0.050',
                  buruk: '> 0.050',
                  color: AppColors.nh3Color,
                ),
                _RangeCard(
                  label: 'Kekeruhan (NTU)',
                  baik: '< 25',
                  waspada: '25 – 50',
                  buruk: '> 50',
                  color: AppColors.ntuColor,
                ),
                _RangeCard(
                  label: 'TDS (ppm)',
                  baik: '100 – 300',
                  waspada: '301 – 500',
                  buruk: '> 500',
                  color: AppColors.tdsColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SENSOR CARD WIDGET
// ─────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.range,
  });
  final String label, value, unit, range;
  final WaterStatus status;
  final IconData icon;
  final Color iconColor, bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -1,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ideal: $range',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RANGE CARD WIDGET
// ─────────────────────────────────────────────
class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.label,
    required this.baik,
    required this.waspada,
    required this.buruk,
    required this.color,
  });
  final String label, baik, waspada, buruk;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RangeRow(AppColors.good, '✓ $baik'),
                _RangeRow(AppColors.warn, '⚠ $waspada'),
                _RangeRow(AppColors.bad, '✗ $buruk'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow(this.color, this.text);
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PULSING DOT
// ─────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TAB 2 – TINDAKAN
// ─────────────────────────────────────────────
class TindakanTab extends StatelessWidget {
  const TindakanTab({super.key, required this.live, required this.isLoading});
  final SensorLive live;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final recs = isLoading ? <Map<String, String>>[] : buildRecommendations(live);
    final overall = isLoading ? WaterStatus.loading : overallStatus(live);
    final top = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7BC8FF),
                  const Color(0xFF98D8A8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, top + 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saran Tindakan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Rekomendasi berdasarkan data sensor',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(overall.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLoading
                                    ? 'Memuat data…'
                                    : recs.isEmpty
                                        ? 'Semua parameter normal!'
                                        : '${recs.length} parameter perlu perhatian',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                isLoading
                                    ? 'Mohon tunggu sebentar'
                                    : recs.isEmpty
                                        ? 'Tidak ada tindakan yang diperlukan'
                                        : 'Ikuti saran di bawah ini',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (recs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.goodBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.good.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      'Kondisi Kolam Sempurna!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Semua indikator kualitas air dalam kondisi BAIK. Pertahankan kondisi kolam Anda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMed,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: recs.map((r) => _RecommendationCard(rec: r)).toList(),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({required this.rec});
  final Map<String, String> rec;
  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isBad = widget.rec['status'] == 'Buruk';
    final borderColor = isBad ? AppColors.bad : AppColors.warn;
    final bgColor = isBad ? AppColors.badBg : AppColors.warnBg;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.rec['emoji']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.rec['param']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Nilai: ${widget.rec['value']}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textMed),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.rec['status']!,
                                style: TextStyle(
                                  color: borderColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.rec['action']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TAB 3 – HISTORY
// ─────────────────────────────────────────────
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<HistoryItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await FirebaseService.fetchHistory();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent, const Color(0xFFFFB347)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, top + 20, 24, 28),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Data kondisi air tersimpan',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.bad, size: 48),
                            const SizedBox(height: 12),
                            Text('Gagal memuat data',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _items.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 56, color: AppColors.textLight),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada data riwayat',
                                style: TextStyle(color: AppColors.textMed, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (_, i) =>
                              _HistoryCard(item: _items[i]),
                        ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final ps = phStatus(item.ph);
    final as = nh3Status(item.nh3);
    final ns = ntuStatus(item.ntu);
    final ts = tdsStatus(item.tds);
    final overall = [ps, as, ns, ts].contains(WaterStatus.bad)
        ? WaterStatus.bad
        : [ps, as, ns, ts].contains(WaterStatus.warn)
            ? WaterStatus.warn
            : WaterStatus.good;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: overall.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(overall.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      overall.label,
                      style: TextStyle(
                        color: overall.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                item.timestamp,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HistoryParam('pH', item.ph.toStringAsFixed(2), ps),
              _HistoryParam('NH₃', '${item.nh3.toStringAsFixed(3)}ppm', as),
              _HistoryParam('NTU', item.ntu.toStringAsFixed(1), ns),
              _HistoryParam('TDS', '${item.tds.toStringAsFixed(0)}ppm', ts),
            ],
          ),
          if (item.unsafeReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warnBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.unsafeReason,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMed, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryParam extends StatelessWidget {
  const _HistoryParam(this.label, this.value, this.status);
  final String label, value;
  final WaterStatus status;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}