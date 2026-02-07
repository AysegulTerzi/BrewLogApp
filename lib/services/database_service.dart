import 'package:firedart/firedart.dart';
import '../models/brew_recipe.dart';

class DatabaseService {
  final CollectionReference _recipesCollection = Firestore.instance.collection('recipes');
  List<BrewRecipe>? _cachedRecipes;

  // Add a new recipe
  // Add a new recipe
  Future<void> addRecipe(BrewRecipe recipe) async {
    await _recipesCollection.add(recipe.toMap());
    _cachedRecipes = null; // Invalidate cache
  }

  // Get a stream of recipes (for real-time updates)
  // Get a stream of recipes (for real-time updates)
  Stream<List<BrewRecipe>> getRecipesStream() {
    return _recipesCollection.stream.map((list) {
      final recipes = list.map((doc) => BrewRecipe.fromMap(doc.id, doc.map)).toList();
      recipes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return recipes;
    }).asBroadcastStream();
  }

  // Get a stream of a SINGLE recipe
  Stream<BrewRecipe> getRecipeStream(String id) {
    return _recipesCollection.document(id).stream.map((doc) {
      if (doc == null) throw Exception('Recipe not found');
      return BrewRecipe.fromMap(doc.id, doc.map);
    }).asBroadcastStream();
  }

  // Get recipes once (Future)
  // Get recipes once (Future) with Caching
  Future<List<BrewRecipe>> getRecipes() async {
    if (_cachedRecipes != null) return _cachedRecipes!;

    final list = await _recipesCollection.get();
    final recipes = list.map((doc) => BrewRecipe.fromMap(doc.id, doc.map)).toList();
    recipes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    _cachedRecipes = recipes;
    return recipes;
  }

  // Update an existing recipe
  Future<void> updateRecipe(BrewRecipe recipe) async {
    // Use set() instead of update() to ensure it works even if doc is missing (and simpler for full updates)
    await _recipesCollection.document(recipe.id).set(recipe.toMap());
    _cachedRecipes = null; // Invalidate cache
  }

  // Delete a recipe
  Future<void> deleteRecipe(String id) async {
    await _recipesCollection.document(id).delete();
    _cachedRecipes = null; // Invalidate cache
  }

  // --- Profile Settings ---
  final DocumentReference _profileDoc = Firestore.instance.collection('settings').document('profile');

  Future<void> saveProfileName(String name) async {
    // Firedart doesn't support SetOptions.merge in the same way.
    // We'll try update, and fallback to set if it doesn't exist.
    try {
      await _profileDoc.update({'name': name});
    } catch (e) {
      await _profileDoc.set({'name': name});
    }
  }

  Stream<String> getProfileNameStream() {
    return _profileDoc.stream.map((doc) {
       if (doc == null) return 'Barista';
       return doc.map['name']?.toString() ?? 'Barista';
    }).asBroadcastStream();
  }
}
