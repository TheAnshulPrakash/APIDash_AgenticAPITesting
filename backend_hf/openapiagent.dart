import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiMessage {
  final String role;
  final String content;
  final Map<String, dynamic>? apiJson; // Stores the AI's structured request

  ApiMessage({required this.role, required this.content, this.apiJson});
}

class OpenApiAgent extends ChangeNotifier {
  final String model = 'qwen2.5:7b-instruct';
  final String openApiSpec;
  final List<ApiMessage> messages = [];
  bool isLoading = false;

  OpenApiAgent({required this.openApiSpec}) {
    _initSystemPrompt();
  }

  void _initSystemPrompt() {
    messages.add(ApiMessage(
      role: 'system',
      content:
          '''You are an API execution planner. Analyze the OpenAPI: $openApiSpec.
      Return ONLY JSON:
      {
        "description": "Explanation",
        "request": {"method": "GET|POST", "path": "/path", "headers": {}, "body": {}},
        "is_last": false
      }
      If the previous request failed, analyze the error and try to fix it.''',
    ));
  }

  Future<void> processStep(String userInstruction) async {
    isLoading = true;
    notifyListeners();

    // 1. Add user input to history
    messages.add(ApiMessage(role: 'user', content: userInstruction));

    try {
      // 2. Get AI Plan
      final aiRaw = await _fetchOllama();
      final Map<String, dynamic> plan = jsonDecode(_cleanJson(aiRaw));

      messages.add(ApiMessage(
          role: 'assistant', content: plan['description'], apiJson: plan));
      notifyListeners();

      // 3. Execute the API request suggested by AI
      await _executeApiRequest(plan);
    } catch (e) {
      messages.add(ApiMessage(role: 'system', content: "Local Error: $e"));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _executeApiRequest(Map<String, dynamic> plan) async {
    final reqData = plan['request'];
    final url = Uri.parse(
        "http://localhost:8000${reqData['path']}"); // Change to your API base

    messages.add(ApiMessage(
        role: 'system',
        content: "⏳ Executing ${reqData['method']} ${reqData['path']}..."));
    notifyListeners();

    try {
      http.Response response;
      final headers = Map<String, String>.from(reqData['headers'] ?? {});
      final body = jsonEncode(reqData['body']);

      switch (reqData['method'].toString().toUpperCase()) {
        case 'POST':
          response = await http.post(url, headers: headers, body: body);
          break;
        default:
          response = await http.get(url, headers: headers);
      }

      // 4. Feed result back to AI memory
      String feedback =
          "API Result: Status ${response.statusCode}, Body: ${response.body}";
      messages.add(ApiMessage(
          role: 'system',
          content: response.statusCode < 300 ? "✅ PASS" : "❌ FAIL"));

      // We push the actual result to the AI history so the next 'Enter' or 'Fix' knows what happened
      messages.add(ApiMessage(
          role: 'user',
          content:
              "The previous request returned: $feedback. What is the next step?"));
    } catch (e) {
      messages.add(ApiMessage(
          role: 'user',
          content:
              "The request failed with error: $e. Please fix the request."));
    }
  }

  Future<String> _fetchOllama() async {
    final res = await http.post(
      Uri.parse('http://localhost:11434/api/chat'),
      body: jsonEncode({
        'model': model,
        'messages': messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        'stream': false,
        'format': 'json',
      }),
    );
    return jsonDecode(res.body)['message']['content'];
  }

  String _cleanJson(String raw) =>
      raw.replaceAll('```json', '').replaceAll('```', '').trim();
}

void main() => runApp(MaterialApp(home: AgenticApp(), theme: ThemeData.dark()));

class AgenticApp extends StatefulWidget {
  @override
  State<AgenticApp> createState() => _AgenticAppState();
}

class _AgenticAppState extends State<AgenticApp> {
  late OpenApiAgent agent;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    agent = OpenApiAgent(openApiSpec: "{...your_json_spec_here...}");
    agent.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ollama API Agent")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: agent.messages.length,
              itemBuilder: (context, i) {
                final m = agent.messages[i];
                if (m.role == 'system' && !m.content.contains('plan')) {
                  return _StatusChip(text: m.content);
                }
                return _ChatBubble(message: m);
              },
            ),
          ),
          if (agent.isLoading) LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: "Enter instruction (e.g. 'Borrow book 1')"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    agent.processStep(_controller.text);
                    _controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ApiMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    bool isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueGrey[800] : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: message.role == 'assistant'
              ? Border.all(color: Colors.blueAccent)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.role.toUpperCase(),
                style: TextStyle(fontSize: 10, color: Colors.blue)),
            SizedBox(height: 4),
            Text(message.content),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    Color color = text.contains('PASS')
        ? Colors.green
        : text.contains('FAIL')
            ? Colors.red
            : Colors.grey;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
