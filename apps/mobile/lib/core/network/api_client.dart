import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiClient {
 ApiClient._(); static final instance=ApiClient._(); String? token;
 String get baseUrl { const c=String.fromEnvironment('API_URL'); if(c.isNotEmpty)return c; final u=Uri.base; var h=u.host.replaceFirst(RegExp(r'-808[0-9](?=\.)'),'-3000'); return Uri(scheme:u.scheme=='http'?'http':'https',host:h,port:h==u.host&&(h=='localhost'||h=='127.0.0.1')?3000:null,path:'/api').toString().replaceAll(RegExp(r'/$'),''); }
 Map<String,String> get headers=>{'Content-Type':'application/json',if(token!=null)'Authorization':'Bearer '+token!};
 Future<dynamic> request(String method,String path,{Object? body}) async {final uri=Uri.parse(baseUrl+path);late http.Response res;if(method=='GET')res=await http.get(uri,headers:headers);else if(method=='POST')res=await http.post(uri,headers:headers,body:body==null?null:jsonEncode(body));else if(method=='PATCH')res=await http.patch(uri,headers:headers,body:body==null?null:jsonEncode(body));else throw Exception('Método inválido');dynamic data;try{data=res.body.isEmpty?null:jsonDecode(res.body);}catch(_){data=res.body;}if(res.statusCode<200||res.statusCode>=300){final msg=data is Map?(data['message'] is List?(data['message'] as List).join(', '):data['message']):null;throw Exception(msg??'Erro '+res.statusCode.toString());}return data;}
}