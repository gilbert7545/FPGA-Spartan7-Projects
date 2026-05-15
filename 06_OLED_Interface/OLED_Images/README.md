# OLED Image Display

Verilog implementation for displaying images on SSD1331 OLED using Spartan-7 FPGA.

## Features
- OLED image rendering
- SPI communication
- FPGA display control
- ROM-based pixel storage

## Image Storage Method

The OLED display resolution used is **96 × 64 pixels**, resulting in:

```text
96 × 64 = 6144 pixels
```

Each pixel color value is stored inside a ROM memory block.

Example:

```verilog
rom[2542] = 16'h71ca;
rom[2543] = 16'h4948;
rom[2544] = 16'h4a09;
rom[2545] = 16'h3a09;
rom[2546] = 16'h2187;
rom[2547] = 16'h31e9;
rom[2548] = 16'h320a;
rom[2549] = 16'h428c;
rom[2550] = 16'h5b0e;
rom[2551] = 16'h52cd;
rom[2552] = 16'h5b0e;
```

Each ROM address corresponds to a pixel location, while the 16-bit hexadecimal value represents the pixel color.

By modifying these ROM values, different images can be displayed on the OLED screen.

## Files
- `oled_image_top.v`

## Tools Used
- Verilog HDL
- Vivado
- Spartan-7 FPGA
- SSD1331 OLED Display
