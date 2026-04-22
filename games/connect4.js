module.exports = {
  name: "connect4",
  init() {
    return {
      board: Array(42).fill(""),
      turn: "red",
      players: {},
      winner: null,
      history: [],
      aiEnabled: false
    };
  },
  reset(g) {
    g.board = Array(42).fill("");
    g.turn = "red";
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
    let compSide = "yellow";
    if (humanPlayers.length > 0 && g.players[humanPlayers[0]] === "yellow") compSide = "red";

    if (g.turn === compSide) {
      let validCols = [];
      for (let c = 0; c < 7; c++) {
        if (!g.board[c]) validCols.push(c); // Top row is empty
      }
      
      if (validCols.length > 0) {
        let bestMove = validCols[Math.floor(Math.random() * validCols.length)];
        
        // Simple blocking/winning for Connect 4 (1 step lookahead)
        for (let c of validCols) {
          // Find row
          for (let r = 5; r >= 0; r--) {
            let i = r * 7 + c;
            if (!g.board[i]) {
              let b = [...g.board]; b[i] = compSide;
              if (this.checkWin(b, r, c)) { bestMove = c; break; }
              break;
            }
          }
        }
        
        // Block human win
        if (bestMove === validCols[Math.floor(Math.random() * validCols.length)]) {
          let humanSide = compSide === "red" ? "yellow" : "red";
          for (let c of validCols) {
            for (let r = 5; r >= 0; r--) {
              let i = r * 7 + c;
              if (!g.board[i]) {
                let b = [...g.board]; b[i] = humanSide;
                if (this.checkWin(b, r, c)) { bestMove = c; break; }
                break;
              }
            }
          }
        }

        this.move(g, bestMove, "Computer");
      }
    }
  },
  move(g, col, username) {
    if (g.winner) return;

    if (!g.players[username]) {
      const assigned = Object.values(g.players);
      if (assigned.length === 0) g.players[username] = "red";
      else if (assigned.length === 1 && !assigned.includes("yellow")) g.players[username] = "yellow";
    }

    const isOnlyPlayer = Object.keys(g.players).length === 1;
    if (g.players[username] !== g.turn && !isOnlyPlayer) return;

    for (let r = 5; r >= 0; r--) {
      let i = r * 7 + col;
      if (!g.board[i]) {
        // Save history before move
        g.history.push({
          board: [...g.board],
          turn: g.turn
        });

        g.board[i] = g.turn;
        const winLine = this.checkWin(g.board, r, col);
        if (winLine) {
          g.winner = g.turn;
          g.winLine = winLine;
        } else if (!g.board.includes("")) {
          g.winner = "draw";
        } else {
          g.turn = g.turn === "red" ? "yellow" : "red";
        }
        break;
      }
    }
  },
  checkWin(b, r, c) {
    const color = b[r * 7 + c];
    const dirs = [[1, 0], [0, 1], [1, 1], [1, -1]];
    for (let [dr, dc] of dirs) {
      let line = [[r, c]];
      for (let s of [1, -1]) {
        for (let i = 1; i < 4; i++) {
          let nr = r + dr * i * s;
          let nc = c + dc * i * s;
          if (nr >= 0 && nr < 6 && nc >= 0 && nc < 7 && b[nr * 7 + nc] === color) {
            line.push([nr, nc]);
          } else break;
        }
      }
      if (line.length >= 4) return line.map(([lr, lc]) => lr * 7 + lc);
    }
    return false;
  }
};
