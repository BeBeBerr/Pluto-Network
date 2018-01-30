function seq = tx_gen_m_seq(m_init)
%MSRG（模件抽头型）结构
connections =m_init;
m=length(connections);%移位寄存器的级数
L=2^m-1;%m序列长度
registers=[zeros(1,m-1) 1];%寄存器初始化
seq(1)=registers(m);%m序列的第一位取移位寄存器移位输出的值
for i=2:L,
    new_reg_cont(1)=connections(1)*seq(i-1);%新寄存器的第一位等于连接值乘寄存器最后一位
    for j=2:m,
        new_reg_cont(j)=rem(registers(j-1)+connections(j)*seq(i-1),2);%其他位等于前边的寄存器值加上连接值乘寄存器最后一位
    end
    registers=new_reg_cont;
    seq(i)=registers(m);%经过一次循环寄存器输出一位得到m序列的其他位
end
end

