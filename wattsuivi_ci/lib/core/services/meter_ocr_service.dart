import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrResult {
  const OcrResult({required this.valueKwh, required this.rawText, required this.imagePath});
  final double valueKwh;
  final String rawText;
  final String imagePath;
}

class MeterOcrService {
  MeterOcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<OcrResult?> scanFromCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2200,
    );
    if (photo == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(photo.path);
      final result = await recognizer.processImage(input);
      final value = _extractLikelyKwh(result.text);
      if (value == null) {
        throw const FormatException(
          'Aucune valeur kWh fiable détectée. Prenez une photo plus nette ou saisissez la valeur manuellement.',
        );
      }
      return OcrResult(valueKwh: value, rawText: result.text, imagePath: photo.path);
    } finally {
      await recognizer.close();
    }
  }

  double? _extractLikelyKwh(String text) {
    final normalized = text.replaceAll(',', '.');
    final withUnit = RegExp(
      r'(\d{1,6}(?:\.\d{1,3})?)\s*(?:k\s*w\s*h|kwh)',
      caseSensitive: false,
    ).allMatches(normalized).toList();
    if (withUnit.isNotEmpty) {
      return double.tryParse(withUnit.last.group(1)!);
    }

    final candidates = RegExp(r'\b(\d{1,5}(?:\.\d{1,3})?)\b')
        .allMatches(normalized)
        .map((m) => double.tryParse(m.group(1)!))
        .whereType<double>()
        .where((v) => v >= 0 && v <= 99999)
        .toList();
    if (candidates.isEmpty) return null;

    final decimals = candidates.where((value) => value != value.roundToDouble()).toList();
    return decimals.isNotEmpty ? decimals.last : candidates.last;
  }
}
