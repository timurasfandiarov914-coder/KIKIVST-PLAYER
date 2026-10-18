import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../../../core/models/catalog_track.dart';
import '../../catalog/domain/catalog_search_service.dart';
import '../../player/data/playback_service.dart';
import '../../resolver/domain/stream_resolver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.audioHandler,
    required this.searchService,
    required this.resolver,
    super.key,
  });

  final PlaybackService audioHandler;
  final CatalogSearchService searchService;
  final StreamResolver resolver;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  SearchResponse? _response;
  String? _notice;
  String? _resolvingKey;
  bool _isSearching = false;
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search([String? value]) async {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty) {
      setState(() => _notice = 'Введи название трека или исполнителя.');
      return;
    }

    setState(() {
      _isSearching = true;
      _notice = null;
      _response = null;
    });

    final response = await widget.searchService.search(query);
    if (!mounted) return;

    setState(() {
      _response = response;
      _isSearching = false;
      if (response.sourceCount == 0) {
        _notice =
            'Каталоги ещё не подключены. Поиск не подменяется демо-данными.';
      } else if (response.tracks.isEmpty && response.hasFailures) {
        _notice = 'Источники временно не ответили. Попробуй ещё раз.';
      }
    });
  }

  Future<void> _playTrack(CatalogTrack track) async {
    setState(() {
      _resolvingKey = track.cacheKey;
      _notice = null;
    });

    try {
      final playable = await widget.resolver.resolve(track);
      if (!mounted) return;

      if (playable == null) {
        setState(() {
          _notice =
              'Для этого трека пока нет доступного способа воспроизведения.';
        });
        return;
      }

      await widget.audioHandler.setQueue([playable]);
      await widget.audioHandler.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _notice =
              'Не удалось запустить трек. Источник мог закрыть поток или изменить доступ.';
        });
      }
    } finally {
      if (mounted) setState(() => _resolvingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _selectedTab == 0 ? _buildSearchPage() : _buildQueuePage(),
            ),
            _buildMiniPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Поиск',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_rounded),
            label: 'Очередь',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPage() {
    final tracks = _response?.tracks ?? const <CatalogTrack>[];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildBrand(),
              const SizedBox(height: 34),
              const Text(
                'Музыка.\nБез лишнего.',
                style: TextStyle(
                  fontSize: 38,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Один плеер для каталогов с разрешённым поиском и воспроизведением.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 24),
              _buildSearchField(),
              const SizedBox(height: 22),
              _buildSourceStatus(),
              if (_notice != null) ...[
                const SizedBox(height: 16),
                _buildNotice(_notice!),
              ],
              if (_isSearching) ...[
                const SizedBox(height: 20),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (tracks.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'РЕЗУЛЬТАТЫ · ${tracks.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: Color(0xFFC8FF45),
                  ),
                ),
                const SizedBox(height: 12),
                for (final track in tracks) _buildTrackRow(track),
              ] else if (_response != null &&
                  _response!.sourceCount > 0 &&
                  !_response!.hasFailures) ...[
                const SizedBox(height: 28),
                _buildEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Ничего не найдено',
                  body: 'Попробуй другое название или имя исполнителя.',
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBrand() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFC8FF45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Color(0xFF11150B),
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KIKI',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.8,
              ),
            ),
            Text(
              'VST PLAYER',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white54,
                letterSpacing: 2.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: const Text(
            'OPEN SOURCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151815),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
        decoration: InputDecoration(
          hintText: 'Трек, артист, релиз…',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
          suffixIcon: IconButton(
            tooltip: 'Искать',
            onPressed: _isSearching ? null : _search,
            icon: _isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }

  Widget _buildSourceStatus() {
    if (widget.searchService.hasSources) {
      return Row(
        children: [
          const Icon(
            Icons.radio_button_checked_rounded,
            size: 13,
            color: Color(0xFFC8FF45),
          ),
          const SizedBox(width: 8),
          Text(
            'Подключено источников: ${_response?.sourceCount ?? '—'}',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131613),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hub_outlined, color: Color(0xFFC8FF45), size: 23),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Каталоги ещё не подключены',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Основа плеера готова. Источники подключаются отдельно — через доступные API и разрешённые способы воспроизведения.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackRow(CatalogTrack track) {
    final isResolving = _resolvingKey == track.cacheKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121512),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: _artwork(track.artworkUri, track.title),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          '${track.artist} · ${track.provider.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: IconButton(
          tooltip: 'Воспроизвести',
          onPressed: isResolving ? null : () => _playTrack(track),
          icon: isResolving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_circle_fill_rounded, size: 30),
        ),
      ),
    );
  }

  Widget _buildQueuePage() {
    return StreamBuilder<List<MediaItem>>(
      stream: widget.audioHandler.queue,
      initialData: const [],
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <MediaItem>[];

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Очередь',
                    style: TextStyle(
                      fontSize: 32,
                      letterSpacing: -1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${items.length} ${items.length == 1 ? 'трек' : 'треков'}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  if (items.isEmpty)
                    _buildEmptyState(
                      icon: Icons.queue_music_rounded,
                      title: 'Здесь пока тихо',
                      body:
                          'Доступные для воспроизведения треки будут появляться в очереди.',
                    )
                  else
                    for (var i = 0; i < items.length; i++)
                      _buildQueueItem(items[i], i),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueueItem(MediaItem item, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: _artwork(item.artUri, item.title),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.artist ?? 'Неизвестный исполнитель',
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: IconButton(
        tooltip: 'Играть',
        onPressed: () => widget.audioHandler.skipToQueueItem(index),
        icon: const Icon(Icons.play_arrow_rounded),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return StreamBuilder<MediaItem?>(
      stream: widget.audioHandler.mediaItem,
      builder: (context, itemSnapshot) {
        final item = itemSnapshot.data;
        if (item == null) return const SizedBox.shrink();

        return StreamBuilder<PlaybackState>(
          stream: widget.audioHandler.playbackState,
          builder: (context, playbackSnapshot) {
            final isPlaying = playbackSnapshot.data?.playing ?? false;
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
              decoration: BoxDecoration(
                color: const Color(0xFF20251D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFC8FF45).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  _artwork(item.artUri, item.title, size: 42),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.artist ?? 'Неизвестный исполнитель',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Предыдущий трек',
                    onPressed: widget.audioHandler.skipToPrevious,
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  IconButton(
                    tooltip: isPlaying ? 'Пауза' : 'Играть',
                    onPressed: isPlaying
                        ? widget.audioHandler.pause
                        : widget.audioHandler.play,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: const Color(0xFFC8FF45),
                      size: 32,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Следующий трек',
                    onPressed: widget.audioHandler.skipToNext,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2417),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8E713A).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF121512),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 31, color: Colors.white38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _artwork(Uri? uri, String seed, {double size = 48}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: uri == null
            ? ColoredBox(
                color: const Color(0xFF252A22),
                child: Center(
                  child: Text(
                    seed.isEmpty ? 'K' : seed[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC8FF45),
                    ),
                  ),
                ),
              )
            : Image.network(
                uri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFF252A22),
                  child: Icon(Icons.music_note_rounded, color: Colors.white54),
                ),
              ),
      ),
    );
  }
}
