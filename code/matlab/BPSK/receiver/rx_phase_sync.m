function [out_signal,ang] = rx_phase_sync(signal_freq_sync,local_seq)

len=length(local_seq);
L=len;
for i=1:L-1
    cor(i)=signal_freq_sync(i).*conj(local_seq(L-i));
end

ang=angle(mean(cor))-pi;

out_signal=signal_freq_sync.*exp(-1i*ang);

end

