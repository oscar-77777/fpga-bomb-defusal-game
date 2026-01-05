# FPGA Modular Bomb-Defusal Game (DE10-Lite)

This repository presents a **fully hardware-implemented bomb-defusal game** designed on the **Intel® DE10-Lite FPGA (MAX10)** platform.  
The system is written entirely in **synthesizable Verilog HDL** and demonstrates a complete digital system integrating multiple game modules, peripheral interfaces, and a centralized control architecture.

The project emphasizes **finite state machine (FSM) design**, **modular hardware architecture**, **real-time user interaction**, and **FPGA peripheral control**, making it suitable both as an educational project and as a professional portfolio piece for FPGA / IC design.

---

## Table of Contents

- [Project Overview](#project-overview)
- [System Architecture](#system-architecture)
- [Game Modules](#game-modules)
- [Central Controller](#central-controller)
- [Hardware Interfaces](#hardware-interfaces)
- [Clocking and Timing Strategy](#clocking-and-timing-strategy)
- [Randomization Strategy](#randomization-strategy)
- [Directory Structure](#directory-structure)

---

## Project Overview

The game challenges players to solve several logic-based puzzle modules before a countdown timer reaches zero.  
Each module must be solved independently; incorrect actions generate **strikes**, and exceeding the strike limit or time expiration triggers a failure state.

Although inspired by classic bomb-defusal puzzle mechanics, this project is **entirely original**, with all logic, FSMs, and interfaces implemented from scratch for educational purposes.

Key design goals:

- Fully synthesizable hardware design
- Clear modular separation between subsystems
- Deterministic and debuggable behavior
- Real-time interaction using physical hardware

---

## System Architecture

At the top level, the system is divided into three major layers:

1. **Central Control Layer**  
   - Global FSM
   - Timer and strike management
   - Module arbitration and game flow control

2. **Game Logic Layer**  
   - Independent puzzle modules
   - Each module contains its own FSM and error detection logic

3. **Peripheral Interface Layer**  
   - LCD drivers
   - 7-segment display drivers
   - Keypad and button input
   - ADC interface
   - Buzzer and LED outputs

All modules communicate through well-defined interfaces, avoiding shared-state hazards and improving maintainability.

---

## Game Modules

Each puzzle is implemented as an independent Verilog module with a clearly defined FSM.

### Wires Module
- Randomly generates wire colors and positions
- Players must cut wires in a specific order based on logical rules
- Incorrect cuts trigger strike signals

### Memory Module
- Multi-stage memory puzzle
- Displays numbers across multiple rounds
- Requires players to recall previous button positions

### Maze Module
- Grid-based maze navigation
- Player position tracked in hardware registers
- Collision detection prevents illegal moves

### Morse Code Module
- Encodes pseudo-random words using Morse signals
- Outputs via LED and buzzer
- Players decode signals to determine correct parameters

### Password Module
- Rotating letter columns displayed on LCD
- Player cycles characters to form a valid password
- Character comparison and validation handled in hardware

Each module reports **status**, **mistakes**, and **completion signals** to the central controller.

---

## Central Controller

The central controller acts as the **system supervisor** and is implemented as a global FSM.

Responsibilities include:

- Sequencing module activation
- Managing the countdown timer
- Tracking strike count
- Handling success and failure states
- Broadcasting system state to all modules and displays

This structure closely resembles real-world **SoC control logic**, where a central state machine coordinates multiple hardware accelerators.

---

## Hardware Interfaces

The project interfaces with several common FPGA peripherals:

### Displays
- **7-segment displays**  
  - Show remaining time (MM:SS)
  - Indicate strike count

- **LCD1602 / LCD2004A (HD44780 compatible)**  
  - Custom 4-bit and 8-bit drivers
  - Display serial numbers, messages, and puzzle information
  - Timing-controlled (no busy-flag polling)

### Input Devices
- Push-buttons with hardware debouncing
- 4×4 matrix keypad for puzzle input
- Toggle switches for configuration and debugging

### Other Peripherals
- **MAX10 ADC**
  - Used for analog input and random seed entropy
- **Piezo buzzer**
  - Morse code output and feedback sounds
- LEDs for visual indicators and debugging

---

## Clocking and Timing Strategy

- Primary system clock: **50 MHz**
- Derived enable pulses:
  - 1 µs tick
  - 1 ms tick
  - 1 second tick

All timing-sensitive modules (LCD, buzzer, countdown timer) operate using these derived enable signals rather than multiple clock domains, ensuring:

- No clock domain crossing (CDC) hazards
- Deterministic simulation behavior
- Easier timing closure in synthesis

---

## Randomization Strategy

To ensure replayability while remaining synthesizable:

- **LFSR (Linear Feedback Shift Register)** is used for pseudo-random generation
- Seed sources include:
  - ADC readings
  - Switch states
  - Reset-time entropy
- Randomization affects:
  - Module selection
  - Puzzle parameters
  - Morse code words
  - Wire configurations

Simulation remains deterministic when fixed seeds are used.

---

## Directory Structure

The repository is organized as a **Quartus-based FPGA system project**, with all RTL, IP-generated files, and build artifacts located under the `BIG_BOMB/` directory.  
This structure reflects a realistic FPGA development workflow integrating custom Verilog modules, Qsys-generated IP, and board-level constraints.

```text
fpga-bomb-defusal-game/
├── BIG_BOMB/                 # Main Quartus project directory
│
│   ├── BIG_BOMB.qpf          # Quartus project file
│   ├── top.qsf               # Pin assignments and timing constraints
│   ├── pin.tcl               # Pin assignment automation script
│
│   ├── top.v                 # Top-level module (system integration)
│   ├── top.v.bak             # Backup of top-level module
│
│   ├── FSM.v                 # Global finite state machine (game flow control)
│   ├── Center_Timmer.v       # Central countdown timer controller
│   ├── tick_generator.v      # Clock divider and timing tick generator
│   ├── free_counter.v        # Generic counter utility
│
│   ├── random_id.v           # Random ID generation logic
│   ├── random_number.v       # Pseudo-random number generator
│   ├── Random_Serial_Number.v# Random serial number generator
│
│   ├── Wires.v               # Wires puzzle module
│   ├── Memorys.v             # Memory puzzle module
│   ├── Mazes.v               # Maze puzzle logic
│   ├── display_mazes.v       # Maze display controller
│   ├── Morse_Code.v          # Morse code puzzle module
│   ├── Passwords.v           # Password puzzle module
│
│   ├── map.mem               # Maze map ROM initialization data
│   ├── initial_pos.mem       # Maze initial position data
│   ├── final_pos.mem         # Maze target position data
│
│   ├── LCD1602A.v             # LCD 16x2 controller (HD44780 compatible)
│   ├── LCD2004A.v             # LCD 20x4 controller (HD44780 compatible)
│   ├── LCD2004A_4bit.txt      # LCD 20x4 initialization (4-bit mode)
│   ├── LCD2004A8bits.txt      # LCD 20x4 initialization (8-bit mode)
│   ├── LCD_temp.txt           # Temporary LCD display content
│   ├── FULL_LCD.txt           # Full LCD display reference table
│
│   ├── seven_digit_driver.v   # 7-segment display driver
│   ├── Seven_Display_on_Board.v # On-board 7-segment controller
│   ├── tm1637_driver.v        # TM1637 7-segment display driver
│
│   ├── debouncing.v           # General-purpose button debounce module
│   ├── wire_debounce.v        # Debounce logic dedicated to Wires module
│
│   ├── dcf.v                  # Digital conversion filter
│   │                           # (maps raw ADC data to logical-level signals)
│
│   ├── adc_to_digital.v       # Analog thresholding logic
│   │                           # (converts ADC values to digital 1 / 0)
│
│   ├── buzzer.v               # Buzzer driver (audio feedback)
│   ├── ws2812_driver.v        # WS2812 RGB LED driver
│
│   ├── talking.v              # System message and text output logic
│   ├── talking.txt            # Text message definition file
│
│   ├── AA.qsys                # Qsys system for ADC integration
│   ├── AA.sopcinfo            # Qsys system metadata
│   ├── ADC.qsys               # MAX10 ADC Qsys system
│   ├── ADC.sopcinfo           # ADC Qsys metadata
│
│   ├── AA/                    # Qsys-generated HDL (ADC subsystem)
│   ├── ADC/                   # Qsys-generated ADC HDL
│   ├── .qsys_edit/            # Qsys edit cache (auto-generated)
│
│   ├── simulation/            # Simulation workspace
│   │   └── modelsim/          # ModelSim simulation files
│
│   ├── db/                    # Quartus synthesis database (auto-generated)
│   ├── incremental_db/        # Quartus incremental compilation data
│   └── output_files/          # Quartus output files (.sof / .pof)
│
├── .gitignore                 # Git ignore rules for Quartus artifacts
└── README.md                  # Project documentation
```
