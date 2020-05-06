PUSH_REGS MACRO
	pushf
	push BX
	push CX
	push DX
	push SI
	push DI
ENDM

POP_REGS MACRO
	pop DI
	pop SI
	pop DX
	pop CX
	pop BX
	popf
ENDM

PROTECT_SITE MACRO
	push BP
	mov BP,SP
	PUSH_REGS
ENDM

RESTORE_SITE MACRO POP_BYTES
	POP_REGS
	mov SP,BP
	pop BP
	ret POP_BYTES
ENDM

data segment
	num2ASCII DB 30H,31H,32H,33H,34H,35H,36H,37H,38H,39H
	ASCII2Num DB 30H Dup('$')
		DB 0H,1H,2H,3H,4H,5H,6H,7H,8H,9H
		DB 7H Dup('$')
		DB 0AH,0BH,0CH,0DH,0EH,0FH
		DB 26 Dup('$')
		DB 0AH,0BH,0CH,0DH,0EH,0FH
		DB 25 Dup('$')
	str1 DB 200H Dup('$')
	str2 DB 200H Dup('$')
	num1 DW 0
	num2 DW 0
	arr DW 200H Dup(0)
	promptInput DB 'Input: $'
	promptOutput DB 'Output: $'
	promptError DB 'Error, Input Again: $'
data ends

stack segment para stack
	DB 1000H Dup(204)
stack ends

code segment
	assume cs:code,ds:data,ss:stack

; 基本输入输出函数

printChar PROC
	; void printChar(char ASCIICode)
	; 通过2号DOS系统调用打印一个字符
	PROTECT_SITE
	mov AX,4H[BP]
	mov DL,AL
	mov AH,02h
	int 21h
	RESTORE_SITE 2
printChar ENDP
	
printLn PROC
	; void printLn(void)
	; 实现打印换行功能
	mov AX,000DH
	push AX
	call printChar
	mov AX,000AH
	push AX
	call printChar
	ret
printLn ENDP

printStr PROC
	; void printStr(char * strAddress)
	; 通过9号DOS系统调用输出一个字符串，字符串必须在数据段DS中
	PROTECT_SITE
	mov DX,4H[BP]
	mov AH,09h
	int 21h
	RESTORE_SITE 2
printStr ENDP

printDigit PROC
	; void printDigit(int16 x)
	; 打印1位十进制数字的ASCII码
	PROTECT_SITE
	lea BX,num2ASCII
	mov SI,4H[BP]
	mov AX,[BX][SI]
	push AX
	call printChar
	RESTORE_SITE 2
printDigit ENDP

printInt PROC
	; void printInt(int16 x)
	; 打印整数x
	PROTECT_SITE
	mov AX,4H[BP]
	mov BX,10
	mov CX,0
lp1:
	mov DX,0
	div BX
	push DX
	inc CX
	test AX,AX
	jnz lp1
lp2:
	call printDigit
	loop lp2
	
	RESTORE_SITE 2
printInt ENDP

printBinaryInt PROC
	; void printBinaryInt(int16 x)
	; 打印数字的二进制形式
	PROTECT_SITE
	mov AX,4H[BP]
	mov BX,2
	mov CX,0
lp1:
	mov DX,0
	div BX
	push DX
	inc CX
	test AX,AX
	jnz lp1
lp2:
	call printDigit
	loop lp2
	
	RESTORE_SITE 2
printBinaryInt ENDP

printDivResult PROC
	; void printDivResult(int16 dividend,int16 divisor)
	; 打印保留一位小数的除法结果：dividend/divisor
	PROTECT_SITE
	mov AX,4[BP]	; Calculate integer part
	mov DX,0
	mov SI,6[BP]
	div SI
	push AX
	call printInt
	mov AX,'.' ; Print period
	push AX
	call printChar
	mov AX,DX ; Calculate decimal part
	mov SI,10 ;把余数乘10
	mul SI
	mov SI,6[BP]
	div SI
	push AX
	call printInt ;打印小数
	RESTORE_SITE 4
printDivResult ENDP

printDivResultX PROC
	; void printDivResultX(int16 dividend,int16 divisor,int16 decimal)
	; 打印保留任意位小数的除法结果：dividend/divisor
	PROTECT_SITE
	mov AX,4[BP]	; Calculate integer part
	mov DX,0
	mov SI,6[BP]
	div SI
	push AX
	call printInt
	mov AX,'.' ; Print period
	push AX
	call printChar

	mov CX,8[BP]
lp:
	mov AX,DX ; Calculate decimal part
	mov SI,10 ;把余数乘10
	mul SI
	mov SI,6[BP]
	div SI
	push AX
	call printInt ;打印小数
	loop lp

	RESTORE_SITE 6
