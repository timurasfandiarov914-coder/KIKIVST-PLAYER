import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/models/catalog_track.dart';
import '../../../core/models/playable_track.dart';

class PlaybackService extends BaseAudioHandler with QueueHandler, SeekHandler {
  PlaybackService() {
    _player.playbackEventStream.listen(
      (_) => _publishState(),
      onError: (Object _, StackTrace _) {
        playbackState.add(
          playbackState.value.copyWith(
            playing: false,
            processingState: AudioProcessingState.error,
          ),
        );
      },
    );

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _tracks.length) {
        mediaItem.add(_toMediaItem(_tracks[index]));
      }
      _publishState();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  List<PlayableTrack> _tracks = const [];

  Future<void> setQueue(
    List<PlayableTrack> tracks, {
    int initialIndex = 0,
  }) async {
    if (tracks.isEmpty) {
      throw ArgumentError.value(tracks, 'tracks', 'Queue cannot be empty.');
    }
    if (initialIndex < 0 || initialIndex >= tracks.length) {
      throw RangeError.index(initialIndex, tracks);
    }

    final previousTracks = _tracks;
    _tracks = List.unmodifiable(tracks);

    final sources = _tracks
        .map((track) {
          return AudioSource.uri(
            track.stream.uri,
            headers: track.stream.headers.isEmpty ? null : track.stream.headers,
            tag: _toMediaItem(track),
          );
        })
        .toList(growable: false);

    try {
      await _player.setAudioSources(sources, initialIndex: initialIndex);
      queue.add(_tracks.map(_toMediaItem).toList(growable: false));
      mediaItem.add(_toMediaItem(_tracks[initialIndex]));
      _publishState();
    } catch (_) {
      _tracks = previousTracks;
      rethrow;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _tracks.length) {
      throw RangeError.index(index, _tracks);
    }
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> skipToNext() async {
    final index = _player.currentIndex;
    if (index != null && index + 1 < _tracks.length) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final index = _player.currentIndex;
    if (index != null && index > 0) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
    await super.stop();
  }

  MediaItem _toMediaItem(PlayableTrack playable) {
    final track = playable.track;
    return MediaItem(
      id: track.cacheKey,
      title: track.title,
      artist: track.artist,
      album: track.provider.label,
      artUri: track.artworkUri,
      duration: track.duration,
    );
  }

  void _publishState() {
    final processingState = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }
}
