import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/storage_service.dart';
import '../../services/mock_data_service.dart';

import '../../core/constants/colors.dart' as app_colors;
import '../../core/router/app_router.dart';
import '../../shared/widgets/mobile_container.dart';

// ─── Constants (mapping to global tokens) ──────────────────────────────────
const _green = app_colors.primaryGreen;
const _lightGreen = app_colors.lightGreen;
const _bg = app_colors.background;
const _textPrimary = app_colors.textPrimary;
const _textSub = app_colors.textSecondary;
const _borderLight = Color(0xFFE5E7EB);
const _chipInactive = app_colors.textHint;

const _cities = ['Chennai', 'Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad'];

// Platform data: name + brand colour
const _platforms = [
  _Platform('Zepto', Color(0xFFE23744)),
  _Platform('Blinkit', Color(0xFFF8D210)),
  _Platform('Swiggy Instamart', Color(0xFFFC8019)),
  _Platform('Dunzo', Color(0xFF00A699)),
  _Platform('BB Now', Color(0xFF00833E)),
];

class _Platform {
  final String name;
  final Color color;
  const _Platform(this.name, this.color);
}

// ─── OnboardingScreen ─────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String? _selectedCity = 'Chennai';
  String? _selectedZone;
  String? _selectedPlatform = 'Zepto';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Active step index for progress dots (simple scroll – all steps visible)
  int get _activeDot {
    if (_selectedPlatform != null) return 3;
    if (_selectedZone != null) return 2;
    if (_selectedCity != null) return 1;
    return 0;
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (_selectedCity == null) {
      _showError('Please select your city.');
      return;
    }
    if (_selectedZone == null) {
      _showError('Please select your delivery zone.');
      return;
    }
    if (_selectedPlatform == null) {
      _showError('Please select your platform.');
      return;
    }

    setState(() => _saving = true);
    
    final box = Hive.box('appData');
    await box.put('userName', name);
    await box.put('userCity', _selectedCity);
    await box.put('userZone', _selectedZone);
    await box.put('userPlatform', _selectedPlatform);
    await box.put('onboardingComplete', true); // ← Mark onboarding done before leaving

    if (!mounted) return;
    
    // Sync Mock Data Service immediately
    Provider.of<MockDataService>(context, listen: false).syncWithStorage();
    
    context.go(AppRoutes.onboardingComplete);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: MobileContainer(
        child: Stack(
          children: [
            // ── Scrollable body ────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top bar
                _TopBar(),
                const SizedBox(height: 12),
                // Progress dots
                _ProgressDots(active: _activeDot),
                const SizedBox(height: 12),
                // ONBOARDING pill badge
                _PillBadge(),
                const SizedBox(height: 16),
                // Scrollable steps
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── STEP 1 ─────────────────────────────────────────
                        const _StepTitle('Step 1: What\'s your name?'),
                        const SizedBox(height: 12),
                        _NameField(controller: _nameController),

                        const SizedBox(height: 28),
                        // ── STEP 2 ─────────────────────────────────────────
                        const _StepTitle('Step 2: Which city do you work in?'),
                        const SizedBox(height: 12),
                        _CityChips(
                          cities: _cities,
                          selected: _selectedCity,
                          onSelect: (c) {
                            if (_selectedCity != c) {
                              setState(() {
                                _selectedCity = c;
                                _selectedZone = null;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 28),
                        // ── STEP 3 ─────────────────────────────────────────
                        const _StepTitle('Step 3: Your work area'),
                        const SizedBox(height: 12),
                        _AreaSearchField(
                          zones: context.watch<MockDataService>().autocompleteCities[_selectedCity] ?? [],
                          city: _selectedCity ?? 'Chennai',
                          selectedZone: _selectedZone,
                          onSelect: (v) {
                            setState(() => _selectedZone = v);
                            if (v != null) FocusScope.of(context).unfocus();
                          },
                        ),

                        const SizedBox(height: 28),
                        // ── STEP 4 ─────────────────────────────────────────
                        const _StepTitle('Step 4: Which platform?'),
                        const SizedBox(height: 12),
                        _PlatformGrid(
                          platforms: _platforms,
                          selected: _selectedPlatform,
                          onSelect: (p) =>
                              setState(() => _selectedPlatform = p),
                        ),

                        const SizedBox(height: 16),
                        // ── Data trust banner ──────────────────────────────
                        _DataTrustBanner(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky Continue button ─────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 76, // above the faded nav (64px) + 12px gap
            child: _ContinueButton(loading: _saving, onTap: _onContinue),
          ),

          // ── Faded bottom nav (decorative) ──────────────────────────────────
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FadedBottomNav(),
          ),

          // ── Floating help button ───────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 82,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.headset_mic_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
          const Expanded(
            child: Text(
              'Hustlr Onboarding',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

// ─── Progress dots ────────────────────────────────────────────────────────────
class _ProgressDots extends StatelessWidget {
  final int active;
  const _ProgressDots({required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isActive = i == active;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _green : _chipInactive,
          ),
        );
      }),
    );
  }
}

// ─── ONBOARDING pill badge ────────────────────────────────────────────────────
class _PillBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _lightGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'ONBOARDING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _green,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Step title ───────────────────────────────────────────────────────────────
class _StepTitle extends StatelessWidget {
  final String text;
  const _StepTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
    );
  }
}

// ─── Step 1: Name field ───────────────────────────────────────────────────────
class _NameField extends StatelessWidget {
  final TextEditingController controller;
  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _borderLight),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Enter your full name',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        ),
        style: const TextStyle(fontSize: 14, color: _textPrimary),
      ),
    );
  }
}

