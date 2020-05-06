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

; ���������������

printChar PROC
	; void printChar(char ASCIICode)
	; ͨ��2��DOSϵͳ���ô�ӡһ���ַ�
	PROTECT_SITE
	mov AX,4H[BP]
	mov DL,AL
	mov AH,02h
	int 21h
	RESTORE_SITE 2
printChar ENDP
	
printLn PROC
	; void printLn(void)
	; ʵ�ִ�ӡ���й���
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
	; ͨ��9��DOSϵͳ�������һ���ַ������ַ������������ݶ�DS��
	PROTECT_SITE
	mov DX,4H[BP]
	mov AH,09h
	int 21h
	RESTORE_SITE 2
printStr ENDP

printDigit PROC
	; void printDigit(int16 x)
	; ��ӡ1λʮ�������ֵ�ASCII��
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
	; ��ӡ����x
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
	; ��ӡ���ֵĶ�������ʽ
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
	; ��ӡ����һλС���ĳ��������dividend/divisor
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
	mov SI,10 ;��������10
	mul SI
	mov SI,6[BP]
	div SI
	push AX
	call printInt ;��ӡС��
	RESTORE_SITE 4
printDivResult ENDP

printDivResultX PROC
	; void printDivResultX(int16 dividend,int16 divisor,int16 decimal)
	; ��ӡ��������λС���ĳ��������dividend/divisor
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
	mov SI,10 ;��������10
	mul SI
	mov SI,6[BP]
	div SI
	push AX
	call printInt ;��ӡС��
	loop lp

	RESTORE_SITE 6
printDivResultX ENDP

readChar PROC
	; char readChar(void)
	; ͨ��1��DOSϵͳ���ö���һ���ַ�
	; Return Value: ASCII char code in AL
	mov AH,01h
	int 21h
	ret
readChar ENDP
	
readStr PROC
	; int16 readStr(char * strAddress)
	; �ֹ�����readChar����һ���ַ���
	; �������ն�����ַ�������
	PROTECT_SITE
	mov BX,4H[BP]
	mov DI,0
lp:
	call readChar
	mov [BX][DI],AL
	inc DI
	cmp AL,0DH ;0DH�ǻس�
	jnz lp
	
	dec DI
	mov BYTE PTR [BX][DI],'$'
	mov AX,DI
	RESTORE_SITE 2
readStr ENDP

readSplitStr PROC
	; int16 readSplitStr(char * strAddress)
	; �ֹ�����readChar����һ���ַ���
	; ���Կո��س���Ϊ������־������ֻ�лس�
	; �������ն�����ַ�������
	PROTECT_SITE
	mov BX,4H[BP]
	mov DI,0
lp:
	call readChar
	mov [BX][DI],AL
	inc DI
	cmp AL,0DH ;0DH�ǻس�
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
	; ����̶����ȵ��ַ���
	; ���Σ��ַ����׵�ַ, �ַ�������
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
	; ��ȫ�Ķ���ʮ����ASCII�ַ�����������[min,max]�����䷶Χ��
	; ����ֵΪ������
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
	call isASCIIDigit ;����ַ����е�ÿ���ַ��Ƿ���ʮ����
	cmp AX,0
	jz false ;����Ҫ�����¶���
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
	call readDecStrSecure; �������ݹ���ñ�������������
fi:	
	RESTORE_SITE 6
readDecStrSecure ENDP

readHexStrSecure PROC
	; void readHexStrSecure(char * strAddress, int16 strLength)
	; ��ȫ�Ķ���16���Ƶ�ASCII�ַ�������⵽������Ҫ��ͻ�����Ҫ���û�����
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

; �����жϼ�ת������

