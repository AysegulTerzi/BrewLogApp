import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/brew_recipe.dart';

class LiveBrewScreen extends StatefulWidget {
  final BrewRecipe recipe;

  const LiveBrewScreen({super.key, required this.recipe});

  @override
  State<LiveBrewScreen> createState() => _LiveBrewScreenState();
}

class _LiveBrewScreenState extends State<LiveBrewScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isRecipeFinished = false;
  List<_ParsedStep> _parsedSteps = [];

  // For total elapsed time (running brew duration)
  Duration _totalElapsed = Duration.zero; // This tracks actual time user spent brewing
  
  @override
  void initState() {
    super.initState();
    _parseSteps();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    // Ticker callback runs every frame. We need to trigger a rebuild.
    setState(() {});
  }
  
  // Re-thinking: Use Stopwatch for accuracy + Ticker for UI updates.
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
  
  void _parseSteps() {
    _parsedSteps = widget.recipe.steps.map((step) {
      return _ParsedStep(
        step: step,
        startTimeSeconds: _parseTime(step.time),
      );
    }).toList();
    _parsedSteps.sort((a, b) => a.startTimeSeconds.compareTo(b.startTimeSeconds));
  }

  int _parseTime(String timeStr) {
    String cleanTime = timeStr.trim();
    if (cleanTime.isEmpty) return 0;
    if (cleanTime.contains('-')) cleanTime = cleanTime.split('-')[0].trim();
    try {
      final parts = cleanTime.split(':');
      if (parts.length == 2) return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      return int.parse(cleanTime);
    } catch (e) {
      return 0;
    }
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _stopwatch.start();
        _ticker.start();
      } else {
        _stopwatch.stop();
        _ticker.stop();
      }
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _stopwatch.reset();
    _ticker.stop();
    setState(() {
      _isRunning = false;
      _isRecipeFinished = false;
      _elapsed = Duration.zero;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  _ParsedStep? _getCurrentStep() {
    int elapsedSeconds = _stopwatch.elapsed.inSeconds;
    _ParsedStep? current;
    for (var step in _parsedSteps) {
      if (elapsedSeconds >= step.startTimeSeconds) current = step;
      else break;
    }
    return current;
  }

  // Helper to determine if we are in a "Wait" phase of the current step
  bool _isWaitingPhase(_ParsedStep? current, _ParsedStep? next, int totalBrewTime) {
    if (current == null) return false;
    
    final start = current.startTimeSeconds;
    final end = next?.startTimeSeconds ?? totalBrewTime;
    final duration = end - start;
    
    // Dynamic Action Duration:
    // Default 12s for long steps (enough for pouring)
    // For shorter steps, use half the duration
    int actionDuration = 12;
    if (duration < 24) {
      actionDuration = duration ~/ 2;
    }
    
    // If step is really short (< 6s), don't show wait at all
    if (duration < 6) return false;

    final elapsedInStep = _stopwatch.elapsed.inSeconds - start;
    return elapsedInStep >= actionDuration;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate progress
    final totalBrewTimeSeconds = widget.recipe.brewTimeSeconds > 0 
        ? widget.recipe.brewTimeSeconds 
        : (_parsedSteps.isNotEmpty ? _parsedSteps.last.startTimeSeconds + 30 : 300);
        
    final currentElapsed = _stopwatch.elapsed;
    
    if (currentElapsed.inSeconds >= totalBrewTimeSeconds && !_isRecipeFinished) {
       // Finish!
       // We should stop the timer here automatically
       // But we can't call setState directly during build if we triggered it here.
       // Schedule a microtask to stop.
       Future.microtask(() {
         if (mounted && _isRunning) {
            _stopwatch.stop();
            _ticker.stop();
            setState(() {
              _isRunning = false;
              _isRecipeFinished = true;
            });
         }
       });
    }

    final elapsedSeconds = currentElapsed.inSeconds;
    
    // Find active step index
    int activeIndex = -1;
    for (int i = 0; i < _parsedSteps.length; i++) {
      if (elapsedSeconds >= _parsedSteps[i].startTimeSeconds) activeIndex = i;
      else break;
    }

    final currentStep = activeIndex != -1 ? _parsedSteps[activeIndex] : null;
    final nextStep = (activeIndex + 1 < _parsedSteps.length) ? _parsedSteps[activeIndex + 1] : null;

    // Smooth Progress Bar
    // Calculate progress based on current step duration
    double stepProgress = 0.0;
    if (currentStep != null) {
      final start = currentStep.startTimeSeconds;
      final end = nextStep?.startTimeSeconds ?? totalBrewTimeSeconds;
      final duration = end - start;
      if (duration > 0) {
        final elapsedInStep = _stopwatch.elapsedMilliseconds - (start * 1000);
        stepProgress = (elapsedInStep / (duration * 1000)).clamp(0.0, 1.0);
      } else {
        stepProgress = 1.0;
      }
    } else if (_parsedSteps.isNotEmpty && elapsedSeconds < _parsedSteps.first.startTimeSeconds) {
      // Pre-brew waiting
       final end = _parsedSteps.first.startTimeSeconds;
       if (end > 0) {
         stepProgress = (currentElapsed.inMilliseconds / (end * 1000)).clamp(0.0, 1.0);
       }
    }
    
    if (_isRecipeFinished) stepProgress = 1.0;

    // WAIT Logic
    bool isWaiting = false;
    String? waitTimeLeft;
    if (currentStep != null && !_isRecipeFinished) {
      isWaiting = _isWaitingPhase(currentStep, nextStep, totalBrewTimeSeconds);
      if (isWaiting) {
        final start = currentStep.startTimeSeconds;
        final end = nextStep?.startTimeSeconds ?? totalBrewTimeSeconds;
        final remaining = end - elapsedSeconds;
        if (remaining > 0) waitTimeLeft = '${remaining}s';
      }
    }

    // UI structure similar to before but utilizing _stopwatch data
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Live Brew', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
             onPressed: () { _stopTimer(); Navigator.pop(context); },
             child: const Text('Exit', style: TextStyle(color: Colors.white))
          )
        ],
      ),
      body: Column(
        children: [
           // Info Header
           Text(
            '${widget.recipe.brewingMethod} • ${widget.recipe.ratio} • ${widget.recipe.coffeeName}',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 40),
          
          // Timer Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280, height: 280,
                child: CircularProgressIndicator(
                  value: stepProgress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.2), 
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    _formatTime(elapsedSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (currentStep != null && !_isRecipeFinished)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(
                         currentStep.step.waterAmount, // Simplification: just show target
                         style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 16, fontWeight: FontWeight.w500),
                       ),
                     ),
                  if (_isRecipeFinished)
                     const Padding(
                       padding: EdgeInsets.only(top: 8.0),
                       child: Text(
                         'DONE',
                         style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold),
                       ),
                     ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 50),
          
          // Bottom Card
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F4F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: Column(
                children: [
                   // Active Step Card
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(24),
                       boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                       ],
                     ),
                     child: _isRecipeFinished 
                       ? Column(
                           children: [
                             Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 48),
                             const SizedBox(height: 8),
                             Text('Enjoy your coffee!', style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                           ],
                         )
                       : Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(currentStep != null ? 'Current Action' : 'Get Ready', style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 8),
                             Text(
                               isWaiting ? 'WAIT' : (currentStep?.step.title ?? 'Prepare'),
                               style: TextStyle(
                                 color: isWaiting ? Colors.orange : theme.colorScheme.primary,
                                 fontSize: isWaiting ? 48 : 24,
                                 fontWeight: FontWeight.bold
                               ),
                             ),
                             if (waitTimeLeft != null)
                               Text('$waitTimeLeft left', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                           ],
                         ),
                   ),
                   
                   const SizedBox(height: 20),
                   
                   // Next Step
                   if (nextStep != null && !_isRecipeFinished)
                      Row(
                        children: [
                          const Text('Next: ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text('${nextStep.step.title} at ${_formatTime(nextStep.startTimeSeconds)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      
                   const Spacer(),
                   
                   // Button
                   SizedBox(
                     width: double.infinity,
                     height: 56,
                     child: ElevatedButton(
                       onPressed: _isRecipeFinished 
                         ? () => Navigator.pop(context)
                         : (_isRunning ? _toggleTimer : _toggleTimer),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: _isRecipeFinished ? theme.colorScheme.primary : (_isRunning ? Colors.white : theme.colorScheme.primary),
                         foregroundColor: _isRecipeFinished ? Colors.white : (_isRunning ? theme.colorScheme.primary : Colors.white),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         side: _isRunning && !_isRecipeFinished ? BorderSide(color: theme.colorScheme.primary) : null,
                       ),
                       child: Text(
                         _isRecipeFinished ? 'Finish' : (_isRunning ? 'Pause' : 'Start'),
                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                       ),
                     ),
                   )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedStep {
  final BrewStep step;
  final int startTimeSeconds;
  _ParsedStep({required this.step, required this.startTimeSeconds});
}
