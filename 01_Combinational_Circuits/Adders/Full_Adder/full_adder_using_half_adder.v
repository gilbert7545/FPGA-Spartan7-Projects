module full_adder_using_half_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
    );
    wire sum1,carry1,carry2;
    half_adder HAa (.a(a),.b(b),.sum(sum1),.carry(carry1));
    half_adder HAb (.a(sum1),.b(cin),.sum(sum),.carry(carry2));
    or or1(cout,carry1,carry2);
endmodule



