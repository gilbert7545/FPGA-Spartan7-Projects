module four_bit_adder(
 input a0,
    input a1,
    input a2,
    input a3,
    input b0,
    input b1,
    input b2,
    input b3,
    output s0,
    output s1,
    output s2,
    output s3,
    output cout
    );
    wire c1,c2,c3;
    full_adder f1(.A(a0),.B(b0),.Cin(c0),.sum(s0),.cout(c1));
    full_adder f2(.A(a1),.B(b1),.Cin(c1),.sum(s1),.cout(c2));
    full_adder f3(.A(a2),.B(b2),.Cin(c2),.sum(s2),.cout(c3));
    full_adder f4(.A(a3),.B(b3),.Cin(c3),.sum(s3),.cout(cout));
endmodule

