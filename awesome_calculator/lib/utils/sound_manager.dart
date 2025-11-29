import 'package:audioplayers/audioplayers.dart';

/// Manages sound effects for the application
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  /// Enable or disable sound effects
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Check if sound is enabled
  bool get isEnabled => _enabled;

  /// Play a sound effect from assets
  /// Example: await SoundManager().playSound('sounds/click.wav');
  Future<void> playSound(String assetPath) async {
    if (!_enabled) return;

    try {
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      // Silently fail if sound cannot be played
      print('Error playing sound $assetPath: $e');
    }
  }

  /// Play a sound effect with specific volume (0.0 to 1.0)
  Future<void> playSoundWithVolume(String assetPath, double volume) async {
    if (!_enabled) return;

    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      print('Error playing sound $assetPath: $e');
    }
  }

  /// Stop currently playing sound
  Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose the audio player
  void dispose() {
    _player.dispose();
  }
}
