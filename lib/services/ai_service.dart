import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static Future<Map<String, dynamic>> verifyReceipt({
    required String base64Image,
    required double expectedAmount,
    required String expectedName,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      return {
        'isAiVerified': false,
        'reason': 'AI Verification is offline (Missing API Key).',
        'transactionId': '',
        'transactionDate': '',
      };
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
You are a highly strict Bank Fraud Investigator.
Your task is to analyze the provided payment receipt image and verify its authenticity.

Expected Amount: RM $expectedAmount
Expected Recipient Name: $expectedName

Please perform the following strict checks:
1. Extract the Amount Paid. Does it exactly match RM $expectedAmount?
2. Extract the Recipient Name. Does it closely match "$expectedName" (ignoring case and minor abbreviations)?
3. Extract the exact Transaction Date and Time (format as YYYY-MM-DD HH:MM).
4. Extract the unique Transaction ID or Reference Number.
5. Analyze the image for any signs of forgery, digital alteration, Photoshop artifacts, inconsistent fonts, or lack of standard bank watermarks.

Respond strictly in the following JSON format:
{
  "isAiVerified": boolean,
  "reason": "String explaining why it was approved or rejected (keep it brief, e.g., 'Perfect match', 'Amount is short', 'Photoshop artifact detected')",
  "transactionId": "String (the extracted reference number)",
  "transactionDate": "String (YYYY-MM-DD HH:MM)"
}

If any check fails (wrong amount, wrong name, or suspected forgery), set isAiVerified to false.
''';

      // We handle both jpeg, png, and pdfs converted to jpeg
      final imageParts = [
        DataPart('image/jpeg', base64Decode(base64Image))
      ];

      final content = [Content.multi([TextPart(prompt), ...imageParts])];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final Map<String, dynamic> result = jsonDecode(response.text!);
        return {
          'isAiVerified': result['isAiVerified'] ?? false,
          'reason': result['reason'] ?? 'Unknown AI response',
          'transactionId': result['transactionId'] ?? '',
          'transactionDate': result['transactionDate'] ?? '',
        };
      }
      return {
        'isAiVerified': false,
        'reason': 'No response from AI.',
        'transactionId': '',
        'transactionDate': '',
      };
    } catch (e) {
      return {
        'isAiVerified': false,
        'reason': 'AI processing error: \$e',
        'transactionId': '',
        'transactionDate': '',
      };
    }
  }
}
