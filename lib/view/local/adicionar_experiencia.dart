import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdicionarExperienciaPage extends StatefulWidget {
  final String localId;
  final String nomeEstabelecimento;
  final String nomeBairro;
  final String nomeZona;
  final String? experienciaId;

  const AdicionarExperienciaPage({
    super.key,
    required this.localId,
    required this.nomeEstabelecimento,
    required this.nomeBairro,
    required this.nomeZona,
    this.experienciaId, required String nomeCategoria,
  });

  @override
  _AdicionarExperienciaPageState createState() =>
      _AdicionarExperienciaPageState();
}

class _AdicionarExperienciaPageState extends State<AdicionarExperienciaPage> {
  final _comentarioController = TextEditingController();
  final _descricaoExperienciaController = TextEditingController();
  final _produtoController = TextEditingController();
  final _precoController = TextEditingController();
  int _avaliacao = 0;
  String _nomeUsuario = 'Usuário Desconhecido';

  @override
  void initState() {
    super.initState();
    _buscarNomeUsuario();
    if (widget.experienciaId != null) {
      _loadExperienciaData();
    }
  }

  Future<void> _buscarNomeUsuario() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      setState(() {
        _nomeUsuario =
            userDoc.exists ? userDoc['nome'] : (user.displayName ?? 'Usuário Desconhecido');
      });
    }
  }

  void _loadExperienciaData() async {
    try {
      final experienciaDoc = await FirebaseFirestore.instance
          .collection('experiencias')
          .doc(widget.experienciaId)
          .get();

      if (experienciaDoc.exists) {
        setState(() {
          _descricaoExperienciaController.text = experienciaDoc['comentario'];
          //_descricaoExperienciaController.text = experienciaDoc['descricao_experiencia']; // Alteração da chave
          _produtoController.text = experienciaDoc['produto'];
          _precoController.text = experienciaDoc['preco'].toString();
          _avaliacao = experienciaDoc['avaliacao'];
        });
      }
    } catch (e) {
      print('Erro ao carregar dados da experiência: $e');
    }
  }

  Future<void> _salvarExperiencia() async {
    if (_comentarioController.text.isEmpty || _precoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios')),
      );
      return;
    }

    double preco = double.tryParse(_precoController.text) ?? 0.0;
    if (preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira um preço válido')),
      );
      return;
    }

    final experienciaData = {
      'comentario': _comentarioController.text,
      'descricao_experiencia': _descricaoExperienciaController.text, // Alteração da chave
      'avaliacao': _avaliacao,
      'produto': _produtoController.text,
      'preco': preco,
      'usuario_nome': _nomeUsuario,
      'data_hora': FieldValue.serverTimestamp(),
      'estabelecimento_id': widget.localId,
    };

    try {
      if (widget.experienciaId == null) {
        await FirebaseFirestore.instance.collection('experiencias').add(experienciaData);
      } else {
        await FirebaseFirestore.instance
            .collection('experiencias')
            .doc(widget.experienciaId)
            .update(experienciaData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Experiência ${widget.experienciaId == null ? 'adicionada' : 'atualizada'} com sucesso')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar experiência: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.experienciaId == null ? 'Adicionar Experiência' : 'Editar Experiência'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _produtoController,
              decoration: const InputDecoration(labelText: 'Produto/Serviço'),
            ),
            TextField(
              controller: _precoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preço (R\$)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comentarioController,
              decoration: const InputDecoration(labelText: 'Descrição da Experiência'),
            ),
            const SizedBox(height: 16),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < _avaliacao ? Colors.yellow : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _avaliacao = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _salvarExperiencia,
              child: Text(widget.experienciaId == null ? 'Cadastrar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
