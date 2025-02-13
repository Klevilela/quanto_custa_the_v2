import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapaDosLocais extends StatefulWidget {
  const MapaDosLocais({super.key});

  @override
  MapaDosLocaisPageState createState() => MapaDosLocaisPageState();
}

class MapaDosLocaisPageState extends State<MapaDosLocais> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final LatLng _teresinaLocation =
      LatLng(-5.0913, -42.8034); // Coordenadas de Teresina
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print(
          "Permissão negada permanentemente. Não será possível obter a localização.");
    }
    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _loadLocais();
  }

  Future<void> _loadLocais() async {
    try {
      // Buscando os locais no Firebase
      QuerySnapshot snapshot =
          await _firestore.collection('estabelecimentos').get();
      List<QueryDocumentSnapshot> documents = snapshot.docs;

      // Adicionando os marcadores para cada local
      for (var document in documents) {
        var data = document.data() as Map<String, dynamic>;
        double latitude = data['latitude'] ?? 0;
        double longitude = data['longitude'] ?? 0;

        // Só adiciona o marcador se a coordenada não for (0, 0)
        if (latitude != 0 && longitude != 0) {
          _markers.add(
            Marker(
              markerId: MarkerId(document.id),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: data['nome'] ?? 'Sem Nome',
                snippet: data['categoria'] ?? 'Sem Categoria',
                onTap: () {
                  _showLocalInfo(data);
                },
              ),
            ),
          );
        }
      }
      _loadLocais();

      // Atualiza o estado para que o mapa renderize os marcadores
      setState(() {});
    } catch (e) {
      print("Erro ao carregar locais: $e");
    }
  }

  void _showLocalInfo(Map<String, dynamic> local) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            local['nome'] ?? 'Sem Nome',
            style: TextStyle(fontWeight: FontWeight.bold), // Nome em negrito
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Adiciona o título 'Categoria' para a categoria
              Text(
                'Categoria: ${local['categoria'] ?? 'Sem Categoria'}',
                style: TextStyle(
                    fontWeight: FontWeight.bold), // Destaque para a categoria
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa dos Locais'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _teresinaLocation,
          zoom: 13, // Um zoom mais afastado para mostrar a cidade
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        padding: const EdgeInsets.only(
            bottom: 100), // Ajuste o padding para subir os botões
      ),
    );
  }
}
