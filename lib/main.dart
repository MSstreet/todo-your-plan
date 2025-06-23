import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.initialize();
  runApp(const MyApp());
}

// 앱 색상 팔레트
class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFF2196F3);
  static const Color accent = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF5F5F5);
  
  static const List<Color> groupColors = [
    Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
    Color(0xFF9C27B0), Color(0xFFF44336), Color(0xFF00BCD4),
    Color(0xFF795548), Color(0xFF607D8B), Color(0xFFE91E63),
    Color(0xFF3F51B5), Color(0xFFFFC107), Color(0xFF009688),
  ];
}

// 알림 서비스 클래스
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // 초기화
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
    
    // 권한 요청 (Android 13+)
    await _requestPermissions();
  }
  
  // 권한 요청
  static Future<void> _requestPermissions() async {
    // Android 13+ 에서는 자동으로 권한이 요청되므로 별도 처리 불필요
    // iOS의 경우 initialize에서 이미 권한을 요청함
  }
  
  // 즉시 알림 표시
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'todo_channel',
        'Todo 알림',
        channelDescription: '할 일 알림을 위한 채널',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    await _notifications.show(id, title, body, details);
  }
  
  // 예약 알림 설정
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'todo_scheduled_channel',
        'Todo 예약 알림',
        channelDescription: '예약된 할 일 알림을 위한 채널',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  // 특정 알림 취소
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  // 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  // 대기 중인 알림 목록 가져오기
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

// 앱 스타일
class AppStyles {
  static const EdgeInsets defaultMargin = EdgeInsets.all(10);
  static const EdgeInsets defaultPadding = EdgeInsets.all(10);
  static const EdgeInsets smallPadding = EdgeInsets.all(5);
  
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      )
    ],
  );
  
  static TextStyle get headerTextStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get titleTextStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get bodyTextStyle => const TextStyle(
    fontSize: 14,
  );
}

// 로딩 오버레이
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List 일정 관리',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const TodoCalendarApp(),
    );
  }
}