printDivResultX ENDP

readChar PROC
	; char readChar(void)
	; 通过1号DOS系统调用读入一个字符
	; Return Value: ASCII char code in AL
	mov AH,01h
	int 21h
	ret
readChar ENDP
	
readStr PROC
	; int16 readStr(char * strAddress)
	; 手工调用readChar读入一个字符串
	; 返回最终读入的字符串长度
	PROTECT_SITE
	mov BX,4H[BP]
	mov DI,0
lp:
	call readChar
	mov [BX][DI],AL
	inc DI
	cmp AL,0DH ;0DH是回车
	jnz lp
	
	dec DI
	mov BYTE PTR [BX][DI],'$'
	mov AX,DI
	RESTORE_SITE 2
readStr ENDP

readSplitStr PROC
	; int16 readSplitStr(char * strAddress)
	; 手工调用readChar读入一个字符串
	; 但以空格或回车作为结束标志，而非只有回车
	; 返回最终读入的字符串长度
	PROTECT_SITE
	mov BX,4H[BP]
	mov DI,0
lp:
	call readChar
	mov [BX][DI],AL
	inc DI
	cmp AL,0DH ;0DH是回车
	jz fi
	cmp AL,' '
	jz fi
	jmp lp
fi:
	dec DI
	mov BYTE PTR [BX][DI],'$'
	mov AX,DI
	RESTORE_SITE 2
readSplitStr ENDP

readStrFixLen PROC 
	; void readStrFixLen(char * strAddress, int16 strlen)
	; 读入固定长度的字符串
	; 传参：字符串首地址, 字符串长度
	PROTECT_SITE
	mov BX,4[BP]
	mov DI,0
lp:
	call readChar
	mov [BX][DI],AL
	inc DI
	cmp DI,WORD PTR 6[BP]
	jnz lp
	
	mov BYTE PTR [BX][DI],'$'
	RESTORE_SITE 4
readStrFixLen ENDP

readDecStrSecure PROC
	; int16 readDecStrSecure(char * strAddress, int16 min, int16 max)
	; 安全的读入十进制ASCII字符串，限制在[min,max]闭区间范围内
	; 返回值为该数字
	; fit [min,max]
	; Parameter 1: String Address
	; Parameter 2: min, 6[BP]
	; Parameter 3: max, 8[BP]
	PROTECT_SITE
	mov BX,4H[BP]
	push BX
	call readStr
	push BX
	call strLen
	mov CX,AX
lp:
	mov SI,CX
	mov AH,0
	mov AL,0FFFFH[BX][SI]
	push AX
	call isASCIIDigit ;检查字符串中的每个字符是否都是十进制
	cmp AX,0
	jz false ;否则要求重新读入
	loop lp
	push BX
	call DecASCII2Int
	cmp AX,8[BP]
	ja false
	cmp AX,6[BP]
	jb false
	jmp fi
false:
	lea SI,promptError
	push SI
	call printStr
	mov SI,8[BP]
	push SI
	mov SI,6[BP]
	push SI
	push BX
	call readDecStrSecure; 输入错误递归调用本函数重新输入
fi:	
	RESTORE_SITE 6
readDecStrSecure ENDP

readHexStrSecure PROC
	; void readHexStrSecure(char * strAddress, int16 strLength)
	; 安全的读入16进制的ASCII字符串，检测到不符合要求就会重新要求用户输入
	; Parameter 1: String Address
	; Parameter 2: String Length
	PROTECT_SITE
	mov BX,4H[BP]
	mov DX,6H[BP]
	
	push BX
	call readStr
	push BX
	call strLen
	cmp AX,DX
	jnz false
	mov CX,DX
lp:
	mov SI,CX
	mov AH,0
	mov AL,0FFFFH[BX][SI]
	push AX
	call isASCIIHexDigit
	cmp AX,0
	jz false
	loop lp
	jmp fi
false:
	lea SI,promptError
	push SI
	call printStr
	push DX
	push BX
	call readHexStrSecure
fi:	
	RESTORE_SITE 4
readHexStrSecure ENDP

; 类型判断及转换函数

isInRange PROC
	; int16 isInRange(int16 v,int16 min,int16 max)
	; 检查数v是否在[min,max]闭区间范围内
	; 是返回1，否则返回0
	PROTECT_SITE
	mov AX,4[BP]
	cmp AX,6[BP]
	jb false
	cmp AX,8[BP]
	ja false
true:
	mov AX,1
	jmp fi
false:
	mov AX,0
fi:
	RESTORE_SITE 6
isInRange ENDP

