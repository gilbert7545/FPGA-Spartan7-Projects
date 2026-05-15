module oled_gilbert(
    input clk,
    input rst,
    output sclk,
    output mosi,
    output cs,
    output dc,
    output res_n,
    output vccen,
    output pmoden
);
    // SPI and OLED init wiring
    wire spi_done;
    wire [7:0] spi_data;
    wire spi_start;
    wire init_done;
    wire sclk_int, mosi_int, cs_int, dc_init, res_n_init;
    assign sclk   = sclk_int;
    assign mosi   = mosi_int;
    assign cs     = cs_int;
    assign dc     = drawing ? draw_dc : dc_init;
    assign res_n  = res_n_init;
    assign vccen  = 1'b1;
    assign pmoden = 1'b1;

    // Drawing state
    reg [6:0] pixel_x = 0;
    reg [6:0] pixel_y = 0;
    reg [7:0] draw_spi_data;
    reg draw_spi_start = 0;
    reg draw_dc = 0;
    reg drawing = 0;
    reg [3:0] state = 0;
    wire [15:0] rgb_pixel;

    // Letter ROM, generates GILBERT pixels
    gilbert_pixel_rom gilbert_rom(
        .x(pixel_x),
        .y(pixel_y),
        .rgb(rgb_pixel)
    );

    // OLED init and SPI
    ssd1331_init oled_init (
        .clk(clk),
        .rst(rst),
        .spi_data(spi_data),
        .spi_start(spi_start),
        .spi_done(spi_done),
        .dc(dc_init),
        .res_n(res_n_init),
        .init_done(init_done)
    );

    spi_master spi (
        .clk(clk),
        .rst(rst),
        .data_in(drawing ? draw_spi_data : spi_data),
        .start(drawing ? draw_spi_start : spi_start),
        .sclk(sclk_int),
        .mosi(mosi_int),
        .cs(cs_int),
        .done(spi_done)
    );

    // Drawing FSM (block letters fill screen, no animation)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            drawing <= 0;
            draw_spi_start <= 0;
            pixel_x <= 0;
            pixel_y <= 0;
        end else if (init_done) begin
            case (state)
                // Set full screen window (same as before)
                0: begin draw_spi_data <= 8'h15; draw_spi_start <= 1; draw_dc <= 0; drawing <= 1; state <= 1; end
                1: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'd0; draw_spi_start <= 1; state <= 2; end end
                2: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'd95; draw_spi_start <= 1; state <= 3; end end
                3: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'h75; draw_spi_start <= 1; state <= 4; end end
                4: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'd0; draw_spi_start <= 1; state <= 5; end end
                5: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'd63; draw_spi_start <= 1; state <= 6; end end
                6: begin draw_spi_start <= 0; if (spi_done) begin draw_dc <= 1; pixel_x <= 0; pixel_y <= 0; state <= 7; end end
                // Write pixel hi/lo
                7: begin draw_spi_data <= rgb_pixel[15:8]; draw_spi_start <= 1; state <= 8; end
                8: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= rgb_pixel[7:0]; draw_spi_start <= 1; state <= 9; end end
                9: begin
                    draw_spi_start <= 0;
                    if (spi_done) begin
                        if (pixel_x < 95) pixel_x <= pixel_x + 1;
                        else begin
                            pixel_x <= 0;
                            if (pixel_y < 63) pixel_y <= pixel_y + 1;
                            else begin
                                pixel_y <= 0;
                                state <= 10; // Done, freeze
                            end
                        end
                        if (state != 10) state <= 7;
                    end
                end
                10: begin
                    // Done, keep display
                end
                default: state <= 0;
            endcase
        end
    end
endmodule

// Simple block letter ROM for "GILBERT", white on black, centered
module gilbert_pixel_rom(
    input [6:0] x,
    input [6:0] y,
    output reg [15:0] rgb
);
    // Each letter 12x24 pixels, 1 pixel spacing, 7 letters: 7*12+6*1 = 90px wide
    // Centered at (3, 20) to (92, 43)
    wire [2:0] letter_idx = (x >= 3 && x < 91) ? (x-3)/13 : 3'd7;
    wire [3:0] lx = (x >= 3 && x < 91) ? (x-3)%13 : 4'd0;
    wire [4:0] ly = (y >= 20 && y < 44) ? (y-20) : 5'd0;
    reg pixel_on;

    always @(*) begin
        // Default background: black
        rgb = 16'h0000;
        pixel_on = 0;

        if (y >= 20 && y < 44 && x >= 3 && x < 91) begin
            case (letter_idx)
                3'd0: begin // G
                    if (lx == 0 || lx == 11 || ly == 0 || ly == 23) pixel_on = 1;
                    if ((ly >= 12 && ly <= 17) && lx >= 6 && lx <= 11) pixel_on = 1;
                end
                3'd1: begin // I
                    if (lx == 5 || ly == 0 || ly == 23) pixel_on = 1;
                end
                3'd2: begin // L
                    if (lx == 0 || ly == 23) pixel_on = 1;
                end
                3'd3: begin // B
                    if (lx == 0 || ly == 0 || ly == 23 || ly == 12 || (lx == 11 && (ly < 12 || ly > 11))) pixel_on = 1;
                end
                3'd4: begin // E
                    if (lx == 0 || ly == 0 || ly == 23 || ly == 12 || (lx == 11 && ly < 12)) pixel_on = 1;
                end
                3'd5: begin // R
                    if (lx == 0 || ly == 0 || ly == 12 || lx == 11 && ly < 12 || (ly > 12 && lx == ly-12)) pixel_on = 1;
                end
                3'd6: begin // T
                    if (ly == 0 || lx == 5) pixel_on = 1;
                end
                default: pixel_on = 0;
            endcase

            if (pixel_on)
                rgb = 16'hFFFF; // White
        end
    end
