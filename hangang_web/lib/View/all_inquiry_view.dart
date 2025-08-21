import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hangangweb/VM/inquiryHandler.dart';
import 'package:hangangweb/View/login_view.dart';
import '../Model/inquiry.dart';
import 'answer_inquiry.dart';

class AllInquiryView extends StatefulWidget {
  const AllInquiryView({super.key});

  @override
  State<AllInquiryView> createState() => _AllInquiryViewState();
}

class _AllInquiryViewState extends State<AllInquiryView> {
  final InquiryHandler handler = InquiryHandler();
  bool isLoading = true;
  String selectedCategory = '전체'; // 선택된 카테고리

  @override
  void initState() {
    super.initState();
    loadInquiries();
  }

  Future<void> loadInquiries() async {
    await handler.fetchInquiries();
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  // 카테고리에 따른 문의 필터링
  List<Inquiry> get filteredInquiries {
    switch (selectedCategory) {
      case '답변요망':
        return handler.inquiries.where((inquiry) => inquiry.state != '답변완료').toList();
      case '답변완료':
        return handler.inquiries.where((inquiry) => inquiry.state == '답변완료').toList();
      default: // '전체'
        return handler.inquiries;
    }
  }

  // 카테고리별 개수 계산
  int get totalCount => handler.inquiries.length;
  int get pendingCount => handler.inquiries.where((inquiry) => inquiry.state != '답변완료').length;
  int get completedCount => handler.inquiries.where((inquiry) => inquiry.state == '답변완료').length;

  @override
  Widget build(BuildContext context) {
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
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.assignment, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              '문의 관리',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ],//Testß
        ),
        actions: [
          // 관리자 정보 표시
          if (handler.isLoggedIn)
            Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF667eea).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle, 
                    color: Color(0xFF667eea), size: 16),
                  SizedBox(width: 6),
                  Text(
                    '${handler.currentAdmin?.id ?? "관리자"}',
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          // 새로고침 버튼
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10b981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() => isLoading = true);
                loadInquiries();
              },
              tooltip: '새로고침',
            ),
          ),
          
          // 로그아웃 버튼
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFef4444), Color(0xFFdc2626)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.logout, color: Color(0xFFef4444)),
                        SizedBox(width: 8),
                        Text('로그아웃'),
                      ],
                    ),
                    content: Text('정말 로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('취소', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFef4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('로그아웃', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                
                if (result == true) {
                  await handler.adminLogout();
                  Navigator.pushReplacement(context, 
                    MaterialPageRoute(builder: (context) => LoginView()));
                }
              },
              tooltip: '로그아웃',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터 섹션
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 제목
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Color(0xFF667eea), size: 20),
                    SizedBox(width: 8),
                    Text(
                      '카테고리 필터',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // 카테고리 버튼들
                Row(
                  children: [
                    _buildCategoryButton('전체', totalCount, Icons.list, Color(0xFF667eea)),
                    SizedBox(width: 12),
                    _buildCategoryButton('답변요망', pendingCount, Icons.schedule, Color(0xFFf59e0b)),
                    SizedBox(width: 12),
                    _buildCategoryButton('답변완료', completedCount, Icons.check_circle, Color(0xFF10b981)),
                  ],
                ),
              ],
            ),
          ),
          
          // 문의 목록 섹션
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
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
                          '문의 목록을 불러오는 중...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredInquiries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            selectedCategory == '전체' 
                              ? '등록된 문의가 없습니다'
                              : '$selectedCategory 문의가 없습니다',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '새로운 문의가 등록되면 여기에 표시됩니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
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
                                    Color(0xFF764ba2).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.list_alt, 
                                    color: Color(0xFF667eea), size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    '$selectedCategory 문의 목록',
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
                                      '${filteredInquiries.length}건',
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
                            
                            // 스크롤 가능한 테이블
                            Expanded(
                              child: SingleChildScrollView(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: MediaQuery.of(context).size.width - 80,
                                    ),
                                    child: DataTable(
                                      columnSpacing: 24,
                                      horizontalMargin: 20,
                                      headingRowHeight: 56,
                                      dataRowHeight: 72,
                                      headingRowColor: MaterialStateProperty.all(
                                        Color(0xFFF8FAFC),
                                      ),
                                      columns: [
                                        DataColumn(
                                          label: _buildColumnHeader('순서', Icons.numbers),
                                        ),
                                        DataColumn(
                                          label: _buildColumnHeader('제목', Icons.title),
                                        ),
                                        DataColumn(
                                          label: _buildColumnHeader('작성자', Icons.person),
                                        ),
                                        DataColumn(
                                          label: _buildColumnHeader('문의일자', Icons.calendar_today),
                                        ),
                                        DataColumn(
                                          label: _buildColumnHeader('상태', Icons.info),
                                        ),
                                        DataColumn(
                                          label: _buildColumnHeader('답변', Icons.reply),
                                        ),
                                      ],
                                      rows: List.generate(filteredInquiries.length, (index) {
                                        final inquiry = filteredInquiries[index];
                                        return DataRow(
                                          color: MaterialStateProperty.resolveWith<Color?>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(MaterialState.hovered)) {
                                                return Color(0xFF667eea).withOpacity(0.05);
                                              }
                                              return index % 2 == 0 
                                                ? Colors.grey.shade50 
                                                : Colors.white;
                                            },
                                          ),
                                          cells: [
                                            DataCell(_buildCellContent('${index + 1}')),
                                            DataCell(_buildTitleCell(inquiry.title)),
                                            DataCell(_buildCellContent(inquiry.userID)),
                                            DataCell(_buildCellContent(inquiry.qDate)),
                                            DataCell(_buildStatusCell(inquiry.state)),
                                            DataCell(_buildActionCell(inquiry, index)),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category, int count, IconData icon, Color color) {
    bool isSelected = selectedCategory == category;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = category;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ] : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
              SizedBox(height: 8),
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeader(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Color(0xFF667eea)),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCellContent(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF4A5568),
        ),
      ),
    );
  }

  Widget _buildTitleCell(String title) {
    return Container(
      constraints: BoxConstraints(maxWidth: 200),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    Color statusColor;
    Color bgColor;
    IconData statusIcon;
    
    switch (status) {
      case '답변완료':
        statusColor = Color(0xFF10b981);
        bgColor = Color(0xFF10b981).withOpacity(0.1);
        statusIcon = Icons.check_circle;
        break;
      case '대기중':
        statusColor = Color(0xFFf59e0b);
        bgColor = Color(0xFFf59e0b).withOpacity(0.1);
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Color(0xFF6b7280);
        bgColor = Color(0xFF6b7280).withOpacity(0.1);
        statusIcon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCell(Inquiry inquiry, int index) {
    if (inquiry.state == '답변완료') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF10b981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done, size: 16, color: Color(0xFF10b981)),
            SizedBox(width: 4),
            Text(
              '완료',
              style: TextStyle(
                color: Color(0xFF10b981),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Get.to(
            () => AnswerInquiry(
              inquiry: inquiry,
              handler: handler,
            ),
          );
          if (result == true) {
            await handler.refreshAllData();
            setState(() {});
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.edit, size: 16, color: Colors.white),
        label: Text(
          '답변하기',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}