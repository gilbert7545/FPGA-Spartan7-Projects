module full_subtractor(
       input a,
       input b,
       input bin,
       output sub,
       output bout
    );
    assign sub=a^b^bin;
    assign bout=~a&(b^bin)|(b&bin);
endmodule

