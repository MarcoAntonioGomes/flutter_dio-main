import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_listin/_core/data/local_data_handler.dart';
import 'package:flutter_listin/_core/interceptors/dio_interceptor.dart';
import 'package:flutter_listin/_core/services/dio_endpoints.dart';
import 'package:flutter_listin/listins/data/database.dart';

class DioService {
  final Dio _dio = Dio(BaseOptions(
      baseUrl: DioEndpoints.devBaseUrl,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5)));
  final StreamController _streamController = StreamController<bool>();

  DioService() {
    _dio.interceptors.add(DioInterceptor());
  }

  get isLoading => _streamController.stream;

  Future<String?> saveLocalTtoServer(AppDatabase appDataBase) async {
    _streamController.add(true);

    Map<String, dynamic> localData =
        await LocalDataHandler().localDataToMap(appdatabase: appDataBase);

    try {
      Response response = await _dio.put(DioEndpoints.listins,
          data: json.encode(localData["listins"]));

      _streamController.add(false);

      if (response.statusCode == 200) {
        return Future.value("Dados salvos no servidor");
      }
    } on DioException catch (e) {
      _streamController.add(false);

      return showTreatedError(e);
    } on Exception {
      _streamController.add(false);
      return Future.value("Não foi possivel salvar os dados no servidor");
    }
  }

  String? showTreatedError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      return e.response!.data!.toString();
    } else {
      return e.message;
    }
  }

  Future<String?> getDataFromServer(AppDatabase appDataBase) async {
    _streamController.add(true);

    try {
      Response response = await _dio.get(DioEndpoints.listins,
          queryParameters: {"orderBy": '"name"', "startAt": 0});

      if (response.data != null) {
        Map<String, dynamic> map = {};

        if (response.data.runtimeType == List) {
          if ((response.data as List<dynamic>).isNotEmpty) {
            map["listins"] = response.data;
          }
        } else {
          List<Map<String, dynamic>> tempList = [];

          for (var mapResponse in (response.data as Map).values) {
            tempList.add(mapResponse);
          }
          map["listins"] = tempList;
          print(tempList);
        }

        await LocalDataHandler()
            .mapToLocalData(map: map, appdatabase: appDataBase);
        _streamController.add(false);
        return Future.value("Dados sincronizados com o servidor");
      }
    }on DioException catch (e) {
      _streamController.add(false);
      return showTreatedError(e);
    } on Exception {
      _streamController.add(false);
      return Future.value("Não foi possivel sincronizar os dados com o servidor");
    }

  }




  Future<String?> clearServerData() async {
    _streamController.add(true);

    try {
      Response response = await _dio.delete(DioEndpoints.listins);
      _streamController.add(false);
      if (response.statusCode == 200) {
        return Future.value("Dados removidos do servidor");
      }
    } on DioException catch (e) {
      _streamController.add(false);
      showTreatedError(e);
    } on Exception catch (e) {
      _streamController.add(false);
      return Future.value("Não foi possivel remover os dados do servidor");
    }
  }
}
