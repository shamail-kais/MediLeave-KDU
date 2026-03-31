import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class ApiConfig {
  // Android emulator → 10.0.2.2 | iOS simulator / web → localhost
  static const String baseUrl = kIsWeb
      ? 'http://localhost:8181/api'
      : 'http://10.0.2.2:8181/api';
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole { student, medicalOfficer, departmentReviewer, admin, unknown }

UserRole parseRole(String? r) {
  switch ((r ?? '').toUpperCase()) {
    case 'ROLE_STUDENT': return UserRole.student;
    case 'ROLE_MEDICAL_OFFICER': return UserRole.medicalOfficer;
    case 'ROLE_DEPARTMENT_REVIEWER': return UserRole.departmentReviewer;
    case 'ROLE_ADMIN': return UserRole.admin;
    default: return UserRole.unknown;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class AuthResponse {
  final String token;
  final int userId;
  final String fullName;
  final String email;
  final UserRole role;

  AuthResponse({required this.token, required this.userId,
      required this.fullName, required this.email, required this.role});

  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
    token: j['token'] ?? '',
    userId: j['userId'] ?? 0,
    fullName: j['fullName'] ?? '',
    email: j['email'] ?? '',
    role: parseRole(j['role']),
  );
}

class Department {
  final int id;
  final String name;
  final String? faculty;
  Department({required this.id, required this.name, this.faculty});
  factory Department.fromJson(Map<String, dynamic> j) =>
      Department(id: j['id'], name: j['name'] ?? '', faculty: j['faculty']);
}

class UserResponse {
  final int id;
  final String fullName;
  final String email;
  final String? registrationNo;
  final String role;
  final String? departmentName;
  final String? faculty;

  UserResponse({required this.id, required this.fullName, required this.email,
      this.registrationNo, required this.role, this.departmentName, this.faculty});

  factory UserResponse.fromJson(Map<String, dynamic> j) => UserResponse(
    id: j['id'],
    fullName: j['fullName'] ?? '',
    email: j['email'] ?? '',
    registrationNo: j['registrationNo'],
    role: j['role'] ?? '',
    departmentName: j['departmentName'],
    faculty: j['faculty'],
  );
}

class LeaveRequest {
  final int id;
  final int studentId;
  final String studentName;
  final String registrationNo;
  final String? departmentName;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String reason;
  final String status;
  final String? medicalComment;
  final String? departmentComment;
  final String? finalComment;
  final String submittedAt;
  final String? updatedAt;
  final List<String> documents;

  LeaveRequest({
    required this.id, required this.studentId, required this.studentName,
    required this.registrationNo, this.departmentName, required this.leaveType,
    required this.startDate, required this.endDate, required this.totalDays,
    required this.reason, required this.status, this.medicalComment,
    this.departmentComment, this.finalComment, required this.submittedAt,
    this.updatedAt, required this.documents,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
    id: j['id'] ?? 0,
    studentId: j['studentId'] ?? 0,
    studentName: j['studentName'] ?? '',
    registrationNo: j['registrationNo'] ?? '',
    departmentName: j['departmentName'],
    leaveType: j['leaveType'] ?? '',
    startDate: (j['startDate'] ?? '').toString(),
    endDate: (j['endDate'] ?? '').toString(),
    totalDays: j['totalDays'] ?? 0,
    reason: j['reason'] ?? '',
    status: j['status'] ?? '',
    medicalComment: j['medicalComment'],
    departmentComment: j['departmentComment'],
    finalComment: j['finalComment'],
    submittedAt: (j['submittedAt'] ?? '').toString(),
    updatedAt: (j['updatedAt'])?.toString(),
    documents: (j['documents'] as List?)?.map((e) => e.toString()).toList() ?? [],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class Api {
  static String? _token;
  static void setToken(String t) => _token = t;
  static void clearToken() => _token = null;

  static Map<String, String> get _h => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
  static Map<String, String> get _ah => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Exception _err(http.Response r) {
    try {
      final b = jsonDecode(r.body);
      return Exception(b['message'] ?? b['error'] ?? 'Error ${r.statusCode}');
    } catch (_) { return Exception('Error ${r.statusCode}'); }
  }

  // AUTH
  static Future<AuthResponse> login(String email, String password) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}));
    if (r.statusCode == 200) return AuthResponse.fromJson(jsonDecode(r.body));
    throw _err(r);
  }

  static Future<void> register({required String fullName, required String email,
      required String password, required String registrationNo,
      required int departmentId}) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fullName': fullName, 'email': email, 'password': password,
        'registrationNo': registrationNo, 'departmentId': departmentId}));
    if (r.statusCode != 200) throw _err(r);
  }

  // STUDENT
  static Future<UserResponse> getProfile() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/student/me'), headers: _h);
    if (r.statusCode == 200) return UserResponse.fromJson(jsonDecode(r.body));
    throw _err(r);
  }

  static Future<List<LeaveRequest>> getMyLeaves() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/student/leave-requests'), headers: _h);
    if (r.statusCode == 200)
      return (jsonDecode(r.body) as List).map((e) => LeaveRequest.fromJson(e)).toList();
    throw _err(r);
  }

  static Future<LeaveRequest> submitLeave({
    required String leaveType, required String startDate,
    required String endDate, required String reason}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/student/leave-requests');
    final req = http.MultipartRequest('POST', uri)..headers.addAll(_ah);
    req.fields['leaveType'] = leaveType;
    req.fields['startDate'] = startDate;
    req.fields['endDate'] = endDate;
    req.fields['reason'] = reason;
    final s = await req.send();
    final r = await http.Response.fromStream(s);
    if (r.statusCode == 200) return LeaveRequest.fromJson(jsonDecode(r.body));
    throw _err(r);
  }

  // MEDICAL
  static Future<List<LeaveRequest>> getMedicalQueue() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/medical/requests'), headers: _h);
    if (r.statusCode == 200)
      return (jsonDecode(r.body) as List).map((e) => LeaveRequest.fromJson(e)).toList();
    throw _err(r);
  }

  static Future<List<LeaveRequest>> getMedicalHistory() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/medical/requests/history'), headers: _h);
    if (r.statusCode == 200)
      return (jsonDecode(r.body) as List).map((e) => LeaveRequest.fromJson(e)).toList();
    throw _err(r);
  }

  static Future<LeaveRequest> medicalVerify(int id, String comment) async {
    final r = await http.put(Uri.parse('${ApiConfig.baseUrl}/medical/requests/$id/verify'),
      headers: _h, body: jsonEncode({'comment': comment}));
    if (r.statusCode == 200) return LeaveRequest.fromJson(jsonDecode(r.body));
    throw _err(r);
  }

  static Future<LeaveRequest> medicalReject(int id, String comment) async {
    final r = await http.put(Uri.parse('${ApiConfig.baseUrl}/medical/requests/$id/reject'),
      headers: _h, body: jsonEncode({'comment': comment}));
    if (r.statusCode == 200) return LeaveRequest.fromJson(jsonDecode(r.body));
    throw _err(r);
  }

  // DEPARTMENT
  static Future<List<LeaveRequest>> getDeptQueue() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/department/requests'), headers: _h);
    if (r.statusCode == 200)
      return (jsonDecode(r.body) as List).map((e) => LeaveRequest.fromJson(e)).toList();
    throw _err(r);
  }

  static Future<List<LeaveRequest>> getDeptHistory() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/department/requests/history'), headers: _h);
    if (r.statusCode == 200)
      return (jsonDecode(r.body) as List).map((e) => LeaveRequest.fromJson(e)).toList();
    throw _err(r);
  }

  static Future<LeaveRequest> deptApprove(int id, String comment) async {
    final r = await http.put(Uri.parse('${ApiConfig.baseUrl}/department/requests/$id/approve'),
      headers: _h, body: jsonEncode({'comment': comment}));
    if (r.statusCode == 200) return LeaveRequest.fromJson(jsonDecode(r.body));
    throw _err(r);
  }

  static Future<LeaveRequest> deptReject(int id, String comment) async {
    final r = await http.put(Uri.parse('${ApiConfig.baseUrl}/department/requests/$id/reject'),
      headers: _h, body: jsonEncode({'comment': comment}));
    if (r.statusCode == 200) return LeaveRequest.fromJson(jsonDecode(r.body));
    throw _err(r);
  }

  // ADMIN
  static Future<List<Department>> getDepartments() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/departments'), headers: _h);
    if (r.statusCode == 200)
      return (jsonDecode(r.body) as List).map((e) => Department.fromJson(e)).toList();
    throw _err(r);
  }

  static Future<Department> createDepartment(String name, String faculty) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/departments'),
      headers: _h, body: jsonEncode({'name': name, 'faculty': faculty}));
    if (r.statusCode == 200) return Department.fromJson(jsonDecode(r.body));
    throw _err(r);
  }

  static Future<List<UserResponse>> getAllUsers() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/users'), headers: _h);
    if (r.statusCode == 200)
      return (jsonDecode(r.body) as List).map((e) => UserResponse.fromJson(e)).toList();
    throw _err(r);
  }

  static Future<List<LeaveRequest>> getAllRequests() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/requests'), headers: _h);
    if (r.statusCode == 200)
      return (jsonDecode(r.body) as List).map((e) => LeaveRequest.fromJson(e)).toList();
    throw _err(r);
  }

  static Future<void> createStaff({required String fullName, required String email,
      required String password, required String role, required int departmentId}) async {
    final r = await http.post(Uri.parse('${ApiConfig.baseUrl}/admin/staff'),
      headers: _h,
      body: jsonEncode({'fullName': fullName, 'email': email, 'password': password,
        'role': role, 'departmentId': departmentId}));
    if (r.statusCode != 200) throw _err(r);
  }

  // Public departments (for register, no auth needed)
  static Future<List<Department>> getPublicDepts() async {
    try {
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/departments'),
        headers: {'Content-Type': 'application/json'});
      if (r.statusCode == 200)
        return (jsonDecode(r.body) as List).map((e) => Department.fromJson(e)).toList();
    } catch (_) {}
    return [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────────────────────────────────────────

class AuthState extends ChangeNotifier {
  AuthResponse? _session;
  bool loading = false;
  String? error;

  AuthResponse? get session => _session;
  bool get loggedIn => _session != null;
  String? get token => _session?.token;
  UserRole get role => _session?.role ?? UserRole.unknown;
  String get name => _session?.fullName ?? '';
  String get email => _session?.email ?? '';

  Future<void> login(String email, String password) async {
    loading = true; error = null; notifyListeners();
    try {
      _session = await Api.login(email.trim(), password);
      Api.setToken(_session!.token);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally { loading = false; notifyListeners(); }
  }

  void logout() {
    _session = null; error = null;
    Api.clearToken();
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────

const _blue = Color(0xFF246BEB);
const _blueDark = Color(0xFF1A50B8);
const _blueSoft = Color(0xFFEAF1FF);
const _green = Color(0xFF17B26A);
const _greenSoft = Color(0xFFDDF7E8);
const _red = Color(0xFFE11D48);
const _redSoft = Color(0xFFFFE1E7);
const _amber = Color(0xFFF59E0B);
const _amberSoft = Color(0xFFFFF8E1);
const _ink = Color(0xFF101828);
const _muted = Color(0xFF667085);
const _light = Color(0xFFF6F8FC);
const _border = Color(0xFFE8EEF7);

Color statusFg(String s) {
  switch (s.toUpperCase()) {
    case 'APPROVED': return _green;
    case 'SUBMITTED': return _blue;
    case 'MEDICALLY_VERIFIED': return const Color(0xFF0E9F6E);
    case 'MEDICALLY_REJECTED': return _red;
    case 'REJECTED': return _red;
    case 'CANCELLED': return _muted;
    default: return _amber;
  }
}
Color statusBg(String s) => statusFg(s).withOpacity(0.10);
String statusLabel(String s) {
  switch (s.toUpperCase()) {
    case 'SUBMITTED': return 'Submitted';
    case 'MEDICALLY_VERIFIED': return 'Med. Verified';
    case 'MEDICALLY_REJECTED': return 'Med. Rejected';
    case 'APPROVED': return 'Approved';
    case 'REJECTED': return 'Rejected';
    case 'CANCELLED': return 'Cancelled';
    default: return s;
  }
}
String leaveLabel(String t) {
  switch (t) {
    case 'MEDICAL_LEAVE': return 'Medical Leave';
    case 'SHORT_MEDICAL_LEAVE': return 'Short Medical';
    case 'EXAM_MEDICAL_LEAVE': return 'Exam Medical';
    case 'OTHER': return 'Other';
    default: return t;
  }
}
String roleLabel(String r) {
  switch (r.toUpperCase()) {
    case 'ROLE_STUDENT': return 'Student';
    case 'ROLE_MEDICAL_OFFICER': return 'Medical Officer';
    case 'ROLE_DEPARTMENT_REVIEWER': return 'Dept. Reviewer';
    case 'ROLE_ADMIN': return 'Admin';
    default: return r;
  }
}

ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: _light,
  colorScheme: ColorScheme.fromSeed(seedColor: _blue, brightness: Brightness.light),
  cardTheme: CardThemeData(
    color: Colors.white, elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: _border)),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _blue, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _red)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
    backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white, foregroundColor: _ink, elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
);

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill(this.status, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: statusBg(status), borderRadius: BorderRadius.circular(20)),
    child: Text(statusLabel(status),
      style: TextStyle(color: statusFg(status), fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 52, color: _muted.withOpacity(0.4)),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: _muted), textAlign: TextAlign.center),
      ])));
}

