import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 弹出支付密码输入框，返回输入的6位密码，取消返回null
Future<String?> showPaymentPasswordDialog() {
  return Get.dialog<String>(_PaymentPasswordDialog());
}

/// 6位 PIN 输入组件（独立使用）
class PinInputWidget extends StatefulWidget {
  final Function(String pin) onSubmit;
  const PinInputWidget({super.key, required this.onSubmit});

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  void _checkComplete() {
    final pin = _ctrls.map((c) => c.text).join();
    if (pin.length == 6) {
      widget.onSubmit(pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          width: 44,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _ctrls[i].text.isNotEmpty ? accentColor : Colors.grey[300]!,
                width: 2,
              ),
            ),
          ),
          child: TextField(
            controller: _ctrls[i],
            focusNode: _nodes[i],
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            obscureText: true,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && i < 5) {
                _nodes[i + 1].requestFocus();
              } else if (value.isEmpty && i > 0) {
                _nodes[i - 1].requestFocus();
              }
              _checkComplete();
            },
          ),
        );
      }),
    );
  }
}

class _PaymentPasswordDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('输入支付密码', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF212121),
            )),
            const SizedBox(height: 8),
            Text('请确认转账信息', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 24),
            PinInputWidget(
              onSubmit: (pin) => Get.back(result: pin),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.back(result: null),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
}
