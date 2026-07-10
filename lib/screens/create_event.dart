import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_model.dart';
import '../utils/image_utils.dart';
import '../widgets/dynamic_image.dart';
import 'dart:math';

class CreateEvent extends StatefulWidget {
  final String? eventId;
  const CreateEvent({super.key, this.eventId});

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  bool _isFree = true;
  bool _isPublic = true;
  bool _autoCloseRegistration = false;
  DateTime? _autoCloseRegistrationTime;
  bool _autoEndCheckIn = false;
  DateTime? _autoEndCheckInTime;
  bool _autoEndEvent = false;
  DateTime? _autoEndEventTime;
  String _targetAudience = 'All Students';
  final List<String> _audiences = [
    'All Students',
    'Faculty Only',
    'Club Members',
    'Staff',
    'Public',
    'Other',
  ];
  String _selectedCategory = 'Workshop';
  bool _isUploading = false;
  String? _posterBase64;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _generateNumericId() {
    final random = Random();
    String result = '';
    for (int i = 0; i < 24; i++) {
      result += random.nextInt(10).toString();
    }
    return result;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  final List<String> _categories = [
    'Workshop',
    'Seminar',
    'Social',
    'Sports',
    'Tech',
    'Arts',
    'Music',
    'Networking',
    'Career',
    'Other',
  ];

  bool _isEditing = false;
  EventModel? _editingEvent;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEventData();
      });
    }
  }

  void _loadEventData() {
    final eventProvider = context.read<EventProvider>();
    final event = eventProvider.getEventById(widget.eventId!);
    if (event != null) {
      setState(() {
        _editingEvent = event;
        _titleController.text = event.title;
        _venueController.text = event.location;
        _capacityController.text = event.spots.toString();
        _descController.text = event.description;
        _timeController.text = event.time;
        _dateController.text = '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}';
        
        _isPublic = event.isPublic;
        _targetAudience = event.targetAudience;
        _selectedCategory = event.category;
        
        _autoCloseRegistration = event.autoCloseRegistration;
        _autoCloseRegistrationTime = event.autoCloseRegistrationTime;
        _autoEndCheckIn = event.autoEndCheckIn;
        _autoEndCheckInTime = event.autoEndCheckInTime;
        _autoEndEvent = event.autoEndEvent;
        _autoEndEventTime = event.autoEndEventTime;
        
        if (event.price == 0) {
          _isFree = true;
          _priceController.text = '';
        } else {
          _isFree = false;
          _priceController.text = event.price.toString();
        }
      });
    }
  }

  Future<void> _showBackDialog() async {
    final bool hasUnsavedChanges = _titleController.text.isNotEmpty || _descController.text.isNotEmpty || _venueController.text.isNotEmpty;
    if (!hasUnsavedChanges) {
      if (mounted) context.pop();
      return;
    }

    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Unsaved Changes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          content: Text(
            'Do you want to save this event as a draft?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Discard',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _saveAsDraft();
              },
              child: const Text('Save Draft'),
            ),
          ],
        );
      },
    );

    if (shouldPop == true) {
      if (mounted) context.pop();
    }
  }

  void _saveAsDraft() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Save as Draft',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          content: Text(
            'Are you sure you want to save this event as a draft?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performSave(isDraft: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _performSave({required bool isDraft}) {
    if (_titleController.text.trim().isEmpty ||
        (!isDraft && (
        _dateController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty ||
        _venueController.text.trim().isEmpty ||
        _capacityController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        (!_isFree && _priceController.text.trim().isEmpty)))) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDraft ? 'Please provide at least a title to save a draft.' : 'Please fill all required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int? capacity = int.tryParse(_capacityController.text.trim());
    if (capacity != null && capacity < 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Max capacity cannot be a negative number'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isFree) {
      final int? priceValue = int.tryParse(_priceController.text.trim());
      if (priceValue == null || priceValue < 0) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid integer price amount'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final userId =
        context.read<AuthProvider>().firebaseUser?.uid ??
        'unknown_org';
    DateTime eventDate = DateTime.now().add(
      const Duration(days: 30),
    );
    try {
      if (_dateController.text.isNotEmpty) {
        final parts = _dateController.text.split('/');
        if (parts.length == 3) {
          eventDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      
      final today = DateTime.now();
      if (!isDraft && !_isEditing && eventDate.isBefore(DateTime(today.year, today.month, today.day))) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event date cannot be in the past'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } catch (e) {
      // ignore
    }

    final newEvent = EventModel(
      id: _isEditing ? _editingEvent!.id : _generateNumericId(),
      title: _titleController.text.trim(),
      organizerId: userId,
      organizerName: context.read<AuthProvider>().userProfile?.name ?? 'Organization Name',
      date: eventDate,
      time: _timeController.text.trim(),
      location: _venueController.text.trim(),
      category: _selectedCategory,
      spots: int.tryParse(_capacityController.text.trim()) ?? 100,
      availableSpots: _isEditing ? _editingEvent!.availableSpots : (int.tryParse(_capacityController.text.trim()) ?? 100),
      imageUrl: _posterBase64 != null 
          ? _posterBase64! 
          : (_isEditing && _editingEvent!.hasValidImage ? _editingEvent!.imageUrl : ImageUtils.getCategoryImage(_selectedCategory)),
      price: _isFree ? 0 : (int.tryParse(_priceController.text.trim()) ?? 0),
      description: _descController.text.trim(),
      isPublic: _isPublic,
      isDraft: isDraft,
      targetAudience: _targetAudience,
      autoCloseRegistration: _autoCloseRegistration,
      autoCloseRegistrationTime: _autoCloseRegistration ? _autoCloseRegistrationTime : null,
      autoEndCheckIn: _autoEndCheckIn,
      autoEndCheckInTime: _autoEndCheckIn ? _autoEndCheckInTime : null,
      autoEndEvent: _autoEndEvent,
      autoEndEventTime: _autoEndEvent ? _autoEndEventTime : null,
      isCancelled: _isEditing ? _editingEvent!.isCancelled : false,
      isRegistrationClosed: _isEditing ? _editingEvent!.isRegistrationClosed : false,
      isCheckInClosed: _isEditing ? _editingEvent!.isCheckInClosed : false,
      isEventEnded: _isEditing ? _editingEvent!.isEventEnded : false,
      registrationTimestamps: _isEditing ? _editingEvent!.registrationTimestamps : [],
      registeredUserIds: _isEditing ? _editingEvent!.registeredUserIds : [],
      attendedUserIds: _isEditing ? _editingEvent!.attendedUserIds : [],
      bookmarkedUserIds: _isEditing ? _editingEvent!.bookmarkedUserIds : [],
      pendingUserIds: _isEditing ? _editingEvent!.pendingUserIds : [],
      averageRating: _isEditing ? _editingEvent!.averageRating : 0.0,
      reviewCount: _isEditing ? _editingEvent!.reviewCount : 0,
    );
    
    if (_isEditing) {
      context.read<EventProvider>().updateEvent(
        widget.eventId!, 
        newEvent,
        actionTitle: 'Event Details Updated',
        actionMessage: 'You successfully updated the details for "${newEvent.title}".',
      );
    } else {
      context.read<EventProvider>().addEvent(newEvent);
    }

    context.go('/organizer/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (didPop) return;
        _showBackDialog();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => _showBackDialog(),
          ),
          actions: [
            if (!_isEditing)
              TextButton(
                onPressed: _saveAsDraft,
                child: Text(
                  'Draft',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (!_isEditing) const SizedBox(width: 8),
          ],
          title: Text(
            _isEditing ? 'Edit Event' : 'Create New Event',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              height: 1.0,
            ),
          ),
        ),
        body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        setState(() => _isUploading = true);
                        final primaryColor = Theme.of(context).colorScheme.primary;
                        try {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            final croppedFile = await ImageCropper().cropImage(
                              sourcePath: pickedFile.path,
                              aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
                              uiSettings: [
                                AndroidUiSettings(
                                    toolbarTitle: 'Crop Event Poster',
                                    toolbarColor: primaryColor,
                                    toolbarWidgetColor: Colors.white,
                                    initAspectRatio: CropAspectRatioPreset.ratio16x9,
                                    lockAspectRatio: true),
                                IOSUiSettings(
                                  title: 'Crop Event Poster',
                                  aspectRatioLockEnabled: true,
                                  resetAspectRatioEnabled: false,
                                ),
                              ],
                              maxWidth: 800,
                              maxHeight: 450,
                              compressQuality: 40,
                            );

                            if (croppedFile != null) {
                              final bytes = await File(croppedFile.path).readAsBytes();
                              final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                              setState(() {
                                _posterBase64 = base64Str;
                              });
                            }
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isUploading = false);
                          }
                        }
                      },
                      child: Container(
                        height: 160,
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
                        child: Stack(
                          children: [
                            if (_posterBase64 != null || (_isEditing && _editingEvent!.hasValidImage))
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: DynamicImage(
                                    imageUrl: _posterBase64 ?? _editingEvent!.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            if (_posterBase64 != null || (_isEditing && _editingEvent!.hasValidImage))
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isUploading)
                                    const CircularProgressIndicator()
                                  else if (_posterBase64 != null || (_isEditing && _editingEvent!.hasValidImage))
                                    Icon(
                                      Icons.edit,
                                      size: 48,
                                      color: Colors.white,
                                    )
                                  else
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isUploading
                                        ? 'Uploading...'
                                        : (_posterBase64 != null || (_isEditing && _editingEvent!.hasValidImage))
                                        ? 'Change Event Poster'
                                        : 'Upload Event Poster',
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(
                                          color: (_posterBase64 != null || (_isEditing && _editingEvent!.hasValidImage))
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  if (_posterBase64 == null && (!_isEditing || !_editingEvent!.hasValidImage) && !_isUploading)
                                    Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '1080px x 1920px',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                    const SizedBox(height: 24),

                    _buildLabel('Event Title'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      hint: 'e.g. Tech Innovation Summit',
                      controller: _titleController,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Date'),
                              const SizedBox(height: 4),
                              _buildTextField(
                                hint: 'Select Date',
                                prefixIcon: Icons.calendar_today,
                                controller: _dateController,
                                readOnly: true,
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null && context.mounted) {
                                    setState(() {
                                      _dateController.text =
                                          "${picked.day}/${picked.month}/${picked.year}";
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Time'),
                              const SizedBox(height: 4),
                              _buildTextField(
                                hint: 'Select Time',
                                prefixIcon: Icons.schedule,
                                controller: _timeController,
                                readOnly: true,
                                onTap: () async {
                                  TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null && context.mounted) {
                                    setState(() {
                                      _timeController.text = picked.format(
                                        context,
                                      );
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Venue'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      hint: 'Building, Room, or Online Link',
                      prefixIcon: Icons.location_on,
                      controller: _venueController,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Max Capacity'),
                              const SizedBox(height: 4),
                              _buildTextField(
                                hint: 'e.g. 150 (0 for unlimited)',
                                prefixIcon: Icons.groups,
                                keyboardType: TextInputType.number,
                                controller: _capacityController,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('Category'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
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
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedCategory = newValue;
                                        });
                                      }
                                    },
                                    items: _categories
                                        .map<DropdownMenuItem<String>>((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Event Mode'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              title: 'PUBLIC',
                              isSelected: _isPublic,
                              onTap: () {
                                setState(() {
                                  _isPublic = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildToggleButton(
                              title: 'PRIVATE',
                              isSelected: !_isPublic,
                              onTap: () {
                                setState(() {
                                  _isPublic = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isPublic
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 16),
                                _buildLabel('Target Audience'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
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
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _targetAudience,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _targetAudience = newValue;
                                          });
                                        }
                                      },
                                      items: _audiences
                                          .map<DropdownMenuItem<String>>((
                                            String value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Ticketing Type'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              title: 'FREE',
                              isSelected: _isFree,
                              onTap: () {
                                setState(() {
                                  _isFree = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildToggleButton(
                              title: 'PAID',
                              isSelected: !_isFree,
                              onTap: () {
                                setState(() {
                                  _isFree = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isFree
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 16),
                                _buildLabel('Ticket Price (RM)'),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  hint: '0.00',
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Automation Options'),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      'Auto-close Registration',
                      'Closes sign-ups at a specific time',
                      _autoCloseRegistration,
                      (val) => setState(() => _autoCloseRegistration = val),
                    ),
                    if (_autoCloseRegistration)
                      _buildDateTimePicker(
                        selectedDate: _autoCloseRegistrationTime,
                        onChanged: (val) => setState(() => _autoCloseRegistrationTime = val),
                      ),
                    _buildSwitchTile(
                      'Auto-end Check-in',
                      'Closes check-in at a specific time',
                      _autoEndCheckIn,
                      (val) => setState(() => _autoEndCheckIn = val),
                    ),
                    if (_autoEndCheckIn)
                      _buildDateTimePicker(
                        selectedDate: _autoEndCheckInTime,
                        onChanged: (val) => setState(() => _autoEndCheckInTime = val),
                      ),
                    _buildSwitchTile(
                      'Auto-end Event',
                      'Marks event as completed at a specific time',
                      _autoEndEvent,
                      (val) => setState(() => _autoEndEvent = val),
                    ),
                    if (_autoEndEvent)
                      _buildDateTimePicker(
                        selectedDate: _autoEndEventTime,
                        onChanged: (val) => setState(() => _autoEndEventTime = val),
                      ),
                    const SizedBox(height: 24),

                    _buildLabel('Description'),
                    const SizedBox(height: 4),
                    _buildTextField(
                      hint:
                          'Provide details about the event, agenda, speakers, etc.',
                      maxLines: 4,
                      controller: _descController,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: const EdgeInsets.all(16),
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
              child: ElevatedButton(
                onPressed: () {
                  // Validation
                  _performSave(isDraft: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  _isEditing ? 'SAVE CHANGES' : 'PUBLISH EVENT',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildLabel(String text, {bool isRequired = true}) {
    return RichText(
      text: TextSpan(
        text: text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.transparent)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required DateTime? selectedDate,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null && mounted) {
          final TimeOfDay? time = await showTimePicker(
            context: context,
            initialTime: selectedDate != null ? TimeOfDay.fromDateTime(selectedDate) : TimeOfDay.now(),
          );
          if (time != null) {
            onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              selectedDate != null
                  ? '// '
                  : 'Select Date & Time',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            if (selectedDate != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: SwitchListTile(
          title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          value: value,
          onChanged: onChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }
}