class ErrBox extends StatelessWidget {
  final String msg;
  const ErrBox(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _redSoft, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _red.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: _red, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: _red, fontSize: 13))),
    ]));
}

class SuccessBox extends StatelessWidget {
  final String msg;
  const SuccessBox(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _greenSoft, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _green.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.check_circle_outline, color: _green, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: _green, fontSize: 13))),
    ]));
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? action;
  const SectionTitle(this.text, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
    if (action != null) action!,
  ]);
}

Future<String?> commentDialog(BuildContext ctx, {required String title, required String actionLabel, required Color actionColor}) async {
  final ctrl = TextEditingController();
  return showDialog<String>(context: ctx, builder: (c) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Comment is required', style: TextStyle(color: _muted, fontSize: 13)),
      const SizedBox(height: 10),
      TextField(controller: ctrl, maxLines: 3,
        decoration: const InputDecoration(hintText: 'Enter your comment...')),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: actionColor),
        onPressed: () { if (ctrl.text.trim().isNotEmpty) Navigator.pop(c, ctrl.text.trim()); },
        child: Text(actionLabel)),
    ],
  ));
}

class LeaveCard extends StatelessWidget {
  final LeaveRequest r;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  const LeaveCard({super.key, required this.r, this.onTap, this.actions});

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: _blueSoft, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.medical_services_outlined, color: _blue, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(leaveLabel(r.leaveType),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
              if (r.studentName.isNotEmpty)
                Text(r.studentName, style: const TextStyle(fontSize: 12, color: _muted)),
            ])),
            StatusPill(r.status),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: _muted),
            const SizedBox(width: 5),
            Text('${r.startDate} → ${r.endDate}',
              style: const TextStyle(fontSize: 13, color: _muted)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _blueSoft, borderRadius: BorderRadius.circular(8)),
              child: Text('${r.totalDays}d', style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 6),
          Text(r.reason, style: const TextStyle(fontSize: 13, color: _muted),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end,
              children: actions!.map((a) => Padding(
                padding: const EdgeInsets.only(left: 8), child: a)).toList()),
          ],
        ],
      )),
    ),
  );
}

class StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const StatCard({super.key, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
    ]),
  );
}

class ActionBtn extends StatelessWidget {
  final String label; final Color color; final IconData icon; final VoidCallback onTap;
  const ActionBtn({super.key, required this.label, required this.color, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// CHART WIDGETS (custom painted — no external packages)
// ─────────────────────────────────────────────────────────────────────────────

// Bar chart item
class _BarItem {
  final String label;
  final int value;
  final Color color;
  const _BarItem(this.label, this.value, this.color);
}

// Custom bar chart painter
class _BarChartPainter extends CustomPainter {
  final List<_BarItem> items;
  final int maxVal;
  _BarChartPainter(this.items, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty || maxVal == 0) return;
    final barW = (size.width / items.length) * 0.55;
    final gap = (size.width / items.length) * 0.45;
    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final chartH = size.height - 32;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final x = i * (barW + gap) + gap / 2;
      final barH = (item.value / maxVal) * chartH;
      final top = chartH - barH;

      // Bar with rounded top
      paint.color = item.color;
      final rr = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top, barW, barH),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6));
      canvas.drawRRect(rr, paint);

      // Value label on top
      textPainter.text = TextSpan(
        text: '${item.value}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: item.color));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + barW / 2 - textPainter.width / 2, top - 16));

      // X label below
      textPainter.text = TextSpan(
        text: item.label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF667085), fontWeight: FontWeight.w600));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + barW / 2 - textPainter.width / 2, chartH + 6));
    }
  }

  @override bool shouldRepaint(_BarChartPainter old) => true;
}

class _BarChart extends StatelessWidget {
  final List<_BarItem> items;
  final double height;
  const _BarChart({required this.items, this.height = 160});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _BarChartPainter(items, maxVal == 0 ? 1 : maxVal),
        size: Size.infinite,
      ),
    );
  }
}

// Donut / pie chart
class _PieSlice {
  final String label;
  final int value;
  final Color color;
  const _PieSlice(this.label, this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_PieSlice> slices;
  final int total;
  _DonutPainter(this.slices, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;
    final paint = Paint()..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.38
      ..strokeCap = StrokeCap.butt;

    double startAngle = -1.5708; // -pi/2 start from top
    for (final s in slices) {
      final sweep = (s.value / total) * 6.2832;
      paint.color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }
  }

  @override bool shouldRepaint(_DonutPainter old) => true;
}

class _DonutChart extends StatelessWidget {
  final List<_PieSlice> slices;
  final String centerLabel;
  final String centerSub;
  const _DonutChart({required this.slices, required this.centerLabel, required this.centerSub});

  @override
  Widget build(BuildContext context) {
    final total = slices.fold(0, (s, e) => s + e.value);
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(width: 110, height: 110,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(painter: _DonutPainter(slices, total == 0 ? 1 : total),
            size: const Size(110, 110)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(centerLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
            Text(centerSub, style: const TextStyle(fontSize: 11, color: _muted)),
          ]),
        ])),
      const SizedBox(width: 20),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: slices.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 10, height: 10,
              decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text(s.label,
              style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w500))),
            Text('${s.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: s.color)),
            const SizedBox(width: 4),
            Text(total > 0 ? '(${(s.value / total * 100).round()}%)' : '',
              style: const TextStyle(fontSize: 11, color: _muted)),
          ]),
        )).toList(),
      )),
    ]);
  }
}

// Horizontal progress bar
class _HBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _HBar({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink))),
          Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.toDouble(), minHeight: 8,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color))),
      ]),
    );
  }
}

