function out_signal = rx_channel_est(signal,uw)
%   MMSE频域均衡函数
%   输入序列x为去掉CP后的接受序列，设其长度为L;
%   uw为系统中使用的独特字序列,长度为uw_num;
%   输出序列y为经过FDE后的输出序列,长度为L-uw_num。
%
L = size(signal,2);                          %求输入序列的长度;
uw_num = size(uw,2);                    %求独特字的长度;
sigstmp(1,:) = signal(1,(uw_num+1):end);     %提取数据信息流;
uwstmp(1,:) = signal(1,1:uw_num);            %提取独特字序列;
H = fft(uwstmp)./fft(uw);
h = ifft(H);
u = [h,zeros(1,L-2*uw_num)];
U = fft(u);  
W = conj(U)./(U.*conj(U));
Sig = fft(sigstmp);
Y = W.*Sig;
out_signal = ifft(Y);

end
