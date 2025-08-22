import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hangangweb/VM/inquiryHandler.dart';
import '../../Model/inquiry.dart';

class AnswerInquiry extends StatefulWidget {
  final Inquiry inquiry;
  final InquiryHandler handler;
  final bool isViewMode; // 보기 모드 여부

  AnswerInquiry({
    Key? key,
    required this.inquiry,
    required this.handler,
    this.isViewMode = false, // 기본값은 false (편집 모드)
  }) : super(key: key);

  @override
  State<AnswerInquiry> createState() => _AnswerInquiryState();
}

class _AnswerInquiryState extends State<AnswerInquiry> {
  final TextEditingController controller = TextEditingController();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isViewMode && widget.inquiry.answerContent?.isNotEmpty == true) {
      controller.text = widget.inquiry.answerContent!;
    }
  }

  Future<void> submitAnswer() async {
    if (controller.text.trim().isEmpty) {
      Get.snackbar(
        '입력 오류',
        '답변 내용을 입력해주세요',
        icon: Icon(Icons.warning, color: Colors.white),
        backgroundColor: Color(0xFFf59e0b),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() => isSubmitting = true);

    final result = await widget.handler.updateInquiry(
      widget.inquiry.id,
      controller.text,
    );

    setState(() => isSubmitting = false);

    if (result.success) {
      Get.snackbar(
        '성공',
        '답변 등록 성공!',
        icon: Icon(Icons.check_circle, color: Colors.white),
        backgroundColor: Color(0xFF10b981),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      // ✅ Navigator.pop → Get.back 으로 변경
      Get.back(result: true,closeOverlays: true);
    } else {
      Get.snackbar(
        '오류',
        result.message ?? '답변 실패',
        icon: Icon(Icons.error, color: Colors.white),
        backgroundColor: Color(0xFFef4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = widget.inquiry.state == '답변완료';
    bool canEdit = !widget.isViewMode && !isCompleted;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2D3748),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_back, color: Color(0xFF667eea), size: 20),
          ),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isViewMode
                      ? [Color(0xFF3b82f6), Color(0xFF3b82f6)]
                      : [Color(0xFF3b82f6), Color(0xFF3b82f6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.isViewMode ? Icons.article : Icons.edit,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.isViewMode ? "문의 상세보기" : "답변 작성",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 문의 정보 카드
              _buildInquiryInfoCard(isCompleted),
              SizedBox(height: 20),
              // 답변 섹션 카드
              _buildAnswerSection(canEdit, isCompleted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInquiryInfoCard(bool isCompleted) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.question_answer,
                      color: Color(0xFF667eea), size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '문의 내용',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Color(0xFF10b981).withOpacity(0.1)
                        : Color(0xFFf59e0b).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.schedule,
                        size: 14,
                        color: isCompleted
                            ? Color(0xFF10b981)
                            : Color(0xFFf59e0b),
                      ),
                      SizedBox(width: 4),
                      Text(
                        widget.inquiry.state,
                        style: TextStyle(
                          color: isCompleted
                              ? Color(0xFF10b981)
                              : Color(0xFFf59e0b),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // _buildInfoRow(Icons.tag, '문의 ID', widget.inquiry.id),
            SizedBox(height: 16),
            _buildInfoRow(Icons.title, '제목', widget.inquiry.title),
            SizedBox(height: 16),
            _buildInfoRow(Icons.person, '작성자', widget.inquiry.userID),
            SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, '문의일자', widget.inquiry.qDate),
            if (widget.inquiry.aDate?.isNotEmpty == true) ...[
              SizedBox(height: 16),
              _buildInfoRow(Icons.schedule, '답변일자', widget.inquiry.aDate!),
            ],
            SizedBox(height: 20),
            Divider(color: Colors.grey.shade200),
            SizedBox(height: 20),
            // 문의 내용
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.message,
                      color: Color(0xFF667eea), size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '문의 내용',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          widget.inquiry.content,
                          style: TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSection(bool canEdit, bool isCompleted) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [Color(0xFF10b981).withOpacity(0.3),
                             Color(0xFF10b981).withOpacity(0.3)]
                          : [Color(0xFFf59e0b).withOpacity(0.3),
                             Color(0xFFf59e0b).withOpacity(0.3)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.reply,
                    color: isCompleted ? Color(0xFF10b981) : Color(0xFFf59e0b),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  isCompleted ? '답변 내용' : '답변 작성',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // 답변 입력 필드
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.isViewMode
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: TextField(
                controller: controller,
                maxLines: 8,
                readOnly: widget.isViewMode,
                style: TextStyle(fontSize: 15, height: 1.5),
                decoration: InputDecoration(
                  hintText: widget.isViewMode
                      ? (isCompleted ? '' : '답변이 아직 등록되지 않았습니다.')
                      : '고객에게 전달할 답변을 작성해주세요...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: widget.isViewMode
                        ? BorderSide.none
                        : BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: widget.isViewMode
                        ? BorderSide.none
                        : BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: widget.isViewMode
                        ? BorderSide.none
                        : BorderSide(color: Color(0xFFf59e0b)),
                  ),
                  filled: true,
                  fillColor: widget.isViewMode
                      ? (isCompleted ? Color(0xFFF0FDF4) : Color(0xFFFEF2F2))
                      : Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.all(20),
                ),
              ),
            ),
            if (canEdit) ...[
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFf59e0b), Color(0xFFf59e0b)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10b981).withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : submitAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    '답변 등록 중...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '답변 등록',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.isViewMode && isCompleted) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF10b981).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Color(0xFF10b981), size: 20),
                    SizedBox(width: 12),
                    Text(
                      '답변이 완료되었습니다',
                      style: TextStyle(
                        color: Color(0xFF10b981),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Color(0xFF667eea), size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Color(0xFF4A5568),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
