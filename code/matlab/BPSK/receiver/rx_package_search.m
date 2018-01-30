function [out_signal,cor_abs,bo,index_s] = rx_package_search(signal,local_sync,len_frame)

signali=(real(signal)>0)*2-1;
signalq=(imag(signal)>0)*2-1;
signalo=signali+1i*signalq;

L=length(signal);
N=length(local_sync);

for i=N:L
    cor_abs(i)=abs(signalo(i-N+1:i)*local_sync');
end
[~,bo]=max(cor_abs(1:length(cor_abs)/2));

index_s=bo-N+1;
index_e=index_s+len_frame-1;
out_signal=signal(index_s:index_e);
end

