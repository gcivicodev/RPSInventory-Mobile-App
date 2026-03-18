import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:rpsinventory/src/providers/auth_provider.dart';
import 'package:rpsinventory/src/config/main_config.dart';

class ViewConduceForms extends ConsumerStatefulWidget {
  final int conduceId;
  final String patientPlanNumber;

  const ViewConduceForms({
    super.key,
    required this.conduceId,
    required this.patientPlanNumber,
  });

  @override
  ConsumerState<ViewConduceForms> createState() => _ViewConduceFormsState();
}

class _ViewConduceFormsState extends ConsumerState<ViewConduceForms> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );

    _loadForm();
  }

  void _loadForm() {
    final authState = ref.read(authProvider);
    final token = authState.token ?? '';

    _controller.loadRequest(
      Uri.parse('${MainConfig.baseApiUrl}public/forms-links'),
      headers: {
        'X-User-Token': token,
        'X-App-Data-PPN': widget.patientPlanNumber,
        'X-App-Data-Conduce': widget.conduceId.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formularios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadForm(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
