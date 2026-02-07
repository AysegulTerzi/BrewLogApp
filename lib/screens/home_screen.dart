import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/brew_recipe.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;
  String _searchQuery = '';
  // ignore: unused_field
  bool _isSearching = false;
  final _searchController = TextEditingController();
  BrewRecipe? _compareA;
  BrewRecipe? _compareB;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to filter recipes for selection dialog
  void _showRecipeSelector(BuildContext context, bool isSlotA) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final databaseService = Provider.of<DatabaseService>(context, listen: false);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Text(
                'Select a Brew',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<BrewRecipe>>(
                  future: databaseService.getRecipes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final recipes = snapshot.data!;
                    return ListView.builder(
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return ListTile(
                          leading: const Icon(Icons.coffee),
                          title: Text(recipe.coffeeName),
                          subtitle: Text('${DateFormat.yMMMd().format(recipe.timestamp)} • ${recipe.brewingMethod}'),
                          onTap: () {
                            setState(() {
                              if (isSlotA) {
                                _compareA = recipe;
                              } else {
                                _compareB = recipe;
                              }
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final theme = Theme.of(context);

    // Filter logic is now handled inside StreamBuilder

    Widget _buildLogsView() {
      return Column(
        children: [
          // Custom Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                // Top Bar: Title - Add - Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Brew Logs',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                     PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      color: Colors.white,
                      onSelected: (value) {
                        if (value == 'Profile') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                           const PopupMenuItem<String>(
                            value: 'Profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.black54),
                                SizedBox(width: 8),
                                Text('Profile'),
                              ],
                            ),
                          ),
                           const PopupMenuItem<String>(
                            value: 'Settings',
                            child: Row(
                              children: [
                                Icon(Icons.settings, color: Colors.black54),
                                SizedBox(width: 8),
                                Text('Settings'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Compact Search Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 40, // Reduced height
                  decoration: BoxDecoration(
                    color: const Color(0xFF252A40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 20, color: theme.colorScheme.onPrimary.withOpacity(0.5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search brews...',
                            hintStyle: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.5)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.only(bottom: 10), // Adjust logic for smaller height
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onPrimary.withOpacity(0.5)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
           // Floating Action Button (Alternative placement found in some designs, keeping clean for now or moving Add here?
           // User didn't ask to move Add button, keeping it in header is fine but maybe inconsistent with Profile.
           // Leaving Add button logic as is for now: it was removed! NO, it was in the header. Wait, I replaced it!
           // The previous code had Add button in the header. I replaced it with Profile.
           // I should probably keep the Add button OR move it to a FloatingActionButton.
           // Let's check the previous header row. It was Menu - Title - Add.
           // User asked: "profil sayfasını alttaki bara değil de sağ üstteki açılır menüye koyalım"
           // So Top Right should be Menu. What about Add?
           // I'll put Add button as a Floating Action Button for better scrolling UX or keep it next to Profile? 
           // Better: Menu(Left) - Title(Center) - [Add, Profile](Right). Or just replace Add? No, we need Add.
           // I will put Add Back in.
           
          // White Curved Content Area
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F4F8), // Off-white background for list
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  child: StreamBuilder<List<BrewRecipe>>(
                    stream: databaseService.getRecipesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final allRecipes = snapshot.data ?? [];
                      // Apply search filter client-side
                      final recipes = _searchQuery.isEmpty 
                          ? allRecipes 
                          : allRecipes.where((r) => 
                              r.coffeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              r.roastery.toLowerCase().contains(_searchQuery.toLowerCase())
                            ).toList();

                      if (recipes.isEmpty) {
                         return Center(
                           child: Text(
                             _searchQuery.isEmpty ? 'No brews yet.' : 'No matches found.',
                             style: const TextStyle(color: Colors.grey),
                           ),
                         );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80), // Extra padding for FAB
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return _RecipeCard(recipe: recipe);
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton(
                    onPressed: () async {
                       await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
                      );
                      setState(() {}); // Refresh list
                    },
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildSelectionCard(BrewRecipe? recipe, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF252A40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.all(12),
            child: recipe == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.white54, size: 32),
                      const SizedBox(height: 8),
                      Text('Select Brew', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.coffeeName, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d').format(recipe.timestamp),
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                         child: Text(recipe.brewingMethod, style: const TextStyle(color: Colors.white, fontSize: 10)),
                      )
                    ],
                  ),
          ),
        ),
      );
    }

    Widget _buildCompareRow(String label, String? valA, String? valB) {
       final bool isDifferent = valA != valB && valA != null && valB != null;
       final Color highlightColor = isDifferent ? const Color(0xFFD2691E) : Colors.black87;
       
       return Padding(
         padding: const EdgeInsets.symmetric(vertical: 12),
         child: Row(
           children: [
             Expanded(child: Text(valA ?? '-', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: highlightColor))),
             Expanded(child: Text(label.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold))),
             Expanded(child: Text(valB ?? '-', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: highlightColor))),
           ],
         ),
       );
    }

    Widget _buildCompareView() {
      return Column(
        children: [
           Padding(
             padding: const EdgeInsets.all(24),
             child: Column(
               children: [
                 Text('Compare Brews', style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 24),
                 Row(
                   children: [
                     _buildSelectionCard(_compareA, () => _showRecipeSelector(context, true)),
                     const Icon(Icons.compare_arrows, color: Colors.white24, size: 32),
                     _buildSelectionCard(_compareB, () => _showRecipeSelector(context, false)),
                   ],
                 ),
               ],
             ),
           ),
           Expanded(
             child: Container(
               width: double.infinity,
               decoration: const BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
               ),
               padding: const EdgeInsets.all(24),
               child: SingleChildScrollView(
                 child: Column(
                   children: [
                     _buildCompareRow('Origin', _compareA?.origin, _compareB?.origin),
                     const Divider(),
                     _buildCompareRow('Variety', _compareA?.variety, _compareB?.variety),
                     const Divider(),
                     _buildCompareRow('Process', _compareA?.process, _compareB?.process),
                     const Divider(),
                     _buildCompareRow('Roast', _compareA?.roastLevel, _compareB?.roastLevel),
                     const Divider(),
                     _buildCompareRow('Method', _compareA?.brewingMethod, _compareB?.brewingMethod),
                     const Divider(),
                     _buildCompareRow('Ratio', _compareA?.ratio, _compareB?.ratio),
                     const Divider(),
                     _buildCompareRow('Grind', _compareA?.grindSize, _compareB?.grindSize),
                     const Divider(),
                     _buildCompareRow('Temp', _compareA != null ? '${_compareA!.waterTemp}°C' : null, _compareB != null ? '${_compareB!.waterTemp}°C' : null),
                     const Divider(),
                     _buildCompareRow('Time', _compareA != null ? '${_compareA!.brewTimeSeconds}s' : null, _compareB != null ? '${_compareB!.brewTimeSeconds}s' : null),
                     const Divider(),
                     _buildCompareRow('Rating', _compareA?.rating.toString(), _compareB?.rating.toString()),
                   ],
                 ),
               ),
             ),
           )
        ],
      );
    }

    Widget _getBody() {
      switch (_bottomNavIndex) {
        case 0: return _buildLogsView();
        case 1: return _buildCompareView();
        default: return _buildLogsView();
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.primary, // Dark Navy
      body: SafeArea(
        bottom: false,
        child: _getBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        backgroundColor: const Color(0xFFF2F4F8), // Match content bg
        elevation: 0,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.compare_arrows), label: 'Compare'),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final BrewRecipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Name + Process
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              recipe.coffeeName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${recipe.process}', // e.g. "• Washed"
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Specs: Method - Dose - Water
                      Text(
                        '${recipe.brewingMethod}  •  ${recipe.ratio}  •  ${recipe.waterTemp}°C', 
                        // Note: Using ratio/temp as filler for now, ideally needs dose/yield fields
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Date
                      Text(
                        DateFormat('MMM d • HH:mm').format(recipe.timestamp),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trailing Visual (Rating / Icon)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4EC), // Light Orange/Cream
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                       const Icon(Icons.coffee, color: Color(0xFFD2691E), size: 20),
                       const SizedBox(height: 4),
                       Text(
                         recipe.rating.toStringAsFixed(1),
                         style: const TextStyle(
                           color: Color(0xFFD2691E),
                           fontWeight: FontWeight.bold,
                           fontSize: 12,
                         ),
                       )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingIndicator extends StatelessWidget {
  final double rating;

  const _RatingIndicator({required this.rating});

  @override
  Widget build(BuildContext context) {
    // Simple star representation for the card summary
    return Row(
      children: [
        Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