// Dashboard card container
class _DashCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _DashCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: const TextStyle(fontSize: 12, color: _muted)),
        ],
        const SizedBox(height: 16),
        child,
      ],
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class StudentDashboardPage extends StatelessWidget {
  final AuthState auth;
  final List<LeaveRequest> leaves;
  final bool loading;
  const StudentDashboardPage({required this.auth, required this.leaves, required this.loading});

  @override
  Widget build(BuildContext context) {
    // Compute from real data
    final total = leaves.length;
    final approved = leaves.where((e) => e.status == 'APPROVED').length;
    final pending = leaves.where((e) =>
      e.status == 'SUBMITTED' || e.status == 'MEDICALLY_VERIFIED').length;
    final medVerified = leaves.where((e) => e.status == 'MEDICALLY_VERIFIED').length;
    final rejected = leaves.where((e) =>
      e.status == 'REJECTED' || e.status == 'MEDICALLY_REJECTED').length;
    final submitted = leaves.where((e) => e.status == 'SUBMITTED').length;

    // Leave type breakdown from real data
    final typeCount = <String, int>{};
    for (final l in leaves) {
      typeCount[l.leaveType] = (typeCount[l.leaveType] ?? 0) + 1;
    }

    // Monthly trend from submittedAt
    final monthCount = <String, int>{};
    for (final l in leaves) {
      if (l.submittedAt.length >= 7) {
        final month = l.submittedAt.substring(0, 7); // "2024-03"
        monthCount[month] = (monthCount[month] ?? 0) + 1;
      }
    }
    final sortedMonths = monthCount.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6
      ? sortedMonths.sublist(sortedMonths.length - 6)
      : sortedMonths;

    if (loading) return const Center(child: CircularProgressIndicator());

    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
      // Greeting
      Row(children: [
        CircleAvatar(radius: 22, backgroundColor: _blueSoft,
          child: Text(auth.name.isNotEmpty ? auth.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.w900, color: _blue, fontSize: 18))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dashboard', style: TextStyle(fontSize: 12, color: _muted)),
          Text(auth.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
        ])),
      ]),
      const SizedBox(height: 20),

      // KPI row
      Row(children: [
        Expanded(child: StatCard(label: 'Total', value: '$total', color: _blue)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Approved', value: '$approved', color: _green)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Pending', value: '$pending', color: _amber)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Rejected', value: '$rejected', color: _red)),
      ]),
      const SizedBox(height: 16),

      // Status donut chart
      if (total > 0) ...[
        _DashCard(
          title: 'Status Breakdown',
          subtitle: 'All your leave requests by status',
          child: _DonutChart(
            centerLabel: '$total',
            centerSub: 'Total',
            slices: [
              if (approved > 0) _PieSlice('Approved', approved, _green),
              if (submitted > 0) _PieSlice('Submitted', submitted, _blue),
              if (medVerified > 0) _PieSlice('Med. Verified', medVerified, const Color(0xFF0E9F6E)),
              if (rejected > 0) _PieSlice('Rejected', rejected, _red),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],

      // Leave type bar chart
      if (typeCount.isNotEmpty) ...[
        _DashCard(
          title: 'Leave Types',
          subtitle: 'Breakdown by leave category',
          child: _BarChart(items: [
            if (typeCount['MEDICAL_LEAVE'] != null)
              _BarItem('Medical', typeCount['MEDICAL_LEAVE']!, _blue),
            if (typeCount['SHORT_MEDICAL_LEAVE'] != null)
              _BarItem('Short', typeCount['SHORT_MEDICAL_LEAVE']!, const Color(0xFF6366F1)),
            if (typeCount['EXAM_MEDICAL_LEAVE'] != null)
              _BarItem('Exam', typeCount['EXAM_MEDICAL_LEAVE']!, _amber),
            if (typeCount['OTHER'] != null)
              _BarItem('Other', typeCount['OTHER']!, _muted),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      // Monthly trend bar chart
      if (recentMonths.isNotEmpty) ...[
        _DashCard(
          title: 'Monthly Trend',
          subtitle: 'Requests submitted per month',
          child: _BarChart(
            height: 140,
            items: recentMonths.map((m) {
              final parts = m.split('-');
              final label = parts.length == 2
                ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
                    [int.parse(parts[1]) - 1]
                : m;
              return _BarItem(label, monthCount[m]!, _blue);
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
      ],

      // Status progress bars
      if (total > 0)
        _DashCard(
          title: 'Progress Overview',
          subtitle: 'How your requests are progressing',
          child: Column(children: [
            _HBar(label: 'Approved', value: approved, total: total, color: _green),
            _HBar(label: 'Pending Review', value: pending, total: total, color: _amber),
            _HBar(label: 'Rejected', value: rejected, total: total, color: _red),
          ]),
        ),

      if (total == 0)
        const EmptyState('No leave data yet.\nSubmit your first leave request to see analytics.'),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDICAL OFFICER DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class MedicalDashboardPage extends StatefulWidget {
  final AuthState auth;
  final List<LeaveRequest> pending;
  const MedicalDashboardPage({required this.auth, required this.pending});
  @override State<MedicalDashboardPage> createState() => _MedicalDashboardPageState();
}

class _MedicalDashboardPageState extends State<MedicalDashboardPage> {
  List<LeaveRequest> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _history = await Api.getMedicalHistory(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final allReviewed = _history.length;
    final verified = _history.where((e) => e.status == 'MEDICALLY_VERIFIED').length;
    final rejected = _history.where((e) => e.status == 'MEDICALLY_REJECTED').length;
    final pendingCount = widget.pending.length;

    // Leave type in pending queue
    final typeCount = <String, int>{};
    for (final l in [...widget.pending, ..._history]) {
      typeCount[l.leaveType] = (typeCount[l.leaveType] ?? 0) + 1;
    }

    // Monthly reviewed trend
    final monthCount = <String, int>{};
    for (final l in _history) {
      if (l.updatedAt != null && l.updatedAt!.length >= 7) {
        final m = l.updatedAt!.substring(0, 7);
        monthCount[m] = (monthCount[m] ?? 0) + 1;
      }
    }
    final sortedMonths = monthCount.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6
      ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
        Row(children: [
          CircleAvatar(radius: 22, backgroundColor: const Color(0xFFDDF7EE),
            child: Text(widget.auth.name.isNotEmpty ? widget.auth.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w900, color: _green, fontSize: 18))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Medical Officer Dashboard', style: TextStyle(fontSize: 12, color: _muted)),
            Text(widget.auth.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ])),
        ]),
        const SizedBox(height: 20),

        // KPI row
        Row(children: [
          Expanded(child: StatCard(label: 'Pending', value: '$pendingCount', color: _amber)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Verified', value: '$verified', color: _green)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Rejected', value: '$rejected', color: _red)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Reviewed', value: '$allReviewed', color: _blue)),
        ]),
        const SizedBox(height: 16),

        // Verified vs rejected donut
        if (allReviewed > 0) ...[
          _DashCard(
            title: 'Review Decisions',
            subtitle: 'Medically verified vs rejected',
            child: _DonutChart(
              centerLabel: '$allReviewed',
              centerSub: 'Reviewed',
              slices: [
                if (verified > 0) _PieSlice('Verified', verified, _green),
                if (rejected > 0) _PieSlice('Rejected', rejected, _red),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Leave types across all
        if (typeCount.isNotEmpty) ...[
          _DashCard(
            title: 'Leave Types Received',
            subtitle: 'All submissions by type',
            child: _BarChart(items: [
              if (typeCount['MEDICAL_LEAVE'] != null)
                _BarItem('Medical', typeCount['MEDICAL_LEAVE']!, _blue),
              if (typeCount['SHORT_MEDICAL_LEAVE'] != null)
                _BarItem('Short', typeCount['SHORT_MEDICAL_LEAVE']!, const Color(0xFF6366F1)),
              if (typeCount['EXAM_MEDICAL_LEAVE'] != null)
                _BarItem('Exam', typeCount['EXAM_MEDICAL_LEAVE']!, _amber),
              if (typeCount['OTHER'] != null)
                _BarItem('Other', typeCount['OTHER']!, _muted),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // Monthly review trend
        if (recentMonths.isNotEmpty) ...[
          _DashCard(
            title: 'Monthly Review Activity',
            subtitle: 'Requests reviewed per month',
            child: _BarChart(
              height: 140,
              items: recentMonths.map((m) {
                final parts = m.split('-');
                final label = parts.length == 2
                  ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
                      [int.parse(parts[1]) - 1]
                  : m;
                return _BarItem(label, monthCount[m]!, _green);
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Decision rate progress
        if (allReviewed > 0)
          _DashCard(
            title: 'Decision Rate',
            subtitle: 'Out of all reviewed requests',
            child: Column(children: [
              _HBar(label: 'Verified & Forwarded', value: verified, total: allReviewed, color: _green),
              _HBar(label: 'Medically Rejected', value: rejected, total: allReviewed, color: _red),
            ]),
          ),

        if (allReviewed == 0 && pendingCount == 0)
          const EmptyState('No data yet. Start reviewing requests to see analytics.'),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEPARTMENT REVIEWER DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class DeptDashboardPage extends StatelessWidget {
  final AuthState auth;
  final List<LeaveRequest> pending;
  final List<LeaveRequest> history;
  const DeptDashboardPage({required this.auth, required this.pending,
      required this.history});

  @override
  Widget build(BuildContext context) {
    final allProcessed = history.length;
    final approved = history.where((e) => e.status == 'APPROVED').length;
    final rejected = history.where((e) => e.status == 'REJECTED').length;
    final pendingCount = pending.length;

    final typeCount = <String, int>{};
    for (final l in [...pending, ...history]) {
      typeCount[l.leaveType] = (typeCount[l.leaveType] ?? 0) + 1;
    }

    final deptCount = <String, int>{};
    for (final l in history) {
      final d = l.departmentName ?? 'Unknown';
      deptCount[d] = (deptCount[d] ?? 0) + 1;
    }

    final monthCount = <String, int>{};
    for (final l in history) {
      final dt = l.updatedAt ?? l.submittedAt;
      if (dt.length >= 7) {
        final m = dt.substring(0, 7);
        monthCount[m] = (monthCount[m] ?? 0) + 1;
      }
    }
    final sortedMonths = monthCount.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];

    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
      Row(children: [
        CircleAvatar(radius: 22, backgroundColor: _blueSoft,
          child: Text(auth.name.isNotEmpty ? auth.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.w900, color: _blue, fontSize: 18))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dept. Reviewer Dashboard', style: TextStyle(fontSize: 12, color: _muted)),
          Text(auth.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ])),
      ]),
      const SizedBox(height: 20),

      Row(children: [
        Expanded(child: StatCard(label: 'Pending', value: '$pendingCount', color: _amber)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Approved', value: '$approved', color: _green)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Rejected', value: '$rejected', color: _red)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Total', value: '${pendingCount + allProcessed}', color: _blue)),
      ]),
      const SizedBox(height: 16),

      if (allProcessed > 0) ...[
        _DashCard(
          title: 'Final Decisions',
          subtitle: 'Approved vs rejected by department',
          child: _DonutChart(
            centerLabel: '$allProcessed',
            centerSub: 'Processed',
            slices: [
              if (approved > 0) _PieSlice('Approved', approved, _green),
              if (rejected > 0) _PieSlice('Rejected', rejected, _red),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],

      if (typeCount.isNotEmpty) ...[
        _DashCard(
          title: 'Leave Types Processed',
          subtitle: 'Breakdown by leave category',
          child: _BarChart(items: [
            if ((typeCount['MEDICAL_LEAVE'] ?? 0) > 0)
              _BarItem('Medical', typeCount['MEDICAL_LEAVE']!, _blue),
            if ((typeCount['SHORT_MEDICAL_LEAVE'] ?? 0) > 0)
              _BarItem('Short', typeCount['SHORT_MEDICAL_LEAVE']!, const Color(0xFF6366F1)),
            if ((typeCount['EXAM_MEDICAL_LEAVE'] ?? 0) > 0)
              _BarItem('Exam', typeCount['EXAM_MEDICAL_LEAVE']!, _amber),
            if ((typeCount['OTHER'] ?? 0) > 0)
              _BarItem('Other', typeCount['OTHER']!, _muted),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      if (deptCount.length > 1) ...[
        _DashCard(
          title: 'Requests by Student Department',
          subtitle: 'Which departments submit most leaves',
          child: Column(
            children: (deptCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
              .take(6)
              .map((e) => _HBar(label: e.key, value: e.value,
                  total: allProcessed == 0 ? 1 : allProcessed, color: _blue))
              .toList(),
          ),
        ),
        const SizedBox(height: 14),
      ],

      if (recentMonths.isNotEmpty) ...[
        _DashCard(
          title: 'Monthly Decision Trend',
          subtitle: 'Requests processed per month',
          child: _BarChart(
            height: 140,
            items: recentMonths.map((m) {
              final parts = m.split('-');
              final label = parts.length == 2
                  ? months[int.parse(parts[1]) - 1] : m;
              return _BarItem(label, monthCount[m]!, _blue);
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
      ],

      if (allProcessed > 0)
        _DashCard(
          title: 'Decision Rate',
          subtitle: 'Out of all processed requests',
          child: Column(children: [
            _HBar(label: 'Approved', value: approved,
                total: allProcessed, color: _green),
            _HBar(label: 'Rejected', value: rejected,
                total: allProcessed, color: _red),
          ]),
        ),

      if (allProcessed == 0 && pendingCount == 0)
        const EmptyState('No data yet. Process requests to see analytics.'),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEPARTMENT REVIEWER
// ─────────────────────────────────────────────────────────────────────────────

class DeptShell extends StatefulWidget {
  final AuthState auth;
  const DeptShell({super.key, required this.auth});
  @override State<DeptShell> createState() => _DeptShellState();
}

class _DeptShellState extends State<DeptShell> {
  int _tab = 0;
  List<LeaveRequest> _pending = [];
  List<LeaveRequest> _history = [];
  bool _loadingP = true, _loadingH = true;

  @override
  void initState() { super.initState(); _loadPending(); _loadHistory(); }

  Future<void> _loadPending() async {
    setState(() => _loadingP = true);
    try { _pending = await Api.getDeptQueue(); } catch (_) {}
    if (mounted) setState(() => _loadingP = false);
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingH = true);
    try { _history = await Api.getDeptHistory(); } catch (_) {}
    if (mounted) setState(() => _loadingH = false);
  }

  Future<void> _loadAll() async =>
      Future.wait([_loadPending(), _loadHistory()]);

  Future<void> _act(LeaveRequest r, bool approve) async {
    final comment = await commentDialog(context,
      title: approve ? 'Approve Request' : 'Reject Request',
      actionLabel: approve ? 'Approve' : 'Reject',
      actionColor: approve ? _green : _red);
    if (comment == null) return;
    try {
      approve
          ? await Api.deptApprove(r.id, comment)
          : await Api.deptReject(r.id, comment);
      await _loadAll();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? 'Approved!' : 'Rejected'),
        backgroundColor: approve ? _green : _red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final approvedCount = _history.where((r) => r.status == 'APPROVED').length;
    final rejectedCount = _history.where((r) => r.status == 'REJECTED').length;

    final pages = [
      // 0 — Dashboard
      DeptDashboardPage(auth: widget.auth, pending: _pending, history: _history),

      // 1 — Pending queue
      Scaffold(
        appBar: AppBar(title: const Text('Pending Approval'),
            automaticallyImplyLeading: false),
        body: RefreshIndicator(
          onRefresh: _loadPending,
          child: _loadingP
            ? const Center(child: CircularProgressIndicator())
            : _pending.isEmpty
              ? const EmptyState('No requests awaiting your approval.')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final r = _pending[i];
                    return LeaveCard(r: r,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LeaveDetailScreen(request: r))),
                      actions: [
                        ActionBtn(label: 'Reject', color: _red,
                            icon: Icons.close_rounded, onTap: () => _act(r, false)),
                        ActionBtn(label: 'Approve', color: _green,
                            icon: Icons.check_circle_rounded, onTap: () => _act(r, true)),
                      ]);
                  }),
        ),
      ),

      // 2 — History
      Scaffold(
        appBar: AppBar(title: const Text('Decision History'),
            automaticallyImplyLeading: false),
        body: RefreshIndicator(
          onRefresh: _loadHistory,
          child: _loadingH
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                if (_history.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(children: [
                      Expanded(child: StatCard(label: 'Approved',
                          value: '$approvedCount', color: _green)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(label: 'Rejected',
                          value: '$rejectedCount', color: _red)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(label: 'Total',
                          value: '${_history.length}', color: _blue)),
                    ]),
                  ),
                Expanded(
                  child: _history.isEmpty
                    ? const EmptyState('No processed requests yet.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => LeaveCard(
                          r: _history[i],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => LeaveDetailScreen(request: _history[i]))),
                        )),
                ),
              ]),
        ),
      ),

      // 3 — Me
      _RoleProfilePage(auth: widget.auth, roleLabel: 'Department Reviewer',
          roleColor: _blue, onLogout: widget.auth.logout),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        height: 68, backgroundColor: Colors.white,
        selectedIndex: _tab, indicatorColor: _blueSoft,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pending.isNotEmpty,
              label: Text('${_pending.length}'),
              child: const Icon(Icons.pending_actions_outlined)),
            selectedIcon: Badge(
              isLabelVisible: _pending.isNotEmpty,
              label: Text('${_pending.length}'),
              child: const Icon(Icons.pending_actions_rounded)),
            label: 'Pending'),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History'),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Me'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardPage extends StatelessWidget {
  final AuthState auth;
  final List<LeaveRequest> requests;
  final List<UserResponse> users;
  final List<Department> departments;
  const AdminDashboardPage({required this.auth, required this.requests,
      required this.users, required this.departments});

  @override
  Widget build(BuildContext context) {
    final total = requests.length;
    final approved = requests.where((e) => e.status == 'APPROVED').length;
    final submitted = requests.where((e) => e.status == 'SUBMITTED').length;
    final medVerified = requests.where((e) => e.status == 'MEDICALLY_VERIFIED').length;
    final medRejected = requests.where((e) => e.status == 'MEDICALLY_REJECTED').length;
    final rejected = requests.where((e) => e.status == 'REJECTED').length;

    // User role distribution
    final roleCount = <String, int>{};
    for (final u in users) {
      roleCount[u.role] = (roleCount[u.role] ?? 0) + 1;
    }

    // Leave type distribution
    final typeCount = <String, int>{};
    for (final r in requests) {
      typeCount[r.leaveType] = (typeCount[r.leaveType] ?? 0) + 1;
    }

    // Department-wise leave count from requests
    final deptCount = <String, int>{};
    for (final r in requests) {
      final d = r.departmentName ?? 'Unknown';
      deptCount[d] = (deptCount[d] ?? 0) + 1;
    }

    // Monthly submission trend
    final monthCount = <String, int>{};
    for (final r in requests) {
      if (r.submittedAt.length >= 7) {
        final m = r.submittedAt.substring(0, 7);
        monthCount[m] = (monthCount[m] ?? 0) + 1;
      }
    }
    final sortedMonths = monthCount.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6
      ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

    final students = roleCount['ROLE_STUDENT'] ?? 0;
    final medOfficers = roleCount['ROLE_MEDICAL_OFFICER'] ?? 0;
    final deptReviewers = roleCount['ROLE_DEPARTMENT_REVIEWER'] ?? 0;
    final admins = roleCount['ROLE_ADMIN'] ?? 0;

    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
      Row(children: [
        CircleAvatar(radius: 22, backgroundColor: const Color(0xFFF3E8FF),
          child: Text(auth.name.isNotEmpty ? auth.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.w900,
              color: Color(0xFF9333EA), fontSize: 18))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Admin Dashboard', style: TextStyle(fontSize: 12, color: _muted)),
          Text(auth.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ])),
      ]),
      const SizedBox(height: 20),

      // System KPIs
      Row(children: [
        Expanded(child: StatCard(label: 'Requests', value: '$total', color: _blue)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Users', value: '${users.length}', color: const Color(0xFF9333EA))),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Depts', value: '${departments.length}', color: _amber)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Approved', value: '$approved', color: _green)),
      ]),
      const SizedBox(height: 16),

      // Full status funnel donut
      if (total > 0) ...[
        _DashCard(
          title: 'System-wide Status Overview',
          subtitle: 'All leave requests by current status',
          child: _DonutChart(
            centerLabel: '$total',
            centerSub: 'Total',
            slices: [
              if (approved > 0) _PieSlice('Approved', approved, _green),
              if (submitted > 0) _PieSlice('Submitted', submitted, _blue),
              if (medVerified > 0) _PieSlice('Med. Verified', medVerified, const Color(0xFF0E9F6E)),
              if (medRejected > 0) _PieSlice('Med. Rejected', medRejected, const Color(0xFFFF6B35)),
              if (rejected > 0) _PieSlice('Rejected', rejected, _red),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],

      // User role distribution
      if (users.isNotEmpty) ...[
        _DashCard(
          title: 'User Roles Distribution',
          subtitle: 'System users by role',
          child: _BarChart(items: [
            if (students > 0) _BarItem('Students', students, _blue),
            if (medOfficers > 0) _BarItem('Medical', medOfficers, _green),
            if (deptReviewers > 0) _BarItem('Dept.Rev', deptReviewers, _amber),
            if (admins > 0) _BarItem('Admins', admins, const Color(0xFF9333EA)),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      // Department-wise leave requests
      if (deptCount.isNotEmpty) ...[
        _DashCard(
          title: 'Requests by Department',
          subtitle: 'Which departments have most leave activity',
          child: Column(
            children: (deptCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
              .take(6)
              .map((e) => _HBar(
                label: e.key, value: e.value,
                total: total == 0 ? 1 : total, color: _blue))
              .toList(),
          ),
        ),
        const SizedBox(height: 14),
      ],

      // Leave type distribution
      if (typeCount.isNotEmpty) ...[
        _DashCard(
          title: 'Leave Type Breakdown',
          subtitle: 'System-wide leave categories',
          child: _BarChart(items: [
            if (typeCount['MEDICAL_LEAVE'] != null)
              _BarItem('Medical', typeCount['MEDICAL_LEAVE']!, _blue),
            if (typeCount['SHORT_MEDICAL_LEAVE'] != null)
              _BarItem('Short', typeCount['SHORT_MEDICAL_LEAVE']!, const Color(0xFF6366F1)),
            if (typeCount['EXAM_MEDICAL_LEAVE'] != null)
              _BarItem('Exam', typeCount['EXAM_MEDICAL_LEAVE']!, _amber),
            if (typeCount['OTHER'] != null)
              _BarItem('Other', typeCount['OTHER']!, _muted),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      // Monthly submission trend
      if (recentMonths.isNotEmpty) ...[
        _DashCard(
          title: 'Monthly Submission Trend',
          subtitle: 'Leave requests submitted per month',
          child: _BarChart(
            height: 140,
            items: recentMonths.map((m) {
              final parts = m.split('-');
              final label = parts.length == 2
                ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
                    [int.parse(parts[1]) - 1]
                : m;
              return _BarItem(label, monthCount[m]!, _blue);
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
      ],

      // Status pipeline progress bars
      if (total > 0)
        _DashCard(
          title: 'Pipeline Health',
          subtitle: 'System-wide request flow',
          child: Column(children: [
            _HBar(label: 'Awaiting Medical Review', value: submitted, total: total, color: _blue),
            _HBar(label: 'Awaiting Dept. Approval', value: medVerified, total: total, color: const Color(0xFF0E9F6E)),
            _HBar(label: 'Finally Approved', value: approved, total: total, color: _green),
            _HBar(label: 'Rejected (any stage)', value: medRejected + rejected, total: total, color: _red),
          ]),
        ),

      if (total == 0 && users.isEmpty)
        const EmptyState('No system data yet.'),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────────────────────────────────────

void main() => runApp(const MediLeaveApp());

class MediLeaveApp extends StatefulWidget {
  const MediLeaveApp({super.key});
  @override State<MediLeaveApp> createState() => _MediLeaveAppState();
}

class _MediLeaveAppState extends State<MediLeaveApp> {
  final _auth = AuthState();
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _auth,
    builder: (_, __) => MaterialApp(
      title: 'MediLeave', theme: appTheme, debugShowCheckedModeBanner: false,
      home: _auth.loggedIn ? _RoleRouter(auth: _auth) : LoginScreen(auth: _auth),
    ),
  );
}

class _RoleRouter extends StatelessWidget {
  final AuthState auth;
  const _RoleRouter({required this.auth});
  @override
  Widget build(BuildContext context) {
    switch (auth.role) {
      case UserRole.student: return StudentShell(auth: auth);
      case UserRole.medicalOfficer: return MedicalShell(auth: auth);
      case UserRole.departmentReviewer: return DeptShell(auth: auth);
      case UserRole.admin: return AdminShell(auth: auth);
      default: return _UnknownRole(auth: auth);
    }
  }
}

class _UnknownRole extends StatelessWidget {
  final AuthState auth;
  const _UnknownRole({required this.auth});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, size: 56, color: _red),
      const SizedBox(height: 16),
      const Text('Unknown role', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 24),
      FilledButton(onPressed: auth.logout, child: const Text('Back to Login')),
    ],
  )));
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final AuthState auth;
  const LoginScreen({super.key, required this.auth});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obs = true;

  @override
  Widget build(BuildContext context) {
    final a = widget.auth;
    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header
            Container(padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_blue, Color(0xFF4FA3FF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: _blue.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 26, backgroundColor: Colors.white24,
                  child: Icon(Icons.medical_services_outlined, color: Colors.white, size: 26)),
                SizedBox(height: 16),
                Text('MediLeave', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Medical leave management system',
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
              ])),
            const SizedBox(height: 24),
            // Card
            Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Sign In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Access your role-based dashboard', style: TextStyle(color: _muted, fontSize: 14)),
                const SizedBox(height: 20),
                if (a.error != null) ErrBox(a.error!),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded))),
                const SizedBox(height: 14),
                TextField(controller: _pass, obscureText: _obs,
                  decoration: InputDecoration(labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obs ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obs = !_obs)))),
                const SizedBox(height: 18),
                SizedBox(height: 54, child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: a.loading ? null : () => a.login(_email.text, _pass.text),
                  child: a.loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                )),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account?", style: TextStyle(color: _muted)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RegisterScreen())),
                    child: const Text('Register', style: TextStyle(color: _blue, fontWeight: FontWeight.w700))),
                ]),
              ],
            ))),
          ]),
        ),
      ))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REGISTER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _reg = TextEditingController();
  bool _obs = true, _loading = false;
  String? _error, _success;
  List<Department> _depts = [];
  Department? _dept;

  @override
  void initState() { super.initState(); _loadDepts(); }

  Future<void> _loadDepts() async {
    final d = await Api.getPublicDepts();
    setState(() => _depts = d);
  }

  Future<void> _submit() async {
    if (_dept == null) { setState(() => _error = 'Select a department'); return; }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await Api.register(fullName: _name.text.trim(), email: _email.text.trim(),
        password: _pass.text, registrationNo: _reg.text.trim(), departmentId: _dept!.id);
      setState(() => _success = 'Registered! Please login.');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Account')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Student Registration',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Fill in your details to register', style: TextStyle(color: _muted, fontSize: 14)),
        const SizedBox(height: 24),
        if (_error != null) ErrBox(_error!),
        if (_success != null) SuccessBox(_success!),
        TextField(controller: _name,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 14),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded))),
        const SizedBox(height: 14),
        TextField(controller: _reg,
          decoration: const InputDecoration(labelText: 'Registration No.', prefixIcon: Icon(Icons.badge_outlined))),
        const SizedBox(height: 14),
        DropdownButtonFormField<Department>(
          value: _dept,
          decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
          items: _depts.map((d) => DropdownMenuItem(value: d,
            child: Text('${d.name}${d.faculty != null ? " (${d.faculty})" : ""}'))).toList(),
          onChanged: (v) => setState(() => _dept = v),
        ),
        const SizedBox(height: 14),
        TextField(controller: _pass, obscureText: _obs,
          decoration: InputDecoration(labelText: 'Password (min 6 chars)',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obs ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obs = !_obs)))),
        const SizedBox(height: 28),
        SizedBox(height: 54, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _loading ? null : _submit,
          child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        )),
      ],
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT
// ─────────────────────────────────────────────────────────────────────────────

class StudentShell extends StatefulWidget {
  final AuthState auth;
  const StudentShell({super.key, required this.auth});
  @override State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _tab = 0;
  List<LeaveRequest> _leaves = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _leaves = await Api.getMyLeaves(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentDashboardPage(auth: widget.auth, leaves: _leaves, loading: _loading),
      _StudentHome(auth: widget.auth, leaves: _leaves, loading: _loading, onRefresh: _load),
      _StudentHistory(leaves: _leaves, loading: _loading),
      _ApplyLeave(auth: widget.auth, onSuccess: _load),
      _StudentProfile(auth: widget.auth),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        height: 68, backgroundColor: Colors.white, selectedIndex: _tab,
        indicatorColor: _blueSoft,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), selectedIcon: Icon(Icons.add_circle_rounded), label: 'Apply'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StudentHome extends StatelessWidget {
  final AuthState auth;
  final List<LeaveRequest> leaves;
  final bool loading;
  final Future<void> Function() onRefresh;
  const _StudentHome({required this.auth, required this.leaves, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final approved = leaves.where((e) => e.status == 'APPROVED').length;
    final pending = leaves.where((e) => e.status == 'SUBMITTED' || e.status == 'MEDICALLY_VERIFIED').length;
    final rejected = leaves.where((e) => e.status == 'REJECTED' || e.status == 'MEDICALLY_REJECTED').length;

    return RefreshIndicator(onRefresh: onRefresh, child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Welcome back,', style: TextStyle(color: _muted, fontSize: 14)),
            Text(auth.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
          ])),
          IconButton(onPressed: auth.logout, icon: const Icon(Icons.logout_rounded, color: _muted)),
        ]),
        const SizedBox(height: 20),
        // Stats
        Row(children: [
          Expanded(child: StatCard(label: 'Total', value: '${leaves.length}', color: _blue)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Approved', value: '$approved', color: _green)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Pending', value: '$pending', color: _amber)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Rejected', value: '$rejected', color: _red)),
        ]),
        const SizedBox(height: 24),
        SectionTitle('Recent Requests', action: leaves.isNotEmpty
          ? TextButton(onPressed: () {}, child: const Text('View all'))
          : null),
        const SizedBox(height: 12),
        if (loading) const Center(child: CircularProgressIndicator())
        else if (leaves.isEmpty) const EmptyState('No leave requests yet.\nTap Apply to submit one.')
        else ...leaves.take(5).map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LeaveCard(r: r),
        )),
      ],
    ));
  }
}

class _StudentHistory extends StatefulWidget {
  final List<LeaveRequest> leaves;
  final bool loading;
  const _StudentHistory({required this.leaves, required this.loading});
  @override State<_StudentHistory> createState() => _StudentHistoryState();
}

class _StudentHistoryState extends State<_StudentHistory> {
  String _filter = 'ALL';
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final q = _search.text.toLowerCase();
    final filtered = widget.leaves.where((r) {
      final matchQ = r.leaveType.toLowerCase().contains(q) || r.reason.toLowerCase().contains(q);
      final matchF = _filter == 'ALL' || r.status.contains(_filter);
      return matchQ && matchF;
    }).toList();

    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
      const Text('Leave History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      TextField(controller: _search, onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search_rounded))),
      const SizedBox(height: 14),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
        children: ['ALL', 'SUBMITTED', 'MEDICALLY_VERIFIED', 'APPROVED', 'REJECTED'].map((f) {
          final sel = _filter == f;
          final label = f == 'ALL' ? 'All' : statusLabel(f);
          return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? _blue : Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _blue : _border)),
              child: Text(label, style: TextStyle(
                color: sel ? Colors.white : _ink, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ));
        }).toList(),
      )),
      const SizedBox(height: 16),
      if (widget.loading) const Center(child: CircularProgressIndicator())
      else if (filtered.isEmpty) EmptyState(_filter == 'ALL' ? 'No leaves found.' : 'No ${statusLabel(_filter)} requests.')
      else ...filtered.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LeaveCard(r: r, onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => LeaveDetailScreen(request: r)))),
      )),
    ]);
  }
}

