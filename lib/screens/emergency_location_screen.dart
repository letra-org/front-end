import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyLocationScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const EmergencyLocationScreen({super.key, required this.onNavigate});

  @override
  State<EmergencyLocationScreen> createState() => _EmergencyLocationScreenState();
}

class _EmergencyLocationScreenState extends State<EmergencyLocationScreen> {
  bool _locationShared = false;
  bool _copied = false;

  final Map<String, dynamic> _currentLocation = {
    'lat': 16.0544,
    'lng': 108.2022,
    'address': 'Đà Nẵng, Việt Nam',
    'accuracy': '±10m',
  };

  final List<Map<String, String>> _emergencyContacts = [
    {'name': 'Cảnh sát', 'number': '113', 'icon': '🚓'},
    {'name': 'Cứu hỏa', 'number': '114', 'icon': '🚒'},
    {'name': 'Cấp cứu', 'number': '115', 'icon': '🚑'},
    {'name': 'Cứu hộ', 'number': '112', 'icon': '⛑️'},
  ];

  void _handleShareLocation() {
    setState(() {
      _locationShared = true;
    });
  }

  void _handleCopyLocation() {
    final locationText = 'Vị trí khẩn cấp: ${_currentLocation['address']}\n'
        'Tọa độ: ${_currentLocation['lat']}, ${_currentLocation['lng']}\n'
        'Độ chính xác: ${_currentLocation['accuracy']}';
    
    Clipboard.setData(ClipboardData(text: locationText));
    setState(() {
      _copied = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.red.shade600,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => widget.onNavigate('settings'),
                    ),
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Chia sẻ vị trí cứu hộ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade600),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Chức năng này chỉ sử dụng trong trường hợp khẩn cấp',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Current Location
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Vị trí hiện tại của bạn',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Địa chỉ: ${_currentLocation['address']}'),
                        Text('Tọa độ: ${_currentLocation['lat']}, ${_currentLocation['lng']}'),
                        Text('Độ chính xác: ${_currentLocation['accuracy']}'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _locationShared ? null : _handleShareLocation,
                                icon: Icon(_locationShared ? Icons.check : Icons.send),
                                label: Text(_locationShared ? 'Đã chia sẻ' : 'Chia sẻ vị trí'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _handleCopyLocation,
                              icon: Icon(_copied ? Icons.check : Icons.copy),
                              style: IconButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_locationShared) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade600),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Vị trí đã được gửi. Vui lòng giữ điện thoại bật.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Emergency Contacts
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text(
                              'Số điện thoại khẩn cấp',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: _emergencyContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _emergencyContacts[index];
                            return InkWell(
                              onTap: () {
                                // Call number
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      contact['icon']!,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      contact['name']!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      contact['number']!,
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
