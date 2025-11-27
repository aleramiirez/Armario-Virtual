// lib/features/outfits/screen/create_outfit_screen.dart

import 'package:armariovirtual/features/outfits/services/outfit_service.dart';
import 'package:armariovirtual/features/outfits/widgets/garment_placeholder.dart';
import 'package:armariovirtual/features/outfits/widgets/garment_selector_sheet.dart';
import 'package:armariovirtual/shared/utils/app_alerts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateOutfitScreen extends StatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  State<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends State<CreateOutfitScreen> {
  DocumentSnapshot? _selectedTop;
  DocumentSnapshot? _selectedBottom;
  DocumentSnapshot? _selectedShoes;

  // --- NUEVAS VARIABLES ---
  final OutfitService _outfitService = OutfitService();
  bool _isLoading = false;

  // Variables para controlar el ajuste de imagen (contain vs cover)
  BoxFit _topFit = BoxFit.contain;
  BoxFit _bottomFit = BoxFit.contain;
  BoxFit _shoesFit = BoxFit.contain;

  Future<void> _selectGarment(
    String category,
    Function(DocumentSnapshot) onGarmentSelected,
  ) async {
    final selectedGarment = await showModalBottomSheet<DocumentSnapshot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GarmentSelectorSheet(category: category),
    );

    if (selectedGarment != null) {
      setState(() {
        onGarmentSelected(selectedGarment);
      });
    }
  }

  void _toggleFit(String section) {
    setState(() {
      if (section == 'top') {
        _topFit = _topFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
      } else if (section == 'bottom') {
        _bottomFit = _bottomFit == BoxFit.contain
            ? BoxFit.cover
            : BoxFit.contain;
      } else if (section == 'shoes') {
        _shoesFit = _shoesFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
      }
    });
  }

  // --- NUEVA FUNCIÓN PARA GUARDAR ---
  Future<void> _saveOutfit() async {
    // 1. Validamos que se hayan seleccionado las 3 prendas
    if (_selectedTop == null ||
        _selectedBottom == null ||
        _selectedShoes == null) {
      AppAlerts.showFloatingSnackBar(
        context,
        'Debes seleccionar las tres prendas para guardar el outfit.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final topData = _selectedTop!.data() as Map<String, dynamic>;
      topData['id'] = _selectedTop!.id;

      final bottomData = _selectedBottom!.data() as Map<String, dynamic>;
      bottomData['id'] = _selectedBottom!.id;

      final shoesData = _selectedShoes!.data() as Map<String, dynamic>;
      shoesData['id'] = _selectedShoes!.id;

      // 2. Llamamos al servicio para guardar los IDs de las prendas
      await _outfitService.saveOutfit(
        topData: topData,
        bottomData: bottomData,
        shoesData: shoesData,
      );

      // 3. Mostramos mensaje de éxito y volvemos a la pantalla anterior
      if (mounted) {
        Navigator.of(context).pop();
        AppAlerts.showFloatingSnackBar(context, 'Outfit guardado con éxito');
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al guardar el outfit',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Outfit'),
        actions: [
          // --- LÓGICA DEL BOTÓN MODIFICADA ---
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _saveOutfit, // Llama a la nueva función
              tooltip: 'Guardar Outfit',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GarmentPlaceholder(
                label: 'Parte Superior',
                placeholderIconPath: 'assets/icons/camiseta.png',
                selectedGarmentUrl: _selectedTop?['imageUrl'],
                fit: _topFit,
                onToggleFit: _selectedTop != null
                    ? () => _toggleFit('top')
                    : null,
                onTap: () =>
                    _selectGarment('top', (garment) => _selectedTop = garment),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GarmentPlaceholder(
                label: 'Parte Inferior',
                placeholderIconPath: 'assets/icons/vaqueros.png',
                selectedGarmentUrl: _selectedBottom?['imageUrl'],
                fit: _bottomFit,
                onToggleFit: _selectedBottom != null
                    ? () => _toggleFit('bottom')
                    : null,
                onTap: () => _selectGarment(
                  'bottom',
                  (garment) => _selectedBottom = garment,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GarmentPlaceholder(
                label: 'Calzado',
                placeholderIconPath: 'assets/icons/zapatos.png',
                selectedGarmentUrl: _selectedShoes?['imageUrl'],
                fit: _shoesFit,
                onToggleFit: _selectedShoes != null
                    ? () => _toggleFit('shoes')
                    : null,
                onTap: () => _selectGarment(
                  'footwear',
                  (garment) => _selectedShoes = garment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
