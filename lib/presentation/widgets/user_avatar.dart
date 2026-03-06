import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final bool isDecentralizedVerified;

  const UserAvatar({
    super.key, 
    this.url, 
    this.radius = 20,
    this.isDecentralizedVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
          child: (url == null || url!.isEmpty) ? const Icon(Icons.person) : null,
        ),
        if (isDecentralizedVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }
}
