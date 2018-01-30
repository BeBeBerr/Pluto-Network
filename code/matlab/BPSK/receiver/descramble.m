function [ a,Si ] = descramble( a,Si )
for i=1:length(a)
    b(i)=xor(Si(4),Si(7));
    b(i)=xor(b(i),a(i));
    c(i)=a(i);
    a(i)=b(i);
    Si(2:7)=Si(1:6);
    Si(1)=c(i);
end

end
