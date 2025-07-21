# 🎮 Tetris Battle on FPGA (雙人俄羅斯方塊對戰)

Authors: 張書睿 (110062109), 蔡承翰 (110062111)  
Course Final Project – Digital System Design using FPGA

## 📌 Overview
This project implements a Tetris Battle game on FPGA, originally aimed at supporting two players across two FPGA boards. Due to development limitations, the final version is a fully functional single-player version with rich gameplay features.


---

## 🚀 Features
### 🎮 Gameplay
- Single-player mode
- Real-time piece movement and gravity
- Line elimination & garbage block handling
- Hold mechanism for strategic gameplay
- Random tetromino generation (LFSR-based)
- Increasing falling speed over time
- Keyboard controls (arrow keys / WASD-like layout)
- Game over detection

### 🖼️ UI Components
- Start screen with countdown
- In-game board with:
  - Hold area (top-left)
  - Current game field (center)
  - Next 6 blocks preview (right)
- Game over and win/lose screens

### ⌨️ Keyboard Controls
| Key(s) | Action |
|--------|--------|
| ← / 4 | Move left |
| → / 6 | Move right |
| ↑ / X / 5 / 1 / 9 | Rotate clockwise |
| Ctrl / Z / 3 / 7 | Rotate counterclockwise |
| ↓ / 2 | Soft drop |
| Space | Hard drop |
| Shift / C / 0 | Hold / Swap block |

---

## 🧠 System Architecture
- **FPGA**: Implemented in Verilog on [insert FPGA model]
- **VGA output**: Display rendered using VGA controller
- **Keyboard input**: Decoded from PS/2 keyboard interface
- **Game logic**: Centralized in `Tetris` module, including:
  - Falling block state
  - Rotation logic
  - Elimination & stacking
  - State machine transitions
  - Block rendering
- **LFSR-based Random Generator**: Guarantees fair piece distribution every 7 blocks

### State Machine Highlights
- `RESTART`, `GET_NEXT_BLOCK`, `FALLING`, `DRAWING`, `ELIMINATE`, `WIN`, `LOSE`, etc.
- Supports block legality checks, angle-based rotation logic (matrix-style), stacking control
- Time-controlled falling logic and soft/hard drop behavior

---

## 🧪 Experimental Results
- All key functions were successfully demonstrated:
  - Piece control, rotation, soft/hard drop, elimination, hold, countdown, etc.
- Game speed increases gradually (though not very perceptible)
- Development Challenges:
  - Early version failed synthesis due to overly nested `case` blocks
  - Rewritten with `stacking_array_hidden` to separate falling and stacked pieces
  - Bitstream generation time ~10 mins made iteration slow
  - Integration into one module due to array sharing limits modular testing

---

## ❗ Limitations & Future Work
- ❌ Multiplayer mode via two FPGA boards not completed due to time constraints
- ❌ Score system not implemented
- ✅ Single-player mode is stable and playable
- 🔧 Future improvements:
  - Multiplayer networking via GPIO or UART
  - Score tracking and combo system
  - Improved modularization for testing and synthesis

---

## 📷 Screenshots
(Add images or GIFs here if you have output screenshots from the VGA)

---
