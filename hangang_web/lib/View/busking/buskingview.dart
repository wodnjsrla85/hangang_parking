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
    0: Colors.orange,
    1: Colors.green,
    2: Colors.red,
    3: Colors.blueGrey,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
  //ㅎㅎ
  List<Busking> get _filtered {
    final list = widget.handler.buskingList;
    if (filterState == null) return list;
    return list.where((e) => e.state == filterState).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.handler.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('버스킹 신청 관리'),
        actions: [
          // 상태 필터
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: filterState,
                hint: const Text('전체', style: TextStyle(color: Colors.white)),
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.white,
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem(value: null, child: Text('전체')),
                  ...stateLabels.entries.map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text('${e.value} (${e.key})'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => filterState = v),
              ),
            ),
          ),
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Center(child: Text('신청 내역이 없습니다.')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final b = _filtered[index];
                      final label = stateLabels[b.state]!;
                      final color = stateColors[b.state]!;

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 1.5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(
                            children: [
                              Expanded(
                                child: 
                                Text(
                                  '${b.name} · ${b.bandName}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(label, style: const TextStyle(color: Colors.white)),
                                backgroundColor: color,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: -6,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        _kv('날짜', b.date),
                                        _kv('카테고리', b.category),
                                        _kv('신청자ID', b.userid),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  b.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          trailing: SizedBox(
                            width: 150,
                            child: _StateDropdown(
                              value: b.state,
                              onChanged: (v) {
                                if (v == null || v == b.state) return;
                                _changeState(b, v);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.download),
        label: const Text('불러오기'),
        onPressed: _load,
      ),
    );
  }
//ㅎㅎ구
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
    DropdownMenuItem(value: 0, child: Text('승인대기')),
    DropdownMenuItem(value: 1, child: Text('승인')),
    DropdownMenuItem(value: 2, child: Text('부결')),
    DropdownMenuItem(value: 3, child: Text('완료')),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      items: _items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}