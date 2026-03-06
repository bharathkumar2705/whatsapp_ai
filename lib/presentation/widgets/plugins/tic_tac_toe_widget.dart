import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/innovation_provider.dart';
import '../../providers/auth_provider.dart';

class TicTacToeWidget extends StatelessWidget {
  final String chatId;
  final String messageId;
  final Map<String, dynamic> data;

  const TicTacToeWidget({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> board = List<int>.from(data['board'] ?? List.filled(9, 0)); // 0=Empty, 1=X, 2=O
    final String nextTurnUid = data['nextTurnUid'] ?? '';
    final String? winner = data['winner'];
    final theme = Theme.of(context);
    final myUid = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
    final bool isMyTurn = nextTurnUid == myUid;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videogame_asset, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text("Tic Tac Toe", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (winner != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                winner == 'draw' ? "It's a Draw! 🤝" : (winner == myUid ? "You Won! 🎉" : "You Lost! 😢"),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: winner == 'draw' ? Colors.orange : (winner == myUid ? Colors.green : Colors.red),
                  fontSize: 16,
                ),
              ),
            )
          else
            Text(
              isMyTurn ? "Your Turn (Move!)" : "Waiting for opponent...",
              style: TextStyle(
                color: isMyTurn ? theme.colorScheme.primary : Colors.grey,
                fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final val = board[index];
              return GestureDetector(
                onTap: (val == 0 && isMyTurn && winner == null) 
                  ? () => _handleMove(context, board, index, myUid) 
                  : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Center(
                    child: val == 0
                        ? null
                        : Text(
                            val == 1 ? 'X' : 'O',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: val == 1 ? Colors.blue : Colors.red,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          if (winner != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                onPressed: () => _resetGame(context, myUid),
                child: const Text("Rematch?"),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMove(BuildContext context, List<int> currentBoard, int index, String myUid) {
    final List<int> newBoard = List.from(currentBoard);
    // Find who played last to determine marker. 
    // In this simple version, let's say the initiator is X(1).
    final int xCount = currentBoard.where((e) => e == 1).length;
    final int oCount = currentBoard.where((e) => e == 2).length;
    final int myMarker = xCount <= oCount ? 1 : 2;
    
    newBoard[index] = myMarker;
    
    // Simple win detection
    String? winner;
    if (_checkWin(newBoard, myMarker)) {
      winner = myUid;
    } else if (!newBoard.contains(0)) {
      winner = 'draw';
    }

    // Determine next turn (get other participant from chat - will use a simple flip for now)
    // Actually, we need the other person's UID. Let's assume the provider handles finding the opponent or we just toggle turns.
    // To keep it simple: we need to send the 'nextTurnUid'.
    // I'll update InnovationProvider to handle the flip based on participants.
    
    Provider.of<InnovationProvider>(context, listen: false).makeTicTacToeMove(
      chatId: chatId,
      messageId: messageId,
      board: newBoard,
      nextTurnUid: 'TOGGLE', // Special flag for provider to flip it? or pass it if known.
      winner: winner,
    );
  }

  bool _checkWin(List<int> b, int m) {
    final wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];
    return wins.any((w) => w.every((i) => b[i] == m));
  }

  void _resetGame(BuildContext context, String myUid) {
    Provider.of<InnovationProvider>(context, listen: false).makeTicTacToeMove(
      chatId: chatId,
      messageId: messageId,
      board: List.filled(9, 0),
      nextTurnUid: myUid,
    );
  }
}
