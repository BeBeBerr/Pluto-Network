function [rStr, crcResult] = bpsk_rx_func(rxdata)
global cyc;
seq_sync = tx_gen_m_seq([1 0 0 0 0 0 1]);
local_sync = tx_modulate(seq_sync, 'BPSK');
rx_signal=rxdata;
%% matched filtering
fir = rcosdesign(1,128,4);
rx_sig_filter = upfirdn(rx_signal,fir,1);
%% normalization
c1=max([abs(real(rx_sig_filter.')),abs(imag(rx_sig_filter.'))]);
rx_sig_norm=rx_sig_filter ./c1;
%% sampling synchronization
[time_error,rx_sig_down]=rx_timing_recovery(rx_sig_norm.');
% rx_sig_down=rx_sig_norm(1:4:end).';
%% package search
[rx_frame,cor_abs,th_max,index_s]=rx_package_search(rx_sig_down,local_sync,703); 
%% coarse freq synchronization
coarse_sync_seq=rx_frame(1:8);
[deltaf1,out_signal1] = rx_freq_sync(coarse_sync_seq,4,rx_frame);
%% first fine freq synchronization
fine_sync_seq_1=out_signal1(1:120);
[deltaf2,out_signal2] = rx_freq_sync(fine_sync_seq_1,2,out_signal1);
%% second fine freq synchronization
fine_sync_seq_2=out_signal2(1:120);
[deltaf3,out_signal3]=rx_freq_sync(fine_sync_seq_2,2,out_signal2);
deltaf=deltaf1+deltaf2+deltaf3;
%% initial phase estimate
[out_signal4,ang]=rx_phase_sync(out_signal3,local_sync);
%% phase track
rx_no_syn_seq=out_signal4(127+1:end);
[out_signal6,phase_curve]=rx_phase_track(rx_no_syn_seq);

%% delete pilot
out_signal7=rx_delete_pilot(out_signal6);
%% time domain equalize
out_signal8=rx_time_equalize(out_signal7);
%% signal demod
[soft_bits_out,evm] = rx_bpsk_demod(out_signal8);
Si=[1 1 0 1 1 0 0];
m=0;
for i=1:length(soft_bits_out)
    [c,Si]=descramble(soft_bits_out(i),Si);
    m=m+1;
    y(m)=c;
end
soft_bits_out=y;
%% crc32 check
ret=crc32(soft_bits_out(1:length(soft_bits_out)-32)).';
crc_bits_32=soft_bits_out(length(soft_bits_out)-31:length(soft_bits_out));
crc_outputs=sum(xor(ret,crc_bits_32),2);

if crc_outputs==0
    crc_32='YES';
    crcResult = 1;
  
%     disp(char(b.'));
%     disp(char(y));
%     disp(char(soft_bits_out(1:end-32)));
else
    crc_32='NO';
    crcResult = 0;
end
  cyc=cyc+1;
    msg=soft_bits_out(1:end-32).';
    w = [128 64 32 16 8 4 2 1];
    Nbits = numel(msg);
    Ny = Nbits/8;
    y = zeros(1,Ny);
    for i = 0:Ny-1
        y(i+1) = w*msg(8*i+(1:8));
    end
    a=[y zeros(1,4)];
    b=reshape(a,64,1);
    %b=reshape(a,16,4);

%% display
%{
%figure(2);clf;
%subplot(231);
plot(real(rx_signal),'r');
hold on;
%plot(imag(rx_signal),'b');
grid on;
title('rx original signal');
%subplot(232);

pwelch(rx_signal,[],[],[],40e6,'centered','psd'); 
%}

% text(0.15,1.0,['帧同步序号：',b.']);

receivedStr = deblank(char(b.'));
rStr = receivedStr;
%{
%disp(receivedStr);
%disp(char(b.'));
% plot(phase_curve);
axis square;
subplot(233);
plot(real(out_signal8),imag(out_signal8),'b*');
title('constellation');
axis([-1.5 1.5 -1.5 1.5]);
axis square;
subplot(234);
plot(phase_curve+pi*2);
title('phae track');
%subplot(235);
text(0.15,1.0,['帧同步序号：',num2str(index_s,5)]);%,'FontSize',12
text(0.15,0.8,['频偏估计值：',num2str(deltaf/1e3,3),'KHz']);
text(0.15,0.6,['调制模式：', 'BPSK']);
text(0.15,0.4,['数据长度：', '500','bytes']);
text(0.15,0.2,['evm：', num2str(evm.*100,3),'%']);
text(0.15,0.0,['crc\_32：', crc_32]);
axis off;
% figure(2)
% plot(cor_abs);
%}
end

