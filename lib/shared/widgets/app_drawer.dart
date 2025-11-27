import 'package:armariovirtual/config/app_theme.dart';
import 'package:armariovirtual/features/outfits/screen/outfits_screen.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    return Drawer(
      width: 250,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            color: AppTheme.colorPrimario,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            child: Text(
              'Armario Virtual',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ),
          // --- Opción Mi Armario ---
          ListTile(
            leading: const Icon(Icons.checkroom),
            title: const Text('Mi Armario'),
            selected: currentRoute == '/home',
            onTap: () {
              if (currentRoute == '/home') {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          // --- Opción Outfits ---
          ListTile(
            leading: Image.asset(
              'assets/icons/disfraz.png',
              width: 30,
              height: 30,
            ),
            title: const Text('Outfits'),
            selected: currentRoute == '/outfits',
            onTap: () {
              // Cierra el menú y navega a la pantalla de Outfits
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const OutfitsScreen(),
                  // Le damos un nombre a la ruta para poder identificarla
                  settings: const RouteSettings(name: '/outfits'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
