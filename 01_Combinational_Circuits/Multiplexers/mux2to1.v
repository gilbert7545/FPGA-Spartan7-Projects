module mux2to1(
    input s,
    input a,
    input b,
    output y
    );
    assign y=(a&(~s))|(b&s);
endmodule

