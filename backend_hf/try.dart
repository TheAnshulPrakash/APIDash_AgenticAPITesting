import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class OpenApiAgent {
  final String model =
      'qwen2.5:7b-instruct'; // Use 'deepseek-r1' for better reasoning
  final String openApiSpec;
  final List<Map<String, String>> _messages = [];

  OpenApiAgent({required this.openApiSpec}) {
    _messages.add({
      'role': 'system',
      'content': '''You are an API execution planner.

Your job is to analyze a provided OpenAPI specification and help the user interact with the API in an Agentic way step-by-step by crafting http requests.

Behavior rules:

1. Carefully read the OpenAPI specification.
2. Determine the correct sequence of HTTP calls required to fulfill the user's request.
3. Produce ONE request at a time.
4. Always return your response strictly as JSON.
5. Do NOT produce explanations outside JSON.

Each response must contain the following fields:

{
  "description": "Human readable explanation of what this request does",
  "request": {
    "method": "GET | POST | PUT | PATCH | DELETE",
    "path": "/endpoint/path",
    "headers": {
      "Content-Type": "application/json"
    },
    "query_params": {},
    "body": {},
  },
  "is_last": false,
  "next_prompt": "Ask the user if they want to continue with the next request from openAPI or perform a custom action."
}

Important rules:

- Only generate ONE HTTP request per response.
- `is_last` must be true only when the task is complete.
- If the API requires parameters that the user has not provided, take related dummy values.
- If the workflow requires multiple steps (for example: create user → add book → borrow book), plan them sequentially.

'''
    });
  }

  Future<void> start() async {
    print('--- 🚀 OpenAPI Agent Started ---');
    bool isLast = false;

    while (!isLast) {
      stdout.write(
          '\nYour Request/Instruction (or press Enter for next logical step): ');
      String? userInput = stdin.readLineSync();
      if (userInput == null || userInput.toLowerCase() == 'exit') break;

      _messages.add({
        'role': 'user',
        'content': userInput.isEmpty
            ? "Give me the next logical API request step."
            : userInput
      });

      stdout.write('🤖 Analyzing Spec & Generating Request...');

      try {
        final aiRawResponse = await _fetchOllamaResponse();
        // Clean the AI response (remove markdown code blocks if present)
        final cleanJson = aiRawResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final Map<String, dynamic> step = jsonDecode(cleanJson);

        isLast = step['is_last_step'] ?? false;

        print('\n\n--- NEXT STEP ---');
        print('📝 Description: ${step['description']}');
        print('💻 Generated Dart Code:\n');
        print('-------------------------------------------');
        print(step);
        print('-------------------------------------------');

        _messages.add({'role': 'assistant', 'content': aiRawResponse});

        if (!isLast) {
          stdout.write(
              '\nDo you want to proceed to the next step? (y/n) or type a custom thought: ');
          String? choice = stdin.readLineSync();
          if (choice?.toLowerCase() == 'n') break;
          if (choice != null && choice.toLowerCase() != 'y') {
            // Treat custom thought as next user input
            _messages
                .add({'role': 'user', 'content': 'Change of plan: $choice'});
          }
        } else {
          print('✅ Sequence completed according to the Agent.');
        }
      } catch (e) {
        print(
            '\n❌ Error: Failed to parse AI response. Ensure model output is valid JSON.');
        print('Raw output: $e');
      }
    }
  }

  Future<String> _fetchOllamaResponse() async {
    final response = await http.post(
      Uri.parse('http://localhost:11434/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'messages': _messages,
        'stream': false,
        'format': 'json',
        'think': false // Ensures Ollama forces JSON output
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['message']['content'];
    }
    throw Exception('Ollama connection failed.');
  }
}

void main() async {
  // Your OpenAPI String
  var ref;
  final String mySpec = '''
{
  "openapi": "3.1.0",
  "info": {
    "title": "Agentic Library Demo API",
    "version": "0.1.0"
  },
  "paths": {
    "/": {
      "get": {
        "summary": "Health Check",
        "operationId": "health_check__get",
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {

                }
              }
            }
          }
        }
      }
    },
    "/users": {
      "post": {
        "summary": "Create User",
        "operationId": "create_user_users_post",
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/UserCreate"
              }
            }
          },
          "required": true
        },
        "responses": {
          "201": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/UserOut"
                }
              }
            }
          },
          "422": {
            "description": "Validation Error",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/HTTPValidationError"
                }
              }
            }
          }
        }
      }
    },
    "/books": {
      "get": {
        "summary": "List Books",
        "operationId": "list_books_books_get",
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "items": {
                    "$ref": "#/components/schemas/BookOut"
                  },
                  "type": "array",
                  "title": "Response List Books Books Get"
                }
              }
            }
          }
        }
      },
      "post": {
        "summary": "Add Book",
        "operationId": "add_book_books_post",
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/BookCreate"
              }
            }
          },
          "required": true
        },
        "responses": {
          "201": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/BookOut"
                }
              }
            }
          },
          "422": {
            "description": "Validation Error",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/HTTPValidationError"
                }
              }
            }
          }
        }
      }
    },
    "/borrow": {
      "post": {
        "summary": "Borrow Book",
        "operationId": "borrow_book_borrow_post",
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/BorrowRequest"
              }
            }
          },
          "required": true
        },
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {

                }
              }
            }
          },
          "422": {
            "description": "Validation Error",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/HTTPValidationError"
                }
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "BookCreate": {
        "properties": {
          "title": {
            "type": "string",
            "title": "Title"
          },
          "author": {
            "type": "string",
            "title": "Author"
          }
        },
        "type": "object",
        "required": [
          "title",
          "author"
        ],
        "title": "BookCreate"
      },
      "BookOut": {
        "properties": {
          "title": {
            "type": "string",
            "title": "Title"
          },
          "author": {
            "type": "string",
            "title": "Author"
          },
          "id": {
            "type": "integer",
            "title": "Id"
          },
          "available": {
            "type": "boolean",
            "title": "Available"
          }
        },
        "type": "object",
        "required": [
          "title",
          "author",
          "id",
          "available"
        ],
        "title": "BookOut"
      },
      "BorrowRequest": {
        "properties": {
          "user_id": {
            "type": "integer",
            "title": "User Id"
          },
          "book_id": {
            "type": "integer",
            "title": "Book Id"
          }
        },
        "type": "object",
        "required": [
          "user_id",
          "book_id"
        ],
        "title": "BorrowRequest"
      },
      "HTTPValidationError": {
        "properties": {
          "detail": {
            "items": {
              "$ref": "#/components/schemas/ValidationError"
            },
            "type": "array",
            "title": "Detail"
          }
        },
        "type": "object",
        "title": "HTTPValidationError"
      },
      "UserCreate": {
        "properties": {
          "name": {
            "type": "string",
            "title": "Name"
          },
          "email": {
            "type": "string",
            "format": "email",
            "title": "Email"
          }
        },
        "type": "object",
        "required": [
          "name",
          "email"
        ],
        "title": "UserCreate"
      },
      "UserOut": {
        "properties": {
          "name": {
            "type": "string",
            "title": "Name"
          },
          "email": {
            "type": "string",
            "format": "email",
            "title": "Email"
          },
          "id": {
            "type": "integer",
            "title": "Id"
          }
        },
        "type": "object",
        "required": [
          "name",
          "email",
          "id"
        ],
        "title": "UserOut"
      },
      "ValidationError": {
        "properties": {
          "loc": {
            "items": {
              "anyOf": [
                {
                  "type": "string"
                },
                {
                  "type": "integer"
                }
              ]
            },
            "type": "array",
            "title": "Location"
          },
          "msg": {
            "type": "string",
            "title": "Message"
          },
          "type": {
            "type": "string",
            "title": "Error Type"
          }
        },
        "type": "object",
        "required": [
          "loc",
          "msg",
          "type"
        ],
        "title": "ValidationError"
      }
    }
  }
}
''';

  final agent = OpenApiAgent(openApiSpec: mySpec);
  await agent.start();
}
