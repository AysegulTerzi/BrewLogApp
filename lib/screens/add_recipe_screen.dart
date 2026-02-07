import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/brew_recipe.dart';
import '../services/database_service.dart';

class AddRecipeScreen extends StatefulWidget {
  final BrewRecipe? originalRecipe;

  const AddRecipeScreen({super.key, this.originalRecipe});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _coffeeNameController = TextEditingController();
  final _roasteryController = TextEditingController();
  final _originController = TextEditingController();
  final _varietyController = TextEditingController();
  final _processController = TextEditingController();
  final _methodController = TextEditingController();
  final _ratioController = TextEditingController();
  final _grindSizeController = TextEditingController();
  final _waterTempController = TextEditingController();
  final _brewTimeMinController = TextEditingController();
  final _brewTimeSecController = TextEditingController();
  final _notesController = TextEditingController();
  final _grinderController = TextEditingController(); // New controller
  final _roastLevelController = TextEditingController(); // New controller

  DateTime? _roastDate;
  String _roastLevel = 'Medium'; // Default
  bool _isIced = false;
  double _rating = 3.0;

  bool _isSubmitting = false;

  // Timeline Steps
  List<BrewStep> _steps = [];

  @override
  void initState() {
    super.initState();
    if (widget.originalRecipe != null) {
      final r = widget.originalRecipe!;
      // ... existing population ...
      _coffeeNameController.text = r.coffeeName;
      _roasteryController.text = r.roastery;
      _originController.text = r.origin;
      _varietyController.text = r.variety;
      _processController.text = r.process;
      _roastDate = r.roastDate;
      _roastLevel = r.roastLevel;
      _methodController.text = r.brewingMethod;
      _ratioController.text = r.ratio;
      _grindSizeController.text = r.grindSize;
      _waterTempController.text = r.waterTemp.toString();
      _brewTimeMinController.text = (r.brewTimeSeconds ~/ 60).toString();
      _brewTimeSecController.text = (r.brewTimeSeconds % 60).toString();
      _isIced = r.isIced;
      _notesController.text = r.notes;
      _rating = r.rating;
      _grinderController.text = r.grinder;
      _roastLevelController.text = r.roastLevel;
      // Populate Steps
      _steps = List.from(r.steps);
    } else {
      // Default Steps
      _steps = [
        BrewStep(title: 'Bloom', time: '0:00 - 0:45', waterAmount: '50g'),
        BrewStep(title: 'Pour 1', time: '0:45 - 1:30', waterAmount: '150g'),
      ];
    }
  }