class _ApplyLeave extends StatefulWidget {
  final AuthState auth;
  final Future<void> Function() onSuccess;
  const _ApplyLeave({required this.auth, required this.onSuccess});
  @override State<_ApplyLeave> createState() => _ApplyLeaveState();
}

class _ApplyLeaveState extends State<_ApplyLeave> {
  // Backend enum values exactly
  static const _types = [
    ('MEDICAL_LEAVE', 'Medical Leave'),
    ('SHORT_MEDICAL_LEAVE', 'Short Medical Leave'),
    ('EXAM_MEDICAL_LEAVE', 'Exam Medical Leave'),
    ('OTHER', 'Other'),
  ];
  String _type = 'MEDICAL_LEAVE';
  DateTime? _start, _end;
  final _reason = TextEditingController();
  bool _loading = false;
  String? _error, _success;

  String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!));
    if (picked == null) return;
    setState(() { isStart ? _start = picked : _end = picked; });
  }

  Future<void> _submit() async {
    if (_start == null || _end == null) { setState(() => _error = 'Select start and end dates'); return; }
    if (_end!.isBefore(_start!)) { setState(() => _error = 'End date must be after start date'); return; }
    if (_reason.text.trim().isEmpty) { setState(() => _error = 'Reason is required'); return; }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await Api.submitLeave(leaveType: _type, startDate: _fmt(_start!),
        endDate: _fmt(_end!), reason: _reason.text.trim());
      setState(() => _success = 'Leave request submitted successfully!');
      _reason.clear(); _start = null; _end = null; _type = 'MEDICAL_LEAVE';
      await widget.onSuccess();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: [
      const Text('Apply for Leave', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      const Text('Submit a new medical leave request', style: TextStyle(color: _muted, fontSize: 14)),
      const SizedBox(height: 20),
      if (_error != null) ErrBox(_error!),
      if (_success != null) SuccessBox(_success!),
      const Text('Leave Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 8),
      Card(child: Column(children: _types.map((t) => RadioListTile<String>(
        value: t.$1, groupValue: _type,
        onChanged: (v) => setState(() => _type = v!),
        title: Text(t.$2, style: const TextStyle(fontSize: 14)),
        activeColor: _blue, dense: true,
      )).toList())),
      const SizedBox(height: 18),
      const Text('Leave Period', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _DateBtn(label: 'Start Date', date: _start, onTap: () => _pickDate(true))),
        const SizedBox(width: 12),
        Expanded(child: _DateBtn(label: 'End Date', date: _end, onTap: () => _pickDate(false))),
      ]),
      if (_start != null && _end != null && !_end!.isBefore(_start!))
        Padding(padding: const EdgeInsets.only(top: 8),
          child: Text('${_end!.difference(_start!).inDays + 1} day(s) selected',
            style: const TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13))),
      const SizedBox(height: 18),
      const Text('Reason', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 8),
      TextField(controller: _reason, maxLines: 4,
        decoration: const InputDecoration(hintText: 'Describe your medical condition...')),
      const SizedBox(height: 28),
      SizedBox(height: 54, child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: _loading ? null : _submit,
        child: _loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      )),
    ],
  );
}

