module oled_traffic_light(
    input clk_100MHz,
    input rst,
    input [3:0] row,
    output [3:0] col,
    // OLED SSD1331
    output sclk,
    output mosi,
    output cs,
    output dc,
    output res_n,
    output vccen,
    output pmoden,
    // 7-segment
    output [3:0] an_timer,   // Left display anodes (active low)
    output [6:0] seg_timer,  // Left display segments (active low)
    output [3:0] an_count,   // Right display anodes (active low)
    output [6:0] seg_count   // Right display segments (active low)
);

    // 1kHz scan clock for 7-segment (approx. 1ms per digit)
    wire clk_1kHz;
    clk_divider div (
        .clk_100MHz(clk_100MHz),
        .reset(rst),
        .clk_1kHz(clk_1kHz)
    );

    // Keypad
    wire [3:0] key;
    wire key_valid;
    keypad_scanner scanner (
        .clk(clk_1kHz),
        .rst(rst),
        .row(row),
        .col(col),
        .key(key),
        .key_valid(key_valid)
    );

    // ---------- Vehicle Count from Keypad ----------
    reg [3:0] vehicle_count;
    reg prev_key_valid;
    wire green_phase_reset;

    always @(posedge clk_100MHz or posedge rst) begin
        if (rst) begin
            vehicle_count <= 0;
            prev_key_valid <= 0;
        end else begin
            if (green_phase_reset)
                vehicle_count <= 0;
            else if (key_valid && !prev_key_valid)
                vehicle_count <= key; // Set to value of key pressed!
            prev_key_valid <= key_valid;
        end
    end

    // ---------- Traffic Light FSM ----------
    wire [1:0] light_state;
    wire [13:0] timer_val;
    traffic_light_fsm_dynamic fsm(
        .clk(clk_100MHz),
        .rst(rst),
        .vehicle_count(vehicle_count),
        .light_state(light_state),
        .time_left(timer_val),
        .green_phase_reset(green_phase_reset)
    );

    // ---------- Timer Display (4-digit multiplexed) ----------
    sevenseg_timer_mux timer_mux(
        .clk(clk_1kHz),
        .rst(rst),
        .timer(timer_val),
        .an_timer(an_timer),
        .seg_timer(seg_timer)
    );

    // ---------- Vehicle Count Display (single digit, no multiplex) ----------
    assign an_count = 4'b1110; // Only rightmost digit is active (an_count[0] low)
    decoder dec_count(
        .hex(vehicle_count),
        .seg(seg_count)
    );

    // OLED SSD1331 + SPI + Drawing FSM (unchanged)
    wire spi_done, spi_start, init_done;
    wire [7:0] spi_data;
    wire sclk_int, mosi_int, cs_int, dc_init, res_n_init;
    wire [15:0] rgb_pixel;
    reg [7:0] draw_spi_data;
    reg draw_spi_start = 0, draw_dc = 0, drawing = 0;
    reg [6:0] pixel_x = 0, pixel_y = 0;
    reg [3:0] draw_state = 0;
    reg [1:0] light_state_d;
    wire state_change = (light_state != light_state_d);

    assign sclk   = sclk_int;
    assign mosi   = mosi_int;
    assign cs     = cs_int;
    assign dc     = drawing ? draw_dc : dc_init;
    assign res_n  = res_n_init;
    assign vccen  = 1'b1;
    assign pmoden = 1'b1;

    ssd1331_init oled_init (
        .clk(clk_100MHz),
        .rst(rst),
        .spi_data(spi_data),
        .spi_start(spi_start),
        .spi_done(spi_done),
        .dc(dc_init),
        .res_n(res_n_init),
        .init_done(init_done)
    );

    spi_master spi (
        .clk(clk_100MHz),
        .rst(rst),
        .data_in(drawing ? draw_spi_data : spi_data),
        .start(drawing ? draw_spi_start : spi_start),
        .sclk(sclk_int),
        .mosi(mosi_int),
        .cs(cs_int),
        .done(spi_done)
    );

    traffic_light_pixel_rom light_rom(
        .x(pixel_x),
        .y(pixel_y),
        .light_sel(light_state),
        .rgb(rgb_pixel)
    );

    always @(posedge clk_100MHz or posedge rst) begin
        if (rst) begin
            draw_state <= 0;
            drawing <= 0;
            draw_spi_start <= 0;
            pixel_x <= 0;
            pixel_y <= 0;
            light_state_d <= 0;
        end else if (init_done) begin
            light_state_d <= light_state;
            case (draw_state)
                0: begin draw_spi_data <= 8'h15; draw_spi_start <= 1; draw_dc <= 0; drawing <= 1; draw_state <= 1; end
                1: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'd0; draw_spi_start <= 1; draw_state <= 2; end end
                2: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'd95; draw_spi_start <= 1; draw_state <= 3; end end
                3: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'h75; draw_spi_start <= 1; draw_state <= 4; end end
                4: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'd0; draw_spi_start <= 1; draw_state <= 5; end end
                5: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= 8'd63; draw_spi_start <= 1; draw_state <= 6; end end
                6: begin draw_spi_start <= 0; if (spi_done) begin draw_dc <= 1; pixel_x <= 0; pixel_y <= 0; draw_state <= 7; end end
                7: begin draw_spi_data <= rgb_pixel[15:8]; draw_spi_start <= 1; draw_state <= 8; end
                8: begin draw_spi_start <= 0; if (spi_done) begin draw_spi_data <= rgb_pixel[7:0]; draw_spi_start <= 1; draw_state <= 9; end end
                9: begin
                    draw_spi_start <= 0;
                    if (spi_done) begin
                        if (pixel_x < 95) pixel_x <= pixel_x + 1;
                        else begin
                            pixel_x <= 0;
                            if (pixel_y < 63) pixel_y <= pixel_y + 1;
                            else begin
                                pixel_y <= 0;
                                draw_state <= 10; // Done, wait for change
                            end
                        end
                        if (draw_state != 10) draw_state <= 7;
                    end
                end
                10: begin
                    if (state_change) draw_state <= 6;
                end
                default: draw_state <= 0;
            endcase
        end
    end
