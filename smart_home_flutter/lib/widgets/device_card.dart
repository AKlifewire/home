import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String name;
  final String type;
  final String? location;
  final String? status;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const DeviceCard({
    Key? key,
    required this.name,
    required this.type,
    this.location,
    this.status,
    required this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getIconForDeviceType(type), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (location != null)
                          Text(
                            location!,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onFavorite != null)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: onFavorite,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(status),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String label;

    switch (status?.toLowerCase()) {
      case 'online':
        color = Colors.green;
        label = 'Online';
        break;
      case 'offline':
        color = Colors.grey;
        label = 'Offline';
        break;
      case 'error':
        color = Colors.red;
        label = 'Error';
        break;
      default:
        color = Colors.orange;
        label = status ?? 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  IconData _getIconForDeviceType(String type) {
    switch (type.toLowerCase()) {
      case 'relay':
        return Icons.power;
      case 'sensor':
        return Icons.thermostat;
      case 'camera':
        return Icons.camera_alt;
      case 'light':
        return Icons.lightbulb;
      case 'thermostat':
        return Icons.thermostat;
      case 'lock':
        return Icons.lock;
      default:
        return Icons.devices;
    }
  }
}