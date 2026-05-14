module half_subtractor(
    input a,
    input b,
    output d,
    output bo
    );
    assign d=a^b;
    assign bo=(~a)&b;
endmodule

