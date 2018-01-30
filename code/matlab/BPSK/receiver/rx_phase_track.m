function [signal,phase_curve] = rx_phase_track(signal)

% local_pilot=ones(1,4)-2;
local_pilot=[1 -1 1 -1 -1 1 -1 1];
% local_pilot=[1 -1 1 -1 -1 1 -1 1];
idx=0;
N=64+8;
phase_curve=0;
for i=1:N:length(signal)-N
    temp=signal(i:(i+N-1));
%     rx_pilot=temp(N-7:end);
    rx_pilot = temp(1:8);
    [~,ang]=rx_phase_sync(rx_pilot,local_pilot);
    idx=idx+1;
    phase_curve(idx)=ang;
    signal(i:end)=signal(i:end).*exp(-1i*ang);
end
