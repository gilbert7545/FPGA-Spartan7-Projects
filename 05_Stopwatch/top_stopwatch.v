//Design 1
module stopwatch(
    input wire clk_1Hz,
    input wire reset,
    input wire stop,
    output reg [7:0] count
);
    always @(posedge clk_1Hz or posedge reset) begin
        if (reset)
            count <= 8'd0;
        else if (!stop) begin
            if (count == 8'd99)
                count <= 8'd0;
            else
                count <= count + 1;
        end
    end
endmodule

//Design 2
module clk_divider(
    input wire clk_100MHz,
    input wire reset,
    output reg clk_1Hz
);
    reg [26:0] counter; // Enough bits to count 100 million cycles

    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_1Hz <= 0;
        end else if (counter == 50_000_000 - 1) begin
            counter <= 0;
            clk_1Hz <= ~clk_1Hz;
        end else
            counter <= counter + 1;
    end
endmodule

//Design 3
module bcd_to_7seg(
    input wire [3:0] bcd,
    output reg [6:0] seg
);
    always @(*) begin
        case (bcd)
            4'd0: seg = 7'b0000001;
            4'd1: seg = 7'b1001111;
            4'd2: seg = 7'b0010010;
            4'd3: seg = 7'b0000110;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100100;
            4'd6: seg = 7'b0100000;
            4'd7: seg = 7'b0001111;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0000100;
            default: seg = 7'b1111111;
        endcase
    end
endmodule

//Design 4
module top_module(
    input wire clk_100MHz,
    input wire reset,
    input wire stop,
    output wire q,
    output wire t,
    output wire r,
    output wire x,
    output wire y,
    output wire z,
    output wire [6:0] seg_ones,
    output wire [6:0] seg_tens
);
  assign q=1;
  assign t=1;
  assign r=1;
  assign x=1;
  assign y=1;
  assign z=1;

    wire clk_1Hz;
    wire [7:0] count;

    // Clock divider
    clk_divider u_clk_div (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .clk_1Hz(clk_1Hz)
    );

    // Stopwatch logic
    stopwatch u_watch (
        .clk_1Hz(clk_1Hz),
        .reset(reset),
        .stop(stop),
        .count(count)
    );

    wire [3:0] ones;
    wire [3:0] tens;

    assign ones = count % 10;
    assign tens = count / 10;

    // Decode to 7-segment
    bcd_to_7seg u_seg0 (.bcd(ones), .seg(seg_ones));
    bcd_to_7seg u_seg1 (.bcd(tens), .seg(seg_tens));
endmodule

