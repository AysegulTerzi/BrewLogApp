import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/brew_recipe.dart';
import '../services/database_service.dart';
import 'add_recipe_screen.dart';
import 'live_brew_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final BrewRecipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BrewRecipe>(
      stream: DatabaseService().getRecipeStream(widget.recipe.id),
      initialData: widget.recipe,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final currentRecipe = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentRecipe.coffeeName, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddRecipeScreen(originalRecipe: currentRecipe)),
                  );
                  // Force refresh by rebuilding, which re-subscribes to the stream
                  if (mounted) setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, currentRecipe),
              const SizedBox(height: 20),
              _buildTimeline(currentRecipe.steps),
              const SizedBox(height: 20),
              _buildInfoCard(context, currentRecipe),
              const SizedBox(height: 20),
              _buildBrewStats(context, currentRecipe),
              const SizedBox(height: 20),
              _buildAnalysisSection(context, currentRecipe),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LiveBrewScreen(recipe: currentRecipe)),
              );
            },
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Start Live Brew', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildTimeline(List<BrewStep> steps) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timeline',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Line & Dot
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5D7B93), // Muted Blue
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: const Color(0xFFE0E0E0),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A1F36),
                                ),
                              ),
                              Text(
                                step.waterAmount,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1F36),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.time,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (!isLast) const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, BrewRecipe recipe) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white.withOpacity(0.1),
          child: const Icon(Icons.coffee, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          recipe.roastery.isNotEmpty ? recipe.roastery : 'Unknown Roaster',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          DateFormat.yMMMd().format(recipe.timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, BrewRecipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             _buildRow(context, 'Origin', recipe.origin),
             const Divider(),
             _buildRow(context, 'Variety', recipe.variety),
             const Divider(),
             _buildRow(context, 'Process', recipe.process),
             const Divider(),
             _buildRow(context, 'Roast Level', recipe.roastLevel),
             if (recipe.roastDate != null) ...[
               const Divider(),
               _buildRow(context, 'Roast Date', DateFormat.yMMMd().format(recipe.roastDate!)),
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildBrewStats(BuildContext context, BrewRecipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Brew Parameters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, Icons.filter_alt, recipe.brewingMethod),
                _buildStatItem(context, Icons.straighten, recipe.ratio),
                _buildStatItem(context, Icons.grid_on, recipe.grindSize),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, Icons.thermostat, '${recipe.waterTemp}°C'),
                _buildStatItem(context, Icons.timer, _formatDuration(recipe.brewTimeSeconds)),
                _buildStatItem(context, recipe.isIced ? Icons.ac_unit : Icons.local_fire_department, recipe.isIced ? 'Iced' : 'Hot'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(label.isNotEmpty ? label : '-', style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAnalysisSection(BuildContext context, BrewRecipe recipe) {
    List<String> suggestions = _analyzeBrew(recipe);

    return Card(
      color: suggestions.isNotEmpty ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.brown),
                const SizedBox(width: 8),
                Text('Brew Analysis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Rating: ${recipe.rating}/5.0', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Notes: "${recipe.notes}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            if (suggestions.isNotEmpty) ...[
              const Divider(),
              const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              const SizedBox(height: 4),
              ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(s)),
                  ],
                ),
              )),
            ]
          ],
        ),
      ),
    );
  }

  List<String> _analyzeBrew(BrewRecipe recipe) {
    List<String> suggestions = [];
    String notes = recipe.notes.toLowerCase();

    if (notes.contains('sour') || notes.contains('acidic') || notes.contains('under')) {
      suggestions.add('Sourness often means under-extraction.');
      suggestions.add('Try grinding finer.');
      suggestions.add('Try increasing water temperature.');
      suggestions.add('Try extending brew time.');
    }

    if (notes.contains('bitter') || notes.contains('astringent') || notes.contains('dry') || notes.contains('over')) {
      suggestions.add('Bitterness often means over-extraction.');
      suggestions.add('Try grinding coarser.');
      suggestions.add('Try decreasing water temperature.');
      suggestions.add('Try shortening brew time.');
    }

    if (notes.contains('weak') || notes.contains('watery')) {
      suggestions.add('Weak coffee might mean your ratio is off.');
      suggestions.add('Try using less water or more coffee (tighten ratio, e.g. 1:15 to 1:14).');
    }
    
    if (notes.contains('strong') || notes.contains('intense')) {
        suggestions.add('If too intense, try using more water (loosen ratio, e.g. 1:15 to 1:16).');
    }

    return suggestions;
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m}m ${s}s';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final db = DatabaseService();
              await db.deleteRecipe(widget.recipe.id);
              if (context.mounted) {
                 Navigator.pop(context); // Close dialog
                 Navigator.pop(context); // Go back to Home
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
