import 'package:apidash/providers/providers.dart';
import 'package:apidash/screens/home_page/editor_pane/details_card/request_pane/ai_request/agentic_api_testing.dart';
import 'package:apidash/screens/home_page/editor_pane/details_card/request_pane/ai_request/ai_helper.dart';
import 'package:apidash/screens/home_page/editor_pane/details_card/request_pane/ai_request/deterministic_execute.dart';
import 'package:apidash/widgets/widgets.dart';
import 'package:apidash_design_system/apidash_design_system.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import 'package:apidash/models/models.dart';
import 'package:apidash_core/apidash_core.dart';

import 'dart:convert';

class _AIOverlayDialog extends ConsumerStatefulWidget {
  final String jsonInput;
  final String endpoint;
  const _AIOverlayDialog({required this.jsonInput, required this.endpoint});

  @override
  ConsumerState<_AIOverlayDialog> createState() => _AIOverlayState();
}

class _AIOverlayState extends ConsumerState<_AIOverlayDialog> {
  final StringBuffer _output = StringBuffer();
  final ScrollController _scrollController = ScrollController();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _runAPITest();
  }

  Future<void> _runAPITest() async {
    final suite = jsonDecode(widget.jsonInput);

    final runner = ApiTestRunner(
      widget.endpoint,
      logger: (line) {
        if (!mounted) return;
        setState(() => _output.writeln(line));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });
      },
    );

    await runner.runSuite(suite);
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedRequestModelProvider);
    debugPrint(
        'Selected request id: ${selected?.id}, name: ${selected?.name}, type: ${selected?.apiType}');
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 800),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 24, 24, 24),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              _done ? "Tests Complete" : "AI Agent Generating Tests",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _done ? "All tests finished." : "Running suite...",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              height: 300,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(17, 24, 39, 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _output
                      .toString()
                      .split(RegExp(r'(?=\[(PASS|FAIL)\])'))
                      .map((line) {
                    if (line.trim().isEmpty) return const SizedBox.shrink();

                    Color textColor = Colors.grey;
                    bool error = true;
                    if (line.startsWith('[PASS]')) {
                      error = false;
                      textColor = const Color.fromRGBO(74, 222, 128, 1);
                    } else if (line.startsWith('[FAIL]')) {
                      textColor = const Color.fromRGBO(248, 113, 113, 0.937);
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        width: double.infinity,
                        alignment: AlignmentGeometry.centerLeft,
                        decoration: BoxDecoration(
                            color: textColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 500,
                                    child: Text(
                                      line,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'monospace',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                      tooltip: "Ask AI",
                                      onPressed: () async {
                                        await explainTestLineWithDashAI(
                                          context: context,
                                          explainerRequestId: selected!.id,
                                          jsonInput: widget.jsonInput,
                                          line: line,
                                        );
                                      },
                                      icon: Icon(Icons.auto_awesome))
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _done ? () => Navigator.pop(context) : null,
                  child: const Text("Done"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AIRequestPromptSection extends ConsumerStatefulWidget {
  const AIRequestPromptSection({super.key});

  @override
  ConsumerState<AIRequestPromptSection> createState() =>
      _AIRequestPromptSectionState();
}

class _AIRequestPromptSectionState
    extends ConsumerState<AIRequestPromptSection> {
  bool optFunctional = true;
  bool optEdgeCases = true;
  bool optErrorHandling = false;
  bool optSecurity = false;
  bool optStressTest = false;

  final TextEditingController urlTextController = TextEditingController();

  int inputMode = 0;
  String? uploadedFileName;
  String? uploadedFileContent;

  Future<void> _pickSchemaFile(String selectedId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'yaml', 'yml'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        setState(() {
          uploadedFileName = result.files.single.name;
          uploadedFileContent = content;
        });

        final notifier = ref.read(collectionStateNotifierProvider.notifier);
        final req = notifier.getRequestModel(selectedId);
        final ai = req?.aiRequestModel;
        if (ai != null) {
          notifier.update(aiRequestModel: ai.copyWith(userPrompt: content));
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _clearSchemaFile(String selectedId) {
    setState(() {
      uploadedFileName = null;
      uploadedFileContent = null;
    });
    final notifier = ref.read(collectionStateNotifierProvider.notifier);
    final req = notifier.getRequestModel(selectedId);
    final ai = req?.aiRequestModel;
    if (ai != null) {
      notifier.update(aiRequestModel: ai.copyWith(userPrompt: ''));
    }
  }

  String? getPrintableAiText(RequestModel? request) {
    if (request == null) return null;
    if (request.apiType != APIType.ai) return null;

    final res = request.httpResponseModel;
    if (res == null) return null;

    final isSse = (res.sseOutput?.isNotEmpty ?? false);
    if (isSse) return res.sseOutput!.join('\n');

    return res.formattedBody ?? res.body;
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final systemPrompt = ref.watch(selectedRequestModelProvider
        .select((value) => value?.aiRequestModel?.systemPrompt));
    final userPrompt = ref.watch(selectedRequestModelProvider
        .select((value) => value?.aiRequestModel?.userPrompt));
    final aiRequestModel = ref
        .read(collectionStateNotifierProvider.notifier)
        .getRequestModel(selectedId!)
        ?.aiRequestModel;

    if (aiRequestModel == null) {
      return kSizedBoxEmpty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Text(
              'Select Agent Context Source',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5.0, top: 4.0, bottom: 8.0),
            child: Text(
              'Define how the AI maps the API. Provide a full OpenAPI schema for deterministic, context-aware generation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          SizedBox(
            height: 45,
            child: TextField(
              controller: urlTextController,
              decoration: InputDecoration(
                hintText: 'Target API URL (e.g., https://localhost:8000)',
                prefixIcon: const Icon(Icons.http),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          kVSpacer10,
          SizedBox(
            height: 45,
            child: TextField(
              readOnly: true,
              controller: TextEditingController(text: uploadedFileName ?? ''),
              decoration: InputDecoration(
                hintText: 'Upload local .yaml or .json schema file',
                prefixIcon: const Icon(Icons.data_object),
                suffixIcon: uploadedFileName != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () => _clearSchemaFile(selectedId),
                        tooltip: 'Remove file',
                      )
                    : IconButton(
                        icon: const Icon(Icons.folder_open, color: Colors.blue),
                        onPressed: () => _pickSchemaFile(selectedId),
                        tooltip: 'Browse local files',
                      ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                filled: uploadedFileName != null,
                fillColor: uploadedFileName != null
                    ? const Color.fromRGBO(33, 150, 243, 0.05)
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          kVSpacer20,
          const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Text(
              'Select AI Tests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5.0, top: 4.0, bottom: 8.0),
            child: Text(
              'Configure the autonomous testing constraints. The agent will generate workflows and assertions based on these selected parameters.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Functional Correctness'),
                  subtitle: const Text(
                      'Generate standard valid JSON payloads & 200 OK assertions.'),
                  value: optFunctional,
                  onChanged: (val) =>
                      setState(() => optFunctional = val ?? false),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  title: const Text('Edge Cases & Boundaries'),
                  subtitle: const Text(
                      'Inject boundary values and null states into parameters.'),
                  value: optEdgeCases,
                  onChanged: (val) =>
                      setState(() => optEdgeCases = val ?? false),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  title: const Text('Auto-Correction (Self-Healing)'),
                  subtitle: const Text(
                      'Agent intercepts 4xx/5xx errors and attempts to patch schemas confirming from the user. (Agentic)'),
                  value: optErrorHandling,
                  onChanged: (val) =>
                      setState(() => optErrorHandling = val ?? false),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  title: const Text('Security Validation'),
                  subtitle: const Text(
                      'Test for missing auth headers and basic workflow vulnerabilities.'),
                  value: optSecurity,
                  onChanged: (val) =>
                      setState(() => optSecurity = val ?? false),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  title: const Text('Exponential Stress Test'),
                  subtitle: const Text(
                      'Dart isolate to exponentially scale concurrent load (Resolves #100).'),
                  value: optStressTest,
                  activeColor: Colors.deepPurple,
                  onChanged: (val) =>
                      setState(() => optStressTest = val ?? false),
                ),
              ],
            ),
          ),
          kVSpacer20,
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: kPh12,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () {
                    final request = ref
                        .read(collectionStateNotifierProvider.notifier)
                        .getRequestModel(selectedId!);

                    final text = getPrintableAiText(request);

                    if (text == null || text.isEmpty) {
                      debugPrint('[AI_OUTPUT] <empty>');
                      return;
                    }

                    debugPrint('AI OUTPUT');
                    debugPrint(text);
                    debugPrint('DONE');
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _AIOverlayDialog(
                        jsonInput: text
                            .trim()
                            .replaceAll(
                                RegExp(r'^```[a-z]*\n?', multiLine: false), '')
                            .replaceAll(RegExp(r'```$'), '')
                            .trim(),
                        endpoint: urlTextController.text,
                      ),
                    );
                  },
                  label: SizedBox(
                    width: 100,
                    child: Text(
                      "Run basic tests",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              kHSpacer10,
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: kPh12,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () {
                    final schema = uploadedFileContent;
                    final baseUrl = urlTextController.text;

                    if (schema == null || schema.isEmpty) {
                      // Optional: Show a snackbar or error if no schema is uploaded
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Please upload an OpenAPI schema first.")),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible:
                          true, // Allow closing by clicking outside
                      builder: (context) => AgenticApp(
                          openApi: schema,
                          endpoint: baseUrl.isEmpty
                              ? "http://localhost:8000"
                              : baseUrl),
                    );
                  },
                  label: SizedBox(
                    width: 100,
                    child: Text(
                      "Go Agentic !",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          kVSpacer20,
          const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Text(
              'Manual Overrides (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5.0, top: 4.0, bottom: 8.0),
            child: Text(
              'Provide specific custom rules or headers to guide the agent\'s generation logic.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('System Prompt', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: TextFieldEditor(
                        key: Key("$selectedId-aireq-sysprompt-body"),
                        fieldKey: "$selectedId-aireq-sysprompt-body",
                        initialValue: systemPrompt,
                        onChanged: (String value) {
                          ref
                              .read(collectionStateNotifierProvider.notifier)
                              .update(
                                  aiRequestModel: aiRequestModel.copyWith(
                                      systemPrompt: value));
                        },
                        hintText: 'Enter System Prompt',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User Prompt / Input',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: TextFieldEditor(
                        key: Key("$selectedId-aireq-userprompt-body"),
                        fieldKey: "$selectedId-aireq-userprompt-body",
                        initialValue: userPrompt,
                        onChanged: (String value) {
                          ref
                              .read(collectionStateNotifierProvider.notifier)
                              .update(
                                  aiRequestModel: aiRequestModel.copyWith(
                                      userPrompt: value));
                        },
                        hintText: 'Enter User Prompt',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
