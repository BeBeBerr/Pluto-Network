function out_signal = rx_time_equalize(signal)
signal=[zeros(1,13) signal zeros(1,5)];
N=length(signal);
M=10;                   %�������Ľ���
W=zeros(M+1,1);         %��ʼ����ͷϵ��
W(ceil(((M+1)/2)))=1;   %��ʼ��
U=1e-3;                 %������������
Y1=zeros(M+1,1);
e=zeros(1,(N-M));       %��ʼ�����
R1=1;
R2=1;
for mmm=1:4
    for n=1:(N-M)
        Y1=signal(n+M:-1:n).';
        YK(n)=W.'*Y1;   %�����������
        YI=real(YK(n));
        YQ=imag(YK(n));
        EI=YI*(YI^2-R1);
        EQ=YQ*(YQ^2-R2);
        e(n)=EI+EQ*sqrt(-1);
        W=W-U*e(n)*conj(Y1);%���ڳ�ͷϵ��
    end
end 
out_signal=YK(9:end);
end