class _DateBtn extends StatelessWidget {
  final String label; final DateTime? date; final VoidCallback onTap;
  const _DateBtn({required this.label, this.date, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border)),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 16, color: _blue),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
          Text(date == null ? 'Select' : '${date!.day}/${date!.month}/${date!.year}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: date == null ? _muted : _ink)),
        ]),
      ]),
    ),
  );
}

class _StudentProfile extends StatelessWidget {
  final AuthState auth;
  const _StudentProfile({required this.auth});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: [
      const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 20),
      Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        CircleAvatar(radius: 36, backgroundColor: _blueSoft,
          child: Text(auth.name.isNotEmpty ? auth.name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _blue))),
        const SizedBox(height: 12),
        Text(auth.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(auth.email, style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 20),
        _PRow(icon: Icons.badge_outlined, label: 'Role', value: 'Student'),
        _PRow(icon: Icons.email_outlined, label: 'Email', value: auth.email),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: _red,
              side: const BorderSide(color: _red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: auth.logout,
            icon: const Icon(Icons.logout_rounded), label: const Text('Logout'))),
      ]))),
    ],
  );
}

class _PRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _PRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      CircleAvatar(radius: 18, backgroundColor: _light,
        child: Icon(icon, size: 16, color: _muted)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ])),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LEAVE DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LeaveDetailScreen extends StatelessWidget {
  final LeaveRequest request;
  const LeaveDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Detail')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero banner
          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_blue, Color(0xFF4FA3FF)]),
              borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(leaveLabel(r.leaveType),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('${r.startDate} → ${r.endDate} · ${r.totalDays} day(s)',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              StatusPill(r.status),
            ])),
          const SizedBox(height: 16),
          _Section('Leave Details', [
            _DRow('Leave Type', leaveLabel(r.leaveType)),
            _DRow('Department', r.departmentName ?? '-'),
            _DRow('Start Date', r.startDate),
            _DRow('End Date', r.endDate),
            _DRow('Total Days', '${r.totalDays}'),
            _DRow('Submitted', r.submittedAt.split('T').first),
          ]),
          const SizedBox(height: 12),
          _Section('Reason', [
            Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(r.reason, style: const TextStyle(fontSize: 14, height: 1.5))),
          ]),
          if (r.medicalComment != null || r.departmentComment != null) ...[
            const SizedBox(height: 12),
            _Section('Review Comments', [
              if (r.medicalComment != null) _Comment('Medical Officer', r.medicalComment!, _green),
              if (r.departmentComment != null) _Comment('Department', r.departmentComment!, _blue),
              if (r.finalComment != null) _Comment('Final Decision', r.finalComment!, _ink),
            ]),
          ],
        ],
      )),
    );
  }
}

