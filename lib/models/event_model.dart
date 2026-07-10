import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String organizerId;
  final String organizerName;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final int spots;
  final int availableSpots;
  final String imageUrl;
  final int price;
  final bool _isTrending;
  final bool _isLimitedSpots;
  final String description;
  final bool isPublic;
  final bool isDraft;
  final String targetAudience;
  final List<DateTime> registrationTimestamps;
  final bool autoCloseRegistration;
  final DateTime? autoCloseRegistrationTime;
  final bool autoEndCheckIn;
  final DateTime? autoEndCheckInTime;
  final bool autoEndEvent;
  final DateTime? autoEndEventTime;
  final bool isCancelled;
  final bool isRegistrationClosed;
  final bool isCheckInClosed;
  final bool isEventEnded;
  final DateTime createdAt;

  bool get hasValidImage => imageUrl.isNotEmpty && !imageUrl.contains('ui-avatars.com');
  String get displayPrice => price == 0 ? 'Free' : 'RM $price';


  bool get isTrending {
    if (_isTrending) return true;
    final now = DateTime.now();
    final recentRegistrations = registrationTimestamps.where((t) => now.difference(t).inHours <= 24).length;
    return recentRegistrations >= 5;
  }

  bool get isLimitedSpots {
    // Limited spots if explicitly set, or if available spots are <= 20% of max capacity
    return _isLimitedSpots || (spots > 0 && availableSpots <= (spots * 0.2));
  }
  final List<String> registeredUserIds;
  final List<String> attendedUserIds;
  final List<String> bookmarkedUserIds;
  final List<String> pendingUserIds;
  final double averageRating;
  final int reviewCount;

  EventModel({
    required this.id,
    required this.title,
    required this.organizerId,
    required this.organizerName,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    required this.spots,
    required this.availableSpots,
    required this.imageUrl,
    required this.price,
    bool isTrendingFlag = false,
    bool isLimitedSpotsFlag = false,
    this.description = '',
    this.isPublic = true,
    this.isDraft = false,
    this.targetAudience = 'All Students',
    this.registrationTimestamps = const [],
    this.autoCloseRegistration = false,
    this.autoCloseRegistrationTime,
    this.autoEndCheckIn = false,
    this.autoEndCheckInTime,
    this.autoEndEvent = false,
    this.autoEndEventTime,
    this.isCancelled = false,
    this.isRegistrationClosed = false,
    this.isCheckInClosed = false,
    this.isEventEnded = false,
    this.registeredUserIds = const [],
    this.attendedUserIds = const [],
    this.bookmarkedUserIds = const [],
    this.pendingUserIds = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    DateTime? createdAt,
  }) : _isTrending = isTrendingFlag,
       _isLimitedSpots = isLimitedSpotsFlag,
       createdAt = createdAt ?? DateTime(2000);

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    DateTime parsedDate = DateTime.now();
    if (data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      parsedDate = DateTime.tryParse(data['date']) ?? DateTime.now();
    }
    
    List<DateTime> parsedTimestamps = [];
    if (data['registrationTimestamps'] != null) {
      for (var t in data['registrationTimestamps']) {
        if (t is Timestamp) {
          parsedTimestamps.add(t.toDate());
        } else if (t is String) {
          parsedTimestamps.add(DateTime.tryParse(t) ?? DateTime.now());
        }
      }
    }

    int parsedPrice = 0;
    var priceData = data['price'];
    if (priceData is num) {
      parsedPrice = priceData.toInt();
    } else if (priceData is String) {
      if (priceData.toLowerCase() == 'free') {
        parsedPrice = 0;
      } else {
        String numericStr = priceData.replaceAll(RegExp(r'[^0-9]'), '');
        parsedPrice = int.tryParse(numericStr) ?? 0;
      }
    }

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      date: parsedDate,
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      category: data['category'] ?? 'All Events',
      spots: data['spots'] ?? 0,
      availableSpots: data['availableSpots'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      price: parsedPrice,
      isTrendingFlag: data['isTrending'] ?? false,
      isLimitedSpotsFlag: data['isLimitedSpots'] ?? false,
      description: data['description'] ?? '',
      isPublic: data['isPublic'] ?? true,
      isDraft: data['isDraft'] ?? false,
      targetAudience: data['targetAudience'] ?? 'All Students',
      registrationTimestamps: parsedTimestamps,
      autoCloseRegistration: data['autoCloseRegistration'] ?? false,
      autoCloseRegistrationTime: data['autoCloseRegistrationTime'] != null ? (data['autoCloseRegistrationTime'] as Timestamp).toDate() : null,
      autoEndCheckIn: data['autoEndCheckIn'] ?? false,
      autoEndCheckInTime: data['autoEndCheckInTime'] != null ? (data['autoEndCheckInTime'] as Timestamp).toDate() : null,
      autoEndEvent: data['autoEndEvent'] ?? false,
      autoEndEventTime: data['autoEndEventTime'] != null ? (data['autoEndEventTime'] as Timestamp).toDate() : null,
      isCancelled: data['isCancelled'] ?? false,
      isRegistrationClosed: data['isRegistrationClosed'] ?? false,
      isCheckInClosed: data['isCheckInClosed'] ?? false,
      isEventEnded: data['isEventEnded'] ?? false,
      registeredUserIds: List<String>.from(data['registeredUserIds'] ?? []),
      attendedUserIds: List<String>.from(data['attendedUserIds'] ?? []),
      bookmarkedUserIds: List<String>.from(data['bookmarkedUserIds'] ?? []),
      pendingUserIds: List<String>.from(data['pendingUserIds'] ?? []),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : (DateTime.tryParse(data['createdAt'].toString()) ?? DateTime(2000)))
          : DateTime(2000),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'category': category,
      'spots': spots,
      'availableSpots': availableSpots,
      'imageUrl': imageUrl,
      'price': price,
      'isTrending': _isTrending,
      'isLimitedSpots': _isLimitedSpots,
      'description': description,
      'isPublic': isPublic,
      'isDraft': isDraft,
      'targetAudience': targetAudience,
      'registrationTimestamps': registrationTimestamps.map((t) => Timestamp.fromDate(t)).toList(),
      'autoCloseRegistration': autoCloseRegistration,
      if (autoCloseRegistrationTime != null) 'autoCloseRegistrationTime': Timestamp.fromDate(autoCloseRegistrationTime!),
      'autoEndCheckIn': autoEndCheckIn,
      if (autoEndCheckInTime != null) 'autoEndCheckInTime': Timestamp.fromDate(autoEndCheckInTime!),
      'autoEndEvent': autoEndEvent,
      if (autoEndEventTime != null) 'autoEndEventTime': Timestamp.fromDate(autoEndEventTime!),
      'isCancelled': isCancelled,
      'isRegistrationClosed': isRegistrationClosed,
      'isCheckInClosed': isCheckInClosed,
      'isEventEnded': isEventEnded,
      'registeredUserIds': registeredUserIds,
      'attendedUserIds': attendedUserIds,
      'bookmarkedUserIds': bookmarkedUserIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    int parsedPrice = 0;
    var priceData = json['price'];
    if (priceData is num) {
      parsedPrice = priceData.toInt();
    } else if (priceData is String) {
      if (priceData.toLowerCase() == 'free') {
        parsedPrice = 0;
      } else {
        String numericStr = priceData.replaceAll(RegExp(r'[^0-9]'), '');
        parsedPrice = int.tryParse(numericStr) ?? 0;
      }
    }

    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? 'All Events',
      spots: json['spots'] ?? 0,
      availableSpots: json['availableSpots'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      price: parsedPrice,
      isTrendingFlag: json['isTrending'] ?? false,
      isLimitedSpotsFlag: json['isLimitedSpots'] ?? false,
      description: json['description'] as String? ?? '',
      isPublic: json['isPublic'] ?? true,
      isDraft: json['isDraft'] ?? false,
      targetAudience: json['targetAudience'] ?? 'All Students',
      registrationTimestamps: (json['registrationTimestamps'] as List<dynamic>?)
          ?.map((t) => DateTime.tryParse(t.toString()) ?? DateTime.now())
          .toList() ?? [],
      autoCloseRegistration: json['autoCloseRegistration'] ?? false,
      autoCloseRegistrationTime: json['autoCloseRegistrationTime'] != null ? DateTime.tryParse(json['autoCloseRegistrationTime']) : null,
      autoEndCheckIn: json['autoEndCheckIn'] ?? false,
      autoEndCheckInTime: json['autoEndCheckInTime'] != null ? DateTime.tryParse(json['autoEndCheckInTime']) : null,
      autoEndEvent: json['autoEndEvent'] ?? false,
      autoEndEventTime: json['autoEndEventTime'] != null ? DateTime.tryParse(json['autoEndEventTime']) : null,
      isCancelled: json['isCancelled'] ?? false,
      isRegistrationClosed: json['isRegistrationClosed'] ?? false,
      isCheckInClosed: json['isCheckInClosed'] ?? false,
      isEventEnded: json['isEventEnded'] ?? false,
      registeredUserIds: List<String>.from(json['registeredUserIds'] ?? []),
      attendedUserIds: List<String>.from(json['attendedUserIds'] ?? []),
      bookmarkedUserIds: List<String>.from(json['bookmarkedUserIds'] ?? []),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: json['createdAt'] != null ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime(2000)) : DateTime(2000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'category': category,
      'spots': spots,
      'availableSpots': availableSpots,
      'imageUrl': imageUrl,
      'price': price,
      'isTrending': _isTrending,
      'isLimitedSpots': _isLimitedSpots,
      'description': description,
      'isPublic': isPublic,
      'isDraft': isDraft,
      'targetAudience': targetAudience,
      'registrationTimestamps': registrationTimestamps.map((t) => t.toIso8601String()).toList(),
      'autoCloseRegistration': autoCloseRegistration,
      if (autoCloseRegistrationTime != null) 'autoCloseRegistrationTime': autoCloseRegistrationTime!.toIso8601String(),
      'autoEndCheckIn': autoEndCheckIn,
      if (autoEndCheckInTime != null) 'autoEndCheckInTime': autoEndCheckInTime!.toIso8601String(),
      'autoEndEvent': autoEndEvent,
      if (autoEndEventTime != null) 'autoEndEventTime': autoEndEventTime!.toIso8601String(),
      'isCancelled': isCancelled,
      'isRegistrationClosed': isRegistrationClosed,
      'isCheckInClosed': isCheckInClosed,
      'isEventEnded': isEventEnded,
      'registeredUserIds': registeredUserIds,
      'attendedUserIds': attendedUserIds,
      'bookmarkedUserIds': bookmarkedUserIds,
      'pendingUserIds': pendingUserIds,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
