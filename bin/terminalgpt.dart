import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';

class ChatMessage {
  final String text;
  final String speaker;

  ChatMessage(this.text, this.speaker);
}

final logger = Logger();

late Directory appDir;
void main(List<String> arguments) async {
  logger.write('\nWelcome to tGPT!\n');

  var parser = ArgParser();
  appDir = await Directory(applicationConfigHome("terminal_gpt_dart_cli"))
      .create(recursive: true);

  parser.addOption('input', abbr: 'i');
  parser.addFlag('model', abbr: "m", negatable: false);
  parser.addFlag('updateKey', abbr: "u", negatable: false);
  parser.addFlag('help', abbr: "h", negatable: false);
  parser.addFlag('clear', abbr: "c", negatable: false);

  var args = parser.parse(arguments);

  String? apiKey = await readApiKeyFromStorage();

  if (apiKey == null) {
    apiKey = await promptForApiKey();
    await writeApiKeyToStorage(apiKey);
  }
  if (args['model']) {
    await updateSelectedModel(apiKey);
  }
  if (args["help"]) {
    logger.info("Options:\n");
    print("  -i, --input <input>  Input to the model");
    print("  -h, --help           Show this help");
    print("  -m --model       Change the model");
    print("  -c --clear       Clear the chat history");
    print("  -u --updateKey   Update the API key");
    exit(0);
  }
  if (args["clear"]) {
    final progress = logger.progress("Cleaning chat history...");
    final chatjson = File(path.join(appDir.path, 'chat.json'));
    try {
      chatjson.deleteSync();
    } catch (e) {
      logger.err('Error occured: $e');
    }
    progress.complete("Chat history cleaned.");
  }
  if (args["updateKey"]) {
    apiKey = await promptForApiKey();
    await writeApiKeyToStorage(apiKey);
  }
  String? modelId = await readModelIdFromStorage();

  try {
    modelId ??= await updateSelectedModel(apiKey);
  } catch (e) {
    logger.err('Error occured: $e');
    exit(1);
  }
  logger.info(backgroundBlue.wrap('Using model: $modelId'));

  var input = args['input'] ?? await promptUserInput(false);

  while (true) {
    await runRequest(input, apiKey, modelId);
    input = await promptUserInput(true);
  }
}

Future<String> updateSelectedModel(String apiKey) async {
  final availableModels = await listModels(apiKey);
  final modelId = logger.chooseOne('Select a model:',
      choices: availableModels.map((m) => m.id).toList());
  await writeModelIdToStorage(modelId);
  return modelId;
}

Future<List<ChatModel>> listModels(String apiKey) async {
  final progress = logger.progress("Getting chat models...");

  var response = await http.get(
    Uri.parse('https://api.openai.com/v1/models?model_type=chat'),
    headers: {'Authorization': 'Bearer $apiKey'},
  );
  progress.complete("Done");
  var jsonResponse = json.decode(response.body);

  final errorMessage = jsonResponse['error'];

  if (errorMessage != null) {
    throw Exception(errorMessage);
  }
  final data = jsonResponse['data'];

  return parseModels(
    List.castFrom<dynamic, Map<String, dynamic>>(data),
  );
}

class ChatModel {
  String id;
  String ownedBy;

  ChatModel({required this.id, required this.ownedBy});
}

List<ChatModel> parseModels(List<Map<String, dynamic>> data) {
  List<ChatModel> models = [];

  for (var model in data) {
    if ((model["id"] as String).contains("gpt")) {
      models.add(ChatModel(id: model['id'], ownedBy: model['owned_by']));
    }
  }

  return models;
}

Future<void> runRequest(String input, String apiKey, String modelId) async {
  // while (true) {

  try {
    final response = await callOpenAiApi(input, apiKey, modelId);

    final codes = extractTextCodePairs(response);

    await promptForCodeEdit(codes);
  } catch (e) {
    logger.err('Error occured: $e');
  }
}

Future<String?> readApiKeyFromStorage() async {
  try {
    var apiKeyFile = File(path.join(appDir.path, 'api_key.txt'));
    if (await apiKeyFile.exists()) {
      return await apiKeyFile.readAsString();
    }
  } catch (_) {}
  return null;
}

Future<String?> readModelIdFromStorage() async {
  try {
    var apiKeyFile = File(path.join(appDir.path, 'terminal_gpt_model_id.txt'));
    if (await apiKeyFile.exists()) {
      return await apiKeyFile.readAsString();
    }
  } catch (_) {}
  return null;
}

Future<void> writeApiKeyToStorage(String apiKey) async {
  try {
    var apiKeyFile = File(path.join(appDir.path, 'api_key.txt'));
    await apiKeyFile.writeAsString(apiKey);
  } catch (_) {}
}

Future<void> writeModelIdToStorage(String modelId) async {
  try {
    var apiKeyFile = File(path.join(appDir.path, 'terminal_gpt_model_id.txt'));
    await apiKeyFile.writeAsString(modelId);
  } catch (_) {}
}

Future<String> promptForApiKey() async {
  stdout.write('Please enter your OpenAI api key: ');
  return stdin.readLineSync()!;
}