endmodule

// --- SSD1331 OLED initialization FSM (unchanged) ---
module ssd1331_init (
    input wire clk,
    input wire rst,
    output reg [7:0] spi_data,
    output reg spi_start,
    input wire spi_done,
    output reg dc,
    output reg res_n,
    output reg init_done
);
    parameter S_IDLE     = 3'd0;
    parameter S_RESET    = 3'd1;
    parameter S_WAIT     = 3'd2;
    parameter S_SEND_CMD = 3'd3;
    parameter S_WAIT_SPI = 3'd4;
    parameter S_DONE     = 3'd5;

    reg [2:0] state;
    parameter NUM_CMDS = 37;
    reg [7:0] init_cmds [0:NUM_CMDS-1];
    reg [5:0] cmd_idx;
    reg [19:0] rst_cnt;
    parameter RST_HOLD = 20'd200_000; // 2ms at 100MHz

    initial begin
        init_cmds[0]  = 8'hAE; // Display off
        init_cmds[1]  = 8'hA0; // Set re-map & color depth
        init_cmds[2]  = 8'h72; // RGB color
        init_cmds[3]  = 8'hA1; // Set display start line
        init_cmds[4]  = 8'h00;
        init_cmds[5]  = 8'hA2; // Set display offset
        init_cmds[6]  = 8'h00;
        init_cmds[7]  = 8'hA4; // Normal display
        init_cmds[8]  = 8'hA8; // Set multiplex ratio
        init_cmds[9]  = 8'h3F;
        init_cmds[10] = 8'hAD; // Set master config
        init_cmds[11] = 8'h8E;
        init_cmds[12] = 8'hB0; // Power save
        init_cmds[13] = 8'h0B;
        init_cmds[14] = 8'hB1; // Phase 1 & 2 period
        init_cmds[15] = 8'h31;
        init_cmds[16] = 8'hB3; // Display clock div
        init_cmds[17] = 8'hF0;
        init_cmds[18] = 8'h8A; // Precharge A
        init_cmds[19] = 8'h64;
        init_cmds[20] = 8'h8B; // Precharge B
        init_cmds[21] = 8'h78;
        init_cmds[22] = 8'h8C; // Precharge C
        init_cmds[23] = 8'h64;
        init_cmds[24] = 8'hBB; // Precharge level
        init_cmds[25] = 8'h3A;
        init_cmds[26] = 8'hBE; // VCOMH
        init_cmds[27] = 8'h3E;
        init_cmds[28] = 8'h87; // Master current
        init_cmds[29] = 8'h06;
        init_cmds[30] = 8'h81; // Contrast A (Red)
        init_cmds[31] = 8'h91;
        init_cmds[32] = 8'h82; // Contrast B (Green)
        init_cmds[33] = 8'h50;
        init_cmds[34] = 8'h83; // Contrast C (Blue)
        init_cmds[35] = 8'h7D;
        init_cmds[36] = 8'hAF; // Display ON
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= S_RESET;
            cmd_idx   <= 0;
            spi_start <= 0;
            spi_data  <= 0;
            dc        <= 0;
            res_n     <= 0;
            init_done <= 0;
            rst_cnt   <= 0;
        end else begin
            case (state)
                S_RESET: begin
                    res_n   <= 0;
                    rst_cnt <= rst_cnt + 1;
                    if (rst_cnt > RST_HOLD) begin
                        res_n   <= 1; // Release reset
                        rst_cnt <= 0;
                        state   <= S_WAIT;
                    end
                end
                S_WAIT: begin
                    rst_cnt <= rst_cnt + 1;
                    if (rst_cnt > RST_HOLD) begin
                        rst_cnt <= 0;
                        state   <= S_SEND_CMD;
                    end
                end
                S_SEND_CMD: begin
                    if (cmd_idx < NUM_CMDS) begin
                        spi_data  <= init_cmds[cmd_idx];
                        spi_start <= 1;
                        dc        <= 0;
                        state     <= S_WAIT_SPI;
                    end else begin
                        state     <= S_DONE;
                        init_done <= 1;
                    end
                end
                S_WAIT_SPI: begin
                    spi_start <= 0;
                    if (spi_done) begin
                        cmd_idx <= cmd_idx + 1;
                        state   <= S_SEND_CMD;
                    end
                end
                S_DONE: begin
                    // Stay here
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule

// SPI master with proper 8-bit transfer (Mode 0, SCLK idle low)
module spi_master(
    input clk,
    input rst,
    input [7:0] data_in,
    input start,
    output reg sclk,
    output reg mosi,
    output reg cs,
    output reg done
);
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    reg [1:0] state;
    localparam IDLE=0, LOAD=1, TRANSFER=2, FINISH=3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            sclk <= 0; // Mode 0: idle low
            mosi <= 0;
            cs   <= 1;
            done <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
        end else begin
            case(state)
                IDLE: begin
                    sclk <= 0;
                    cs <= 1;
                    done <= 0;
                    if (start) begin
                        cs <= 0;
                        shift_reg <= data_in;
                        bit_cnt <= 4'd7;
                        state <= LOAD;
                    end                
                end
                LOAD: begin
                    mosi <= shift_reg[7];
                    state <= TRANSFER;
                end
                TRANSFER: begin
                    sclk <= 1;
                    state <= FINISH;
                end
                FINISH: begin
                    sclk <= 0;
                    shift_reg <= {shift_reg[6:0],1'b0};
                    if (bit_cnt == 0) begin
                        cs <= 1;
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        state <= LOAD;
                    end
                end
            endcase
        end
    end
endmodule

