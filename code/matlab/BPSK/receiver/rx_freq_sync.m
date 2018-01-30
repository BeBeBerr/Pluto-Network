function [deltaf,out_signal] = rx_freq_sync(sync_samples,Num,samples_package)

Tchip=1/10000000;

len=length(samples_package);

N=length(sync_samples)/Num;
L0=length(sync_samples);

zr=sync_samples.^2;

for m=1:N
    r0(m)=mean(zr(1+m:L0).*conj(zr(1:L0-m)));
end
deltaf=angle(sum(r0))/(pi*(N+1)*Tchip)/2;
freq_offset=deltaf;
out_signal=samples_package(1:end).*exp(-1i*2*pi*freq_offset*(1:len)*Tchip);

end