  // ... dispose ...

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _roastDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _roastDate) {
      setState(() {
        _roastDate = picked;
      });
    }
  }

  void _addStep() {
    setState(() {
      _steps.add(BrewStep(title: 'Pour ${_steps.length}', time: '', waterAmount: ''));
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _updateStep(int index, String? title, String? time, String? amount) {
    setState(() {
      final old = _steps[index];
      _steps[index] = BrewStep(
        title: title ?? old.title,
        time: time ?? old.time,
        waterAmount: amount ?? old.waterAmount,
      );
    });
  }

  // Check _submitForm for steps inclusion
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
         // ... vars ...
        final int mins = int.tryParse(_brewTimeMinController.text) ?? 0;
        final int secs = int.tryParse(_brewTimeSecController.text) ?? 0;
        final int totalSeconds = (mins * 60) + secs;

        final recipe = BrewRecipe(
          id: widget.originalRecipe?.id ?? '',
          coffeeName: _coffeeNameController.text,
          roastery: _roasteryController.text,
          origin: _originController.text,
          variety: _varietyController.text,
          process: _processController.text,
          roastDate: _roastDate,
          roastLevel: _roastLevel,
          brewingMethod: _methodController.text,
          ratio: _ratioController.text,
          grindSize: _grindSizeController.text,
          waterTemp: double.tryParse(_waterTempController.text) ?? 93,
          brewTimeSeconds: totalSeconds,
          isIced: _isIced,
          notes: _notesController.text,
          rating: _rating,
          timestamp: widget.originalRecipe?.timestamp ?? DateTime.now(),
          grinder: _grinderController.text,
          steps: _steps, // Add steps here
        );
        
        // ... save logic ...
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        if (widget.originalRecipe != null) {
          await dbService.updateRecipe(recipe);
        } else {
          await dbService.addRecipe(recipe);
        }

        if (mounted) {
           Navigator.pop(context);
        }
      } catch (e, stackTrace) {
        print('Error submitting recipe: $e');
        print(stackTrace);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error saving brew: $e'), backgroundColor: Colors.red),
           );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.originalRecipe != null ? 'Edit Brew' : 'Log New Brew', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
             // ... existing inputs ...
             _buildSectionHeader('Coffee Details'),
             _buildTextField(_coffeeNameController, 'Name', icon: Icons.coffee, required: true),
             const SizedBox(height: 8),
             _buildTextField(_roasteryController, 'Roastery', icon: Icons.store),
             const SizedBox(height: 8),
             Row(
               children: [
                 Expanded(child: _buildTextField(_originController, 'Origin', icon: Icons.public)),
                 const SizedBox(width: 8),
                 Expanded(child: _buildTextField(_varietyController, 'Variety', icon: Icons.grass)),
               ],
             ),
             const SizedBox(height: 8),
             _buildTextField(_processController, 'Process', icon: Icons.settings),
             const SizedBox(height: 16),
             _buildRoastDateAndLevel(),
             const SizedBox(height: 24),

             _buildSectionHeader('Brewing Parameters'),
             Row(
               children: [
                 Expanded(flex: 2, child: _buildTextField(_methodController, 'Method', hint: 'V60...', icon: Icons.filter_alt)),
                 const SizedBox(width: 8),
                 Expanded(flex: 1, child: _buildTextField(_ratioController, 'Ratio', hint: '1:15')),
               ],
             ),
             // ... other inputs ...
             const SizedBox(height: 8),
             Row(
               children: [
                 Expanded(child: _buildTextField(_grindSizeController, 'Grind Size', icon: Icons.grid_on)),
                 const SizedBox(width: 8),
                 Expanded(child: _buildTextField(_waterTempController, 'Temp (°C)', keyboardType: TextInputType.number)),
               ],
             ),
             const SizedBox(height: 8),
             Row(
               children: [
                 Expanded(child: _buildTextField(_brewTimeMinController, 'Min', keyboardType: TextInputType.number)),
                 const SizedBox(width: 8),
                 Expanded(child: _buildTextField(_brewTimeSecController, 'Sec', keyboardType: TextInputType.number)),
                 const SizedBox(width: 16),
                 Expanded(child: SwitchListTile(
                   title: const Text('Iced'), value: _isIced, onChanged: (val) => setState(() => _isIced = val), dense: true, contentPadding: EdgeInsets.zero
                 )),
               ],
             ),

             const SizedBox(height: 24),
             _buildTimelineSection(), // New Timeline Section

             const SizedBox(height: 24),
             _buildSectionHeader('Results'),
             _buildTextField(_notesController, 'Notes', maxLines: 4),
             const SizedBox(height: 16),
             const Center(child: Text('Overall Rating', style: TextStyle(fontWeight: FontWeight.bold))),
             const SizedBox(height: 8),
             Center(child: _buildFaceRatingBar()),
             const SizedBox(height: 32),
             
             ElevatedButton(
               onPressed: _isSubmitting ? null : _submitForm,
               child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text(widget.originalRecipe != null ? 'Update Brew Log' : 'Save Brew Log'),
             ),
             const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Timeline'),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
              onPressed: _addStep,
            ),
          ],
        ),
        if (_steps.isEmpty) 
          const Padding(padding: EdgeInsets.all(8.0), child: Text('No steps added.', style: TextStyle(color: Colors.grey))),
        
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Dot line visual
                  Column(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
                      if (index != _steps.length -1) Container(width: 2, height: 30, color: Colors.blueAccent.withOpacity(0.3)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Inputs
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextFormField(
                              initialValue: step.title,
                              decoration: const InputDecoration(labelText: 'Title', isDense: true, contentPadding: EdgeInsets.all(8)),
                              onChanged: (val) => _updateStep(index, val, null, null),
                            )),
                            const SizedBox(width: 8),
                             Expanded(child: TextFormField(
                              initialValue: step.waterAmount,
                              decoration: const InputDecoration(labelText: 'Amount (g)', isDense: true, contentPadding: EdgeInsets.all(8)),
                              onChanged: (val) => _updateStep(index, null, null, val),
                            )),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                            initialValue: step.time,
                            decoration: const InputDecoration(labelText: 'Time (e.g. 0:00 - 0:30)', isDense: true, contentPadding: EdgeInsets.all(8)),
                            onChanged: (val) => _updateStep(index, null, val, null),
                         ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeStep(index)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const Divider(thickness: 1.5, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? hint, IconData? icon, bool required = false, TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.brown) : null,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required ? (value) => value == null || value.isEmpty ? '$label is required' : null : null,
    );
  }

  Widget _buildRoastDateAndLevel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Roast Date',
                        prefixIcon: Icon(Icons.calendar_today, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _roastDate == null ? 'Select Date' : DateFormat.yMMMd().format(_roastDate!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Roast Level')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: ['Light', 'Medium', 'Medium-Dark', 'Dark'].map((level) {
                return ChoiceChip(
                  label: Text(level),
                  selected: _roastLevel == level,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _roastLevel = level;
                      });
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(color: _roastLevel == level ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceRatingBar() {
    return RatingBar.builder(
      initialRating: _rating,
      itemCount: 5,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red);
          case 1:
            return const Icon(Icons.sentiment_dissatisfied, color: Colors.redAccent);
          case 2:
            return const Icon(Icons.sentiment_neutral, color: Colors.amber);
          case 3:
            return const Icon(Icons.sentiment_satisfied, color: Colors.lightGreen);
          case 4:
            return const Icon(Icons.sentiment_very_satisfied, color: Colors.green);
          default:
             return const Icon(Icons.sentiment_neutral, color: Colors.amber);
        }
      },
      onRatingUpdate: (rating) {
        setState(() {
          _rating = rating;
        });
      },
    );
  }
}
