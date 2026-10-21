import 'package:flutter/material.dart';

import 'app_state.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _service = ActivationService();

  String _role = 'customer';
  bool _codeSent = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.length < 10) {
      setState(() => _error = 'أدخل الاسم ورقم هاتف صحيح');
      return;
    }
    final code = await _service.sendCode(phone);
    if (!mounted) return;
    setState(() {
      _codeSent = true;
      _error = null;
    });
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رمز التفعيل (وضع تجريبي)'),
        content: Text(
          code,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, letterSpacing: 6, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
        ],
      ),
    );
  }

  void _verify() {
    if (_service.verify(_phone.text.trim(), _code.text.trim())) {
      appState.activate(_name.text.trim(), _phone.text.trim(), _role);
    } else {
      setState(() => _error = 'الرمز غير صحيح، حاول مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.delivery_dining, size: 84, color: scheme.primary),
                  const SizedBox(height: 8),
                  const Text('سريع ديليفري',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('فعّل حسابك للبدء',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 28),
                  if (!_codeSent) ...[
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                          labelText: 'الاسم', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'رقم الهاتف', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'customer', label: Text('عميل'), icon: Icon(Icons.shopping_bag)),
                        ButtonSegment(value: 'courier', label: Text('مندوب توصيل'), icon: Icon(Icons.two_wheeler)),
                      ],
                      selected: {_role},
                      onSelectionChanged: (s) => setState(() => _role = s.first),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _sendCode, child: const Padding(
                      padding: EdgeInsets.all(12), child: Text('إرسال رمز التفعيل'))),
                  ] else ...[
                    Text('أدخل الرمز المرسل إلى ${_phone.text.trim()}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 6),
                      decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _verify, child: const Padding(
                      padding: EdgeInsets.all(12), child: Text('تفعيل'))),
                    TextButton(
                      onPressed: () => setState(() {
                        _codeSent = false;
                        _code.clear();
                        _error = null;
                      }),
                      child: const Text('تعديل البيانات'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
