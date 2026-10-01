import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
class ApiException implements Exception{ApiException(this.message,{this.statusCode});final String message;final int? statusCode;@override String toString()=>message;}
class ApiClient{
 ApiClient({http.Client? client}):_client=client??http.Client();final http.Client _client;String? token;
 static String get baseUrl{const configured=String.fromEnvironment('API_URL',defaultValue:'');if(configured.isNotEmpty)return configured.replaceAll(RegExp(r'/$'),'');if(kIsWeb)return 'http://127.0.0.1:3000/api';return 'http://10.0.2.2:3000/api';}
 Future<dynamic> get(String path,{bool authenticated=false})=>_send('GET',path,authenticated:authenticated);
 Future<dynamic> post(String path,{Object? body,bool authenticated=false})=>_send('POST',path,body:body,authenticated:authenticated);
 Future<dynamic> patch(String path,{Object? body,bool authenticated=false})=>_send('PATCH',path,body:body,authenticated:authenticated);
 Future<dynamic> _send(String method,String path,{Object? body,bool authenticated=false})async{
  final uri=Uri.parse('$baseUrl$path');final headers=<String,String>{'Accept':'application/json'};if(body!=null)headers['Content-Type']='application/json';if(authenticated&&token!=null)headers['Authorization']='Bearer $token';
  late http.Response response;try{if(method=='POST'){response=await _client.post(uri,headers:headers,body:body==null?null:jsonEncode(body));}else if(method=='PATCH'){response=await _client.patch(uri,headers:headers,body:body==null?null:jsonEncode(body));}else{response=await _client.get(uri,headers:headers);}}catch(_){throw ApiException('Não foi possível conectar à Porto Prime.');}
  dynamic decoded;if(response.body.isNotEmpty){try{decoded=jsonDecode(response.body);}catch(_){decoded=response.body;}}
  if(response.statusCode<200||response.statusCode>=300){var message='Não foi possível concluir a operação.';if(decoded is Map&&decoded['message']!=null){final v=decoded['message'];message=v is List?v.join('\n'):v.toString();}throw ApiException(message,statusCode:response.statusCode);}return decoded;
 }
}
