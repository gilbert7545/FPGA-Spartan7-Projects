# Full Adder

Verilog implementations of Full Adders and related arithmetic circuits.

## Included Designs

### 1-bit Full Adder
Performs single-bit binary addition with carry input.

### Full Adder using Half Adders
Hierarchical implementation of a Full Adder using two Half Adder modules and OR gate logic for carry generation.

> Note: This design requires the `half_adder.v` module from the Half_Adder section.

### 4-bit Full Adder
Performs multi-bit binary addition using cascaded Full Adders.

## Files
- `full_adder.v`
- `full_adder_tb.v`
- `full_adder_using_half_adder.v`
- `full_adder_using_half_adder_tb.v`
- `four_bit_adder.v`
- `four_bit_adder_tb.v`

## Tools Used
- Verilog HDL
- Vivado
- Spartan-7 FPGA
