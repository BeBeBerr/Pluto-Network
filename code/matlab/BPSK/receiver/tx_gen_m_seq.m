function seq = tx_gen_m_seq(m_init)
%MSRG��ģ����ͷ�ͣ��ṹ
connections =m_init;
m=length(connections);%��λ�Ĵ����ļ���
L=2^m-1;%m���г���
registers=[zeros(1,m-1) 1];%�Ĵ�����ʼ��
seq(1)=registers(m);%m���еĵ�һλȡ��λ�Ĵ�����λ�����ֵ
for i=2:L,
    new_reg_cont(1)=connections(1)*seq(i-1);%�¼Ĵ����ĵ�һλ��������ֵ�˼Ĵ������һλ
    for j=2:m,
        new_reg_cont(j)=rem(registers(j-1)+connections(j)*seq(i-1),2);%����λ����ǰ�ߵļĴ���ֵ��������ֵ�˼Ĵ������һλ
    end
    registers=new_reg_cont;
    seq(i)=registers(m);%����һ��ѭ���Ĵ������һλ�õ�m���е�����λ
end
end

