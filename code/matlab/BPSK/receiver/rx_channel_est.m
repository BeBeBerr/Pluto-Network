function out_signal = rx_channel_est(signal,uw)
%   MMSEƵ����⺯��
%   ��������xΪȥ��CP��Ľ������У����䳤��ΪL;
%   uwΪϵͳ��ʹ�õĶ���������,����Ϊuw_num;
%   �������yΪ����FDE����������,����ΪL-uw_num��
%
L = size(signal,2);                          %���������еĳ���;
uw_num = size(uw,2);                    %������ֵĳ���;
sigstmp(1,:) = signal(1,(uw_num+1):end);     %��ȡ������Ϣ��;
uwstmp(1,:) = signal(1,1:uw_num);            %��ȡ����������;
H = fft(uwstmp)./fft(uw);
h = ifft(H);
u = [h,zeros(1,L-2*uw_num)];
U = fft(u);  
W = conj(U)./(U.*conj(U));
Sig = fft(sigstmp);
Y = W.*Sig;
out_signal = ifft(Y);

end
