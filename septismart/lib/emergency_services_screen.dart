import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;

class EmergencyServicesScreen extends StatelessWidget {
  const EmergencyServicesScreen({super.key});

  Future<List<_Company>> _loadCompanies() async {
    final jsonStr = await rootBundle.loadString('assets/emergency_services.json');
    final raw = json.decode(jsonStr) as List<dynamic>;
    return raw.map((e) => _Company.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Services')),
      body: FutureBuilder<List<_Company>>(
        future: _loadCompanies(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Failed to load services: ${snap.error}'),
            );
          }
          final items = snap.data ?? const <_Company>[];
          if (items.isEmpty) {
            return const Center(child: Text('No services found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = items[i];
              return Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.apartment),
                  ),
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.address),
                        const SizedBox(height: 6),
                        _RatingRow(rating: c.rating),
                        const SizedBox(height: 4),
                        Text('Phone: ${c.phoneNumber}'),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Copy phone',
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: c.phoneNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number copied')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Company {
  final String name;
  final String address;
  final String phoneNumber;
  final double rating;
  const _Company({
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.rating,
  });

  factory _Company.fromMap(Map<String, dynamic> m) {
    // We ignore the Mongo-style _id and just map the fields we need.
    return _Company(
      name: (m['name'] ?? '') as String,
      address: (m['address'] ?? '') as String,
      phoneNumber: (m['phoneNumber'] ?? '') as String,
      rating: (m['rating'] is num) ? (m['rating'] as num).toDouble() : 0.0,
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    final empty = 5 - full - (half ? 1 : 0);

    return Row(
      children: [
        for (var i = 0; i < full; i++) const Icon(Icons.star, size: 16),
        if (half) const Icon(Icons.star_half, size: 16),
        for (var i = 0; i < empty; i++) const Icon(Icons.star_border, size: 16),
        const SizedBox(width: 6),
        Text(rating.toStringAsFixed(1)),
      ],
    );
  }
}