endmodule

// Timer multiplexer: 4-digit, active low anode, active low cathode
module sevenseg_timer_mux(
    input clk,
    input rst,
    input [13:0] timer,         // up to 9999
    output reg [3:0] an_timer,
    output reg [6:0] seg_timer
);
    reg [1:0] scan_cnt = 0;
    wire [3:0] timer_thousands = (timer / 1000) % 10;
    wire [3:0] timer_hundreds  = (timer / 100) % 10;
    wire [3:0] timer_tens      = (timer / 10) % 10;
    wire [3:0] timer_ones      = timer % 10;

    reg [3:0] digit_timer;
    wire [6:0] seg_timer_out;
    decoder dec_timer(digit_timer, seg_timer_out);

    always @(posedge clk or posedge rst) begin
        if (rst)
            scan_cnt <= 0;
        else
            scan_cnt <= scan_cnt + 1;
    end

    always @(*) begin
        an_timer = 4'b1111;
        case (scan_cnt)
            2'd0: begin an_timer = 4'b1110; digit_timer = timer_ones;      end // rightmost
            2'd1: begin an_timer = 4'b1101; digit_timer = timer_tens;      end
            2'd2: begin an_timer = 4'b1011; digit_timer = timer_hundreds;  end
            2'd3: begin an_timer = 4'b0111; digit_timer = timer_thousands; end // leftmost
        endcase
        seg_timer = seg_timer_out;
    end
endmodule

module decoder(
    input [3:0] hex,
    output reg [6:0] seg
);
    always @(*) begin
        case (hex)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule

// ... clk_divider, keypad_scanner, traffic_light_fsm_dynamic, traffic_light_pixel_rom, ssd1331_init, spi_master as before ...

