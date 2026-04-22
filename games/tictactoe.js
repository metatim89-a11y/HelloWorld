module.exports = {
  name: "tictactoe",
  init() {
    return {
      board: Array(9).fill(""),
      turn: "X",
      players: {}, // { username: "X" or "O" }
      winner: null,
      history: [],
      aiEnabled: false
    };
  },
  reset(g) {
    g.board = Array(9).fill("");
    g.turn = "X";
    g.winner = null;
    g.history = [];
    g.winLine = null;
  },
  toggleAI(g) {
    g.aiEnabled = !g.aiEnabled;
    g.players = {};
    this.reset(g);
  },
  undo(g) {
    if (g.history.length > 0) {
      const prevState = g.history.pop();
      g.board = prevState.board;
      g.turn = prevState.turn;
      g.winner = null;
      g.winLine = null;
    }
  },
  computerMove(g) {
    if (g.winner || !g.aiEnabled) return;
    const humanPlayers = Object.keys(g.players).filter(p => p !== "Computer");
    let compSide = "O";
    if (humanPlayers.length > 0 && g.players[humanPlayers[0]] === "O") compSide = "X";

    if (g.turn === compSide) {
      let empties = [];
      g.board.forEach((c, i) => { if (c === "") empties.push(i); });
      if (empties.length > 0) {
        let bestMove = empties[Math.floor(Math.random() * empties.length)];
        // Simple blocking/winning
        for (let i of empties) {
          let b = [...g.board]; b[i] = compSide; 
          if(this.checkWin(b)) {bestMove=i; break;}
        }
        if (bestMove === empties[Math.floor(Math.random() * empties.length)]) {
          let humanSide = compSide === "X" ? "O" : "X";
          for (let i of empties) {
            let b = [...g.board]; b[i] = humanSide; 
            if(this.checkWin(b)) {bestMove=i; break;}
          }
        }
        this.move(g, bestMove, "Computer");
      }
    }
  },
  move(g, i, username) {
    if (g.winner) return;

    // Assign player if not already assigned
    if (!g.players[username]) {
      const assigned = Object.values(g.players);
      if (assigned.length === 0) g.players[username] = "X";
      else if (assigned.length === 1 && !assigned.includes("O")) g.players[username] = "O";
    }

    // Validate turn (allow solo play if only one player is present)
    const isOnlyPlayer = Object.keys(g.players).length === 1;
    if (g.players[username] !== g.turn && !isOnlyPlayer) return;

    // Validate move
    if (!g.board[i]) {
      // Save history before move
      g.history.push({
        board: [...g.board],
        turn: g.turn
      });

      g.board[i] = g.turn;
      
      const winData = this.checkWin(g.board);
      if (winData) {
        g.winner = g.turn;
        g.winLine = winData;
      } else if (!g.board.includes("")) {
        g.winner = "draw";
      } else {
        g.turn = g.turn === "X" ? "O" : "X";
      }
    }
  },
  checkWin(b) {
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    return wins.find(([a, b1, c]) => b[a] && b[a] === b[b1] && b[a] === b[c]);
  }
};
