import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/mock_data_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/primary_button.dart';

const _cities = ['Chennai', 'Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad'];
const _platforms = ['Zepto', 'Blinkit', 'Swiggy Instamart', 'Dunzo', 'BB Now'];

const Map<String, List<String>> _cityZones = {
  'Chennai': [
    'Adyar Dark Store Zone', 'Anna Nagar Dark Store Zone', 'T Nagar Dark Store Zone',
    'OMR Dark Store Zone', 'Velachery Dark Store Zone', 'Porur Dark Store Zone',
    'Tambaram Dark Store Zone', 'Sholinganallur Dark Store Zone', 'Mylapore Dark Store Zone', 'Perambur Dark Store Zone'
  ],
  'Bengaluru': [
    'Koramangala Dark Store Zone', 'HSR Layout Dark Store Zone', 'Indiranagar Dark Store Zone',
    'Whitefield Dark Store Zone', 'Electronic City Dark Store Zone', 'Jayanagar Dark Store Zone',
    'Marathahalli Dark Store Zone', 'BTM Layout Dark Store Zone', 'Hebbal Dark Store Zone', 'Sarjapur Dark Store Zone'
  ],
  'Mumbai': [
    'Andheri Dark Store Zone', 'Bandra Dark Store Zone', 'Powai Dark Store Zone',
    'Thane Dark Store Zone', 'Malad Dark Store Zone', 'Borivali Dark Store Zone',
    'Goregaon Dark Store Zone', 'Kurla Dark Store Zone', 'Dadar Dark Store Zone', 'Chembur Dark Store Zone'
  ],
  'Delhi': [
    'Connaught Place Dark Store Zone', 'Lajpat Nagar Dark Store Zone', 'Dwarka Dark Store Zone',
    'Rohini Dark Store Zone', 'Saket Dark Store Zone', 'Noida Sector 18 Dark Store Zone',
    'Gurugram Sector 29 Dark Store Zone', 'Karol Bagh Dark Store Zone', 'Pitampura Dark Store Zone', 'Vasant Kunj Dark Store Zone'
  ],
  'Hyderabad': [
    'Banjara Hills Dark Store Zone', 'Hitech City Dark Store Zone', 'Gachibowli Dark Store Zone',
    'Madhapur Dark Store Zone', 'Kukatpally Dark Store Zone', 'Secunderabad Dark Store Zone',
    'Ameerpet Dark Store Zone', 'LB Nagar Dark Store Zone', 'Kondapur Dark Store Zone', 'Uppal Dark Store Zone'
  ],
};

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();

  String? _selectedCity;
  String? _selectedZone;
  String? _selectedPlatform;
  bool _saving = false;

  int get _activeStep {
    if (_nameController.text.trim().isEmpty) return 1;
    if (_selectedCity == null) return 2;
    if (_selectedZone == null) return 3;
    if (_selectedPlatform == null) return 4;
    return 5;
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { _showError('Please enter your name.'); return; }
    if (_selectedCity == null) { _showError('Please select your city.'); return; }
    if (_selectedZone == null) { _showError('Please select your zone.'); return; }
    if (_selectedPlatform == null) { _showError('Please select your platform.'); return; }

    setState(() => _saving = true);

    try {
      final phone = await StorageService.instance.getPhone() ?? '';

      final workerData = await ApiService.instance.registerWorker(
        name: name,
        phone: phone,
        zone: _selectedZone!,
        city: _selectedCity!,
        platform: _selectedPlatform!,
      );

      final userId = workerData['user']['id'] as String;

      await StorageService.setUserId(userId);
      await StorageService.setString('userName', name);
      await StorageService.setUserZone(_selectedZone!);
      await StorageService.setString('userCity', _selectedCity!);

      final policyData = await ApiService.instance.createPolicy(
        userId: userId,
        planTier: 'standard',
      );

      final policyId = policyData['policy']['id'] as String;
      await StorageService.setPolicyId(policyId);

      // Add premium deducted notification
      NotificationService.instance.addPremiumDeducted(49);

      await StorageService.setOnboarded(true);

      final box = Hive.box('appData');
      await box.put('userName', name);
      await box.put('userCity', _selectedCity);
      await box.put('userZone', _selectedZone);
      await box.put('userPlatform', _selectedPlatform);
      await box.put('onboardingComplete', true);

      if (!mounted) return;

      Provider.of<MockDataService>(context, listen: false).syncWithStorage();
      context.go(AppRoutes.onboardingComplete);
    } catch (e) {
      print('Onboarding error: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Theme.of(context).colorScheme.onError)),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  void _showZonePicker(BuildContext context) {
    if (_selectedCity == null) return;
    final zones = _cityZones[_selectedCity] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredZones = searchQuery.isEmpty 
              ? zones 
              : zones.where((z) => z.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Search your zone...",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredZones.length,
                        itemBuilder: (context, index) {
                          final zone = filteredZones[index];
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedZone = zone);
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, color: Color(0xFF2E7D32), size: 8),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(zone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B0F))),
                                        const SizedBox(height: 2),
                                        Text('$_selectedCity, India', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (_selectedZone == zone)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputRadius = BorderRadius.circular(isDark ? 24 : 16);

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        backgroundColor: theme.canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'HUSTLR',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            Text('Profile Setup', style: theme.textTheme.displayMedium),
            const SizedBox(height: 12),
            Text(
              'Enter your details to get your personalised protection plan.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 48),

            // ── Step 1: Name ─────────────────────────────────────────────────
            Text('WHAT IS YOUR NAME?', style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: inputRadius,
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Step 2: City ─────────────────────────────────────────────────
            Text('WHICH CITY DO YOU WORK IN?', style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: _cities.map((city) {
                final isSelected = city == _selectedCity;
                return GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    if (_selectedCity != city) {
                      setState(() {
                        _selectedCity = city;
                        _selectedZone = null; // Clear selected zone when city changes
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark || !isSelected ? [] : [
                        BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))
                      ],
                    ),
                    child: Text(
                      city,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? theme.canvasColor : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // ── Step 3: Zone ─────────────────────────────────────────────────
            Text('WHICH ZONE DO YOU WORK IN?', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              'Select your ${_selectedPlatform ?? 'Zepto'} dark store delivery zone',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectedCity != null ? () => _showZonePicker(context) : null,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _selectedCity != null ? const Color(0xFFE5E7EB) : const Color(0xFFE5E7EB).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 8, offset: Offset(0, 2))
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: _selectedCity != null ? const Color(0xFF2E7D32) : Colors.grey.shade400, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectedZone == null
                          ? Text("Search your zone...", style: TextStyle(color: Colors.grey.shade500, fontSize: 14))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_selectedZone!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B0F))),
                                Text(_selectedCity ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.1)),
                              ],
                            ),
                    ),
                    if (_selectedZone != null)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18)
                    else
                      Icon(Icons.keyboard_arrow_down_rounded, color: _selectedCity != null ? const Color(0xFF2E7D32) : Colors.grey.shade400),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Step 4: Platform ─────────────────────────────────────────────
            Text('WHICH PLATFORM DO YOU USE?', style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: _platforms.map((platform) {
                final isSelected = platform == _selectedPlatform;
                return GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _selectedPlatform = platform);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (MediaQuery.of(context).size.width - 56 - 12) / 2,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.surface : theme.cardColor,
                      borderRadius: inputRadius,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: isDark ? 1 : 2,
                      ),
                      boxShadow: isDark || isSelected ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          platform,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: theme.canvasColor,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Row(
          children: [
            Expanded(
              child: PrimaryButton(
                text: 'Create Profile',
                isLoading: _saving,
                onPressed: _activeStep == 5 ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
