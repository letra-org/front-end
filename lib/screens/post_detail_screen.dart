import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post by ${post['author'] ?? 'User'}'),
      ),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(0),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(post, context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text(post['content'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
              ),
              if (post['imageUrl'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CachedNetworkImage(
                    imageUrl: post['imageUrl'],
                    placeholder: (context, url) => Container(height: 250, color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              _buildPostActions(post),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(Map<String, dynamic> post, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: post['avatarUrl'] != null ? CachedNetworkImageProvider(post['avatarUrl']) : null,
            child: post['avatarUrl'] == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post['author'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(post['time'] ?? 'now', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostActions(Map<String, dynamic> post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildActionButton(Icons.thumb_up_outlined, '${post['likes']}', () {}),
          const SizedBox(width: 16),
          _buildActionButton(Icons.comment_outlined, '${post['comments']}', () {}),
          const SizedBox(width: 16),
          _buildActionButton(Icons.share_outlined, 'Share', () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: Colors.grey[700]),
      label: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