class Todo {
  final int id;
  final String text;
  final bool completed;
  final String groupId;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.text,
    this.completed = false,
    required this.groupId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
      'groupId': groupId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      text: json['text'],
      completed: json['completed'] ?? false,
      groupId: json['groupId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Todo copyWith({
    int? id,
    String? text,
    bool? completed,
    String? groupId,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TodoGroup {
  final String id;
  final String name;
  final Color color;

  TodoGroup({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }

  factory TodoGroup.fromJson(Map<String, dynamic> json) {
    return TodoGroup(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
    );
  }

  TodoGroup copyWith({
    String? id,
    String? name,
    Color? color,
  }) {
    return TodoGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}

// 통일된 화살표 아이콘
class ArrowIcon extends StatelessWidget {
  final bool isLeft;
  final VoidCallback onPressed;
  final String text;

  const ArrowIcon({
    super.key,
    required this.isLeft,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        isLeft ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right,
        color: AppColors.primary,
      ),
      label: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 캘린더 헤더 위젯
class CalendarHeader extends StatelessWidget {
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const CalendarHeader({
    super.key,
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ArrowIcon(
          isLeft: true,
          onPressed: onPrevious,
          text: '이전',
        ),
        Text(title, style: AppStyles.headerTextStyle),
        ArrowIcon(
          isLeft: false,
          onPressed: onNext,
          text: '다음',
        ),
      ],
    );
  }
}

// 뷰 탭 위젯
class ViewTabs extends StatelessWidget {
  final String currentView;
  final Function(String) onViewChanged;

  const ViewTabs({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final views = [
      {'key': 'month', 'label': '월간'},
      {'key': 'week', 'label': '주간'},
      {'key': 'day', 'label': '일간'},
    ];

    return Container(
      margin: AppStyles.defaultMargin.copyWith(top: 0, bottom: 0),
      padding: AppStyles.smallPadding,
      decoration: AppStyles.cardDecoration,
      child: Row(
        children: views.map((view) {
          final isActive = currentView == view['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => onViewChanged(view['key']!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive 
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4)]
                      : null,
                ),
                child: Center(
                  child: Text(
                    view['label']!,
                    style: TextStyle(
                      fontSize: 16,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Todo 입력 페이지 (완전한 새 화면)
class TodoInputPage extends StatefulWidget {
  final List<TodoGroup> todoGroups;
  final List<Todo> todos;
  final Function(Todo) onTodoAdded;
  final Function(TodoGroup) onGroupCreated;
  final Function(TodoGroup) onGroupUpdated;
  final Function(String) onGroupDeleted;
  final Function(int) onTodoDeleted;

  const TodoInputPage({
    super.key,
    required this.todoGroups,
    required this.todos,
    required this.onTodoAdded,
    required this.onGroupCreated,
    required this.onGroupUpdated,
    required this.onGroupDeleted,
    required this.onTodoDeleted,
  });

  @override
  State<TodoInputPage> createState() => _TodoInputPageState();
}

class _TodoInputPageState extends State<TodoInputPage> {
  final TextEditingController todoController = TextEditingController();
  String todoInput = '';
  String selectedGroupId = '';
  bool showGroupManager = false;
  Map<String, bool> expandedGroups = {};

  // 페이지 내부에서 관리할 로컬 상태
  late List<TodoGroup> localTodoGroups;
  late List<Todo> localTodos;

  @override
  void initState() {
    super.initState();
    // 전달받은 데이터를 로컬 상태로 복사
    localTodoGroups = List.from(widget.todoGroups);
    localTodos = List.from(widget.todos);
    
    // 모든 그룹을 기본적으로 펼쳐진 상태로 초기화
    for (final group in localTodoGroups) {
      expandedGroups[group.id] = true;
    }
  }

  @override
  void dispose() {
    todoController.dispose();
    super.dispose();
  }

  bool _validateTodoInput(String text, String groupId) {
    if (text.trim().isEmpty) {
      _showAlert('알림', '할 일을 입력해주세요.');
      return false;
    }
    
    if (text.length > 100) {
      _showAlert('알림', '할 일은 100자 이내로 입력해주세요.');
      return false;
    }
    
    if (groupId.isEmpty) {
      _showAlert('알림', '그룹을 선택해주세요.');
      return false;
    }
    
    return true;
  }

  void _addTodo() {
    if (!_validateTodoInput(todoInput, selectedGroupId)) return;

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch,
      text: todoInput.trim(),
      completed: false,
      groupId: selectedGroupId,
    );
    
    // 부모에 전달
    widget.onTodoAdded(newTodo);
    
    // 로컬 상태 업데이트
    setState(() {
      localTodos.add(newTodo);
      todoInput = '';
      selectedGroupId = '';
    });
    
    todoController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('할 일이 추가되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showGroupEditDialog(TodoGroup group) async {
    final result = await showDialog<TodoGroup>(
      context: context,
      builder: (context) => GroupEditDialog(
        group: group,
        onGroupUpdated: (updatedGroup) {},
      ),
    );
    
    if (result != null) {
      // 중복 이름 체크 (자신 제외)
      if (localTodoGroups.any((g) => g.id != group.id && g.name == result.name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 존재하는 그룹 이름입니다.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // 부모에 전달
      widget.onGroupUpdated(result);
      
      // 로컬 상태 업데이트
      setState(() {
        final index = localTodoGroups.indexWhere((g) => g.id == group.id);
        if (index != -1) {
          localTodoGroups[index] = result;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('그룹이 수정되었습니다.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showGroupCreateDialog() async {
    final result = await showDialog<TodoGroup>(
      context: context,
      builder: (context) => GroupCreateDialog(
        onGroupCreated: (newGroup) {},
      ),
    );
    
    if (result != null) {
      // 중복 이름 체크
      if (localTodoGroups.any((group) => group.name == result.name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 존재하는 그룹 이름입니다.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // 부모에 전달
      widget.onGroupCreated(result);
      
      // 로컬 상태 업데이트
      setState(() {
        localTodoGroups.add(result);
        expandedGroups[result.id] = true; // 이 줄 추가!
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('새 그룹이 생성되었습니다.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _deleteGroup(String groupId) {
    showDialog(
      context: context,
      builder: (context) {
        final group = localTodoGroups.firstWhere((g) => g.id == groupId);
        return AlertDialog(
          title: const Text('그룹 삭제'),
          content: Text(
            '"${group.name}" 그룹을 삭제하시겠습니까?\n이 그룹의 모든 할 일도 함께 삭제됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                // 부모에 전달
                widget.onGroupDeleted(groupId);
                
                // 로컬 상태 업데이트
                setState(() {
                  localTodos.removeWhere((todo) => todo.groupId == groupId);
                  localTodoGroups.removeWhere((g) => g.id == groupId);
                  expandedGroups.remove(groupId); // 삭제된 그룹의 상태도 제거
                  
                  // 삭제된 그룹이 선택되어 있었다면 선택 해제
                  if (selectedGroupId == groupId) {
                    selectedGroupId = '';
                  }
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('그룹이 삭제되었습니다.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteTodo(int todoId) {
    showDialog(
      context: context,
      builder: (context) {
        final todo = localTodos.firstWhere((t) => t.id == todoId);
        return AlertDialog(
          title: const Text('할 일 삭제'),
          content: Text('\"${todo.text}\"를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                // 부모에 전달
                widget.onTodoDeleted(todoId);
                
                // 로컬 상태 업데이트
                setState(() {
                  localTodos.removeWhere((todo) => todo.id == todoId);
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('할 일이 삭제되었습니다.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '할 일 추가',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppStyles.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 할 일 입력
            Card(
              child: Padding(
                padding: AppStyles.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '새 할 일',
                      style: AppStyles.headerTextStyle,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: todoController,
                      decoration: InputDecoration(
                        hintText: '할 일을 입력하세요 (최대 100자)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        counterText: '${todoInput.length}/100',
                      ),
                      maxLines: 3,
                      maxLength: 100,
                       onChanged: (value) {
                        setState(() {
                          todoInput = value;
                          });
                       }
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 그룹 선택
            Card(
              child: Padding(
                padding: AppStyles.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '그룹 선택',
                          style: AppStyles.headerTextStyle,
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _showGroupCreateDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('새 그룹'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  showGroupManager = !showGroupManager;
                                });
                              },
                              icon: Icon(
                                showGroupManager ? Icons.expand_less : Icons.expand_more,
                                size: 16,
                              ),
                              label: const Text('관리'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 그룹 선택 버튼들
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: localTodoGroups.map((group) {
                        final isSelected = selectedGroupId == group.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedGroupId = group.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? group.color.withOpacity(0.2) : Colors.white,
                              border: Border.all(
                                color: group.color,
                                width: isSelected ? 3 : 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: group.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected ? group.color : Colors.grey.shade600,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    // 그룹 관리 패널
                    if (showGroupManager) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: AppStyles.defaultPadding,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '그룹 관리',
                              style: AppStyles.headerTextStyle.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            ...localTodoGroups.map((group) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: group.color.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: group.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        group.name,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _showGroupEditDialog(group),
                                          icon: const Icon(Icons.edit, size: 18),
                                          color: AppColors.secondary,
                                          tooltip: '수정',
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteGroup(group.id),
                                          icon: const Icon(Icons.delete, size: 18),
                                          color: AppColors.error,
                                          tooltip: '삭제',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 추가 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (todoInput.trim().isEmpty || selectedGroupId.isEmpty)
                    ? null
                    : _addTodo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '할 일 추가',
                  style: TextStyle(
                    color: (todoInput.trim().isEmpty || selectedGroupId.isEmpty)
                        ? Colors.grey.shade600
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // 기존 할 일 목록
            Card(
              child: Padding(
                padding: AppStyles.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기존 할 일 목록 (${localTodos.length}개)',
                      style: AppStyles.headerTextStyle,
                    ),
                    const SizedBox(height: 10),
                    localTodos.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                '아직 할 일이 없습니다\n위에서 새로운 할 일을 추가해보세요!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            constraints: const BoxConstraints(maxHeight: 400), // 최대 높이 제한
                            child: SingleChildScrollView(
                              child: Column(
                                children: localTodoGroups.map((group) {
                                  final groupTodos = localTodos.where((todo) => todo.groupId == group.id).toList();
                                  if (groupTodos.isEmpty) return const SizedBox.shrink();
                                  
                                  final isExpanded = expandedGroups[group.id] ?? true;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: group.color.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: group.color.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        // 그룹 헤더 (클릭 가능)
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              expandedGroups[group.id] = !isExpanded;
                                            });
                                          },
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10),
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: group.color.withOpacity(0.1),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                topRight: Radius.circular(10),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // 펼침/접힘 아이콘
                                                Icon(
                                                  isExpanded 
                                                      ? Icons.keyboard_arrow_down 
                                                      : Icons.keyboard_arrow_right,
                                                  color: group.color,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                // 그룹 색상 인디케이터
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: group.color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // 그룹명과 개수
                                                Expanded(
                                                  child: Text(
                                                    '${group.name} (${groupTodos.length}개)',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                // 그룹 관리 버튼들
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      onPressed: () => _showGroupEditDialog(group),
                                                      icon: const Icon(Icons.edit, size: 16),
                                                      color: AppColors.secondary,
                                                      tooltip: '그룹 수정',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => _deleteGroup(group.id),
                                                      icon: const Icon(Icons.delete, size: 16),
                                                      color: AppColors.error,
                                                      tooltip: '그룹 삭제',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        // 할 일 목록 (접혔을 때는 숨김)
                                        if (isExpanded) ...[
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                children: groupTodos.map((todo) {
                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 8),
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: group.color.withOpacity(0.3)),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.05),
                                                          blurRadius: 2,
                                                          offset: const Offset(0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        // 세로 구분선
                                                        Container(
                                                          width: 3,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            color: group.color,
                                                            borderRadius: BorderRadius.circular(2),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        // 할 일 내용
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                todo.text,
                                                                style: AppStyles.bodyTextStyle.copyWith(
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                '생성일: ${todo.createdAt.month}/${todo.createdAt.day} ${todo.createdAt.hour}:${todo.createdAt.minute.toString().padLeft(2, '0')}',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.grey.shade600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        // 삭제 버튼
                                                        IconButton(
                                                          onPressed: () => _deleteTodo(todo.id),
                                                          icon: const Icon(
                                                            Icons.delete_outline,
                                                            color: AppColors.error,
                                                            size: 20,
                                                          ),
                                                          tooltip: '삭제',
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
    );
  }
}

class GroupEditDialog extends StatefulWidget {
  final TodoGroup group;
  final Function(TodoGroup) onGroupUpdated;

  const GroupEditDialog({
    super.key,
    required this.group,
    required this.onGroupUpdated,
  });

  @override
  State<GroupEditDialog> createState() => _GroupEditDialogState();
}

class _GroupEditDialogState extends State<GroupEditDialog> {
  late TextEditingController controller;
  late int selectedColorIndex;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.group.name);
    selectedColorIndex = AppColors.groupColors.indexOf(widget.group.color);
    if (selectedColorIndex == -1) selectedColorIndex = 0;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('그룹 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '그룹 이름 (최대 20자)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            maxLength: 20,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 15),
          const Text('색상 선택:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColors.groupColors.asMap().entries.map((entry) {
              final index = entry.key;
              final color = entry.value;
              final isSelected = selectedColorIndex == index;
              
              return GestureDetector(
                onTap: () => setState(() => selectedColorIndex = index),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected 
                        ? Border.all(color: Colors.black, width: 3)
                        : Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: controller.text.trim().isEmpty ? null : () {
            final updatedGroup = widget.group.copyWith(
              name: controller.text.trim(),
              color: AppColors.groupColors[selectedColorIndex],
            );
            Navigator.pop(context, updatedGroup);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('수정', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class GroupCreateDialog extends StatefulWidget {
  final Function(TodoGroup) onGroupCreated;

  const GroupCreateDialog({
    super.key,
    required this.onGroupCreated,
  });

  @override
  State<GroupCreateDialog> createState() => _GroupCreateDialogState();
}

class _GroupCreateDialogState extends State<GroupCreateDialog> {
  final controller = TextEditingController();
  int selectedColorIndex = 0;
  String groupName = '';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 그룹 만들기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '그룹 이름 (최대 20자)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              
            ),
            maxLength: 20,
            onChanged: (value) {
              setState(() {
              groupName = value;
      });
    },
          ),
          const SizedBox(height: 15),
          const Text('색상 선택:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColors.groupColors.asMap().entries.map((entry) {
              final index = entry.key;
              final color = entry.value;
              final isSelected = selectedColorIndex == index;
              
              return GestureDetector(
                onTap: () => setState(() => selectedColorIndex = index),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected 
                        ? Border.all(color: Colors.black, width: 3)
                        : Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: groupName.trim().isEmpty ? null : () {
            final newGroup = TodoGroup(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: controller.text.trim(),
              color: AppColors.groupColors[selectedColorIndex],
            );
            Navigator.pop(context, newGroup);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('생성', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// 알림 설정 다이얼로그
class NotificationSettingsDialog extends StatefulWidget {
  final bool notificationsEnabled;
  final int minutesBefore;
  final Function(bool, int) onSettingsChanged;

  const NotificationSettingsDialog({
    super.key,
    required this.notificationsEnabled,
    required this.minutesBefore,
    required this.onSettingsChanged,
  });

  @override
  State<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  late bool _notificationsEnabled;
  late int _minutesBefore;
  
  final List<int> _notificationOptions = [0, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.notificationsEnabled;
    _minutesBefore = widget.minutesBefore;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.notifications, color: AppColors.primary),
          SizedBox(width: 10),
          Text('알림 설정'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('알림 사용'),
            subtitle: const Text('일정 시간에 알림을 받습니다'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: AppColors.primary,
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 20),
            const Text(
              '알림 시점',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...(_notificationOptions.map((minutes) {
              return RadioListTile<int>(
                title: Text(minutes == 0 ? '정시에' : '$minutes분 전'),
                value: minutes,
                groupValue: _minutesBefore,
                onChanged: (value) {
                  setState(() {
                    _minutesBefore = value!;
                  });
                },
                activeColor: AppColors.primary,
              );
            })),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSettingsChanged(_notificationsEnabled, _minutesBefore);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text(
            '저장',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class TodoCalendarApp extends StatefulWidget {
  const TodoCalendarApp({super.key});

  @override
  State<TodoCalendarApp> createState() => _TodoCalendarAppState();
}

class _TodoCalendarAppState extends State<TodoCalendarApp> {
  List<Todo> todos = [];
  List<TodoGroup> todoGroups = [];
  String currentView = 'month';
  DateTime currentMonth = DateTime.now();
  DateTime currentDayDate = DateTime.now();
  DateTime currentWeekDate = DateTime.now(); // 추가할 변수
  Map<String, List<Todo>> scheduledTodos = {};
  bool showTodoSelectorModal = false;
  String selectedScheduleKey = '';
  bool isLoading = false;
  Map<String, bool> selectorExpandedGroups = {};
  
  // 알림 설정
  bool notificationsEnabled = true;
  int minutesBefore = 5; // 기본값: 5분 전 알림

  bool showScheduleEditModal = false;
  bool showNewTodoForScheduleModal = false;
  Todo? currentEditingTodo;
  String currentEditingScheduleKey = '';
  String newTodoText = '';
  String newTodoSelectedGroupId = '';
  final TextEditingController newTodoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // 알림 서비스 초기화
      await NotificationService.initialize();
      
      await _initializeDefaultGroups();
      await _loadData();
      await _loadNotificationSettings();
      
      // 기존 알림들을 다시 설정
      await _rescheduleAllNotifications();
    } catch (e) {
      _showAlert('오류', '앱 초기화에 실패했습니다: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializeDefaultGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGroups = prefs.getString('todoGroups');
      
      if (savedGroups == null) {
        final defaultGroups = [
          TodoGroup(id: 'routine', name: '루틴', color: AppColors.groupColors[0]),
          TodoGroup(id: 'today', name: '오늘 할 일', color: AppColors.groupColors[1]),
          TodoGroup(id: 'weekend', name: '주말에 할 일', color: AppColors.groupColors[2]),
        ];
        setState(() {
          todoGroups = defaultGroups;
        });
        await _saveGroups();
      } else {
        final List<dynamic> groupsJson = json.decode(savedGroups);
        setState(() {
          todoGroups = groupsJson.map((g) => TodoGroup.fromJson(g)).toList();
        });
      }
    } catch (e) {
      throw Exception('그룹 초기화 실패: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedTodos = prefs.getString('todos');
      if (savedTodos != null) {
        final List<dynamic> todosJson = json.decode(savedTodos);
        setState(() {
          todos = todosJson.map((t) => Todo.fromJson(t)).toList();
        });
      }

      final savedScheduled = prefs.getString('scheduledTodos');
      if (savedScheduled != null) {
        final Map<String, dynamic> scheduledJson = json.decode(savedScheduled);
        setState(() {
          scheduledTodos = scheduledJson.map((key, value) {
            final List<dynamic> todosList = value;
            return MapEntry(key, todosList.map((t) => Todo.fromJson(t)).toList());
          });
        });
      }
    } catch (e) {
      throw Exception('데이터 로드 실패: $e');
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        minutesBefore = prefs.getInt('minutesBefore') ?? 5;
      });
    } catch (e) {
      print('알림 설정 로드 실패: $e');
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', notificationsEnabled);
      await prefs.setInt('minutesBefore', minutesBefore);
    } catch (e) {
      print('알림 설정 저장 실패: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('todos', json.encode(todos.map((t) => t.toJson()).toList()));
      
      final scheduledJson = scheduledTodos.map((key, value) {
        return MapEntry(key, value.map((t) => t.toJson()).toList());
      });
      await prefs.setString('scheduledTodos', json.encode(scheduledJson));
    } catch (e) {
      _showAlert('오류', '데이터 저장에 실패했습니다: $e');
    }
  }

  Future<void> _saveGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('todoGroups', json.encode(todoGroups.map((g) => g.toJson()).toList()));
    } catch (e) {
      _showAlert('오류', '그룹 저장에 실패했습니다: $e');
    }
  }

  // 알림 관련 메서드들
  DateTime? _parseScheduleKey(String scheduleKey) {
    try {
      final parts = scheduleKey.split('-');
      if (parts.length >= 4) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final hour = int.parse(parts[3]);
        final minute = parts.length >= 5 ? int.parse(parts[4]) : 0;
        
        return DateTime(year, month, day, hour, minute);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _scheduleNotificationForTodo(String scheduleKey, Todo todo) async {
    if (!notificationsEnabled) return;
    
    final scheduledTime = _parseScheduleKey(scheduleKey);
    if (scheduledTime == null) return;
    
    // 알림 시간 계산 (지정된 분 전)
    final notificationTime = scheduledTime.subtract(Duration(minutes: minutesBefore));
    
    // 현재 시간보다 이후인 경우만 알림 설정
    if (notificationTime.isAfter(DateTime.now())) {
      final group = _getGroupById(todo.groupId);
      final groupName = group?.name ?? '일정';
      
      await NotificationService.scheduleNotification(
        id: '${scheduleKey}_${todo.id}'.hashCode.abs(),
        title: '📅 $groupName 알림',
        body: minutesBefore == 0 
            ? '지금: ${todo.text}'
            : '$minutesBefore분 후: ${todo.text}',
        scheduledTime: notificationTime,
      );
    }
  }

  Future<void> _cancelNotificationForTodo(String scheduleKey, int todoId) async {
    final notificationId = '${scheduleKey}_$todoId'.hashCode.abs();
    await NotificationService.cancelNotification(notificationId);
  }

  Future<void> _rescheduleAllNotifications() async {
    // 기존 알림 모두 취소
    await NotificationService.cancelAllNotifications();
    
    if (!notificationsEnabled) return;
    
    // 모든 예약된 할 일에 대해 알림 재설정
    for (final entry in scheduledTodos.entries) {
      final scheduleKey = entry.key;
      final todos = entry.value;
      
      for (final todo in todos) {
        await _scheduleNotificationForTodo(scheduleKey, todo);
      }
    }
  }

  void _addTodo(Todo todo) {
    setState(() {
      todos.add(todo);
    });
    _saveData();
  }

  void _createNewGroup(TodoGroup group) {
    setState(() {
      todoGroups.add(group);
    });
    _saveGroups();
  }

  void _updateGroup(TodoGroup updatedGroup) {
    setState(() {
      final index = todoGroups.indexWhere((group) => group.id == updatedGroup.id);
      if (index != -1) {
        todoGroups[index] = updatedGroup;
      }
    });
    _saveGroups();
  }

  void _deleteGroup(String groupId) {
    setState(() {
      todos.removeWhere((todo) => todo.groupId == groupId);
      scheduledTodos.forEach((key, todoList) {
        todoList.removeWhere((todo) => todo.groupId == groupId);
      });
      todoGroups.removeWhere((g) => g.id == groupId);
    });
    
    _saveData();
    _saveGroups();
    
    // 삭제된 그룹의 할 일들에 대한 알림도 취소
    _rescheduleAllNotifications();
  }

  void _deleteTodo(int id) {
    setState(() {
      todos.removeWhere((todo) => todo.id == id);
      scheduledTodos.forEach((key, todoList) {
        todoList.removeWhere((todo) => todo.id == id);
      });
    });
    
    _saveData();
    
    // 해당 할 일의 알림 취소
    for (final scheduleKey in scheduledTodos.keys) {
      _cancelNotificationForTodo(scheduleKey, id);
    }
  }

  void _deleteScheduledTodo(String scheduleKey, int todoId) {
    setState(() {
      if (scheduledTodos.containsKey(scheduleKey)) {
        scheduledTodos[scheduleKey]!.removeWhere((todo) => todo.id == todoId);
        if (scheduledTodos[scheduleKey]!.isEmpty) {
          scheduledTodos.remove(scheduleKey);
        }
      }
    });
    _saveData();
    
    // 해당 일정의 알림 취소
    _cancelNotificationForTodo(scheduleKey, todoId);
  }
void _addTodoToSchedule(Todo todo, String scheduleKey) {
  if (!mounted) return;
  
  // 중복 체크 개선 - 팝업으로 확인 후 수정 옵션 제공
  if (scheduledTodos.containsKey(scheduleKey) && scheduledTodos[scheduleKey]!.isNotEmpty) {
    // 🔧 기존 일정이 있을 때 확인 다이얼로그 표시
    final existingTodo = scheduledTodos[scheduleKey]!.first;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림'),
        content: const Text('이 시간대에는 이미 일정이 있습니다. 기존 일정을 수정하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 알림 다이얼로그 닫기
              _showScheduleOptionsDialog(scheduleKey, existingTodo); // 수정 옵션 다이얼로그 열기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return;
  }
  
  // 기존 일정 추가 로직은 그대로
  setState(() {
    if (!scheduledTodos.containsKey(scheduleKey)) {
      scheduledTodos[scheduleKey] = [];
    }
    scheduledTodos[scheduleKey]!.add(todo);
  });
  
  _saveData().then((_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정에 추가되었습니다!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }).catchError((error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  });
}
  void _showTodoSelector(String scheduleKey) {
    if (todos.isEmpty) {
      _showAlert('알림', '먼저 할 일을 추가해주세요.');
      return;
    }

    setState(() {
      selectedScheduleKey = scheduleKey;
      showTodoSelectorModal = true;
    });
  }

  TodoGroup? _getGroupById(String groupId) {
    try {
      return todoGroups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => NotificationSettingsDialog(
        notificationsEnabled: notificationsEnabled,
        minutesBefore: minutesBefore,
        onSettingsChanged: (enabled, minutes) async {
          setState(() {
            notificationsEnabled = enabled;
            minutesBefore = minutes;
          });
          
          await _saveNotificationSettings();
          await _rescheduleAllNotifications();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림 설정이 저장되었습니다.'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  void _showDayEventDialog(String dateKey) {
  final dayTodos = scheduledTodos[dateKey] ?? [];
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateKey(dateKey),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // 일정 추가 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showTodoSelector(dateKey);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  '새 일정 추가',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 일정 목록
            Text(
              '일정 목록 (${dayTodos.length}개)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: dayTodos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text(
                            '등록된 일정이 없습니다',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '위의 버튼을 눌러 새 일정을 추가해보세요',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: dayTodos.length,
                      itemBuilder: (context, index) {
                        final todo = dayTodos[index];
                        final group = _getGroupById(todo.groupId);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: group?.color.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                            border: Border.all(
                              color: group?.color ?? Colors.blue,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // 그룹 색상 인디케이터
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: group?.color ?? Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // 일정 내용
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todo.text,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: group?.color ?? Colors.blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          group?.name ?? '기본',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 삭제 버튼
                              IconButton(
                                onPressed: () {
                                  _showDeleteEventDialog(dateKey, todo);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                tooltip: '일정 삭제',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

// 3. 날짜 키 포맷팅 함수
String _formatDateKey(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length >= 3) {
    final year = parts[0];
    final month = parts[1];
    final day = parts[2];
    return '${year}년 ${month}월 ${day}일';
  }
  return dateKey;
}

// 4. 일정 삭제 확인 다이얼로그
void _showDeleteEventDialog(String dateKey, Todo todo) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('일정 삭제'),
      content: Text('"${todo.text}" 일정을 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            _deleteScheduledTodo(dateKey, todo.id);
            Navigator.pop(context); // 삭제 다이얼로그 닫기
            Navigator.pop(context); // 일정 목록 다이얼로그 닫기
            _showDayEventDialog(dateKey); // 일정 목록 다시 열기 (업데이트된 내용으로)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text(
            '삭제',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

  // 날짜 계산 개선
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday == 7 ? 0 : weekday));
  }

  // 스와이프 제스처가 포함된 월간 캘린더
  Widget _buildSwipeableMonthCalendar() {
    return GestureDetector(
      onPanEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx > 300) {
          // 오른쪽 스와이프 - 이전 달
          setState(() {
            currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
          });
        } else if (details.velocity.pixelsPerSecond.dx < -300) {
          // 왼쪽 스와이프 - 다음 달
          setState(() {
            currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
          });
        }
      },
      child: _renderMonthCalendar(),
    );
  }

  Widget _renderMonthCalendar() {
  final year = currentMonth.year;
  final month = currentMonth.month;
  final firstDay = DateTime(year, month, 1).weekday % 7;
  final daysInMonth = DateTime(year, month + 1, 0).day;
  
  const dayNames = ['일', '월', '화', '수', '목', '금', '토'];
  const headerColors = [
    Colors.red, AppColors.primary, AppColors.primary, AppColors.primary,
    AppColors.primary, AppColors.primary, AppColors.secondary
  ];
  
  List<Widget> calendarDays = [];
  
  // 요일 헤더
  List<Widget> headers = [];
  for (int i = 0; i < 7; i++) {
    headers.add(
      Container(
        height: 40,
        color: headerColors[i],
        child: Center(
          child: Text(
            dayNames[i],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  // 빈 칸 채우기
  for (int i = 0; i < firstDay; i++) {
    calendarDays.add(
      Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
  
  // 날짜 채우기
  for (int day = 1; day <= daysInMonth; day++) {
    final dateKey = '$year-$month-$day';
    final dayTodos = scheduledTodos[dateKey] ?? [];
    final dayOfWeek = (firstDay + day - 1) % 7;
    
    calendarDays.add(
      GestureDetector(
        onTap: () => _showDayEventDialog(dateKey),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: dayOfWeek == 0 
                ? Colors.red.shade50 
                : dayOfWeek == 6 
                    ? Colors.blue.shade50 
                    : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 표시
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: dayOfWeek == 0 
                        ? Colors.red 
                        : dayOfWeek == 6 
                            ? Colors.blue 
                            : Colors.black,
                  ),
                ),
              ),
              // 일정 개수 표시
              Expanded(
                child: Center(
                  child: dayTodos.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${dayTodos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  return Column(
    children: [
      GridView.count(
        shrinkWrap: true,
        crossAxisCount: 7,
        childAspectRatio: 1,
        children: headers,
      ),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        childAspectRatio: 1,
        children: calendarDays,
      ),
    ],
  );
}

 Widget _renderWeekSchedule() {
  // currentWeekDate 기준으로 주간 시작일 계산
  final weekStart = _getWeekStart(currentWeekDate);
  const dayNames = ['일', '월', '화', '수', '목', '금', '토'];
  final hours = List.generate(24, (i) => i);
  
  return Column(
    children: [
      // 주간 네비게이션 헤더 추가
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  currentWeekDate = currentWeekDate.subtract(const Duration(days: 7));
                });
              },
              icon: const Icon(
                Icons.keyboard_arrow_left,
                color: AppColors.primary,
                size: 32,
              ),
              tooltip: '이전 주',
            ),
            Text(
              '${weekStart.month}월 ${weekStart.day}일 - ${weekStart.add(const Duration(days: 6)).month}월 ${weekStart.add(const Duration(days: 6)).day}일',
              style: AppStyles.headerTextStyle,
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  currentWeekDate = currentWeekDate.add(const Duration(days: 7));
                });
              },
              icon: const Icon(
                Icons.keyboard_arrow_right,
                color: AppColors.primary,
                size: 32,
              ),
              tooltip: '다음 주',
            ),
          ],
        ),
      ),
      // 기존 주간 스케줄
      Expanded(
        child: Column(
          children: [
            // 요일 헤더
            Row(
              children: [
                Container(
                  width: 60,
                  height: 40,
                  color: Colors.grey.shade200,
                ),
                ...List.generate(7, (i) {
                  final date = weekStart.add(Duration(days: i));
                  return Expanded(
                    child: Container(
                      height: 40,
                      color: i == 0 
                          ? Colors.red.shade50 
                          : i == 6 
                              ? Colors.blue.shade50 
                              : Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNames[i],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: i == 0 
                                  ? Colors.red 
                                  : i == 6 
                                      ? Colors.blue 
                                      : Colors.black,
                            ),
                          ),
                          Text(
                            '${date.month}/${date.day}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            // 시간별 스케줄
            Expanded(
              child: ListView.builder(
                itemCount: hours.length,
                itemBuilder: (context, hourIndex) {
                  final hour = hours[hourIndex];
                  return Row(
                    children: [
                      Container(
                        width: 60,
                        height: 70,
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(7, (dayIndex) {
                        final date = weekStart.add(Duration(days: dayIndex));
                        
                        final firstHalfKey = '${date.year}-${date.month}-${date.day}-$hour-0';
                        final secondHalfKey = '${date.year}-${date.month}-${date.day}-$hour-30';
                        
                        final firstHalfTodos = scheduledTodos[firstHalfKey] ?? [];
                        final secondHalfTodos = scheduledTodos[secondHalfKey] ?? [];
                        
                        return Expanded(
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                // 0-30분 슬롯
                                  Expanded(
                                    child: Material(  // ← 이 부분 추가!
                                      color: Colors.transparent,
                                      child: InkWell(  // ← GestureDetector 대신 InkWell 사용
                                        onTap: () => _showTodoSelector(firstHalfKey),
                                        onLongPress: firstHalfTodos.isNotEmpty ? () {
                                          final todo = firstHalfTodos[0];
                                          _showScheduleOptionsDialog(firstHalfKey, todo); // ← 이 부분 변경!
                                        } : null,
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade200,
                                                width: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: firstHalfTodos.isNotEmpty
                                              ? Container(
                                                  margin: const EdgeInsets.all(2),
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: _getGroupById(firstHalfTodos[0].groupId)?.color ?? Colors.blue,
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: Text(
                                                    firstHalfTodos[0].text,
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                // 30-60분 슬롯
                                Expanded(
                                    child: Material(  // ← 이 부분 추가!
                                      color: Colors.transparent,
                                      child: InkWell(  // ← GestureDetector 대신 InkWell 사용
                                        onTap: () => _showTodoSelector(secondHalfKey),
                                        onLongPress: secondHalfTodos.isNotEmpty ? () {
                                          final todo = secondHalfTodos[0];
                                          _showScheduleOptionsDialog(secondHalfKey, todo); // ← 변경
                                        } : null,
                                        child: Container(
                                          width: double.infinity,
                                          color: Colors.grey.shade50,
                                          child: secondHalfTodos.isNotEmpty
                                              ? Container(
                                                  margin: const EdgeInsets.all(2),
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: _getGroupById(secondHalfTodos[0].groupId)?.color ?? Colors.blue,
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: Text(
                                                    secondHalfTodos[0].text,
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _renderDaySchedule() {
  final year = currentDayDate.year;
  final month = currentDayDate.month;
  final day = currentDayDate.day;
  final hours = List.generate(24, (i) => i);
  
  return ListView.builder(
    itemCount: hours.length,
    itemBuilder: (context, hourIndex) {
      final hour = hours[hourIndex];
      final firstHalfKey = '$year-$month-$day-$hour-0';
      final secondHalfKey = '$year-$month-$day-$hour-30';
      
      final firstHalfTodos = scheduledTodos[firstHalfKey] ?? [];
      final secondHalfTodos = scheduledTodos[secondHalfKey] ?? [];
      
      return Container(
        // 시간별 경계선 추가
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade400,
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  // 0-30분 슬롯
                  Material(  // ← 이 부분 추가!
                    color: Colors.transparent,
                    child: InkWell(  // ← GestureDetector 대신 InkWell 사용
                      onTap: () => _showTodoSelector(firstHalfKey),
                     onLongPress: firstHalfTodos.isNotEmpty ? () {
                          final todo = firstHalfTodos[0];
                          _showScheduleOptionsDialog(firstHalfKey, todo); // ← 이 부분 변경!
                        } : null,
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                '00분 - 30분',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: firstHalfTodos.isEmpty
                                  ? const Center(
                                      child: Text(
                                        '일정을 추가하려면 탭하세요',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: firstHalfTodos.length,
                                      itemBuilder: (context, index) {
                                        final todo = firstHalfTodos[index];
                                        final group = _getGroupById(todo.groupId);
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 3),
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: group?.color ?? Colors.blue,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            todo.text,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 30-60분 슬롯
                    Material(  // ← 이 부분 추가!
                    color: Colors.transparent,
                    child: InkWell(  // ← GestureDetector 대신 InkWell 사용
                      onTap: () => _showTodoSelector(secondHalfKey),
                      onLongPress: secondHalfTodos.isNotEmpty ? () {
                        final todo = secondHalfTodos[0];
                        _showScheduleOptionsDialog(secondHalfKey, todo); // ← 변경
                      } : null,
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                '30분 - 60분',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: secondHalfTodos.isEmpty
                                  ? const Center(
                                      child: Text(
                                        '일정을 추가하려면 탭하세요',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: secondHalfTodos.length,
                                      itemBuilder: (context, index) {
                                        final todo = secondHalfTodos[index];
                                        final group = _getGroupById(todo.groupId);
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 3),
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: group?.color ?? Colors.blue,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            todo.text,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildTodoSelectorModal() {
  // 그룹별 펼침 상태 초기화 (한 번만)
  for (final group in todoGroups) {
    selectorExpandedGroups.putIfAbsent(group.id, () => true);
  }

  return AlertDialog(
    title: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('할 일 선택'),
        SizedBox(height: 5),
        Text(
          '일정에 추가할 할 일을 선택하세요',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: double.maxFinite,
      height: 400,
      child: Column(
        children: [
          // 전체 펼치기/접기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    for (final group in todoGroups) {
                      selectorExpandedGroups[group.id] = true;
                    }
                  });
                },
                icon: const Icon(Icons.expand_more, size: 16),
                label: const Text('전체 펼치기'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    for (final group in todoGroups) {
                      selectorExpandedGroups[group.id] = false;
                    }
                  });
                },
                icon: const Icon(Icons.expand_less, size: 16),
                label: const Text('전체 접기'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          const Divider(),
          
          // 그룹별 할 일 목록
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: todoGroups.map((group) {
                  final groupTodos = todos.where((todo) => todo.groupId == group.id).toList();
                  if (groupTodos.isEmpty) return const SizedBox.shrink();
                  
                  final isExpanded = selectorExpandedGroups[group.id] ?? true;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: group.color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: group.color.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        // 그룹 헤더 (클릭 가능)
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectorExpandedGroups[group.id] = !isExpanded;
                            });
                          },
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              color: group.color.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                // 펼침/접힘 아이콘
                                Icon(
                                  isExpanded 
                                      ? Icons.keyboard_arrow_down 
                                      : Icons.keyboard_arrow_right,
                                  color: group.color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                // 그룹 색상 인디케이터
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: group.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // 그룹명과 개수
                                Expanded(
                                  child: Text(
                                    '${group.name} (${groupTodos.length}개)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                // 그룹 전체 선택 버튼 (옵션)
                                if (isExpanded && groupTodos.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      // 랜덤으로 그룹의 첫 번째 할 일 선택
                                      _addTodoToSchedule(groupTodos.first, selectedScheduleKey);
                                      setState(() {
                                        showTodoSelectorModal = false;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: group.color,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    child: const Text(
                                      '첫 번째 선택',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        // 할 일 목록 (접혔을 때는 숨김)
                        if (isExpanded) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              children: groupTodos.map((todo) {
                                return InkWell(
                                  onTap: () {
                                    _addTodoToSchedule(todo, selectedScheduleKey);
                                    setState(() {
                                      showTodoSelectorModal = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: group.color.withOpacity(0.1),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // 세로 구분선
                                        Container(
                                          width: 3,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: group.color,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // 할 일 내용
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                todo.text,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '생성일: ${todo.createdAt.month}/${todo.createdAt.day}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // 선택 아이콘
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: group.color,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          setState(() {
            showTodoSelectorModal = false;
          });
        },
        child: const Text(
          '취소',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    ],
  );
}

  // 총 일정 개수 계산 함수 추가
  int get totalScheduledTodos {
    int count = 0;
    scheduledTodos.forEach((key, todoList) {
      count += todoList.length;
    });
    return count;
  }

// 1. 일정 옵션 다이얼로그 (삭제/수정 선택)
 void _showScheduleOptionsDialog(String scheduleKey, Todo todo) {
  // 🐛 디버깅: 어떤 일정이 선택되었는지 확인
  print('🔍 선택된 일정: ${todo.text}');
  print('🔍 스케줄 키: $scheduleKey');
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.event,
            color: _getGroupById(todo.groupId)?.color ?? AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '"${todo.text}"',
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('어떤 작업을 하시겠습니까?'),
          const SizedBox(height: 10),
          // 🔧 추가: 현재 선택된 일정 정보 표시
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택된 일정: ${todo.text}'),
                Text('시간: ${_formatScheduleKey(scheduleKey)}'),
                Text('그룹: ${_getGroupById(todo.groupId)?.name ?? "기본"}'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // 🔧 Row로 버튼들을 가로로 정렬
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 취소 버튼
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ),
            
            // 수정 버튼
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showScheduleEditDialog(scheduleKey, todo);
                },
                icon: const Icon(Icons.edit, color: AppColors.secondary, size: 18),
                label: const Text(
                  '수정',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
            ),
            
            // 삭제 버튼
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteScheduleConfirmDialog(scheduleKey, todo);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 8), // 높이 조정
                ),
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                label: const Text(
                  '삭제',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // 2. 일정 수정 다이얼로그 시작
void _showScheduleEditDialog(String scheduleKey, Todo currentTodo) {
  // 🔧 디버깅: 수정 다이얼로그가 올바른 정보로 시작되는지 확인
  print('🔍 편집 시작 - 할 일: ${currentTodo.text}, 키: $scheduleKey');
  
  setState(() {
    currentEditingTodo = currentTodo;
    currentEditingScheduleKey = scheduleKey;
    showScheduleEditModal = true;
    // 새 할 일 입력 관련 상태 초기화
    newTodoText = '';
    newTodoSelectedGroupId = '';
  });
  
  // 컨트롤러도 초기화
  newTodoController.clear();
}

  // 3. 일정 수정 모달 UI
 Widget _buildScheduleEditModal() {
  // 🔧 null 체크 개선
  if (currentEditingTodo == null) {
    print('🔍 ❌ currentEditingTodo가 null입니다!');
    return const SizedBox.shrink();
  }
  
  // 🔧 로컬 변수로 안전하게 저장
  final editingTodo = currentEditingTodo!;
  final editingKey = currentEditingScheduleKey;
  
  return AlertDialog(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('일정 수정'),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '현재: "${editingTodo.text}"',  // 🔧 로컬 변수 사용
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: double.maxFinite,
      height: 300,
      child: Column(
        children: [
          // 수정 옵션 버튼들
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 🔧 상태를 닫지 않고 다른 다이얼로그 열기
                    _showExistingTodoSelector();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.list, color: Colors.white, size: 18),
                  label: const Text(
                    '기존 할 일로 변경',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showScheduleEditModal = false;
                      newTodoText = '';
                      newTodoSelectedGroupId = '';
                      showNewTodoForScheduleModal = true;
                      // 🔧 currentEditingTodo는 유지!
                    });
                    newTodoController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    '새 할 일로 변경',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 현재 일정 정보
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '현재 일정 정보',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getGroupById(editingTodo.groupId)?.color ?? Colors.blue,  // 🔧 로컬 변수 사용
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getGroupById(editingTodo.groupId)?.name ?? '기본',  // 🔧 로컬 변수 사용
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  editingTodo.text,  // 🔧 로컬 변수 사용
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Text(
                  '생성일: ${editingTodo.createdAt.month}/${editingTodo.createdAt.day} ${editingTodo.createdAt.hour}:${editingTodo.createdAt.minute.toString().padLeft(2, '0')}',  // 🔧 로컬 변수 사용
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                Text(
                  '시간: ${_formatScheduleKey(editingKey)}',  // 🔧 로컬 변수 사용
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          setState(() {
            showScheduleEditModal = false;
            currentEditingTodo = null;
            currentEditingScheduleKey = '';
          });
        },
        child: const Text(
          '취소',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    ],
  );
}

  // 4. 기존 할 일 선택 다이얼로그
  void _showExistingTodoSelector() {
  // 🔧 null 체크 추가
  if (currentEditingTodo == null) {
    _showAlert('오류', '편집할 일정 정보를 찾을 수 없습니다.');
    return;
  }

  if (todos.isEmpty) {
    _showAlert('알림', '선택할 수 있는 다른 할 일이 없습니다.');
    return;
  }

  // 🔧 로컬 변수로 저장해서 안전하게 사용
  final editingTodo = currentEditingTodo!;
  final editingScheduleKey = currentEditingScheduleKey;

  final availableTodos = todos.where((todo) => todo.id != editingTodo.id).toList();
  
  if (availableTodos.isEmpty) {
    _showAlert('알림', '수정할 수 있는 다른 할 일이 없습니다.');
    return;
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        Map<String, bool> localExpandedGroups = {};
        for (final group in todoGroups) {
          localExpandedGroups[group.id] = true;
        }

        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('기존 할 일로 변경'),
              const SizedBox(height: 5),
              Text(
                '"${editingTodo.text}"를 다른 할 일로 변경하세요',  // 🔧 로컬 변수 사용
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          for (final group in todoGroups) {
                            localExpandedGroups[group.id] = true;
                          }
                        });
                      },
                      icon: const Icon(Icons.expand_more, size: 16),
                      label: const Text('전체 펼치기'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          for (final group in todoGroups) {
                            localExpandedGroups[group.id] = false;
                          }
                        });
                      },
                      icon: const Icon(Icons.expand_less, size: 16),
                      label: const Text('전체 접기'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: todoGroups.map((group) {
                        final groupTodos = availableTodos.where((todo) => todo.groupId == group.id).toList();
                        if (groupTodos.isEmpty) return const SizedBox.shrink();
                        
                        final isExpanded = localExpandedGroups[group.id] ?? true;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: group.color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: group.color.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    localExpandedGroups[group.id] = !isExpanded;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: group.color.withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                        color: group.color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: group.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${group.name} (${groupTodos.length}개)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              if (isExpanded) ...[
                                Column(
                                  children: groupTodos.map((todo) {
                                    return InkWell(
                                      onTap: () {
                                        // 🔧 로컬 변수 사용
                                       Navigator.pop(context); // 할 일 선택 팝업 닫기
  
                                        // 🔧 2단계: 편집 모달도 닫기
                                        setState(() {
                                          showScheduleEditModal = false;
                                          currentEditingTodo = null;
                                          currentEditingScheduleKey = '';
                                        });
                                        
                                        // 🔧 3단계: 일정 교체 실행
                                        _replaceScheduledTodo(editingScheduleKey, editingTodo, todo);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: group.color.withOpacity(0.1),
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 3,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: group.color,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    todo.text,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '생성일: ${todo.createdAt.month}/${todo.createdAt.day}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.swap_horiz,
                                              color: AppColors.secondary,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    ),
  );
}

  // 5. 새 할 일 추가 모달
  Widget _buildNewTodoForScheduleModal() {
  return AlertDialog(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('새 할 일로 변경'),
        const SizedBox(height: 5),
        Text(
          '"${currentEditingTodo?.text}"를 새로운 할 일로 변경하세요',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: double.maxFinite,
      height: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== 🔧 수정된 TextField ==========
          TextField(
            controller: newTodoController,
            decoration: InputDecoration(
              hintText: '새로운 할 일을 입력하세요 (최대 100자)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              counterText: '${newTodoText.length}/100',
            ),
            maxLines: 3,
            maxLength: 100,
            onChanged: (value) {
              // ← 🔧 setState 내부에서 StatefulBuilder 호출 (만약 StatefulBuilder 사용시)
              // ← 하지만 현재는 일반 AlertDialog이므로 그대로 setState 사용
              setState(() {
                newTodoText = value;
              });
            },
          ),
          const SizedBox(height: 15),
          
          const Text(
            '그룹 선택',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: todoGroups.map((group) {
                  final isSelected = newTodoSelectedGroupId == group.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        newTodoSelectedGroupId = group.id;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? group.color.withOpacity(0.2) : Colors.white,
                        border: Border.all(
                          color: group.color,
                          width: isSelected ? 3 : 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: group.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            group.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? group.color : Colors.grey.shade600,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          setState(() {
            showNewTodoForScheduleModal = false;
            newTodoText = '';
            newTodoSelectedGroupId = '';
            currentEditingTodo = null;
            currentEditingScheduleKey = '';
          });
          newTodoController.clear();
        },
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: (newTodoText.trim().isEmpty || newTodoSelectedGroupId.isEmpty)
            ? null
            : () {
                _createAndReplaceScheduledTodo();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
        ),
        child: const Text(
          '변경',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ],
  );
}

  // 6. 일정 교체 함수
  void _replaceScheduledTodo(String scheduleKey, Todo oldTodo, Todo newTodo) {
  setState(() {
    if (scheduledTodos.containsKey(scheduleKey)) {
      // 기존 할 일 완전 제거
      scheduledTodos[scheduleKey]!.removeWhere((todo) => todo.id == oldTodo.id);
      print('🔍 기존 일정 삭제: ${oldTodo.text}');
      
      // 리스트가 비었으면 새 리스트 생성
      if (scheduledTodos[scheduleKey]!.isEmpty) {
        scheduledTodos[scheduleKey] = [];
      }
      
      // 새 할 일 추가 (중복 체크)
      if (!scheduledTodos[scheduleKey]!.any((todo) => todo.id == newTodo.id)) {
        scheduledTodos[scheduleKey]!.add(newTodo);
        print('🔍 새 일정 추가: ${newTodo.text}');
      }
    } else {
      // 키가 없으면 새로 생성
      scheduledTodos[scheduleKey] = [newTodo];
      print('🔍 새 키로 일정 생성: ${newTodo.text}');
    }
  });
  
  _saveData();
  
  // 🔧 성공 메시지 표시 (약간의 지연 후)
  Future.delayed(Duration(milliseconds: 100), () {
    _showAlert('성공', '"${oldTodo.text}"에서 "${newTodo.text}"로 일정이 수정되었습니다.');
  });
}

  // 7. 새 할 일 생성 및 교체
  void _createAndReplaceScheduledTodo() {
  // null 체크
  if (currentEditingTodo == null) {
    _showAlert('오류', '편집할 일정 정보를 찾을 수 없습니다.');
    return;
  }
  
  // 로컬 변수로 안전하게 저장
  final editingTodo = currentEditingTodo!;
  final editingKey = currentEditingScheduleKey;
  
  // 새 할 일 생성
  final newTodo = Todo(
    id: DateTime.now().millisecondsSinceEpoch,
    text: newTodoText.trim(),
    completed: false,
    groupId: newTodoSelectedGroupId,
  );
  
  // 할 일 목록에 추가
  setState(() {
    todos.add(newTodo);
  });
  
  // 🔧 1단계: 모든 모달 닫기
  setState(() {
    showNewTodoForScheduleModal = false;
    showScheduleEditModal = false;  // 편집 모달도 닫기
    newTodoText = '';
    newTodoSelectedGroupId = '';
    currentEditingTodo = null;
    currentEditingScheduleKey = '';
  });
  newTodoController.clear();
  
  // 🔧 2단계: 일정 교체 실행
  _replaceScheduledTodo(editingKey, editingTodo, newTodo);
}

  // 8. 삭제 확인 다이얼로그
  void _showDeleteScheduleConfirmDialog(String scheduleKey, Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('"${todo.text}" 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteScheduledTodo(scheduleKey, todo.id);
              Navigator.pop(context);
              _showAlert('성공', '일정이 삭제되었습니다.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 9. 스케줄 키 포맷팅
  String _formatScheduleKey(String scheduleKey) {
    final parts = scheduleKey.split('-');
    if (parts.length >= 5) {
      final hour = parts[3];
      final minute = parts[4];
      return '${hour.padLeft(2, '0')}:${minute.padLeft(2, '0')}';
    } else if (parts.length >= 4) {
      final hour = parts[3];
      return '${hour.padLeft(2, '0')}:00';
    }
    return scheduleKey;
  }

  // ========== 여기까지 새 함수들 ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Todo 관리',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 알림 설정 버튼 추가
          Container(
            margin: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: _showNotificationSettings,
              icon: Icon(
                notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                color: Colors.white,
              ),
              tooltip: '알림 설정',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 15),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TodoInputPage(
                      todoGroups: todoGroups,
                      todos: todos,
                      onTodoAdded: _addTodo,
                      onGroupCreated: _createNewGroup,
                      onGroupUpdated: _updateGroup,
                      onGroupDeleted: _deleteGroup,
                      onTodoDeleted: _deleteTodo,
                    ),
                  ),
                );
                // 페이지에서 돌아왔을 때 상태 강제 새로고침
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Todo 추가',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: Stack(
          children: [
            Column(
              children: [
                // Todo 개수 표시
                Container(
                  margin: AppStyles.defaultMargin,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: AppStyles.cardDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatsItem('총 할 일', '${todos.length}개', AppColors.primary),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _buildStatsItem('그룹 수', '${todoGroups.length}개', AppColors.secondary),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _buildStatsItem('일정', '${totalScheduledTodos}개', AppColors.accent),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _buildStatsItem(
                        '알림', 
                        notificationsEnabled ? '활성' : '비활성', 
                        notificationsEnabled ? AppColors.primary : Colors.grey,
                      ),
                    ],
                  ),
                ),
                // 뷰 탭
                ViewTabs(
                  currentView: currentView,
                  onViewChanged: (view) {
                    setState(() {
                      currentView = view;
                    });
                  },
                ),
                // 캘린더 섹션
                Expanded(
                  child: Container(
                    margin: AppStyles.defaultMargin,
                    decoration: AppStyles.cardDecoration,
                    child: Column(
                      children: [
                        if (currentView == 'month') ...[
                          CalendarHeader(
                            title: '${currentMonth.year}년 ${currentMonth.month}월',
                            onPrevious: () {
                              setState(() {
                                currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                              });
                            },
                            onNext: () {
                              setState(() {
                                currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                              });
                            },
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildSwipeableMonthCalendar(),
                            ),
                          ),
                        ] else if (currentView == 'week') ...[
                          Expanded(child: _renderWeekSchedule()),
                        ] else ...[
                          CalendarHeader(
                            title: '${currentDayDate.year}년 ${currentDayDate.month}월 ${currentDayDate.day}일',
                            onPrevious: () {
                              setState(() {
                                currentDayDate = currentDayDate.subtract(const Duration(days: 1));
                              });
                            },
                            onNext: () {
                              setState(() {
                                currentDayDate = currentDayDate.add(const Duration(days: 1));
                              });
                            },
                          ),
                          Expanded(child: _renderDaySchedule()),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // 모달들
            if (showTodoSelectorModal) _buildTodoSelectorModal(),
            if (showScheduleEditModal) _buildScheduleEditModal(),
            if (showNewTodoForScheduleModal) _buildNewTodoForScheduleModal(),
          ],
        ),
      ),
    );
  }

void _debugScheduleState(String scheduleKey) {
  print('🔍 === 일정 상태 디버깅 ===');
  print('🔍 scheduleKey: $scheduleKey');
  print('🔍 해당 키의 일정들: ${scheduledTodos[scheduleKey]?.map((t) => t.text).toList()}');
  print('🔍 전체 스케줄 키들: ${scheduledTodos.keys.toList()}');
  print('🔍 ========================');
}

  @override
  void dispose() {
    newTodoController.dispose();
    super.dispose();
  }

  Widget _buildStatsItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/*
pubspec.yaml에 추가해야 할 dependencies:

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

android/app/src/main/AndroidManifest.xml에 추가해야 할 권한:
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<application> 태그 안에 추가:
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
</receiver>

iOS의 경우 ios/Runner/AppDelegate.swift에 추가:
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}

주요 기능:
1. 일정에 할 일을 추가할 때 자동으로 알림이 설정됩니다
2. 알림 설정에서 알림 활성화/비활성화 및 알림 시점(정시, 5분전, 10분전 등)을 설정할 수 있습니다
3. 앱 바의 종 아이콘을 통해 알림 설정에 접근할 수 있습니다
4. 일정이 삭제되면 해당 알림도 자동으로 취소됩니다
5. 알림 설정이 변경되면 모든 기존 알림이 새로운 설정에 맞게 재설정됩니다

알림은 다음과 같이 작동합니다:
- 일정 시간에 도달하기 전 설정된 시간(기본 5분 전)에 알림이 표시됩니다
- 알림 제목에는 그룹명이 포함되고, 내용에는 할 일 텍스트가 표시됩니다
- 현재 시간보다 이후인 일정에만 알림이 설정됩니다

사용법:
1. 할 일을 추가합니다
2. 캘린더에서 원하는 시간대를 탭합니다
3. 추가할 할 일을 선택합니다
4. 자동으로 해당 시간에 맞는 알림이 설정됩니다
5. 알림 설정을 변경하려면 앱 바의 종 아이콘을 탭합니다
*/