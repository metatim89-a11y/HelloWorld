const { Chess } = require('chess.js');

module.exports = {
  name: "chess",
  init() {
    const game = new Chess();
    return {
      fen: game.fen(),
      turn: "white",
      players: {},
      winner: null,
      sel: null,
      board: this.getFlatBoard(game),
      history: [],
      aiEnabled: false
    };
  },
  reset(g) {
    const game = new Chess();
    g.fen = game.fen();
    g.turn = "white";
    g.winner = null;
    g.sel = null;
    g.board = this.getFlatBoard(game);
    g.history = [];
  },
  toggleAI(g) {
    g.aiEnabled = !g.aiEnabled;
    g.players = {};
    this.reset(g);
  },
  undo(g) {
    if (g.history.length > 0) {
      g.fen = g.history.pop();
      const game = new Chess(g.fen);
      g.board = this.getFlatBoard(game);
      g.turn = game.turn() === 'w' ? 'white' : 'black';
      g.winner = null;
      g.sel = null;
    }
  },
  computerMove(g) {
    if (g.winner || !g.aiEnabled) return;
    const humanPlayers = Object.keys(g.players).filter(p => p !== "Computer");
    let compSide = "black";
    if (humanPlayers.length > 0 && g.players[humanPlayers[0]] === "black") compSide = "white";

    if (g.turn === compSide) {
      const game = new Chess(g.fen);
      const moves = game.moves({ verbose: true });
      if (moves.length > 0) {
        // For simple AI, just pick a random move, or pick captures if available
        let bestMove = moves[Math.floor(Math.random() * moves.length)];
        const captures = moves.filter(m => m.flags.includes('c'));
        if (captures.length > 0) {
          bestMove = captures[Math.floor(Math.random() * captures.length)];
        }
        
        // Actually apply the move
        const oldFen = g.fen;
        game.move(bestMove.san);
        
        g.history.push(oldFen);
        g.fen = game.fen();
        g.board = this.getFlatBoard(game);
        g.turn = game.turn() === 'w' ? 'white' : 'black';
        
        if (game.isGameOver()) {
          if (game.isCheckmate()) g.winner = compSide;
          else g.winner = "draw";
        }
      }
    }
  },
  move(g, m, username) {
    if (g.winner) return;

    if (!g.players[username]) {
      const assigned = Object.values(g.players);
      if (assigned.length === 0) g.players[username] = "white";
      else if (assigned.length === 1 && !assigned.includes("black")) g.players[username] = "black";
    }

    const game = new Chess(g.fen);
    const turnColor = game.turn() === 'w' ? 'white' : 'black';
    const isOnlyPlayer = Object.keys(g.players).length === 1;
    if (g.players[username] !== turnColor && !isOnlyPlayer) return;

    if (g.sel === null) {
      // First click: select piece
      const square = this.indexToSquare(m);
      const piece = game.get(square);
      const isCorrectTurnPiece = (piece && ((piece.color === 'w' && turnColor === 'white') || (piece.color === 'b' && turnColor === 'black')));
      if (isCorrectTurnPiece) {
        g.sel = m;
      }
    } else {
      // Second click: try move
      const from = this.indexToSquare(g.sel);
      const to = this.indexToSquare(m);
      
      try {
        const oldFen = g.fen;
        const moveResult = game.move({ from, to, promotion: 'q' });
        if (moveResult) {
          g.history.push(oldFen);
          g.fen = game.fen();
          g.board = this.getFlatBoard(game);
          g.turn = game.turn() === 'w' ? 'white' : 'black';
          
          if (game.isGameOver()) {
            if (game.isCheckmate()) g.winner = turnColor;
            else g.winner = "draw";
          }
        }
      } catch (e) {
        // Invalid move
      }
      g.sel = null;
    }
  },
  getFlatBoard(game) {
    const board = Array(64).fill("");
    game.board().forEach((row, r) => {
      row.forEach((cell, c) => {
        if (cell) {
          const char = cell.type;
          board[r * 8 + c] = cell.color === 'w' ? char.toUpperCase() : char.toLowerCase();
        }
      });
    });
    return board;
  },
  indexToSquare(i) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const r = 8 - Math.floor(i / 8);
    const c = i % 8;
    return files[c] + r;
  }
};
