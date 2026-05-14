module full_subtractor_using_half_subtractor(
    input a,
    input b,
    input bin,
    output d,
    output bout
    );
    wire w1,c1,c2;
    half_subtractor HBa (.a(a),.b(b),.d(w1),.bo(c1));
    half_subtractor HBb (.a(w1),.b(bin),.d(d),.bo(c2));
    or or1(bout,c1,c2);
endmodule

