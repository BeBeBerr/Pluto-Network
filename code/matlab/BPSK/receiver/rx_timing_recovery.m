function [time_error,iq] = rx_timing_recovery(signal)

N=ceil((length(signal))/4);
Ns=4*N;                         %�ܵĲ�������

bt=2e-2/1.3;
c1=8/3*bt;
c2=32/9*bt*bt;
w=[0.5,zeros(1,N-1)];           %��·�˲�������Ĵ�������ֵ��Ϊ0.5
n=[0.9,zeros(1,Ns-1)];          %NCO�Ĵ�������ֵ��Ϊ0.9
n_temp=[n(1),zeros(1,Ns-1)]; 
u=[0.6,zeros(1,2*N-1)];         %NCO����Ķ�ʱ��������Ĵ�������ֵ��Ϊ0.6
out_signal_I=zeros(1,2*N);      %I·�ڲ���������� 
out_signal_Q=zeros(1,2*N);      %Q·�ڲ����������
time_error=zeros(1,N);          %Gardner��ȡ��ʱ�����Ĵ���

ik=time_error;
qk=time_error;

k=1;                            %������ʾTiʱ�����,ָʾu,yI,yQ
ms=1;                           %����ָʾT��ʱ�����,����ָʾa,b�Լ�w
strobe=zeros(1,Ns);
aI=real(signal);
bQ=imag(signal);
ns=length(aI)-1;
i=1;
while(i<ns)
    n_temp(i+1)=n(i)-w(ms);
    if(n_temp(i+1)>0)
        n(i+1)=n_temp(i+1);
    else
        n(i+1)=mod(n_temp(i+1),1);
        %�ڲ��˲���ģ��
        FI1=0.5*aI(i+2)-0.5*aI(i+1)-0.5*aI(i)+0.5*aI(i-1);
        FI2=1.5*aI(i+1)-0.5*aI(i+2)-0.5*aI(i)-0.5*aI(i-1);
        FI3=aI(i);
        out_signal_I(k)=(FI1*u(k)+FI2)*u(k)+FI3;
        
        FQ1=0.5*bQ(i+2)-0.5*bQ(i+1)-0.5*bQ(i)+0.5*bQ(i-1);
        FQ2=1.5*bQ(i+1)-0.5*bQ(i+2)-0.5*bQ(i)-0.5*bQ(i-1);
        FQ3=bQ(i);
        out_signal_Q(k)=(FQ1*u(k)+FQ2)*u(k)+FQ3;
        
        strobe(k)=mod(k,2);
        %ʱ�������ȡģ�飬���õ���Gardner�㷨
        if(strobe(k)==0)
            %ȡ����ֵ����
            ik(ms)=out_signal_I(k);
            qk(ms)=out_signal_Q(k);
            %ÿ�����ݷ��ż���һ��ʱ�����
            if(k>2)
               Ia=(out_signal_I(k)+out_signal_I(k-2))/2;
               Qa=(out_signal_Q(k)+out_signal_Q(k-2))/2;
               time_error(ms)=[out_signal_I(k-1)-Ia]*(out_signal_I(k)-out_signal_I(k-2))+[out_signal_Q(k-1)-Qa]*(out_signal_Q(k)-out_signal_Q(k-2));
            else
               time_error(ms)=(out_signal_I(k-1)*out_signal_I(k)+out_signal_Q(k-1)*out_signal_Q(k));
            end
            %��·�˲���,ÿ�����ݷ��ż���һ�λ�·�˲������
            if(ms>1)
                w(ms+1)=w(ms)+c1*(time_error(ms)-time_error(ms-1))+c2*time_error(ms-1);
            else
                w(ms+1)=w(ms)+c1*time_error(ms)+c2*time_error(ms);
            end
            ms=ms+1;
        end
        k=k+1;
        u(k)=n(i)/w(ms);
    end
    i=i+1;
end

iq=ik+1i*qk;
c1=max([abs(real(iq)),abs(imag(iq))]);
iq=iq ./c1;


% figure(1);
% subplot(311);
% plot(u);
% xlabel('�������');
% ylabel('�������');
% grid on;
% subplot(312);
% plot(time_error);
% xlabel('�������');
% ylabel('��ʱ���');
% grid on;
% subplot(313);
% plot(w);
% xlabel('�������');
% ylabel('��·�˲������');
% grid on;

end