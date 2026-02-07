import 'dart:async';
import 'package:flutter/material.dart';
import '../models/brew_recipe.dart';

class LiveBrewScreen extends StatefulWidget {
  final BrewRecipe recipe;

  const LiveBrewScreen({super.key, required this.recipe});

  @override
  State<LiveBrewScreen> createState() => _LiveBrewScreenState();
}

class _LiveBrewScreenState extends State<LiveBrewScreen> {
  late Timer _timer;
  int _elapsedMilliseconds = 0; // Changed to ms for smoothness
  int _totalElapsedMilliseconds = 0; // Continues even after finish
  bool _isRunning = false;
  bool _isRecipeFinished = false;
  List<_ParsedStep> _parsedSteps = [];

  @override
  void initState() {
    super.initState();
    _parseSteps();
  }

  void _parseSteps() {
    _parsedSteps = widget.recipe.steps.map((step) {
      return _ParsedStep(
        step: step,
        startTimeSeconds: _parseTime(step.time),
      );
    }).toList();
    
    // Sort by time just in case
    _parsedSteps.sort((a, b) => a.startTimeSeconds.compareTo(b.startTimeSeconds));
  }

  int _parseTime(String timeStr) {
    String cleanTime = timeStr.trim();
    if (cleanTime.isEmpty) return 0;

    // Handle ranges like "0:00 - 0:05" by taking the start time
    if (cleanTime.contains('-')) {
      cleanTime = cleanTime.split('-')[0].trim();
    }

    try {
      final parts = cleanTime.split(':');
      if (parts.length == 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
      return int.parse(cleanTime); // Assume seconds if no colon
    } catch (e) {
      print('Error parsing time: $timeStr');
      return 0; // Default to 0 on error
    }
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _totalElapsedMilliseconds += 100;
          if (!_isRecipeFinished) {
             _elapsedMilliseconds += 100;
          }
        });
      });
    } else {
      _timer.cancel();
    }
  }

  void _stopTimer() {
    _timer.cancel();
    setState(() {
      _isRunning = false;
      _elapsedMilliseconds = 0;
      _totalElapsedMilliseconds = 0;
      _isRecipeFinished = false;
    });
  }

  @override
  void dispose() {
    if (_isRunning) _timer.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _getWaterTargetDisplay(_ParsedStep? current) {
    if (current == null) return '';
    String currentAmount = current.step.waterAmount; // e.g. "150ml"
    
    // Attempt to find total water from last step
    String totalAmount = '';
    if (_parsedSteps.isNotEmpty) {
      totalAmount = _parsedSteps.last.step.waterAmount;
    }
    
    if (totalAmount.isNotEmpty && currentAmount != totalAmount) {
      return '$currentAmount / $totalAmount';
    }
    return currentAmount;
  }

  _ParsedStep? _getCurrentStep() {
    // Find the latest step that has started
    _ParsedStep? current;
    int elapsedSeconds = _elapsedMilliseconds ~/ 1000;
    for (var step in _parsedSteps) {
      if (elapsedSeconds >= step.startTimeSeconds) {
        current = step;
      } else {
        break; // Future step
      }
    }
    return current;
  }

  _ParsedStep? _getNextStep() {
    int elapsedSeconds = _elapsedMilliseconds ~/ 1000;
    for (var step in _parsedSteps) {
      if (elapsedSeconds < step.startTimeSeconds) {
        return step;
      }
    }
    return null;
  }

  // Helper to determine if we are in a "Wait" phase of the current step
  bool _isWaitingPhase(_ParsedStep? current, _ParsedStep? next) {
    if (current == null) return false;
    
    // Calculate duration of current step
    final start = current.startTimeSeconds;
    final end = next?.startTimeSeconds ?? (_parsedSteps.last.startTimeSeconds + 45); // fallback end
    final duration = end - start;
    
    // If step is long (> 20s), assume first 15s is Action, rest is Wait
    if (duration > 20) {
      final elapsedInStep = (_elapsedMilliseconds ~/ 1000) - start;
      return elapsedInStep >= 15;
    }
    return false;
  }

  String _getCurrentActionTitle(_ParsedStep? current, bool isWaiting) {
    if (current == null) return 'Get Ready...';
    if (isWaiting) return 'WAIT';
    return current.step.title;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine active step index directly
    int activeIndex = -1;
    int elapsedSeconds = _elapsedMilliseconds ~/ 1000;
    
    for (int i = 0; i < _parsedSteps.length; i++) {
      if (elapsedSeconds >= _parsedSteps[i].startTimeSeconds) {
        activeIndex = i;
      } else {
        break; 
      }
    }

    final currentStep = activeIndex != -1 ? _parsedSteps[activeIndex] : null;
    final nextStep = (activeIndex + 1 < _parsedSteps.length) ? _parsedSteps[activeIndex + 1] : null;

    // Per-step progress
    double progress = 0.0;
    if (currentStep != null) {
      final start = currentStep.startTimeSeconds;
      final end = nextStep?.startTimeSeconds ?? (start + 30); 
      final duration = end - start;
      if (duration > 0) {
        progress = ((_elapsedMilliseconds - (start * 1000)) / (duration * 1000)).clamp(0.0, 1.0);
      } else {
        progress = 1.0;
      }
    } else if (_parsedSteps.isNotEmpty && elapsedSeconds < _parsedSteps.first.startTimeSeconds) {
       final end = _parsedSteps.first.startTimeSeconds;
       if (end > 0) progress = (_elapsedMilliseconds / (end * 1000)).clamp(0.0, 1.0);
    }

    // Check if finished
    final recipeTotalTime = widget.recipe.brewTimeSeconds > 0 ? widget.recipe.brewTimeSeconds : 0;
    final lastStepEnd = _parsedSteps.isNotEmpty ? _parsedSteps.last.startTimeSeconds + 45 : 300;
    final totalBrewTime = recipeTotalTime > 0 ? recipeTotalTime : lastStepEnd;
    
    // Auto-stop logic
    if (elapsedSeconds >= totalBrewTime && !_isRecipeFinished) {
       _isRecipeFinished = true;
       progress = 1.0;
       // We stop incrementing _elapsedMilliseconds in the periodic callback checks
    } else if (_isRecipeFinished) {
        progress = 1.0;
    }

    // Determine UI State
    final isWaiting = _isWaitingPhase(currentStep, nextStep);
    final actionTitle = _getCurrentActionTitle(currentStep, isWaiting);
    
    // Calculate remaining wait time if in wait phase
    String? waitTimeLeft;
    if (isWaiting && currentStep != null) {
      final end = nextStep?.startTimeSeconds ?? totalBrewTime;
      final remaining = end - elapsedSeconds;
      if (remaining > 0) waitTimeLeft = '${remaining}s';
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Live Brew', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
               _stopTimer();
               Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Text(
            '${widget.recipe.brewingMethod} • ${widget.recipe.ratio} • ${widget.recipe.coffeeName}',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          
          const SizedBox(height: 40),

          // Big Timer Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.2), 
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange), 
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    _formatTime(_elapsedMilliseconds ~/ 1000),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (currentStep != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(
                         _getWaterTargetDisplay(currentStep),
                         style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 16, fontWeight: FontWeight.w500),
                       ),
                     ),
                  // Secondary Continuous Timer
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Total: ${_formatTime(_totalElapsedMilliseconds ~/ 1000)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 50),

          // Current Instruction Card
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
                  // Active Step
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStep != null ? 'Current Action' : 'Get Ready',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                          if (_isRecipeFinished)
                             Text('Enjoy your brew!', style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold))
                          else
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   actionTitle,
                                   style: TextStyle(
                                     color: isWaiting ? Colors.orange : theme.colorScheme.primary, 
                                     fontSize: isWaiting ? 48 : 24, 
                                     fontWeight: FontWeight.bold
                                   ),
                                 ),
                                 if (waitTimeLeft != null)
                                    Text(
                                      '$waitTimeLeft left',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 18),
                                    ),
                               ],
                             ),
                        if (!_isRecipeFinished && !isWaiting && currentStep != null && currentStep.step.waterAmount.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Target: ${currentStep.step.waterAmount}',
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Next Step Preview
                  if (nextStep != null)
                    Row(
                      children: [
                        const Text('Next: ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text('${nextStep.step.title} at ${_formatTime(nextStep.startTimeSeconds)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),

                  const Spacer(),

                  // Controls
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isRunning ? () {
                               _toggleTimer();
                            } : _toggleTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRunning ? Colors.white : theme.colorScheme.primary,
                              foregroundColor: _isRunning ? theme.colorScheme.primary : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              side: _isRunning ? BorderSide(color: theme.colorScheme.primary) : null,
                            ),
                            child: Text(
                              _isRunning ? 'Pause' : 'Start',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
