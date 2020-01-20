import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _productController = TextEditingController();
  final _amountController = TextEditingController();
  final _valueController = TextEditingController();
  List _products = [];
  double _all = 0.0;

  Map<String, dynamic> _lastDelete;
  int _lastDeletePos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _products = json.decode(data);

      });
    });
  }

  void _addProduct() {
    setState(() {
      Map<String, dynamic> newProduct = Map();
      newProduct["name"] = _productController.text;
      newProduct["amount"] = _amountController.text != "" ? _amountController.text : "0";
      newProduct["value"] = _valueController.text != "" ? _valueController.text.replaceAll(",", ".") : "0";
      newProduct["ok"] = false;
      newProduct["all"] = _all.toString();

      _clear();

      _products.add(newProduct);

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          //preferredSize: const Size.fromHeight(48.0),
          child: Text(
            "Total R\$ ${_all.toStringAsFixed(2)}",
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text("Lista de compras"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),

      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: _fieldsProduct(),
          ),
          Align(
              alignment: Alignment.centerRight,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                  child: SizedBox(
                    child: RaisedButton(
                      color: Colors.blueAccent,
                      child: Text(
                        "ADD",
                        style: TextStyle(color: Colors.white),
                      ),
                      textColor: Colors.blueAccent,

                      onPressed: _addProduct,
                    ),
                    width: double.infinity,
                  ))),
          Expanded(

            child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _products.length,
                  itemBuilder: _buildItem
                )
            ),
          )
        ],
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_products);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  void _deleteProduct(index) {
    setState(() {
      _lastDelete = Map.from(_products[index]);
      _lastDeletePos = index;
      if(_all > 0){
        _all -= double.parse(_products[index]["amount"]) *
            double.parse(_products[index]["value"]);
      }

      _products.removeAt(index);

      _saveData();
    });
  }

  Widget _fieldsProduct() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: TextField(
            controller: _productController,
            decoration: InputDecoration(
                labelText: "Produto",
                labelStyle: TextStyle(color: Colors.blueAccent)),
          ),
        ),
        Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Quant.",
                    labelStyle: TextStyle(color: Colors.blueAccent)),
              ),
            )),
        Expanded(
          flex: 1,
          child: TextField(
            controller: _valueController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: "R\$",
                labelStyle: TextStyle(color: Colors.blueAccent)),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(context, index) {
    return Dismissible(

      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.green,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.edit, color: Colors.white),
        ),
      ),

      secondaryBackground: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),

      child: CheckboxListTile(
          onChanged: (check) {
            setState(() {
              _products[index]["ok"] = check;

              if (check) {
                _all += double.parse(_products[index]["amount"]) *
                    double.parse(_products[index]["value"]);
              } else {
                _all -= double.parse(_products[index]["amount"]) *
                    double.parse(_products[index]["value"]);
              }
              _products[index]["all"] = _all.toString();
              _saveData();
            });
          },
          title: Text(_products[index]["name"]),
          subtitle: Row(
            children: <Widget>[
              Expanded(child: Text("Quant: ${_products[index]["amount"]}")),
              Align(
                  alignment: Alignment.centerRight,
                  child: Text("Unit: R\$ ${_products[index]["value"]}"))
            ],
          ),
          value: _products[index]["ok"],
          secondary: CircleAvatar(
            child: Icon(_products[index]["ok"] ? Icons.check : Icons.error),
          ),
        ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _productController.text = _products[index]["name"];
          _amountController.text = _products[index]["amount"];
          _valueController.text = _products[index]["value"];
          _products[index]["all"] = _all.toString();
        }

        _deleteProduct(index);

        final snack = SnackBar(
          content: Text("Processo feito com sucesso!"),
          action: SnackBarAction(
            label: "Desfazer",
            onPressed: () {
              if(_lastDelete["ok"]) {
                _all += double.parse(_lastDelete["amount"]) *
                    double.parse(_lastDelete["value"]);
              }

              setState(() {
                _products.insert(_lastDeletePos, _lastDelete);
                _saveData();
                _clear();
              });
            },
          ),
          duration: Duration(seconds: 3),
        );

        Scaffold.of(context).showSnackBar(snack);
      },
    );
  }

  void _clear() {
    _productController.text = "";
    _amountController.text = "";
    _valueController.text = "";
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _products.sort( (a, b) {
        if(a["ok"] && !b["ok"]) return 1;
        if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });

  }
}
