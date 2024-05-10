import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _imageFile;
  String _imageBase64 = '';
  String _status = 'Nenhuma foto selecionada';
  String imageDescription = "";
  var imageByte;

  // Access your API key as an environment variable (see "Set up your API key" above)
  static const String apiKey = "AIzaSyBMgHx_NQTgdq0LaGPLm5yPtB-gL5IXjj8";

  //  exit(1);

  static String baseUrl =
      "https://us-central1-aiplatform.googleapis.com/v1/projects/";
  static String projectId = "alura-422819";
  static String modelId = "gemini-1.0-pro";

  //final apiKey = "AIzaSyBOOlA9Y578O8Zv6YWRPsKyfS-zS9eU7ew";

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final imageBase64 = base64Encode(bytes); // Já converte para base64 aqui
      imageByte = imageBase64;

      final appDirectory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now()}.jpg'; // Unique filename
      final newImagePath = '${appDirectory.path}/$fileName';
      imageDescription = newImagePath;
      // Save the image to the app's directory (optional)
      await File(newImagePath).writeAsBytes(bytes); // Salva a imagem (opcional)

      setState(() {
        _imageFile =
            File(newImagePath); // Update with saved image path (opcional)
        _status = 'Foto salva'; // Update status message (opcional)
        _imageBase64 = imageBase64;

        // Update with base64 string
      });
    }
  }

  Future<String> sendPromptWithImage(
      String textPrompt, String targetAudience) async {
    // Prepare the image data

    // Build the request body
    final body = {
      "inputs": [
        {"prompt": textPrompt, "image_content": _imageBase64}
      ],
      "parameters": {
        "temperature": 0.9,
        "topK": 0,
        "topP": 1.0,
        "max_tokens": 2048,
        "safety_settings": [
          {
            "harm_category": "HARASSMENT",
            "block_threshold": "MEDIUM_AND_ABOVE"
          },
          {
            "harm_category": "HATE_SPEECH",
            "block_threshold": "MEDIUM_AND_ABOVE"
          },
          {
            "harm_category": "SEXUALLY_EXPLICIT",
            "block_threshold": "MEDIUM_AND_ABOVE"
          },
          {
            "harm_category": "DANGEROUS_CONTENT",
            "block_threshold": "MEDIUM_AND_ABOVE"
          },
        ],
      },
    };

    // Build the request URL
    final url = Uri.parse("$baseUrl$projectId/$modelId:generateContent");

    // Send the POST request
    final response = await http.post(
      url,
      body: jsonEncode(body),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
    );

    // Check for errors
    if (response.statusCode != 200) {
      throw Exception("Error sending request: ${response.statusCode}");
    }

    // Parse the response
    final data = jsonDecode(response.body);
    return data["text"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Câmera e Envio de Foto'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 100,
              color: Colors.blue,
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
            ),
            Text(_status),
            const SizedBox(height: 20),

            SizedBox(
                height: 200,
                width: 200,
                child: _imageFile != null
                    ? Image.file(File(_imageFile!.path))
                    : null),
            ElevatedButton(
              //onPressed: _imageFile != null ? _sendImage : null,

              onPressed: () async {
                // For text-only input, use the gemini-pro model
                try {
                  final content = [
                    Content.data('image/jpeg', base64Decode(_imageBase64)),
                    Content.text(
                        'Descreva essa imagem de forma simples,  mas o objetivo é auxiliar na decisão se é um produto reciclavel  ou organico, caso reciclavel , recomende  formas de reutiliza-lo em casa, quando não oferecer riscos, sabe o conceito de faça você mesmo ? Seria algo assim, só que receicle você mesmo')
                  ];

                  final model = GenerativeModel(
                      model: 'gemini-1.5-pro-latest', apiKey: apiKey);

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) => Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  final response = await model.generateContent(content);

                  // Hide loading indicator
                  Navigator.pop(context);

                  // Show response in popup
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Descrição da Imagem'),
                      content: SingleChildScrollView(
                        child: Text(response.text.toString()),
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint("error: ${e}");
                  // Handle error (optional)
                } finally {
                  // Ensure loading indicator is hidden even on error
                  Navigator.maybePop(context);
                }
              },
              child: const Text('Enviar Foto'),
            ),
            //SizedBox(child: Text(_imageBase64)),
          ],
        ),
      ),
    );
  }
}