Future<String> promptUserInput(bool askAQ) async {
  stdout.writeln(
      "\n${backgroundGreen.wrap(askAQ ? "Ask anything else?" : 'What would you like to ask tGPT?')!}\n");

  return stdin.readLineSync()!;
}

Future<String> callOpenAiApi(
    String input, String apiKey, String modelId) async {
  final userMessage = ChatMessage(
    input.trim(),
    "user",
  );
  stdout.writeln("\n${backgroundBlue.wrap("Input")!}:$input");
  final chatHistory = await retrieveChatHistory();
  stdout.writeln("Chat History: ${chatHistory.length}");
  chatHistory.add({
    "role": userMessage.speaker,
    "content": userMessage.text,
  });

  final progress = logger.progress('Waiting for responce...');
  final responce = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        "messages": chatHistory,
        "model": modelId, //"gpt-3.5-turbo",
        //'max_tokens': 1024,
        'temperature': 0.5,
        // 'n': 1,
        // 'stop': '\n',
      }));

  progress.complete();

  var responseJson = jsonDecode(responce.body);

  final error = responseJson['error'];
  if (error != null) {
    throw Exception(error);
  }

  final recievedAssistanMessage = ChatMessage(
    (responseJson['choices'][0]['message']["content"] as String),
    (responseJson['choices'][0]["message"]['role'] as String),
  );
  await saveMessage(userMessage);
  await saveMessage(recievedAssistanMessage);

  return recievedAssistanMessage.text;
}

Future<List<Map<String, dynamic>>> retrieveChatHistory() async {
  final chatjson = File(path.join(appDir.path, 'chat.json'));

  if (await chatjson.exists()) {
    final jsonContent = await chatjson.readAsString();
    final jsonMap = jsonDecode(jsonContent) as Map<String, dynamic>?;
    final messages = jsonMap?['messages'] == null
        ? []
        : jsonMap!['messages'] as List<dynamic>;

    return messages.map((e) => e as Map<String, dynamic>).toList();
  } else {
    return [];
  }
}

Future<ChatMessage> saveMessage(ChatMessage message) async {
  final chatjson = File(path.join(appDir.path, 'chat.json'));
  if (await chatjson.exists()) {
    final jsonContent = await chatjson.readAsString();
    final jsonMap = jsonDecode(jsonContent) as Map<String, dynamic>;
    final messages = jsonMap['messages'] as List<dynamic>;
    messages.add({
      'role': message.speaker,
      'content': message.text,
    });
    jsonMap['messages'] = messages;
    await chatjson.writeAsString(
      jsonEncode(jsonMap),
    );
  } else {
    await chatjson.writeAsString(jsonEncode({
      'messages': [
        {
          'role': message.speaker,
          'content': message.text,
        }
      ]
    }));
  }
  return message;
}

List<TextCodeModel> extractTextCodePairs(String input) {
  final List<TextCodeModel> pairs = [];

  final regex = RegExp(r'^\s*(.*?)\s*(```(?:[\S\s]+?)```)', multiLine: true);
  final matches = regex.allMatches(input);

  for (final match in matches) {
    final text = match.group(1)?.trim() ?? '';
    final code = match.group(2)?.trim() ?? '';

    if (text.isNotEmpty || code.isNotEmpty) {
      pairs.add(TextCodeModel(text: text, code: code));
    }
  }

  if (pairs.isEmpty) {
    pairs.add(TextCodeModel(text: input, code: null));
  }

  return pairs;
}

Future<void> promptForCodeEdit(List<TextCodeModel> codes) async {
  logger.success("\n------------------------\n");

  for (final model in codes) {
    logger.write(backgroundLightMagenta.wrap("Assistant"));
    stdout.writeln("\n");
    logger.write("${backgroundBlack.wrap(model.text)}\n");
    logger.success(model.code ?? "");
    print('');
  }
}

Future<bool> promptToRunCode() async {
  stdout.write('Do you want to run the code? (y/n) ');
  var answer = stdin.readLineSync()?.toLowerCase() ?? '';
  return answer == 'y' || answer == 'yes';
}

Future<void> executeCode(String code) async {
  try {
    // Split the command string into parts
    var parts = code.split(' ');

    // Extract the executable and argument list
    var executable = parts.first;
    var arguments = parts.sublist(1);
    await runExecutableArguments(
      executable,
      arguments,
      runInShell: true,
      stdout: stdout,
      stdin: stdin,
      stderr: stderr,
    );
  } catch (e) {
    print('Error running the code: $e');
  }
}

String extractCode(String input) {
  // Ask the user for input text

  // Split the input text into lines
  var lines = input.split('\n');

  // Loop through each line and check if it looks like code
  var codeLines = <String>[];
  for (var line in lines) {
    // Check if the line starts with an asterisk
    if (line.trim().startsWith('*')) {
      // Remove the asterisk and add the line to the code lines
      codeLines.add(line.substring(1));
    }
  }

  return codeLines.join('\n');
}

class TextCodeModel {
  final String? text;
  final String? code;

  TextCodeModel({this.text, this.code});
}
