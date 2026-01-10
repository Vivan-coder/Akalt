import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

class ProfileEditState {
  final bool isLoading;
  final String? error;
  final File? selectedImage;

  ProfileEditState({this.isLoading = false, this.error, this.selectedImage});

  ProfileEditState copyWith({
    bool? isLoading,
    String? error,
    File? selectedImage,
  }) {
    return ProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedImage: selectedImage ?? this.selectedImage,
    );
  }
}

class ProfileEditNotifier extends Notifier<ProfileEditState> {
  @override
  ProfileEditState build() {
    return ProfileEditState();
  }

  void setImage(File? image) {
    state = state.copyWith(selectedImage: image);
  }

  Future<bool> saveProfile({
    required String username,
    required String bio,
    String? whatsAppNumber,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userService = ref.read(userServiceProvider);
      String? photoUrl;
      if (state.selectedImage != null) {
        photoUrl = await userService.uploadProfileImage(
          user.uid,
          state.selectedImage!,
        );
      }

      final updateData = {
        'username': username,
        'bio': bio,
        if (whatsAppNumber != null) 'whatsAppNumber': whatsAppNumber,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

      await userService.updateUserProfile(user.uid, updateData);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final profileEditProvider =
    NotifierProvider<ProfileEditNotifier, ProfileEditState>(() {
      return ProfileEditNotifier();
    });
