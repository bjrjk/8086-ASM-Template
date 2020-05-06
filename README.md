# 8086 ASM Template
8086汇编模板。

## Registers Conventions 寄存器约定
`AX`: Caller Save
AX由调用者保存

Others Registers: Callee Save
其他所有寄存器由被调用者保存

## Call Convention 函数调用约定
Parameter Passing Convention: `_stdcall`
传参调用约定为stdcall

程序中除特殊说明之外，所有函数都由栈传递。
参数从右向左压入堆栈，被调用函数执行完毕后，参数由被调用者清理。
返回值统一放在AX中。

寄存器中，BP做帧指针，SP做栈指针。
保护现场后栈中BP及其上有可能的参数存储位置：
`[BP]` -> previous BP ，上一函数的帧指针
`[BP+2]` -> return address，上一函数的返回地址
`[BP+4]` -> first parameter，第一个参数（若有）
`[BP+6]` -> second parameter，第二个参数（若有）
...，第X个，以此类推

程序中典型的读取函数调用参数的语句：
`mov AX,4H[BP]` 将第一个参数放至AX

## Reusable Macro Function 可重用宏
`PUSH_REGS MACRO`
保护除AX返回值、BP帧指针、SP栈指针之外的其他所有寄存器（包括标志寄存器）

`POP_REGS MACRO`
恢复除AX返回值、BP帧指针、SP栈指针之外的其他所有寄存器（包括标志寄存器）

`PROTECT_SITE MACRO`
保护现场

`RESTORE_SITE MACRO POP_BYTES`
恢复现场并清栈中的调用参数POP_BYTES字节

