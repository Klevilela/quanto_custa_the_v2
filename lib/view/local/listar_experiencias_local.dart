import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';  // Para formatação da data
import 'package:quanto_custa_the_v2/view/local/adicionar_experiencia.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Importando o Google Maps

class ListarExperienciasPage extends StatefulWidget {
  final String localId;
  final String nomeEstabelecimento;
  final String nomeBairro;
  final String nomeZona;
  final String nomeCategoria; // Agora incluímos o nome da categoria
  final double? latitude; // Latitude do estabelecimento
  final double? longitude; // Longitude do estabelecimento
  final String? endereco; // Adicionado campo de endereço

  const ListarExperienciasPage({
    super.key,
    required this.localId,
    required this.nomeEstabelecimento,
    required this.nomeBairro,
    required this.nomeZona,
    required this.nomeCategoria, // Recebendo nomeCategoria
    this.latitude,
    this.longitude,
    this.endereco, // Recebendo o endereço
  });

  @override
  ListarExperienciasPageState createState() => ListarExperienciasPageState();
}

class ListarExperienciasPageState extends State<ListarExperienciasPage> {
  // Controlador do Google Maps
  late GoogleMapController mapController;

  final Set<Marker> _markers = {}; // Conjunto de marcadores para o mapa

  @override
  void initState() {
    super.initState();

    // Se houver latitude e longitude, adiciona um marcador no mapa
    if (widget.latitude != null && widget.longitude != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('local_marker'),
          position: LatLng(widget.latitude!, widget.longitude!),
          infoWindow: InfoWindow(title: widget.nomeEstabelecimento),
        ),
      );
    }
  }

  // Função para atualizar a lista de experiências após o cadastro
  void _atualizarExperiencias() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiências'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do Estabelecimento
            Text(
              widget.nomeEstabelecimento,
              style: const TextStyle(
                fontSize: 24, // Aumenta o tamanho da fonte do nome do estabelecimento
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Categoria: ${widget.nomeCategoria}', // Agora exibe corretamente a categoria
              style: const TextStyle(
                fontSize: 18, // Tamanho maior para a categoria
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bairro: ${widget.nomeBairro} | Zona: ${widget.nomeZona}',
              style: const TextStyle(
                fontSize: 16, // Fonte menor para bairro e zona
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            // Exibindo o endereço do estabelecimento
            Text(
              'Endereço: ${widget.endereco ?? 'Endereço não informado'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),

            // Exibindo o mapa se houver localização
            if (widget.latitude != null && widget.longitude != null)
              SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.latitude!, widget.longitude!),
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                ),
              ),

            // Exibindo as experiências cadastradas
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('experiencias')
                    .where('estabelecimento_id', isEqualTo: widget.localId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }

                  final experiencias = snapshot.data!.docs;

                  if (experiencias.isEmpty) {
                    return const Center(child: Text('Nenhuma experiência registrada.'));
                  }

                  return ListView.builder(
                    itemCount: experiencias.length,
                    itemBuilder: (context, index) {
                      var doc = experiencias[index];

                      // Formatando a data
                      String formattedDate = '';
                      if (doc['data_hora'] != null) {
                        DateTime dateTime = doc['data_hora'].toDate();
                        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(doc['comentario'] ?? 'Sem comentário'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exibindo o produto
                              Text('Produto: ${doc['produto'] ?? 'Produto desconhecido'}'),
                              // Exibindo o preço com verificação de nulo
                              Text(
                                'Preço: R\$ ${doc['preco'] != null ? doc['preco'].toStringAsFixed(2) : '0.00'}',
                              ),
                              // Exibindo a avaliação por estrelas
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    Icons.star,
                                    color: index < (doc['avaliacao'] ?? 0)
                                        ? Colors.yellow
                                        : Colors.grey,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),

                              // Informações sobre o usuário e data
                              Text('Por: ${doc['usuario_nome'] ?? 'Usuário desconhecido'}'),
                              Text('Data: $formattedDate'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // Navegar para a página de edição de experiência
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdicionarExperienciaPage(
                                    localId: widget.localId,
                                    nomeEstabelecimento: widget.nomeEstabelecimento,
                                    nomeBairro: widget.nomeBairro,
                                    nomeZona: widget.nomeZona,
                                    nomeCategoria: widget.nomeCategoria, // Passando nomeCategoria para edição
                                    experienciaId: doc.id, // Passando o ID para edição
                                  ),
                                ),
                              ).then((_) {
                                _atualizarExperiencias(); // Atualiza as experiências após editar
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 60.0),
              child: Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdicionarExperienciaPage(
                          localId: widget.localId,
                          nomeEstabelecimento: widget.nomeEstabelecimento,
                          nomeBairro: widget.nomeBairro,
                          nomeZona: widget.nomeZona,
                          nomeCategoria: widget.nomeCategoria, // Passando o nomeCategoria
                        ),
                      ),
                    ).then((_) {
                      _atualizarExperiencias(); // Atualiza as experiências após adicionar
                    });
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  child: const Text('Cadastrar Nova Experiência'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