isLowerChar PROC 
	; int16 isLowerChar(char c)
	; 判断字符c是不是小写字母
	; 是小写返回1，不是小写返回0
	PROTECT_SITE
	mov DX,4H[BP]
	
	cmp DL,'a' ;c>='a'
	jb false
	cmp DL,'z' ;c<='z'
	ja false
true:
	mov AX,0001H
	jmp fi
false:
	mov AX,0000H
fi:	
	RESTORE_SITE 2
isLowerChar ENDP

isLowerStr PROC
	; int16 isLowerStr(char * strAddress)
	; 判断字符串是否全为小写字母
	; 全为小写返回1，否则返回0
	PROTECT_SITE
	mov BX,4H[BP]
	mov DI,0
	push BX
	call strLen ;先获取字符串长度，从而知道要循环几次
	cmp AX,0
	jz fi
lp:
	mov DL,BYTE PTR [BX][DI]
	cmp DL,'$'
	jz true ;假如是字符串结束标识，就返回1
	push DX
	call isLowerChar
	cmp AX,0 ;判断当前字符是否为小写
	jz fi ;是0就不是小写，返回0
	inc DI
	jmp lp
true:
	mov AX,0001H
fi:
	RESTORE_SITE 2
isLowerStr ENDP

isASCIIDigit PROC
	; int16 isASCIIDigit(char c)
	; 判断字符c是否为ASCII的10进制数字
	; 是返回1，不是返回0
	PROTECT_SITE
	mov AX,4H[BP]
	cmp AL,'0'
	jb false
	cmp AL,'9'
	ja false
true:
	mov AX,0001H
	jmp fi
false:
	mov AX,0000H
fi:
	RESTORE_SITE 2
isASCIIDigit ENDP

isASCIIHexDigit PROC
	; int16 isASCIIHexDigit(char c)
	; 判断字符c是否为ASCII的16进制数字
	; 是返回1，不是返回0
	PROTECT_SITE
	lea BX,ASCII2Num
	mov SI,4H[BP]
	mov AL,[BX][SI]
	cmp AL,'$'
	jz false
true:
	mov AX,0001H
	jmp fi
false:
	mov AX,0000H
fi:
	RESTORE_SITE 2
isASCIIHexDigit ENDP

char2Upper PROC 
	; char char2Upper(REG chr)
	; 本函数为特殊函数，通过AX寄存器传参
	; 将小写字母转换为大写
	; Parameter: ASCII char in AL
	; Return Value: Uppercase ASCII in AL
	PROTECT_SITE
	cmp AL,'a' ;c>='a'
	jb fi
	cmp AL,'z' ;c<='z'
	ja fi
	sub AL,20H ;c-='a'+'A'
fi:	
	RESTORE_SITE 0
char2Upper ENDP

isLowerStrAnd2Upper PROC
	; int16 isLowerStrAnd2Upper(char * strAddress)
	; 判断字符串是否全为小写字母，并将小写字母转为大写的
	; 全为小写且转换成功返回1，否则返回0
	PROTECT_SITE
	mov BX,4H[BP]
	mov DI,0
	push BX
	call strLen ;先获取字符串长度，从而知道要循环几次
	cmp AX,0
	jz fi
lp:
	mov DL,BYTE PTR [BX][DI]
	cmp DL,'$'
	jz true ;假如是字符串结束标识，就返回1
	push DX
	call isLowerChar
	cmp AX,0 ;判断当前字符是否为小写
	jz fi ;是0就不是小写，返回0
	mov AL,DL
	call char2Upper ;字符转换为大写
	mov BYTE PTR [BX][DI],AL ;写回字符串
	inc DI
	jmp lp
true:
	mov AX,0001H
fi:
	RESTORE_SITE 2
isLowerStrAnd2Upper ENDP

ASCIIDigit2Int PROC
	; int8 ASCIIDigit2Int(int16 ASCIIDigit)
	; 将各进制的ASCII码转为数字
	PROTECT_SITE
	lea BX,ASCII2Num
	mov SI,4H[BP]
	mov AL,[BX][SI]
	mov AH,0
	RESTORE_SITE 2
ASCIIDigit2Int ENDP

DecASCII2Int PROC
	; int16 DecASCII2Int(char * DecASCIIStrAddress)
	; 将十进制ASCII字符串转化为整数
	PROTECT_SITE
	mov BX,4H[BP]	;BI store string offset
	mov CX,0
	mov SI,10		;SI store 10
	mov DI,0		;DI store shift
	mov DX,0 		;DX store Num
