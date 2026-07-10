import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import '../providers/auth_provider.dart';

class PostEventFeedback extends StatefulWidget {
  final String eventId;
  const PostEventFeedback({super.key, required this.eventId});

  @override
  State<PostEventFeedback> createState() => _PostEventFeedbackState();
}

class _PostEventFeedbackState extends State<PostEventFeedback> {
  int _overallRating = 0;
  int _speakerRating = 0;
  int _venueRating = 0;
  int _contentRating = 0;
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final event = eventProvider.events.firstWhere((e) => e.id == widget.eventId, 
        orElse: () => EventModel(id: '', title: 'Unknown Event', organizerId: '', organizerName: '', date: DateTime.now(), time: '', location: '', category: '', spots: 0, availableSpots: 0, imageUrl: '', price: 0));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Section
              Text(
                event.title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Share your feedback to help us improve future events.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Main Content Canvas
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Overall Rating
                    Column(
                      children: [
                        Text(
                          'Overall Experience',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStarRating(
                          rating: _overallRating,
                          onRatingChanged: (val) => setState(() => _overallRating = val),
                          size: 40,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 24),

                    // Specific Categories
                    _buildCategoryRating(
                      label: 'Speaker Quality',
                      rating: _speakerRating,
                      onRatingChanged: (val) => setState(() => _speakerRating = val),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryRating(
                      label: 'Venue & Facilities',
                      rating: _venueRating,
                      onRatingChanged: (val) => setState(() => _venueRating = val),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryRating(
                      label: 'Content Relevance',
                      rating: _contentRating,
                      onRatingChanged: (val) => setState(() => _contentRating = val),
                    ),
                    const SizedBox(height: 24),

                    // Additional Comments
                    Text(
                      'Additional Comments',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What could we improve for next time?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    ElevatedButton(
                      onPressed: () async {
                          if (_overallRating == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select an overall rating')),
                            );
                            return;
                          }
                          
                          setState(() => _isSubmitting = true);
                          
                          try {
                            final userId = context.read<AuthProvider>().firebaseUser?.uid;
                            if (userId == null) throw Exception('Not logged in');
                            
                            await context.read<EventProvider>().submitFeedback(
                              eventId: widget.eventId,
                              userId: userId,
                              overallRating: _overallRating.toDouble(),
                              speakerRating: _speakerRating.toDouble(),
                              venueRating: _venueRating.toDouble(),
                              contentRating: _contentRating.toDouble(),
                              comments: _commentsController.text,
                            );
                            
                            if (context.mounted) {
                               context.go('/feedback-submitted');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : Text(
                              'Submit Feedback',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Skip for now',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRating({
    required String label,
    required int rating,
    required Function(int) onRatingChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _buildStarRating(
            rating: rating,
            onRatingChanged: onRatingChanged,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating({
    required int rating,
    required Function(int) onRatingChanged,
    required double size,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Icon(
              rating > index ? Icons.star : Icons.star_border,
              size: size,
              color: rating > index ? Theme.of(context).colorScheme.tertiaryContainer : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );
      }),
    );
  }
}
