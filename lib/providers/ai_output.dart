import 'package:flutter/foundation.dart';
import 'package:apidash/models/models.dart';
import 'package:apidash_core/apidash_core.dart';

class AiOutputDebug {
  static String? getPrintableAiText(RequestModel? request) {
    if (request == null) return null;
    if (request.apiType != APIType.ai) return null;

    final res = request.httpResponseModel;
    if (res == null) return null;

    final isSse = (res.sseOutput?.isNotEmpty ?? false);
    if (isSse) return res.sseOutput!.join('\n');

    return res.formattedBody ?? res.body;
  }

  static void printAiOutput(RequestModel? request, {String tag = 'AI_OUTPUT'}) {
    final text = getPrintableAiText(request);

    if (text == null || text.isEmpty) {
      debugPrint('[$tag] <empty>');
      return;
    }

    debugPrint('[$tag] ---------- START ----------');
    debugPrint(text); // debugPrint handles long strings better than print()
    debugPrint('[$tag] ---------- END ------------');
  }
}
