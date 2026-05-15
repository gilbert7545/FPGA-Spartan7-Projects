# FPGA-Spartan7-Projects

## 📚 Learning Resources & References

These projects were developed through self-learning, experimentation, AI-assisted debugging, and FPGA documentation resources.

Helpful references used during development include:

- RealDigital FPGA Documentation  
  https://www.realdigital.org/doc/02013cd17602c8af749f00561f88ae21

- Digilent Clock Divider Tutorial  
  https://digilent.com/reference/learn/programmable-logic/tutorials/use-flip-flops-to-build-a-clock-divider/start

Additional understanding was built through:
- Vivado experimentation
- FPGA debugging
- Verilog simulations
- AI-assisted problem solving and design exploration



## 🔌 FPGA Pin Assignments

The projects were implemented on the Spartan-7 FPGA Boolean Board using Vivado I/O pin constraints.

Various modules such as:
- ALU outputs
- Switch inputs
- Seven-segment displays
- OLED interfaces
- Counters

were mapped to dedicated FPGA package pins through Vivado I/O planning.

### Example Pin Mapping

| Signal | Direction | FPGA Pin |
|---|---|---|
| result[0] | OUT | E6 |
| result[1] | OUT | C3 |
| result[2] | OUT | B2 |
| result[3] | OUT | A2 |
| s[0] | IN | P2 |
| s[1] | IN | P1 |

### Arithmetic System Mapping

| Signal | Direction | FPGA Pin |
|---|---|---|
| a[3:0] | IN | K1, K2, L1, M1 |
| b[3:0] | IN | T2, U1, U2, V2 |
| quotient[3:0] | OUT | E5, E3, E2, E1 |
| remainder[3:0] | OUT | F2, F1, G2, G1 |

These assignments enabled real-time hardware verification on the Spartan-7 FPGA board.

> 📷 Constraint and I/O planning screenshots are available in the `constraints/` or project image sections for reference.
