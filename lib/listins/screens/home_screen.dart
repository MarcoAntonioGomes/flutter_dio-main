import 'package:flutter/material.dart';
import 'package:flutter_listin/_core/services/dio_service.dart';
import 'package:flutter_listin/authentication/models/mock_user.dart';
import 'package:flutter_listin/listins/data/database.dart';
import 'package:flutter_listin/listins/screens/widgets/home_drawer.dart';
import 'package:flutter_listin/listins/screens/widgets/home_listin_item.dart';
import '../models/listin.dart';
import 'widgets/listin_add_edit_modal.dart';
import 'widgets/listin_options_modal.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  final MockUser user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Listin> listListins = [];
  late AppDatabase _appDatabase;
  DioService _dioService = DioService();

  @override
  void initState() {
    _appDatabase = AppDatabase();
    refresh();
    super.initState();
  }

  @override
  void dispose() {
    _appDatabase.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HomeDrawer(user: widget.user),
      appBar: AppBar(
        title: const Text("Minhas listas"),
        actions: [
          PopupMenuButton(
              icon: Icon(Icons.cloud),
              onSelected: (value) {
                if (value == "SAVE") {
                  showConfirmDialog(
                      "Confirma a sobreescrita dos dados na nuvem ?",
                      saveOnServer);
                }
                if (value == "SYNC") {
                  showConfirmDialog(
                      "Confirma a sincronização dos dados com a nuvem ?",
                      syncWithServer);
                }
                if (value == "CLEAR") {
                  showConfirmDialog("Confirma a exclusão dos dados da nuvem ?",
                      clearServerData);
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                      value: "SAVE",
                      child: ListTile(
                        leading: Icon(Icons.upload),
                        title: Text("Salvar na nuvem"),
                      )),
                  PopupMenuItem(
                      value: "SYNC",
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text("Sincronizar da nuvem"),
                      )),
                  PopupMenuItem(
                      value: "CLEAR",
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text("Remover dados da nuvem"),
                      )),
                ];
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddModal();
        },
        child: const Icon(Icons.add),
      ),
      body: (listListins.isEmpty)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/bag.png"),
                  const SizedBox(height: 32),
                  const Text(
                    "Nenhuma lista ainda.\nVamos criar a primeira?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () {
                return refresh();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                child: StreamBuilder<bool>(
                    stream: _dioService.isLoading,
                    builder: (context, snapshot) {
                      var isLoading = snapshot.data;
                      if (isLoading == true) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 250),
                              child: CircularProgressIndicator(),
                            ),
                          ],
                        );
                      }
                      return ListView(
                        children: List.generate(
                          listListins.length,
                          (index) {
                            Listin listin = listListins[index];
                            return HomeListinItem(
                              listin: listin,
                              showOptionModal: showOptionModal,
                            );
                          },
                        ),
                      );
                    }),
              ),
            ),
    );
  }

  showAddModal({Listin? listin}) {
    showAddEditListinModal(
      context: context,
      onRefresh: refresh,
      model: listin,
      appDatabase: _appDatabase,
    );
  }

  showOptionModal(Listin listin) {
    showListinOptionsModal(
      context: context,
      listin: listin,
      onRemove: remove,
    ).then((value) {
      if (value != null && value) {
        showAddModal(listin: listin);
      }
    });
  }

  refresh() async {
    // Basta alimentar essa variável com Listins que, quando o método for
    // chamado, a tela sera reconstruída com os itens.
    List<Listin> listaListins = await _appDatabase.getListins();

    setState(() {
      listListins = listaListins;
    });
  }

  void remove(Listin model) async {
    await _appDatabase.deleteListin(int.parse(model.id));
    refresh();
  }

  saveOnServer() async {
    Get.back();
    await _dioService.saveLocalTtoServer(_appDatabase).then( (value) {

      if(value != null){
        var snackBar = SnackBar(content: Text(value));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

    });
  }

  showConfirmDialog(String mensagem, Function()? onConfirm) async {
    Get.defaultDialog(
        title: "Atenção",
        content: Text(
          mensagem,
          textAlign: TextAlign.center,
        ),
        textConfirm: "Confirmar",
        textCancel: "Cancelar",
        onConfirm: onConfirm);
  }

  syncWithServer() async {
    Get.back();
    await _dioService.getDataFromServer(_appDatabase).then( (value) {
      if(value != null){
        var snackBar = SnackBar(content: Text(value));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    refresh();
  }

  clearServerData() async {
    Get.back();
    await _dioService.clearServerData().then( (value) {
      if(value != null){
        var snackBar = SnackBar(content: Text(value));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }
}