// ─── Step 2: City chips ───────────────────────────────────────────────────────
class _CityChips extends StatelessWidget {
  final List<String> cities;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CityChips(
      {required this.cities,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cities.map((city) {
        final isSelected = city == selected;
        return GestureDetector(
          onTap: () => onSelect(city),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? _green : _chipInactive,
                width: 1.5,
              ),
            ),
            child: Text(
              city,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? _green : _textSub,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Step 3: Area Search Field ───────────────────────────────────────────────
class _AreaSearchField extends StatefulWidget {
  final List<String> zones;
  final String city;
  final String? selectedZone;
  final ValueChanged<String?> onSelect;

  const _AreaSearchField({
    required this.zones,
    required this.city,
    required this.selectedZone,
    required this.onSelect,
  });

  @override
  State<_AreaSearchField> createState() => _AreaSearchFieldState();
}

class _AreaSearchFieldState extends State<_AreaSearchField> {
  String _searchQuery = '';
  List<String> _filteredAreas = [];
  final TextEditingController _controller = TextEditingController();

  void _filterAreas(String query) {
    setState(() {
      _searchQuery = query;
      _filteredAreas = query.isEmpty
          ? []
          : widget.zones
              .where((area) =>
                  area.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  void didUpdateWidget(covariant _AreaSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedZone == null && oldWidget.selectedZone != null) {
      _controller.clear();
      _searchQuery = '';
      _filteredAreas = [];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _filterAreas,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, color: _green, size: 22),
            hintText: 'Type your area or dark store location...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(fontSize: 14, color: _textPrimary),
        ),
        if (_filteredAreas.isNotEmpty && widget.selectedZone == null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _filteredAreas.length,
              itemBuilder: (context, index) {
                final area = _filteredAreas[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_rounded, color: _green),
                  title: Text(area, style: const TextStyle(fontSize: 14, color: _textPrimary)),
                  subtitle: Text(widget.city, style: const TextStyle(fontSize: 12, color: _textSub)),
                  onTap: () {
                    setState(() {
                      _filteredAreas = [];
                      _searchQuery = area;
                      _controller.text = area;
                    });
                    widget.onSelect(area);
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
        if (widget.selectedZone != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Chip(
              avatar: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              label: Text(widget.selectedZone!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: _green,
              deleteIcon: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              onDeleted: () {
                _controller.clear();
                widget.onSelect(null);
                setState(() {
                  _filteredAreas = [];
                  _searchQuery = '';
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              side: BorderSide.none,
            ),
          ),
      ],
    );
  }
}

// ─── Step 4: Platform grid ────────────────────────────────────────────────────
class _PlatformGrid extends StatelessWidget {
  final List<_Platform> platforms;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _PlatformGrid(
      {required this.platforms,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // Split into pairs; last item (Dunzo) if odd gets full width
    final rows = <Widget>[];
    for (int i = 0; i < platforms.length; i += 2) {
      if (i + 1 < platforms.length) {
        rows.add(Row(children: [
          Expanded(
              child: _PlatformCard(
                  p: platforms[i],
                  selected: selected,
                  onSelect: onSelect)),
          const SizedBox(width: 12),
          Expanded(
              child: _PlatformCard(
                  p: platforms[i + 1],
                  selected: selected,
                  onSelect: onSelect)),
        ]));
      } else {
        // Odd last item → centred full width
        rows.add(Row(children: [
          Expanded(
              child: _PlatformCard(
                  p: platforms[i],
                  selected: selected,
                  onSelect: onSelect)),
          const SizedBox(width: 12),
          const Expanded(child: SizedBox()),
        ]));
      }
      if (i + 2 < platforms.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _PlatformCard extends StatelessWidget {
  final _Platform p;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _PlatformCard(
      {required this.p, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isSelected = p.name == selected;
    return GestureDetector(
      onTap: () => onSelect(p.name),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _green : _borderLight,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder — coloured icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconFor(p.name),
                color: p.color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              p.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'Zepto':
        return Icons.electric_bolt_rounded;
      case 'Blinkit':
        return Icons.flash_on_rounded;
      case 'Swiggy Instamart':
        return Icons.shopping_basket_rounded;
      case 'Dunzo':
        return Icons.all_inclusive_rounded;
      case 'BB Now':
        return Icons.local_grocery_store_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}

// ─── Data trust banner ────────────────────────────────────────────────────────
class _DataTrustBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Your data is safe. We only use this to calculate your weekly risk score.',
              style: TextStyle(
                fontSize: 12,
                color: _textSub,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sticky continue button ───────────────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _ContinueButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }
}

// ─── Faded bottom nav (decorative) ───────────────────────────────────────────
class _FadedBottomNav extends StatelessWidget {
  const _FadedBottomNav();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'HOME'),
      (Icons.shield_rounded, 'POLICY'),
      (Icons.receipt_long_rounded, 'CLAIMS'),
      (Icons.account_balance_wallet_rounded, 'WALLET'),
      (Icons.person_rounded, 'PROFILE'),
    ];

    return Opacity(
      opacity: 0.45,
      child: Container(
        height: 64,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items
              .map(
                (item) => SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$1, size: 22, color: const Color(0xFF9CA3AF)),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
