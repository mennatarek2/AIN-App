import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Count of active SOS alerts across the user's communities.
/// Starts at 0. Will be connected to a SignalR stream in the SOS feature sprint.
final sosBadgeCountProvider = StateProvider<int>((ref) => 0);
