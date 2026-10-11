import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
class PartnerReferral {
  static String? code;
  static Future<void> capture(ApiClient api) async {
    final prefs=await SharedPreferences.getInstance();
    final saved=prefs.getString('pp_referral_code');
    final at=prefs.getInt('pp_referral_at')??0;
    if(DateTime.now().millisecondsSinceEpoch-at<const Duration(days:30).inMilliseconds)code=saved;
    final incoming=Uri.base.queryParameters['ref'];
    if(incoming==null||!RegExp(r'^[a-zA-Z0-9-]{8,64}$').hasMatch(incoming))return;
    try {
      final data=await api.request('GET','/partners/public/$incoming').timeout(const Duration(seconds:8));
      if(data['code']!=incoming)return;
      code=incoming;
      await prefs.setString('pp_referral_code',incoming);
      await prefs.setInt('pp_referral_at',DateTime.now().millisecondsSinceEpoch);
    } catch (_) { /* An unavailable referral never blocks shopping. */ }
  }
}
