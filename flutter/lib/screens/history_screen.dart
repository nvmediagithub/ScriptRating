import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _historyItems = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Mock loading delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock history data
      _historyItems = [
        {
          'id': '1',
          'title': 'Sample Script 1',
          'rating': 'PG-13',
          'date': '2024-01-15 14:30',
          'categories': ['Violence', 'Language'],
        },
        {
          'id': '2',
          'title': 'Movie Script Alpha',
          'rating': 'R',
          'date': '2024-01-14 09:15',
          'categories': ['Violence', 'Adult Content', 'Language'],
        },
        {
          'id': '3',
          'title': 'TV Pilot Beta',
          'rating': 'PG',
          'date': '2024-01-13 16:45',
          'categories': ['Language'],
        },
        {
          'id': '4',
          'title': 'Short Film Gamma',
          'rating': 'PG-13',
          'date': '2024-01-12 11:20',
          'categories': ['Adult Content'],
        },
      ];
    } catch (e) {
      setState(() {
        _error = 'Failed to load history: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewResult(String id) {
    // Navigate to results screen with specific ID
    context.go('/results');
  }

  void _deleteItem(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Analysis'),
        content: const Text(
          'Are you sure you want to delete this analysis from history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _historyItems.removeWhere((item) => item['id'] == id);
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Analysis deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadHistory,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _historyItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No analysis history found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _historyItems.length,
              itemBuilder: (context, index) {
                final item = _historyItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRatingColor(item['rating']),
                      child: Text(
                        item['rating'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Analyzed on ${item['date']}'),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: (item['categories'] as List<String>)
                              .map(
                                (category) => Chip(
                                  label: Text(
                                    category,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'view') {
                          _viewResult(item['id']);
                        } else if (value == 'delete') {
                          _deleteItem(item['id']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('View Results'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _viewResult(item['id']),
                  ),
                );
              },
            ),
    );
  }

  Color _getRatingColor(String rating) {
    switch (rating) {
      case 'G':
        return Colors.green;
      case 'PG':
        return Colors.blue;
      case 'PG-13':
        return Colors.orange;
      case 'R':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