// 1kHz clock divider from 100MHz
module clk_divider(
    input wire clk_100MHz,
    input wire reset,
    output reg clk_1kHz
);
    reg [16:0] count;
    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            count <= 0;
            clk_1kHz <= 0;
        end else if (count == 17'd49_999) begin
            clk_1kHz <= ~clk_1kHz;
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end
endmodule

// Keypad scanner: outputs key and key_valid
module keypad_scanner(
    input clk,
    input rst,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key,
    output reg key_valid
);
    reg [1:0] col_index;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            col_index <= 0;
            col <= 4'b1110;
        end else begin
            col_index <= col_index + 1;
            col <= ~(4'b0001 << col_index);
        end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key <= 0;
            key_valid <= 0;
        end else begin
            key_valid <= 0;
            case (~col)
                4'b0001: begin
                    if (!row[0]) begin key <= 4'h1; key_valid <= 1; end
                    else if (!row[1]) begin key <= 4'h4; key_valid <= 1; end
                    else if (!row[2]) begin key <= 4'h7; key_valid <= 1; end
                    else if (!row[3]) begin key <= 4'h0; key_valid <= 1; end
                end
                4'b0010: begin
                    if (!row[0]) begin key <= 4'h2; key_valid <= 1; end
                    else if (!row[1]) begin key <= 4'h5; key_valid <= 1; end
                    else if (!row[2]) begin key <= 4'h8; key_valid <= 1; end
                    else if (!row[3]) begin key <= 4'hF; key_valid <= 1; end
                end
                4'b0100: begin
                    if (!row[0]) begin key <= 4'h3; key_valid <= 1; end
                    else if (!row[1]) begin key <= 4'h6; key_valid <= 1; end
                    else if (!row[2]) begin key <= 4'h9; key_valid <= 1; end
                    else if (!row[3]) begin key <= 4'hE; key_valid <= 1; end
                end
                4'b1000: begin
                    if (!row[0]) begin key <= 4'hA; key_valid <= 1; end
                    else if (!row[1]) begin key <= 4'hB; key_valid <= 1; end
                    else if (!row[2]) begin key <= 4'hC; key_valid <= 1; end
                    else if (!row[3]) begin key <= 4'hD; key_valid <= 1; end
                end
            endcase
        end
    end
endmodule
module traffic_light_fsm_dynamic #(
    parameter CNT_1S = 100_000_000  // Number of clock cycles per second (default: 100 MHz)
)(
    input clk,
    input rst,
    input [3:0] vehicle_count,
    output reg [1:0] light_state, // 0=RED, 1=YELLOW, 2=GREEN
    output reg [13:0] time_left,
    output reg green_phase_reset
);
    reg [31:0] cnt;
    reg [1:0] state, next_state;
    reg [13:0] green_duration, next_green_duration;
    reg [13:0] phase_duration;

    localparam RED_DURATION    = 16; // seconds
    localparam YELLOW_DURATION = 11; // seconds
    localparam GREEN_SHORT     = 24; // 23 to 0 (24s)
    localparam GREEN_LONG      = 31; // 30 to 0 (31s)

    // Combinational logic for next state and timing
    always @(*) begin
        next_state = state;
        next_green_duration = green_duration;
        case (state)
            0: begin // RED
                phase_duration = RED_DURATION;
                if (cnt >= (RED_DURATION * CNT_1S) - 1)
                    next_state = 1;
            end
            1: begin // YELLOW
                phase_duration = YELLOW_DURATION;
                if (cnt >= (YELLOW_DURATION * CNT_1S) - 1) begin
                    next_state = 2;
                    if (vehicle_count > 5)
                        next_green_duration = GREEN_LONG;
                    else
                        next_green_duration = GREEN_SHORT;
                end
            end
            2: begin // GREEN
                phase_duration = green_duration;
                if (cnt >= (green_duration * CNT_1S) - 1)
                    next_state = 0;
            end
            default: phase_duration = RED_DURATION;
        endcase
    end

    // Sequential logic for state progression, timer, and outputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            cnt <= 0;
            green_duration <= GREEN_SHORT;
            time_left <= RED_DURATION - 1;
            green_phase_reset <= 0;
        end else begin
            green_phase_reset <= 0;
            if (state != next_state) begin
                cnt <= 0;
                // Latch new green_duration just BEFORE entering green
                if (next_state == 2)
                    green_duration <= next_green_duration;
                // Signal green_phase_reset just AFTER leaving green
                if (state == 2 && next_state == 0)
                    green_phase_reset <= 1;
                state <= next_state;
            end else begin
                cnt <= cnt + 1;
            end

            light_state <= state;
            if (cnt < (phase_duration * CNT_1S))
                time_left <= (phase_duration - 1) - (cnt / CNT_1S);
            else
                time_left <= 0;
        end
    end
endmodule
module traffic_light_pixel_rom(
    input [6:0] x,
    input [6:0] y,
    input [1:0] light_sel,
    output reg [15:0] rgb
);
    localparam BLACK  = 16'h0000;
    localparam WHITE  = 16'hFFFF;
    localparam GRAY   = 16'h8410;
    localparam RED    = 16'hF800;
    localparam YELLOW = 16'hFFE0;
    localparam GREEN  = 16'h07E0;
    localparam BKG    = 16'h3186;
    localparam integer radius = 6;
    localparam integer cy = 32;
    integer dx, dy, dist2;
    always @(*) begin
        rgb = BKG;
        // Rectangle box
        if (x >= 24 && x <= 72 && y >= 22 && y <= 43) begin
            if (x == 24 || x == 72 || y == 22 || y == 43)
                rgb = BLACK;
            else begin
                // Circle 0 (left)
                dx = x - 34; dy = y - cy; dist2 = dx*dx + dy*dy;
                if (dist2 < radius*radius) begin
                    rgb = (light_sel == 0) ? RED : GRAY;
                end
                // Circle 1 (middle)
                dx = x - 48; dy = y - cy; dist2 = dx*dx + dy*dy;
                if (dist2 < radius*radius) begin
                    rgb = (light_sel == 1) ? YELLOW : GRAY;
                end
                // Circle 2 (right)
                dx = x - 62; dy = y - cy; dist2 = dx*dx + dy*dy;
                if (dist2 < radius*radius) begin
                    rgb = (light_sel == 2) ? GREEN : GRAY;
                end
                // If not in any circle, fill black
                if (
                    !((x-34)*(x-34)+(y-cy)*(y-cy)<radius*radius) &&
                    !((x-48)*(x-48)+(y-cy)*(y-cy)<radius*radius) &&
                    !((x-62)*(x-62)+(y-cy)*(y-cy)<radius*radius)
                ) rgb = BLACK;
            end
        end
    end
endmodule

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


