import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_listin/_core/services/dio_endpoints.dart';
import 'package:logger/logger.dart';

class DioInterceptor extends Interceptor{

  Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0, printEmojis: false));

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {

    super.onResponse(response, handler);
  }


  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {

    String log = "";
    log += "REQUISIÇÃO\n";
    log +=  "Timestamp: ${DateTime.now()}\n";
    log += "Método: ${options.method}";
    log +=  "URL: ${options.uri}\n";
    log += "Cabeçalho: ${JsonEncoder.withIndent(" ").convert(options.headers)}\n";
    if(options.data != null){
      log += "Corpo: ${const JsonEncoder.withIndent(" ").convert(json.decode(options.data))}\n";
    }
   _logger.w(log);
    Dio().post("${DioEndpoints.devBaseUrl}${DioEndpoints.logs}", data: {
      "request": log,
    });
    super.onRequest(options, handler);
  }


  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {

    super.onError(err, handler);
  }

}