lp:
	mov AX,DX		;DX = DX * 10
	mul SI
	mov DX,AX
	mov AL,[BX][DI]	;AX = nextDigitInt
	mov AH,0
	push AX
	call ASCIIDigit2Int
	add DX,AX		;DX += AX
	inc DI
	cmp BYTE PTR[BX][DI],'$'
	jnz lp
	
	mov AX,DX
	RESTORE_SITE 2
DecASCII2Int ENDP

HexASCII2Int PROC
	; int16 HexASCII2Int(char * hexASCIIStrAddress)
	; 将4位十六进制ASCII字符串转化为整数
	PROTECT_SITE
	mov AX,0
	mov BX,4H[BP]
	mov CX,0
	mov DI,0
lp:
	mov AL,[BX][DI]
	mov AH,0
	push AX
	call ASCIIDigit2Int
	shl CX,1
	shl CX,1
	shl CX,1
	shl CX,1
	or CX,AX
	inc DI
	cmp DI,4
	jb lp
	
	mov AX,CX
	RESTORE_SITE 2
HexASCII2Int ENDP

; 字符串相关函数

strLen PROC
	; int16 strLen(char * strAddress)
	; 返回DOS风格字符串(以$结尾)的长度
	PROTECT_SITE
	mov BX,4H[BP]
	mov SI,0
lp:
	mov AL,[BX][SI]
	inc SI
	cmp AL,'$'
	jnz lp
	
	dec SI
	mov AX,SI
	RESTORE_SITE 2
strLen ENDP

strLenNumeric PROC
	; int16 strLenNumeric(char * strAddress)
	; 返回DOS风格字符串(以$结尾)中所含的十进制数字的个数
	PROTECT_SITE
	mov BX,4H[BP]
	mov SI,0
	mov CX,0
lp:
	mov AL,[BX][SI]
	mov AH,0
	push AX
	call isASCIIDigit
	test AX,AX
	jz false
	inc CX
false:
	mov AL,[BX][SI]
	inc SI
	cmp AL,'$'
	jnz lp
	
	mov AX,CX
	RESTORE_SITE 2
strLenNumeric ENDP

strCmp PROC
	; int16 strCmp(char * strAddr1,char * strAddr2)
	; 检查两字符串是否相同
	; 相同返回1，不相同返回2
	PROTECT_SITE
	mov DI,4H[BP] ;strAddr1
	mov SI,6H[BP] ;strAddr2
	mov BX,0
lp:
	mov AH,[BX][DI]
	mov AL,[BX][SI]
	cmp AH,AL
	jnz false
	cmp AH,'$'
	jz true
	cmp AL,'$'
	jz true
	inc BX
	jmp lp
false:
	mov AX,0000H
	jmp fi
true:
	mov AX,0001H
fi:
	RESTORE_SITE 4
strCmp ENDP

strCharSame PROC
	; int16 strCharSame(char* addr)
	; 检查字符串内字符是否全部相同
	; 全部相同返回1，否则返回0
	PROTECT_SITE
	mov BX,4[BP]
	push BX
	call strLen
	cmp AX,0
	jz true
	mov SI,AX
	mov DL,[BX]
lp:
	dec SI
	cmp DL,BYTE PTR [SI][BX]
	jne false
	cmp SI,0
	jne lp
true:
	mov AX,1
	jmp fi
false:
	mov AX,0
fi:
	RESTORE_SITE 2
strCharSame ENDP

; 排序函数

SwapWORD PROC 
	; void SwapWORD(int16* addr1, int16* addr2)
	; 交换两字内容
	; 传参为两待交换字的内存地址
	PROTECT_SITE
	mov SI,4[BP]
	mov DI,6[BP]
	mov BX,[SI]
	mov DX,[DI]
	mov WORD PTR [DI],BX
	mov WORD PTR [SI],DX
	RESTORE_SITE 4
SwapWORD ENDP

Sort PROC 
	; void Sort(int16* array, int16 size)
	; 对数组从大到小排序
	; 传参16位数组首地址，元素个数
	PROTECT_SITE
	mov BX,4[BP]
	mov CX,6[BP]
outlp:
	mov DX,0
inlp:
	mov DI,DX
	add DI,DX
	inc DX
	mov AX,WORD PTR[BX][DI]
	cmp AX,WORD PTR 2[BX][DI]
	ja inlp_break
	lea AX,WORD PTR[BX][DI]
	push AX
	lea AX,WORD PTR 2[BX][DI]
	push AX
	call SwapWORD
inlp_break:
	cmp DX,WORD PTR 6[BP]
	jne inlp

	loop outlp

	RESTORE_SITE 4
Sort ENDP

main:
	mov AX,data
	mov DS,AX
	mov BP,SP
	
	; Your Code here

	mov AH,4Ch
	mov AL,0  			; Return Value
	int 21h
code ends

end main




