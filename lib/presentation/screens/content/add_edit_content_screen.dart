import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/media_item.dart';
import '../../providers/providers.dart';

/// Écran unique pour créer ou modifier un contenu.
/// Passe [existing] pour éditer un élément existant, sinon crée un nouveau.
class AddEditContentScreen extends ConsumerStatefulWidget {
  final MediaItem? existing;
  const AddEditContentScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditContentScreen> createState() =>
      _AddEditContentScreenState();
}

class _AddEditContentScreenState extends ConsumerState<AddEditContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late ContentType _type;
  late PublicationStatus _workStatus;
  late PersonalStatus _personalStatus;
  bool? _hasSequel;
  WatchLanguage? _watchLanguage;
  String? _coverPath;

  final _titleCtrl = TextEditingController();
  final _originalTitleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final _studioCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _arcCtrl = TextEditingController();

  final _totalEpisodesCtrl = TextEditingController();
  final _airedEpisodesCtrl = TextEditingController();
  final _currentEpisodeCtrl = TextEditingController(text: '0');
  final _totalSeasonsCtrl = TextEditingController();
  final _currentSeasonCtrl = TextEditingController();
  final _releaseYearCtrl = TextEditingController();

  final _totalVolumesCtrl = TextEditingController();
  final _publishedVolumesCtrl = TextEditingController();
  final _currentVolumeCtrl = TextEditingController(text: '0');
  final _totalChaptersCtrl = TextEditingController();
  final _publishedChaptersCtrl = TextEditingController();
  final _currentChapterCtrl = TextEditingController(text: '0');

  double? _rating;
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _genres = {};

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? ContentType.anime;
    _workStatus = e?.workStatus ?? PublicationStatus.ongoing;
    _personalStatus = e?.personalStatus ?? PersonalStatus.toConsume;
    _hasSequel = e?.hasSequel;
    _watchLanguage = e?.watchLanguage;
    _coverPath = e?.coverImagePath;

    _titleCtrl.text = e?.title ?? '';
    _originalTitleCtrl.text = e?.originalTitle ?? '';
    _descCtrl.text = e?.description ?? '';
    _commentCtrl.text = e?.comment ?? '';
    _studioCtrl.text = e?.studio ?? '';
    _authorCtrl.text = e?.author ?? '';
    _arcCtrl.text = e?.currentArcName ?? '';

    _totalEpisodesCtrl.text = e?.totalEpisodes?.toString() ?? '';
    _airedEpisodesCtrl.text = e?.airedEpisodes?.toString() ?? '';
    _currentEpisodeCtrl.text = (e?.currentEpisode ?? 0).toString();
    _totalSeasonsCtrl.text = e?.totalSeasons?.toString() ?? '';
    _currentSeasonCtrl.text = e?.currentSeason?.toString() ?? '';
    _releaseYearCtrl.text = e?.releaseYear?.toString() ?? '';

    _totalVolumesCtrl.text = e?.totalVolumes?.toString() ?? '';
    _publishedVolumesCtrl.text = e?.publishedVolumes?.toString() ?? '';
    _currentVolumeCtrl.text = (e?.currentVolume ?? 0).toString();
    _totalChaptersCtrl.text = e?.totalChapters?.toString() ?? '';
    _publishedChaptersCtrl.text = e?.publishedChapters?.toString() ?? '';
    _currentChapterCtrl.text = (e?.currentChapter ?? 0).toString();

    _rating = e?.rating;
    _startDate = e?.startDate;
    _endDate = e?.endDate;
    if (e != null) _genres.addAll(e.genres);
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _originalTitleCtrl, _descCtrl, _commentCtrl, _studioCtrl,
      _authorCtrl, _arcCtrl, _totalEpisodesCtrl, _airedEpisodesCtrl,
      _currentEpisodeCtrl, _totalSeasonsCtrl, _currentSeasonCtrl,
      _releaseYearCtrl, _totalVolumesCtrl, _publishedVolumesCtrl,
      _currentVolumeCtrl, _totalChaptersCtrl, _publishedChaptersCtrl,
      _currentChapterCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) =>
      c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());

  Future<void> _pickImage() async {
    final path =
        await ref.read(imageStorageServiceProvider).pickAndStoreImage();
    if (path != null) setState(() => _coverPath = path);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(activeProfileProvider);
    if (profile == null) return;

    setState(() => _saving = true);

    final draft = MediaItem(
      id: widget.existing?.id ?? '',
      profileId: profile.id,
      type: _type,
      title: _titleCtrl.text.trim(),
      originalTitle: _originalTitleCtrl.text.trim().isEmpty
          ? null
          : _originalTitleCtrl.text.trim(),
      coverImagePath: _coverPath,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      workStatus: _workStatus,
      hasSequel: _type == ContentType.anime ? _hasSequel : null,
      personalStatus: _personalStatus,
      rating: _rating,
      comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      genres: _genres.toList(),
      totalEpisodes: _type == ContentType.anime ? _int(_totalEpisodesCtrl) : null,
      airedEpisodes: _type == ContentType.anime ? _int(_airedEpisodesCtrl) : null,
      currentEpisode: _type == ContentType.anime ? (_int(_currentEpisodeCtrl) ?? 0) : 0,
      totalSeasons: _type == ContentType.anime ? _int(_totalSeasonsCtrl) : null,
      currentSeason: _type == ContentType.anime ? _int(_currentSeasonCtrl) : null,
      studio: _type == ContentType.anime && _studioCtrl.text.trim().isNotEmpty
          ? _studioCtrl.text.trim()
          : null,
      releaseYear: _type == ContentType.anime ? _int(_releaseYearCtrl) : null,
      watchLanguage: _type == ContentType.anime ? _watchLanguage : null,
      totalVolumes: _type == ContentType.manga ? _int(_totalVolumesCtrl) : null,
      publishedVolumes:
          _type == ContentType.manga ? _int(_publishedVolumesCtrl) : null,
      currentVolume: _type == ContentType.manga ? (_int(_currentVolumeCtrl) ?? 0) : 0,
      author: _type != ContentType.anime && _authorCtrl.text.trim().isNotEmpty
          ? _authorCtrl.text.trim()
          : null,
      totalChapters: _type != ContentType.anime ? _int(_totalChaptersCtrl) : null,
      publishedChapters:
          _type != ContentType.anime ? _int(_publishedChaptersCtrl) : null,
      currentChapter: _type != ContentType.anime ? (_int(_currentChapterCtrl) ?? 0) : 0,
      currentArcName: _type != ContentType.anime && _arcCtrl.text.trim().isNotEmpty
          ? _arcCtrl.text.trim()
          : null,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(mediaRepositoryProvider);
    if (_isEditing) {
      await repo.update(draft);
    } else {
      await repo.create(draft);
    }
    ref.read(libraryRevisionProvider.notifier).state++;

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReading = _type != ContentType.anime;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier' : 'Ajouter un contenu'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type de contenu
            SegmentedButton<ContentType>(
              segments: ContentType.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                  .toList(),
              selected: {_type},
              onSelectionChanged: _isEditing
                  ? null // le type ne change pas une fois créé
                  : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),

            // Image de couverture
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        image: _coverPath != null
                            ? DecorationImage(
                                image: FileImage(File(_coverPath!)),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: _coverPath == null
                          ? const Icon(Icons.add_photo_alternate_outlined, size: 32)
                          : null,
                    ),
                    if (_coverPath != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _coverPath = null),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le titre est requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _originalTitleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Titre original (ex : Shingeki no Kyojin)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Statut réel de l'œuvre — indépendant de mon propre avancement.
            Text('Statut réel de l\u2019œuvre',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              "Où en est la publication/diffusion de l'œuvre elle-même.",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PublicationStatus.values
                  .map((s) => ChoiceChip(
                        label: Text(s.label),
                        selected: _workStatus == s,
                        onSelected: (_) => setState(() => _workStatus = s),
                      ))
                  .toList(),
            ),
            if (_type == ContentType.anime) ...[
              const SizedBox(height: 12),
              Text('Suite prévue ?', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Inconnu'),
                    selected: _hasSequel == null,
                    onSelected: (_) => setState(() => _hasSequel = null),
                  ),
                  ChoiceChip(
                    label: const Text('Oui'),
                    selected: _hasSequel == true,
                    onSelected: (_) => setState(() => _hasSequel = true),
                  ),
                  ChoiceChip(
                    label: const Text('Non'),
                    selected: _hasSequel == false,
                    onSelected: (_) => setState(() => _hasSequel = false),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Statut personnel — totalement indépendant du statut réel.
            Text('Mon statut', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PersonalStatus.values
                  .map((s) => ChoiceChip(
                        label: Text(s.labelFor(_type)),
                        selected: _personalStatus == s,
                        onSelected: (_) => setState(() => _personalStatus = s),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            if (_type == ContentType.anime) ..._animeFields(),
            if (isReading) ..._readingFields(),

            const SizedBox(height: 20),
            Text('Organisation détaillée (optionnel)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_type == ContentType.anime)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currentSeasonCtrl,
                      decoration: const InputDecoration(labelText: 'Saison actuelle'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalSeasonsCtrl,
                      decoration: const InputDecoration(labelText: 'Nb de saisons'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              )
            else
              TextFormField(
                controller: _arcCtrl,
                decoration: const InputDecoration(
                    labelText: 'Arc narratif actuel (ex : "Arc Shibuya")'),
              ),
            const SizedBox(height: 20),

            Text('Genres', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kDefaultGenres
                  .map((g) => FilterChip(
                        label: Text(g),
                        selected: _genres.contains(g),
                        onSelected: (sel) => setState(
                            () => sel ? _genres.add(g) : _genres.remove(g)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_startDate == null
                        ? 'Date de début'
                        : _dateFormat.format(_startDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_endDate == null
                        ? 'Date de fin'
                        : _dateFormat.format(_endDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text('Note personnelle', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _rating ?? 0,
              min: 0,
              max: 10,
              divisions: 20,
              label: (_rating ?? 0).toStringAsFixed(1),
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentCtrl,
              decoration: const InputDecoration(labelText: 'Commentaire personnel'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_isEditing ? 'Enregistrer' : 'Ajouter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _animeFields() => [
        Text('Détails anime', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _currentEpisodeCtrl,
                decoration: const InputDecoration(labelText: 'Épisode actuel'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _totalEpisodesCtrl,
                decoration: const InputDecoration(
                    labelText: "Total d'épisodes prévus (si connu)"),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _airedEpisodesCtrl,
          decoration: const InputDecoration(
              labelText: 'Épisodes déjà diffusés (si différent du total)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _studioCtrl,
                decoration: const InputDecoration(labelText: 'Studio'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _releaseYearCtrl,
                decoration: const InputDecoration(labelText: 'Année de sortie'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Langue de visionnage', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Non précisé'),
              selected: _watchLanguage == null,
              onSelected: (_) => setState(() => _watchLanguage = null),
            ),
            for (final lang in WatchLanguage.values)
              ChoiceChip(
                label: Text(lang.label),
                selected: _watchLanguage == lang,
                onSelected: (_) => setState(() => _watchLanguage = lang),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _readingFields() => [
        Text(
            _type == ContentType.manga ? 'Détails manga' : 'Détails manhwa',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _currentChapterCtrl,
                decoration: const InputDecoration(labelText: 'Chapitre actuel'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _totalChaptersCtrl,
                decoration: const InputDecoration(
                    labelText: 'Total de chapitres prévus (si connu)'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _publishedChaptersCtrl,
          decoration: const InputDecoration(
              labelText: 'Chapitres publiés actuellement'),
          keyboardType: TextInputType.number,
        ),
        if (_type == ContentType.manga) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _currentVolumeCtrl,
                  decoration: const InputDecoration(labelText: 'Tome actuel'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _totalVolumesCtrl,
                  decoration: const InputDecoration(labelText: 'Total de tomes prévus'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _publishedVolumesCtrl,
            decoration:
                const InputDecoration(labelText: 'Tomes publiés actuellement'),
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _authorCtrl,
          decoration: const InputDecoration(labelText: 'Auteur'),
        ),
        const SizedBox(height: 20),
      ];
}
