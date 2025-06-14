# 程序目的：模拟一个包含循环和后续算术溢出 (Ovf) 异常的程序。
# MIPS Ovf 异常的 ExcCode 是 12。

.set noreorder         # 确保汇编器不会重排指令顺序
.text                  # 文本段（代码段）
.globl __start          # 定义全局入口点 __start

__start:
        # 假设 __start 位于一个已知的基地址，例如在仿真中为 0xBFC00000

        # 初始化循环计数器 $s0 和累加器 $s1
        # PC: 基地址 + 0
  addiu $s0, $zero, 3   # $s0 = 3 (循环次数)
                        # 机器码: 0x24100003 ($s0 是寄存器 16)
        # PC: 基地址 + 4
  addiu $s1, $zero, 0   # $s1 = 0 (累加和初始化)
                        # 机器码: 0x24110000 ($s1 是寄存器 17)

loop_start:             # 循环开始标签
        # PC: 基地址 + 8 (第一次循环时)
  addu $s1, $s1, $s0    # $s1 = $s1 + $s0 (使用 addu 避免在此处溢出)
                        # 机器码: 0x02308821 (rs=$s1, rt=$s0, rd=$s1, funct=0x21)
        # PC: 基地址 + 12
  addiu $s0, $s0, -1    # $s0 = $s0 - 1 (计数器递减)
                        # 机器码: 0x2610FFFF (-1 的16位立即数表示为 0xFFFF)
        # PC: 基地址 + 16
  bgtz $s0, loop_start  # 如果 $s0 > 0, 跳转到 loop_start
                        # 目标地址: loop_start (基地址 + 8)
                        # 当前 PC+4: (基地址 + 16) + 4 = 基地址 + 20
                        # 偏移量 = ( (基地址 + 8) - (基地址 + 20) ) / 4 = -12 / 4 = -3
                        # 机器码: 0x1E00FFFD ($s0 > $zero 分支, -3 的16位立即数表示为 0xFFFD)
        # PC: 基地址 + 20
  nop                   # 分支延迟槽
                        # 机器码: 0x00000000

        # 循环结束后，$s1 的值将是 3 + 2 + 1 = 6
        # 现在准备触发溢出

        # PC: 基地址 + 24
  lui  $t0, 0x7FFF      # 装载立即数高位: $t0 = 0x7FFF0000
                        # 机器码: 0x3c087fff ($t0 是寄存器 8)
        # PC: 基地址 + 28
  ori  $t0, $t0, 0xFFFF # 立即数或操作: $t0 = 0x7FFFFFFF (有符号整型的最大正数)
                        # 机器码: 0x3508ffff
        # PC: 基地址 + 32
  addiu $t1, $zero, 1   # 无符号立即数加法: $t1 = 1
                        # 机器码: 0x24090001 ($t1 是寄存器 9)

        # PC: 基地址 + 36
  add  $t2, $t0, $t1    # 加法: $t2 = $t0 + $t1
                        # 0x7FFFFFFF + 1 = 0x80000000. 这将导致一个溢出。
                        # EPC 应该是这条指令的地址。
                        # 机器码: 0x01095020 ($t2 是寄存器 10, rs=$t0, rt=$t1, add指令的funct字段是0x20)

        # PC: 基地址 + 40
  nop                   # 空操作。如果异常被及时处理，这条指令理想情况下不应完成执行。
                        # 机器码: 0x00000000

        # 异常发生点之后的无限循环
end_loop:
        # PC: 基地址 + 44
  b end_loop            # 跳转到自身
                        # 机器码: 0x0400FFFF (beq $0, $0, -1 相对于 PC+4)
        # PC: 基地址 + 48
  nop                   # 分支延迟槽
                        # 机器码: 0x00000000

.set reorder