isInRange PROC
	; int16 isInRange(int16 v,int16 min,int16 max)
	; �����v�Ƿ���[min,max]�����䷶Χ��
	; �Ƿ���1�����򷵻�0
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
	; �ж��ַ�c�ǲ���Сд��ĸ
	; ��Сд����1������Сд����0
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
	; �ж��ַ����Ƿ�ȫΪСд��ĸ
	; ȫΪСд����1�����򷵻�0
	PROTECT_SITE
	mov BX,4H[BP]
	mov DI,0
	push BX
	call strLen ;�Ȼ�ȡ�ַ������ȣ��Ӷ�֪��Ҫѭ������
	cmp AX,0
	jz fi
lp:
	mov DL,BYTE PTR [BX][DI]
	cmp DL,'$'
	jz true ;�������ַ���������ʶ���ͷ���1
	push DX
	call isLowerChar
	cmp AX,0 ;�жϵ�ǰ�ַ��Ƿ�ΪСд
	jz fi ;��0�Ͳ���Сд������0
	inc DI
	jmp lp
true:
	mov AX,0001H
fi:
	RESTORE_SITE 2
isLowerStr ENDP

isASCIIDigit PROC
	; int16 isASCIIDigit(char c)
	; �ж��ַ�c�Ƿ�ΪASCII��10��������
	; �Ƿ���1�����Ƿ���0
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
	; �ж��ַ�c�Ƿ�ΪASCII��16��������
	; �Ƿ���1�����Ƿ���0
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
	; ������Ϊ���⺯����ͨ��AX�Ĵ�������
	; ��Сд��ĸת��Ϊ��д
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
	; �ж��ַ����Ƿ�ȫΪСд��ĸ������Сд��ĸתΪ��д��
	; ȫΪСд��ת���ɹ�����1�����򷵻�0
	PROTECT_SITE
	mov BX,4H[BP]
	mov DI,0
	push BX
	call strLen ;�Ȼ�ȡ�ַ������ȣ��Ӷ�֪��Ҫѭ������
	cmp AX,0
	jz fi
lp:
	mov DL,BYTE PTR [BX][DI]
	cmp DL,'$'
	jz true ;�������ַ���������ʶ���ͷ���1
	push DX
	call isLowerChar
	cmp AX,0 ;�жϵ�ǰ�ַ��Ƿ�ΪСд
	jz fi ;��0�Ͳ���Сд������0
	mov AL,DL
	call char2Upper ;�ַ�ת��Ϊ��д
	mov BYTE PTR [BX][DI],AL ;д���ַ���
	inc DI
	jmp lp
true:
	mov AX,0001H
fi:
	RESTORE_SITE 2
isLowerStrAnd2Upper ENDP

ASCIIDigit2Int PROC
	; int8 ASCIIDigit2Int(int16 ASCIIDigit)
	; �������Ƶ�ASCII��תΪ����
	PROTECT_SITE
	lea BX,ASCII2Num
	mov SI,4H[BP]
	mov AL,[BX][SI]
	mov AH,0
	RESTORE_SITE 2
ASCIIDigit2Int ENDP

DecASCII2Int PROC
	; int16 DecASCII2Int(char * DecASCIIStrAddress)
	; ��ʮ����ASCII�ַ���ת��Ϊ����
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
	; ��4λʮ������ASCII�ַ���ת��Ϊ����
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

; �ַ�����غ���

strLen PROC
	; int16 strLen(char * strAddress)
	; ����DOS����ַ���(��$��β)�ĳ���
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
	; ����DOS����ַ���(��$��β)��������ʮ�������ֵĸ���
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
	; ������ַ����Ƿ���ͬ
	; ��ͬ����1������ͬ����2
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
	; ����ַ������ַ��Ƿ�ȫ����ͬ
	; ȫ����ͬ����1�����򷵻�0
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

; ������

SwapWORD PROC 
	; void SwapWORD(int16* addr1, int16* addr2)
	; ������������
	; ����Ϊ���������ֵ��ڴ��ַ
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
	; ������Ӵ�С����
	; ����16λ�����׵�ַ��Ԫ�ظ���
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




