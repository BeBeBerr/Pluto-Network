function inf_bits=tx_prbs15(packetlength)
h1=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
for i=1:packetlength*8-32
h2(i)=h1(15);
a=xor(h1(15),h1(14));
h1(2:15)=h1(1:14);
h1(1)=a;
end
ret=crc32(h2);
inf_bits=[h2 ret.'];
end
