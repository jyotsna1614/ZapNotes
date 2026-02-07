import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../widgets/gradient_background.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import '../services/auth_service.dart';
import 'auth_page.dart';
import 'note_editor_page.dart';
import 'note_unlock_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotesService _notesService = NotesService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isGridView = false; // false = list view, true = grid view

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadLayoutPreference();
  }

  Future<void> _loadLayoutPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('isGridView') ?? false;
    });
  }

  Future<void> _toggleLayout() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool('isGridView', _isGridView);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await _notesService.getAllNotes();
    setState(() {
      _notes = notes;
      _filteredNotes = notes;
      _isLoading = false;
    });
  }

  void _searchNotes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredNotes = _notes;
      });
    } else {
      setState(() {
        _filteredNotes = _notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase()) ||
                 note.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.cyanAzure),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.pinkLavender),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  Future<void> _createNewNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NoteEditorPage(),
      ),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _openNote(Note note) async {
    // Check if note is locked
    if (note.isLocked) {
      final unlocked = await showDialog<bool>(
        context: context,
        builder: (context) => const NoteUnlockDialog(),
      );

      if (unlocked != true) return;
    }

    // Open note editor
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(note: note),
      ),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Delete Note',
          style: TextStyle(color: AppColors.pinkLavender),
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _notesService.deleteNote(note.id);
      _loadNotes();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          backgroundColor: AppColors.pinkLavender,
        ),
      );
    }
  }

  Future<void> _toggleNoteLock(Note note) async {
    await _notesService.toggleNoteLock(note.id);
    _loadNotes();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(note.isLocked ? 'Note unlocked' : 'Note locked'),
        backgroundColor: AppColors.cyanAzure,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: _searchNotes,
              )
            : const Text(
                'ZapNotes',
                style: TextStyle(color: AppColors.pinkLavender),
              ),
        backgroundColor: AppColors.darkSurface,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppColors.cyanAzure,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchNotes('');
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: AppColors.cyanAzure,
            ),
            onPressed: _toggleLayout,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.cyanAzure),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.cyanAzure,
                ),
              )
            : _filteredNotes.isEmpty
                ? _buildEmptyState()
                : _buildNotesList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        backgroundColor: AppColors.pinkLavender,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.note_add_outlined,
            size: 100,
            color: AppColors.cyanAzure.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _isSearching ? 'No notes found' : 'No notes yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching
                ? 'Try a different search term'
                : 'Tap + to create your first note',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _filteredNotes.length,
        itemBuilder: (context, index) {
          final note = _filteredNotes[index];
          return _buildNoteCardGrid(note);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredNotes.length,
        itemBuilder: (context, index) {
          final note = _filteredNotes[index];
          return _buildNoteCard(note);
        },
      );
    }
  }

  Widget _buildNoteCard(Note note) {
    final bool showContent = !note.isLocked;
    
    return Card(
      color: AppColors.darkSurface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: note.isLocked
              ? AppColors.pinkLavender.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _openNote(note),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isLocked)
                    const Icon(
                      Icons.lock,
                      color: AppColors.pinkLavender,
                      size: 20,
                    ),
                  if (note.isLocked) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      showContent 
                          ? (note.title.isEmpty ? 'Untitled' : note.title)
                          : 'Locked Note',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyanAzure,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: AppColors.darkSurface,
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'lock':
                          _toggleNoteLock(note);
                          break;
                        case 'delete':
                          _deleteNote(note);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'lock',
                        child: Row(
                          children: [
                            Icon(
                              note.isLocked ? Icons.lock_open : Icons.lock,
                              color: AppColors.cyanAzure,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              note.isLocked ? 'Unlock' : 'Lock',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                showContent
                    ? (note.content.isEmpty ? 'No content' : note.content)
                    : 'This note is locked. Tap to unlock and view.',
                style: TextStyle(
                  fontSize: 14,
                  color: showContent 
                      ? AppColors.textSecondary 
                      : AppColors.textSecondary.withOpacity(0.6),
                  fontStyle: showContent ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCardGrid(Note note) {
    final bool showContent = !note.isLocked;
    
    return Card(
      color: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: note.isLocked
              ? AppColors.pinkLavender.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _openNote(note),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isLocked)
                    const Icon(
                      Icons.lock,
                      color: AppColors.pinkLavender,
                      size: 18,
                    ),
                  if (note.isLocked) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      showContent 
                          ? (note.title.isEmpty ? 'Untitled' : note.title)
                          : 'Locked Note',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyanAzure,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: AppColors.darkSurface,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'lock':
                          _toggleNoteLock(note);
                          break;
                        case 'delete':
                          _deleteNote(note);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'lock',
                        child: Row(
                          children: [
                            Icon(
                              note.isLocked ? Icons.lock_open : Icons.lock,
                              color: AppColors.cyanAzure,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              note.isLocked ? 'Unlock' : 'Lock',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  showContent
                      ? (note.content.isEmpty ? 'No content' : note.content)
                      : 'Locked. Tap to view.',
                  style: TextStyle(
                    fontSize: 13,
                    color: showContent 
                        ? AppColors.textSecondary 
                        : AppColors.textSecondary.withOpacity(0.6),
                    fontStyle: showContent ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