class _Section extends StatelessWidget {
  final String title; final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) => Card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(16,14,16,8),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _muted))),
      const Divider(color: _border, height: 1),
      ...children,
    ],
  ));
}

class _DRow extends StatelessWidget {
  final String l, v;
  const _DRow(this.l, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      SizedBox(width: 100, child: Text(l, style: const TextStyle(color: _muted, fontSize: 13))),
      Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
    ]),
  );
}

class _Comment extends StatelessWidget {
  final String label, text; final Color color;
  const _Comment(this.label, this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
      border: Border(left: BorderSide(color: color, width: 3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4),
      Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// MEDICAL OFFICER
// ─────────────────────────────────────────────────────────────────────────────

class MedicalShell extends StatefulWidget {
  final AuthState auth;
  const MedicalShell({super.key, required this.auth});
  @override State<MedicalShell> createState() => _MedicalShellState();
}

class _MedicalShellState extends State<MedicalShell> {
  int _tab = 0;
  List<LeaveRequest> _pending = [];
  List<LeaveRequest> _history = [];
  bool _loadingP = true, _loadingH = true;

  @override
  void initState() { super.initState(); _loadPending(); _loadHistory(); }

  Future<void> _loadPending() async {
    setState(() => _loadingP = true);
    try { _pending = await Api.getMedicalQueue(); } catch (_) {}
    if (mounted) setState(() => _loadingP = false);
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingH = true);
    try { _history = await Api.getMedicalHistory(); } catch (_) {}
    if (mounted) setState(() => _loadingH = false);
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadPending(), _loadHistory()]);
  }

