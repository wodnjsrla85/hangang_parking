import 'package:flutter/material.dart';
import 'package:hangangweb/Model/busking.dart';
import 'package:hangangweb/VM/buskingHandler.dart';

class Buskingview extends StatefulWidget {
  final BuskingHandler handler;
  const Buskingview({super.key, required this.handler});

  @override
  State<Buskingview> createState() => _BuskingviewState();
}

class _BuskingviewState extends State<Buskingview> {
  static const stateLabels = {
    0: '승인대기',
    1: '승인',
    2: '부결',
    3: '완료',
  };

  static const stateColors = {
    0: Color(0xFFf59e0b),
    1: Color(0xFF10b981),
    2: Color(0xFFef4444),
    3: Color(0xFF6b7280),
  };

  static const stateIcons = {
    0: Icons.schedule,
    1: Icons.check_circle,
    2: Icons.cancel,
    3: Icons.task_alt,
  };

  int? filterState; // null이면 전체

  @override
  void initState() {
    super.initState();
    _load();
  }
  
  Future<void> _load() async {
    final r = await widget.handler.fetchBuskingList();
    if (!mounted) return;
    if (!r.success) {
      _toast(r.message);
    }
    setState(() {});
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Color(0xFF667eea),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _changeState(Busking b, int newState) async {
    if (!mounted) return;

    // ✅ 완료(3) 선택 시: 삭제 수행
    if (newState == 3) {
      final del = await widget.handler.deleteBuskingByUserId(b.id!); // _id 기반 삭제
      if (!mounted) return;
      if (del.success) {
        _toast('완료 처리되어 삭제되었습니다.');
        await widget.handler.fetchBuskingList();  // 서버 기준 재동기화 권장
        setState(() {});
      } else {
        _toast('삭제 실패: ${del.message}');
      }
      return;
    }

    // ✅ 그 외 상태(0,1,2): 업데이트 수행
    final r = await widget.handler.updateBuskingById(
      b.id!,
      {'state': newState},
    );
    if (!mounted) return;
    if (r.success) {
      await widget.handler.fetchBuskingList();       
      _toast('상태 변경: ${stateLabels[newState]}');
      setState(() {});
    } else {
      _toast(r.message);
    }
  }

  List<Busking> get _filtered {
    final list = widget.handler.buskingList;
    if (filterState == null) return list;
    return list.where((e) => e.state == filterState).toList();
  }

  // 카테고리별 개수 계산
  int get totalCount => widget.handler.buskingList.length;
  int get pendingCount => widget.handler.buskingList.where((e) => e.state == 0).length;
  int get approvedCount => widget.handler.buskingList.where((e) => e.state == 1).length;
  int get rejectedCount => widget.handler.buskingList.where((e) => e.state == 2).length;
  int get completedCount => widget.handler.buskingList.where((e) => e.state == 3).length;

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.handler.isLoading;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2D3748),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF667eea)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.music_note, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              '버스킹 신청 관리',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        actions: [
          // 새로고침 버튼
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10b981), Color(0xFF10b981)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _load,
              tooltip: '새로고침',
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 상태 필터 섹션
          Container(
            margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '상태별 필터',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStateFilterButton('전체', null, totalCount, Icons.list, Color(0xFF667eea))),
                    SizedBox(width: 8),
                    Expanded(child: _buildStateFilterButton('승인대기', 0, pendingCount, stateIcons[0]!, stateColors[0]!)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStateFilterButton('승인', 1, approvedCount, stateIcons[1]!, stateColors[1]!)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStateFilterButton('부결', 2, rejectedCount, stateIcons[2]!, stateColors[2]!)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStateFilterButton('완료', 3, completedCount, stateIcons[3]!, stateColors[3]!)),
                  ],
                ),
              ],
            ),
          ),
          // 버스킹 신청 목록 섹션
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '버스킹 신청 목록을 불러오는 중...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                filterState == null
                                    ? '등록된 버스킹 신청이 없습니다'
                                    : '${stateLabels[filterState]} 신청이 없습니다',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '새로운 신청이 등록되면 여기에 표시됩니다',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 헤더
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF667eea).withOpacity(0.1),
                                      Color(0xFF667eea).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.music_note, color: Color(0xFF667eea), size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      '${filterState == null ? "전체" : stateLabels[filterState]} 버스킹 신청',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF667eea),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_filtered.length}건',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 스크롤 가능한 목록
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _load,
                                  color: Color(0xFF667eea),
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(16),
                                    itemCount: _filtered.length,
                                    itemBuilder: (context, index) {
                                      final b = _filtered[index];
                                      return _buildBuskingCard(b, index);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF667eea),
        onPressed: _load,
        icon: Icon(Icons.refresh, color: Colors.white),
        label: Text(
          '새로고침',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildStateFilterButton(String label, int? state, int count, IconData icon, Color color) {
    bool isSelected = filterState == state;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterState = state;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 16),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuskingCard(Busking b, int index) {
    final label = stateLabels[b.state]!;
    final color = stateColors[b.state]!;
    final icon = stateIcons[b.state]!;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 행 - 이름과 상태
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${b.name} · ${b.bandName}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // 정보 행들 - 더 컴팩트하게
            Row(
              children: [
                Expanded(child: _buildCompactInfo('📅', b.date)),
                SizedBox(width: 12),
                Expanded(child: _buildCompactInfo('🎵', b.category)),
                SizedBox(width: 12),
                Expanded(child: _buildCompactInfo('👤', b.userid)),
              ],
            ),
            
            SizedBox(height: 12),
            
            // 신청 내용 - 더 간결하게
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                b.content,
                style: TextStyle(
                  color: Color(0xFF4A5568),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            SizedBox(height: 12),
            
            // 상태 변경 - 오른쪽 정렬로 간결하게
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '상태 변경',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _StateDropdown(
                    value: b.state,
                    onChanged: (v) {
                      if (v == null || v == b.state) return;
                      _changeState(b, v);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(String emoji, String value) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 14)),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(v),
      ],
    );
  }
}

class _StateDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int?> onChanged;
  const _StateDropdown({required this.value, required this.onChanged});

  static const _items = [
    DropdownMenuItem(value: 0, child: Text('승인대기', style: TextStyle(fontSize: 12))),
    DropdownMenuItem(value: 1, child: Text('승인', style: TextStyle(fontSize: 12))),
    DropdownMenuItem(value: 2, child: Text('부결', style: TextStyle(fontSize: 12))),
    DropdownMenuItem(value: 3, child: Text('완료', style: TextStyle(fontSize: 12))),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      items: _items,
      onChanged: onChanged,
      underline: SizedBox(),
      style: TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 12,
      ),
      dropdownColor: Colors.white,
      isDense: true,
    );
  }
}