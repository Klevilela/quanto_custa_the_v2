import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CadastrarLocal extends StatefulWidget {
  const CadastrarLocal({super.key});

  @override
  CadastrarLocalState createState() => CadastrarLocalState();
}

class CadastrarLocalState extends State<CadastrarLocal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController(); // Campo de endereço
  double? latitude;
  double? longitude;
  String? zonaSelecionada = 'Zona Leste';
  bool _useCurrentLocation = false;
  bool _isSubmitting = false; 

  List<String> zonas = ['Zona Leste', 'Zona Sudeste', 'Zona Norte', 'Zona Sul', 'Centro'];

  
  Future<void> _obterLocalizacao() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
      }
    }
  }

  Future<void> _salvarNoFirestore() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Usuário não autenticado!')),
          );
        }
        return;
      }

      if (_useCurrentLocation) {
        await _obterLocalizacao();
      }

      try {
        // Verificar se já existe um local com o mesmo nome, zona, bairro e endereço
        QuerySnapshot existing = await FirebaseFirestore.instance
            .collection('estabelecimentos')
            .where('nome', isEqualTo: _nomeController.text)
            .where('zona', isEqualTo: zonaSelecionada)
            .where('bairro', isEqualTo: _bairroController.text)
            .where('endereco', isEqualTo: _enderecoController.text.isEmpty ? 'Endereço não informado' : _enderecoController.text) // Usando o valor padrão se o campo de endereço estiver vazio
            .get();

        if (existing.docs.isNotEmpty) {
          setState(() {
            _isSubmitting = false; // Reabilita o botão após a verificação
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Este local já está cadastrado!')),
            );
          }
          return;
        }

        // Caso não haja duplicação, realiza o cadastro
        await FirebaseFirestore.instance.collection('estabelecimentos').add({
          'nome': _nomeController.text,
          'categoria': _categoriaController.text,
          'zona': zonaSelecionada,
          'bairro': _bairroController.text,
          'endereco': _enderecoController.text.isEmpty ? 'Endereço não informado' : _enderecoController.text, // Salvando o valor padrão se necessário
          'latitude': latitude ?? 0.0, // Usa 0.0 caso a localização não tenha sido passada
          'longitude': longitude ?? 0.0,
          'usuario_id': user.uid,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!')),
          );

          // Limpar os campos e reabilitar o botão
          _nomeController.clear();
          _categoriaController.clear();
          _bairroController.clear();
          _enderecoController.clear(); // Limpar o campo de endereço
          setState(() {
            _isSubmitting = false;
          });

          // Voltar à tela anterior
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false; // Reabilita o botão após erro
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cadastrar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Local')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Local'),
                validator: (value) => value!.isEmpty ? 'Digite o nome' : null,
              ),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (value) => value!.isEmpty ? 'Digite a categoria' : null,
              ),
              DropdownButtonFormField<String>(
                value: zonaSelecionada,
                decoration: const InputDecoration(labelText: 'Zona'),
                items: zonas.map((zona) {
                  return DropdownMenuItem<String>(
                    value: zona,
                    child: Text(zona),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    zonaSelecionada = value;
                  });
                },
                validator: (value) => value == null ? 'Selecione a zona' : null,
              ),
              TextFormField(
                controller: _bairroController,
                decoration: const InputDecoration(labelText: 'Bairro'),
                validator: (value) => value!.isEmpty ? 'Digite o bairro' : null,
              ),
              TextFormField( // Novo campo de endereço
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço'),
                validator: (value) => value!.isEmpty ? 'Digite o endereço' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _useCurrentLocation,
                    onChanged: (bool? value) {
                      setState(() {
                        _useCurrentLocation = value!;
                      });
                    },
                  ),
                  const Text('Usar minha localização atual'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _salvarNoFirestore, // Desabilita o botão enquanto o cadastro é feito
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Cadastrar Local'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
