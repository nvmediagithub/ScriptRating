import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/script.dart';

class ScriptListItem extends StatelessWidget {
  final Script script;

  const ScriptListItem({
    super.key,
    required this.script,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          script.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (script.author != null) Text('Author: ${script.author}'),
            if (script.rating != null)
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('Rating: ${script.rating!.toStringAsFixed(1)}'),
                ],
              ),
            if (script.createdAt != null)
              Text('Created: ${script.createdAt!.toLocal().toString().split(' ')[0]}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () => context.go('/results'),
              tooltip: 'View Analysis',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.go('/results'),
      ),
    );
  }
}