  Future<void> _act(LeaveRequest r, bool verify) async {
    final comment = await commentDialog(context,
      title: verify ? 'Medically Verify' : 'Reject Medically',
      actionLabel: verify ? 'Verify' : 'Reject',
      actionColor: verify ? _green : _red);
    if (comment == null) return;
    try {
      verify
        ? await Api.medicalVerify(r.id, comment)
        : await Api.medicalReject(r.id, comment);
      await _loadAll();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(verify ? 'Verified successfully' : 'Rejected'),
        backgroundColor: verify ? _green : _red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // 0 — Dashboard
      _MedicalDashPage(auth: widget.auth, pending: _pending, history: _history,
          onRefresh: _loadAll),
      // 1 — Pending queue
      _MedicalPendingPage(items: _pending, loading: _loadingP,
          onRefresh: _loadPending, onAct: _act),
      // 2 — History (verified + rejected by this officer)
      _MedicalHistoryPage(history: _history, loading: _loadingH,
          onRefresh: _loadHistory),
      // 3 — Profile / Me
      _RoleProfilePage(auth: widget.auth, roleLabel: 'Medical Officer',
          roleColor: _green, onLogout: widget.auth.logout),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        height: 68, backgroundColor: Colors.white, selectedIndex: _tab,
        indicatorColor: _blueSoft,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pending.isNotEmpty,
              label: Text('${_pending.length}'),
              child: const Icon(Icons.fact_check_outlined)),
            selectedIcon: Badge(
              isLabelVisible: _pending.isNotEmpty,
              label: Text('${_pending.length}'),
              child: const Icon(Icons.fact_check_rounded)),
            label: 'Queue'),
          const NavigationDestination(icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded), label: 'History'),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded), label: 'Me'),
        ],
      ),
    );
  }
}

// Medical Dashboard page — reads real data from both pending + history
class _MedicalDashPage extends StatelessWidget {
  final AuthState auth;
  final List<LeaveRequest> pending;
  final List<LeaveRequest> history;
  final Future<void> Function() onRefresh;
  const _MedicalDashPage({required this.auth, required this.pending,
      required this.history, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final allReviewed = history.length;
    final verified  = history.where((e) => e.status == 'MEDICALLY_VERIFIED').length;
    final rejected  = history.where((e) => e.status == 'MEDICALLY_REJECTED').length;
    final pendingCount = pending.length;

    // Leave type counts across pending + history
    final typeCount = <String, int>{};
    for (final l in [...pending, ...history]) {
      typeCount[l.leaveType] = (typeCount[l.leaveType] ?? 0) + 1;
    }

    // Monthly reviewed trend from updatedAt in history
    final monthCount = <String, int>{};
    for (final l in history) {
      final dt = l.updatedAt ?? l.submittedAt;
      if (dt.length >= 7) {
        final m = dt.substring(0, 7);
        monthCount[m] = (monthCount[m] ?? 0) + 1;
      }
    }
    final sortedMonths = monthCount.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
        // Header
        Row(children: [
          CircleAvatar(radius: 22, backgroundColor: const Color(0xFFDDF7EE),
            child: Text(auth.name.isNotEmpty ? auth.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w900, color: _green, fontSize: 18))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Medical Officer', style: TextStyle(fontSize: 12, color: _muted)),
            Text(auth.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ])),
        ]),
        const SizedBox(height: 20),

        // KPI cards
        Row(children: [
          Expanded(child: StatCard(label: 'Pending', value: '$pendingCount', color: _amber)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Verified', value: '$verified', color: _green)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Rejected', value: '$rejected', color: _red)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Reviewed', value: '$allReviewed', color: _blue)),
        ]),
        const SizedBox(height: 16),

        // Donut — verified vs rejected
        if (allReviewed > 0) ...[
          _DashCard(
            title: 'Review Decisions',
            subtitle: 'Medically verified vs rejected',
            child: _DonutChart(
              centerLabel: '$allReviewed',
              centerSub: 'Reviewed',
              slices: [
                if (verified > 0) _PieSlice('Verified', verified, _green),
                if (rejected > 0) _PieSlice('Rejected', rejected, _red),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Bar — leave types
        if (typeCount.isNotEmpty) ...[
          _DashCard(
            title: 'Leave Types Received',
            subtitle: 'All submissions by category',
            child: _BarChart(items: [
              if ((typeCount['MEDICAL_LEAVE'] ?? 0) > 0)
                _BarItem('Medical', typeCount['MEDICAL_LEAVE']!, _blue),
              if ((typeCount['SHORT_MEDICAL_LEAVE'] ?? 0) > 0)
                _BarItem('Short', typeCount['SHORT_MEDICAL_LEAVE']!, const Color(0xFF6366F1)),
              if ((typeCount['EXAM_MEDICAL_LEAVE'] ?? 0) > 0)
                _BarItem('Exam', typeCount['EXAM_MEDICAL_LEAVE']!, _amber),
              if ((typeCount['OTHER'] ?? 0) > 0)
                _BarItem('Other', typeCount['OTHER']!, _muted),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // Bar — monthly trend
        if (recentMonths.isNotEmpty) ...[
          _DashCard(
            title: 'Monthly Review Activity',
            subtitle: 'Requests reviewed per month',
            child: _BarChart(
              height: 140,
              items: recentMonths.map((m) {
                final parts = m.split('-');
                final label = parts.length == 2
                    ? months[int.parse(parts[1]) - 1] : m;
                return _BarItem(label, monthCount[m]!, _green);
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Progress bars — decision rate
        if (allReviewed > 0)
          _DashCard(
            title: 'Decision Rate',
            subtitle: 'Out of all reviewed requests',
            child: Column(children: [
              _HBar(label: 'Verified & Forwarded', value: verified,
                  total: allReviewed, color: _green),
              _HBar(label: 'Medically Rejected', value: rejected,
                  total: allReviewed, color: _red),
            ]),
          ),

        if (allReviewed == 0 && pendingCount == 0)
          const EmptyState('No data yet. Start reviewing to see analytics.'),
      ]),
    );
  }
}

// Medical pending queue page
class _MedicalPendingPage extends StatelessWidget {
  final List<LeaveRequest> items;
  final bool loading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(LeaveRequest, bool) onAct;
  const _MedicalPendingPage({required this.items, required this.loading,
      required this.onRefresh, required this.onAct});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review Queue'), automaticallyImplyLeading: false),
    body: RefreshIndicator(
      onRefresh: onRefresh,
      child: loading
        ? const Center(child: CircularProgressIndicator())
        : items.isEmpty
          ? const EmptyState('No submitted requests awaiting medical review.')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final r = items[i];
                return LeaveCard(r: r,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LeaveDetailScreen(request: r))),
                  actions: [
                    ActionBtn(label: 'Reject', color: _red, icon: Icons.close_rounded,
                        onTap: () => onAct(r, false)),
                    ActionBtn(label: 'Verify', color: _green, icon: Icons.verified_rounded,
                        onTap: () => onAct(r, true)),
                  ]);
              }),
    ),
  );
}

// Medical history page — shows verified + rejected by this officer
class _MedicalHistoryPage extends StatelessWidget {
  final List<LeaveRequest> history;
  final bool loading;
  final Future<void> Function() onRefresh;
  const _MedicalHistoryPage({required this.history, required this.loading,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final verified = history.where((e) => e.status == 'MEDICALLY_VERIFIED').length;
    final rejected = history.where((e) => e.status == 'MEDICALLY_REJECTED').length;
    return Scaffold(
      appBar: AppBar(title: const Text('Review History'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (history.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: [
                    Expanded(child: StatCard(label: 'Verified', value: '$verified', color: _green)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Rejected', value: '$rejected', color: _red)),
                    const SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Total', value: '${history.length}', color: _blue)),
                  ]),
                ),
              Expanded(
                child: history.isEmpty
                  ? const EmptyState('No reviewed requests yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => LeaveCard(
                        r: history[i],
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => LeaveDetailScreen(request: history[i]))),
                      )),
              ),
            ]),
      ),
    );
  }
}


// Shared profile page for Medical, Dept, Admin roles
class _RoleProfilePage extends StatelessWidget {
  final AuthState auth;
  final String roleLabel;
  final Color roleColor;
  final VoidCallback onLogout;
  const _RoleProfilePage({required this.auth, required this.roleLabel,
      required this.roleColor, required this.onLogout});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Profile'), automaticallyImplyLeading: false),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
      Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        CircleAvatar(radius: 40,
          backgroundColor: roleColor.withOpacity(0.12),
          child: Text(
            auth.name.isNotEmpty ? auth.name[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: roleColor))),
        const SizedBox(height: 14),
        Text(auth.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 4),
        Text(auth.email, style: const TextStyle(fontSize: 14, color: _muted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20)),
          child: Text(roleLabel,
            style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 13))),
        const SizedBox(height: 24),
        const Divider(color: _border),
        const SizedBox(height: 16),
        _PRow(icon: Icons.badge_outlined, label: 'Role', value: roleLabel),
        _PRow(icon: Icons.email_outlined, label: 'Email', value: auth.email),
        _PRow(icon: Icons.verified_user_outlined, label: 'Status', value: 'Active'),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: _red,
              side: const BorderSide(color: _red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)))),
      ]))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN
