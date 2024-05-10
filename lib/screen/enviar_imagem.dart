  
  /*
  
  DESABILITADA
  
  Future<void> _sendImage() async {
    if (_imageFile != null) {
      final uri = Uri.parse(
          'https://postimages.org/'); // Replace with your server endpoint
      var request = http.MultipartRequest('POST', uri);

      // Use http.MultipartFile.fromPath for compatibility
      final multipartFile = await http.MultipartFile.fromPath(
          'image', _imageFile!.path,
          filename: 'foto.jpg');

      request.files.add(multipartFile);

      final response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          _status = 'Foto enviada com sucesso';
        });
      } else {
        setState(() {
          _status = 'Erro ao enviar foto (Status code: ${response.statusCode})';
        });
      }
    }
  }
  */