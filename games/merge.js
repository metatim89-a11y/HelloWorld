module.exports = {
  name: "merge",
  init() {
    return {
      grid: this.createGrid(5, 5),
      score: 0,
      players: {},
      winner: null
    };
  },
  createGrid(rows, cols) {
    let grid = [];
    for (let i = 0; i < rows * cols; i++) {
      grid.push(Math.pow(2, Math.floor(Math.random() * 3) + 1)); // 2, 4, or 8
    }
    return grid;
  },
  reset(g) {
    g.grid = this.createGrid(5, 5);
    g.score = 0;
    g.winner = null;
  },
  move(g, index, username) {
    if (g.winner) return;
    
    const val = g.grid[index];
    if (!val) return;

    let cluster = [];
    let visited = new Set();
    let stack = [index];

    // Find all connected identical numbers
    while (stack.length > 0) {
      let curr = stack.pop();
      if (visited.has(curr)) continue;
      visited.add(curr);
      cluster.push(curr);

      const neighbors = this.getNeighbors(curr, 5, 5);
      neighbors.forEach(n => {
        if (g.grid[n] === val && !visited.has(n)) {
          stack.push(n);
        }
      });
    }

    if (cluster.length >= 2) {
      // Merge: Update the clicked cell and clear others
      g.grid[index] = val * Math.pow(2, cluster.length - 1);
      cluster.forEach(i => {
        if (i !== index) g.grid[i] = null;
      });

      // Simple "gravity" - numbers fall down
      this.applyGravity(g, 5, 5);
      // Refill empty spots
      this.refill(g);
      
      g.score += g.grid[index];
    }
  },
  getNeighbors(i, rows, cols) {
    let n = [];
    let r = Math.floor(i / cols);
    let c = i % cols;
    if (r > 0) n.push(i - cols);
    if (r < rows - 1) n.push(i + cols);
    if (c > 0) n.push(i - 1);
    if (c < cols - 1) n.push(i + 1);
    return n;
  },
  applyGravity(g, rows, cols) {
    for (let c = 0; c < cols; c++) {
      let column = [];
      for (let r = 0; r < rows; r++) {
        if (g.grid[r * cols + c] !== null) {
          column.push(g.grid[r * cols + c]);
        }
      }
      for (let r = rows - 1; r >= 0; r--) {
        g.grid[r * cols + c] = column.length > 0 ? column.pop() : null;
      }
    }
  },
  refill(g) {
    g.grid = g.grid.map(v => v === null ? Math.pow(2, Math.floor(Math.random() * 3) + 1) : v);
  }
};