// ─────────────────────────────────────────────────────────────────────────────

class AdminShell extends StatefulWidget {
  final AuthState auth;
  const AdminShell({super.key, required this.auth});
  @override State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<UserResponse> _users = [];
  List<Department> _depts = [];
  List<LeaveRequest> _requests = [];
  bool _loadingU = true, _loadingD = true, _loadingR = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override void dispose() { _tabs.dispose(); super.dispose(); }

  void _loadAll() { _loadUsers(); _loadDepts(); _loadRequests(); }

  Future<void> _loadUsers() async {
    setState(() => _loadingU = true);
    try { _users = await Api.getAllUsers(); } catch (_) {}
    if (mounted) setState(() => _loadingU = false);
  }
  Future<void> _loadDepts() async {
    setState(() => _loadingD = true);
    try { _depts = await Api.getDepartments(); } catch (_) {}
    if (mounted) setState(() => _loadingD = false);
  }
  Future<void> _loadRequests() async {
    setState(() => _loadingR = true);
    try { _requests = await Api.getAllRequests(); } catch (_) {}
    if (mounted) setState(() => _loadingR = false);
  }

  int _bottomTab = 0;

  // Pages indexed by bottom nav
  // 0=Dashboard 1=Users 2=Depts 3=Requests 4=Me
  Widget _buildDashboard() => RefreshIndicator(
    onRefresh: () async => _loadAll(),
    child: AdminDashboardPage(auth: widget.auth, requests: _requests,
        users: _users, departments: _depts));

  Widget _buildUsers() => Scaffold(
    appBar: AppBar(title: const Text('Users'), automaticallyImplyLeading: false,
      actions: [IconButton(
        icon: const Icon(Icons.person_add_rounded),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => _CreateStaffScreen(depts: _depts)));
          _loadUsers();
        })]),
    body: RefreshIndicator(onRefresh: _loadUsers, child: _loadingU
      ? const Center(child: CircularProgressIndicator())
      : _users.isEmpty ? const EmptyState('No users.')
      : ListView.separated(padding: const EdgeInsets.all(20),
          itemCount: _users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _UserCard(user: _users[i]))));

  Widget _buildDepts() => Scaffold(
    appBar: AppBar(title: const Text('Departments'), automaticallyImplyLeading: false,
      actions: [IconButton(
        icon: const Icon(Icons.add_business_rounded),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const _CreateDeptScreen()));
          _loadDepts();
        })]),
    body: RefreshIndicator(onRefresh: _loadDepts, child: _loadingD
      ? const Center(child: CircularProgressIndicator())
      : _depts.isEmpty ? const EmptyState('No departments.')
      : ListView.separated(padding: const EdgeInsets.all(20),
          itemCount: _depts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final d = _depts[i];
            return Card(child: ListTile(
              leading: Container(width: 42, height: 42,
                decoration: BoxDecoration(color: _blueSoft,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.business_rounded, color: _blue)),
              title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: d.faculty != null ? Text(d.faculty!) : null));
          })));

  Widget _buildRequests() => Scaffold(
    appBar: AppBar(title: const Text('All Requests'), automaticallyImplyLeading: false),
    body: RefreshIndicator(onRefresh: _loadRequests, child: _loadingR
      ? const Center(child: CircularProgressIndicator())
      : _requests.isEmpty ? const EmptyState('No requests.')
      : ListView.separated(padding: const EdgeInsets.all(20),
          itemCount: _requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => LeaveCard(r: _requests[i],
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => LeaveDetailScreen(request: _requests[i])))))));

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      _buildUsers(),
      _buildDepts(),
      _buildRequests(),
      _RoleProfilePage(auth: widget.auth, roleLabel: 'Admin',
          roleColor: const Color(0xFF9333EA), onLogout: widget.auth.logout),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_bottomTab]),
      bottomNavigationBar: NavigationBar(
        height: 68, backgroundColor: Colors.white,
        selectedIndex: _bottomTab, indicatorColor: _blueSoft,
        onDestinationSelected: (i) => setState(() => _bottomTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_outlined),
              selectedIcon: Icon(Icons.people_rounded), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business_rounded), label: 'Depts'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded), label: 'Me'),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserResponse user;
  const _UserCard({required this.user});

  Color get _c {
    switch (user.role.toUpperCase()) {
      case 'ROLE_ADMIN': return const Color(0xFF9333EA);
      case 'ROLE_MEDICAL_OFFICER': return _green;
      case 'ROLE_DEPARTMENT_REVIEWER': return _blue;
      default: return _amber;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      CircleAvatar(radius: 22, backgroundColor: _c.withOpacity(0.12),
        child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
          style: TextStyle(fontWeight: FontWeight.w800, color: _c, fontSize: 16))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Text(user.email, style: const TextStyle(fontSize: 12, color: _muted)),
        if (user.registrationNo != null)
          Text(user.registrationNo!, style: const TextStyle(fontSize: 12, color: _muted)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(roleLabel(user.role), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _c))),
        if (user.departmentName != null) ...[
          const SizedBox(height: 4),
          Text(user.departmentName!, style: const TextStyle(fontSize: 11, color: _muted)),
        ],
        if (user.faculty != null) ...[
          const SizedBox(height: 2),
          Text(user.faculty!, style: const TextStyle(fontSize: 11, color: _muted)),
        ],
      ]),
    ])),
  );
}

class _CreateStaffScreen extends StatefulWidget {
  final List<Department> depts;
  const _CreateStaffScreen({required this.depts});
  @override State<_CreateStaffScreen> createState() => _CreateStaffState();
}

class _CreateStaffState extends State<_CreateStaffScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obs = true, _loading = false;
  String? _error;
  Department? _dept;
  String _role = 'ROLE_MEDICAL_OFFICER';

  static const _roles = [
    ('ROLE_MEDICAL_OFFICER', 'Medical Officer'),
    ('ROLE_DEPARTMENT_REVIEWER', 'Department Reviewer'),
    ('ROLE_ADMIN', 'Admin'),
  ];

  Future<void> _submit() async {
    if (_dept == null) { setState(() => _error = 'Select department'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await Api.createStaff(fullName: _name.text.trim(), email: _email.text.trim(),
        password: _pass.text, role: _role, departmentId: _dept!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff created!'), backgroundColor: _green));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Staff')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ErrBox(_error!),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name')),
        const SizedBox(height: 14),
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 14),
        const Text('Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        Card(child: Column(children: _roles.map((r) => RadioListTile<String>(
          value: r.$1, groupValue: _role,
          onChanged: (v) => setState(() => _role = v!),
          title: Text(r.$2, style: const TextStyle(fontSize: 14)),
          activeColor: _blue, dense: true,
        )).toList())),
        const SizedBox(height: 14),
        DropdownButtonFormField<Department>(
          value: _dept,
          decoration: const InputDecoration(labelText: 'Department'),
          items: widget.depts.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
          onChanged: (v) => setState(() => _dept = v),
        ),
        const SizedBox(height: 14),
        TextField(controller: _pass, obscureText: _obs,
          decoration: InputDecoration(labelText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(_obs ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obs = !_obs)))),
        const SizedBox(height: 28),
        SizedBox(height: 54, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _loading ? null : _submit,
          child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Create Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
      ],
    )),
  );
}

class _CreateDeptScreen extends StatefulWidget {
  const _CreateDeptScreen();
  @override State<_CreateDeptScreen> createState() => _CreateDeptState();
}

class _CreateDeptState extends State<_CreateDeptScreen> {
  final _name = TextEditingController();
  final _faculty = TextEditingController();
  bool _loading = false; String? _error;

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) { setState(() => _error = 'Name required'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await Api.createDepartment(_name.text.trim(), _faculty.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department created!'), backgroundColor: _green));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Department')),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ErrBox(_error!),
        TextField(controller: _name,
          decoration: const InputDecoration(labelText: 'Department Name',
            prefixIcon: Icon(Icons.business_rounded))),
        const SizedBox(height: 14),
        TextField(controller: _faculty,
          decoration: const InputDecoration(labelText: 'Faculty (optional)',
            prefixIcon: Icon(Icons.account_balance_outlined))),
        const SizedBox(height: 28),
        SizedBox(height: 54, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _loading ? null : _submit,
          child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Create Department', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
      ],
    )),
  );
}
