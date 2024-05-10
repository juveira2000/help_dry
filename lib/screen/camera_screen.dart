import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  // ignore: prefer_typing_uninitialized_variables
  var imageByte;

  // Access your API key as an environment variable (see "Set up your API key" above)
  static const String apiKey = "DIGITE A KEY";
  String texto =
      "'Descreva essa imagem de forma simples,  mas o objetivo é auxiliar na decisão se é um produto reciclavel  ou organico, caso reciclavel , recomende  formas de reutiliza-lo em casa, quando não oferecer riscos, sabe o conceito de faça você mesmo ? Seria algo assim, só que receicle você mesmo'";
  String sobre =
      "'Este aplicativo utiliza inteligência artificial para te ajudar a identificar itens recicláveis e te sugerir formas criativas de reutilizá-los. Junte-se ao movimento pela reciclagem!'";
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
        _status = 'Salvo'; // Update status message (opcional)
        _imageBase64 = imageBase64;

        // Update with base64 string
      });
    }
  }

  Widget _buildImage() {
    final image = FileImage(_imageFile!);
    return Image(
      image: ResizeImage(
        image,
        height: _imageFile == null ? 0 : 150,
        width: _imageFile == null ? 0 : 150,
      ), // Resize to 200x200
      fit: BoxFit.cover, // Maintain aspect ratio while filling the container
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.recycling),
        title: const Row(
          children: [
            Text('Recicle'),

            // Optional search icon
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    height: MediaQuery.of(context).size.height *
                        0.20, // Adjust height as needed
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    // ... rest of the popup content
                    child: Text(sobre),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Clique no Icone para abrir a camera"),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            IconButton(
              iconSize: 100,
              color: Colors.blue,
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
            ),

            SizedBox(
                height: _imageFile == null
                    ? 0
                    : MediaQuery.of(context).size.height * 0.15,
                width: _imageFile == null
                    ? 0
                    : MediaQuery.of(context).size.width * 0.40,
                child: _imageFile != null ? _buildImage() : null),
            ElevatedButton(
              //onPressed: _imageFile != null ? _sendImage : null,

              onPressed: () async {
                // For text-only input, use the gemini-pro model
                try {
                  final content = [
                    Content.data('image/jpeg', base64Decode(_imageBase64)),
                    Content.text(texto)
                  ];

                  final model = GenerativeModel(
                      model: 'gemini-1.5-pro-latest', apiKey: apiKey);

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) => Center(
                      child: CircularProgressIndicator(
                        color: Colors.green[50],
                      ),
                    ),
                  );

                  final response = await model.generateContent(content);

                  // Hide loading indicator
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);

                  // Show response in popup
                  showDialog(
                    // ignore: use_build_context_synchronously
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Descrição da Imagem'),
                      content: SingleChildScrollView(
                        child: Text(response.text.toString()),
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint("error: $e");
                  // Handle error (optional)
                } finally {
                  // Ensure loading indicator is hidden even on error
                  // ignore: use_build_context_synchronously
                  Navigator.maybePop(context);
                }
              },
              child: const Text('Perguntar ao Gemini'),
            ),
            //SizedBox(child: Text(_imageBase64)),
          ],
        ),
      ),
    );
  }
}
