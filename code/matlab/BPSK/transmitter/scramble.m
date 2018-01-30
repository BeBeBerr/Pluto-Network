%scrambling x^7+x^4+1
function scramble_bits=scramble(scramble_int,data_bits)
A=scramble_int;
for i=1:length(data_bits)
    a=xor(A(4),A(7));
    a=xor(a,data_bits(i));
    data_bits(i)=a;
    A(2:7)=A(1:6);
    A(1)=a;
end
scramble_bits=data_bits;