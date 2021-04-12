
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c1c78793          	addi	a5,a5,-996 # 80005c80 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	3a4080e7          	jalr	932(ra) # 800024c2 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7e0080e7          	jalr	2016(ra) # 80001992 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e9c080e7          	jalr	-356(ra) # 8000205e <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	26e080e7          	jalr	622(ra) # 8000246c <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	23a080e7          	jalr	570(ra) # 80002518 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	db8080e7          	jalr	-584(ra) # 800021ea <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	96c080e7          	jalr	-1684(ra) # 800021ea <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	754080e7          	jalr	1876(ra) # 8000205e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e1a080e7          	jalr	-486(ra) # 80001976 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	de8080e7          	jalr	-536(ra) # 80001976 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	ddc080e7          	jalr	-548(ra) # 80001976 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	dc4080e7          	jalr	-572(ra) # 80001976 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	d84080e7          	jalr	-636(ra) # 80001976 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d58080e7          	jalr	-680(ra) # 80001976 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	af2080e7          	jalr	-1294(ra) # 80001966 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	ad6080e7          	jalr	-1322(ra) # 80001966 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	7a8080e7          	jalr	1960(ra) # 8000265a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	e06080e7          	jalr	-506(ra) # 80005cc0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fea080e7          	jalr	-22(ra) # 80001eac <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	994080e7          	jalr	-1644(ra) # 800018b6 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	708080e7          	jalr	1800(ra) # 80002632 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	728080e7          	jalr	1832(ra) # 8000265a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	d70080e7          	jalr	-656(ra) # 80005caa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	d7e080e7          	jalr	-642(ra) # 80005cc0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	f46080e7          	jalr	-186(ra) # 80002e90 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	5d8080e7          	jalr	1496(ra) # 8000352a <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	586080e7          	jalr	1414(ra) # 800044e0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	e80080e7          	jalr	-384(ra) # 80005de2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d04080e7          	jalr	-764(ra) # 80001c6e <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	614080e7          	jalr	1556(ra) # 80001820 <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6b05                	lui	s6,0x1
    8000126e:	0735e263          	bltu	a1,s3,800012d2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    *pte = 0;
    800012c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	995a                	add	s2,s2,s6
    800012ce:	fb3972e3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d2:	4601                	li	a2,0
    800012d4:	85ca                	mv	a1,s2
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	cce080e7          	jalr	-818(ra) # 80000fa6 <walk>
    800012e0:	84aa                	mv	s1,a0
    800012e2:	d95d                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012e4:	6108                	ld	a0,0(a0)
    800012e6:	00157793          	andi	a5,a0,1
    800012ea:	dfdd                	beqz	a5,800012a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	3ff57793          	andi	a5,a0,1023
    800012f0:	fd7784e3          	beq	a5,s7,800012b8 <uvmunmap+0x76>
    if(do_free){
    800012f4:	fc0a8ae3          	beqz	s5,800012c8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	6da080e7          	jalr	1754(ra) # 800009d6 <kfree>
    80001304:	b7d1                	j	800012c8 <uvmunmap+0x86>

0000000080001306 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	7c2080e7          	jalr	1986(ra) # 80000ad2 <kalloc>
    80001318:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000131a:	c519                	beqz	a0,80001328 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	99e080e7          	jalr	-1634(ra) # 80000cbe <memset>
  return pagetable;
}
    80001328:	8526                	mv	a0,s1
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001334:	7179                	addi	sp,sp,-48
    80001336:	f406                	sd	ra,40(sp)
    80001338:	f022                	sd	s0,32(sp)
    8000133a:	ec26                	sd	s1,24(sp)
    8000133c:	e84a                	sd	s2,16(sp)
    8000133e:	e44e                	sd	s3,8(sp)
    80001340:	e052                	sd	s4,0(sp)
    80001342:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001344:	6785                	lui	a5,0x1
    80001346:	04f67863          	bgeu	a2,a5,80001396 <uvminit+0x62>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	89ae                	mv	s3,a1
    8000134e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	782080e7          	jalr	1922(ra) # 80000ad2 <kalloc>
    80001358:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	960080e7          	jalr	-1696(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001366:	4779                	li	a4,30
    80001368:	86ca                	mv	a3,s2
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	8552                	mv	a0,s4
    80001370:	00000097          	auipc	ra,0x0
    80001374:	d1e080e7          	jalr	-738(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001378:	8626                	mv	a2,s1
    8000137a:	85ce                	mv	a1,s3
    8000137c:	854a                	mv	a0,s2
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	99c080e7          	jalr	-1636(ra) # 80000d1a <memmove>
}
    80001386:	70a2                	ld	ra,40(sp)
    80001388:	7402                	ld	s0,32(sp)
    8000138a:	64e2                	ld	s1,24(sp)
    8000138c:	6942                	ld	s2,16(sp)
    8000138e:	69a2                	ld	s3,8(sp)
    80001390:	6a02                	ld	s4,0(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret
    panic("inituvm: more than a page");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	daa50513          	addi	a0,a0,-598 # 80008140 <digits+0x100>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800013a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a6:	1101                	addi	sp,sp,-32
    800013a8:	ec06                	sd	ra,24(sp)
    800013aa:	e822                	sd	s0,16(sp)
    800013ac:	e426                	sd	s1,8(sp)
    800013ae:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013b2:	00b67d63          	bgeu	a2,a1,800013cc <uvmdealloc+0x26>
    800013b6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b8:	6785                	lui	a5,0x1
    800013ba:	17fd                	addi	a5,a5,-1
    800013bc:	00f60733          	add	a4,a2,a5
    800013c0:	767d                	lui	a2,0xfffff
    800013c2:	8f71                	and	a4,a4,a2
    800013c4:	97ae                	add	a5,a5,a1
    800013c6:	8ff1                	and	a5,a5,a2
    800013c8:	00f76863          	bltu	a4,a5,800013d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d8:	8f99                	sub	a5,a5,a4
    800013da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013dc:	4685                	li	a3,1
    800013de:	0007861b          	sext.w	a2,a5
    800013e2:	85ba                	mv	a1,a4
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	e5e080e7          	jalr	-418(ra) # 80001242 <uvmunmap>
    800013ec:	b7c5                	j	800013cc <uvmdealloc+0x26>

00000000800013ee <uvmalloc>:
  if(newsz < oldsz)
    800013ee:	0ab66163          	bltu	a2,a1,80001490 <uvmalloc+0xa2>
{
    800013f2:	7139                	addi	sp,sp,-64
    800013f4:	fc06                	sd	ra,56(sp)
    800013f6:	f822                	sd	s0,48(sp)
    800013f8:	f426                	sd	s1,40(sp)
    800013fa:	f04a                	sd	s2,32(sp)
    800013fc:	ec4e                	sd	s3,24(sp)
    800013fe:	e852                	sd	s4,16(sp)
    80001400:	e456                	sd	s5,8(sp)
    80001402:	0080                	addi	s0,sp,64
    80001404:	8aaa                	mv	s5,a0
    80001406:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001408:	6985                	lui	s3,0x1
    8000140a:	19fd                	addi	s3,s3,-1
    8000140c:	95ce                	add	a1,a1,s3
    8000140e:	79fd                	lui	s3,0xfffff
    80001410:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001414:	08c9f063          	bgeu	s3,a2,80001494 <uvmalloc+0xa6>
    80001418:	894e                	mv	s2,s3
    mem = kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	6b8080e7          	jalr	1720(ra) # 80000ad2 <kalloc>
    80001422:	84aa                	mv	s1,a0
    if(mem == 0){
    80001424:	c51d                	beqz	a0,80001452 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001426:	6605                	lui	a2,0x1
    80001428:	4581                	li	a1,0
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	894080e7          	jalr	-1900(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001432:	4779                	li	a4,30
    80001434:	86a6                	mv	a3,s1
    80001436:	6605                	lui	a2,0x1
    80001438:	85ca                	mv	a1,s2
    8000143a:	8556                	mv	a0,s5
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	c52080e7          	jalr	-942(ra) # 8000108e <mappages>
    80001444:	e905                	bnez	a0,80001474 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001446:	6785                	lui	a5,0x1
    80001448:	993e                	add	s2,s2,a5
    8000144a:	fd4968e3          	bltu	s2,s4,8000141a <uvmalloc+0x2c>
  return newsz;
    8000144e:	8552                	mv	a0,s4
    80001450:	a809                	j	80001462 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001452:	864e                	mv	a2,s3
    80001454:	85ca                	mv	a1,s2
    80001456:	8556                	mv	a0,s5
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f4e080e7          	jalr	-178(ra) # 800013a6 <uvmdealloc>
      return 0;
    80001460:	4501                	li	a0,0
}
    80001462:	70e2                	ld	ra,56(sp)
    80001464:	7442                	ld	s0,48(sp)
    80001466:	74a2                	ld	s1,40(sp)
    80001468:	7902                	ld	s2,32(sp)
    8000146a:	69e2                	ld	s3,24(sp)
    8000146c:	6a42                	ld	s4,16(sp)
    8000146e:	6aa2                	ld	s5,8(sp)
    80001470:	6121                	addi	sp,sp,64
    80001472:	8082                	ret
      kfree(mem);
    80001474:	8526                	mv	a0,s1
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	560080e7          	jalr	1376(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000147e:	864e                	mv	a2,s3
    80001480:	85ca                	mv	a1,s2
    80001482:	8556                	mv	a0,s5
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f22080e7          	jalr	-222(ra) # 800013a6 <uvmdealloc>
      return 0;
    8000148c:	4501                	li	a0,0
    8000148e:	bfd1                	j	80001462 <uvmalloc+0x74>
    return oldsz;
    80001490:	852e                	mv	a0,a1
}
    80001492:	8082                	ret
  return newsz;
    80001494:	8532                	mv	a0,a2
    80001496:	b7f1                	j	80001462 <uvmalloc+0x74>

0000000080001498 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
    800014a8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014aa:	84aa                	mv	s1,a0
    800014ac:	6905                	lui	s2,0x1
    800014ae:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014b0:	4985                	li	s3,1
    800014b2:	a821                	j	800014ca <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b6:	0532                	slli	a0,a0,0xc
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	fe0080e7          	jalr	-32(ra) # 80001498 <freewalk>
      pagetable[i] = 0;
    800014c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014c4:	04a1                	addi	s1,s1,8
    800014c6:	03248163          	beq	s1,s2,800014e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014cc:	00f57793          	andi	a5,a0,15
    800014d0:	ff3782e3          	beq	a5,s3,800014b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014d4:	8905                	andi	a0,a0,1
    800014d6:	d57d                	beqz	a0,800014c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014d8:	00007517          	auipc	a0,0x7
    800014dc:	c8850513          	addi	a0,a0,-888 # 80008160 <digits+0x120>
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014e8:	8552                	mv	a0,s4
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	4ec080e7          	jalr	1260(ra) # 800009d6 <kfree>
}
    800014f2:	70a2                	ld	ra,40(sp)
    800014f4:	7402                	ld	s0,32(sp)
    800014f6:	64e2                	ld	s1,24(sp)
    800014f8:	6942                	ld	s2,16(sp)
    800014fa:	69a2                	ld	s3,8(sp)
    800014fc:	6a02                	ld	s4,0(sp)
    800014fe:	6145                	addi	sp,sp,48
    80001500:	8082                	ret

0000000080001502 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001502:	1101                	addi	sp,sp,-32
    80001504:	ec06                	sd	ra,24(sp)
    80001506:	e822                	sd	s0,16(sp)
    80001508:	e426                	sd	s1,8(sp)
    8000150a:	1000                	addi	s0,sp,32
    8000150c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000150e:	e999                	bnez	a1,80001524 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001510:	8526                	mv	a0,s1
    80001512:	00000097          	auipc	ra,0x0
    80001516:	f86080e7          	jalr	-122(ra) # 80001498 <freewalk>
}
    8000151a:	60e2                	ld	ra,24(sp)
    8000151c:	6442                	ld	s0,16(sp)
    8000151e:	64a2                	ld	s1,8(sp)
    80001520:	6105                	addi	sp,sp,32
    80001522:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001524:	6605                	lui	a2,0x1
    80001526:	167d                	addi	a2,a2,-1
    80001528:	962e                	add	a2,a2,a1
    8000152a:	4685                	li	a3,1
    8000152c:	8231                	srli	a2,a2,0xc
    8000152e:	4581                	li	a1,0
    80001530:	00000097          	auipc	ra,0x0
    80001534:	d12080e7          	jalr	-750(ra) # 80001242 <uvmunmap>
    80001538:	bfe1                	j	80001510 <uvmfree+0xe>

000000008000153a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000153a:	c679                	beqz	a2,80001608 <uvmcopy+0xce>
{
    8000153c:	715d                	addi	sp,sp,-80
    8000153e:	e486                	sd	ra,72(sp)
    80001540:	e0a2                	sd	s0,64(sp)
    80001542:	fc26                	sd	s1,56(sp)
    80001544:	f84a                	sd	s2,48(sp)
    80001546:	f44e                	sd	s3,40(sp)
    80001548:	f052                	sd	s4,32(sp)
    8000154a:	ec56                	sd	s5,24(sp)
    8000154c:	e85a                	sd	s6,16(sp)
    8000154e:	e45e                	sd	s7,8(sp)
    80001550:	0880                	addi	s0,sp,80
    80001552:	8b2a                	mv	s6,a0
    80001554:	8aae                	mv	s5,a1
    80001556:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001558:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000155a:	4601                	li	a2,0
    8000155c:	85ce                	mv	a1,s3
    8000155e:	855a                	mv	a0,s6
    80001560:	00000097          	auipc	ra,0x0
    80001564:	a46080e7          	jalr	-1466(ra) # 80000fa6 <walk>
    80001568:	c531                	beqz	a0,800015b4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000156a:	6118                	ld	a4,0(a0)
    8000156c:	00177793          	andi	a5,a4,1
    80001570:	cbb1                	beqz	a5,800015c4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001572:	00a75593          	srli	a1,a4,0xa
    80001576:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000157a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	554080e7          	jalr	1364(ra) # 80000ad2 <kalloc>
    80001586:	892a                	mv	s2,a0
    80001588:	c939                	beqz	a0,800015de <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	85de                	mv	a1,s7
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	78c080e7          	jalr	1932(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001596:	8726                	mv	a4,s1
    80001598:	86ca                	mv	a3,s2
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85ce                	mv	a1,s3
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	aee080e7          	jalr	-1298(ra) # 8000108e <mappages>
    800015a8:	e515                	bnez	a0,800015d4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	6785                	lui	a5,0x1
    800015ac:	99be                	add	s3,s3,a5
    800015ae:	fb49e6e3          	bltu	s3,s4,8000155a <uvmcopy+0x20>
    800015b2:	a081                	j	800015f2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	bbc50513          	addi	a0,a0,-1092 # 80008170 <digits+0x130>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	bcc50513          	addi	a0,a0,-1076 # 80008190 <digits+0x150>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
      kfree(mem);
    800015d4:	854a                	mv	a0,s2
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	400080e7          	jalr	1024(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015de:	4685                	li	a3,1
    800015e0:	00c9d613          	srli	a2,s3,0xc
    800015e4:	4581                	li	a1,0
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	c5a080e7          	jalr	-934(ra) # 80001242 <uvmunmap>
  return -1;
    800015f0:	557d                	li	a0,-1
}
    800015f2:	60a6                	ld	ra,72(sp)
    800015f4:	6406                	ld	s0,64(sp)
    800015f6:	74e2                	ld	s1,56(sp)
    800015f8:	7942                	ld	s2,48(sp)
    800015fa:	79a2                	ld	s3,40(sp)
    800015fc:	7a02                	ld	s4,32(sp)
    800015fe:	6ae2                	ld	s5,24(sp)
    80001600:	6b42                	ld	s6,16(sp)
    80001602:	6ba2                	ld	s7,8(sp)
    80001604:	6161                	addi	sp,sp,80
    80001606:	8082                	ret
  return 0;
    80001608:	4501                	li	a0,0
}
    8000160a:	8082                	ret

000000008000160c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160c:	1141                	addi	sp,sp,-16
    8000160e:	e406                	sd	ra,8(sp)
    80001610:	e022                	sd	s0,0(sp)
    80001612:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001614:	4601                	li	a2,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	990080e7          	jalr	-1648(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000161e:	c901                	beqz	a0,8000162e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001620:	611c                	ld	a5,0(a0)
    80001622:	9bbd                	andi	a5,a5,-17
    80001624:	e11c                	sd	a5,0(a0)
}
    80001626:	60a2                	ld	ra,8(sp)
    80001628:	6402                	ld	s0,0(sp)
    8000162a:	0141                	addi	sp,sp,16
    8000162c:	8082                	ret
    panic("uvmclear");
    8000162e:	00007517          	auipc	a0,0x7
    80001632:	b8250513          	addi	a0,a0,-1150 # 800081b0 <digits+0x170>
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	ef4080e7          	jalr	-268(ra) # 8000052a <panic>

000000008000163e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163e:	c6bd                	beqz	a3,800016ac <copyout+0x6e>
{
    80001640:	715d                	addi	sp,sp,-80
    80001642:	e486                	sd	ra,72(sp)
    80001644:	e0a2                	sd	s0,64(sp)
    80001646:	fc26                	sd	s1,56(sp)
    80001648:	f84a                	sd	s2,48(sp)
    8000164a:	f44e                	sd	s3,40(sp)
    8000164c:	f052                	sd	s4,32(sp)
    8000164e:	ec56                	sd	s5,24(sp)
    80001650:	e85a                	sd	s6,16(sp)
    80001652:	e45e                	sd	s7,8(sp)
    80001654:	e062                	sd	s8,0(sp)
    80001656:	0880                	addi	s0,sp,80
    80001658:	8b2a                	mv	s6,a0
    8000165a:	8c2e                	mv	s8,a1
    8000165c:	8a32                	mv	s4,a2
    8000165e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001660:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001662:	6a85                	lui	s5,0x1
    80001664:	a015                	j	80001688 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001666:	9562                	add	a0,a0,s8
    80001668:	0004861b          	sext.w	a2,s1
    8000166c:	85d2                	mv	a1,s4
    8000166e:	41250533          	sub	a0,a0,s2
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	6a8080e7          	jalr	1704(ra) # 80000d1a <memmove>

    len -= n;
    8000167a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001680:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001684:	02098263          	beqz	s3,800016a8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001688:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168c:	85ca                	mv	a1,s2
    8000168e:	855a                	mv	a0,s6
    80001690:	00000097          	auipc	ra,0x0
    80001694:	9bc080e7          	jalr	-1604(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001698:	cd01                	beqz	a0,800016b0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000169a:	418904b3          	sub	s1,s2,s8
    8000169e:	94d6                	add	s1,s1,s5
    if(n > len)
    800016a0:	fc99f3e3          	bgeu	s3,s1,80001666 <copyout+0x28>
    800016a4:	84ce                	mv	s1,s3
    800016a6:	b7c1                	j	80001666 <copyout+0x28>
  }
  return 0;
    800016a8:	4501                	li	a0,0
    800016aa:	a021                	j	800016b2 <copyout+0x74>
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret
      return -1;
    800016b0:	557d                	li	a0,-1
}
    800016b2:	60a6                	ld	ra,72(sp)
    800016b4:	6406                	ld	s0,64(sp)
    800016b6:	74e2                	ld	s1,56(sp)
    800016b8:	7942                	ld	s2,48(sp)
    800016ba:	79a2                	ld	s3,40(sp)
    800016bc:	7a02                	ld	s4,32(sp)
    800016be:	6ae2                	ld	s5,24(sp)
    800016c0:	6b42                	ld	s6,16(sp)
    800016c2:	6ba2                	ld	s7,8(sp)
    800016c4:	6c02                	ld	s8,0(sp)
    800016c6:	6161                	addi	sp,sp,80
    800016c8:	8082                	ret

00000000800016ca <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	caa5                	beqz	a3,8000173a <copyin+0x70>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8a2e                	mv	s4,a1
    800016e8:	8c32                	mv	s8,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a01d                	j	80001716 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f2:	018505b3          	add	a1,a0,s8
    800016f6:	0004861b          	sext.w	a2,s1
    800016fa:	412585b3          	sub	a1,a1,s2
    800016fe:	8552                	mv	a0,s4
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	61a080e7          	jalr	1562(ra) # 80000d1a <memmove>

    len -= n;
    80001708:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000170c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001712:	02098263          	beqz	s3,80001736 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001716:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000171a:	85ca                	mv	a1,s2
    8000171c:	855a                	mv	a0,s6
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	92e080e7          	jalr	-1746(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001726:	cd01                	beqz	a0,8000173e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001728:	418904b3          	sub	s1,s2,s8
    8000172c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172e:	fc99f2e3          	bgeu	s3,s1,800016f2 <copyin+0x28>
    80001732:	84ce                	mv	s1,s3
    80001734:	bf7d                	j	800016f2 <copyin+0x28>
  }
  return 0;
    80001736:	4501                	li	a0,0
    80001738:	a021                	j	80001740 <copyin+0x76>
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret
      return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	60a6                	ld	ra,72(sp)
    80001742:	6406                	ld	s0,64(sp)
    80001744:	74e2                	ld	s1,56(sp)
    80001746:	7942                	ld	s2,48(sp)
    80001748:	79a2                	ld	s3,40(sp)
    8000174a:	7a02                	ld	s4,32(sp)
    8000174c:	6ae2                	ld	s5,24(sp)
    8000174e:	6b42                	ld	s6,16(sp)
    80001750:	6ba2                	ld	s7,8(sp)
    80001752:	6c02                	ld	s8,0(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret

0000000080001758 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001758:	c6c5                	beqz	a3,80001800 <copyinstr+0xa8>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8a2a                	mv	s4,a0
    80001772:	8b2e                	mv	s6,a1
    80001774:	8bb2                	mv	s7,a2
    80001776:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6985                	lui	s3,0x1
    8000177c:	a035                	j	800017a8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001782:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001784:	0017b793          	seqz	a5,a5
    80001788:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6161                	addi	sp,sp,80
    800017a0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017a2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a6:	c8a9                	beqz	s1,800017f8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	8552                	mv	a0,s4
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	89c080e7          	jalr	-1892(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017b8:	c131                	beqz	a0,800017fc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ba:	41790833          	sub	a6,s2,s7
    800017be:	984e                	add	a6,a6,s3
    if(n > max)
    800017c0:	0104f363          	bgeu	s1,a6,800017c6 <copyinstr+0x6e>
    800017c4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c6:	955e                	add	a0,a0,s7
    800017c8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017cc:	fc080be3          	beqz	a6,800017a2 <copyinstr+0x4a>
    800017d0:	985a                	add	a6,a6,s6
    800017d2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d4:	41650633          	sub	a2,a0,s6
    800017d8:	14fd                	addi	s1,s1,-1
    800017da:	9b26                	add	s6,s6,s1
    800017dc:	00f60733          	add	a4,a2,a5
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017e4:	df49                	beqz	a4,8000177e <copyinstr+0x26>
        *dst = *p;
    800017e6:	00e78023          	sb	a4,0(a5)
      --max;
    800017ea:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ee:	0785                	addi	a5,a5,1
    while(n > 0){
    800017f0:	ff0796e3          	bne	a5,a6,800017dc <copyinstr+0x84>
      dst++;
    800017f4:	8b42                	mv	s6,a6
    800017f6:	b775                	j	800017a2 <copyinstr+0x4a>
    800017f8:	4781                	li	a5,0
    800017fa:	b769                	j	80001784 <copyinstr+0x2c>
      return -1;
    800017fc:	557d                	li	a0,-1
    800017fe:	b779                	j	8000178c <copyinstr+0x34>
  int got_null = 0;
    80001800:	4781                	li	a5,0
  if(got_null){
    80001802:	0017b793          	seqz	a5,a5
    80001806:	40f00533          	neg	a0,a5
}
    8000180a:	8082                	ret

000000008000180c <getProc>:

struct cpu cpus[NCPU];

struct proc proc[NPROC];
struct proc *getProc()
{
    8000180c:	1141                	addi	sp,sp,-16
    8000180e:	e422                	sd	s0,8(sp)
    80001810:	0800                	addi	s0,sp,16
  return proc;
}
    80001812:	00010517          	auipc	a0,0x10
    80001816:	ebe50513          	addi	a0,a0,-322 # 800116d0 <proc>
    8000181a:	6422                	ld	s0,8(sp)
    8000181c:	0141                	addi	sp,sp,16
    8000181e:	8082                	ret

0000000080001820 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001820:	7139                	addi	sp,sp,-64
    80001822:	fc06                	sd	ra,56(sp)
    80001824:	f822                	sd	s0,48(sp)
    80001826:	f426                	sd	s1,40(sp)
    80001828:	f04a                	sd	s2,32(sp)
    8000182a:	ec4e                	sd	s3,24(sp)
    8000182c:	e852                	sd	s4,16(sp)
    8000182e:	e456                	sd	s5,8(sp)
    80001830:	e05a                	sd	s6,0(sp)
    80001832:	0080                	addi	s0,sp,64
    80001834:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001836:	00010497          	auipc	s1,0x10
    8000183a:	e9a48493          	addi	s1,s1,-358 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000183e:	8b26                	mv	s6,s1
    80001840:	00006a97          	auipc	s5,0x6
    80001844:	7c0a8a93          	addi	s5,s5,1984 # 80008000 <etext>
    80001848:	04000937          	lui	s2,0x4000
    8000184c:	197d                	addi	s2,s2,-1
    8000184e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001850:	00016a17          	auipc	s4,0x16
    80001854:	880a0a13          	addi	s4,s4,-1920 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001858:	fffff097          	auipc	ra,0xfffff
    8000185c:	27a080e7          	jalr	634(ra) # 80000ad2 <kalloc>
    80001860:	862a                	mv	a2,a0
    if (pa == 0)
    80001862:	c131                	beqz	a0,800018a6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001864:	416485b3          	sub	a1,s1,s6
    80001868:	858d                	srai	a1,a1,0x3
    8000186a:	000ab783          	ld	a5,0(s5)
    8000186e:	02f585b3          	mul	a1,a1,a5
    80001872:	2585                	addiw	a1,a1,1
    80001874:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001878:	4719                	li	a4,6
    8000187a:	6685                	lui	a3,0x1
    8000187c:	40b905b3          	sub	a1,s2,a1
    80001880:	854e                	mv	a0,s3
    80001882:	00000097          	auipc	ra,0x0
    80001886:	89a080e7          	jalr	-1894(ra) # 8000111c <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000188a:	16848493          	addi	s1,s1,360
    8000188e:	fd4495e3          	bne	s1,s4,80001858 <proc_mapstacks+0x38>
  }
}
    80001892:	70e2                	ld	ra,56(sp)
    80001894:	7442                	ld	s0,48(sp)
    80001896:	74a2                	ld	s1,40(sp)
    80001898:	7902                	ld	s2,32(sp)
    8000189a:	69e2                	ld	s3,24(sp)
    8000189c:	6a42                	ld	s4,16(sp)
    8000189e:	6aa2                	ld	s5,8(sp)
    800018a0:	6b02                	ld	s6,0(sp)
    800018a2:	6121                	addi	sp,sp,64
    800018a4:	8082                	ret
      panic("kalloc");
    800018a6:	00007517          	auipc	a0,0x7
    800018aa:	91a50513          	addi	a0,a0,-1766 # 800081c0 <digits+0x180>
    800018ae:	fffff097          	auipc	ra,0xfffff
    800018b2:	c7c080e7          	jalr	-900(ra) # 8000052a <panic>

00000000800018b6 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018b6:	7139                	addi	sp,sp,-64
    800018b8:	fc06                	sd	ra,56(sp)
    800018ba:	f822                	sd	s0,48(sp)
    800018bc:	f426                	sd	s1,40(sp)
    800018be:	f04a                	sd	s2,32(sp)
    800018c0:	ec4e                	sd	s3,24(sp)
    800018c2:	e852                	sd	s4,16(sp)
    800018c4:	e456                	sd	s5,8(sp)
    800018c6:	e05a                	sd	s6,0(sp)
    800018c8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018ca:	00007597          	auipc	a1,0x7
    800018ce:	8fe58593          	addi	a1,a1,-1794 # 800081c8 <digits+0x188>
    800018d2:	00010517          	auipc	a0,0x10
    800018d6:	9ce50513          	addi	a0,a0,-1586 # 800112a0 <pid_lock>
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	258080e7          	jalr	600(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e2:	00007597          	auipc	a1,0x7
    800018e6:	8ee58593          	addi	a1,a1,-1810 # 800081d0 <digits+0x190>
    800018ea:	00010517          	auipc	a0,0x10
    800018ee:	9ce50513          	addi	a0,a0,-1586 # 800112b8 <wait_lock>
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	240080e7          	jalr	576(ra) # 80000b32 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800018fa:	00010497          	auipc	s1,0x10
    800018fe:	dd648493          	addi	s1,s1,-554 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    80001902:	00007b17          	auipc	s6,0x7
    80001906:	8deb0b13          	addi	s6,s6,-1826 # 800081e0 <digits+0x1a0>
    p->kstack = KSTACK((int)(p - proc));
    8000190a:	8aa6                	mv	s5,s1
    8000190c:	00006a17          	auipc	s4,0x6
    80001910:	6f4a0a13          	addi	s4,s4,1780 # 80008000 <etext>
    80001914:	04000937          	lui	s2,0x4000
    80001918:	197d                	addi	s2,s2,-1
    8000191a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000191c:	00015997          	auipc	s3,0x15
    80001920:	7b498993          	addi	s3,s3,1972 # 800170d0 <tickslock>
    initlock(&p->lock, "proc");
    80001924:	85da                	mv	a1,s6
    80001926:	8526                	mv	a0,s1
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	20a080e7          	jalr	522(ra) # 80000b32 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001930:	415487b3          	sub	a5,s1,s5
    80001934:	878d                	srai	a5,a5,0x3
    80001936:	000a3703          	ld	a4,0(s4)
    8000193a:	02e787b3          	mul	a5,a5,a4
    8000193e:	2785                	addiw	a5,a5,1
    80001940:	00d7979b          	slliw	a5,a5,0xd
    80001944:	40f907b3          	sub	a5,s2,a5
    80001948:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000194a:	16848493          	addi	s1,s1,360
    8000194e:	fd349be3          	bne	s1,s3,80001924 <procinit+0x6e>
  }
}
    80001952:	70e2                	ld	ra,56(sp)
    80001954:	7442                	ld	s0,48(sp)
    80001956:	74a2                	ld	s1,40(sp)
    80001958:	7902                	ld	s2,32(sp)
    8000195a:	69e2                	ld	s3,24(sp)
    8000195c:	6a42                	ld	s4,16(sp)
    8000195e:	6aa2                	ld	s5,8(sp)
    80001960:	6b02                	ld	s6,0(sp)
    80001962:	6121                	addi	sp,sp,64
    80001964:	8082                	ret

0000000080001966 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001966:	1141                	addi	sp,sp,-16
    80001968:	e422                	sd	s0,8(sp)
    8000196a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000196c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000196e:	2501                	sext.w	a0,a0
    80001970:	6422                	ld	s0,8(sp)
    80001972:	0141                	addi	sp,sp,16
    80001974:	8082                	ret

0000000080001976 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001976:	1141                	addi	sp,sp,-16
    80001978:	e422                	sd	s0,8(sp)
    8000197a:	0800                	addi	s0,sp,16
    8000197c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000197e:	2781                	sext.w	a5,a5
    80001980:	079e                	slli	a5,a5,0x7
  return c;
}
    80001982:	00010517          	auipc	a0,0x10
    80001986:	94e50513          	addi	a0,a0,-1714 # 800112d0 <cpus>
    8000198a:	953e                	add	a0,a0,a5
    8000198c:	6422                	ld	s0,8(sp)
    8000198e:	0141                	addi	sp,sp,16
    80001990:	8082                	ret

0000000080001992 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001992:	1101                	addi	sp,sp,-32
    80001994:	ec06                	sd	ra,24(sp)
    80001996:	e822                	sd	s0,16(sp)
    80001998:	e426                	sd	s1,8(sp)
    8000199a:	1000                	addi	s0,sp,32
  push_off();
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	1da080e7          	jalr	474(ra) # 80000b76 <push_off>
    800019a4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019a6:	2781                	sext.w	a5,a5
    800019a8:	079e                	slli	a5,a5,0x7
    800019aa:	00010717          	auipc	a4,0x10
    800019ae:	8f670713          	addi	a4,a4,-1802 # 800112a0 <pid_lock>
    800019b2:	97ba                	add	a5,a5,a4
    800019b4:	7b84                	ld	s1,48(a5)
  pop_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	260080e7          	jalr	608(ra) # 80000c16 <pop_off>
  return p;
}
    800019be:	8526                	mv	a0,s1
    800019c0:	60e2                	ld	ra,24(sp)
    800019c2:	6442                	ld	s0,16(sp)
    800019c4:	64a2                	ld	s1,8(sp)
    800019c6:	6105                	addi	sp,sp,32
    800019c8:	8082                	ret

00000000800019ca <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019ca:	1141                	addi	sp,sp,-16
    800019cc:	e406                	sd	ra,8(sp)
    800019ce:	e022                	sd	s0,0(sp)
    800019d0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d2:	00000097          	auipc	ra,0x0
    800019d6:	fc0080e7          	jalr	-64(ra) # 80001992 <myproc>
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	29c080e7          	jalr	668(ra) # 80000c76 <release>

  if (first)
    800019e2:	00007797          	auipc	a5,0x7
    800019e6:	05e7a783          	lw	a5,94(a5) # 80008a40 <first.1>
    800019ea:	eb89                	bnez	a5,800019fc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ec:	00001097          	auipc	ra,0x1
    800019f0:	c86080e7          	jalr	-890(ra) # 80002672 <usertrapret>
}
    800019f4:	60a2                	ld	ra,8(sp)
    800019f6:	6402                	ld	s0,0(sp)
    800019f8:	0141                	addi	sp,sp,16
    800019fa:	8082                	ret
    first = 0;
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	0407a223          	sw	zero,68(a5) # 80008a40 <first.1>
    fsinit(ROOTDEV);
    80001a04:	4505                	li	a0,1
    80001a06:	00002097          	auipc	ra,0x2
    80001a0a:	aa4080e7          	jalr	-1372(ra) # 800034aa <fsinit>
    80001a0e:	bff9                	j	800019ec <forkret+0x22>

0000000080001a10 <allocpid>:
{
    80001a10:	1101                	addi	sp,sp,-32
    80001a12:	ec06                	sd	ra,24(sp)
    80001a14:	e822                	sd	s0,16(sp)
    80001a16:	e426                	sd	s1,8(sp)
    80001a18:	e04a                	sd	s2,0(sp)
    80001a1a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a1c:	00010917          	auipc	s2,0x10
    80001a20:	88490913          	addi	s2,s2,-1916 # 800112a0 <pid_lock>
    80001a24:	854a                	mv	a0,s2
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	19c080e7          	jalr	412(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a2e:	00007797          	auipc	a5,0x7
    80001a32:	01678793          	addi	a5,a5,22 # 80008a44 <nextpid>
    80001a36:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a38:	0014871b          	addiw	a4,s1,1
    80001a3c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	236080e7          	jalr	566(ra) # 80000c76 <release>
}
    80001a48:	8526                	mv	a0,s1
    80001a4a:	60e2                	ld	ra,24(sp)
    80001a4c:	6442                	ld	s0,16(sp)
    80001a4e:	64a2                	ld	s1,8(sp)
    80001a50:	6902                	ld	s2,0(sp)
    80001a52:	6105                	addi	sp,sp,32
    80001a54:	8082                	ret

0000000080001a56 <proc_pagetable>:
{
    80001a56:	1101                	addi	sp,sp,-32
    80001a58:	ec06                	sd	ra,24(sp)
    80001a5a:	e822                	sd	s0,16(sp)
    80001a5c:	e426                	sd	s1,8(sp)
    80001a5e:	e04a                	sd	s2,0(sp)
    80001a60:	1000                	addi	s0,sp,32
    80001a62:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	8a2080e7          	jalr	-1886(ra) # 80001306 <uvmcreate>
    80001a6c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a6e:	c121                	beqz	a0,80001aae <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a70:	4729                	li	a4,10
    80001a72:	00005697          	auipc	a3,0x5
    80001a76:	58e68693          	addi	a3,a3,1422 # 80007000 <_trampoline>
    80001a7a:	6605                	lui	a2,0x1
    80001a7c:	040005b7          	lui	a1,0x4000
    80001a80:	15fd                	addi	a1,a1,-1
    80001a82:	05b2                	slli	a1,a1,0xc
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	60a080e7          	jalr	1546(ra) # 8000108e <mappages>
    80001a8c:	02054863          	bltz	a0,80001abc <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a90:	4719                	li	a4,6
    80001a92:	05893683          	ld	a3,88(s2)
    80001a96:	6605                	lui	a2,0x1
    80001a98:	020005b7          	lui	a1,0x2000
    80001a9c:	15fd                	addi	a1,a1,-1
    80001a9e:	05b6                	slli	a1,a1,0xd
    80001aa0:	8526                	mv	a0,s1
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	5ec080e7          	jalr	1516(ra) # 8000108e <mappages>
    80001aaa:	02054163          	bltz	a0,80001acc <proc_pagetable+0x76>
}
    80001aae:	8526                	mv	a0,s1
    80001ab0:	60e2                	ld	ra,24(sp)
    80001ab2:	6442                	ld	s0,16(sp)
    80001ab4:	64a2                	ld	s1,8(sp)
    80001ab6:	6902                	ld	s2,0(sp)
    80001ab8:	6105                	addi	sp,sp,32
    80001aba:	8082                	ret
    uvmfree(pagetable, 0);
    80001abc:	4581                	li	a1,0
    80001abe:	8526                	mv	a0,s1
    80001ac0:	00000097          	auipc	ra,0x0
    80001ac4:	a42080e7          	jalr	-1470(ra) # 80001502 <uvmfree>
    return 0;
    80001ac8:	4481                	li	s1,0
    80001aca:	b7d5                	j	80001aae <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001acc:	4681                	li	a3,0
    80001ace:	4605                	li	a2,1
    80001ad0:	040005b7          	lui	a1,0x4000
    80001ad4:	15fd                	addi	a1,a1,-1
    80001ad6:	05b2                	slli	a1,a1,0xc
    80001ad8:	8526                	mv	a0,s1
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	768080e7          	jalr	1896(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae2:	4581                	li	a1,0
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	00000097          	auipc	ra,0x0
    80001aea:	a1c080e7          	jalr	-1508(ra) # 80001502 <uvmfree>
    return 0;
    80001aee:	4481                	li	s1,0
    80001af0:	bf7d                	j	80001aae <proc_pagetable+0x58>

0000000080001af2 <proc_freepagetable>:
{
    80001af2:	1101                	addi	sp,sp,-32
    80001af4:	ec06                	sd	ra,24(sp)
    80001af6:	e822                	sd	s0,16(sp)
    80001af8:	e426                	sd	s1,8(sp)
    80001afa:	e04a                	sd	s2,0(sp)
    80001afc:	1000                	addi	s0,sp,32
    80001afe:	84aa                	mv	s1,a0
    80001b00:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	040005b7          	lui	a1,0x4000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b2                	slli	a1,a1,0xc
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	734080e7          	jalr	1844(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	020005b7          	lui	a1,0x2000
    80001b1e:	15fd                	addi	a1,a1,-1
    80001b20:	05b6                	slli	a1,a1,0xd
    80001b22:	8526                	mv	a0,s1
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	71e080e7          	jalr	1822(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b2c:	85ca                	mv	a1,s2
    80001b2e:	8526                	mv	a0,s1
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	9d2080e7          	jalr	-1582(ra) # 80001502 <uvmfree>
}
    80001b38:	60e2                	ld	ra,24(sp)
    80001b3a:	6442                	ld	s0,16(sp)
    80001b3c:	64a2                	ld	s1,8(sp)
    80001b3e:	6902                	ld	s2,0(sp)
    80001b40:	6105                	addi	sp,sp,32
    80001b42:	8082                	ret

0000000080001b44 <freeproc>:
{
    80001b44:	1101                	addi	sp,sp,-32
    80001b46:	ec06                	sd	ra,24(sp)
    80001b48:	e822                	sd	s0,16(sp)
    80001b4a:	e426                	sd	s1,8(sp)
    80001b4c:	1000                	addi	s0,sp,32
    80001b4e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b50:	6d28                	ld	a0,88(a0)
    80001b52:	c509                	beqz	a0,80001b5c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	e82080e7          	jalr	-382(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b5c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b60:	68a8                	ld	a0,80(s1)
    80001b62:	c511                	beqz	a0,80001b6e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b64:	64ac                	ld	a1,72(s1)
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	f8c080e7          	jalr	-116(ra) # 80001af2 <proc_freepagetable>
  p->pagetable = 0;
    80001b6e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b72:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b76:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b7e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b82:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b86:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b8e:	0004ac23          	sw	zero,24(s1)
}
    80001b92:	60e2                	ld	ra,24(sp)
    80001b94:	6442                	ld	s0,16(sp)
    80001b96:	64a2                	ld	s1,8(sp)
    80001b98:	6105                	addi	sp,sp,32
    80001b9a:	8082                	ret

0000000080001b9c <allocproc>:
{
    80001b9c:	1101                	addi	sp,sp,-32
    80001b9e:	ec06                	sd	ra,24(sp)
    80001ba0:	e822                	sd	s0,16(sp)
    80001ba2:	e426                	sd	s1,8(sp)
    80001ba4:	e04a                	sd	s2,0(sp)
    80001ba6:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001ba8:	00010497          	auipc	s1,0x10
    80001bac:	b2848493          	addi	s1,s1,-1240 # 800116d0 <proc>
    80001bb0:	00015917          	auipc	s2,0x15
    80001bb4:	52090913          	addi	s2,s2,1312 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bb8:	8526                	mv	a0,s1
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	008080e7          	jalr	8(ra) # 80000bc2 <acquire>
    if (p->state == UNUSED)
    80001bc2:	4c9c                	lw	a5,24(s1)
    80001bc4:	cf81                	beqz	a5,80001bdc <allocproc+0x40>
      release(&p->lock);
    80001bc6:	8526                	mv	a0,s1
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	0ae080e7          	jalr	174(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd0:	16848493          	addi	s1,s1,360
    80001bd4:	ff2492e3          	bne	s1,s2,80001bb8 <allocproc+0x1c>
  return 0;
    80001bd8:	4481                	li	s1,0
    80001bda:	a899                	j	80001c30 <allocproc+0x94>
  p->pid = allocpid();
    80001bdc:	00000097          	auipc	ra,0x0
    80001be0:	e34080e7          	jalr	-460(ra) # 80001a10 <allocpid>
    80001be4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001be6:	4785                	li	a5,1
    80001be8:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	ee8080e7          	jalr	-280(ra) # 80000ad2 <kalloc>
    80001bf2:	892a                	mv	s2,a0
    80001bf4:	eca8                	sd	a0,88(s1)
    80001bf6:	c521                	beqz	a0,80001c3e <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e5c080e7          	jalr	-420(ra) # 80001a56 <proc_pagetable>
    80001c02:	892a                	mv	s2,a0
    80001c04:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c06:	c921                	beqz	a0,80001c56 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001c08:	07000613          	li	a2,112
    80001c0c:	4581                	li	a1,0
    80001c0e:	06048513          	addi	a0,s1,96
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	0ac080e7          	jalr	172(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c1a:	00000797          	auipc	a5,0x0
    80001c1e:	db078793          	addi	a5,a5,-592 # 800019ca <forkret>
    80001c22:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c24:	60bc                	ld	a5,64(s1)
    80001c26:	6705                	lui	a4,0x1
    80001c28:	97ba                	add	a5,a5,a4
    80001c2a:	f4bc                	sd	a5,104(s1)
  p->traceMask = 0; //initially no sys calls are traced
    80001c2c:	0204aa23          	sw	zero,52(s1)
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	f04080e7          	jalr	-252(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	02c080e7          	jalr	44(ra) # 80000c76 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	bff1                	j	80001c30 <allocproc+0x94>
    freeproc(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	eec080e7          	jalr	-276(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	014080e7          	jalr	20(ra) # 80000c76 <release>
    return 0;
    80001c6a:	84ca                	mv	s1,s2
    80001c6c:	b7d1                	j	80001c30 <allocproc+0x94>

0000000080001c6e <userinit>:
{
    80001c6e:	1101                	addi	sp,sp,-32
    80001c70:	ec06                	sd	ra,24(sp)
    80001c72:	e822                	sd	s0,16(sp)
    80001c74:	e426                	sd	s1,8(sp)
    80001c76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f24080e7          	jalr	-220(ra) # 80001b9c <allocproc>
    80001c80:	84aa                	mv	s1,a0
  initproc = p;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	3aa7b323          	sd	a0,934(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8a:	03400613          	li	a2,52
    80001c8e:	00007597          	auipc	a1,0x7
    80001c92:	dc258593          	addi	a1,a1,-574 # 80008a50 <initcode>
    80001c96:	6928                	ld	a0,80(a0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	69c080e7          	jalr	1692(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001ca0:	6785                	lui	a5,0x1
    80001ca2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ca4:	6cb8                	ld	a4,88(s1)
    80001ca6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001caa:	6cb8                	ld	a4,88(s1)
    80001cac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cae:	4641                	li	a2,16
    80001cb0:	00006597          	auipc	a1,0x6
    80001cb4:	53858593          	addi	a1,a1,1336 # 800081e8 <digits+0x1a8>
    80001cb8:	15848513          	addi	a0,s1,344
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	154080e7          	jalr	340(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	53450513          	addi	a0,a0,1332 # 800081f8 <digits+0x1b8>
    80001ccc:	00002097          	auipc	ra,0x2
    80001cd0:	20c080e7          	jalr	524(ra) # 80003ed8 <namei>
    80001cd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd8:	478d                	li	a5,3
    80001cda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	f98080e7          	jalr	-104(ra) # 80000c76 <release>
}
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <growproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	e04a                	sd	s2,0(sp)
    80001cfa:	1000                	addi	s0,sp,32
    80001cfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	c94080e7          	jalr	-876(ra) # 80001992 <myproc>
    80001d06:	892a                	mv	s2,a0
  sz = p->sz;
    80001d08:	652c                	ld	a1,72(a0)
    80001d0a:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d0e:	00904f63          	bgtz	s1,80001d2c <growproc+0x3c>
  else if (n < 0)
    80001d12:	0204cc63          	bltz	s1,80001d4a <growproc+0x5a>
  p->sz = sz;
    80001d16:	1602                	slli	a2,a2,0x20
    80001d18:	9201                	srli	a2,a2,0x20
    80001d1a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d1e:	4501                	li	a0,0
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6902                	ld	s2,0(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d2c:	9e25                	addw	a2,a2,s1
    80001d2e:	1602                	slli	a2,a2,0x20
    80001d30:	9201                	srli	a2,a2,0x20
    80001d32:	1582                	slli	a1,a1,0x20
    80001d34:	9181                	srli	a1,a1,0x20
    80001d36:	6928                	ld	a0,80(a0)
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	6b6080e7          	jalr	1718(ra) # 800013ee <uvmalloc>
    80001d40:	0005061b          	sext.w	a2,a0
    80001d44:	fa69                	bnez	a2,80001d16 <growproc+0x26>
      return -1;
    80001d46:	557d                	li	a0,-1
    80001d48:	bfe1                	j	80001d20 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4a:	9e25                	addw	a2,a2,s1
    80001d4c:	1602                	slli	a2,a2,0x20
    80001d4e:	9201                	srli	a2,a2,0x20
    80001d50:	1582                	slli	a1,a1,0x20
    80001d52:	9181                	srli	a1,a1,0x20
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	650080e7          	jalr	1616(ra) # 800013a6 <uvmdealloc>
    80001d5e:	0005061b          	sext.w	a2,a0
    80001d62:	bf55                	j	80001d16 <growproc+0x26>

0000000080001d64 <fork>:
{
    80001d64:	7139                	addi	sp,sp,-64
    80001d66:	fc06                	sd	ra,56(sp)
    80001d68:	f822                	sd	s0,48(sp)
    80001d6a:	f426                	sd	s1,40(sp)
    80001d6c:	f04a                	sd	s2,32(sp)
    80001d6e:	ec4e                	sd	s3,24(sp)
    80001d70:	e852                	sd	s4,16(sp)
    80001d72:	e456                	sd	s5,8(sp)
    80001d74:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	c1c080e7          	jalr	-996(ra) # 80001992 <myproc>
    80001d7e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	e1c080e7          	jalr	-484(ra) # 80001b9c <allocproc>
    80001d88:	12050063          	beqz	a0,80001ea8 <fork+0x144>
    80001d8c:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001d8e:	048ab603          	ld	a2,72(s5)
    80001d92:	692c                	ld	a1,80(a0)
    80001d94:	050ab503          	ld	a0,80(s5)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	7a2080e7          	jalr	1954(ra) # 8000153a <uvmcopy>
    80001da0:	04054863          	bltz	a0,80001df0 <fork+0x8c>
  np->sz = p->sz;
    80001da4:	048ab783          	ld	a5,72(s5)
    80001da8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dac:	058ab683          	ld	a3,88(s5)
    80001db0:	87b6                	mv	a5,a3
    80001db2:	0589b703          	ld	a4,88(s3)
    80001db6:	12068693          	addi	a3,a3,288
    80001dba:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbe:	6788                	ld	a0,8(a5)
    80001dc0:	6b8c                	ld	a1,16(a5)
    80001dc2:	6f90                	ld	a2,24(a5)
    80001dc4:	01073023          	sd	a6,0(a4)
    80001dc8:	e708                	sd	a0,8(a4)
    80001dca:	eb0c                	sd	a1,16(a4)
    80001dcc:	ef10                	sd	a2,24(a4)
    80001dce:	02078793          	addi	a5,a5,32
    80001dd2:	02070713          	addi	a4,a4,32
    80001dd6:	fed792e3          	bne	a5,a3,80001dba <fork+0x56>
  np->trapframe->a0 = 0;
    80001dda:	0589b783          	ld	a5,88(s3)
    80001dde:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001de2:	0d0a8493          	addi	s1,s5,208
    80001de6:	0d098913          	addi	s2,s3,208
    80001dea:	150a8a13          	addi	s4,s5,336
    80001dee:	a00d                	j	80001e10 <fork+0xac>
    freeproc(np);
    80001df0:	854e                	mv	a0,s3
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	d52080e7          	jalr	-686(ra) # 80001b44 <freeproc>
    release(&np->lock);
    80001dfa:	854e                	mv	a0,s3
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	e7a080e7          	jalr	-390(ra) # 80000c76 <release>
    return -1;
    80001e04:	597d                	li	s2,-1
    80001e06:	a079                	j	80001e94 <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80001e08:	04a1                	addi	s1,s1,8
    80001e0a:	0921                	addi	s2,s2,8
    80001e0c:	01448b63          	beq	s1,s4,80001e22 <fork+0xbe>
    if (p->ofile[i])
    80001e10:	6088                	ld	a0,0(s1)
    80001e12:	d97d                	beqz	a0,80001e08 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e14:	00002097          	auipc	ra,0x2
    80001e18:	75e080e7          	jalr	1886(ra) # 80004572 <filedup>
    80001e1c:	00a93023          	sd	a0,0(s2)
    80001e20:	b7e5                	j	80001e08 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e22:	150ab503          	ld	a0,336(s5)
    80001e26:	00002097          	auipc	ra,0x2
    80001e2a:	8be080e7          	jalr	-1858(ra) # 800036e4 <idup>
    80001e2e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e32:	4641                	li	a2,16
    80001e34:	158a8593          	addi	a1,s5,344
    80001e38:	15898513          	addi	a0,s3,344
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	fd4080e7          	jalr	-44(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e44:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e48:	854e                	mv	a0,s3
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e2c080e7          	jalr	-468(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e52:	0000f497          	auipc	s1,0xf
    80001e56:	46648493          	addi	s1,s1,1126 # 800112b8 <wait_lock>
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	d66080e7          	jalr	-666(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e64:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e0c080e7          	jalr	-500(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e72:	854e                	mv	a0,s3
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d4e080e7          	jalr	-690(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e7c:	478d                	li	a5,3
    80001e7e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e82:	854e                	mv	a0,s3
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	df2080e7          	jalr	-526(ra) # 80000c76 <release>
  np->traceMask = p->traceMask;
    80001e8c:	034aa783          	lw	a5,52(s5)
    80001e90:	02f9aa23          	sw	a5,52(s3)
}
    80001e94:	854a                	mv	a0,s2
    80001e96:	70e2                	ld	ra,56(sp)
    80001e98:	7442                	ld	s0,48(sp)
    80001e9a:	74a2                	ld	s1,40(sp)
    80001e9c:	7902                	ld	s2,32(sp)
    80001e9e:	69e2                	ld	s3,24(sp)
    80001ea0:	6a42                	ld	s4,16(sp)
    80001ea2:	6aa2                	ld	s5,8(sp)
    80001ea4:	6121                	addi	sp,sp,64
    80001ea6:	8082                	ret
    return -1;
    80001ea8:	597d                	li	s2,-1
    80001eaa:	b7ed                	j	80001e94 <fork+0x130>

0000000080001eac <scheduler>:
{
    80001eac:	7139                	addi	sp,sp,-64
    80001eae:	fc06                	sd	ra,56(sp)
    80001eb0:	f822                	sd	s0,48(sp)
    80001eb2:	f426                	sd	s1,40(sp)
    80001eb4:	f04a                	sd	s2,32(sp)
    80001eb6:	ec4e                	sd	s3,24(sp)
    80001eb8:	e852                	sd	s4,16(sp)
    80001eba:	e456                	sd	s5,8(sp)
    80001ebc:	e05a                	sd	s6,0(sp)
    80001ebe:	0080                	addi	s0,sp,64
    80001ec0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ec2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec4:	00779a93          	slli	s5,a5,0x7
    80001ec8:	0000f717          	auipc	a4,0xf
    80001ecc:	3d870713          	addi	a4,a4,984 # 800112a0 <pid_lock>
    80001ed0:	9756                	add	a4,a4,s5
    80001ed2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed6:	0000f717          	auipc	a4,0xf
    80001eda:	40270713          	addi	a4,a4,1026 # 800112d8 <cpus+0x8>
    80001ede:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ee0:	498d                	li	s3,3
        p->state = RUNNING;
    80001ee2:	4b11                	li	s6,4
        c->proc = p;
    80001ee4:	079e                	slli	a5,a5,0x7
    80001ee6:	0000fa17          	auipc	s4,0xf
    80001eea:	3baa0a13          	addi	s4,s4,954 # 800112a0 <pid_lock>
    80001eee:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ef0:	00015917          	auipc	s2,0x15
    80001ef4:	1e090913          	addi	s2,s2,480 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001efc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f00:	10079073          	csrw	sstatus,a5
    80001f04:	0000f497          	auipc	s1,0xf
    80001f08:	7cc48493          	addi	s1,s1,1996 # 800116d0 <proc>
    80001f0c:	a811                	j	80001f20 <scheduler+0x74>
      release(&p->lock);
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	d66080e7          	jalr	-666(ra) # 80000c76 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f18:	16848493          	addi	s1,s1,360
    80001f1c:	fd248ee3          	beq	s1,s2,80001ef8 <scheduler+0x4c>
      acquire(&p->lock);
    80001f20:	8526                	mv	a0,s1
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	ca0080e7          	jalr	-864(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    80001f2a:	4c9c                	lw	a5,24(s1)
    80001f2c:	ff3791e3          	bne	a5,s3,80001f0e <scheduler+0x62>
        p->state = RUNNING;
    80001f30:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f34:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f38:	06048593          	addi	a1,s1,96
    80001f3c:	8556                	mv	a0,s5
    80001f3e:	00000097          	auipc	ra,0x0
    80001f42:	68a080e7          	jalr	1674(ra) # 800025c8 <swtch>
        c->proc = 0;
    80001f46:	020a3823          	sd	zero,48(s4)
    80001f4a:	b7d1                	j	80001f0e <scheduler+0x62>

0000000080001f4c <sched>:
{
    80001f4c:	7179                	addi	sp,sp,-48
    80001f4e:	f406                	sd	ra,40(sp)
    80001f50:	f022                	sd	s0,32(sp)
    80001f52:	ec26                	sd	s1,24(sp)
    80001f54:	e84a                	sd	s2,16(sp)
    80001f56:	e44e                	sd	s3,8(sp)
    80001f58:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f5a:	00000097          	auipc	ra,0x0
    80001f5e:	a38080e7          	jalr	-1480(ra) # 80001992 <myproc>
    80001f62:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	be4080e7          	jalr	-1052(ra) # 80000b48 <holding>
    80001f6c:	c93d                	beqz	a0,80001fe2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f6e:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f70:	2781                	sext.w	a5,a5
    80001f72:	079e                	slli	a5,a5,0x7
    80001f74:	0000f717          	auipc	a4,0xf
    80001f78:	32c70713          	addi	a4,a4,812 # 800112a0 <pid_lock>
    80001f7c:	97ba                	add	a5,a5,a4
    80001f7e:	0a87a703          	lw	a4,168(a5)
    80001f82:	4785                	li	a5,1
    80001f84:	06f71763          	bne	a4,a5,80001ff2 <sched+0xa6>
  if (p->state == RUNNING)
    80001f88:	4c98                	lw	a4,24(s1)
    80001f8a:	4791                	li	a5,4
    80001f8c:	06f70b63          	beq	a4,a5,80002002 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f90:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f94:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001f96:	efb5                	bnez	a5,80002012 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f98:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f9a:	0000f917          	auipc	s2,0xf
    80001f9e:	30690913          	addi	s2,s2,774 # 800112a0 <pid_lock>
    80001fa2:	2781                	sext.w	a5,a5
    80001fa4:	079e                	slli	a5,a5,0x7
    80001fa6:	97ca                	add	a5,a5,s2
    80001fa8:	0ac7a983          	lw	s3,172(a5)
    80001fac:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fae:	2781                	sext.w	a5,a5
    80001fb0:	079e                	slli	a5,a5,0x7
    80001fb2:	0000f597          	auipc	a1,0xf
    80001fb6:	32658593          	addi	a1,a1,806 # 800112d8 <cpus+0x8>
    80001fba:	95be                	add	a1,a1,a5
    80001fbc:	06048513          	addi	a0,s1,96
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	608080e7          	jalr	1544(ra) # 800025c8 <swtch>
    80001fc8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fca:	2781                	sext.w	a5,a5
    80001fcc:	079e                	slli	a5,a5,0x7
    80001fce:	97ca                	add	a5,a5,s2
    80001fd0:	0b37a623          	sw	s3,172(a5)
}
    80001fd4:	70a2                	ld	ra,40(sp)
    80001fd6:	7402                	ld	s0,32(sp)
    80001fd8:	64e2                	ld	s1,24(sp)
    80001fda:	6942                	ld	s2,16(sp)
    80001fdc:	69a2                	ld	s3,8(sp)
    80001fde:	6145                	addi	sp,sp,48
    80001fe0:	8082                	ret
    panic("sched p->lock");
    80001fe2:	00006517          	auipc	a0,0x6
    80001fe6:	21e50513          	addi	a0,a0,542 # 80008200 <digits+0x1c0>
    80001fea:	ffffe097          	auipc	ra,0xffffe
    80001fee:	540080e7          	jalr	1344(ra) # 8000052a <panic>
    panic("sched locks");
    80001ff2:	00006517          	auipc	a0,0x6
    80001ff6:	21e50513          	addi	a0,a0,542 # 80008210 <digits+0x1d0>
    80001ffa:	ffffe097          	auipc	ra,0xffffe
    80001ffe:	530080e7          	jalr	1328(ra) # 8000052a <panic>
    panic("sched running");
    80002002:	00006517          	auipc	a0,0x6
    80002006:	21e50513          	addi	a0,a0,542 # 80008220 <digits+0x1e0>
    8000200a:	ffffe097          	auipc	ra,0xffffe
    8000200e:	520080e7          	jalr	1312(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002012:	00006517          	auipc	a0,0x6
    80002016:	21e50513          	addi	a0,a0,542 # 80008230 <digits+0x1f0>
    8000201a:	ffffe097          	auipc	ra,0xffffe
    8000201e:	510080e7          	jalr	1296(ra) # 8000052a <panic>

0000000080002022 <yield>:
{
    80002022:	1101                	addi	sp,sp,-32
    80002024:	ec06                	sd	ra,24(sp)
    80002026:	e822                	sd	s0,16(sp)
    80002028:	e426                	sd	s1,8(sp)
    8000202a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	966080e7          	jalr	-1690(ra) # 80001992 <myproc>
    80002034:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	b8c080e7          	jalr	-1140(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000203e:	478d                	li	a5,3
    80002040:	cc9c                	sw	a5,24(s1)
  sched();
    80002042:	00000097          	auipc	ra,0x0
    80002046:	f0a080e7          	jalr	-246(ra) # 80001f4c <sched>
  release(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c2a080e7          	jalr	-982(ra) # 80000c76 <release>
}
    80002054:	60e2                	ld	ra,24(sp)
    80002056:	6442                	ld	s0,16(sp)
    80002058:	64a2                	ld	s1,8(sp)
    8000205a:	6105                	addi	sp,sp,32
    8000205c:	8082                	ret

000000008000205e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000205e:	7179                	addi	sp,sp,-48
    80002060:	f406                	sd	ra,40(sp)
    80002062:	f022                	sd	s0,32(sp)
    80002064:	ec26                	sd	s1,24(sp)
    80002066:	e84a                	sd	s2,16(sp)
    80002068:	e44e                	sd	s3,8(sp)
    8000206a:	1800                	addi	s0,sp,48
    8000206c:	89aa                	mv	s3,a0
    8000206e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002070:	00000097          	auipc	ra,0x0
    80002074:	922080e7          	jalr	-1758(ra) # 80001992 <myproc>
    80002078:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	b48080e7          	jalr	-1208(ra) # 80000bc2 <acquire>
  release(lk);
    80002082:	854a                	mv	a0,s2
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	bf2080e7          	jalr	-1038(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    8000208c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002090:	4789                	li	a5,2
    80002092:	cc9c                	sw	a5,24(s1)

  sched();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	eb8080e7          	jalr	-328(ra) # 80001f4c <sched>

  // Tidy up.
  p->chan = 0;
    8000209c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a0:	8526                	mv	a0,s1
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	bd4080e7          	jalr	-1068(ra) # 80000c76 <release>
  acquire(lk);
    800020aa:	854a                	mv	a0,s2
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	b16080e7          	jalr	-1258(ra) # 80000bc2 <acquire>
}
    800020b4:	70a2                	ld	ra,40(sp)
    800020b6:	7402                	ld	s0,32(sp)
    800020b8:	64e2                	ld	s1,24(sp)
    800020ba:	6942                	ld	s2,16(sp)
    800020bc:	69a2                	ld	s3,8(sp)
    800020be:	6145                	addi	sp,sp,48
    800020c0:	8082                	ret

00000000800020c2 <wait>:
{
    800020c2:	715d                	addi	sp,sp,-80
    800020c4:	e486                	sd	ra,72(sp)
    800020c6:	e0a2                	sd	s0,64(sp)
    800020c8:	fc26                	sd	s1,56(sp)
    800020ca:	f84a                	sd	s2,48(sp)
    800020cc:	f44e                	sd	s3,40(sp)
    800020ce:	f052                	sd	s4,32(sp)
    800020d0:	ec56                	sd	s5,24(sp)
    800020d2:	e85a                	sd	s6,16(sp)
    800020d4:	e45e                	sd	s7,8(sp)
    800020d6:	e062                	sd	s8,0(sp)
    800020d8:	0880                	addi	s0,sp,80
    800020da:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	8b6080e7          	jalr	-1866(ra) # 80001992 <myproc>
    800020e4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020e6:	0000f517          	auipc	a0,0xf
    800020ea:	1d250513          	addi	a0,a0,466 # 800112b8 <wait_lock>
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	ad4080e7          	jalr	-1324(ra) # 80000bc2 <acquire>
    havekids = 0;
    800020f6:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800020f8:	4a15                	li	s4,5
        havekids = 1;
    800020fa:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800020fc:	00015997          	auipc	s3,0x15
    80002100:	fd498993          	addi	s3,s3,-44 # 800170d0 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002104:	0000fc17          	auipc	s8,0xf
    80002108:	1b4c0c13          	addi	s8,s8,436 # 800112b8 <wait_lock>
    havekids = 0;
    8000210c:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000210e:	0000f497          	auipc	s1,0xf
    80002112:	5c248493          	addi	s1,s1,1474 # 800116d0 <proc>
    80002116:	a0bd                	j	80002184 <wait+0xc2>
          pid = np->pid;
    80002118:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000211c:	000b0e63          	beqz	s6,80002138 <wait+0x76>
    80002120:	4691                	li	a3,4
    80002122:	02c48613          	addi	a2,s1,44
    80002126:	85da                	mv	a1,s6
    80002128:	05093503          	ld	a0,80(s2)
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	512080e7          	jalr	1298(ra) # 8000163e <copyout>
    80002134:	02054563          	bltz	a0,8000215e <wait+0x9c>
          freeproc(np);
    80002138:	8526                	mv	a0,s1
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	a0a080e7          	jalr	-1526(ra) # 80001b44 <freeproc>
          release(&np->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	b32080e7          	jalr	-1230(ra) # 80000c76 <release>
          release(&wait_lock);
    8000214c:	0000f517          	auipc	a0,0xf
    80002150:	16c50513          	addi	a0,a0,364 # 800112b8 <wait_lock>
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	b22080e7          	jalr	-1246(ra) # 80000c76 <release>
          return pid;
    8000215c:	a09d                	j	800021c2 <wait+0x100>
            release(&np->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b16080e7          	jalr	-1258(ra) # 80000c76 <release>
            release(&wait_lock);
    80002168:	0000f517          	auipc	a0,0xf
    8000216c:	15050513          	addi	a0,a0,336 # 800112b8 <wait_lock>
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	b06080e7          	jalr	-1274(ra) # 80000c76 <release>
            return -1;
    80002178:	59fd                	li	s3,-1
    8000217a:	a0a1                	j	800021c2 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    8000217c:	16848493          	addi	s1,s1,360
    80002180:	03348463          	beq	s1,s3,800021a8 <wait+0xe6>
      if (np->parent == p)
    80002184:	7c9c                	ld	a5,56(s1)
    80002186:	ff279be3          	bne	a5,s2,8000217c <wait+0xba>
        acquire(&np->lock);
    8000218a:	8526                	mv	a0,s1
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	a36080e7          	jalr	-1482(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    80002194:	4c9c                	lw	a5,24(s1)
    80002196:	f94781e3          	beq	a5,s4,80002118 <wait+0x56>
        release(&np->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	ada080e7          	jalr	-1318(ra) # 80000c76 <release>
        havekids = 1;
    800021a4:	8756                	mv	a4,s5
    800021a6:	bfd9                	j	8000217c <wait+0xba>
    if (!havekids || p->killed)
    800021a8:	c701                	beqz	a4,800021b0 <wait+0xee>
    800021aa:	02892783          	lw	a5,40(s2)
    800021ae:	c79d                	beqz	a5,800021dc <wait+0x11a>
      release(&wait_lock);
    800021b0:	0000f517          	auipc	a0,0xf
    800021b4:	10850513          	addi	a0,a0,264 # 800112b8 <wait_lock>
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	abe080e7          	jalr	-1346(ra) # 80000c76 <release>
      return -1;
    800021c0:	59fd                	li	s3,-1
}
    800021c2:	854e                	mv	a0,s3
    800021c4:	60a6                	ld	ra,72(sp)
    800021c6:	6406                	ld	s0,64(sp)
    800021c8:	74e2                	ld	s1,56(sp)
    800021ca:	7942                	ld	s2,48(sp)
    800021cc:	79a2                	ld	s3,40(sp)
    800021ce:	7a02                	ld	s4,32(sp)
    800021d0:	6ae2                	ld	s5,24(sp)
    800021d2:	6b42                	ld	s6,16(sp)
    800021d4:	6ba2                	ld	s7,8(sp)
    800021d6:	6c02                	ld	s8,0(sp)
    800021d8:	6161                	addi	sp,sp,80
    800021da:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800021dc:	85e2                	mv	a1,s8
    800021de:	854a                	mv	a0,s2
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	e7e080e7          	jalr	-386(ra) # 8000205e <sleep>
    havekids = 0;
    800021e8:	b715                	j	8000210c <wait+0x4a>

00000000800021ea <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800021ea:	7139                	addi	sp,sp,-64
    800021ec:	fc06                	sd	ra,56(sp)
    800021ee:	f822                	sd	s0,48(sp)
    800021f0:	f426                	sd	s1,40(sp)
    800021f2:	f04a                	sd	s2,32(sp)
    800021f4:	ec4e                	sd	s3,24(sp)
    800021f6:	e852                	sd	s4,16(sp)
    800021f8:	e456                	sd	s5,8(sp)
    800021fa:	0080                	addi	s0,sp,64
    800021fc:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800021fe:	0000f497          	auipc	s1,0xf
    80002202:	4d248493          	addi	s1,s1,1234 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002206:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002208:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000220a:	00015917          	auipc	s2,0x15
    8000220e:	ec690913          	addi	s2,s2,-314 # 800170d0 <tickslock>
    80002212:	a811                	j	80002226 <wakeup+0x3c>
      }
      release(&p->lock);
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	a60080e7          	jalr	-1440(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000221e:	16848493          	addi	s1,s1,360
    80002222:	03248663          	beq	s1,s2,8000224e <wakeup+0x64>
    if (p != myproc())
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	76c080e7          	jalr	1900(ra) # 80001992 <myproc>
    8000222e:	fea488e3          	beq	s1,a0,8000221e <wakeup+0x34>
      acquire(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	98e080e7          	jalr	-1650(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000223c:	4c9c                	lw	a5,24(s1)
    8000223e:	fd379be3          	bne	a5,s3,80002214 <wakeup+0x2a>
    80002242:	709c                	ld	a5,32(s1)
    80002244:	fd4798e3          	bne	a5,s4,80002214 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002248:	0154ac23          	sw	s5,24(s1)
    8000224c:	b7e1                	j	80002214 <wakeup+0x2a>
    }
  }
}
    8000224e:	70e2                	ld	ra,56(sp)
    80002250:	7442                	ld	s0,48(sp)
    80002252:	74a2                	ld	s1,40(sp)
    80002254:	7902                	ld	s2,32(sp)
    80002256:	69e2                	ld	s3,24(sp)
    80002258:	6a42                	ld	s4,16(sp)
    8000225a:	6aa2                	ld	s5,8(sp)
    8000225c:	6121                	addi	sp,sp,64
    8000225e:	8082                	ret

0000000080002260 <reparent>:
{
    80002260:	7179                	addi	sp,sp,-48
    80002262:	f406                	sd	ra,40(sp)
    80002264:	f022                	sd	s0,32(sp)
    80002266:	ec26                	sd	s1,24(sp)
    80002268:	e84a                	sd	s2,16(sp)
    8000226a:	e44e                	sd	s3,8(sp)
    8000226c:	e052                	sd	s4,0(sp)
    8000226e:	1800                	addi	s0,sp,48
    80002270:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002272:	0000f497          	auipc	s1,0xf
    80002276:	45e48493          	addi	s1,s1,1118 # 800116d0 <proc>
      pp->parent = initproc;
    8000227a:	00007a17          	auipc	s4,0x7
    8000227e:	daea0a13          	addi	s4,s4,-594 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002282:	00015997          	auipc	s3,0x15
    80002286:	e4e98993          	addi	s3,s3,-434 # 800170d0 <tickslock>
    8000228a:	a029                	j	80002294 <reparent+0x34>
    8000228c:	16848493          	addi	s1,s1,360
    80002290:	01348d63          	beq	s1,s3,800022aa <reparent+0x4a>
    if (pp->parent == p)
    80002294:	7c9c                	ld	a5,56(s1)
    80002296:	ff279be3          	bne	a5,s2,8000228c <reparent+0x2c>
      pp->parent = initproc;
    8000229a:	000a3503          	ld	a0,0(s4)
    8000229e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	f4a080e7          	jalr	-182(ra) # 800021ea <wakeup>
    800022a8:	b7d5                	j	8000228c <reparent+0x2c>
}
    800022aa:	70a2                	ld	ra,40(sp)
    800022ac:	7402                	ld	s0,32(sp)
    800022ae:	64e2                	ld	s1,24(sp)
    800022b0:	6942                	ld	s2,16(sp)
    800022b2:	69a2                	ld	s3,8(sp)
    800022b4:	6a02                	ld	s4,0(sp)
    800022b6:	6145                	addi	sp,sp,48
    800022b8:	8082                	ret

00000000800022ba <exit>:
{
    800022ba:	7179                	addi	sp,sp,-48
    800022bc:	f406                	sd	ra,40(sp)
    800022be:	f022                	sd	s0,32(sp)
    800022c0:	ec26                	sd	s1,24(sp)
    800022c2:	e84a                	sd	s2,16(sp)
    800022c4:	e44e                	sd	s3,8(sp)
    800022c6:	e052                	sd	s4,0(sp)
    800022c8:	1800                	addi	s0,sp,48
    800022ca:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	6c6080e7          	jalr	1734(ra) # 80001992 <myproc>
    800022d4:	89aa                	mv	s3,a0
  if (p == initproc)
    800022d6:	00007797          	auipc	a5,0x7
    800022da:	d527b783          	ld	a5,-686(a5) # 80009028 <initproc>
    800022de:	0d050493          	addi	s1,a0,208
    800022e2:	15050913          	addi	s2,a0,336
    800022e6:	02a79363          	bne	a5,a0,8000230c <exit+0x52>
    panic("init exiting");
    800022ea:	00006517          	auipc	a0,0x6
    800022ee:	f5e50513          	addi	a0,a0,-162 # 80008248 <digits+0x208>
    800022f2:	ffffe097          	auipc	ra,0xffffe
    800022f6:	238080e7          	jalr	568(ra) # 8000052a <panic>
      fileclose(f);
    800022fa:	00002097          	auipc	ra,0x2
    800022fe:	2ca080e7          	jalr	714(ra) # 800045c4 <fileclose>
      p->ofile[fd] = 0;
    80002302:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002306:	04a1                	addi	s1,s1,8
    80002308:	01248563          	beq	s1,s2,80002312 <exit+0x58>
    if (p->ofile[fd])
    8000230c:	6088                	ld	a0,0(s1)
    8000230e:	f575                	bnez	a0,800022fa <exit+0x40>
    80002310:	bfdd                	j	80002306 <exit+0x4c>
  begin_op();
    80002312:	00002097          	auipc	ra,0x2
    80002316:	de6080e7          	jalr	-538(ra) # 800040f8 <begin_op>
  iput(p->cwd);
    8000231a:	1509b503          	ld	a0,336(s3)
    8000231e:	00001097          	auipc	ra,0x1
    80002322:	5be080e7          	jalr	1470(ra) # 800038dc <iput>
  end_op();
    80002326:	00002097          	auipc	ra,0x2
    8000232a:	e52080e7          	jalr	-430(ra) # 80004178 <end_op>
  p->cwd = 0;
    8000232e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002332:	0000f497          	auipc	s1,0xf
    80002336:	f8648493          	addi	s1,s1,-122 # 800112b8 <wait_lock>
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	886080e7          	jalr	-1914(ra) # 80000bc2 <acquire>
  reparent(p);
    80002344:	854e                	mv	a0,s3
    80002346:	00000097          	auipc	ra,0x0
    8000234a:	f1a080e7          	jalr	-230(ra) # 80002260 <reparent>
  wakeup(p->parent);
    8000234e:	0389b503          	ld	a0,56(s3)
    80002352:	00000097          	auipc	ra,0x0
    80002356:	e98080e7          	jalr	-360(ra) # 800021ea <wakeup>
  acquire(&p->lock);
    8000235a:	854e                	mv	a0,s3
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	866080e7          	jalr	-1946(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002364:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002368:	4795                	li	a5,5
    8000236a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	906080e7          	jalr	-1786(ra) # 80000c76 <release>
  sched();
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	bd4080e7          	jalr	-1068(ra) # 80001f4c <sched>
  panic("zombie exit");
    80002380:	00006517          	auipc	a0,0x6
    80002384:	ed850513          	addi	a0,a0,-296 # 80008258 <digits+0x218>
    80002388:	ffffe097          	auipc	ra,0xffffe
    8000238c:	1a2080e7          	jalr	418(ra) # 8000052a <panic>

0000000080002390 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002390:	7179                	addi	sp,sp,-48
    80002392:	f406                	sd	ra,40(sp)
    80002394:	f022                	sd	s0,32(sp)
    80002396:	ec26                	sd	s1,24(sp)
    80002398:	e84a                	sd	s2,16(sp)
    8000239a:	e44e                	sd	s3,8(sp)
    8000239c:	1800                	addi	s0,sp,48
    8000239e:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023a0:	0000f497          	auipc	s1,0xf
    800023a4:	33048493          	addi	s1,s1,816 # 800116d0 <proc>
    800023a8:	00015997          	auipc	s3,0x15
    800023ac:	d2898993          	addi	s3,s3,-728 # 800170d0 <tickslock>
  {
    acquire(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	810080e7          	jalr	-2032(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    800023ba:	589c                	lw	a5,48(s1)
    800023bc:	01278d63          	beq	a5,s2,800023d6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8b4080e7          	jalr	-1868(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023ca:	16848493          	addi	s1,s1,360
    800023ce:	ff3491e3          	bne	s1,s3,800023b0 <kill+0x20>
  }
  return -1;
    800023d2:	557d                	li	a0,-1
    800023d4:	a829                	j	800023ee <kill+0x5e>
      p->killed = 1;
    800023d6:	4785                	li	a5,1
    800023d8:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800023da:	4c98                	lw	a4,24(s1)
    800023dc:	4789                	li	a5,2
    800023de:	00f70f63          	beq	a4,a5,800023fc <kill+0x6c>
      release(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	892080e7          	jalr	-1902(ra) # 80000c76 <release>
      return 0;
    800023ec:	4501                	li	a0,0
}
    800023ee:	70a2                	ld	ra,40(sp)
    800023f0:	7402                	ld	s0,32(sp)
    800023f2:	64e2                	ld	s1,24(sp)
    800023f4:	6942                	ld	s2,16(sp)
    800023f6:	69a2                	ld	s3,8(sp)
    800023f8:	6145                	addi	sp,sp,48
    800023fa:	8082                	ret
        p->state = RUNNABLE;
    800023fc:	478d                	li	a5,3
    800023fe:	cc9c                	sw	a5,24(s1)
    80002400:	b7cd                	j	800023e2 <kill+0x52>

0000000080002402 <trace>:

int trace(int mask, int pid)
{
    80002402:	7179                	addi	sp,sp,-48
    80002404:	f406                	sd	ra,40(sp)
    80002406:	f022                	sd	s0,32(sp)
    80002408:	ec26                	sd	s1,24(sp)
    8000240a:	e84a                	sd	s2,16(sp)
    8000240c:	e44e                	sd	s3,8(sp)
    8000240e:	e052                	sd	s4,0(sp)
    80002410:	1800                	addi	s0,sp,48
    80002412:	8a2a                	mv	s4,a0
    80002414:	892e                	mv	s2,a1
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002416:	0000f497          	auipc	s1,0xf
    8000241a:	2ba48493          	addi	s1,s1,698 # 800116d0 <proc>
    8000241e:	00015997          	auipc	s3,0x15
    80002422:	cb298993          	addi	s3,s3,-846 # 800170d0 <tickslock>
  {
    acquire(&p->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	79a080e7          	jalr	1946(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    80002430:	589c                	lw	a5,48(s1)
    80002432:	01278d63          	beq	a5,s2,8000244c <trace+0x4a>
    {
      p->traceMask = mask;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002436:	8526                	mv	a0,s1
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	83e080e7          	jalr	-1986(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002440:	16848493          	addi	s1,s1,360
    80002444:	ff3491e3          	bne	s1,s3,80002426 <trace+0x24>
  }
  return -1;
    80002448:	557d                	li	a0,-1
    8000244a:	a809                	j	8000245c <trace+0x5a>
      p->traceMask = mask;
    8000244c:	0344aa23          	sw	s4,52(s1)
      release(&p->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	824080e7          	jalr	-2012(ra) # 80000c76 <release>
      return 0;
    8000245a:	4501                	li	a0,0
}
    8000245c:	70a2                	ld	ra,40(sp)
    8000245e:	7402                	ld	s0,32(sp)
    80002460:	64e2                	ld	s1,24(sp)
    80002462:	6942                	ld	s2,16(sp)
    80002464:	69a2                	ld	s3,8(sp)
    80002466:	6a02                	ld	s4,0(sp)
    80002468:	6145                	addi	sp,sp,48
    8000246a:	8082                	ret

000000008000246c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000246c:	7179                	addi	sp,sp,-48
    8000246e:	f406                	sd	ra,40(sp)
    80002470:	f022                	sd	s0,32(sp)
    80002472:	ec26                	sd	s1,24(sp)
    80002474:	e84a                	sd	s2,16(sp)
    80002476:	e44e                	sd	s3,8(sp)
    80002478:	e052                	sd	s4,0(sp)
    8000247a:	1800                	addi	s0,sp,48
    8000247c:	84aa                	mv	s1,a0
    8000247e:	892e                	mv	s2,a1
    80002480:	89b2                	mv	s3,a2
    80002482:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	50e080e7          	jalr	1294(ra) # 80001992 <myproc>
  if (user_dst)
    8000248c:	c08d                	beqz	s1,800024ae <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000248e:	86d2                	mv	a3,s4
    80002490:	864e                	mv	a2,s3
    80002492:	85ca                	mv	a1,s2
    80002494:	6928                	ld	a0,80(a0)
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	1a8080e7          	jalr	424(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000249e:	70a2                	ld	ra,40(sp)
    800024a0:	7402                	ld	s0,32(sp)
    800024a2:	64e2                	ld	s1,24(sp)
    800024a4:	6942                	ld	s2,16(sp)
    800024a6:	69a2                	ld	s3,8(sp)
    800024a8:	6a02                	ld	s4,0(sp)
    800024aa:	6145                	addi	sp,sp,48
    800024ac:	8082                	ret
    memmove((char *)dst, src, len);
    800024ae:	000a061b          	sext.w	a2,s4
    800024b2:	85ce                	mv	a1,s3
    800024b4:	854a                	mv	a0,s2
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	864080e7          	jalr	-1948(ra) # 80000d1a <memmove>
    return 0;
    800024be:	8526                	mv	a0,s1
    800024c0:	bff9                	j	8000249e <either_copyout+0x32>

00000000800024c2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024c2:	7179                	addi	sp,sp,-48
    800024c4:	f406                	sd	ra,40(sp)
    800024c6:	f022                	sd	s0,32(sp)
    800024c8:	ec26                	sd	s1,24(sp)
    800024ca:	e84a                	sd	s2,16(sp)
    800024cc:	e44e                	sd	s3,8(sp)
    800024ce:	e052                	sd	s4,0(sp)
    800024d0:	1800                	addi	s0,sp,48
    800024d2:	892a                	mv	s2,a0
    800024d4:	84ae                	mv	s1,a1
    800024d6:	89b2                	mv	s3,a2
    800024d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	4b8080e7          	jalr	1208(ra) # 80001992 <myproc>
  if (user_src)
    800024e2:	c08d                	beqz	s1,80002504 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024e4:	86d2                	mv	a3,s4
    800024e6:	864e                	mv	a2,s3
    800024e8:	85ca                	mv	a1,s2
    800024ea:	6928                	ld	a0,80(a0)
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	1de080e7          	jalr	478(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800024f4:	70a2                	ld	ra,40(sp)
    800024f6:	7402                	ld	s0,32(sp)
    800024f8:	64e2                	ld	s1,24(sp)
    800024fa:	6942                	ld	s2,16(sp)
    800024fc:	69a2                	ld	s3,8(sp)
    800024fe:	6a02                	ld	s4,0(sp)
    80002500:	6145                	addi	sp,sp,48
    80002502:	8082                	ret
    memmove(dst, (char *)src, len);
    80002504:	000a061b          	sext.w	a2,s4
    80002508:	85ce                	mv	a1,s3
    8000250a:	854a                	mv	a0,s2
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	80e080e7          	jalr	-2034(ra) # 80000d1a <memmove>
    return 0;
    80002514:	8526                	mv	a0,s1
    80002516:	bff9                	j	800024f4 <either_copyin+0x32>

0000000080002518 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002518:	715d                	addi	sp,sp,-80
    8000251a:	e486                	sd	ra,72(sp)
    8000251c:	e0a2                	sd	s0,64(sp)
    8000251e:	fc26                	sd	s1,56(sp)
    80002520:	f84a                	sd	s2,48(sp)
    80002522:	f44e                	sd	s3,40(sp)
    80002524:	f052                	sd	s4,32(sp)
    80002526:	ec56                	sd	s5,24(sp)
    80002528:	e85a                	sd	s6,16(sp)
    8000252a:	e45e                	sd	s7,8(sp)
    8000252c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000252e:	00006517          	auipc	a0,0x6
    80002532:	b9a50513          	addi	a0,a0,-1126 # 800080c8 <digits+0x88>
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	03e080e7          	jalr	62(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000253e:	0000f497          	auipc	s1,0xf
    80002542:	2ea48493          	addi	s1,s1,746 # 80011828 <proc+0x158>
    80002546:	00015917          	auipc	s2,0x15
    8000254a:	ce290913          	addi	s2,s2,-798 # 80017228 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002550:	00006997          	auipc	s3,0x6
    80002554:	d1898993          	addi	s3,s3,-744 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002558:	00006a97          	auipc	s5,0x6
    8000255c:	d18a8a93          	addi	s5,s5,-744 # 80008270 <digits+0x230>
    printf("\n");
    80002560:	00006a17          	auipc	s4,0x6
    80002564:	b68a0a13          	addi	s4,s4,-1176 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002568:	00006b97          	auipc	s7,0x6
    8000256c:	d40b8b93          	addi	s7,s7,-704 # 800082a8 <states.0>
    80002570:	a00d                	j	80002592 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002572:	ed86a583          	lw	a1,-296(a3)
    80002576:	8556                	mv	a0,s5
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	ffc080e7          	jalr	-4(ra) # 80000574 <printf>
    printf("\n");
    80002580:	8552                	mv	a0,s4
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	ff2080e7          	jalr	-14(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000258a:	16848493          	addi	s1,s1,360
    8000258e:	03248263          	beq	s1,s2,800025b2 <procdump+0x9a>
    if (p->state == UNUSED)
    80002592:	86a6                	mv	a3,s1
    80002594:	ec04a783          	lw	a5,-320(s1)
    80002598:	dbed                	beqz	a5,8000258a <procdump+0x72>
      state = "???";
    8000259a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259c:	fcfb6be3          	bltu	s6,a5,80002572 <procdump+0x5a>
    800025a0:	02079713          	slli	a4,a5,0x20
    800025a4:	01d75793          	srli	a5,a4,0x1d
    800025a8:	97de                	add	a5,a5,s7
    800025aa:	6390                	ld	a2,0(a5)
    800025ac:	f279                	bnez	a2,80002572 <procdump+0x5a>
      state = "???";
    800025ae:	864e                	mv	a2,s3
    800025b0:	b7c9                	j	80002572 <procdump+0x5a>
  }
}
    800025b2:	60a6                	ld	ra,72(sp)
    800025b4:	6406                	ld	s0,64(sp)
    800025b6:	74e2                	ld	s1,56(sp)
    800025b8:	7942                	ld	s2,48(sp)
    800025ba:	79a2                	ld	s3,40(sp)
    800025bc:	7a02                	ld	s4,32(sp)
    800025be:	6ae2                	ld	s5,24(sp)
    800025c0:	6b42                	ld	s6,16(sp)
    800025c2:	6ba2                	ld	s7,8(sp)
    800025c4:	6161                	addi	sp,sp,80
    800025c6:	8082                	ret

00000000800025c8 <swtch>:
    800025c8:	00153023          	sd	ra,0(a0)
    800025cc:	00253423          	sd	sp,8(a0)
    800025d0:	e900                	sd	s0,16(a0)
    800025d2:	ed04                	sd	s1,24(a0)
    800025d4:	03253023          	sd	s2,32(a0)
    800025d8:	03353423          	sd	s3,40(a0)
    800025dc:	03453823          	sd	s4,48(a0)
    800025e0:	03553c23          	sd	s5,56(a0)
    800025e4:	05653023          	sd	s6,64(a0)
    800025e8:	05753423          	sd	s7,72(a0)
    800025ec:	05853823          	sd	s8,80(a0)
    800025f0:	05953c23          	sd	s9,88(a0)
    800025f4:	07a53023          	sd	s10,96(a0)
    800025f8:	07b53423          	sd	s11,104(a0)
    800025fc:	0005b083          	ld	ra,0(a1)
    80002600:	0085b103          	ld	sp,8(a1)
    80002604:	6980                	ld	s0,16(a1)
    80002606:	6d84                	ld	s1,24(a1)
    80002608:	0205b903          	ld	s2,32(a1)
    8000260c:	0285b983          	ld	s3,40(a1)
    80002610:	0305ba03          	ld	s4,48(a1)
    80002614:	0385ba83          	ld	s5,56(a1)
    80002618:	0405bb03          	ld	s6,64(a1)
    8000261c:	0485bb83          	ld	s7,72(a1)
    80002620:	0505bc03          	ld	s8,80(a1)
    80002624:	0585bc83          	ld	s9,88(a1)
    80002628:	0605bd03          	ld	s10,96(a1)
    8000262c:	0685bd83          	ld	s11,104(a1)
    80002630:	8082                	ret

0000000080002632 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002632:	1141                	addi	sp,sp,-16
    80002634:	e406                	sd	ra,8(sp)
    80002636:	e022                	sd	s0,0(sp)
    80002638:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000263a:	00006597          	auipc	a1,0x6
    8000263e:	c9e58593          	addi	a1,a1,-866 # 800082d8 <states.0+0x30>
    80002642:	00015517          	auipc	a0,0x15
    80002646:	a8e50513          	addi	a0,a0,-1394 # 800170d0 <tickslock>
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	4e8080e7          	jalr	1256(ra) # 80000b32 <initlock>
}
    80002652:	60a2                	ld	ra,8(sp)
    80002654:	6402                	ld	s0,0(sp)
    80002656:	0141                	addi	sp,sp,16
    80002658:	8082                	ret

000000008000265a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000265a:	1141                	addi	sp,sp,-16
    8000265c:	e422                	sd	s0,8(sp)
    8000265e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002660:	00003797          	auipc	a5,0x3
    80002664:	59078793          	addi	a5,a5,1424 # 80005bf0 <kernelvec>
    80002668:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000266c:	6422                	ld	s0,8(sp)
    8000266e:	0141                	addi	sp,sp,16
    80002670:	8082                	ret

0000000080002672 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002672:	1141                	addi	sp,sp,-16
    80002674:	e406                	sd	ra,8(sp)
    80002676:	e022                	sd	s0,0(sp)
    80002678:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000267a:	fffff097          	auipc	ra,0xfffff
    8000267e:	318080e7          	jalr	792(ra) # 80001992 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002682:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002686:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002688:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000268c:	00005617          	auipc	a2,0x5
    80002690:	97460613          	addi	a2,a2,-1676 # 80007000 <_trampoline>
    80002694:	00005697          	auipc	a3,0x5
    80002698:	96c68693          	addi	a3,a3,-1684 # 80007000 <_trampoline>
    8000269c:	8e91                	sub	a3,a3,a2
    8000269e:	040007b7          	lui	a5,0x4000
    800026a2:	17fd                	addi	a5,a5,-1
    800026a4:	07b2                	slli	a5,a5,0xc
    800026a6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ac:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ae:	180026f3          	csrr	a3,satp
    800026b2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026b4:	6d38                	ld	a4,88(a0)
    800026b6:	6134                	ld	a3,64(a0)
    800026b8:	6585                	lui	a1,0x1
    800026ba:	96ae                	add	a3,a3,a1
    800026bc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026be:	6d38                	ld	a4,88(a0)
    800026c0:	00000697          	auipc	a3,0x0
    800026c4:	13868693          	addi	a3,a3,312 # 800027f8 <usertrap>
    800026c8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ca:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026cc:	8692                	mv	a3,tp
    800026ce:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026d4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026d8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026dc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026e0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026e2:	6f18                	ld	a4,24(a4)
    800026e4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026e8:	692c                	ld	a1,80(a0)
    800026ea:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026ec:	00005717          	auipc	a4,0x5
    800026f0:	9a470713          	addi	a4,a4,-1628 # 80007090 <userret>
    800026f4:	8f11                	sub	a4,a4,a2
    800026f6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026f8:	577d                	li	a4,-1
    800026fa:	177e                	slli	a4,a4,0x3f
    800026fc:	8dd9                	or	a1,a1,a4
    800026fe:	02000537          	lui	a0,0x2000
    80002702:	157d                	addi	a0,a0,-1
    80002704:	0536                	slli	a0,a0,0xd
    80002706:	9782                	jalr	a5
}
    80002708:	60a2                	ld	ra,8(sp)
    8000270a:	6402                	ld	s0,0(sp)
    8000270c:	0141                	addi	sp,sp,16
    8000270e:	8082                	ret

0000000080002710 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002710:	1101                	addi	sp,sp,-32
    80002712:	ec06                	sd	ra,24(sp)
    80002714:	e822                	sd	s0,16(sp)
    80002716:	e426                	sd	s1,8(sp)
    80002718:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000271a:	00015497          	auipc	s1,0x15
    8000271e:	9b648493          	addi	s1,s1,-1610 # 800170d0 <tickslock>
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	49e080e7          	jalr	1182(ra) # 80000bc2 <acquire>
  ticks++;
    8000272c:	00007517          	auipc	a0,0x7
    80002730:	90450513          	addi	a0,a0,-1788 # 80009030 <ticks>
    80002734:	411c                	lw	a5,0(a0)
    80002736:	2785                	addiw	a5,a5,1
    80002738:	c11c                	sw	a5,0(a0)
  //start add UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE
  // end add
  wakeup(&ticks);
    8000273a:	00000097          	auipc	ra,0x0
    8000273e:	ab0080e7          	jalr	-1360(ra) # 800021ea <wakeup>
  release(&tickslock);
    80002742:	8526                	mv	a0,s1
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	532080e7          	jalr	1330(ra) # 80000c76 <release>
}
    8000274c:	60e2                	ld	ra,24(sp)
    8000274e:	6442                	ld	s0,16(sp)
    80002750:	64a2                	ld	s1,8(sp)
    80002752:	6105                	addi	sp,sp,32
    80002754:	8082                	ret

0000000080002756 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002756:	1101                	addi	sp,sp,-32
    80002758:	ec06                	sd	ra,24(sp)
    8000275a:	e822                	sd	s0,16(sp)
    8000275c:	e426                	sd	s1,8(sp)
    8000275e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002760:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002764:	00074d63          	bltz	a4,8000277e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002768:	57fd                	li	a5,-1
    8000276a:	17fe                	slli	a5,a5,0x3f
    8000276c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000276e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002770:	06f70363          	beq	a4,a5,800027d6 <devintr+0x80>
  }
}
    80002774:	60e2                	ld	ra,24(sp)
    80002776:	6442                	ld	s0,16(sp)
    80002778:	64a2                	ld	s1,8(sp)
    8000277a:	6105                	addi	sp,sp,32
    8000277c:	8082                	ret
     (scause & 0xff) == 9){
    8000277e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002782:	46a5                	li	a3,9
    80002784:	fed792e3          	bne	a5,a3,80002768 <devintr+0x12>
    int irq = plic_claim();
    80002788:	00003097          	auipc	ra,0x3
    8000278c:	570080e7          	jalr	1392(ra) # 80005cf8 <plic_claim>
    80002790:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002792:	47a9                	li	a5,10
    80002794:	02f50763          	beq	a0,a5,800027c2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002798:	4785                	li	a5,1
    8000279a:	02f50963          	beq	a0,a5,800027cc <devintr+0x76>
    return 1;
    8000279e:	4505                	li	a0,1
    } else if(irq){
    800027a0:	d8f1                	beqz	s1,80002774 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027a2:	85a6                	mv	a1,s1
    800027a4:	00006517          	auipc	a0,0x6
    800027a8:	b3c50513          	addi	a0,a0,-1220 # 800082e0 <states.0+0x38>
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	dc8080e7          	jalr	-568(ra) # 80000574 <printf>
      plic_complete(irq);
    800027b4:	8526                	mv	a0,s1
    800027b6:	00003097          	auipc	ra,0x3
    800027ba:	566080e7          	jalr	1382(ra) # 80005d1c <plic_complete>
    return 1;
    800027be:	4505                	li	a0,1
    800027c0:	bf55                	j	80002774 <devintr+0x1e>
      uartintr();
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	1c4080e7          	jalr	452(ra) # 80000986 <uartintr>
    800027ca:	b7ed                	j	800027b4 <devintr+0x5e>
      virtio_disk_intr();
    800027cc:	00004097          	auipc	ra,0x4
    800027d0:	9e2080e7          	jalr	-1566(ra) # 800061ae <virtio_disk_intr>
    800027d4:	b7c5                	j	800027b4 <devintr+0x5e>
    if(cpuid() == 0){
    800027d6:	fffff097          	auipc	ra,0xfffff
    800027da:	190080e7          	jalr	400(ra) # 80001966 <cpuid>
    800027de:	c901                	beqz	a0,800027ee <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027e0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027e6:	14479073          	csrw	sip,a5
    return 2;
    800027ea:	4509                	li	a0,2
    800027ec:	b761                	j	80002774 <devintr+0x1e>
      clockintr();
    800027ee:	00000097          	auipc	ra,0x0
    800027f2:	f22080e7          	jalr	-222(ra) # 80002710 <clockintr>
    800027f6:	b7ed                	j	800027e0 <devintr+0x8a>

00000000800027f8 <usertrap>:
{
    800027f8:	1101                	addi	sp,sp,-32
    800027fa:	ec06                	sd	ra,24(sp)
    800027fc:	e822                	sd	s0,16(sp)
    800027fe:	e426                	sd	s1,8(sp)
    80002800:	e04a                	sd	s2,0(sp)
    80002802:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002804:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002808:	1007f793          	andi	a5,a5,256
    8000280c:	e3ad                	bnez	a5,8000286e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000280e:	00003797          	auipc	a5,0x3
    80002812:	3e278793          	addi	a5,a5,994 # 80005bf0 <kernelvec>
    80002816:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	178080e7          	jalr	376(ra) # 80001992 <myproc>
    80002822:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002824:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002826:	14102773          	csrr	a4,sepc
    8000282a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000282c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002830:	47a1                	li	a5,8
    80002832:	04f71c63          	bne	a4,a5,8000288a <usertrap+0x92>
    if(p->killed)
    80002836:	551c                	lw	a5,40(a0)
    80002838:	e3b9                	bnez	a5,8000287e <usertrap+0x86>
    p->trapframe->epc += 4;
    8000283a:	6cb8                	ld	a4,88(s1)
    8000283c:	6f1c                	ld	a5,24(a4)
    8000283e:	0791                	addi	a5,a5,4
    80002840:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002842:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002846:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000284a:	10079073          	csrw	sstatus,a5
    syscall();
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	2e0080e7          	jalr	736(ra) # 80002b2e <syscall>
  if(p->killed)
    80002856:	549c                	lw	a5,40(s1)
    80002858:	ebc1                	bnez	a5,800028e8 <usertrap+0xf0>
  usertrapret();
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	e18080e7          	jalr	-488(ra) # 80002672 <usertrapret>
}
    80002862:	60e2                	ld	ra,24(sp)
    80002864:	6442                	ld	s0,16(sp)
    80002866:	64a2                	ld	s1,8(sp)
    80002868:	6902                	ld	s2,0(sp)
    8000286a:	6105                	addi	sp,sp,32
    8000286c:	8082                	ret
    panic("usertrap: not from user mode");
    8000286e:	00006517          	auipc	a0,0x6
    80002872:	a9250513          	addi	a0,a0,-1390 # 80008300 <states.0+0x58>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	cb4080e7          	jalr	-844(ra) # 8000052a <panic>
      exit(-1);
    8000287e:	557d                	li	a0,-1
    80002880:	00000097          	auipc	ra,0x0
    80002884:	a3a080e7          	jalr	-1478(ra) # 800022ba <exit>
    80002888:	bf4d                	j	8000283a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000288a:	00000097          	auipc	ra,0x0
    8000288e:	ecc080e7          	jalr	-308(ra) # 80002756 <devintr>
    80002892:	892a                	mv	s2,a0
    80002894:	c501                	beqz	a0,8000289c <usertrap+0xa4>
  if(p->killed)
    80002896:	549c                	lw	a5,40(s1)
    80002898:	c3a1                	beqz	a5,800028d8 <usertrap+0xe0>
    8000289a:	a815                	j	800028ce <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000289c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028a0:	5890                	lw	a2,48(s1)
    800028a2:	00006517          	auipc	a0,0x6
    800028a6:	a7e50513          	addi	a0,a0,-1410 # 80008320 <states.0+0x78>
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	cca080e7          	jalr	-822(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028b6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ba:	00006517          	auipc	a0,0x6
    800028be:	a9650513          	addi	a0,a0,-1386 # 80008350 <states.0+0xa8>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	cb2080e7          	jalr	-846(ra) # 80000574 <printf>
    p->killed = 1;
    800028ca:	4785                	li	a5,1
    800028cc:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028ce:	557d                	li	a0,-1
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	9ea080e7          	jalr	-1558(ra) # 800022ba <exit>
  if(which_dev == 2)
    800028d8:	4789                	li	a5,2
    800028da:	f8f910e3          	bne	s2,a5,8000285a <usertrap+0x62>
    yield();
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	744080e7          	jalr	1860(ra) # 80002022 <yield>
    800028e6:	bf95                	j	8000285a <usertrap+0x62>
  int which_dev = 0;
    800028e8:	4901                	li	s2,0
    800028ea:	b7d5                	j	800028ce <usertrap+0xd6>

00000000800028ec <kerneltrap>:
{
    800028ec:	7179                	addi	sp,sp,-48
    800028ee:	f406                	sd	ra,40(sp)
    800028f0:	f022                	sd	s0,32(sp)
    800028f2:	ec26                	sd	s1,24(sp)
    800028f4:	e84a                	sd	s2,16(sp)
    800028f6:	e44e                	sd	s3,8(sp)
    800028f8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fa:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fe:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002902:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002906:	1004f793          	andi	a5,s1,256
    8000290a:	cb85                	beqz	a5,8000293a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002910:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002912:	ef85                	bnez	a5,8000294a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002914:	00000097          	auipc	ra,0x0
    80002918:	e42080e7          	jalr	-446(ra) # 80002756 <devintr>
    8000291c:	cd1d                	beqz	a0,8000295a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000291e:	4789                	li	a5,2
    80002920:	06f50a63          	beq	a0,a5,80002994 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002924:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002928:	10049073          	csrw	sstatus,s1
}
    8000292c:	70a2                	ld	ra,40(sp)
    8000292e:	7402                	ld	s0,32(sp)
    80002930:	64e2                	ld	s1,24(sp)
    80002932:	6942                	ld	s2,16(sp)
    80002934:	69a2                	ld	s3,8(sp)
    80002936:	6145                	addi	sp,sp,48
    80002938:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	a3650513          	addi	a0,a0,-1482 # 80008370 <states.0+0xc8>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	be8080e7          	jalr	-1048(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000294a:	00006517          	auipc	a0,0x6
    8000294e:	a4e50513          	addi	a0,a0,-1458 # 80008398 <states.0+0xf0>
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	bd8080e7          	jalr	-1064(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000295a:	85ce                	mv	a1,s3
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	a5c50513          	addi	a0,a0,-1444 # 800083b8 <states.0+0x110>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c10080e7          	jalr	-1008(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000296c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002970:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002974:	00006517          	auipc	a0,0x6
    80002978:	a5450513          	addi	a0,a0,-1452 # 800083c8 <states.0+0x120>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	bf8080e7          	jalr	-1032(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002984:	00006517          	auipc	a0,0x6
    80002988:	a5c50513          	addi	a0,a0,-1444 # 800083e0 <states.0+0x138>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	b9e080e7          	jalr	-1122(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	ffe080e7          	jalr	-2(ra) # 80001992 <myproc>
    8000299c:	d541                	beqz	a0,80002924 <kerneltrap+0x38>
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	ff4080e7          	jalr	-12(ra) # 80001992 <myproc>
    800029a6:	4d18                	lw	a4,24(a0)
    800029a8:	4791                	li	a5,4
    800029aa:	f6f71de3          	bne	a4,a5,80002924 <kerneltrap+0x38>
    yield();
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	674080e7          	jalr	1652(ra) # 80002022 <yield>
    800029b6:	b7bd                	j	80002924 <kerneltrap+0x38>

00000000800029b8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029b8:	1101                	addi	sp,sp,-32
    800029ba:	ec06                	sd	ra,24(sp)
    800029bc:	e822                	sd	s0,16(sp)
    800029be:	e426                	sd	s1,8(sp)
    800029c0:	1000                	addi	s0,sp,32
    800029c2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	fce080e7          	jalr	-50(ra) # 80001992 <myproc>
  switch (n)
    800029cc:	4795                	li	a5,5
    800029ce:	0497e163          	bltu	a5,s1,80002a10 <argraw+0x58>
    800029d2:	048a                	slli	s1,s1,0x2
    800029d4:	00006717          	auipc	a4,0x6
    800029d8:	bc470713          	addi	a4,a4,-1084 # 80008598 <states.0+0x2f0>
    800029dc:	94ba                	add	s1,s1,a4
    800029de:	409c                	lw	a5,0(s1)
    800029e0:	97ba                	add	a5,a5,a4
    800029e2:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    800029e4:	6d3c                	ld	a5,88(a0)
    800029e6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029e8:	60e2                	ld	ra,24(sp)
    800029ea:	6442                	ld	s0,16(sp)
    800029ec:	64a2                	ld	s1,8(sp)
    800029ee:	6105                	addi	sp,sp,32
    800029f0:	8082                	ret
    return p->trapframe->a1;
    800029f2:	6d3c                	ld	a5,88(a0)
    800029f4:	7fa8                	ld	a0,120(a5)
    800029f6:	bfcd                	j	800029e8 <argraw+0x30>
    return p->trapframe->a2;
    800029f8:	6d3c                	ld	a5,88(a0)
    800029fa:	63c8                	ld	a0,128(a5)
    800029fc:	b7f5                	j	800029e8 <argraw+0x30>
    return p->trapframe->a3;
    800029fe:	6d3c                	ld	a5,88(a0)
    80002a00:	67c8                	ld	a0,136(a5)
    80002a02:	b7dd                	j	800029e8 <argraw+0x30>
    return p->trapframe->a4;
    80002a04:	6d3c                	ld	a5,88(a0)
    80002a06:	6bc8                	ld	a0,144(a5)
    80002a08:	b7c5                	j	800029e8 <argraw+0x30>
    return p->trapframe->a5;
    80002a0a:	6d3c                	ld	a5,88(a0)
    80002a0c:	6fc8                	ld	a0,152(a5)
    80002a0e:	bfe9                	j	800029e8 <argraw+0x30>
  panic("argraw");
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	9e050513          	addi	a0,a0,-1568 # 800083f0 <states.0+0x148>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b12080e7          	jalr	-1262(ra) # 8000052a <panic>

0000000080002a20 <fetchaddr>:
{
    80002a20:	1101                	addi	sp,sp,-32
    80002a22:	ec06                	sd	ra,24(sp)
    80002a24:	e822                	sd	s0,16(sp)
    80002a26:	e426                	sd	s1,8(sp)
    80002a28:	e04a                	sd	s2,0(sp)
    80002a2a:	1000                	addi	s0,sp,32
    80002a2c:	84aa                	mv	s1,a0
    80002a2e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	f62080e7          	jalr	-158(ra) # 80001992 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002a38:	653c                	ld	a5,72(a0)
    80002a3a:	02f4f863          	bgeu	s1,a5,80002a6a <fetchaddr+0x4a>
    80002a3e:	00848713          	addi	a4,s1,8
    80002a42:	02e7e663          	bltu	a5,a4,80002a6e <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a46:	46a1                	li	a3,8
    80002a48:	8626                	mv	a2,s1
    80002a4a:	85ca                	mv	a1,s2
    80002a4c:	6928                	ld	a0,80(a0)
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	c7c080e7          	jalr	-900(ra) # 800016ca <copyin>
    80002a56:	00a03533          	snez	a0,a0
    80002a5a:	40a00533          	neg	a0,a0
}
    80002a5e:	60e2                	ld	ra,24(sp)
    80002a60:	6442                	ld	s0,16(sp)
    80002a62:	64a2                	ld	s1,8(sp)
    80002a64:	6902                	ld	s2,0(sp)
    80002a66:	6105                	addi	sp,sp,32
    80002a68:	8082                	ret
    return -1;
    80002a6a:	557d                	li	a0,-1
    80002a6c:	bfcd                	j	80002a5e <fetchaddr+0x3e>
    80002a6e:	557d                	li	a0,-1
    80002a70:	b7fd                	j	80002a5e <fetchaddr+0x3e>

0000000080002a72 <fetchstr>:
{
    80002a72:	7179                	addi	sp,sp,-48
    80002a74:	f406                	sd	ra,40(sp)
    80002a76:	f022                	sd	s0,32(sp)
    80002a78:	ec26                	sd	s1,24(sp)
    80002a7a:	e84a                	sd	s2,16(sp)
    80002a7c:	e44e                	sd	s3,8(sp)
    80002a7e:	1800                	addi	s0,sp,48
    80002a80:	892a                	mv	s2,a0
    80002a82:	84ae                	mv	s1,a1
    80002a84:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	f0c080e7          	jalr	-244(ra) # 80001992 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a8e:	86ce                	mv	a3,s3
    80002a90:	864a                	mv	a2,s2
    80002a92:	85a6                	mv	a1,s1
    80002a94:	6928                	ld	a0,80(a0)
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	cc2080e7          	jalr	-830(ra) # 80001758 <copyinstr>
  if (err < 0)
    80002a9e:	00054763          	bltz	a0,80002aac <fetchstr+0x3a>
  return strlen(buf);
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	39e080e7          	jalr	926(ra) # 80000e42 <strlen>
}
    80002aac:	70a2                	ld	ra,40(sp)
    80002aae:	7402                	ld	s0,32(sp)
    80002ab0:	64e2                	ld	s1,24(sp)
    80002ab2:	6942                	ld	s2,16(sp)
    80002ab4:	69a2                	ld	s3,8(sp)
    80002ab6:	6145                	addi	sp,sp,48
    80002ab8:	8082                	ret

0000000080002aba <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	1000                	addi	s0,sp,32
    80002ac4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	ef2080e7          	jalr	-270(ra) # 800029b8 <argraw>
    80002ace:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ad0:	4501                	li	a0,0
    80002ad2:	60e2                	ld	ra,24(sp)
    80002ad4:	6442                	ld	s0,16(sp)
    80002ad6:	64a2                	ld	s1,8(sp)
    80002ad8:	6105                	addi	sp,sp,32
    80002ada:	8082                	ret

0000000080002adc <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002adc:	1101                	addi	sp,sp,-32
    80002ade:	ec06                	sd	ra,24(sp)
    80002ae0:	e822                	sd	s0,16(sp)
    80002ae2:	e426                	sd	s1,8(sp)
    80002ae4:	1000                	addi	s0,sp,32
    80002ae6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	ed0080e7          	jalr	-304(ra) # 800029b8 <argraw>
    80002af0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002af2:	4501                	li	a0,0
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret

0000000080002afe <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	e04a                	sd	s2,0(sp)
    80002b08:	1000                	addi	s0,sp,32
    80002b0a:	84ae                	mv	s1,a1
    80002b0c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	eaa080e7          	jalr	-342(ra) # 800029b8 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b16:	864a                	mv	a2,s2
    80002b18:	85a6                	mv	a1,s1
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	f58080e7          	jalr	-168(ra) # 80002a72 <fetchstr>
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6902                	ld	s2,0(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret

0000000080002b2e <syscall>:
    [SYS_mkdir] "sys_mkdir",
    [SYS_close] "sys_close",
    [SYS_trace] "sys_trace",
};
void syscall(void)
{
    80002b2e:	7139                	addi	sp,sp,-64
    80002b30:	fc06                	sd	ra,56(sp)
    80002b32:	f822                	sd	s0,48(sp)
    80002b34:	f426                	sd	s1,40(sp)
    80002b36:	f04a                	sd	s2,32(sp)
    80002b38:	ec4e                	sd	s3,24(sp)
    80002b3a:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	e56080e7          	jalr	-426(ra) # 80001992 <myproc>
    80002b44:	84aa                	mv	s1,a0
  int firstArg;
  num = p->trapframe->a7;
    80002b46:	05853903          	ld	s2,88(a0)
    80002b4a:	0a893783          	ld	a5,168(s2)
    80002b4e:	0007899b          	sext.w	s3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002b52:	37fd                	addiw	a5,a5,-1
    80002b54:	4755                	li	a4,21
    80002b56:	0cf76563          	bltu	a4,a5,80002c20 <syscall+0xf2>
    80002b5a:	00399713          	slli	a4,s3,0x3
    80002b5e:	00006797          	auipc	a5,0x6
    80002b62:	a5278793          	addi	a5,a5,-1454 # 800085b0 <syscalls>
    80002b66:	97ba                	add	a5,a5,a4
    80002b68:	639c                	ld	a5,0(a5)
    80002b6a:	cbdd                	beqz	a5,80002c20 <syscall+0xf2>
  {
    p->trapframe->a0 = syscalls[num]();
    80002b6c:	9782                	jalr	a5
    80002b6e:	06a93823          	sd	a0,112(s2)
    //start messing with code
    if ((p->traceMask & (1 << num)))
    80002b72:	58dc                	lw	a5,52(s1)
    80002b74:	4137d7bb          	sraw	a5,a5,s3
    80002b78:	8b85                	andi	a5,a5,1
    80002b7a:	c3f1                	beqz	a5,80002c3e <syscall+0x110>
    {
      printf("%d: syscall %s ", p->pid, syscalls_str[num]);
    80002b7c:	00399713          	slli	a4,s3,0x3
    80002b80:	00006797          	auipc	a5,0x6
    80002b84:	a3078793          	addi	a5,a5,-1488 # 800085b0 <syscalls>
    80002b88:	97ba                	add	a5,a5,a4
    80002b8a:	7fd0                	ld	a2,184(a5)
    80002b8c:	588c                	lw	a1,48(s1)
    80002b8e:	00006517          	auipc	a0,0x6
    80002b92:	86a50513          	addi	a0,a0,-1942 # 800083f8 <states.0+0x150>
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	9de080e7          	jalr	-1570(ra) # 80000574 <printf>
      if (num == SYS_fork)
    80002b9e:	4785                	li	a5,1
    80002ba0:	02f98363          	beq	s3,a5,80002bc6 <syscall+0x98>
      {
        printf("NULL ");
      }
      if (num == SYS_kill)
    80002ba4:	4799                	li	a5,6
    80002ba6:	02f98963          	beq	s3,a5,80002bd8 <syscall+0xaa>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      if (num == SYS_sbrk)
    80002baa:	47b1                	li	a5,12
    80002bac:	04f98863          	beq	s3,a5,80002bfc <syscall+0xce>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      printf("-> %d\n", p->trapframe->a0);
    80002bb0:	6cbc                	ld	a5,88(s1)
    80002bb2:	7bac                	ld	a1,112(a5)
    80002bb4:	00006517          	auipc	a0,0x6
    80002bb8:	86450513          	addi	a0,a0,-1948 # 80008418 <states.0+0x170>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	9b8080e7          	jalr	-1608(ra) # 80000574 <printf>
    80002bc4:	a8ad                	j	80002c3e <syscall+0x110>
        printf("NULL ");
    80002bc6:	00006517          	auipc	a0,0x6
    80002bca:	84250513          	addi	a0,a0,-1982 # 80008408 <states.0+0x160>
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	9a6080e7          	jalr	-1626(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002bd6:	bfe9                	j	80002bb0 <syscall+0x82>
        argint(0, &firstArg);
    80002bd8:	fcc40593          	addi	a1,s0,-52
    80002bdc:	4501                	li	a0,0
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	edc080e7          	jalr	-292(ra) # 80002aba <argint>
        printf("%d ", firstArg);
    80002be6:	fcc42583          	lw	a1,-52(s0)
    80002bea:	00006517          	auipc	a0,0x6
    80002bee:	82650513          	addi	a0,a0,-2010 # 80008410 <states.0+0x168>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	982080e7          	jalr	-1662(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002bfa:	bf5d                	j	80002bb0 <syscall+0x82>
        argint(0, &firstArg);
    80002bfc:	fcc40593          	addi	a1,s0,-52
    80002c00:	4501                	li	a0,0
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	eb8080e7          	jalr	-328(ra) # 80002aba <argint>
        printf("%d ", firstArg);
    80002c0a:	fcc42583          	lw	a1,-52(s0)
    80002c0e:	00006517          	auipc	a0,0x6
    80002c12:	80250513          	addi	a0,a0,-2046 # 80008410 <states.0+0x168>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	95e080e7          	jalr	-1698(ra) # 80000574 <printf>
    80002c1e:	bf49                	j	80002bb0 <syscall+0x82>
    }
    //end messing with code
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002c20:	86ce                	mv	a3,s3
    80002c22:	15848613          	addi	a2,s1,344
    80002c26:	588c                	lw	a1,48(s1)
    80002c28:	00005517          	auipc	a0,0x5
    80002c2c:	7f850513          	addi	a0,a0,2040 # 80008420 <states.0+0x178>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	944080e7          	jalr	-1724(ra) # 80000574 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c38:	6cbc                	ld	a5,88(s1)
    80002c3a:	577d                	li	a4,-1
    80002c3c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c3e:	70e2                	ld	ra,56(sp)
    80002c40:	7442                	ld	s0,48(sp)
    80002c42:	74a2                	ld	s1,40(sp)
    80002c44:	7902                	ld	s2,32(sp)
    80002c46:	69e2                	ld	s3,24(sp)
    80002c48:	6121                	addi	sp,sp,64
    80002c4a:	8082                	ret

0000000080002c4c <sys_trace>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_trace(void)
{
    80002c4c:	1101                	addi	sp,sp,-32
    80002c4e:	ec06                	sd	ra,24(sp)
    80002c50:	e822                	sd	s0,16(sp)
    80002c52:	1000                	addi	s0,sp,32
  int mask;
  int pid;
  argint(0, &mask);
    80002c54:	fec40593          	addi	a1,s0,-20
    80002c58:	4501                	li	a0,0
    80002c5a:	00000097          	auipc	ra,0x0
    80002c5e:	e60080e7          	jalr	-416(ra) # 80002aba <argint>
  if(argint(1, &pid) < 0)
    80002c62:	fe840593          	addi	a1,s0,-24
    80002c66:	4505                	li	a0,1
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	e52080e7          	jalr	-430(ra) # 80002aba <argint>
    80002c70:	87aa                	mv	a5,a0
    return -1;
    80002c72:	557d                	li	a0,-1
  if(argint(1, &pid) < 0)
    80002c74:	0007ca63          	bltz	a5,80002c88 <sys_trace+0x3c>
  return trace(mask, pid);
    80002c78:	fe842583          	lw	a1,-24(s0)
    80002c7c:	fec42503          	lw	a0,-20(s0)
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	782080e7          	jalr	1922(ra) # 80002402 <trace>
}
    80002c88:	60e2                	ld	ra,24(sp)
    80002c8a:	6442                	ld	s0,16(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <sys_exit>:

uint64
sys_exit(void)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c98:	fec40593          	addi	a1,s0,-20
    80002c9c:	4501                	li	a0,0
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	e1c080e7          	jalr	-484(ra) # 80002aba <argint>
    return -1;
    80002ca6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca8:	00054963          	bltz	a0,80002cba <sys_exit+0x2a>
  exit(n);
    80002cac:	fec42503          	lw	a0,-20(s0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	60a080e7          	jalr	1546(ra) # 800022ba <exit>
  return 0;  // not reached
    80002cb8:	4781                	li	a5,0
}
    80002cba:	853e                	mv	a0,a5
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret

0000000080002cc4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e406                	sd	ra,8(sp)
    80002cc8:	e022                	sd	s0,0(sp)
    80002cca:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	cc6080e7          	jalr	-826(ra) # 80001992 <myproc>
}
    80002cd4:	5908                	lw	a0,48(a0)
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <sys_fork>:

uint64
sys_fork(void)
{
    80002cde:	1141                	addi	sp,sp,-16
    80002ce0:	e406                	sd	ra,8(sp)
    80002ce2:	e022                	sd	s0,0(sp)
    80002ce4:	0800                	addi	s0,sp,16
  return fork();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	07e080e7          	jalr	126(ra) # 80001d64 <fork>
}
    80002cee:	60a2                	ld	ra,8(sp)
    80002cf0:	6402                	ld	s0,0(sp)
    80002cf2:	0141                	addi	sp,sp,16
    80002cf4:	8082                	ret

0000000080002cf6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cfe:	fe840593          	addi	a1,s0,-24
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	dd8080e7          	jalr	-552(ra) # 80002adc <argaddr>
    80002d0c:	87aa                	mv	a5,a0
    return -1;
    80002d0e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d10:	0007c863          	bltz	a5,80002d20 <sys_wait+0x2a>
  return wait(p);
    80002d14:	fe843503          	ld	a0,-24(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	3aa080e7          	jalr	938(ra) # 800020c2 <wait>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d28:	7179                	addi	sp,sp,-48
    80002d2a:	f406                	sd	ra,40(sp)
    80002d2c:	f022                	sd	s0,32(sp)
    80002d2e:	ec26                	sd	s1,24(sp)
    80002d30:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d32:	fdc40593          	addi	a1,s0,-36
    80002d36:	4501                	li	a0,0
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	d82080e7          	jalr	-638(ra) # 80002aba <argint>
    return -1;
    80002d40:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d42:	00054f63          	bltz	a0,80002d60 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	c4c080e7          	jalr	-948(ra) # 80001992 <myproc>
    80002d4e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d50:	fdc42503          	lw	a0,-36(s0)
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	f9c080e7          	jalr	-100(ra) # 80001cf0 <growproc>
    80002d5c:	00054863          	bltz	a0,80002d6c <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002d60:	8526                	mv	a0,s1
    80002d62:	70a2                	ld	ra,40(sp)
    80002d64:	7402                	ld	s0,32(sp)
    80002d66:	64e2                	ld	s1,24(sp)
    80002d68:	6145                	addi	sp,sp,48
    80002d6a:	8082                	ret
    return -1;
    80002d6c:	54fd                	li	s1,-1
    80002d6e:	bfcd                	j	80002d60 <sys_sbrk+0x38>

0000000080002d70 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d70:	7139                	addi	sp,sp,-64
    80002d72:	fc06                	sd	ra,56(sp)
    80002d74:	f822                	sd	s0,48(sp)
    80002d76:	f426                	sd	s1,40(sp)
    80002d78:	f04a                	sd	s2,32(sp)
    80002d7a:	ec4e                	sd	s3,24(sp)
    80002d7c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d7e:	fcc40593          	addi	a1,s0,-52
    80002d82:	4501                	li	a0,0
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	d36080e7          	jalr	-714(ra) # 80002aba <argint>
    return -1;
    80002d8c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d8e:	06054563          	bltz	a0,80002df8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d92:	00014517          	auipc	a0,0x14
    80002d96:	33e50513          	addi	a0,a0,830 # 800170d0 <tickslock>
    80002d9a:	ffffe097          	auipc	ra,0xffffe
    80002d9e:	e28080e7          	jalr	-472(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002da2:	00006917          	auipc	s2,0x6
    80002da6:	28e92903          	lw	s2,654(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002daa:	fcc42783          	lw	a5,-52(s0)
    80002dae:	cf85                	beqz	a5,80002de6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db0:	00014997          	auipc	s3,0x14
    80002db4:	32098993          	addi	s3,s3,800 # 800170d0 <tickslock>
    80002db8:	00006497          	auipc	s1,0x6
    80002dbc:	27848493          	addi	s1,s1,632 # 80009030 <ticks>
    if(myproc()->killed){
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	bd2080e7          	jalr	-1070(ra) # 80001992 <myproc>
    80002dc8:	551c                	lw	a5,40(a0)
    80002dca:	ef9d                	bnez	a5,80002e08 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dcc:	85ce                	mv	a1,s3
    80002dce:	8526                	mv	a0,s1
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	28e080e7          	jalr	654(ra) # 8000205e <sleep>
  while(ticks - ticks0 < n){
    80002dd8:	409c                	lw	a5,0(s1)
    80002dda:	412787bb          	subw	a5,a5,s2
    80002dde:	fcc42703          	lw	a4,-52(s0)
    80002de2:	fce7efe3          	bltu	a5,a4,80002dc0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002de6:	00014517          	auipc	a0,0x14
    80002dea:	2ea50513          	addi	a0,a0,746 # 800170d0 <tickslock>
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	e88080e7          	jalr	-376(ra) # 80000c76 <release>
  return 0;
    80002df6:	4781                	li	a5,0
}
    80002df8:	853e                	mv	a0,a5
    80002dfa:	70e2                	ld	ra,56(sp)
    80002dfc:	7442                	ld	s0,48(sp)
    80002dfe:	74a2                	ld	s1,40(sp)
    80002e00:	7902                	ld	s2,32(sp)
    80002e02:	69e2                	ld	s3,24(sp)
    80002e04:	6121                	addi	sp,sp,64
    80002e06:	8082                	ret
      release(&tickslock);
    80002e08:	00014517          	auipc	a0,0x14
    80002e0c:	2c850513          	addi	a0,a0,712 # 800170d0 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	e66080e7          	jalr	-410(ra) # 80000c76 <release>
      return -1;
    80002e18:	57fd                	li	a5,-1
    80002e1a:	bff9                	j	80002df8 <sys_sleep+0x88>

0000000080002e1c <sys_kill>:

uint64
sys_kill(void)
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e24:	fec40593          	addi	a1,s0,-20
    80002e28:	4501                	li	a0,0
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	c90080e7          	jalr	-880(ra) # 80002aba <argint>
    80002e32:	87aa                	mv	a5,a0
    return -1;
    80002e34:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e36:	0007c863          	bltz	a5,80002e46 <sys_kill+0x2a>
  return kill(pid);
    80002e3a:	fec42503          	lw	a0,-20(s0)
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	552080e7          	jalr	1362(ra) # 80002390 <kill>
}
    80002e46:	60e2                	ld	ra,24(sp)
    80002e48:	6442                	ld	s0,16(sp)
    80002e4a:	6105                	addi	sp,sp,32
    80002e4c:	8082                	ret

0000000080002e4e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e58:	00014517          	auipc	a0,0x14
    80002e5c:	27850513          	addi	a0,a0,632 # 800170d0 <tickslock>
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	d62080e7          	jalr	-670(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002e68:	00006497          	auipc	s1,0x6
    80002e6c:	1c84a483          	lw	s1,456(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e70:	00014517          	auipc	a0,0x14
    80002e74:	26050513          	addi	a0,a0,608 # 800170d0 <tickslock>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	dfe080e7          	jalr	-514(ra) # 80000c76 <release>
  return xticks;
}
    80002e80:	02049513          	slli	a0,s1,0x20
    80002e84:	9101                	srli	a0,a0,0x20
    80002e86:	60e2                	ld	ra,24(sp)
    80002e88:	6442                	ld	s0,16(sp)
    80002e8a:	64a2                	ld	s1,8(sp)
    80002e8c:	6105                	addi	sp,sp,32
    80002e8e:	8082                	ret

0000000080002e90 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e90:	7179                	addi	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	e84a                	sd	s2,16(sp)
    80002e9a:	e44e                	sd	s3,8(sp)
    80002e9c:	e052                	sd	s4,0(sp)
    80002e9e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ea0:	00006597          	auipc	a1,0x6
    80002ea4:	88058593          	addi	a1,a1,-1920 # 80008720 <syscalls_str+0xb8>
    80002ea8:	00014517          	auipc	a0,0x14
    80002eac:	24050513          	addi	a0,a0,576 # 800170e8 <bcache>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	c82080e7          	jalr	-894(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eb8:	0001c797          	auipc	a5,0x1c
    80002ebc:	23078793          	addi	a5,a5,560 # 8001f0e8 <bcache+0x8000>
    80002ec0:	0001c717          	auipc	a4,0x1c
    80002ec4:	49070713          	addi	a4,a4,1168 # 8001f350 <bcache+0x8268>
    80002ec8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ecc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed0:	00014497          	auipc	s1,0x14
    80002ed4:	23048493          	addi	s1,s1,560 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002ed8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eda:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002edc:	00006a17          	auipc	s4,0x6
    80002ee0:	84ca0a13          	addi	s4,s4,-1972 # 80008728 <syscalls_str+0xc0>
    b->next = bcache.head.next;
    80002ee4:	2b893783          	ld	a5,696(s2)
    80002ee8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eea:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002eee:	85d2                	mv	a1,s4
    80002ef0:	01048513          	addi	a0,s1,16
    80002ef4:	00001097          	auipc	ra,0x1
    80002ef8:	4c2080e7          	jalr	1218(ra) # 800043b6 <initsleeplock>
    bcache.head.next->prev = b;
    80002efc:	2b893783          	ld	a5,696(s2)
    80002f00:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f02:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f06:	45848493          	addi	s1,s1,1112
    80002f0a:	fd349de3          	bne	s1,s3,80002ee4 <binit+0x54>
  }
}
    80002f0e:	70a2                	ld	ra,40(sp)
    80002f10:	7402                	ld	s0,32(sp)
    80002f12:	64e2                	ld	s1,24(sp)
    80002f14:	6942                	ld	s2,16(sp)
    80002f16:	69a2                	ld	s3,8(sp)
    80002f18:	6a02                	ld	s4,0(sp)
    80002f1a:	6145                	addi	sp,sp,48
    80002f1c:	8082                	ret

0000000080002f1e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f1e:	7179                	addi	sp,sp,-48
    80002f20:	f406                	sd	ra,40(sp)
    80002f22:	f022                	sd	s0,32(sp)
    80002f24:	ec26                	sd	s1,24(sp)
    80002f26:	e84a                	sd	s2,16(sp)
    80002f28:	e44e                	sd	s3,8(sp)
    80002f2a:	1800                	addi	s0,sp,48
    80002f2c:	892a                	mv	s2,a0
    80002f2e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f30:	00014517          	auipc	a0,0x14
    80002f34:	1b850513          	addi	a0,a0,440 # 800170e8 <bcache>
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	c8a080e7          	jalr	-886(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f40:	0001c497          	auipc	s1,0x1c
    80002f44:	4604b483          	ld	s1,1120(s1) # 8001f3a0 <bcache+0x82b8>
    80002f48:	0001c797          	auipc	a5,0x1c
    80002f4c:	40878793          	addi	a5,a5,1032 # 8001f350 <bcache+0x8268>
    80002f50:	02f48f63          	beq	s1,a5,80002f8e <bread+0x70>
    80002f54:	873e                	mv	a4,a5
    80002f56:	a021                	j	80002f5e <bread+0x40>
    80002f58:	68a4                	ld	s1,80(s1)
    80002f5a:	02e48a63          	beq	s1,a4,80002f8e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f5e:	449c                	lw	a5,8(s1)
    80002f60:	ff279ce3          	bne	a5,s2,80002f58 <bread+0x3a>
    80002f64:	44dc                	lw	a5,12(s1)
    80002f66:	ff3799e3          	bne	a5,s3,80002f58 <bread+0x3a>
      b->refcnt++;
    80002f6a:	40bc                	lw	a5,64(s1)
    80002f6c:	2785                	addiw	a5,a5,1
    80002f6e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f70:	00014517          	auipc	a0,0x14
    80002f74:	17850513          	addi	a0,a0,376 # 800170e8 <bcache>
    80002f78:	ffffe097          	auipc	ra,0xffffe
    80002f7c:	cfe080e7          	jalr	-770(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002f80:	01048513          	addi	a0,s1,16
    80002f84:	00001097          	auipc	ra,0x1
    80002f88:	46c080e7          	jalr	1132(ra) # 800043f0 <acquiresleep>
      return b;
    80002f8c:	a8b9                	j	80002fea <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f8e:	0001c497          	auipc	s1,0x1c
    80002f92:	40a4b483          	ld	s1,1034(s1) # 8001f398 <bcache+0x82b0>
    80002f96:	0001c797          	auipc	a5,0x1c
    80002f9a:	3ba78793          	addi	a5,a5,954 # 8001f350 <bcache+0x8268>
    80002f9e:	00f48863          	beq	s1,a5,80002fae <bread+0x90>
    80002fa2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fa4:	40bc                	lw	a5,64(s1)
    80002fa6:	cf81                	beqz	a5,80002fbe <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa8:	64a4                	ld	s1,72(s1)
    80002faa:	fee49de3          	bne	s1,a4,80002fa4 <bread+0x86>
  panic("bget: no buffers");
    80002fae:	00005517          	auipc	a0,0x5
    80002fb2:	78250513          	addi	a0,a0,1922 # 80008730 <syscalls_str+0xc8>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	574080e7          	jalr	1396(ra) # 8000052a <panic>
      b->dev = dev;
    80002fbe:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fc2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fc6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fca:	4785                	li	a5,1
    80002fcc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fce:	00014517          	auipc	a0,0x14
    80002fd2:	11a50513          	addi	a0,a0,282 # 800170e8 <bcache>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	ca0080e7          	jalr	-864(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002fde:	01048513          	addi	a0,s1,16
    80002fe2:	00001097          	auipc	ra,0x1
    80002fe6:	40e080e7          	jalr	1038(ra) # 800043f0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fea:	409c                	lw	a5,0(s1)
    80002fec:	cb89                	beqz	a5,80002ffe <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fee:	8526                	mv	a0,s1
    80002ff0:	70a2                	ld	ra,40(sp)
    80002ff2:	7402                	ld	s0,32(sp)
    80002ff4:	64e2                	ld	s1,24(sp)
    80002ff6:	6942                	ld	s2,16(sp)
    80002ff8:	69a2                	ld	s3,8(sp)
    80002ffa:	6145                	addi	sp,sp,48
    80002ffc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ffe:	4581                	li	a1,0
    80003000:	8526                	mv	a0,s1
    80003002:	00003097          	auipc	ra,0x3
    80003006:	f24080e7          	jalr	-220(ra) # 80005f26 <virtio_disk_rw>
    b->valid = 1;
    8000300a:	4785                	li	a5,1
    8000300c:	c09c                	sw	a5,0(s1)
  return b;
    8000300e:	b7c5                	j	80002fee <bread+0xd0>

0000000080003010 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003010:	1101                	addi	sp,sp,-32
    80003012:	ec06                	sd	ra,24(sp)
    80003014:	e822                	sd	s0,16(sp)
    80003016:	e426                	sd	s1,8(sp)
    80003018:	1000                	addi	s0,sp,32
    8000301a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000301c:	0541                	addi	a0,a0,16
    8000301e:	00001097          	auipc	ra,0x1
    80003022:	46c080e7          	jalr	1132(ra) # 8000448a <holdingsleep>
    80003026:	cd01                	beqz	a0,8000303e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003028:	4585                	li	a1,1
    8000302a:	8526                	mv	a0,s1
    8000302c:	00003097          	auipc	ra,0x3
    80003030:	efa080e7          	jalr	-262(ra) # 80005f26 <virtio_disk_rw>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret
    panic("bwrite");
    8000303e:	00005517          	auipc	a0,0x5
    80003042:	70a50513          	addi	a0,a0,1802 # 80008748 <syscalls_str+0xe0>
    80003046:	ffffd097          	auipc	ra,0xffffd
    8000304a:	4e4080e7          	jalr	1252(ra) # 8000052a <panic>

000000008000304e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000304e:	1101                	addi	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	e426                	sd	s1,8(sp)
    80003056:	e04a                	sd	s2,0(sp)
    80003058:	1000                	addi	s0,sp,32
    8000305a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000305c:	01050913          	addi	s2,a0,16
    80003060:	854a                	mv	a0,s2
    80003062:	00001097          	auipc	ra,0x1
    80003066:	428080e7          	jalr	1064(ra) # 8000448a <holdingsleep>
    8000306a:	c92d                	beqz	a0,800030dc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000306c:	854a                	mv	a0,s2
    8000306e:	00001097          	auipc	ra,0x1
    80003072:	3d8080e7          	jalr	984(ra) # 80004446 <releasesleep>

  acquire(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	07250513          	addi	a0,a0,114 # 800170e8 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	b44080e7          	jalr	-1212(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003086:	40bc                	lw	a5,64(s1)
    80003088:	37fd                	addiw	a5,a5,-1
    8000308a:	0007871b          	sext.w	a4,a5
    8000308e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003090:	eb05                	bnez	a4,800030c0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003092:	68bc                	ld	a5,80(s1)
    80003094:	64b8                	ld	a4,72(s1)
    80003096:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003098:	64bc                	ld	a5,72(s1)
    8000309a:	68b8                	ld	a4,80(s1)
    8000309c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000309e:	0001c797          	auipc	a5,0x1c
    800030a2:	04a78793          	addi	a5,a5,74 # 8001f0e8 <bcache+0x8000>
    800030a6:	2b87b703          	ld	a4,696(a5)
    800030aa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030ac:	0001c717          	auipc	a4,0x1c
    800030b0:	2a470713          	addi	a4,a4,676 # 8001f350 <bcache+0x8268>
    800030b4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030b6:	2b87b703          	ld	a4,696(a5)
    800030ba:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030bc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030c0:	00014517          	auipc	a0,0x14
    800030c4:	02850513          	addi	a0,a0,40 # 800170e8 <bcache>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	bae080e7          	jalr	-1106(ra) # 80000c76 <release>
}
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6902                	ld	s2,0(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret
    panic("brelse");
    800030dc:	00005517          	auipc	a0,0x5
    800030e0:	67450513          	addi	a0,a0,1652 # 80008750 <syscalls_str+0xe8>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	446080e7          	jalr	1094(ra) # 8000052a <panic>

00000000800030ec <bpin>:

void
bpin(struct buf *b) {
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	e426                	sd	s1,8(sp)
    800030f4:	1000                	addi	s0,sp,32
    800030f6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	ff050513          	addi	a0,a0,-16 # 800170e8 <bcache>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	ac2080e7          	jalr	-1342(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003108:	40bc                	lw	a5,64(s1)
    8000310a:	2785                	addiw	a5,a5,1
    8000310c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000310e:	00014517          	auipc	a0,0x14
    80003112:	fda50513          	addi	a0,a0,-38 # 800170e8 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b60080e7          	jalr	-1184(ra) # 80000c76 <release>
}
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	64a2                	ld	s1,8(sp)
    80003124:	6105                	addi	sp,sp,32
    80003126:	8082                	ret

0000000080003128 <bunpin>:

void
bunpin(struct buf *b) {
    80003128:	1101                	addi	sp,sp,-32
    8000312a:	ec06                	sd	ra,24(sp)
    8000312c:	e822                	sd	s0,16(sp)
    8000312e:	e426                	sd	s1,8(sp)
    80003130:	1000                	addi	s0,sp,32
    80003132:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	fb450513          	addi	a0,a0,-76 # 800170e8 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	a86080e7          	jalr	-1402(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003144:	40bc                	lw	a5,64(s1)
    80003146:	37fd                	addiw	a5,a5,-1
    80003148:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000314a:	00014517          	auipc	a0,0x14
    8000314e:	f9e50513          	addi	a0,a0,-98 # 800170e8 <bcache>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b24080e7          	jalr	-1244(ra) # 80000c76 <release>
}
    8000315a:	60e2                	ld	ra,24(sp)
    8000315c:	6442                	ld	s0,16(sp)
    8000315e:	64a2                	ld	s1,8(sp)
    80003160:	6105                	addi	sp,sp,32
    80003162:	8082                	ret

0000000080003164 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	e04a                	sd	s2,0(sp)
    8000316e:	1000                	addi	s0,sp,32
    80003170:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003172:	00d5d59b          	srliw	a1,a1,0xd
    80003176:	0001c797          	auipc	a5,0x1c
    8000317a:	64e7a783          	lw	a5,1614(a5) # 8001f7c4 <sb+0x1c>
    8000317e:	9dbd                	addw	a1,a1,a5
    80003180:	00000097          	auipc	ra,0x0
    80003184:	d9e080e7          	jalr	-610(ra) # 80002f1e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003188:	0074f713          	andi	a4,s1,7
    8000318c:	4785                	li	a5,1
    8000318e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003192:	14ce                	slli	s1,s1,0x33
    80003194:	90d9                	srli	s1,s1,0x36
    80003196:	00950733          	add	a4,a0,s1
    8000319a:	05874703          	lbu	a4,88(a4)
    8000319e:	00e7f6b3          	and	a3,a5,a4
    800031a2:	c69d                	beqz	a3,800031d0 <bfree+0x6c>
    800031a4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031a6:	94aa                	add	s1,s1,a0
    800031a8:	fff7c793          	not	a5,a5
    800031ac:	8ff9                	and	a5,a5,a4
    800031ae:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031b2:	00001097          	auipc	ra,0x1
    800031b6:	11e080e7          	jalr	286(ra) # 800042d0 <log_write>
  brelse(bp);
    800031ba:	854a                	mv	a0,s2
    800031bc:	00000097          	auipc	ra,0x0
    800031c0:	e92080e7          	jalr	-366(ra) # 8000304e <brelse>
}
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	64a2                	ld	s1,8(sp)
    800031ca:	6902                	ld	s2,0(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret
    panic("freeing free block");
    800031d0:	00005517          	auipc	a0,0x5
    800031d4:	58850513          	addi	a0,a0,1416 # 80008758 <syscalls_str+0xf0>
    800031d8:	ffffd097          	auipc	ra,0xffffd
    800031dc:	352080e7          	jalr	850(ra) # 8000052a <panic>

00000000800031e0 <balloc>:
{
    800031e0:	711d                	addi	sp,sp,-96
    800031e2:	ec86                	sd	ra,88(sp)
    800031e4:	e8a2                	sd	s0,80(sp)
    800031e6:	e4a6                	sd	s1,72(sp)
    800031e8:	e0ca                	sd	s2,64(sp)
    800031ea:	fc4e                	sd	s3,56(sp)
    800031ec:	f852                	sd	s4,48(sp)
    800031ee:	f456                	sd	s5,40(sp)
    800031f0:	f05a                	sd	s6,32(sp)
    800031f2:	ec5e                	sd	s7,24(sp)
    800031f4:	e862                	sd	s8,16(sp)
    800031f6:	e466                	sd	s9,8(sp)
    800031f8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031fa:	0001c797          	auipc	a5,0x1c
    800031fe:	5b27a783          	lw	a5,1458(a5) # 8001f7ac <sb+0x4>
    80003202:	cbd1                	beqz	a5,80003296 <balloc+0xb6>
    80003204:	8baa                	mv	s7,a0
    80003206:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003208:	0001cb17          	auipc	s6,0x1c
    8000320c:	5a0b0b13          	addi	s6,s6,1440 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003210:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003212:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003214:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003216:	6c89                	lui	s9,0x2
    80003218:	a831                	j	80003234 <balloc+0x54>
    brelse(bp);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	e32080e7          	jalr	-462(ra) # 8000304e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003224:	015c87bb          	addw	a5,s9,s5
    80003228:	00078a9b          	sext.w	s5,a5
    8000322c:	004b2703          	lw	a4,4(s6)
    80003230:	06eaf363          	bgeu	s5,a4,80003296 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003234:	41fad79b          	sraiw	a5,s5,0x1f
    80003238:	0137d79b          	srliw	a5,a5,0x13
    8000323c:	015787bb          	addw	a5,a5,s5
    80003240:	40d7d79b          	sraiw	a5,a5,0xd
    80003244:	01cb2583          	lw	a1,28(s6)
    80003248:	9dbd                	addw	a1,a1,a5
    8000324a:	855e                	mv	a0,s7
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	cd2080e7          	jalr	-814(ra) # 80002f1e <bread>
    80003254:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003256:	004b2503          	lw	a0,4(s6)
    8000325a:	000a849b          	sext.w	s1,s5
    8000325e:	8662                	mv	a2,s8
    80003260:	faa4fde3          	bgeu	s1,a0,8000321a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003264:	41f6579b          	sraiw	a5,a2,0x1f
    80003268:	01d7d69b          	srliw	a3,a5,0x1d
    8000326c:	00c6873b          	addw	a4,a3,a2
    80003270:	00777793          	andi	a5,a4,7
    80003274:	9f95                	subw	a5,a5,a3
    80003276:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000327a:	4037571b          	sraiw	a4,a4,0x3
    8000327e:	00e906b3          	add	a3,s2,a4
    80003282:	0586c683          	lbu	a3,88(a3)
    80003286:	00d7f5b3          	and	a1,a5,a3
    8000328a:	cd91                	beqz	a1,800032a6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328c:	2605                	addiw	a2,a2,1
    8000328e:	2485                	addiw	s1,s1,1
    80003290:	fd4618e3          	bne	a2,s4,80003260 <balloc+0x80>
    80003294:	b759                	j	8000321a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003296:	00005517          	auipc	a0,0x5
    8000329a:	4da50513          	addi	a0,a0,1242 # 80008770 <syscalls_str+0x108>
    8000329e:	ffffd097          	auipc	ra,0xffffd
    800032a2:	28c080e7          	jalr	652(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032a6:	974a                	add	a4,a4,s2
    800032a8:	8fd5                	or	a5,a5,a3
    800032aa:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032ae:	854a                	mv	a0,s2
    800032b0:	00001097          	auipc	ra,0x1
    800032b4:	020080e7          	jalr	32(ra) # 800042d0 <log_write>
        brelse(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	d94080e7          	jalr	-620(ra) # 8000304e <brelse>
  bp = bread(dev, bno);
    800032c2:	85a6                	mv	a1,s1
    800032c4:	855e                	mv	a0,s7
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	c58080e7          	jalr	-936(ra) # 80002f1e <bread>
    800032ce:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032d0:	40000613          	li	a2,1024
    800032d4:	4581                	li	a1,0
    800032d6:	05850513          	addi	a0,a0,88
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	9e4080e7          	jalr	-1564(ra) # 80000cbe <memset>
  log_write(bp);
    800032e2:	854a                	mv	a0,s2
    800032e4:	00001097          	auipc	ra,0x1
    800032e8:	fec080e7          	jalr	-20(ra) # 800042d0 <log_write>
  brelse(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	d60080e7          	jalr	-672(ra) # 8000304e <brelse>
}
    800032f6:	8526                	mv	a0,s1
    800032f8:	60e6                	ld	ra,88(sp)
    800032fa:	6446                	ld	s0,80(sp)
    800032fc:	64a6                	ld	s1,72(sp)
    800032fe:	6906                	ld	s2,64(sp)
    80003300:	79e2                	ld	s3,56(sp)
    80003302:	7a42                	ld	s4,48(sp)
    80003304:	7aa2                	ld	s5,40(sp)
    80003306:	7b02                	ld	s6,32(sp)
    80003308:	6be2                	ld	s7,24(sp)
    8000330a:	6c42                	ld	s8,16(sp)
    8000330c:	6ca2                	ld	s9,8(sp)
    8000330e:	6125                	addi	sp,sp,96
    80003310:	8082                	ret

0000000080003312 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003312:	7179                	addi	sp,sp,-48
    80003314:	f406                	sd	ra,40(sp)
    80003316:	f022                	sd	s0,32(sp)
    80003318:	ec26                	sd	s1,24(sp)
    8000331a:	e84a                	sd	s2,16(sp)
    8000331c:	e44e                	sd	s3,8(sp)
    8000331e:	e052                	sd	s4,0(sp)
    80003320:	1800                	addi	s0,sp,48
    80003322:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003324:	47ad                	li	a5,11
    80003326:	04b7fe63          	bgeu	a5,a1,80003382 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000332a:	ff45849b          	addiw	s1,a1,-12
    8000332e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003332:	0ff00793          	li	a5,255
    80003336:	0ae7e463          	bltu	a5,a4,800033de <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000333a:	08052583          	lw	a1,128(a0)
    8000333e:	c5b5                	beqz	a1,800033aa <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003340:	00092503          	lw	a0,0(s2)
    80003344:	00000097          	auipc	ra,0x0
    80003348:	bda080e7          	jalr	-1062(ra) # 80002f1e <bread>
    8000334c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000334e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003352:	02049713          	slli	a4,s1,0x20
    80003356:	01e75593          	srli	a1,a4,0x1e
    8000335a:	00b784b3          	add	s1,a5,a1
    8000335e:	0004a983          	lw	s3,0(s1)
    80003362:	04098e63          	beqz	s3,800033be <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003366:	8552                	mv	a0,s4
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	ce6080e7          	jalr	-794(ra) # 8000304e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003370:	854e                	mv	a0,s3
    80003372:	70a2                	ld	ra,40(sp)
    80003374:	7402                	ld	s0,32(sp)
    80003376:	64e2                	ld	s1,24(sp)
    80003378:	6942                	ld	s2,16(sp)
    8000337a:	69a2                	ld	s3,8(sp)
    8000337c:	6a02                	ld	s4,0(sp)
    8000337e:	6145                	addi	sp,sp,48
    80003380:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003382:	02059793          	slli	a5,a1,0x20
    80003386:	01e7d593          	srli	a1,a5,0x1e
    8000338a:	00b504b3          	add	s1,a0,a1
    8000338e:	0504a983          	lw	s3,80(s1)
    80003392:	fc099fe3          	bnez	s3,80003370 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003396:	4108                	lw	a0,0(a0)
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	e48080e7          	jalr	-440(ra) # 800031e0 <balloc>
    800033a0:	0005099b          	sext.w	s3,a0
    800033a4:	0534a823          	sw	s3,80(s1)
    800033a8:	b7e1                	j	80003370 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033aa:	4108                	lw	a0,0(a0)
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	e34080e7          	jalr	-460(ra) # 800031e0 <balloc>
    800033b4:	0005059b          	sext.w	a1,a0
    800033b8:	08b92023          	sw	a1,128(s2)
    800033bc:	b751                	j	80003340 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033be:	00092503          	lw	a0,0(s2)
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	e1e080e7          	jalr	-482(ra) # 800031e0 <balloc>
    800033ca:	0005099b          	sext.w	s3,a0
    800033ce:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033d2:	8552                	mv	a0,s4
    800033d4:	00001097          	auipc	ra,0x1
    800033d8:	efc080e7          	jalr	-260(ra) # 800042d0 <log_write>
    800033dc:	b769                	j	80003366 <bmap+0x54>
  panic("bmap: out of range");
    800033de:	00005517          	auipc	a0,0x5
    800033e2:	3aa50513          	addi	a0,a0,938 # 80008788 <syscalls_str+0x120>
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	144080e7          	jalr	324(ra) # 8000052a <panic>

00000000800033ee <iget>:
{
    800033ee:	7179                	addi	sp,sp,-48
    800033f0:	f406                	sd	ra,40(sp)
    800033f2:	f022                	sd	s0,32(sp)
    800033f4:	ec26                	sd	s1,24(sp)
    800033f6:	e84a                	sd	s2,16(sp)
    800033f8:	e44e                	sd	s3,8(sp)
    800033fa:	e052                	sd	s4,0(sp)
    800033fc:	1800                	addi	s0,sp,48
    800033fe:	89aa                	mv	s3,a0
    80003400:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003402:	0001c517          	auipc	a0,0x1c
    80003406:	3c650513          	addi	a0,a0,966 # 8001f7c8 <itable>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	7b8080e7          	jalr	1976(ra) # 80000bc2 <acquire>
  empty = 0;
    80003412:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003414:	0001c497          	auipc	s1,0x1c
    80003418:	3cc48493          	addi	s1,s1,972 # 8001f7e0 <itable+0x18>
    8000341c:	0001e697          	auipc	a3,0x1e
    80003420:	e5468693          	addi	a3,a3,-428 # 80021270 <log>
    80003424:	a039                	j	80003432 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003426:	02090b63          	beqz	s2,8000345c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000342a:	08848493          	addi	s1,s1,136
    8000342e:	02d48a63          	beq	s1,a3,80003462 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003432:	449c                	lw	a5,8(s1)
    80003434:	fef059e3          	blez	a5,80003426 <iget+0x38>
    80003438:	4098                	lw	a4,0(s1)
    8000343a:	ff3716e3          	bne	a4,s3,80003426 <iget+0x38>
    8000343e:	40d8                	lw	a4,4(s1)
    80003440:	ff4713e3          	bne	a4,s4,80003426 <iget+0x38>
      ip->ref++;
    80003444:	2785                	addiw	a5,a5,1
    80003446:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003448:	0001c517          	auipc	a0,0x1c
    8000344c:	38050513          	addi	a0,a0,896 # 8001f7c8 <itable>
    80003450:	ffffe097          	auipc	ra,0xffffe
    80003454:	826080e7          	jalr	-2010(ra) # 80000c76 <release>
      return ip;
    80003458:	8926                	mv	s2,s1
    8000345a:	a03d                	j	80003488 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000345c:	f7f9                	bnez	a5,8000342a <iget+0x3c>
    8000345e:	8926                	mv	s2,s1
    80003460:	b7e9                	j	8000342a <iget+0x3c>
  if(empty == 0)
    80003462:	02090c63          	beqz	s2,8000349a <iget+0xac>
  ip->dev = dev;
    80003466:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000346a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000346e:	4785                	li	a5,1
    80003470:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003474:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003478:	0001c517          	auipc	a0,0x1c
    8000347c:	35050513          	addi	a0,a0,848 # 8001f7c8 <itable>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	7f6080e7          	jalr	2038(ra) # 80000c76 <release>
}
    80003488:	854a                	mv	a0,s2
    8000348a:	70a2                	ld	ra,40(sp)
    8000348c:	7402                	ld	s0,32(sp)
    8000348e:	64e2                	ld	s1,24(sp)
    80003490:	6942                	ld	s2,16(sp)
    80003492:	69a2                	ld	s3,8(sp)
    80003494:	6a02                	ld	s4,0(sp)
    80003496:	6145                	addi	sp,sp,48
    80003498:	8082                	ret
    panic("iget: no inodes");
    8000349a:	00005517          	auipc	a0,0x5
    8000349e:	30650513          	addi	a0,a0,774 # 800087a0 <syscalls_str+0x138>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	088080e7          	jalr	136(ra) # 8000052a <panic>

00000000800034aa <fsinit>:
fsinit(int dev) {
    800034aa:	7179                	addi	sp,sp,-48
    800034ac:	f406                	sd	ra,40(sp)
    800034ae:	f022                	sd	s0,32(sp)
    800034b0:	ec26                	sd	s1,24(sp)
    800034b2:	e84a                	sd	s2,16(sp)
    800034b4:	e44e                	sd	s3,8(sp)
    800034b6:	1800                	addi	s0,sp,48
    800034b8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034ba:	4585                	li	a1,1
    800034bc:	00000097          	auipc	ra,0x0
    800034c0:	a62080e7          	jalr	-1438(ra) # 80002f1e <bread>
    800034c4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034c6:	0001c997          	auipc	s3,0x1c
    800034ca:	2e298993          	addi	s3,s3,738 # 8001f7a8 <sb>
    800034ce:	02000613          	li	a2,32
    800034d2:	05850593          	addi	a1,a0,88
    800034d6:	854e                	mv	a0,s3
    800034d8:	ffffe097          	auipc	ra,0xffffe
    800034dc:	842080e7          	jalr	-1982(ra) # 80000d1a <memmove>
  brelse(bp);
    800034e0:	8526                	mv	a0,s1
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	b6c080e7          	jalr	-1172(ra) # 8000304e <brelse>
  if(sb.magic != FSMAGIC)
    800034ea:	0009a703          	lw	a4,0(s3)
    800034ee:	102037b7          	lui	a5,0x10203
    800034f2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034f6:	02f71263          	bne	a4,a5,8000351a <fsinit+0x70>
  initlog(dev, &sb);
    800034fa:	0001c597          	auipc	a1,0x1c
    800034fe:	2ae58593          	addi	a1,a1,686 # 8001f7a8 <sb>
    80003502:	854a                	mv	a0,s2
    80003504:	00001097          	auipc	ra,0x1
    80003508:	b4e080e7          	jalr	-1202(ra) # 80004052 <initlog>
}
    8000350c:	70a2                	ld	ra,40(sp)
    8000350e:	7402                	ld	s0,32(sp)
    80003510:	64e2                	ld	s1,24(sp)
    80003512:	6942                	ld	s2,16(sp)
    80003514:	69a2                	ld	s3,8(sp)
    80003516:	6145                	addi	sp,sp,48
    80003518:	8082                	ret
    panic("invalid file system");
    8000351a:	00005517          	auipc	a0,0x5
    8000351e:	29650513          	addi	a0,a0,662 # 800087b0 <syscalls_str+0x148>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	008080e7          	jalr	8(ra) # 8000052a <panic>

000000008000352a <iinit>:
{
    8000352a:	7179                	addi	sp,sp,-48
    8000352c:	f406                	sd	ra,40(sp)
    8000352e:	f022                	sd	s0,32(sp)
    80003530:	ec26                	sd	s1,24(sp)
    80003532:	e84a                	sd	s2,16(sp)
    80003534:	e44e                	sd	s3,8(sp)
    80003536:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003538:	00005597          	auipc	a1,0x5
    8000353c:	29058593          	addi	a1,a1,656 # 800087c8 <syscalls_str+0x160>
    80003540:	0001c517          	auipc	a0,0x1c
    80003544:	28850513          	addi	a0,a0,648 # 8001f7c8 <itable>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	5ea080e7          	jalr	1514(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003550:	0001c497          	auipc	s1,0x1c
    80003554:	2a048493          	addi	s1,s1,672 # 8001f7f0 <itable+0x28>
    80003558:	0001e997          	auipc	s3,0x1e
    8000355c:	d2898993          	addi	s3,s3,-728 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003560:	00005917          	auipc	s2,0x5
    80003564:	27090913          	addi	s2,s2,624 # 800087d0 <syscalls_str+0x168>
    80003568:	85ca                	mv	a1,s2
    8000356a:	8526                	mv	a0,s1
    8000356c:	00001097          	auipc	ra,0x1
    80003570:	e4a080e7          	jalr	-438(ra) # 800043b6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003574:	08848493          	addi	s1,s1,136
    80003578:	ff3498e3          	bne	s1,s3,80003568 <iinit+0x3e>
}
    8000357c:	70a2                	ld	ra,40(sp)
    8000357e:	7402                	ld	s0,32(sp)
    80003580:	64e2                	ld	s1,24(sp)
    80003582:	6942                	ld	s2,16(sp)
    80003584:	69a2                	ld	s3,8(sp)
    80003586:	6145                	addi	sp,sp,48
    80003588:	8082                	ret

000000008000358a <ialloc>:
{
    8000358a:	715d                	addi	sp,sp,-80
    8000358c:	e486                	sd	ra,72(sp)
    8000358e:	e0a2                	sd	s0,64(sp)
    80003590:	fc26                	sd	s1,56(sp)
    80003592:	f84a                	sd	s2,48(sp)
    80003594:	f44e                	sd	s3,40(sp)
    80003596:	f052                	sd	s4,32(sp)
    80003598:	ec56                	sd	s5,24(sp)
    8000359a:	e85a                	sd	s6,16(sp)
    8000359c:	e45e                	sd	s7,8(sp)
    8000359e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a0:	0001c717          	auipc	a4,0x1c
    800035a4:	21472703          	lw	a4,532(a4) # 8001f7b4 <sb+0xc>
    800035a8:	4785                	li	a5,1
    800035aa:	04e7fa63          	bgeu	a5,a4,800035fe <ialloc+0x74>
    800035ae:	8aaa                	mv	s5,a0
    800035b0:	8bae                	mv	s7,a1
    800035b2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035b4:	0001ca17          	auipc	s4,0x1c
    800035b8:	1f4a0a13          	addi	s4,s4,500 # 8001f7a8 <sb>
    800035bc:	00048b1b          	sext.w	s6,s1
    800035c0:	0044d793          	srli	a5,s1,0x4
    800035c4:	018a2583          	lw	a1,24(s4)
    800035c8:	9dbd                	addw	a1,a1,a5
    800035ca:	8556                	mv	a0,s5
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	952080e7          	jalr	-1710(ra) # 80002f1e <bread>
    800035d4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035d6:	05850993          	addi	s3,a0,88
    800035da:	00f4f793          	andi	a5,s1,15
    800035de:	079a                	slli	a5,a5,0x6
    800035e0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035e2:	00099783          	lh	a5,0(s3)
    800035e6:	c785                	beqz	a5,8000360e <ialloc+0x84>
    brelse(bp);
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	a66080e7          	jalr	-1434(ra) # 8000304e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f0:	0485                	addi	s1,s1,1
    800035f2:	00ca2703          	lw	a4,12(s4)
    800035f6:	0004879b          	sext.w	a5,s1
    800035fa:	fce7e1e3          	bltu	a5,a4,800035bc <ialloc+0x32>
  panic("ialloc: no inodes");
    800035fe:	00005517          	auipc	a0,0x5
    80003602:	1da50513          	addi	a0,a0,474 # 800087d8 <syscalls_str+0x170>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f24080e7          	jalr	-220(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    8000360e:	04000613          	li	a2,64
    80003612:	4581                	li	a1,0
    80003614:	854e                	mv	a0,s3
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	6a8080e7          	jalr	1704(ra) # 80000cbe <memset>
      dip->type = type;
    8000361e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003622:	854a                	mv	a0,s2
    80003624:	00001097          	auipc	ra,0x1
    80003628:	cac080e7          	jalr	-852(ra) # 800042d0 <log_write>
      brelse(bp);
    8000362c:	854a                	mv	a0,s2
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	a20080e7          	jalr	-1504(ra) # 8000304e <brelse>
      return iget(dev, inum);
    80003636:	85da                	mv	a1,s6
    80003638:	8556                	mv	a0,s5
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	db4080e7          	jalr	-588(ra) # 800033ee <iget>
}
    80003642:	60a6                	ld	ra,72(sp)
    80003644:	6406                	ld	s0,64(sp)
    80003646:	74e2                	ld	s1,56(sp)
    80003648:	7942                	ld	s2,48(sp)
    8000364a:	79a2                	ld	s3,40(sp)
    8000364c:	7a02                	ld	s4,32(sp)
    8000364e:	6ae2                	ld	s5,24(sp)
    80003650:	6b42                	ld	s6,16(sp)
    80003652:	6ba2                	ld	s7,8(sp)
    80003654:	6161                	addi	sp,sp,80
    80003656:	8082                	ret

0000000080003658 <iupdate>:
{
    80003658:	1101                	addi	sp,sp,-32
    8000365a:	ec06                	sd	ra,24(sp)
    8000365c:	e822                	sd	s0,16(sp)
    8000365e:	e426                	sd	s1,8(sp)
    80003660:	e04a                	sd	s2,0(sp)
    80003662:	1000                	addi	s0,sp,32
    80003664:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003666:	415c                	lw	a5,4(a0)
    80003668:	0047d79b          	srliw	a5,a5,0x4
    8000366c:	0001c597          	auipc	a1,0x1c
    80003670:	1545a583          	lw	a1,340(a1) # 8001f7c0 <sb+0x18>
    80003674:	9dbd                	addw	a1,a1,a5
    80003676:	4108                	lw	a0,0(a0)
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	8a6080e7          	jalr	-1882(ra) # 80002f1e <bread>
    80003680:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003682:	05850793          	addi	a5,a0,88
    80003686:	40c8                	lw	a0,4(s1)
    80003688:	893d                	andi	a0,a0,15
    8000368a:	051a                	slli	a0,a0,0x6
    8000368c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000368e:	04449703          	lh	a4,68(s1)
    80003692:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003696:	04649703          	lh	a4,70(s1)
    8000369a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000369e:	04849703          	lh	a4,72(s1)
    800036a2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036a6:	04a49703          	lh	a4,74(s1)
    800036aa:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036ae:	44f8                	lw	a4,76(s1)
    800036b0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036b2:	03400613          	li	a2,52
    800036b6:	05048593          	addi	a1,s1,80
    800036ba:	0531                	addi	a0,a0,12
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	65e080e7          	jalr	1630(ra) # 80000d1a <memmove>
  log_write(bp);
    800036c4:	854a                	mv	a0,s2
    800036c6:	00001097          	auipc	ra,0x1
    800036ca:	c0a080e7          	jalr	-1014(ra) # 800042d0 <log_write>
  brelse(bp);
    800036ce:	854a                	mv	a0,s2
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	97e080e7          	jalr	-1666(ra) # 8000304e <brelse>
}
    800036d8:	60e2                	ld	ra,24(sp)
    800036da:	6442                	ld	s0,16(sp)
    800036dc:	64a2                	ld	s1,8(sp)
    800036de:	6902                	ld	s2,0(sp)
    800036e0:	6105                	addi	sp,sp,32
    800036e2:	8082                	ret

00000000800036e4 <idup>:
{
    800036e4:	1101                	addi	sp,sp,-32
    800036e6:	ec06                	sd	ra,24(sp)
    800036e8:	e822                	sd	s0,16(sp)
    800036ea:	e426                	sd	s1,8(sp)
    800036ec:	1000                	addi	s0,sp,32
    800036ee:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036f0:	0001c517          	auipc	a0,0x1c
    800036f4:	0d850513          	addi	a0,a0,216 # 8001f7c8 <itable>
    800036f8:	ffffd097          	auipc	ra,0xffffd
    800036fc:	4ca080e7          	jalr	1226(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003700:	449c                	lw	a5,8(s1)
    80003702:	2785                	addiw	a5,a5,1
    80003704:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003706:	0001c517          	auipc	a0,0x1c
    8000370a:	0c250513          	addi	a0,a0,194 # 8001f7c8 <itable>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	568080e7          	jalr	1384(ra) # 80000c76 <release>
}
    80003716:	8526                	mv	a0,s1
    80003718:	60e2                	ld	ra,24(sp)
    8000371a:	6442                	ld	s0,16(sp)
    8000371c:	64a2                	ld	s1,8(sp)
    8000371e:	6105                	addi	sp,sp,32
    80003720:	8082                	ret

0000000080003722 <ilock>:
{
    80003722:	1101                	addi	sp,sp,-32
    80003724:	ec06                	sd	ra,24(sp)
    80003726:	e822                	sd	s0,16(sp)
    80003728:	e426                	sd	s1,8(sp)
    8000372a:	e04a                	sd	s2,0(sp)
    8000372c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000372e:	c115                	beqz	a0,80003752 <ilock+0x30>
    80003730:	84aa                	mv	s1,a0
    80003732:	451c                	lw	a5,8(a0)
    80003734:	00f05f63          	blez	a5,80003752 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003738:	0541                	addi	a0,a0,16
    8000373a:	00001097          	auipc	ra,0x1
    8000373e:	cb6080e7          	jalr	-842(ra) # 800043f0 <acquiresleep>
  if(ip->valid == 0){
    80003742:	40bc                	lw	a5,64(s1)
    80003744:	cf99                	beqz	a5,80003762 <ilock+0x40>
}
    80003746:	60e2                	ld	ra,24(sp)
    80003748:	6442                	ld	s0,16(sp)
    8000374a:	64a2                	ld	s1,8(sp)
    8000374c:	6902                	ld	s2,0(sp)
    8000374e:	6105                	addi	sp,sp,32
    80003750:	8082                	ret
    panic("ilock");
    80003752:	00005517          	auipc	a0,0x5
    80003756:	09e50513          	addi	a0,a0,158 # 800087f0 <syscalls_str+0x188>
    8000375a:	ffffd097          	auipc	ra,0xffffd
    8000375e:	dd0080e7          	jalr	-560(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003762:	40dc                	lw	a5,4(s1)
    80003764:	0047d79b          	srliw	a5,a5,0x4
    80003768:	0001c597          	auipc	a1,0x1c
    8000376c:	0585a583          	lw	a1,88(a1) # 8001f7c0 <sb+0x18>
    80003770:	9dbd                	addw	a1,a1,a5
    80003772:	4088                	lw	a0,0(s1)
    80003774:	fffff097          	auipc	ra,0xfffff
    80003778:	7aa080e7          	jalr	1962(ra) # 80002f1e <bread>
    8000377c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000377e:	05850593          	addi	a1,a0,88
    80003782:	40dc                	lw	a5,4(s1)
    80003784:	8bbd                	andi	a5,a5,15
    80003786:	079a                	slli	a5,a5,0x6
    80003788:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000378a:	00059783          	lh	a5,0(a1)
    8000378e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003792:	00259783          	lh	a5,2(a1)
    80003796:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000379a:	00459783          	lh	a5,4(a1)
    8000379e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037a2:	00659783          	lh	a5,6(a1)
    800037a6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037aa:	459c                	lw	a5,8(a1)
    800037ac:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037ae:	03400613          	li	a2,52
    800037b2:	05b1                	addi	a1,a1,12
    800037b4:	05048513          	addi	a0,s1,80
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	562080e7          	jalr	1378(ra) # 80000d1a <memmove>
    brelse(bp);
    800037c0:	854a                	mv	a0,s2
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	88c080e7          	jalr	-1908(ra) # 8000304e <brelse>
    ip->valid = 1;
    800037ca:	4785                	li	a5,1
    800037cc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037ce:	04449783          	lh	a5,68(s1)
    800037d2:	fbb5                	bnez	a5,80003746 <ilock+0x24>
      panic("ilock: no type");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	02450513          	addi	a0,a0,36 # 800087f8 <syscalls_str+0x190>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	d4e080e7          	jalr	-690(ra) # 8000052a <panic>

00000000800037e4 <iunlock>:
{
    800037e4:	1101                	addi	sp,sp,-32
    800037e6:	ec06                	sd	ra,24(sp)
    800037e8:	e822                	sd	s0,16(sp)
    800037ea:	e426                	sd	s1,8(sp)
    800037ec:	e04a                	sd	s2,0(sp)
    800037ee:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037f0:	c905                	beqz	a0,80003820 <iunlock+0x3c>
    800037f2:	84aa                	mv	s1,a0
    800037f4:	01050913          	addi	s2,a0,16
    800037f8:	854a                	mv	a0,s2
    800037fa:	00001097          	auipc	ra,0x1
    800037fe:	c90080e7          	jalr	-880(ra) # 8000448a <holdingsleep>
    80003802:	cd19                	beqz	a0,80003820 <iunlock+0x3c>
    80003804:	449c                	lw	a5,8(s1)
    80003806:	00f05d63          	blez	a5,80003820 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	c3a080e7          	jalr	-966(ra) # 80004446 <releasesleep>
}
    80003814:	60e2                	ld	ra,24(sp)
    80003816:	6442                	ld	s0,16(sp)
    80003818:	64a2                	ld	s1,8(sp)
    8000381a:	6902                	ld	s2,0(sp)
    8000381c:	6105                	addi	sp,sp,32
    8000381e:	8082                	ret
    panic("iunlock");
    80003820:	00005517          	auipc	a0,0x5
    80003824:	fe850513          	addi	a0,a0,-24 # 80008808 <syscalls_str+0x1a0>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	d02080e7          	jalr	-766(ra) # 8000052a <panic>

0000000080003830 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003830:	7179                	addi	sp,sp,-48
    80003832:	f406                	sd	ra,40(sp)
    80003834:	f022                	sd	s0,32(sp)
    80003836:	ec26                	sd	s1,24(sp)
    80003838:	e84a                	sd	s2,16(sp)
    8000383a:	e44e                	sd	s3,8(sp)
    8000383c:	e052                	sd	s4,0(sp)
    8000383e:	1800                	addi	s0,sp,48
    80003840:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003842:	05050493          	addi	s1,a0,80
    80003846:	08050913          	addi	s2,a0,128
    8000384a:	a021                	j	80003852 <itrunc+0x22>
    8000384c:	0491                	addi	s1,s1,4
    8000384e:	01248d63          	beq	s1,s2,80003868 <itrunc+0x38>
    if(ip->addrs[i]){
    80003852:	408c                	lw	a1,0(s1)
    80003854:	dde5                	beqz	a1,8000384c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003856:	0009a503          	lw	a0,0(s3)
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	90a080e7          	jalr	-1782(ra) # 80003164 <bfree>
      ip->addrs[i] = 0;
    80003862:	0004a023          	sw	zero,0(s1)
    80003866:	b7dd                	j	8000384c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003868:	0809a583          	lw	a1,128(s3)
    8000386c:	e185                	bnez	a1,8000388c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000386e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003872:	854e                	mv	a0,s3
    80003874:	00000097          	auipc	ra,0x0
    80003878:	de4080e7          	jalr	-540(ra) # 80003658 <iupdate>
}
    8000387c:	70a2                	ld	ra,40(sp)
    8000387e:	7402                	ld	s0,32(sp)
    80003880:	64e2                	ld	s1,24(sp)
    80003882:	6942                	ld	s2,16(sp)
    80003884:	69a2                	ld	s3,8(sp)
    80003886:	6a02                	ld	s4,0(sp)
    80003888:	6145                	addi	sp,sp,48
    8000388a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000388c:	0009a503          	lw	a0,0(s3)
    80003890:	fffff097          	auipc	ra,0xfffff
    80003894:	68e080e7          	jalr	1678(ra) # 80002f1e <bread>
    80003898:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000389a:	05850493          	addi	s1,a0,88
    8000389e:	45850913          	addi	s2,a0,1112
    800038a2:	a021                	j	800038aa <itrunc+0x7a>
    800038a4:	0491                	addi	s1,s1,4
    800038a6:	01248b63          	beq	s1,s2,800038bc <itrunc+0x8c>
      if(a[j])
    800038aa:	408c                	lw	a1,0(s1)
    800038ac:	dde5                	beqz	a1,800038a4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038ae:	0009a503          	lw	a0,0(s3)
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	8b2080e7          	jalr	-1870(ra) # 80003164 <bfree>
    800038ba:	b7ed                	j	800038a4 <itrunc+0x74>
    brelse(bp);
    800038bc:	8552                	mv	a0,s4
    800038be:	fffff097          	auipc	ra,0xfffff
    800038c2:	790080e7          	jalr	1936(ra) # 8000304e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038c6:	0809a583          	lw	a1,128(s3)
    800038ca:	0009a503          	lw	a0,0(s3)
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	896080e7          	jalr	-1898(ra) # 80003164 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038d6:	0809a023          	sw	zero,128(s3)
    800038da:	bf51                	j	8000386e <itrunc+0x3e>

00000000800038dc <iput>:
{
    800038dc:	1101                	addi	sp,sp,-32
    800038de:	ec06                	sd	ra,24(sp)
    800038e0:	e822                	sd	s0,16(sp)
    800038e2:	e426                	sd	s1,8(sp)
    800038e4:	e04a                	sd	s2,0(sp)
    800038e6:	1000                	addi	s0,sp,32
    800038e8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ea:	0001c517          	auipc	a0,0x1c
    800038ee:	ede50513          	addi	a0,a0,-290 # 8001f7c8 <itable>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	2d0080e7          	jalr	720(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038fa:	4498                	lw	a4,8(s1)
    800038fc:	4785                	li	a5,1
    800038fe:	02f70363          	beq	a4,a5,80003924 <iput+0x48>
  ip->ref--;
    80003902:	449c                	lw	a5,8(s1)
    80003904:	37fd                	addiw	a5,a5,-1
    80003906:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003908:	0001c517          	auipc	a0,0x1c
    8000390c:	ec050513          	addi	a0,a0,-320 # 8001f7c8 <itable>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	366080e7          	jalr	870(ra) # 80000c76 <release>
}
    80003918:	60e2                	ld	ra,24(sp)
    8000391a:	6442                	ld	s0,16(sp)
    8000391c:	64a2                	ld	s1,8(sp)
    8000391e:	6902                	ld	s2,0(sp)
    80003920:	6105                	addi	sp,sp,32
    80003922:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003924:	40bc                	lw	a5,64(s1)
    80003926:	dff1                	beqz	a5,80003902 <iput+0x26>
    80003928:	04a49783          	lh	a5,74(s1)
    8000392c:	fbf9                	bnez	a5,80003902 <iput+0x26>
    acquiresleep(&ip->lock);
    8000392e:	01048913          	addi	s2,s1,16
    80003932:	854a                	mv	a0,s2
    80003934:	00001097          	auipc	ra,0x1
    80003938:	abc080e7          	jalr	-1348(ra) # 800043f0 <acquiresleep>
    release(&itable.lock);
    8000393c:	0001c517          	auipc	a0,0x1c
    80003940:	e8c50513          	addi	a0,a0,-372 # 8001f7c8 <itable>
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	332080e7          	jalr	818(ra) # 80000c76 <release>
    itrunc(ip);
    8000394c:	8526                	mv	a0,s1
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	ee2080e7          	jalr	-286(ra) # 80003830 <itrunc>
    ip->type = 0;
    80003956:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000395a:	8526                	mv	a0,s1
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	cfc080e7          	jalr	-772(ra) # 80003658 <iupdate>
    ip->valid = 0;
    80003964:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003968:	854a                	mv	a0,s2
    8000396a:	00001097          	auipc	ra,0x1
    8000396e:	adc080e7          	jalr	-1316(ra) # 80004446 <releasesleep>
    acquire(&itable.lock);
    80003972:	0001c517          	auipc	a0,0x1c
    80003976:	e5650513          	addi	a0,a0,-426 # 8001f7c8 <itable>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	248080e7          	jalr	584(ra) # 80000bc2 <acquire>
    80003982:	b741                	j	80003902 <iput+0x26>

0000000080003984 <iunlockput>:
{
    80003984:	1101                	addi	sp,sp,-32
    80003986:	ec06                	sd	ra,24(sp)
    80003988:	e822                	sd	s0,16(sp)
    8000398a:	e426                	sd	s1,8(sp)
    8000398c:	1000                	addi	s0,sp,32
    8000398e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003990:	00000097          	auipc	ra,0x0
    80003994:	e54080e7          	jalr	-428(ra) # 800037e4 <iunlock>
  iput(ip);
    80003998:	8526                	mv	a0,s1
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	f42080e7          	jalr	-190(ra) # 800038dc <iput>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6105                	addi	sp,sp,32
    800039aa:	8082                	ret

00000000800039ac <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039ac:	1141                	addi	sp,sp,-16
    800039ae:	e422                	sd	s0,8(sp)
    800039b0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039b2:	411c                	lw	a5,0(a0)
    800039b4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039b6:	415c                	lw	a5,4(a0)
    800039b8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039ba:	04451783          	lh	a5,68(a0)
    800039be:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039c2:	04a51783          	lh	a5,74(a0)
    800039c6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039ca:	04c56783          	lwu	a5,76(a0)
    800039ce:	e99c                	sd	a5,16(a1)
}
    800039d0:	6422                	ld	s0,8(sp)
    800039d2:	0141                	addi	sp,sp,16
    800039d4:	8082                	ret

00000000800039d6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039d6:	457c                	lw	a5,76(a0)
    800039d8:	0ed7e963          	bltu	a5,a3,80003aca <readi+0xf4>
{
    800039dc:	7159                	addi	sp,sp,-112
    800039de:	f486                	sd	ra,104(sp)
    800039e0:	f0a2                	sd	s0,96(sp)
    800039e2:	eca6                	sd	s1,88(sp)
    800039e4:	e8ca                	sd	s2,80(sp)
    800039e6:	e4ce                	sd	s3,72(sp)
    800039e8:	e0d2                	sd	s4,64(sp)
    800039ea:	fc56                	sd	s5,56(sp)
    800039ec:	f85a                	sd	s6,48(sp)
    800039ee:	f45e                	sd	s7,40(sp)
    800039f0:	f062                	sd	s8,32(sp)
    800039f2:	ec66                	sd	s9,24(sp)
    800039f4:	e86a                	sd	s10,16(sp)
    800039f6:	e46e                	sd	s11,8(sp)
    800039f8:	1880                	addi	s0,sp,112
    800039fa:	8baa                	mv	s7,a0
    800039fc:	8c2e                	mv	s8,a1
    800039fe:	8ab2                	mv	s5,a2
    80003a00:	84b6                	mv	s1,a3
    80003a02:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a04:	9f35                	addw	a4,a4,a3
    return 0;
    80003a06:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a08:	0ad76063          	bltu	a4,a3,80003aa8 <readi+0xd2>
  if(off + n > ip->size)
    80003a0c:	00e7f463          	bgeu	a5,a4,80003a14 <readi+0x3e>
    n = ip->size - off;
    80003a10:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a14:	0a0b0963          	beqz	s6,80003ac6 <readi+0xf0>
    80003a18:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a1a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a1e:	5cfd                	li	s9,-1
    80003a20:	a82d                	j	80003a5a <readi+0x84>
    80003a22:	020a1d93          	slli	s11,s4,0x20
    80003a26:	020ddd93          	srli	s11,s11,0x20
    80003a2a:	05890793          	addi	a5,s2,88
    80003a2e:	86ee                	mv	a3,s11
    80003a30:	963e                	add	a2,a2,a5
    80003a32:	85d6                	mv	a1,s5
    80003a34:	8562                	mv	a0,s8
    80003a36:	fffff097          	auipc	ra,0xfffff
    80003a3a:	a36080e7          	jalr	-1482(ra) # 8000246c <either_copyout>
    80003a3e:	05950d63          	beq	a0,s9,80003a98 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a42:	854a                	mv	a0,s2
    80003a44:	fffff097          	auipc	ra,0xfffff
    80003a48:	60a080e7          	jalr	1546(ra) # 8000304e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4c:	013a09bb          	addw	s3,s4,s3
    80003a50:	009a04bb          	addw	s1,s4,s1
    80003a54:	9aee                	add	s5,s5,s11
    80003a56:	0569f763          	bgeu	s3,s6,80003aa4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a5a:	000ba903          	lw	s2,0(s7)
    80003a5e:	00a4d59b          	srliw	a1,s1,0xa
    80003a62:	855e                	mv	a0,s7
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	8ae080e7          	jalr	-1874(ra) # 80003312 <bmap>
    80003a6c:	0005059b          	sext.w	a1,a0
    80003a70:	854a                	mv	a0,s2
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	4ac080e7          	jalr	1196(ra) # 80002f1e <bread>
    80003a7a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7c:	3ff4f613          	andi	a2,s1,1023
    80003a80:	40cd07bb          	subw	a5,s10,a2
    80003a84:	413b073b          	subw	a4,s6,s3
    80003a88:	8a3e                	mv	s4,a5
    80003a8a:	2781                	sext.w	a5,a5
    80003a8c:	0007069b          	sext.w	a3,a4
    80003a90:	f8f6f9e3          	bgeu	a3,a5,80003a22 <readi+0x4c>
    80003a94:	8a3a                	mv	s4,a4
    80003a96:	b771                	j	80003a22 <readi+0x4c>
      brelse(bp);
    80003a98:	854a                	mv	a0,s2
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	5b4080e7          	jalr	1460(ra) # 8000304e <brelse>
      tot = -1;
    80003aa2:	59fd                	li	s3,-1
  }
  return tot;
    80003aa4:	0009851b          	sext.w	a0,s3
}
    80003aa8:	70a6                	ld	ra,104(sp)
    80003aaa:	7406                	ld	s0,96(sp)
    80003aac:	64e6                	ld	s1,88(sp)
    80003aae:	6946                	ld	s2,80(sp)
    80003ab0:	69a6                	ld	s3,72(sp)
    80003ab2:	6a06                	ld	s4,64(sp)
    80003ab4:	7ae2                	ld	s5,56(sp)
    80003ab6:	7b42                	ld	s6,48(sp)
    80003ab8:	7ba2                	ld	s7,40(sp)
    80003aba:	7c02                	ld	s8,32(sp)
    80003abc:	6ce2                	ld	s9,24(sp)
    80003abe:	6d42                	ld	s10,16(sp)
    80003ac0:	6da2                	ld	s11,8(sp)
    80003ac2:	6165                	addi	sp,sp,112
    80003ac4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac6:	89da                	mv	s3,s6
    80003ac8:	bff1                	j	80003aa4 <readi+0xce>
    return 0;
    80003aca:	4501                	li	a0,0
}
    80003acc:	8082                	ret

0000000080003ace <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ace:	457c                	lw	a5,76(a0)
    80003ad0:	10d7e863          	bltu	a5,a3,80003be0 <writei+0x112>
{
    80003ad4:	7159                	addi	sp,sp,-112
    80003ad6:	f486                	sd	ra,104(sp)
    80003ad8:	f0a2                	sd	s0,96(sp)
    80003ada:	eca6                	sd	s1,88(sp)
    80003adc:	e8ca                	sd	s2,80(sp)
    80003ade:	e4ce                	sd	s3,72(sp)
    80003ae0:	e0d2                	sd	s4,64(sp)
    80003ae2:	fc56                	sd	s5,56(sp)
    80003ae4:	f85a                	sd	s6,48(sp)
    80003ae6:	f45e                	sd	s7,40(sp)
    80003ae8:	f062                	sd	s8,32(sp)
    80003aea:	ec66                	sd	s9,24(sp)
    80003aec:	e86a                	sd	s10,16(sp)
    80003aee:	e46e                	sd	s11,8(sp)
    80003af0:	1880                	addi	s0,sp,112
    80003af2:	8b2a                	mv	s6,a0
    80003af4:	8c2e                	mv	s8,a1
    80003af6:	8ab2                	mv	s5,a2
    80003af8:	8936                	mv	s2,a3
    80003afa:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003afc:	00e687bb          	addw	a5,a3,a4
    80003b00:	0ed7e263          	bltu	a5,a3,80003be4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b04:	00043737          	lui	a4,0x43
    80003b08:	0ef76063          	bltu	a4,a5,80003be8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b0c:	0c0b8863          	beqz	s7,80003bdc <writei+0x10e>
    80003b10:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b12:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b16:	5cfd                	li	s9,-1
    80003b18:	a091                	j	80003b5c <writei+0x8e>
    80003b1a:	02099d93          	slli	s11,s3,0x20
    80003b1e:	020ddd93          	srli	s11,s11,0x20
    80003b22:	05848793          	addi	a5,s1,88
    80003b26:	86ee                	mv	a3,s11
    80003b28:	8656                	mv	a2,s5
    80003b2a:	85e2                	mv	a1,s8
    80003b2c:	953e                	add	a0,a0,a5
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	994080e7          	jalr	-1644(ra) # 800024c2 <either_copyin>
    80003b36:	07950263          	beq	a0,s9,80003b9a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b3a:	8526                	mv	a0,s1
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	794080e7          	jalr	1940(ra) # 800042d0 <log_write>
    brelse(bp);
    80003b44:	8526                	mv	a0,s1
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	508080e7          	jalr	1288(ra) # 8000304e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b4e:	01498a3b          	addw	s4,s3,s4
    80003b52:	0129893b          	addw	s2,s3,s2
    80003b56:	9aee                	add	s5,s5,s11
    80003b58:	057a7663          	bgeu	s4,s7,80003ba4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b5c:	000b2483          	lw	s1,0(s6)
    80003b60:	00a9559b          	srliw	a1,s2,0xa
    80003b64:	855a                	mv	a0,s6
    80003b66:	fffff097          	auipc	ra,0xfffff
    80003b6a:	7ac080e7          	jalr	1964(ra) # 80003312 <bmap>
    80003b6e:	0005059b          	sext.w	a1,a0
    80003b72:	8526                	mv	a0,s1
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	3aa080e7          	jalr	938(ra) # 80002f1e <bread>
    80003b7c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7e:	3ff97513          	andi	a0,s2,1023
    80003b82:	40ad07bb          	subw	a5,s10,a0
    80003b86:	414b873b          	subw	a4,s7,s4
    80003b8a:	89be                	mv	s3,a5
    80003b8c:	2781                	sext.w	a5,a5
    80003b8e:	0007069b          	sext.w	a3,a4
    80003b92:	f8f6f4e3          	bgeu	a3,a5,80003b1a <writei+0x4c>
    80003b96:	89ba                	mv	s3,a4
    80003b98:	b749                	j	80003b1a <writei+0x4c>
      brelse(bp);
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	fffff097          	auipc	ra,0xfffff
    80003ba0:	4b2080e7          	jalr	1202(ra) # 8000304e <brelse>
  }

  if(off > ip->size)
    80003ba4:	04cb2783          	lw	a5,76(s6)
    80003ba8:	0127f463          	bgeu	a5,s2,80003bb0 <writei+0xe2>
    ip->size = off;
    80003bac:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bb0:	855a                	mv	a0,s6
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	aa6080e7          	jalr	-1370(ra) # 80003658 <iupdate>

  return tot;
    80003bba:	000a051b          	sext.w	a0,s4
}
    80003bbe:	70a6                	ld	ra,104(sp)
    80003bc0:	7406                	ld	s0,96(sp)
    80003bc2:	64e6                	ld	s1,88(sp)
    80003bc4:	6946                	ld	s2,80(sp)
    80003bc6:	69a6                	ld	s3,72(sp)
    80003bc8:	6a06                	ld	s4,64(sp)
    80003bca:	7ae2                	ld	s5,56(sp)
    80003bcc:	7b42                	ld	s6,48(sp)
    80003bce:	7ba2                	ld	s7,40(sp)
    80003bd0:	7c02                	ld	s8,32(sp)
    80003bd2:	6ce2                	ld	s9,24(sp)
    80003bd4:	6d42                	ld	s10,16(sp)
    80003bd6:	6da2                	ld	s11,8(sp)
    80003bd8:	6165                	addi	sp,sp,112
    80003bda:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bdc:	8a5e                	mv	s4,s7
    80003bde:	bfc9                	j	80003bb0 <writei+0xe2>
    return -1;
    80003be0:	557d                	li	a0,-1
}
    80003be2:	8082                	ret
    return -1;
    80003be4:	557d                	li	a0,-1
    80003be6:	bfe1                	j	80003bbe <writei+0xf0>
    return -1;
    80003be8:	557d                	li	a0,-1
    80003bea:	bfd1                	j	80003bbe <writei+0xf0>

0000000080003bec <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bec:	1141                	addi	sp,sp,-16
    80003bee:	e406                	sd	ra,8(sp)
    80003bf0:	e022                	sd	s0,0(sp)
    80003bf2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bf4:	4639                	li	a2,14
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	1a0080e7          	jalr	416(ra) # 80000d96 <strncmp>
}
    80003bfe:	60a2                	ld	ra,8(sp)
    80003c00:	6402                	ld	s0,0(sp)
    80003c02:	0141                	addi	sp,sp,16
    80003c04:	8082                	ret

0000000080003c06 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c06:	7139                	addi	sp,sp,-64
    80003c08:	fc06                	sd	ra,56(sp)
    80003c0a:	f822                	sd	s0,48(sp)
    80003c0c:	f426                	sd	s1,40(sp)
    80003c0e:	f04a                	sd	s2,32(sp)
    80003c10:	ec4e                	sd	s3,24(sp)
    80003c12:	e852                	sd	s4,16(sp)
    80003c14:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c16:	04451703          	lh	a4,68(a0)
    80003c1a:	4785                	li	a5,1
    80003c1c:	00f71a63          	bne	a4,a5,80003c30 <dirlookup+0x2a>
    80003c20:	892a                	mv	s2,a0
    80003c22:	89ae                	mv	s3,a1
    80003c24:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c26:	457c                	lw	a5,76(a0)
    80003c28:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c2a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2c:	e79d                	bnez	a5,80003c5a <dirlookup+0x54>
    80003c2e:	a8a5                	j	80003ca6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c30:	00005517          	auipc	a0,0x5
    80003c34:	be050513          	addi	a0,a0,-1056 # 80008810 <syscalls_str+0x1a8>
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	8f2080e7          	jalr	-1806(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003c40:	00005517          	auipc	a0,0x5
    80003c44:	be850513          	addi	a0,a0,-1048 # 80008828 <syscalls_str+0x1c0>
    80003c48:	ffffd097          	auipc	ra,0xffffd
    80003c4c:	8e2080e7          	jalr	-1822(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c50:	24c1                	addiw	s1,s1,16
    80003c52:	04c92783          	lw	a5,76(s2)
    80003c56:	04f4f763          	bgeu	s1,a5,80003ca4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c5a:	4741                	li	a4,16
    80003c5c:	86a6                	mv	a3,s1
    80003c5e:	fc040613          	addi	a2,s0,-64
    80003c62:	4581                	li	a1,0
    80003c64:	854a                	mv	a0,s2
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	d70080e7          	jalr	-656(ra) # 800039d6 <readi>
    80003c6e:	47c1                	li	a5,16
    80003c70:	fcf518e3          	bne	a0,a5,80003c40 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c74:	fc045783          	lhu	a5,-64(s0)
    80003c78:	dfe1                	beqz	a5,80003c50 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c7a:	fc240593          	addi	a1,s0,-62
    80003c7e:	854e                	mv	a0,s3
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	f6c080e7          	jalr	-148(ra) # 80003bec <namecmp>
    80003c88:	f561                	bnez	a0,80003c50 <dirlookup+0x4a>
      if(poff)
    80003c8a:	000a0463          	beqz	s4,80003c92 <dirlookup+0x8c>
        *poff = off;
    80003c8e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c92:	fc045583          	lhu	a1,-64(s0)
    80003c96:	00092503          	lw	a0,0(s2)
    80003c9a:	fffff097          	auipc	ra,0xfffff
    80003c9e:	754080e7          	jalr	1876(ra) # 800033ee <iget>
    80003ca2:	a011                	j	80003ca6 <dirlookup+0xa0>
  return 0;
    80003ca4:	4501                	li	a0,0
}
    80003ca6:	70e2                	ld	ra,56(sp)
    80003ca8:	7442                	ld	s0,48(sp)
    80003caa:	74a2                	ld	s1,40(sp)
    80003cac:	7902                	ld	s2,32(sp)
    80003cae:	69e2                	ld	s3,24(sp)
    80003cb0:	6a42                	ld	s4,16(sp)
    80003cb2:	6121                	addi	sp,sp,64
    80003cb4:	8082                	ret

0000000080003cb6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cb6:	711d                	addi	sp,sp,-96
    80003cb8:	ec86                	sd	ra,88(sp)
    80003cba:	e8a2                	sd	s0,80(sp)
    80003cbc:	e4a6                	sd	s1,72(sp)
    80003cbe:	e0ca                	sd	s2,64(sp)
    80003cc0:	fc4e                	sd	s3,56(sp)
    80003cc2:	f852                	sd	s4,48(sp)
    80003cc4:	f456                	sd	s5,40(sp)
    80003cc6:	f05a                	sd	s6,32(sp)
    80003cc8:	ec5e                	sd	s7,24(sp)
    80003cca:	e862                	sd	s8,16(sp)
    80003ccc:	e466                	sd	s9,8(sp)
    80003cce:	1080                	addi	s0,sp,96
    80003cd0:	84aa                	mv	s1,a0
    80003cd2:	8aae                	mv	s5,a1
    80003cd4:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cd6:	00054703          	lbu	a4,0(a0)
    80003cda:	02f00793          	li	a5,47
    80003cde:	02f70363          	beq	a4,a5,80003d04 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ce2:	ffffe097          	auipc	ra,0xffffe
    80003ce6:	cb0080e7          	jalr	-848(ra) # 80001992 <myproc>
    80003cea:	15053503          	ld	a0,336(a0)
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	9f6080e7          	jalr	-1546(ra) # 800036e4 <idup>
    80003cf6:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cf8:	02f00913          	li	s2,47
  len = path - s;
    80003cfc:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003cfe:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d00:	4b85                	li	s7,1
    80003d02:	a865                	j	80003dba <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d04:	4585                	li	a1,1
    80003d06:	4505                	li	a0,1
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	6e6080e7          	jalr	1766(ra) # 800033ee <iget>
    80003d10:	89aa                	mv	s3,a0
    80003d12:	b7dd                	j	80003cf8 <namex+0x42>
      iunlockput(ip);
    80003d14:	854e                	mv	a0,s3
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	c6e080e7          	jalr	-914(ra) # 80003984 <iunlockput>
      return 0;
    80003d1e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d20:	854e                	mv	a0,s3
    80003d22:	60e6                	ld	ra,88(sp)
    80003d24:	6446                	ld	s0,80(sp)
    80003d26:	64a6                	ld	s1,72(sp)
    80003d28:	6906                	ld	s2,64(sp)
    80003d2a:	79e2                	ld	s3,56(sp)
    80003d2c:	7a42                	ld	s4,48(sp)
    80003d2e:	7aa2                	ld	s5,40(sp)
    80003d30:	7b02                	ld	s6,32(sp)
    80003d32:	6be2                	ld	s7,24(sp)
    80003d34:	6c42                	ld	s8,16(sp)
    80003d36:	6ca2                	ld	s9,8(sp)
    80003d38:	6125                	addi	sp,sp,96
    80003d3a:	8082                	ret
      iunlock(ip);
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	aa6080e7          	jalr	-1370(ra) # 800037e4 <iunlock>
      return ip;
    80003d46:	bfe9                	j	80003d20 <namex+0x6a>
      iunlockput(ip);
    80003d48:	854e                	mv	a0,s3
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	c3a080e7          	jalr	-966(ra) # 80003984 <iunlockput>
      return 0;
    80003d52:	89e6                	mv	s3,s9
    80003d54:	b7f1                	j	80003d20 <namex+0x6a>
  len = path - s;
    80003d56:	40b48633          	sub	a2,s1,a1
    80003d5a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d5e:	099c5463          	bge	s8,s9,80003de6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d62:	4639                	li	a2,14
    80003d64:	8552                	mv	a0,s4
    80003d66:	ffffd097          	auipc	ra,0xffffd
    80003d6a:	fb4080e7          	jalr	-76(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003d6e:	0004c783          	lbu	a5,0(s1)
    80003d72:	01279763          	bne	a5,s2,80003d80 <namex+0xca>
    path++;
    80003d76:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d78:	0004c783          	lbu	a5,0(s1)
    80003d7c:	ff278de3          	beq	a5,s2,80003d76 <namex+0xc0>
    ilock(ip);
    80003d80:	854e                	mv	a0,s3
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	9a0080e7          	jalr	-1632(ra) # 80003722 <ilock>
    if(ip->type != T_DIR){
    80003d8a:	04499783          	lh	a5,68(s3)
    80003d8e:	f97793e3          	bne	a5,s7,80003d14 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d92:	000a8563          	beqz	s5,80003d9c <namex+0xe6>
    80003d96:	0004c783          	lbu	a5,0(s1)
    80003d9a:	d3cd                	beqz	a5,80003d3c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d9c:	865a                	mv	a2,s6
    80003d9e:	85d2                	mv	a1,s4
    80003da0:	854e                	mv	a0,s3
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	e64080e7          	jalr	-412(ra) # 80003c06 <dirlookup>
    80003daa:	8caa                	mv	s9,a0
    80003dac:	dd51                	beqz	a0,80003d48 <namex+0x92>
    iunlockput(ip);
    80003dae:	854e                	mv	a0,s3
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	bd4080e7          	jalr	-1068(ra) # 80003984 <iunlockput>
    ip = next;
    80003db8:	89e6                	mv	s3,s9
  while(*path == '/')
    80003dba:	0004c783          	lbu	a5,0(s1)
    80003dbe:	05279763          	bne	a5,s2,80003e0c <namex+0x156>
    path++;
    80003dc2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc4:	0004c783          	lbu	a5,0(s1)
    80003dc8:	ff278de3          	beq	a5,s2,80003dc2 <namex+0x10c>
  if(*path == 0)
    80003dcc:	c79d                	beqz	a5,80003dfa <namex+0x144>
    path++;
    80003dce:	85a6                	mv	a1,s1
  len = path - s;
    80003dd0:	8cda                	mv	s9,s6
    80003dd2:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003dd4:	01278963          	beq	a5,s2,80003de6 <namex+0x130>
    80003dd8:	dfbd                	beqz	a5,80003d56 <namex+0xa0>
    path++;
    80003dda:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ddc:	0004c783          	lbu	a5,0(s1)
    80003de0:	ff279ce3          	bne	a5,s2,80003dd8 <namex+0x122>
    80003de4:	bf8d                	j	80003d56 <namex+0xa0>
    memmove(name, s, len);
    80003de6:	2601                	sext.w	a2,a2
    80003de8:	8552                	mv	a0,s4
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	f30080e7          	jalr	-208(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003df2:	9cd2                	add	s9,s9,s4
    80003df4:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003df8:	bf9d                	j	80003d6e <namex+0xb8>
  if(nameiparent){
    80003dfa:	f20a83e3          	beqz	s5,80003d20 <namex+0x6a>
    iput(ip);
    80003dfe:	854e                	mv	a0,s3
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	adc080e7          	jalr	-1316(ra) # 800038dc <iput>
    return 0;
    80003e08:	4981                	li	s3,0
    80003e0a:	bf19                	j	80003d20 <namex+0x6a>
  if(*path == 0)
    80003e0c:	d7fd                	beqz	a5,80003dfa <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	85a6                	mv	a1,s1
    80003e14:	b7d1                	j	80003dd8 <namex+0x122>

0000000080003e16 <dirlink>:
{
    80003e16:	7139                	addi	sp,sp,-64
    80003e18:	fc06                	sd	ra,56(sp)
    80003e1a:	f822                	sd	s0,48(sp)
    80003e1c:	f426                	sd	s1,40(sp)
    80003e1e:	f04a                	sd	s2,32(sp)
    80003e20:	ec4e                	sd	s3,24(sp)
    80003e22:	e852                	sd	s4,16(sp)
    80003e24:	0080                	addi	s0,sp,64
    80003e26:	892a                	mv	s2,a0
    80003e28:	8a2e                	mv	s4,a1
    80003e2a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e2c:	4601                	li	a2,0
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	dd8080e7          	jalr	-552(ra) # 80003c06 <dirlookup>
    80003e36:	e93d                	bnez	a0,80003eac <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e38:	04c92483          	lw	s1,76(s2)
    80003e3c:	c49d                	beqz	s1,80003e6a <dirlink+0x54>
    80003e3e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e40:	4741                	li	a4,16
    80003e42:	86a6                	mv	a3,s1
    80003e44:	fc040613          	addi	a2,s0,-64
    80003e48:	4581                	li	a1,0
    80003e4a:	854a                	mv	a0,s2
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	b8a080e7          	jalr	-1142(ra) # 800039d6 <readi>
    80003e54:	47c1                	li	a5,16
    80003e56:	06f51163          	bne	a0,a5,80003eb8 <dirlink+0xa2>
    if(de.inum == 0)
    80003e5a:	fc045783          	lhu	a5,-64(s0)
    80003e5e:	c791                	beqz	a5,80003e6a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e60:	24c1                	addiw	s1,s1,16
    80003e62:	04c92783          	lw	a5,76(s2)
    80003e66:	fcf4ede3          	bltu	s1,a5,80003e40 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e6a:	4639                	li	a2,14
    80003e6c:	85d2                	mv	a1,s4
    80003e6e:	fc240513          	addi	a0,s0,-62
    80003e72:	ffffd097          	auipc	ra,0xffffd
    80003e76:	f60080e7          	jalr	-160(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003e7a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e7e:	4741                	li	a4,16
    80003e80:	86a6                	mv	a3,s1
    80003e82:	fc040613          	addi	a2,s0,-64
    80003e86:	4581                	li	a1,0
    80003e88:	854a                	mv	a0,s2
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	c44080e7          	jalr	-956(ra) # 80003ace <writei>
    80003e92:	872a                	mv	a4,a0
    80003e94:	47c1                	li	a5,16
  return 0;
    80003e96:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e98:	02f71863          	bne	a4,a5,80003ec8 <dirlink+0xb2>
}
    80003e9c:	70e2                	ld	ra,56(sp)
    80003e9e:	7442                	ld	s0,48(sp)
    80003ea0:	74a2                	ld	s1,40(sp)
    80003ea2:	7902                	ld	s2,32(sp)
    80003ea4:	69e2                	ld	s3,24(sp)
    80003ea6:	6a42                	ld	s4,16(sp)
    80003ea8:	6121                	addi	sp,sp,64
    80003eaa:	8082                	ret
    iput(ip);
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	a30080e7          	jalr	-1488(ra) # 800038dc <iput>
    return -1;
    80003eb4:	557d                	li	a0,-1
    80003eb6:	b7dd                	j	80003e9c <dirlink+0x86>
      panic("dirlink read");
    80003eb8:	00005517          	auipc	a0,0x5
    80003ebc:	98050513          	addi	a0,a0,-1664 # 80008838 <syscalls_str+0x1d0>
    80003ec0:	ffffc097          	auipc	ra,0xffffc
    80003ec4:	66a080e7          	jalr	1642(ra) # 8000052a <panic>
    panic("dirlink");
    80003ec8:	00005517          	auipc	a0,0x5
    80003ecc:	a8050513          	addi	a0,a0,-1408 # 80008948 <syscalls_str+0x2e0>
    80003ed0:	ffffc097          	auipc	ra,0xffffc
    80003ed4:	65a080e7          	jalr	1626(ra) # 8000052a <panic>

0000000080003ed8 <namei>:

struct inode*
namei(char *path)
{
    80003ed8:	1101                	addi	sp,sp,-32
    80003eda:	ec06                	sd	ra,24(sp)
    80003edc:	e822                	sd	s0,16(sp)
    80003ede:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ee0:	fe040613          	addi	a2,s0,-32
    80003ee4:	4581                	li	a1,0
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	dd0080e7          	jalr	-560(ra) # 80003cb6 <namex>
}
    80003eee:	60e2                	ld	ra,24(sp)
    80003ef0:	6442                	ld	s0,16(sp)
    80003ef2:	6105                	addi	sp,sp,32
    80003ef4:	8082                	ret

0000000080003ef6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ef6:	1141                	addi	sp,sp,-16
    80003ef8:	e406                	sd	ra,8(sp)
    80003efa:	e022                	sd	s0,0(sp)
    80003efc:	0800                	addi	s0,sp,16
    80003efe:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f00:	4585                	li	a1,1
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	db4080e7          	jalr	-588(ra) # 80003cb6 <namex>
}
    80003f0a:	60a2                	ld	ra,8(sp)
    80003f0c:	6402                	ld	s0,0(sp)
    80003f0e:	0141                	addi	sp,sp,16
    80003f10:	8082                	ret

0000000080003f12 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f12:	1101                	addi	sp,sp,-32
    80003f14:	ec06                	sd	ra,24(sp)
    80003f16:	e822                	sd	s0,16(sp)
    80003f18:	e426                	sd	s1,8(sp)
    80003f1a:	e04a                	sd	s2,0(sp)
    80003f1c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f1e:	0001d917          	auipc	s2,0x1d
    80003f22:	35290913          	addi	s2,s2,850 # 80021270 <log>
    80003f26:	01892583          	lw	a1,24(s2)
    80003f2a:	02892503          	lw	a0,40(s2)
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	ff0080e7          	jalr	-16(ra) # 80002f1e <bread>
    80003f36:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f38:	02c92683          	lw	a3,44(s2)
    80003f3c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f3e:	02d05863          	blez	a3,80003f6e <write_head+0x5c>
    80003f42:	0001d797          	auipc	a5,0x1d
    80003f46:	35e78793          	addi	a5,a5,862 # 800212a0 <log+0x30>
    80003f4a:	05c50713          	addi	a4,a0,92
    80003f4e:	36fd                	addiw	a3,a3,-1
    80003f50:	02069613          	slli	a2,a3,0x20
    80003f54:	01e65693          	srli	a3,a2,0x1e
    80003f58:	0001d617          	auipc	a2,0x1d
    80003f5c:	34c60613          	addi	a2,a2,844 # 800212a4 <log+0x34>
    80003f60:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f62:	4390                	lw	a2,0(a5)
    80003f64:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f66:	0791                	addi	a5,a5,4
    80003f68:	0711                	addi	a4,a4,4
    80003f6a:	fed79ce3          	bne	a5,a3,80003f62 <write_head+0x50>
  }
  bwrite(buf);
    80003f6e:	8526                	mv	a0,s1
    80003f70:	fffff097          	auipc	ra,0xfffff
    80003f74:	0a0080e7          	jalr	160(ra) # 80003010 <bwrite>
  brelse(buf);
    80003f78:	8526                	mv	a0,s1
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	0d4080e7          	jalr	212(ra) # 8000304e <brelse>
}
    80003f82:	60e2                	ld	ra,24(sp)
    80003f84:	6442                	ld	s0,16(sp)
    80003f86:	64a2                	ld	s1,8(sp)
    80003f88:	6902                	ld	s2,0(sp)
    80003f8a:	6105                	addi	sp,sp,32
    80003f8c:	8082                	ret

0000000080003f8e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f8e:	0001d797          	auipc	a5,0x1d
    80003f92:	30e7a783          	lw	a5,782(a5) # 8002129c <log+0x2c>
    80003f96:	0af05d63          	blez	a5,80004050 <install_trans+0xc2>
{
    80003f9a:	7139                	addi	sp,sp,-64
    80003f9c:	fc06                	sd	ra,56(sp)
    80003f9e:	f822                	sd	s0,48(sp)
    80003fa0:	f426                	sd	s1,40(sp)
    80003fa2:	f04a                	sd	s2,32(sp)
    80003fa4:	ec4e                	sd	s3,24(sp)
    80003fa6:	e852                	sd	s4,16(sp)
    80003fa8:	e456                	sd	s5,8(sp)
    80003faa:	e05a                	sd	s6,0(sp)
    80003fac:	0080                	addi	s0,sp,64
    80003fae:	8b2a                	mv	s6,a0
    80003fb0:	0001da97          	auipc	s5,0x1d
    80003fb4:	2f0a8a93          	addi	s5,s5,752 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fba:	0001d997          	auipc	s3,0x1d
    80003fbe:	2b698993          	addi	s3,s3,694 # 80021270 <log>
    80003fc2:	a00d                	j	80003fe4 <install_trans+0x56>
    brelse(lbuf);
    80003fc4:	854a                	mv	a0,s2
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	088080e7          	jalr	136(ra) # 8000304e <brelse>
    brelse(dbuf);
    80003fce:	8526                	mv	a0,s1
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	07e080e7          	jalr	126(ra) # 8000304e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd8:	2a05                	addiw	s4,s4,1
    80003fda:	0a91                	addi	s5,s5,4
    80003fdc:	02c9a783          	lw	a5,44(s3)
    80003fe0:	04fa5e63          	bge	s4,a5,8000403c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fe4:	0189a583          	lw	a1,24(s3)
    80003fe8:	014585bb          	addw	a1,a1,s4
    80003fec:	2585                	addiw	a1,a1,1
    80003fee:	0289a503          	lw	a0,40(s3)
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	f2c080e7          	jalr	-212(ra) # 80002f1e <bread>
    80003ffa:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ffc:	000aa583          	lw	a1,0(s5)
    80004000:	0289a503          	lw	a0,40(s3)
    80004004:	fffff097          	auipc	ra,0xfffff
    80004008:	f1a080e7          	jalr	-230(ra) # 80002f1e <bread>
    8000400c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000400e:	40000613          	li	a2,1024
    80004012:	05890593          	addi	a1,s2,88
    80004016:	05850513          	addi	a0,a0,88
    8000401a:	ffffd097          	auipc	ra,0xffffd
    8000401e:	d00080e7          	jalr	-768(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004022:	8526                	mv	a0,s1
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	fec080e7          	jalr	-20(ra) # 80003010 <bwrite>
    if(recovering == 0)
    8000402c:	f80b1ce3          	bnez	s6,80003fc4 <install_trans+0x36>
      bunpin(dbuf);
    80004030:	8526                	mv	a0,s1
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	0f6080e7          	jalr	246(ra) # 80003128 <bunpin>
    8000403a:	b769                	j	80003fc4 <install_trans+0x36>
}
    8000403c:	70e2                	ld	ra,56(sp)
    8000403e:	7442                	ld	s0,48(sp)
    80004040:	74a2                	ld	s1,40(sp)
    80004042:	7902                	ld	s2,32(sp)
    80004044:	69e2                	ld	s3,24(sp)
    80004046:	6a42                	ld	s4,16(sp)
    80004048:	6aa2                	ld	s5,8(sp)
    8000404a:	6b02                	ld	s6,0(sp)
    8000404c:	6121                	addi	sp,sp,64
    8000404e:	8082                	ret
    80004050:	8082                	ret

0000000080004052 <initlog>:
{
    80004052:	7179                	addi	sp,sp,-48
    80004054:	f406                	sd	ra,40(sp)
    80004056:	f022                	sd	s0,32(sp)
    80004058:	ec26                	sd	s1,24(sp)
    8000405a:	e84a                	sd	s2,16(sp)
    8000405c:	e44e                	sd	s3,8(sp)
    8000405e:	1800                	addi	s0,sp,48
    80004060:	892a                	mv	s2,a0
    80004062:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004064:	0001d497          	auipc	s1,0x1d
    80004068:	20c48493          	addi	s1,s1,524 # 80021270 <log>
    8000406c:	00004597          	auipc	a1,0x4
    80004070:	7dc58593          	addi	a1,a1,2012 # 80008848 <syscalls_str+0x1e0>
    80004074:	8526                	mv	a0,s1
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	abc080e7          	jalr	-1348(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000407e:	0149a583          	lw	a1,20(s3)
    80004082:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004084:	0109a783          	lw	a5,16(s3)
    80004088:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000408a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000408e:	854a                	mv	a0,s2
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	e8e080e7          	jalr	-370(ra) # 80002f1e <bread>
  log.lh.n = lh->n;
    80004098:	4d34                	lw	a3,88(a0)
    8000409a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000409c:	02d05663          	blez	a3,800040c8 <initlog+0x76>
    800040a0:	05c50793          	addi	a5,a0,92
    800040a4:	0001d717          	auipc	a4,0x1d
    800040a8:	1fc70713          	addi	a4,a4,508 # 800212a0 <log+0x30>
    800040ac:	36fd                	addiw	a3,a3,-1
    800040ae:	02069613          	slli	a2,a3,0x20
    800040b2:	01e65693          	srli	a3,a2,0x1e
    800040b6:	06050613          	addi	a2,a0,96
    800040ba:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040bc:	4390                	lw	a2,0(a5)
    800040be:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040c0:	0791                	addi	a5,a5,4
    800040c2:	0711                	addi	a4,a4,4
    800040c4:	fed79ce3          	bne	a5,a3,800040bc <initlog+0x6a>
  brelse(buf);
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	f86080e7          	jalr	-122(ra) # 8000304e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040d0:	4505                	li	a0,1
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	ebc080e7          	jalr	-324(ra) # 80003f8e <install_trans>
  log.lh.n = 0;
    800040da:	0001d797          	auipc	a5,0x1d
    800040de:	1c07a123          	sw	zero,450(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	e30080e7          	jalr	-464(ra) # 80003f12 <write_head>
}
    800040ea:	70a2                	ld	ra,40(sp)
    800040ec:	7402                	ld	s0,32(sp)
    800040ee:	64e2                	ld	s1,24(sp)
    800040f0:	6942                	ld	s2,16(sp)
    800040f2:	69a2                	ld	s3,8(sp)
    800040f4:	6145                	addi	sp,sp,48
    800040f6:	8082                	ret

00000000800040f8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040f8:	1101                	addi	sp,sp,-32
    800040fa:	ec06                	sd	ra,24(sp)
    800040fc:	e822                	sd	s0,16(sp)
    800040fe:	e426                	sd	s1,8(sp)
    80004100:	e04a                	sd	s2,0(sp)
    80004102:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004104:	0001d517          	auipc	a0,0x1d
    80004108:	16c50513          	addi	a0,a0,364 # 80021270 <log>
    8000410c:	ffffd097          	auipc	ra,0xffffd
    80004110:	ab6080e7          	jalr	-1354(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004114:	0001d497          	auipc	s1,0x1d
    80004118:	15c48493          	addi	s1,s1,348 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000411c:	4979                	li	s2,30
    8000411e:	a039                	j	8000412c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004120:	85a6                	mv	a1,s1
    80004122:	8526                	mv	a0,s1
    80004124:	ffffe097          	auipc	ra,0xffffe
    80004128:	f3a080e7          	jalr	-198(ra) # 8000205e <sleep>
    if(log.committing){
    8000412c:	50dc                	lw	a5,36(s1)
    8000412e:	fbed                	bnez	a5,80004120 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004130:	509c                	lw	a5,32(s1)
    80004132:	0017871b          	addiw	a4,a5,1
    80004136:	0007069b          	sext.w	a3,a4
    8000413a:	0027179b          	slliw	a5,a4,0x2
    8000413e:	9fb9                	addw	a5,a5,a4
    80004140:	0017979b          	slliw	a5,a5,0x1
    80004144:	54d8                	lw	a4,44(s1)
    80004146:	9fb9                	addw	a5,a5,a4
    80004148:	00f95963          	bge	s2,a5,8000415a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000414c:	85a6                	mv	a1,s1
    8000414e:	8526                	mv	a0,s1
    80004150:	ffffe097          	auipc	ra,0xffffe
    80004154:	f0e080e7          	jalr	-242(ra) # 8000205e <sleep>
    80004158:	bfd1                	j	8000412c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000415a:	0001d517          	auipc	a0,0x1d
    8000415e:	11650513          	addi	a0,a0,278 # 80021270 <log>
    80004162:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004164:	ffffd097          	auipc	ra,0xffffd
    80004168:	b12080e7          	jalr	-1262(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000416c:	60e2                	ld	ra,24(sp)
    8000416e:	6442                	ld	s0,16(sp)
    80004170:	64a2                	ld	s1,8(sp)
    80004172:	6902                	ld	s2,0(sp)
    80004174:	6105                	addi	sp,sp,32
    80004176:	8082                	ret

0000000080004178 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004178:	7139                	addi	sp,sp,-64
    8000417a:	fc06                	sd	ra,56(sp)
    8000417c:	f822                	sd	s0,48(sp)
    8000417e:	f426                	sd	s1,40(sp)
    80004180:	f04a                	sd	s2,32(sp)
    80004182:	ec4e                	sd	s3,24(sp)
    80004184:	e852                	sd	s4,16(sp)
    80004186:	e456                	sd	s5,8(sp)
    80004188:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000418a:	0001d497          	auipc	s1,0x1d
    8000418e:	0e648493          	addi	s1,s1,230 # 80021270 <log>
    80004192:	8526                	mv	a0,s1
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	a2e080e7          	jalr	-1490(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000419c:	509c                	lw	a5,32(s1)
    8000419e:	37fd                	addiw	a5,a5,-1
    800041a0:	0007891b          	sext.w	s2,a5
    800041a4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041a6:	50dc                	lw	a5,36(s1)
    800041a8:	e7b9                	bnez	a5,800041f6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041aa:	04091e63          	bnez	s2,80004206 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041ae:	0001d497          	auipc	s1,0x1d
    800041b2:	0c248493          	addi	s1,s1,194 # 80021270 <log>
    800041b6:	4785                	li	a5,1
    800041b8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ba:	8526                	mv	a0,s1
    800041bc:	ffffd097          	auipc	ra,0xffffd
    800041c0:	aba080e7          	jalr	-1350(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041c4:	54dc                	lw	a5,44(s1)
    800041c6:	06f04763          	bgtz	a5,80004234 <end_op+0xbc>
    acquire(&log.lock);
    800041ca:	0001d497          	auipc	s1,0x1d
    800041ce:	0a648493          	addi	s1,s1,166 # 80021270 <log>
    800041d2:	8526                	mv	a0,s1
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	9ee080e7          	jalr	-1554(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800041dc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041e0:	8526                	mv	a0,s1
    800041e2:	ffffe097          	auipc	ra,0xffffe
    800041e6:	008080e7          	jalr	8(ra) # 800021ea <wakeup>
    release(&log.lock);
    800041ea:	8526                	mv	a0,s1
    800041ec:	ffffd097          	auipc	ra,0xffffd
    800041f0:	a8a080e7          	jalr	-1398(ra) # 80000c76 <release>
}
    800041f4:	a03d                	j	80004222 <end_op+0xaa>
    panic("log.committing");
    800041f6:	00004517          	auipc	a0,0x4
    800041fa:	65a50513          	addi	a0,a0,1626 # 80008850 <syscalls_str+0x1e8>
    800041fe:	ffffc097          	auipc	ra,0xffffc
    80004202:	32c080e7          	jalr	812(ra) # 8000052a <panic>
    wakeup(&log);
    80004206:	0001d497          	auipc	s1,0x1d
    8000420a:	06a48493          	addi	s1,s1,106 # 80021270 <log>
    8000420e:	8526                	mv	a0,s1
    80004210:	ffffe097          	auipc	ra,0xffffe
    80004214:	fda080e7          	jalr	-38(ra) # 800021ea <wakeup>
  release(&log.lock);
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>
}
    80004222:	70e2                	ld	ra,56(sp)
    80004224:	7442                	ld	s0,48(sp)
    80004226:	74a2                	ld	s1,40(sp)
    80004228:	7902                	ld	s2,32(sp)
    8000422a:	69e2                	ld	s3,24(sp)
    8000422c:	6a42                	ld	s4,16(sp)
    8000422e:	6aa2                	ld	s5,8(sp)
    80004230:	6121                	addi	sp,sp,64
    80004232:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004234:	0001da97          	auipc	s5,0x1d
    80004238:	06ca8a93          	addi	s5,s5,108 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000423c:	0001da17          	auipc	s4,0x1d
    80004240:	034a0a13          	addi	s4,s4,52 # 80021270 <log>
    80004244:	018a2583          	lw	a1,24(s4)
    80004248:	012585bb          	addw	a1,a1,s2
    8000424c:	2585                	addiw	a1,a1,1
    8000424e:	028a2503          	lw	a0,40(s4)
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	ccc080e7          	jalr	-820(ra) # 80002f1e <bread>
    8000425a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000425c:	000aa583          	lw	a1,0(s5)
    80004260:	028a2503          	lw	a0,40(s4)
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	cba080e7          	jalr	-838(ra) # 80002f1e <bread>
    8000426c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000426e:	40000613          	li	a2,1024
    80004272:	05850593          	addi	a1,a0,88
    80004276:	05848513          	addi	a0,s1,88
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	aa0080e7          	jalr	-1376(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004282:	8526                	mv	a0,s1
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	d8c080e7          	jalr	-628(ra) # 80003010 <bwrite>
    brelse(from);
    8000428c:	854e                	mv	a0,s3
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	dc0080e7          	jalr	-576(ra) # 8000304e <brelse>
    brelse(to);
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	db6080e7          	jalr	-586(ra) # 8000304e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a0:	2905                	addiw	s2,s2,1
    800042a2:	0a91                	addi	s5,s5,4
    800042a4:	02ca2783          	lw	a5,44(s4)
    800042a8:	f8f94ee3          	blt	s2,a5,80004244 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	c66080e7          	jalr	-922(ra) # 80003f12 <write_head>
    install_trans(0); // Now install writes to home locations
    800042b4:	4501                	li	a0,0
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	cd8080e7          	jalr	-808(ra) # 80003f8e <install_trans>
    log.lh.n = 0;
    800042be:	0001d797          	auipc	a5,0x1d
    800042c2:	fc07af23          	sw	zero,-34(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	c4c080e7          	jalr	-948(ra) # 80003f12 <write_head>
    800042ce:	bdf5                	j	800041ca <end_op+0x52>

00000000800042d0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042d0:	1101                	addi	sp,sp,-32
    800042d2:	ec06                	sd	ra,24(sp)
    800042d4:	e822                	sd	s0,16(sp)
    800042d6:	e426                	sd	s1,8(sp)
    800042d8:	e04a                	sd	s2,0(sp)
    800042da:	1000                	addi	s0,sp,32
    800042dc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042de:	0001d917          	auipc	s2,0x1d
    800042e2:	f9290913          	addi	s2,s2,-110 # 80021270 <log>
    800042e6:	854a                	mv	a0,s2
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	8da080e7          	jalr	-1830(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042f0:	02c92603          	lw	a2,44(s2)
    800042f4:	47f5                	li	a5,29
    800042f6:	06c7c563          	blt	a5,a2,80004360 <log_write+0x90>
    800042fa:	0001d797          	auipc	a5,0x1d
    800042fe:	f927a783          	lw	a5,-110(a5) # 8002128c <log+0x1c>
    80004302:	37fd                	addiw	a5,a5,-1
    80004304:	04f65e63          	bge	a2,a5,80004360 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004308:	0001d797          	auipc	a5,0x1d
    8000430c:	f887a783          	lw	a5,-120(a5) # 80021290 <log+0x20>
    80004310:	06f05063          	blez	a5,80004370 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004314:	4781                	li	a5,0
    80004316:	06c05563          	blez	a2,80004380 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000431a:	44cc                	lw	a1,12(s1)
    8000431c:	0001d717          	auipc	a4,0x1d
    80004320:	f8470713          	addi	a4,a4,-124 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004324:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004326:	4314                	lw	a3,0(a4)
    80004328:	04b68c63          	beq	a3,a1,80004380 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000432c:	2785                	addiw	a5,a5,1
    8000432e:	0711                	addi	a4,a4,4
    80004330:	fef61be3          	bne	a2,a5,80004326 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004334:	0621                	addi	a2,a2,8
    80004336:	060a                	slli	a2,a2,0x2
    80004338:	0001d797          	auipc	a5,0x1d
    8000433c:	f3878793          	addi	a5,a5,-200 # 80021270 <log>
    80004340:	963e                	add	a2,a2,a5
    80004342:	44dc                	lw	a5,12(s1)
    80004344:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004346:	8526                	mv	a0,s1
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	da4080e7          	jalr	-604(ra) # 800030ec <bpin>
    log.lh.n++;
    80004350:	0001d717          	auipc	a4,0x1d
    80004354:	f2070713          	addi	a4,a4,-224 # 80021270 <log>
    80004358:	575c                	lw	a5,44(a4)
    8000435a:	2785                	addiw	a5,a5,1
    8000435c:	d75c                	sw	a5,44(a4)
    8000435e:	a835                	j	8000439a <log_write+0xca>
    panic("too big a transaction");
    80004360:	00004517          	auipc	a0,0x4
    80004364:	50050513          	addi	a0,a0,1280 # 80008860 <syscalls_str+0x1f8>
    80004368:	ffffc097          	auipc	ra,0xffffc
    8000436c:	1c2080e7          	jalr	450(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004370:	00004517          	auipc	a0,0x4
    80004374:	50850513          	addi	a0,a0,1288 # 80008878 <syscalls_str+0x210>
    80004378:	ffffc097          	auipc	ra,0xffffc
    8000437c:	1b2080e7          	jalr	434(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004380:	00878713          	addi	a4,a5,8
    80004384:	00271693          	slli	a3,a4,0x2
    80004388:	0001d717          	auipc	a4,0x1d
    8000438c:	ee870713          	addi	a4,a4,-280 # 80021270 <log>
    80004390:	9736                	add	a4,a4,a3
    80004392:	44d4                	lw	a3,12(s1)
    80004394:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004396:	faf608e3          	beq	a2,a5,80004346 <log_write+0x76>
  }
  release(&log.lock);
    8000439a:	0001d517          	auipc	a0,0x1d
    8000439e:	ed650513          	addi	a0,a0,-298 # 80021270 <log>
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	8d4080e7          	jalr	-1836(ra) # 80000c76 <release>
}
    800043aa:	60e2                	ld	ra,24(sp)
    800043ac:	6442                	ld	s0,16(sp)
    800043ae:	64a2                	ld	s1,8(sp)
    800043b0:	6902                	ld	s2,0(sp)
    800043b2:	6105                	addi	sp,sp,32
    800043b4:	8082                	ret

00000000800043b6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043b6:	1101                	addi	sp,sp,-32
    800043b8:	ec06                	sd	ra,24(sp)
    800043ba:	e822                	sd	s0,16(sp)
    800043bc:	e426                	sd	s1,8(sp)
    800043be:	e04a                	sd	s2,0(sp)
    800043c0:	1000                	addi	s0,sp,32
    800043c2:	84aa                	mv	s1,a0
    800043c4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043c6:	00004597          	auipc	a1,0x4
    800043ca:	4d258593          	addi	a1,a1,1234 # 80008898 <syscalls_str+0x230>
    800043ce:	0521                	addi	a0,a0,8
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	762080e7          	jalr	1890(ra) # 80000b32 <initlock>
  lk->name = name;
    800043d8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043dc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e0:	0204a423          	sw	zero,40(s1)
}
    800043e4:	60e2                	ld	ra,24(sp)
    800043e6:	6442                	ld	s0,16(sp)
    800043e8:	64a2                	ld	s1,8(sp)
    800043ea:	6902                	ld	s2,0(sp)
    800043ec:	6105                	addi	sp,sp,32
    800043ee:	8082                	ret

00000000800043f0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043f0:	1101                	addi	sp,sp,-32
    800043f2:	ec06                	sd	ra,24(sp)
    800043f4:	e822                	sd	s0,16(sp)
    800043f6:	e426                	sd	s1,8(sp)
    800043f8:	e04a                	sd	s2,0(sp)
    800043fa:	1000                	addi	s0,sp,32
    800043fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043fe:	00850913          	addi	s2,a0,8
    80004402:	854a                	mv	a0,s2
    80004404:	ffffc097          	auipc	ra,0xffffc
    80004408:	7be080e7          	jalr	1982(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    8000440c:	409c                	lw	a5,0(s1)
    8000440e:	cb89                	beqz	a5,80004420 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004410:	85ca                	mv	a1,s2
    80004412:	8526                	mv	a0,s1
    80004414:	ffffe097          	auipc	ra,0xffffe
    80004418:	c4a080e7          	jalr	-950(ra) # 8000205e <sleep>
  while (lk->locked) {
    8000441c:	409c                	lw	a5,0(s1)
    8000441e:	fbed                	bnez	a5,80004410 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004420:	4785                	li	a5,1
    80004422:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	56e080e7          	jalr	1390(ra) # 80001992 <myproc>
    8000442c:	591c                	lw	a5,48(a0)
    8000442e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004430:	854a                	mv	a0,s2
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	844080e7          	jalr	-1980(ra) # 80000c76 <release>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004454:	00850913          	addi	s2,a0,8
    80004458:	854a                	mv	a0,s2
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	768080e7          	jalr	1896(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004462:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004466:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffe097          	auipc	ra,0xffffe
    80004470:	d7e080e7          	jalr	-642(ra) # 800021ea <wakeup>
  release(&lk->lk);
    80004474:	854a                	mv	a0,s2
    80004476:	ffffd097          	auipc	ra,0xffffd
    8000447a:	800080e7          	jalr	-2048(ra) # 80000c76 <release>
}
    8000447e:	60e2                	ld	ra,24(sp)
    80004480:	6442                	ld	s0,16(sp)
    80004482:	64a2                	ld	s1,8(sp)
    80004484:	6902                	ld	s2,0(sp)
    80004486:	6105                	addi	sp,sp,32
    80004488:	8082                	ret

000000008000448a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000448a:	7179                	addi	sp,sp,-48
    8000448c:	f406                	sd	ra,40(sp)
    8000448e:	f022                	sd	s0,32(sp)
    80004490:	ec26                	sd	s1,24(sp)
    80004492:	e84a                	sd	s2,16(sp)
    80004494:	e44e                	sd	s3,8(sp)
    80004496:	1800                	addi	s0,sp,48
    80004498:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000449a:	00850913          	addi	s2,a0,8
    8000449e:	854a                	mv	a0,s2
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	722080e7          	jalr	1826(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a8:	409c                	lw	a5,0(s1)
    800044aa:	ef99                	bnez	a5,800044c8 <holdingsleep+0x3e>
    800044ac:	4481                	li	s1,0
  release(&lk->lk);
    800044ae:	854a                	mv	a0,s2
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	7c6080e7          	jalr	1990(ra) # 80000c76 <release>
  return r;
}
    800044b8:	8526                	mv	a0,s1
    800044ba:	70a2                	ld	ra,40(sp)
    800044bc:	7402                	ld	s0,32(sp)
    800044be:	64e2                	ld	s1,24(sp)
    800044c0:	6942                	ld	s2,16(sp)
    800044c2:	69a2                	ld	s3,8(sp)
    800044c4:	6145                	addi	sp,sp,48
    800044c6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044c8:	0284a983          	lw	s3,40(s1)
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	4c6080e7          	jalr	1222(ra) # 80001992 <myproc>
    800044d4:	5904                	lw	s1,48(a0)
    800044d6:	413484b3          	sub	s1,s1,s3
    800044da:	0014b493          	seqz	s1,s1
    800044de:	bfc1                	j	800044ae <holdingsleep+0x24>

00000000800044e0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044e0:	1141                	addi	sp,sp,-16
    800044e2:	e406                	sd	ra,8(sp)
    800044e4:	e022                	sd	s0,0(sp)
    800044e6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044e8:	00004597          	auipc	a1,0x4
    800044ec:	3c058593          	addi	a1,a1,960 # 800088a8 <syscalls_str+0x240>
    800044f0:	0001d517          	auipc	a0,0x1d
    800044f4:	ec850513          	addi	a0,a0,-312 # 800213b8 <ftable>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	63a080e7          	jalr	1594(ra) # 80000b32 <initlock>
}
    80004500:	60a2                	ld	ra,8(sp)
    80004502:	6402                	ld	s0,0(sp)
    80004504:	0141                	addi	sp,sp,16
    80004506:	8082                	ret

0000000080004508 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004508:	1101                	addi	sp,sp,-32
    8000450a:	ec06                	sd	ra,24(sp)
    8000450c:	e822                	sd	s0,16(sp)
    8000450e:	e426                	sd	s1,8(sp)
    80004510:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004512:	0001d517          	auipc	a0,0x1d
    80004516:	ea650513          	addi	a0,a0,-346 # 800213b8 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	6a8080e7          	jalr	1704(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004522:	0001d497          	auipc	s1,0x1d
    80004526:	eae48493          	addi	s1,s1,-338 # 800213d0 <ftable+0x18>
    8000452a:	0001e717          	auipc	a4,0x1e
    8000452e:	e4670713          	addi	a4,a4,-442 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004532:	40dc                	lw	a5,4(s1)
    80004534:	cf99                	beqz	a5,80004552 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004536:	02848493          	addi	s1,s1,40
    8000453a:	fee49ce3          	bne	s1,a4,80004532 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000453e:	0001d517          	auipc	a0,0x1d
    80004542:	e7a50513          	addi	a0,a0,-390 # 800213b8 <ftable>
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	730080e7          	jalr	1840(ra) # 80000c76 <release>
  return 0;
    8000454e:	4481                	li	s1,0
    80004550:	a819                	j	80004566 <filealloc+0x5e>
      f->ref = 1;
    80004552:	4785                	li	a5,1
    80004554:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004556:	0001d517          	auipc	a0,0x1d
    8000455a:	e6250513          	addi	a0,a0,-414 # 800213b8 <ftable>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	718080e7          	jalr	1816(ra) # 80000c76 <release>
}
    80004566:	8526                	mv	a0,s1
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004572:	1101                	addi	sp,sp,-32
    80004574:	ec06                	sd	ra,24(sp)
    80004576:	e822                	sd	s0,16(sp)
    80004578:	e426                	sd	s1,8(sp)
    8000457a:	1000                	addi	s0,sp,32
    8000457c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000457e:	0001d517          	auipc	a0,0x1d
    80004582:	e3a50513          	addi	a0,a0,-454 # 800213b8 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	63c080e7          	jalr	1596(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000458e:	40dc                	lw	a5,4(s1)
    80004590:	02f05263          	blez	a5,800045b4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004594:	2785                	addiw	a5,a5,1
    80004596:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	e2050513          	addi	a0,a0,-480 # 800213b8 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	6d6080e7          	jalr	1750(ra) # 80000c76 <release>
  return f;
}
    800045a8:	8526                	mv	a0,s1
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6105                	addi	sp,sp,32
    800045b2:	8082                	ret
    panic("filedup");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	2fc50513          	addi	a0,a0,764 # 800088b0 <syscalls_str+0x248>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>

00000000800045c4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045c4:	7139                	addi	sp,sp,-64
    800045c6:	fc06                	sd	ra,56(sp)
    800045c8:	f822                	sd	s0,48(sp)
    800045ca:	f426                	sd	s1,40(sp)
    800045cc:	f04a                	sd	s2,32(sp)
    800045ce:	ec4e                	sd	s3,24(sp)
    800045d0:	e852                	sd	s4,16(sp)
    800045d2:	e456                	sd	s5,8(sp)
    800045d4:	0080                	addi	s0,sp,64
    800045d6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045d8:	0001d517          	auipc	a0,0x1d
    800045dc:	de050513          	addi	a0,a0,-544 # 800213b8 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	5e2080e7          	jalr	1506(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800045e8:	40dc                	lw	a5,4(s1)
    800045ea:	06f05163          	blez	a5,8000464c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045ee:	37fd                	addiw	a5,a5,-1
    800045f0:	0007871b          	sext.w	a4,a5
    800045f4:	c0dc                	sw	a5,4(s1)
    800045f6:	06e04363          	bgtz	a4,8000465c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045fa:	0004a903          	lw	s2,0(s1)
    800045fe:	0094ca83          	lbu	s5,9(s1)
    80004602:	0104ba03          	ld	s4,16(s1)
    80004606:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000460a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000460e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004612:	0001d517          	auipc	a0,0x1d
    80004616:	da650513          	addi	a0,a0,-602 # 800213b8 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	65c080e7          	jalr	1628(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004622:	4785                	li	a5,1
    80004624:	04f90d63          	beq	s2,a5,8000467e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004628:	3979                	addiw	s2,s2,-2
    8000462a:	4785                	li	a5,1
    8000462c:	0527e063          	bltu	a5,s2,8000466c <fileclose+0xa8>
    begin_op();
    80004630:	00000097          	auipc	ra,0x0
    80004634:	ac8080e7          	jalr	-1336(ra) # 800040f8 <begin_op>
    iput(ff.ip);
    80004638:	854e                	mv	a0,s3
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	2a2080e7          	jalr	674(ra) # 800038dc <iput>
    end_op();
    80004642:	00000097          	auipc	ra,0x0
    80004646:	b36080e7          	jalr	-1226(ra) # 80004178 <end_op>
    8000464a:	a00d                	j	8000466c <fileclose+0xa8>
    panic("fileclose");
    8000464c:	00004517          	auipc	a0,0x4
    80004650:	26c50513          	addi	a0,a0,620 # 800088b8 <syscalls_str+0x250>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	ed6080e7          	jalr	-298(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000465c:	0001d517          	auipc	a0,0x1d
    80004660:	d5c50513          	addi	a0,a0,-676 # 800213b8 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	612080e7          	jalr	1554(ra) # 80000c76 <release>
  }
}
    8000466c:	70e2                	ld	ra,56(sp)
    8000466e:	7442                	ld	s0,48(sp)
    80004670:	74a2                	ld	s1,40(sp)
    80004672:	7902                	ld	s2,32(sp)
    80004674:	69e2                	ld	s3,24(sp)
    80004676:	6a42                	ld	s4,16(sp)
    80004678:	6aa2                	ld	s5,8(sp)
    8000467a:	6121                	addi	sp,sp,64
    8000467c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000467e:	85d6                	mv	a1,s5
    80004680:	8552                	mv	a0,s4
    80004682:	00000097          	auipc	ra,0x0
    80004686:	34c080e7          	jalr	844(ra) # 800049ce <pipeclose>
    8000468a:	b7cd                	j	8000466c <fileclose+0xa8>

000000008000468c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000468c:	715d                	addi	sp,sp,-80
    8000468e:	e486                	sd	ra,72(sp)
    80004690:	e0a2                	sd	s0,64(sp)
    80004692:	fc26                	sd	s1,56(sp)
    80004694:	f84a                	sd	s2,48(sp)
    80004696:	f44e                	sd	s3,40(sp)
    80004698:	0880                	addi	s0,sp,80
    8000469a:	84aa                	mv	s1,a0
    8000469c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000469e:	ffffd097          	auipc	ra,0xffffd
    800046a2:	2f4080e7          	jalr	756(ra) # 80001992 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046a6:	409c                	lw	a5,0(s1)
    800046a8:	37f9                	addiw	a5,a5,-2
    800046aa:	4705                	li	a4,1
    800046ac:	04f76763          	bltu	a4,a5,800046fa <filestat+0x6e>
    800046b0:	892a                	mv	s2,a0
    ilock(f->ip);
    800046b2:	6c88                	ld	a0,24(s1)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	06e080e7          	jalr	110(ra) # 80003722 <ilock>
    stati(f->ip, &st);
    800046bc:	fb840593          	addi	a1,s0,-72
    800046c0:	6c88                	ld	a0,24(s1)
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	2ea080e7          	jalr	746(ra) # 800039ac <stati>
    iunlock(f->ip);
    800046ca:	6c88                	ld	a0,24(s1)
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	118080e7          	jalr	280(ra) # 800037e4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046d4:	46e1                	li	a3,24
    800046d6:	fb840613          	addi	a2,s0,-72
    800046da:	85ce                	mv	a1,s3
    800046dc:	05093503          	ld	a0,80(s2)
    800046e0:	ffffd097          	auipc	ra,0xffffd
    800046e4:	f5e080e7          	jalr	-162(ra) # 8000163e <copyout>
    800046e8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046ec:	60a6                	ld	ra,72(sp)
    800046ee:	6406                	ld	s0,64(sp)
    800046f0:	74e2                	ld	s1,56(sp)
    800046f2:	7942                	ld	s2,48(sp)
    800046f4:	79a2                	ld	s3,40(sp)
    800046f6:	6161                	addi	sp,sp,80
    800046f8:	8082                	ret
  return -1;
    800046fa:	557d                	li	a0,-1
    800046fc:	bfc5                	j	800046ec <filestat+0x60>

00000000800046fe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046fe:	7179                	addi	sp,sp,-48
    80004700:	f406                	sd	ra,40(sp)
    80004702:	f022                	sd	s0,32(sp)
    80004704:	ec26                	sd	s1,24(sp)
    80004706:	e84a                	sd	s2,16(sp)
    80004708:	e44e                	sd	s3,8(sp)
    8000470a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000470c:	00854783          	lbu	a5,8(a0)
    80004710:	c3d5                	beqz	a5,800047b4 <fileread+0xb6>
    80004712:	84aa                	mv	s1,a0
    80004714:	89ae                	mv	s3,a1
    80004716:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004718:	411c                	lw	a5,0(a0)
    8000471a:	4705                	li	a4,1
    8000471c:	04e78963          	beq	a5,a4,8000476e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004720:	470d                	li	a4,3
    80004722:	04e78d63          	beq	a5,a4,8000477c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004726:	4709                	li	a4,2
    80004728:	06e79e63          	bne	a5,a4,800047a4 <fileread+0xa6>
    ilock(f->ip);
    8000472c:	6d08                	ld	a0,24(a0)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	ff4080e7          	jalr	-12(ra) # 80003722 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004736:	874a                	mv	a4,s2
    80004738:	5094                	lw	a3,32(s1)
    8000473a:	864e                	mv	a2,s3
    8000473c:	4585                	li	a1,1
    8000473e:	6c88                	ld	a0,24(s1)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	296080e7          	jalr	662(ra) # 800039d6 <readi>
    80004748:	892a                	mv	s2,a0
    8000474a:	00a05563          	blez	a0,80004754 <fileread+0x56>
      f->off += r;
    8000474e:	509c                	lw	a5,32(s1)
    80004750:	9fa9                	addw	a5,a5,a0
    80004752:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004754:	6c88                	ld	a0,24(s1)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	08e080e7          	jalr	142(ra) # 800037e4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000475e:	854a                	mv	a0,s2
    80004760:	70a2                	ld	ra,40(sp)
    80004762:	7402                	ld	s0,32(sp)
    80004764:	64e2                	ld	s1,24(sp)
    80004766:	6942                	ld	s2,16(sp)
    80004768:	69a2                	ld	s3,8(sp)
    8000476a:	6145                	addi	sp,sp,48
    8000476c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000476e:	6908                	ld	a0,16(a0)
    80004770:	00000097          	auipc	ra,0x0
    80004774:	3c0080e7          	jalr	960(ra) # 80004b30 <piperead>
    80004778:	892a                	mv	s2,a0
    8000477a:	b7d5                	j	8000475e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000477c:	02451783          	lh	a5,36(a0)
    80004780:	03079693          	slli	a3,a5,0x30
    80004784:	92c1                	srli	a3,a3,0x30
    80004786:	4725                	li	a4,9
    80004788:	02d76863          	bltu	a4,a3,800047b8 <fileread+0xba>
    8000478c:	0792                	slli	a5,a5,0x4
    8000478e:	0001d717          	auipc	a4,0x1d
    80004792:	b8a70713          	addi	a4,a4,-1142 # 80021318 <devsw>
    80004796:	97ba                	add	a5,a5,a4
    80004798:	639c                	ld	a5,0(a5)
    8000479a:	c38d                	beqz	a5,800047bc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000479c:	4505                	li	a0,1
    8000479e:	9782                	jalr	a5
    800047a0:	892a                	mv	s2,a0
    800047a2:	bf75                	j	8000475e <fileread+0x60>
    panic("fileread");
    800047a4:	00004517          	auipc	a0,0x4
    800047a8:	12450513          	addi	a0,a0,292 # 800088c8 <syscalls_str+0x260>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	d7e080e7          	jalr	-642(ra) # 8000052a <panic>
    return -1;
    800047b4:	597d                	li	s2,-1
    800047b6:	b765                	j	8000475e <fileread+0x60>
      return -1;
    800047b8:	597d                	li	s2,-1
    800047ba:	b755                	j	8000475e <fileread+0x60>
    800047bc:	597d                	li	s2,-1
    800047be:	b745                	j	8000475e <fileread+0x60>

00000000800047c0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047c0:	715d                	addi	sp,sp,-80
    800047c2:	e486                	sd	ra,72(sp)
    800047c4:	e0a2                	sd	s0,64(sp)
    800047c6:	fc26                	sd	s1,56(sp)
    800047c8:	f84a                	sd	s2,48(sp)
    800047ca:	f44e                	sd	s3,40(sp)
    800047cc:	f052                	sd	s4,32(sp)
    800047ce:	ec56                	sd	s5,24(sp)
    800047d0:	e85a                	sd	s6,16(sp)
    800047d2:	e45e                	sd	s7,8(sp)
    800047d4:	e062                	sd	s8,0(sp)
    800047d6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047d8:	00954783          	lbu	a5,9(a0)
    800047dc:	10078663          	beqz	a5,800048e8 <filewrite+0x128>
    800047e0:	892a                	mv	s2,a0
    800047e2:	8aae                	mv	s5,a1
    800047e4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047e6:	411c                	lw	a5,0(a0)
    800047e8:	4705                	li	a4,1
    800047ea:	02e78263          	beq	a5,a4,8000480e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ee:	470d                	li	a4,3
    800047f0:	02e78663          	beq	a5,a4,8000481c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047f4:	4709                	li	a4,2
    800047f6:	0ee79163          	bne	a5,a4,800048d8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047fa:	0ac05d63          	blez	a2,800048b4 <filewrite+0xf4>
    int i = 0;
    800047fe:	4981                	li	s3,0
    80004800:	6b05                	lui	s6,0x1
    80004802:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004806:	6b85                	lui	s7,0x1
    80004808:	c00b8b9b          	addiw	s7,s7,-1024
    8000480c:	a861                	j	800048a4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000480e:	6908                	ld	a0,16(a0)
    80004810:	00000097          	auipc	ra,0x0
    80004814:	22e080e7          	jalr	558(ra) # 80004a3e <pipewrite>
    80004818:	8a2a                	mv	s4,a0
    8000481a:	a045                	j	800048ba <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000481c:	02451783          	lh	a5,36(a0)
    80004820:	03079693          	slli	a3,a5,0x30
    80004824:	92c1                	srli	a3,a3,0x30
    80004826:	4725                	li	a4,9
    80004828:	0cd76263          	bltu	a4,a3,800048ec <filewrite+0x12c>
    8000482c:	0792                	slli	a5,a5,0x4
    8000482e:	0001d717          	auipc	a4,0x1d
    80004832:	aea70713          	addi	a4,a4,-1302 # 80021318 <devsw>
    80004836:	97ba                	add	a5,a5,a4
    80004838:	679c                	ld	a5,8(a5)
    8000483a:	cbdd                	beqz	a5,800048f0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000483c:	4505                	li	a0,1
    8000483e:	9782                	jalr	a5
    80004840:	8a2a                	mv	s4,a0
    80004842:	a8a5                	j	800048ba <filewrite+0xfa>
    80004844:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	8b0080e7          	jalr	-1872(ra) # 800040f8 <begin_op>
      ilock(f->ip);
    80004850:	01893503          	ld	a0,24(s2)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	ece080e7          	jalr	-306(ra) # 80003722 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000485c:	8762                	mv	a4,s8
    8000485e:	02092683          	lw	a3,32(s2)
    80004862:	01598633          	add	a2,s3,s5
    80004866:	4585                	li	a1,1
    80004868:	01893503          	ld	a0,24(s2)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	262080e7          	jalr	610(ra) # 80003ace <writei>
    80004874:	84aa                	mv	s1,a0
    80004876:	00a05763          	blez	a0,80004884 <filewrite+0xc4>
        f->off += r;
    8000487a:	02092783          	lw	a5,32(s2)
    8000487e:	9fa9                	addw	a5,a5,a0
    80004880:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004884:	01893503          	ld	a0,24(s2)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	f5c080e7          	jalr	-164(ra) # 800037e4 <iunlock>
      end_op();
    80004890:	00000097          	auipc	ra,0x0
    80004894:	8e8080e7          	jalr	-1816(ra) # 80004178 <end_op>

      if(r != n1){
    80004898:	009c1f63          	bne	s8,s1,800048b6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000489c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048a0:	0149db63          	bge	s3,s4,800048b6 <filewrite+0xf6>
      int n1 = n - i;
    800048a4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048a8:	84be                	mv	s1,a5
    800048aa:	2781                	sext.w	a5,a5
    800048ac:	f8fb5ce3          	bge	s6,a5,80004844 <filewrite+0x84>
    800048b0:	84de                	mv	s1,s7
    800048b2:	bf49                	j	80004844 <filewrite+0x84>
    int i = 0;
    800048b4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048b6:	013a1f63          	bne	s4,s3,800048d4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ba:	8552                	mv	a0,s4
    800048bc:	60a6                	ld	ra,72(sp)
    800048be:	6406                	ld	s0,64(sp)
    800048c0:	74e2                	ld	s1,56(sp)
    800048c2:	7942                	ld	s2,48(sp)
    800048c4:	79a2                	ld	s3,40(sp)
    800048c6:	7a02                	ld	s4,32(sp)
    800048c8:	6ae2                	ld	s5,24(sp)
    800048ca:	6b42                	ld	s6,16(sp)
    800048cc:	6ba2                	ld	s7,8(sp)
    800048ce:	6c02                	ld	s8,0(sp)
    800048d0:	6161                	addi	sp,sp,80
    800048d2:	8082                	ret
    ret = (i == n ? n : -1);
    800048d4:	5a7d                	li	s4,-1
    800048d6:	b7d5                	j	800048ba <filewrite+0xfa>
    panic("filewrite");
    800048d8:	00004517          	auipc	a0,0x4
    800048dc:	00050513          	mv	a0,a0
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	c4a080e7          	jalr	-950(ra) # 8000052a <panic>
    return -1;
    800048e8:	5a7d                	li	s4,-1
    800048ea:	bfc1                	j	800048ba <filewrite+0xfa>
      return -1;
    800048ec:	5a7d                	li	s4,-1
    800048ee:	b7f1                	j	800048ba <filewrite+0xfa>
    800048f0:	5a7d                	li	s4,-1
    800048f2:	b7e1                	j	800048ba <filewrite+0xfa>

00000000800048f4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048f4:	7179                	addi	sp,sp,-48
    800048f6:	f406                	sd	ra,40(sp)
    800048f8:	f022                	sd	s0,32(sp)
    800048fa:	ec26                	sd	s1,24(sp)
    800048fc:	e84a                	sd	s2,16(sp)
    800048fe:	e44e                	sd	s3,8(sp)
    80004900:	e052                	sd	s4,0(sp)
    80004902:	1800                	addi	s0,sp,48
    80004904:	84aa                	mv	s1,a0
    80004906:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004908:	0005b023          	sd	zero,0(a1)
    8000490c:	00053023          	sd	zero,0(a0) # 800088d8 <syscalls_str+0x270>
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004910:	00000097          	auipc	ra,0x0
    80004914:	bf8080e7          	jalr	-1032(ra) # 80004508 <filealloc>
    80004918:	e088                	sd	a0,0(s1)
    8000491a:	c551                	beqz	a0,800049a6 <pipealloc+0xb2>
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	bec080e7          	jalr	-1044(ra) # 80004508 <filealloc>
    80004924:	00aa3023          	sd	a0,0(s4)
    80004928:	c92d                	beqz	a0,8000499a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	1a8080e7          	jalr	424(ra) # 80000ad2 <kalloc>
    80004932:	892a                	mv	s2,a0
    80004934:	c125                	beqz	a0,80004994 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004936:	4985                	li	s3,1
    80004938:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000493c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004940:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004944:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004948:	00004597          	auipc	a1,0x4
    8000494c:	fa058593          	addi	a1,a1,-96 # 800088e8 <syscalls_str+0x280>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	1e2080e7          	jalr	482(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004958:	609c                	ld	a5,0(s1)
    8000495a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000495e:	609c                	ld	a5,0(s1)
    80004960:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004964:	609c                	ld	a5,0(s1)
    80004966:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000496a:	609c                	ld	a5,0(s1)
    8000496c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004970:	000a3783          	ld	a5,0(s4)
    80004974:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004978:	000a3783          	ld	a5,0(s4)
    8000497c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004980:	000a3783          	ld	a5,0(s4)
    80004984:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004988:	000a3783          	ld	a5,0(s4)
    8000498c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004990:	4501                	li	a0,0
    80004992:	a025                	j	800049ba <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004994:	6088                	ld	a0,0(s1)
    80004996:	e501                	bnez	a0,8000499e <pipealloc+0xaa>
    80004998:	a039                	j	800049a6 <pipealloc+0xb2>
    8000499a:	6088                	ld	a0,0(s1)
    8000499c:	c51d                	beqz	a0,800049ca <pipealloc+0xd6>
    fileclose(*f0);
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	c26080e7          	jalr	-986(ra) # 800045c4 <fileclose>
  if(*f1)
    800049a6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049aa:	557d                	li	a0,-1
  if(*f1)
    800049ac:	c799                	beqz	a5,800049ba <pipealloc+0xc6>
    fileclose(*f1);
    800049ae:	853e                	mv	a0,a5
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	c14080e7          	jalr	-1004(ra) # 800045c4 <fileclose>
  return -1;
    800049b8:	557d                	li	a0,-1
}
    800049ba:	70a2                	ld	ra,40(sp)
    800049bc:	7402                	ld	s0,32(sp)
    800049be:	64e2                	ld	s1,24(sp)
    800049c0:	6942                	ld	s2,16(sp)
    800049c2:	69a2                	ld	s3,8(sp)
    800049c4:	6a02                	ld	s4,0(sp)
    800049c6:	6145                	addi	sp,sp,48
    800049c8:	8082                	ret
  return -1;
    800049ca:	557d                	li	a0,-1
    800049cc:	b7fd                	j	800049ba <pipealloc+0xc6>

00000000800049ce <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049ce:	1101                	addi	sp,sp,-32
    800049d0:	ec06                	sd	ra,24(sp)
    800049d2:	e822                	sd	s0,16(sp)
    800049d4:	e426                	sd	s1,8(sp)
    800049d6:	e04a                	sd	s2,0(sp)
    800049d8:	1000                	addi	s0,sp,32
    800049da:	84aa                	mv	s1,a0
    800049dc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	1e4080e7          	jalr	484(ra) # 80000bc2 <acquire>
  if(writable){
    800049e6:	02090d63          	beqz	s2,80004a20 <pipeclose+0x52>
    pi->writeopen = 0;
    800049ea:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049ee:	21848513          	addi	a0,s1,536
    800049f2:	ffffd097          	auipc	ra,0xffffd
    800049f6:	7f8080e7          	jalr	2040(ra) # 800021ea <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049fa:	2204b783          	ld	a5,544(s1)
    800049fe:	eb95                	bnez	a5,80004a32 <pipeclose+0x64>
    release(&pi->lock);
    80004a00:	8526                	mv	a0,s1
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	274080e7          	jalr	628(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	fca080e7          	jalr	-54(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004a14:	60e2                	ld	ra,24(sp)
    80004a16:	6442                	ld	s0,16(sp)
    80004a18:	64a2                	ld	s1,8(sp)
    80004a1a:	6902                	ld	s2,0(sp)
    80004a1c:	6105                	addi	sp,sp,32
    80004a1e:	8082                	ret
    pi->readopen = 0;
    80004a20:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a24:	21c48513          	addi	a0,s1,540
    80004a28:	ffffd097          	auipc	ra,0xffffd
    80004a2c:	7c2080e7          	jalr	1986(ra) # 800021ea <wakeup>
    80004a30:	b7e9                	j	800049fa <pipeclose+0x2c>
    release(&pi->lock);
    80004a32:	8526                	mv	a0,s1
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	242080e7          	jalr	578(ra) # 80000c76 <release>
}
    80004a3c:	bfe1                	j	80004a14 <pipeclose+0x46>

0000000080004a3e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a3e:	711d                	addi	sp,sp,-96
    80004a40:	ec86                	sd	ra,88(sp)
    80004a42:	e8a2                	sd	s0,80(sp)
    80004a44:	e4a6                	sd	s1,72(sp)
    80004a46:	e0ca                	sd	s2,64(sp)
    80004a48:	fc4e                	sd	s3,56(sp)
    80004a4a:	f852                	sd	s4,48(sp)
    80004a4c:	f456                	sd	s5,40(sp)
    80004a4e:	f05a                	sd	s6,32(sp)
    80004a50:	ec5e                	sd	s7,24(sp)
    80004a52:	e862                	sd	s8,16(sp)
    80004a54:	1080                	addi	s0,sp,96
    80004a56:	84aa                	mv	s1,a0
    80004a58:	8aae                	mv	s5,a1
    80004a5a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a5c:	ffffd097          	auipc	ra,0xffffd
    80004a60:	f36080e7          	jalr	-202(ra) # 80001992 <myproc>
    80004a64:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	15a080e7          	jalr	346(ra) # 80000bc2 <acquire>
  while(i < n){
    80004a70:	0b405363          	blez	s4,80004b16 <pipewrite+0xd8>
  int i = 0;
    80004a74:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a76:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a78:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a7c:	21c48b93          	addi	s7,s1,540
    80004a80:	a089                	j	80004ac2 <pipewrite+0x84>
      release(&pi->lock);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	1f2080e7          	jalr	498(ra) # 80000c76 <release>
      return -1;
    80004a8c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a8e:	854a                	mv	a0,s2
    80004a90:	60e6                	ld	ra,88(sp)
    80004a92:	6446                	ld	s0,80(sp)
    80004a94:	64a6                	ld	s1,72(sp)
    80004a96:	6906                	ld	s2,64(sp)
    80004a98:	79e2                	ld	s3,56(sp)
    80004a9a:	7a42                	ld	s4,48(sp)
    80004a9c:	7aa2                	ld	s5,40(sp)
    80004a9e:	7b02                	ld	s6,32(sp)
    80004aa0:	6be2                	ld	s7,24(sp)
    80004aa2:	6c42                	ld	s8,16(sp)
    80004aa4:	6125                	addi	sp,sp,96
    80004aa6:	8082                	ret
      wakeup(&pi->nread);
    80004aa8:	8562                	mv	a0,s8
    80004aaa:	ffffd097          	auipc	ra,0xffffd
    80004aae:	740080e7          	jalr	1856(ra) # 800021ea <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ab2:	85a6                	mv	a1,s1
    80004ab4:	855e                	mv	a0,s7
    80004ab6:	ffffd097          	auipc	ra,0xffffd
    80004aba:	5a8080e7          	jalr	1448(ra) # 8000205e <sleep>
  while(i < n){
    80004abe:	05495d63          	bge	s2,s4,80004b18 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004ac2:	2204a783          	lw	a5,544(s1)
    80004ac6:	dfd5                	beqz	a5,80004a82 <pipewrite+0x44>
    80004ac8:	0289a783          	lw	a5,40(s3)
    80004acc:	fbdd                	bnez	a5,80004a82 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ace:	2184a783          	lw	a5,536(s1)
    80004ad2:	21c4a703          	lw	a4,540(s1)
    80004ad6:	2007879b          	addiw	a5,a5,512
    80004ada:	fcf707e3          	beq	a4,a5,80004aa8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ade:	4685                	li	a3,1
    80004ae0:	01590633          	add	a2,s2,s5
    80004ae4:	faf40593          	addi	a1,s0,-81
    80004ae8:	0509b503          	ld	a0,80(s3)
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	bde080e7          	jalr	-1058(ra) # 800016ca <copyin>
    80004af4:	03650263          	beq	a0,s6,80004b18 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004af8:	21c4a783          	lw	a5,540(s1)
    80004afc:	0017871b          	addiw	a4,a5,1
    80004b00:	20e4ae23          	sw	a4,540(s1)
    80004b04:	1ff7f793          	andi	a5,a5,511
    80004b08:	97a6                	add	a5,a5,s1
    80004b0a:	faf44703          	lbu	a4,-81(s0)
    80004b0e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b12:	2905                	addiw	s2,s2,1
    80004b14:	b76d                	j	80004abe <pipewrite+0x80>
  int i = 0;
    80004b16:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b18:	21848513          	addi	a0,s1,536
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	6ce080e7          	jalr	1742(ra) # 800021ea <wakeup>
  release(&pi->lock);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	150080e7          	jalr	336(ra) # 80000c76 <release>
  return i;
    80004b2e:	b785                	j	80004a8e <pipewrite+0x50>

0000000080004b30 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b30:	715d                	addi	sp,sp,-80
    80004b32:	e486                	sd	ra,72(sp)
    80004b34:	e0a2                	sd	s0,64(sp)
    80004b36:	fc26                	sd	s1,56(sp)
    80004b38:	f84a                	sd	s2,48(sp)
    80004b3a:	f44e                	sd	s3,40(sp)
    80004b3c:	f052                	sd	s4,32(sp)
    80004b3e:	ec56                	sd	s5,24(sp)
    80004b40:	e85a                	sd	s6,16(sp)
    80004b42:	0880                	addi	s0,sp,80
    80004b44:	84aa                	mv	s1,a0
    80004b46:	892e                	mv	s2,a1
    80004b48:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	e48080e7          	jalr	-440(ra) # 80001992 <myproc>
    80004b52:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b54:	8526                	mv	a0,s1
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	06c080e7          	jalr	108(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5e:	2184a703          	lw	a4,536(s1)
    80004b62:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b66:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b6a:	02f71463          	bne	a4,a5,80004b92 <piperead+0x62>
    80004b6e:	2244a783          	lw	a5,548(s1)
    80004b72:	c385                	beqz	a5,80004b92 <piperead+0x62>
    if(pr->killed){
    80004b74:	028a2783          	lw	a5,40(s4)
    80004b78:	ebc1                	bnez	a5,80004c08 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b7a:	85a6                	mv	a1,s1
    80004b7c:	854e                	mv	a0,s3
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	4e0080e7          	jalr	1248(ra) # 8000205e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b86:	2184a703          	lw	a4,536(s1)
    80004b8a:	21c4a783          	lw	a5,540(s1)
    80004b8e:	fef700e3          	beq	a4,a5,80004b6e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b92:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b94:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b96:	05505363          	blez	s5,80004bdc <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004b9a:	2184a783          	lw	a5,536(s1)
    80004b9e:	21c4a703          	lw	a4,540(s1)
    80004ba2:	02f70d63          	beq	a4,a5,80004bdc <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ba6:	0017871b          	addiw	a4,a5,1
    80004baa:	20e4ac23          	sw	a4,536(s1)
    80004bae:	1ff7f793          	andi	a5,a5,511
    80004bb2:	97a6                	add	a5,a5,s1
    80004bb4:	0187c783          	lbu	a5,24(a5)
    80004bb8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bbc:	4685                	li	a3,1
    80004bbe:	fbf40613          	addi	a2,s0,-65
    80004bc2:	85ca                	mv	a1,s2
    80004bc4:	050a3503          	ld	a0,80(s4)
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	a76080e7          	jalr	-1418(ra) # 8000163e <copyout>
    80004bd0:	01650663          	beq	a0,s6,80004bdc <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bd4:	2985                	addiw	s3,s3,1
    80004bd6:	0905                	addi	s2,s2,1
    80004bd8:	fd3a91e3          	bne	s5,s3,80004b9a <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bdc:	21c48513          	addi	a0,s1,540
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	60a080e7          	jalr	1546(ra) # 800021ea <wakeup>
  release(&pi->lock);
    80004be8:	8526                	mv	a0,s1
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	08c080e7          	jalr	140(ra) # 80000c76 <release>
  return i;
}
    80004bf2:	854e                	mv	a0,s3
    80004bf4:	60a6                	ld	ra,72(sp)
    80004bf6:	6406                	ld	s0,64(sp)
    80004bf8:	74e2                	ld	s1,56(sp)
    80004bfa:	7942                	ld	s2,48(sp)
    80004bfc:	79a2                	ld	s3,40(sp)
    80004bfe:	7a02                	ld	s4,32(sp)
    80004c00:	6ae2                	ld	s5,24(sp)
    80004c02:	6b42                	ld	s6,16(sp)
    80004c04:	6161                	addi	sp,sp,80
    80004c06:	8082                	ret
      release(&pi->lock);
    80004c08:	8526                	mv	a0,s1
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	06c080e7          	jalr	108(ra) # 80000c76 <release>
      return -1;
    80004c12:	59fd                	li	s3,-1
    80004c14:	bff9                	j	80004bf2 <piperead+0xc2>

0000000080004c16 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c16:	de010113          	addi	sp,sp,-544
    80004c1a:	20113c23          	sd	ra,536(sp)
    80004c1e:	20813823          	sd	s0,528(sp)
    80004c22:	20913423          	sd	s1,520(sp)
    80004c26:	21213023          	sd	s2,512(sp)
    80004c2a:	ffce                	sd	s3,504(sp)
    80004c2c:	fbd2                	sd	s4,496(sp)
    80004c2e:	f7d6                	sd	s5,488(sp)
    80004c30:	f3da                	sd	s6,480(sp)
    80004c32:	efde                	sd	s7,472(sp)
    80004c34:	ebe2                	sd	s8,464(sp)
    80004c36:	e7e6                	sd	s9,456(sp)
    80004c38:	e3ea                	sd	s10,448(sp)
    80004c3a:	ff6e                	sd	s11,440(sp)
    80004c3c:	1400                	addi	s0,sp,544
    80004c3e:	892a                	mv	s2,a0
    80004c40:	dea43423          	sd	a0,-536(s0)
    80004c44:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c48:	ffffd097          	auipc	ra,0xffffd
    80004c4c:	d4a080e7          	jalr	-694(ra) # 80001992 <myproc>
    80004c50:	84aa                	mv	s1,a0

  begin_op();
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	4a6080e7          	jalr	1190(ra) # 800040f8 <begin_op>

  if((ip = namei(path)) == 0){
    80004c5a:	854a                	mv	a0,s2
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	27c080e7          	jalr	636(ra) # 80003ed8 <namei>
    80004c64:	c93d                	beqz	a0,80004cda <exec+0xc4>
    80004c66:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	aba080e7          	jalr	-1350(ra) # 80003722 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c70:	04000713          	li	a4,64
    80004c74:	4681                	li	a3,0
    80004c76:	e4840613          	addi	a2,s0,-440
    80004c7a:	4581                	li	a1,0
    80004c7c:	8556                	mv	a0,s5
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	d58080e7          	jalr	-680(ra) # 800039d6 <readi>
    80004c86:	04000793          	li	a5,64
    80004c8a:	00f51a63          	bne	a0,a5,80004c9e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c8e:	e4842703          	lw	a4,-440(s0)
    80004c92:	464c47b7          	lui	a5,0x464c4
    80004c96:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c9a:	04f70663          	beq	a4,a5,80004ce6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c9e:	8556                	mv	a0,s5
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	ce4080e7          	jalr	-796(ra) # 80003984 <iunlockput>
    end_op();
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	4d0080e7          	jalr	1232(ra) # 80004178 <end_op>
  }
  return -1;
    80004cb0:	557d                	li	a0,-1
}
    80004cb2:	21813083          	ld	ra,536(sp)
    80004cb6:	21013403          	ld	s0,528(sp)
    80004cba:	20813483          	ld	s1,520(sp)
    80004cbe:	20013903          	ld	s2,512(sp)
    80004cc2:	79fe                	ld	s3,504(sp)
    80004cc4:	7a5e                	ld	s4,496(sp)
    80004cc6:	7abe                	ld	s5,488(sp)
    80004cc8:	7b1e                	ld	s6,480(sp)
    80004cca:	6bfe                	ld	s7,472(sp)
    80004ccc:	6c5e                	ld	s8,464(sp)
    80004cce:	6cbe                	ld	s9,456(sp)
    80004cd0:	6d1e                	ld	s10,448(sp)
    80004cd2:	7dfa                	ld	s11,440(sp)
    80004cd4:	22010113          	addi	sp,sp,544
    80004cd8:	8082                	ret
    end_op();
    80004cda:	fffff097          	auipc	ra,0xfffff
    80004cde:	49e080e7          	jalr	1182(ra) # 80004178 <end_op>
    return -1;
    80004ce2:	557d                	li	a0,-1
    80004ce4:	b7f9                	j	80004cb2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ce6:	8526                	mv	a0,s1
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	d6e080e7          	jalr	-658(ra) # 80001a56 <proc_pagetable>
    80004cf0:	8b2a                	mv	s6,a0
    80004cf2:	d555                	beqz	a0,80004c9e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cf4:	e6842783          	lw	a5,-408(s0)
    80004cf8:	e8045703          	lhu	a4,-384(s0)
    80004cfc:	c735                	beqz	a4,80004d68 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cfe:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d00:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d04:	6a05                	lui	s4,0x1
    80004d06:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d0a:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004d0e:	6d85                	lui	s11,0x1
    80004d10:	7d7d                	lui	s10,0xfffff
    80004d12:	ac1d                	j	80004f48 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d14:	00004517          	auipc	a0,0x4
    80004d18:	bdc50513          	addi	a0,a0,-1060 # 800088f0 <syscalls_str+0x288>
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	80e080e7          	jalr	-2034(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d24:	874a                	mv	a4,s2
    80004d26:	009c86bb          	addw	a3,s9,s1
    80004d2a:	4581                	li	a1,0
    80004d2c:	8556                	mv	a0,s5
    80004d2e:	fffff097          	auipc	ra,0xfffff
    80004d32:	ca8080e7          	jalr	-856(ra) # 800039d6 <readi>
    80004d36:	2501                	sext.w	a0,a0
    80004d38:	1aa91863          	bne	s2,a0,80004ee8 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d3c:	009d84bb          	addw	s1,s11,s1
    80004d40:	013d09bb          	addw	s3,s10,s3
    80004d44:	1f74f263          	bgeu	s1,s7,80004f28 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d48:	02049593          	slli	a1,s1,0x20
    80004d4c:	9181                	srli	a1,a1,0x20
    80004d4e:	95e2                	add	a1,a1,s8
    80004d50:	855a                	mv	a0,s6
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	2fa080e7          	jalr	762(ra) # 8000104c <walkaddr>
    80004d5a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d5c:	dd45                	beqz	a0,80004d14 <exec+0xfe>
      n = PGSIZE;
    80004d5e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d60:	fd49f2e3          	bgeu	s3,s4,80004d24 <exec+0x10e>
      n = sz - i;
    80004d64:	894e                	mv	s2,s3
    80004d66:	bf7d                	j	80004d24 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d68:	4481                	li	s1,0
  iunlockput(ip);
    80004d6a:	8556                	mv	a0,s5
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	c18080e7          	jalr	-1000(ra) # 80003984 <iunlockput>
  end_op();
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	404080e7          	jalr	1028(ra) # 80004178 <end_op>
  p = myproc();
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	c16080e7          	jalr	-1002(ra) # 80001992 <myproc>
    80004d84:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d86:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d8a:	6785                	lui	a5,0x1
    80004d8c:	17fd                	addi	a5,a5,-1
    80004d8e:	94be                	add	s1,s1,a5
    80004d90:	77fd                	lui	a5,0xfffff
    80004d92:	8fe5                	and	a5,a5,s1
    80004d94:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d98:	6609                	lui	a2,0x2
    80004d9a:	963e                	add	a2,a2,a5
    80004d9c:	85be                	mv	a1,a5
    80004d9e:	855a                	mv	a0,s6
    80004da0:	ffffc097          	auipc	ra,0xffffc
    80004da4:	64e080e7          	jalr	1614(ra) # 800013ee <uvmalloc>
    80004da8:	8c2a                	mv	s8,a0
  ip = 0;
    80004daa:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dac:	12050e63          	beqz	a0,80004ee8 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004db0:	75f9                	lui	a1,0xffffe
    80004db2:	95aa                	add	a1,a1,a0
    80004db4:	855a                	mv	a0,s6
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	856080e7          	jalr	-1962(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004dbe:	7afd                	lui	s5,0xfffff
    80004dc0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dc2:	df043783          	ld	a5,-528(s0)
    80004dc6:	6388                	ld	a0,0(a5)
    80004dc8:	c925                	beqz	a0,80004e38 <exec+0x222>
    80004dca:	e8840993          	addi	s3,s0,-376
    80004dce:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004dd2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dd4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	06c080e7          	jalr	108(ra) # 80000e42 <strlen>
    80004dde:	0015079b          	addiw	a5,a0,1
    80004de2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004de6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dea:	13596363          	bltu	s2,s5,80004f10 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dee:	df043d83          	ld	s11,-528(s0)
    80004df2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004df6:	8552                	mv	a0,s4
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	04a080e7          	jalr	74(ra) # 80000e42 <strlen>
    80004e00:	0015069b          	addiw	a3,a0,1
    80004e04:	8652                	mv	a2,s4
    80004e06:	85ca                	mv	a1,s2
    80004e08:	855a                	mv	a0,s6
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	834080e7          	jalr	-1996(ra) # 8000163e <copyout>
    80004e12:	10054363          	bltz	a0,80004f18 <exec+0x302>
    ustack[argc] = sp;
    80004e16:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e1a:	0485                	addi	s1,s1,1
    80004e1c:	008d8793          	addi	a5,s11,8
    80004e20:	def43823          	sd	a5,-528(s0)
    80004e24:	008db503          	ld	a0,8(s11)
    80004e28:	c911                	beqz	a0,80004e3c <exec+0x226>
    if(argc >= MAXARG)
    80004e2a:	09a1                	addi	s3,s3,8
    80004e2c:	fb3c95e3          	bne	s9,s3,80004dd6 <exec+0x1c0>
  sz = sz1;
    80004e30:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e34:	4a81                	li	s5,0
    80004e36:	a84d                	j	80004ee8 <exec+0x2d2>
  sp = sz;
    80004e38:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e3a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e3c:	00349793          	slli	a5,s1,0x3
    80004e40:	f9040713          	addi	a4,s0,-112
    80004e44:	97ba                	add	a5,a5,a4
    80004e46:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004e4a:	00148693          	addi	a3,s1,1
    80004e4e:	068e                	slli	a3,a3,0x3
    80004e50:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e54:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e58:	01597663          	bgeu	s2,s5,80004e64 <exec+0x24e>
  sz = sz1;
    80004e5c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e60:	4a81                	li	s5,0
    80004e62:	a059                	j	80004ee8 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e64:	e8840613          	addi	a2,s0,-376
    80004e68:	85ca                	mv	a1,s2
    80004e6a:	855a                	mv	a0,s6
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	7d2080e7          	jalr	2002(ra) # 8000163e <copyout>
    80004e74:	0a054663          	bltz	a0,80004f20 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e78:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e7c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e80:	de843783          	ld	a5,-536(s0)
    80004e84:	0007c703          	lbu	a4,0(a5)
    80004e88:	cf11                	beqz	a4,80004ea4 <exec+0x28e>
    80004e8a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e8c:	02f00693          	li	a3,47
    80004e90:	a039                	j	80004e9e <exec+0x288>
      last = s+1;
    80004e92:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e96:	0785                	addi	a5,a5,1
    80004e98:	fff7c703          	lbu	a4,-1(a5)
    80004e9c:	c701                	beqz	a4,80004ea4 <exec+0x28e>
    if(*s == '/')
    80004e9e:	fed71ce3          	bne	a4,a3,80004e96 <exec+0x280>
    80004ea2:	bfc5                	j	80004e92 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ea4:	4641                	li	a2,16
    80004ea6:	de843583          	ld	a1,-536(s0)
    80004eaa:	158b8513          	addi	a0,s7,344
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	f62080e7          	jalr	-158(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004eb6:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004eba:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ebe:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ec2:	058bb783          	ld	a5,88(s7)
    80004ec6:	e6043703          	ld	a4,-416(s0)
    80004eca:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ecc:	058bb783          	ld	a5,88(s7)
    80004ed0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ed4:	85ea                	mv	a1,s10
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	c1c080e7          	jalr	-996(ra) # 80001af2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ede:	0004851b          	sext.w	a0,s1
    80004ee2:	bbc1                	j	80004cb2 <exec+0x9c>
    80004ee4:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ee8:	df843583          	ld	a1,-520(s0)
    80004eec:	855a                	mv	a0,s6
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	c04080e7          	jalr	-1020(ra) # 80001af2 <proc_freepagetable>
  if(ip){
    80004ef6:	da0a94e3          	bnez	s5,80004c9e <exec+0x88>
  return -1;
    80004efa:	557d                	li	a0,-1
    80004efc:	bb5d                	j	80004cb2 <exec+0x9c>
    80004efe:	de943c23          	sd	s1,-520(s0)
    80004f02:	b7dd                	j	80004ee8 <exec+0x2d2>
    80004f04:	de943c23          	sd	s1,-520(s0)
    80004f08:	b7c5                	j	80004ee8 <exec+0x2d2>
    80004f0a:	de943c23          	sd	s1,-520(s0)
    80004f0e:	bfe9                	j	80004ee8 <exec+0x2d2>
  sz = sz1;
    80004f10:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f14:	4a81                	li	s5,0
    80004f16:	bfc9                	j	80004ee8 <exec+0x2d2>
  sz = sz1;
    80004f18:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f1c:	4a81                	li	s5,0
    80004f1e:	b7e9                	j	80004ee8 <exec+0x2d2>
  sz = sz1;
    80004f20:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f24:	4a81                	li	s5,0
    80004f26:	b7c9                	j	80004ee8 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f28:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f2c:	e0843783          	ld	a5,-504(s0)
    80004f30:	0017869b          	addiw	a3,a5,1
    80004f34:	e0d43423          	sd	a3,-504(s0)
    80004f38:	e0043783          	ld	a5,-512(s0)
    80004f3c:	0387879b          	addiw	a5,a5,56
    80004f40:	e8045703          	lhu	a4,-384(s0)
    80004f44:	e2e6d3e3          	bge	a3,a4,80004d6a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f48:	2781                	sext.w	a5,a5
    80004f4a:	e0f43023          	sd	a5,-512(s0)
    80004f4e:	03800713          	li	a4,56
    80004f52:	86be                	mv	a3,a5
    80004f54:	e1040613          	addi	a2,s0,-496
    80004f58:	4581                	li	a1,0
    80004f5a:	8556                	mv	a0,s5
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	a7a080e7          	jalr	-1414(ra) # 800039d6 <readi>
    80004f64:	03800793          	li	a5,56
    80004f68:	f6f51ee3          	bne	a0,a5,80004ee4 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f6c:	e1042783          	lw	a5,-496(s0)
    80004f70:	4705                	li	a4,1
    80004f72:	fae79de3          	bne	a5,a4,80004f2c <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f76:	e3843603          	ld	a2,-456(s0)
    80004f7a:	e3043783          	ld	a5,-464(s0)
    80004f7e:	f8f660e3          	bltu	a2,a5,80004efe <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f82:	e2043783          	ld	a5,-480(s0)
    80004f86:	963e                	add	a2,a2,a5
    80004f88:	f6f66ee3          	bltu	a2,a5,80004f04 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f8c:	85a6                	mv	a1,s1
    80004f8e:	855a                	mv	a0,s6
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	45e080e7          	jalr	1118(ra) # 800013ee <uvmalloc>
    80004f98:	dea43c23          	sd	a0,-520(s0)
    80004f9c:	d53d                	beqz	a0,80004f0a <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f9e:	e2043c03          	ld	s8,-480(s0)
    80004fa2:	de043783          	ld	a5,-544(s0)
    80004fa6:	00fc77b3          	and	a5,s8,a5
    80004faa:	ff9d                	bnez	a5,80004ee8 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fac:	e1842c83          	lw	s9,-488(s0)
    80004fb0:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fb4:	f60b8ae3          	beqz	s7,80004f28 <exec+0x312>
    80004fb8:	89de                	mv	s3,s7
    80004fba:	4481                	li	s1,0
    80004fbc:	b371                	j	80004d48 <exec+0x132>

0000000080004fbe <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fbe:	7179                	addi	sp,sp,-48
    80004fc0:	f406                	sd	ra,40(sp)
    80004fc2:	f022                	sd	s0,32(sp)
    80004fc4:	ec26                	sd	s1,24(sp)
    80004fc6:	e84a                	sd	s2,16(sp)
    80004fc8:	1800                	addi	s0,sp,48
    80004fca:	892e                	mv	s2,a1
    80004fcc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fce:	fdc40593          	addi	a1,s0,-36
    80004fd2:	ffffe097          	auipc	ra,0xffffe
    80004fd6:	ae8080e7          	jalr	-1304(ra) # 80002aba <argint>
    80004fda:	04054063          	bltz	a0,8000501a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fde:	fdc42703          	lw	a4,-36(s0)
    80004fe2:	47bd                	li	a5,15
    80004fe4:	02e7ed63          	bltu	a5,a4,8000501e <argfd+0x60>
    80004fe8:	ffffd097          	auipc	ra,0xffffd
    80004fec:	9aa080e7          	jalr	-1622(ra) # 80001992 <myproc>
    80004ff0:	fdc42703          	lw	a4,-36(s0)
    80004ff4:	01a70793          	addi	a5,a4,26
    80004ff8:	078e                	slli	a5,a5,0x3
    80004ffa:	953e                	add	a0,a0,a5
    80004ffc:	611c                	ld	a5,0(a0)
    80004ffe:	c395                	beqz	a5,80005022 <argfd+0x64>
    return -1;
  if(pfd)
    80005000:	00090463          	beqz	s2,80005008 <argfd+0x4a>
    *pfd = fd;
    80005004:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005008:	4501                	li	a0,0
  if(pf)
    8000500a:	c091                	beqz	s1,8000500e <argfd+0x50>
    *pf = f;
    8000500c:	e09c                	sd	a5,0(s1)
}
    8000500e:	70a2                	ld	ra,40(sp)
    80005010:	7402                	ld	s0,32(sp)
    80005012:	64e2                	ld	s1,24(sp)
    80005014:	6942                	ld	s2,16(sp)
    80005016:	6145                	addi	sp,sp,48
    80005018:	8082                	ret
    return -1;
    8000501a:	557d                	li	a0,-1
    8000501c:	bfcd                	j	8000500e <argfd+0x50>
    return -1;
    8000501e:	557d                	li	a0,-1
    80005020:	b7fd                	j	8000500e <argfd+0x50>
    80005022:	557d                	li	a0,-1
    80005024:	b7ed                	j	8000500e <argfd+0x50>

0000000080005026 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005026:	1101                	addi	sp,sp,-32
    80005028:	ec06                	sd	ra,24(sp)
    8000502a:	e822                	sd	s0,16(sp)
    8000502c:	e426                	sd	s1,8(sp)
    8000502e:	1000                	addi	s0,sp,32
    80005030:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	960080e7          	jalr	-1696(ra) # 80001992 <myproc>
    8000503a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000503c:	0d050793          	addi	a5,a0,208
    80005040:	4501                	li	a0,0
    80005042:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005044:	6398                	ld	a4,0(a5)
    80005046:	cb19                	beqz	a4,8000505c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005048:	2505                	addiw	a0,a0,1
    8000504a:	07a1                	addi	a5,a5,8
    8000504c:	fed51ce3          	bne	a0,a3,80005044 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005050:	557d                	li	a0,-1
}
    80005052:	60e2                	ld	ra,24(sp)
    80005054:	6442                	ld	s0,16(sp)
    80005056:	64a2                	ld	s1,8(sp)
    80005058:	6105                	addi	sp,sp,32
    8000505a:	8082                	ret
      p->ofile[fd] = f;
    8000505c:	01a50793          	addi	a5,a0,26
    80005060:	078e                	slli	a5,a5,0x3
    80005062:	963e                	add	a2,a2,a5
    80005064:	e204                	sd	s1,0(a2)
      return fd;
    80005066:	b7f5                	j	80005052 <fdalloc+0x2c>

0000000080005068 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005068:	715d                	addi	sp,sp,-80
    8000506a:	e486                	sd	ra,72(sp)
    8000506c:	e0a2                	sd	s0,64(sp)
    8000506e:	fc26                	sd	s1,56(sp)
    80005070:	f84a                	sd	s2,48(sp)
    80005072:	f44e                	sd	s3,40(sp)
    80005074:	f052                	sd	s4,32(sp)
    80005076:	ec56                	sd	s5,24(sp)
    80005078:	0880                	addi	s0,sp,80
    8000507a:	89ae                	mv	s3,a1
    8000507c:	8ab2                	mv	s5,a2
    8000507e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005080:	fb040593          	addi	a1,s0,-80
    80005084:	fffff097          	auipc	ra,0xfffff
    80005088:	e72080e7          	jalr	-398(ra) # 80003ef6 <nameiparent>
    8000508c:	892a                	mv	s2,a0
    8000508e:	12050e63          	beqz	a0,800051ca <create+0x162>
    return 0;

  ilock(dp);
    80005092:	ffffe097          	auipc	ra,0xffffe
    80005096:	690080e7          	jalr	1680(ra) # 80003722 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000509a:	4601                	li	a2,0
    8000509c:	fb040593          	addi	a1,s0,-80
    800050a0:	854a                	mv	a0,s2
    800050a2:	fffff097          	auipc	ra,0xfffff
    800050a6:	b64080e7          	jalr	-1180(ra) # 80003c06 <dirlookup>
    800050aa:	84aa                	mv	s1,a0
    800050ac:	c921                	beqz	a0,800050fc <create+0x94>
    iunlockput(dp);
    800050ae:	854a                	mv	a0,s2
    800050b0:	fffff097          	auipc	ra,0xfffff
    800050b4:	8d4080e7          	jalr	-1836(ra) # 80003984 <iunlockput>
    ilock(ip);
    800050b8:	8526                	mv	a0,s1
    800050ba:	ffffe097          	auipc	ra,0xffffe
    800050be:	668080e7          	jalr	1640(ra) # 80003722 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050c2:	2981                	sext.w	s3,s3
    800050c4:	4789                	li	a5,2
    800050c6:	02f99463          	bne	s3,a5,800050ee <create+0x86>
    800050ca:	0444d783          	lhu	a5,68(s1)
    800050ce:	37f9                	addiw	a5,a5,-2
    800050d0:	17c2                	slli	a5,a5,0x30
    800050d2:	93c1                	srli	a5,a5,0x30
    800050d4:	4705                	li	a4,1
    800050d6:	00f76c63          	bltu	a4,a5,800050ee <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050da:	8526                	mv	a0,s1
    800050dc:	60a6                	ld	ra,72(sp)
    800050de:	6406                	ld	s0,64(sp)
    800050e0:	74e2                	ld	s1,56(sp)
    800050e2:	7942                	ld	s2,48(sp)
    800050e4:	79a2                	ld	s3,40(sp)
    800050e6:	7a02                	ld	s4,32(sp)
    800050e8:	6ae2                	ld	s5,24(sp)
    800050ea:	6161                	addi	sp,sp,80
    800050ec:	8082                	ret
    iunlockput(ip);
    800050ee:	8526                	mv	a0,s1
    800050f0:	fffff097          	auipc	ra,0xfffff
    800050f4:	894080e7          	jalr	-1900(ra) # 80003984 <iunlockput>
    return 0;
    800050f8:	4481                	li	s1,0
    800050fa:	b7c5                	j	800050da <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050fc:	85ce                	mv	a1,s3
    800050fe:	00092503          	lw	a0,0(s2)
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	488080e7          	jalr	1160(ra) # 8000358a <ialloc>
    8000510a:	84aa                	mv	s1,a0
    8000510c:	c521                	beqz	a0,80005154 <create+0xec>
  ilock(ip);
    8000510e:	ffffe097          	auipc	ra,0xffffe
    80005112:	614080e7          	jalr	1556(ra) # 80003722 <ilock>
  ip->major = major;
    80005116:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000511a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000511e:	4a05                	li	s4,1
    80005120:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005124:	8526                	mv	a0,s1
    80005126:	ffffe097          	auipc	ra,0xffffe
    8000512a:	532080e7          	jalr	1330(ra) # 80003658 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000512e:	2981                	sext.w	s3,s3
    80005130:	03498a63          	beq	s3,s4,80005164 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005134:	40d0                	lw	a2,4(s1)
    80005136:	fb040593          	addi	a1,s0,-80
    8000513a:	854a                	mv	a0,s2
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	cda080e7          	jalr	-806(ra) # 80003e16 <dirlink>
    80005144:	06054b63          	bltz	a0,800051ba <create+0x152>
  iunlockput(dp);
    80005148:	854a                	mv	a0,s2
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	83a080e7          	jalr	-1990(ra) # 80003984 <iunlockput>
  return ip;
    80005152:	b761                	j	800050da <create+0x72>
    panic("create: ialloc");
    80005154:	00003517          	auipc	a0,0x3
    80005158:	7bc50513          	addi	a0,a0,1980 # 80008910 <syscalls_str+0x2a8>
    8000515c:	ffffb097          	auipc	ra,0xffffb
    80005160:	3ce080e7          	jalr	974(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005164:	04a95783          	lhu	a5,74(s2)
    80005168:	2785                	addiw	a5,a5,1
    8000516a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000516e:	854a                	mv	a0,s2
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	4e8080e7          	jalr	1256(ra) # 80003658 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005178:	40d0                	lw	a2,4(s1)
    8000517a:	00003597          	auipc	a1,0x3
    8000517e:	7a658593          	addi	a1,a1,1958 # 80008920 <syscalls_str+0x2b8>
    80005182:	8526                	mv	a0,s1
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	c92080e7          	jalr	-878(ra) # 80003e16 <dirlink>
    8000518c:	00054f63          	bltz	a0,800051aa <create+0x142>
    80005190:	00492603          	lw	a2,4(s2)
    80005194:	00003597          	auipc	a1,0x3
    80005198:	79458593          	addi	a1,a1,1940 # 80008928 <syscalls_str+0x2c0>
    8000519c:	8526                	mv	a0,s1
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	c78080e7          	jalr	-904(ra) # 80003e16 <dirlink>
    800051a6:	f80557e3          	bgez	a0,80005134 <create+0xcc>
      panic("create dots");
    800051aa:	00003517          	auipc	a0,0x3
    800051ae:	78650513          	addi	a0,a0,1926 # 80008930 <syscalls_str+0x2c8>
    800051b2:	ffffb097          	auipc	ra,0xffffb
    800051b6:	378080e7          	jalr	888(ra) # 8000052a <panic>
    panic("create: dirlink");
    800051ba:	00003517          	auipc	a0,0x3
    800051be:	78650513          	addi	a0,a0,1926 # 80008940 <syscalls_str+0x2d8>
    800051c2:	ffffb097          	auipc	ra,0xffffb
    800051c6:	368080e7          	jalr	872(ra) # 8000052a <panic>
    return 0;
    800051ca:	84aa                	mv	s1,a0
    800051cc:	b739                	j	800050da <create+0x72>

00000000800051ce <sys_dup>:
{
    800051ce:	7179                	addi	sp,sp,-48
    800051d0:	f406                	sd	ra,40(sp)
    800051d2:	f022                	sd	s0,32(sp)
    800051d4:	ec26                	sd	s1,24(sp)
    800051d6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051d8:	fd840613          	addi	a2,s0,-40
    800051dc:	4581                	li	a1,0
    800051de:	4501                	li	a0,0
    800051e0:	00000097          	auipc	ra,0x0
    800051e4:	dde080e7          	jalr	-546(ra) # 80004fbe <argfd>
    return -1;
    800051e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051ea:	02054363          	bltz	a0,80005210 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051ee:	fd843503          	ld	a0,-40(s0)
    800051f2:	00000097          	auipc	ra,0x0
    800051f6:	e34080e7          	jalr	-460(ra) # 80005026 <fdalloc>
    800051fa:	84aa                	mv	s1,a0
    return -1;
    800051fc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051fe:	00054963          	bltz	a0,80005210 <sys_dup+0x42>
  filedup(f);
    80005202:	fd843503          	ld	a0,-40(s0)
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	36c080e7          	jalr	876(ra) # 80004572 <filedup>
  return fd;
    8000520e:	87a6                	mv	a5,s1
}
    80005210:	853e                	mv	a0,a5
    80005212:	70a2                	ld	ra,40(sp)
    80005214:	7402                	ld	s0,32(sp)
    80005216:	64e2                	ld	s1,24(sp)
    80005218:	6145                	addi	sp,sp,48
    8000521a:	8082                	ret

000000008000521c <sys_read>:
{
    8000521c:	7179                	addi	sp,sp,-48
    8000521e:	f406                	sd	ra,40(sp)
    80005220:	f022                	sd	s0,32(sp)
    80005222:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005224:	fe840613          	addi	a2,s0,-24
    80005228:	4581                	li	a1,0
    8000522a:	4501                	li	a0,0
    8000522c:	00000097          	auipc	ra,0x0
    80005230:	d92080e7          	jalr	-622(ra) # 80004fbe <argfd>
    return -1;
    80005234:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005236:	04054163          	bltz	a0,80005278 <sys_read+0x5c>
    8000523a:	fe440593          	addi	a1,s0,-28
    8000523e:	4509                	li	a0,2
    80005240:	ffffe097          	auipc	ra,0xffffe
    80005244:	87a080e7          	jalr	-1926(ra) # 80002aba <argint>
    return -1;
    80005248:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000524a:	02054763          	bltz	a0,80005278 <sys_read+0x5c>
    8000524e:	fd840593          	addi	a1,s0,-40
    80005252:	4505                	li	a0,1
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	888080e7          	jalr	-1912(ra) # 80002adc <argaddr>
    return -1;
    8000525c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525e:	00054d63          	bltz	a0,80005278 <sys_read+0x5c>
  return fileread(f, p, n);
    80005262:	fe442603          	lw	a2,-28(s0)
    80005266:	fd843583          	ld	a1,-40(s0)
    8000526a:	fe843503          	ld	a0,-24(s0)
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	490080e7          	jalr	1168(ra) # 800046fe <fileread>
    80005276:	87aa                	mv	a5,a0
}
    80005278:	853e                	mv	a0,a5
    8000527a:	70a2                	ld	ra,40(sp)
    8000527c:	7402                	ld	s0,32(sp)
    8000527e:	6145                	addi	sp,sp,48
    80005280:	8082                	ret

0000000080005282 <sys_write>:
{
    80005282:	7179                	addi	sp,sp,-48
    80005284:	f406                	sd	ra,40(sp)
    80005286:	f022                	sd	s0,32(sp)
    80005288:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528a:	fe840613          	addi	a2,s0,-24
    8000528e:	4581                	li	a1,0
    80005290:	4501                	li	a0,0
    80005292:	00000097          	auipc	ra,0x0
    80005296:	d2c080e7          	jalr	-724(ra) # 80004fbe <argfd>
    return -1;
    8000529a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529c:	04054163          	bltz	a0,800052de <sys_write+0x5c>
    800052a0:	fe440593          	addi	a1,s0,-28
    800052a4:	4509                	li	a0,2
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	814080e7          	jalr	-2028(ra) # 80002aba <argint>
    return -1;
    800052ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b0:	02054763          	bltz	a0,800052de <sys_write+0x5c>
    800052b4:	fd840593          	addi	a1,s0,-40
    800052b8:	4505                	li	a0,1
    800052ba:	ffffe097          	auipc	ra,0xffffe
    800052be:	822080e7          	jalr	-2014(ra) # 80002adc <argaddr>
    return -1;
    800052c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c4:	00054d63          	bltz	a0,800052de <sys_write+0x5c>
  return filewrite(f, p, n);
    800052c8:	fe442603          	lw	a2,-28(s0)
    800052cc:	fd843583          	ld	a1,-40(s0)
    800052d0:	fe843503          	ld	a0,-24(s0)
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	4ec080e7          	jalr	1260(ra) # 800047c0 <filewrite>
    800052dc:	87aa                	mv	a5,a0
}
    800052de:	853e                	mv	a0,a5
    800052e0:	70a2                	ld	ra,40(sp)
    800052e2:	7402                	ld	s0,32(sp)
    800052e4:	6145                	addi	sp,sp,48
    800052e6:	8082                	ret

00000000800052e8 <sys_close>:
{
    800052e8:	1101                	addi	sp,sp,-32
    800052ea:	ec06                	sd	ra,24(sp)
    800052ec:	e822                	sd	s0,16(sp)
    800052ee:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052f0:	fe040613          	addi	a2,s0,-32
    800052f4:	fec40593          	addi	a1,s0,-20
    800052f8:	4501                	li	a0,0
    800052fa:	00000097          	auipc	ra,0x0
    800052fe:	cc4080e7          	jalr	-828(ra) # 80004fbe <argfd>
    return -1;
    80005302:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005304:	02054463          	bltz	a0,8000532c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005308:	ffffc097          	auipc	ra,0xffffc
    8000530c:	68a080e7          	jalr	1674(ra) # 80001992 <myproc>
    80005310:	fec42783          	lw	a5,-20(s0)
    80005314:	07e9                	addi	a5,a5,26
    80005316:	078e                	slli	a5,a5,0x3
    80005318:	97aa                	add	a5,a5,a0
    8000531a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000531e:	fe043503          	ld	a0,-32(s0)
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	2a2080e7          	jalr	674(ra) # 800045c4 <fileclose>
  return 0;
    8000532a:	4781                	li	a5,0
}
    8000532c:	853e                	mv	a0,a5
    8000532e:	60e2                	ld	ra,24(sp)
    80005330:	6442                	ld	s0,16(sp)
    80005332:	6105                	addi	sp,sp,32
    80005334:	8082                	ret

0000000080005336 <sys_fstat>:
{
    80005336:	1101                	addi	sp,sp,-32
    80005338:	ec06                	sd	ra,24(sp)
    8000533a:	e822                	sd	s0,16(sp)
    8000533c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000533e:	fe840613          	addi	a2,s0,-24
    80005342:	4581                	li	a1,0
    80005344:	4501                	li	a0,0
    80005346:	00000097          	auipc	ra,0x0
    8000534a:	c78080e7          	jalr	-904(ra) # 80004fbe <argfd>
    return -1;
    8000534e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005350:	02054563          	bltz	a0,8000537a <sys_fstat+0x44>
    80005354:	fe040593          	addi	a1,s0,-32
    80005358:	4505                	li	a0,1
    8000535a:	ffffd097          	auipc	ra,0xffffd
    8000535e:	782080e7          	jalr	1922(ra) # 80002adc <argaddr>
    return -1;
    80005362:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005364:	00054b63          	bltz	a0,8000537a <sys_fstat+0x44>
  return filestat(f, st);
    80005368:	fe043583          	ld	a1,-32(s0)
    8000536c:	fe843503          	ld	a0,-24(s0)
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	31c080e7          	jalr	796(ra) # 8000468c <filestat>
    80005378:	87aa                	mv	a5,a0
}
    8000537a:	853e                	mv	a0,a5
    8000537c:	60e2                	ld	ra,24(sp)
    8000537e:	6442                	ld	s0,16(sp)
    80005380:	6105                	addi	sp,sp,32
    80005382:	8082                	ret

0000000080005384 <sys_link>:
{
    80005384:	7169                	addi	sp,sp,-304
    80005386:	f606                	sd	ra,296(sp)
    80005388:	f222                	sd	s0,288(sp)
    8000538a:	ee26                	sd	s1,280(sp)
    8000538c:	ea4a                	sd	s2,272(sp)
    8000538e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005390:	08000613          	li	a2,128
    80005394:	ed040593          	addi	a1,s0,-304
    80005398:	4501                	li	a0,0
    8000539a:	ffffd097          	auipc	ra,0xffffd
    8000539e:	764080e7          	jalr	1892(ra) # 80002afe <argstr>
    return -1;
    800053a2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053a4:	10054e63          	bltz	a0,800054c0 <sys_link+0x13c>
    800053a8:	08000613          	li	a2,128
    800053ac:	f5040593          	addi	a1,s0,-176
    800053b0:	4505                	li	a0,1
    800053b2:	ffffd097          	auipc	ra,0xffffd
    800053b6:	74c080e7          	jalr	1868(ra) # 80002afe <argstr>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053bc:	10054263          	bltz	a0,800054c0 <sys_link+0x13c>
  begin_op();
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	d38080e7          	jalr	-712(ra) # 800040f8 <begin_op>
  if((ip = namei(old)) == 0){
    800053c8:	ed040513          	addi	a0,s0,-304
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	b0c080e7          	jalr	-1268(ra) # 80003ed8 <namei>
    800053d4:	84aa                	mv	s1,a0
    800053d6:	c551                	beqz	a0,80005462 <sys_link+0xde>
  ilock(ip);
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	34a080e7          	jalr	842(ra) # 80003722 <ilock>
  if(ip->type == T_DIR){
    800053e0:	04449703          	lh	a4,68(s1)
    800053e4:	4785                	li	a5,1
    800053e6:	08f70463          	beq	a4,a5,8000546e <sys_link+0xea>
  ip->nlink++;
    800053ea:	04a4d783          	lhu	a5,74(s1)
    800053ee:	2785                	addiw	a5,a5,1
    800053f0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053f4:	8526                	mv	a0,s1
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	262080e7          	jalr	610(ra) # 80003658 <iupdate>
  iunlock(ip);
    800053fe:	8526                	mv	a0,s1
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	3e4080e7          	jalr	996(ra) # 800037e4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005408:	fd040593          	addi	a1,s0,-48
    8000540c:	f5040513          	addi	a0,s0,-176
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	ae6080e7          	jalr	-1306(ra) # 80003ef6 <nameiparent>
    80005418:	892a                	mv	s2,a0
    8000541a:	c935                	beqz	a0,8000548e <sys_link+0x10a>
  ilock(dp);
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	306080e7          	jalr	774(ra) # 80003722 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005424:	00092703          	lw	a4,0(s2)
    80005428:	409c                	lw	a5,0(s1)
    8000542a:	04f71d63          	bne	a4,a5,80005484 <sys_link+0x100>
    8000542e:	40d0                	lw	a2,4(s1)
    80005430:	fd040593          	addi	a1,s0,-48
    80005434:	854a                	mv	a0,s2
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	9e0080e7          	jalr	-1568(ra) # 80003e16 <dirlink>
    8000543e:	04054363          	bltz	a0,80005484 <sys_link+0x100>
  iunlockput(dp);
    80005442:	854a                	mv	a0,s2
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	540080e7          	jalr	1344(ra) # 80003984 <iunlockput>
  iput(ip);
    8000544c:	8526                	mv	a0,s1
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	48e080e7          	jalr	1166(ra) # 800038dc <iput>
  end_op();
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	d22080e7          	jalr	-734(ra) # 80004178 <end_op>
  return 0;
    8000545e:	4781                	li	a5,0
    80005460:	a085                	j	800054c0 <sys_link+0x13c>
    end_op();
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	d16080e7          	jalr	-746(ra) # 80004178 <end_op>
    return -1;
    8000546a:	57fd                	li	a5,-1
    8000546c:	a891                	j	800054c0 <sys_link+0x13c>
    iunlockput(ip);
    8000546e:	8526                	mv	a0,s1
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	514080e7          	jalr	1300(ra) # 80003984 <iunlockput>
    end_op();
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	d00080e7          	jalr	-768(ra) # 80004178 <end_op>
    return -1;
    80005480:	57fd                	li	a5,-1
    80005482:	a83d                	j	800054c0 <sys_link+0x13c>
    iunlockput(dp);
    80005484:	854a                	mv	a0,s2
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	4fe080e7          	jalr	1278(ra) # 80003984 <iunlockput>
  ilock(ip);
    8000548e:	8526                	mv	a0,s1
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	292080e7          	jalr	658(ra) # 80003722 <ilock>
  ip->nlink--;
    80005498:	04a4d783          	lhu	a5,74(s1)
    8000549c:	37fd                	addiw	a5,a5,-1
    8000549e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a2:	8526                	mv	a0,s1
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	1b4080e7          	jalr	436(ra) # 80003658 <iupdate>
  iunlockput(ip);
    800054ac:	8526                	mv	a0,s1
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	4d6080e7          	jalr	1238(ra) # 80003984 <iunlockput>
  end_op();
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	cc2080e7          	jalr	-830(ra) # 80004178 <end_op>
  return -1;
    800054be:	57fd                	li	a5,-1
}
    800054c0:	853e                	mv	a0,a5
    800054c2:	70b2                	ld	ra,296(sp)
    800054c4:	7412                	ld	s0,288(sp)
    800054c6:	64f2                	ld	s1,280(sp)
    800054c8:	6952                	ld	s2,272(sp)
    800054ca:	6155                	addi	sp,sp,304
    800054cc:	8082                	ret

00000000800054ce <sys_unlink>:
{
    800054ce:	7151                	addi	sp,sp,-240
    800054d0:	f586                	sd	ra,232(sp)
    800054d2:	f1a2                	sd	s0,224(sp)
    800054d4:	eda6                	sd	s1,216(sp)
    800054d6:	e9ca                	sd	s2,208(sp)
    800054d8:	e5ce                	sd	s3,200(sp)
    800054da:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054dc:	08000613          	li	a2,128
    800054e0:	f3040593          	addi	a1,s0,-208
    800054e4:	4501                	li	a0,0
    800054e6:	ffffd097          	auipc	ra,0xffffd
    800054ea:	618080e7          	jalr	1560(ra) # 80002afe <argstr>
    800054ee:	18054163          	bltz	a0,80005670 <sys_unlink+0x1a2>
  begin_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	c06080e7          	jalr	-1018(ra) # 800040f8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054fa:	fb040593          	addi	a1,s0,-80
    800054fe:	f3040513          	addi	a0,s0,-208
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	9f4080e7          	jalr	-1548(ra) # 80003ef6 <nameiparent>
    8000550a:	84aa                	mv	s1,a0
    8000550c:	c979                	beqz	a0,800055e2 <sys_unlink+0x114>
  ilock(dp);
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	214080e7          	jalr	532(ra) # 80003722 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005516:	00003597          	auipc	a1,0x3
    8000551a:	40a58593          	addi	a1,a1,1034 # 80008920 <syscalls_str+0x2b8>
    8000551e:	fb040513          	addi	a0,s0,-80
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	6ca080e7          	jalr	1738(ra) # 80003bec <namecmp>
    8000552a:	14050a63          	beqz	a0,8000567e <sys_unlink+0x1b0>
    8000552e:	00003597          	auipc	a1,0x3
    80005532:	3fa58593          	addi	a1,a1,1018 # 80008928 <syscalls_str+0x2c0>
    80005536:	fb040513          	addi	a0,s0,-80
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	6b2080e7          	jalr	1714(ra) # 80003bec <namecmp>
    80005542:	12050e63          	beqz	a0,8000567e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005546:	f2c40613          	addi	a2,s0,-212
    8000554a:	fb040593          	addi	a1,s0,-80
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	6b6080e7          	jalr	1718(ra) # 80003c06 <dirlookup>
    80005558:	892a                	mv	s2,a0
    8000555a:	12050263          	beqz	a0,8000567e <sys_unlink+0x1b0>
  ilock(ip);
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	1c4080e7          	jalr	452(ra) # 80003722 <ilock>
  if(ip->nlink < 1)
    80005566:	04a91783          	lh	a5,74(s2)
    8000556a:	08f05263          	blez	a5,800055ee <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000556e:	04491703          	lh	a4,68(s2)
    80005572:	4785                	li	a5,1
    80005574:	08f70563          	beq	a4,a5,800055fe <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005578:	4641                	li	a2,16
    8000557a:	4581                	li	a1,0
    8000557c:	fc040513          	addi	a0,s0,-64
    80005580:	ffffb097          	auipc	ra,0xffffb
    80005584:	73e080e7          	jalr	1854(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005588:	4741                	li	a4,16
    8000558a:	f2c42683          	lw	a3,-212(s0)
    8000558e:	fc040613          	addi	a2,s0,-64
    80005592:	4581                	li	a1,0
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	538080e7          	jalr	1336(ra) # 80003ace <writei>
    8000559e:	47c1                	li	a5,16
    800055a0:	0af51563          	bne	a0,a5,8000564a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055a4:	04491703          	lh	a4,68(s2)
    800055a8:	4785                	li	a5,1
    800055aa:	0af70863          	beq	a4,a5,8000565a <sys_unlink+0x18c>
  iunlockput(dp);
    800055ae:	8526                	mv	a0,s1
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	3d4080e7          	jalr	980(ra) # 80003984 <iunlockput>
  ip->nlink--;
    800055b8:	04a95783          	lhu	a5,74(s2)
    800055bc:	37fd                	addiw	a5,a5,-1
    800055be:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055c2:	854a                	mv	a0,s2
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	094080e7          	jalr	148(ra) # 80003658 <iupdate>
  iunlockput(ip);
    800055cc:	854a                	mv	a0,s2
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	3b6080e7          	jalr	950(ra) # 80003984 <iunlockput>
  end_op();
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	ba2080e7          	jalr	-1118(ra) # 80004178 <end_op>
  return 0;
    800055de:	4501                	li	a0,0
    800055e0:	a84d                	j	80005692 <sys_unlink+0x1c4>
    end_op();
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	b96080e7          	jalr	-1130(ra) # 80004178 <end_op>
    return -1;
    800055ea:	557d                	li	a0,-1
    800055ec:	a05d                	j	80005692 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055ee:	00003517          	auipc	a0,0x3
    800055f2:	36250513          	addi	a0,a0,866 # 80008950 <syscalls_str+0x2e8>
    800055f6:	ffffb097          	auipc	ra,0xffffb
    800055fa:	f34080e7          	jalr	-204(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055fe:	04c92703          	lw	a4,76(s2)
    80005602:	02000793          	li	a5,32
    80005606:	f6e7f9e3          	bgeu	a5,a4,80005578 <sys_unlink+0xaa>
    8000560a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000560e:	4741                	li	a4,16
    80005610:	86ce                	mv	a3,s3
    80005612:	f1840613          	addi	a2,s0,-232
    80005616:	4581                	li	a1,0
    80005618:	854a                	mv	a0,s2
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	3bc080e7          	jalr	956(ra) # 800039d6 <readi>
    80005622:	47c1                	li	a5,16
    80005624:	00f51b63          	bne	a0,a5,8000563a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005628:	f1845783          	lhu	a5,-232(s0)
    8000562c:	e7a1                	bnez	a5,80005674 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000562e:	29c1                	addiw	s3,s3,16
    80005630:	04c92783          	lw	a5,76(s2)
    80005634:	fcf9ede3          	bltu	s3,a5,8000560e <sys_unlink+0x140>
    80005638:	b781                	j	80005578 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000563a:	00003517          	auipc	a0,0x3
    8000563e:	32e50513          	addi	a0,a0,814 # 80008968 <syscalls_str+0x300>
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	ee8080e7          	jalr	-280(ra) # 8000052a <panic>
    panic("unlink: writei");
    8000564a:	00003517          	auipc	a0,0x3
    8000564e:	33650513          	addi	a0,a0,822 # 80008980 <syscalls_str+0x318>
    80005652:	ffffb097          	auipc	ra,0xffffb
    80005656:	ed8080e7          	jalr	-296(ra) # 8000052a <panic>
    dp->nlink--;
    8000565a:	04a4d783          	lhu	a5,74(s1)
    8000565e:	37fd                	addiw	a5,a5,-1
    80005660:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005664:	8526                	mv	a0,s1
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	ff2080e7          	jalr	-14(ra) # 80003658 <iupdate>
    8000566e:	b781                	j	800055ae <sys_unlink+0xe0>
    return -1;
    80005670:	557d                	li	a0,-1
    80005672:	a005                	j	80005692 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005674:	854a                	mv	a0,s2
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	30e080e7          	jalr	782(ra) # 80003984 <iunlockput>
  iunlockput(dp);
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	304080e7          	jalr	772(ra) # 80003984 <iunlockput>
  end_op();
    80005688:	fffff097          	auipc	ra,0xfffff
    8000568c:	af0080e7          	jalr	-1296(ra) # 80004178 <end_op>
  return -1;
    80005690:	557d                	li	a0,-1
}
    80005692:	70ae                	ld	ra,232(sp)
    80005694:	740e                	ld	s0,224(sp)
    80005696:	64ee                	ld	s1,216(sp)
    80005698:	694e                	ld	s2,208(sp)
    8000569a:	69ae                	ld	s3,200(sp)
    8000569c:	616d                	addi	sp,sp,240
    8000569e:	8082                	ret

00000000800056a0 <sys_open>:

uint64
sys_open(void)
{
    800056a0:	7131                	addi	sp,sp,-192
    800056a2:	fd06                	sd	ra,184(sp)
    800056a4:	f922                	sd	s0,176(sp)
    800056a6:	f526                	sd	s1,168(sp)
    800056a8:	f14a                	sd	s2,160(sp)
    800056aa:	ed4e                	sd	s3,152(sp)
    800056ac:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056ae:	08000613          	li	a2,128
    800056b2:	f5040593          	addi	a1,s0,-176
    800056b6:	4501                	li	a0,0
    800056b8:	ffffd097          	auipc	ra,0xffffd
    800056bc:	446080e7          	jalr	1094(ra) # 80002afe <argstr>
    return -1;
    800056c0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056c2:	0c054163          	bltz	a0,80005784 <sys_open+0xe4>
    800056c6:	f4c40593          	addi	a1,s0,-180
    800056ca:	4505                	li	a0,1
    800056cc:	ffffd097          	auipc	ra,0xffffd
    800056d0:	3ee080e7          	jalr	1006(ra) # 80002aba <argint>
    800056d4:	0a054863          	bltz	a0,80005784 <sys_open+0xe4>

  begin_op();
    800056d8:	fffff097          	auipc	ra,0xfffff
    800056dc:	a20080e7          	jalr	-1504(ra) # 800040f8 <begin_op>

  if(omode & O_CREATE){
    800056e0:	f4c42783          	lw	a5,-180(s0)
    800056e4:	2007f793          	andi	a5,a5,512
    800056e8:	cbdd                	beqz	a5,8000579e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056ea:	4681                	li	a3,0
    800056ec:	4601                	li	a2,0
    800056ee:	4589                	li	a1,2
    800056f0:	f5040513          	addi	a0,s0,-176
    800056f4:	00000097          	auipc	ra,0x0
    800056f8:	974080e7          	jalr	-1676(ra) # 80005068 <create>
    800056fc:	892a                	mv	s2,a0
    if(ip == 0){
    800056fe:	c959                	beqz	a0,80005794 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005700:	04491703          	lh	a4,68(s2)
    80005704:	478d                	li	a5,3
    80005706:	00f71763          	bne	a4,a5,80005714 <sys_open+0x74>
    8000570a:	04695703          	lhu	a4,70(s2)
    8000570e:	47a5                	li	a5,9
    80005710:	0ce7ec63          	bltu	a5,a4,800057e8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	df4080e7          	jalr	-524(ra) # 80004508 <filealloc>
    8000571c:	89aa                	mv	s3,a0
    8000571e:	10050263          	beqz	a0,80005822 <sys_open+0x182>
    80005722:	00000097          	auipc	ra,0x0
    80005726:	904080e7          	jalr	-1788(ra) # 80005026 <fdalloc>
    8000572a:	84aa                	mv	s1,a0
    8000572c:	0e054663          	bltz	a0,80005818 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005730:	04491703          	lh	a4,68(s2)
    80005734:	478d                	li	a5,3
    80005736:	0cf70463          	beq	a4,a5,800057fe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000573a:	4789                	li	a5,2
    8000573c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005740:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005744:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005748:	f4c42783          	lw	a5,-180(s0)
    8000574c:	0017c713          	xori	a4,a5,1
    80005750:	8b05                	andi	a4,a4,1
    80005752:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005756:	0037f713          	andi	a4,a5,3
    8000575a:	00e03733          	snez	a4,a4
    8000575e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005762:	4007f793          	andi	a5,a5,1024
    80005766:	c791                	beqz	a5,80005772 <sys_open+0xd2>
    80005768:	04491703          	lh	a4,68(s2)
    8000576c:	4789                	li	a5,2
    8000576e:	08f70f63          	beq	a4,a5,8000580c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005772:	854a                	mv	a0,s2
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	070080e7          	jalr	112(ra) # 800037e4 <iunlock>
  end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	9fc080e7          	jalr	-1540(ra) # 80004178 <end_op>

  return fd;
}
    80005784:	8526                	mv	a0,s1
    80005786:	70ea                	ld	ra,184(sp)
    80005788:	744a                	ld	s0,176(sp)
    8000578a:	74aa                	ld	s1,168(sp)
    8000578c:	790a                	ld	s2,160(sp)
    8000578e:	69ea                	ld	s3,152(sp)
    80005790:	6129                	addi	sp,sp,192
    80005792:	8082                	ret
      end_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	9e4080e7          	jalr	-1564(ra) # 80004178 <end_op>
      return -1;
    8000579c:	b7e5                	j	80005784 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000579e:	f5040513          	addi	a0,s0,-176
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	736080e7          	jalr	1846(ra) # 80003ed8 <namei>
    800057aa:	892a                	mv	s2,a0
    800057ac:	c905                	beqz	a0,800057dc <sys_open+0x13c>
    ilock(ip);
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	f74080e7          	jalr	-140(ra) # 80003722 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057b6:	04491703          	lh	a4,68(s2)
    800057ba:	4785                	li	a5,1
    800057bc:	f4f712e3          	bne	a4,a5,80005700 <sys_open+0x60>
    800057c0:	f4c42783          	lw	a5,-180(s0)
    800057c4:	dba1                	beqz	a5,80005714 <sys_open+0x74>
      iunlockput(ip);
    800057c6:	854a                	mv	a0,s2
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	1bc080e7          	jalr	444(ra) # 80003984 <iunlockput>
      end_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	9a8080e7          	jalr	-1624(ra) # 80004178 <end_op>
      return -1;
    800057d8:	54fd                	li	s1,-1
    800057da:	b76d                	j	80005784 <sys_open+0xe4>
      end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	99c080e7          	jalr	-1636(ra) # 80004178 <end_op>
      return -1;
    800057e4:	54fd                	li	s1,-1
    800057e6:	bf79                	j	80005784 <sys_open+0xe4>
    iunlockput(ip);
    800057e8:	854a                	mv	a0,s2
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	19a080e7          	jalr	410(ra) # 80003984 <iunlockput>
    end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	986080e7          	jalr	-1658(ra) # 80004178 <end_op>
    return -1;
    800057fa:	54fd                	li	s1,-1
    800057fc:	b761                	j	80005784 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057fe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005802:	04691783          	lh	a5,70(s2)
    80005806:	02f99223          	sh	a5,36(s3)
    8000580a:	bf2d                	j	80005744 <sys_open+0xa4>
    itrunc(ip);
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	022080e7          	jalr	34(ra) # 80003830 <itrunc>
    80005816:	bfb1                	j	80005772 <sys_open+0xd2>
      fileclose(f);
    80005818:	854e                	mv	a0,s3
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	daa080e7          	jalr	-598(ra) # 800045c4 <fileclose>
    iunlockput(ip);
    80005822:	854a                	mv	a0,s2
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	160080e7          	jalr	352(ra) # 80003984 <iunlockput>
    end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	94c080e7          	jalr	-1716(ra) # 80004178 <end_op>
    return -1;
    80005834:	54fd                	li	s1,-1
    80005836:	b7b9                	j	80005784 <sys_open+0xe4>

0000000080005838 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005838:	7175                	addi	sp,sp,-144
    8000583a:	e506                	sd	ra,136(sp)
    8000583c:	e122                	sd	s0,128(sp)
    8000583e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	8b8080e7          	jalr	-1864(ra) # 800040f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005848:	08000613          	li	a2,128
    8000584c:	f7040593          	addi	a1,s0,-144
    80005850:	4501                	li	a0,0
    80005852:	ffffd097          	auipc	ra,0xffffd
    80005856:	2ac080e7          	jalr	684(ra) # 80002afe <argstr>
    8000585a:	02054963          	bltz	a0,8000588c <sys_mkdir+0x54>
    8000585e:	4681                	li	a3,0
    80005860:	4601                	li	a2,0
    80005862:	4585                	li	a1,1
    80005864:	f7040513          	addi	a0,s0,-144
    80005868:	00000097          	auipc	ra,0x0
    8000586c:	800080e7          	jalr	-2048(ra) # 80005068 <create>
    80005870:	cd11                	beqz	a0,8000588c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	112080e7          	jalr	274(ra) # 80003984 <iunlockput>
  end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	8fe080e7          	jalr	-1794(ra) # 80004178 <end_op>
  return 0;
    80005882:	4501                	li	a0,0
}
    80005884:	60aa                	ld	ra,136(sp)
    80005886:	640a                	ld	s0,128(sp)
    80005888:	6149                	addi	sp,sp,144
    8000588a:	8082                	ret
    end_op();
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	8ec080e7          	jalr	-1812(ra) # 80004178 <end_op>
    return -1;
    80005894:	557d                	li	a0,-1
    80005896:	b7fd                	j	80005884 <sys_mkdir+0x4c>

0000000080005898 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005898:	7135                	addi	sp,sp,-160
    8000589a:	ed06                	sd	ra,152(sp)
    8000589c:	e922                	sd	s0,144(sp)
    8000589e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	858080e7          	jalr	-1960(ra) # 800040f8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058a8:	08000613          	li	a2,128
    800058ac:	f7040593          	addi	a1,s0,-144
    800058b0:	4501                	li	a0,0
    800058b2:	ffffd097          	auipc	ra,0xffffd
    800058b6:	24c080e7          	jalr	588(ra) # 80002afe <argstr>
    800058ba:	04054a63          	bltz	a0,8000590e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058be:	f6c40593          	addi	a1,s0,-148
    800058c2:	4505                	li	a0,1
    800058c4:	ffffd097          	auipc	ra,0xffffd
    800058c8:	1f6080e7          	jalr	502(ra) # 80002aba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058cc:	04054163          	bltz	a0,8000590e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058d0:	f6840593          	addi	a1,s0,-152
    800058d4:	4509                	li	a0,2
    800058d6:	ffffd097          	auipc	ra,0xffffd
    800058da:	1e4080e7          	jalr	484(ra) # 80002aba <argint>
     argint(1, &major) < 0 ||
    800058de:	02054863          	bltz	a0,8000590e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058e2:	f6841683          	lh	a3,-152(s0)
    800058e6:	f6c41603          	lh	a2,-148(s0)
    800058ea:	458d                	li	a1,3
    800058ec:	f7040513          	addi	a0,s0,-144
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	778080e7          	jalr	1912(ra) # 80005068 <create>
     argint(2, &minor) < 0 ||
    800058f8:	c919                	beqz	a0,8000590e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	08a080e7          	jalr	138(ra) # 80003984 <iunlockput>
  end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	876080e7          	jalr	-1930(ra) # 80004178 <end_op>
  return 0;
    8000590a:	4501                	li	a0,0
    8000590c:	a031                	j	80005918 <sys_mknod+0x80>
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	86a080e7          	jalr	-1942(ra) # 80004178 <end_op>
    return -1;
    80005916:	557d                	li	a0,-1
}
    80005918:	60ea                	ld	ra,152(sp)
    8000591a:	644a                	ld	s0,144(sp)
    8000591c:	610d                	addi	sp,sp,160
    8000591e:	8082                	ret

0000000080005920 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005920:	7135                	addi	sp,sp,-160
    80005922:	ed06                	sd	ra,152(sp)
    80005924:	e922                	sd	s0,144(sp)
    80005926:	e526                	sd	s1,136(sp)
    80005928:	e14a                	sd	s2,128(sp)
    8000592a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000592c:	ffffc097          	auipc	ra,0xffffc
    80005930:	066080e7          	jalr	102(ra) # 80001992 <myproc>
    80005934:	892a                	mv	s2,a0
  
  begin_op();
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	7c2080e7          	jalr	1986(ra) # 800040f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000593e:	08000613          	li	a2,128
    80005942:	f6040593          	addi	a1,s0,-160
    80005946:	4501                	li	a0,0
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	1b6080e7          	jalr	438(ra) # 80002afe <argstr>
    80005950:	04054b63          	bltz	a0,800059a6 <sys_chdir+0x86>
    80005954:	f6040513          	addi	a0,s0,-160
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	580080e7          	jalr	1408(ra) # 80003ed8 <namei>
    80005960:	84aa                	mv	s1,a0
    80005962:	c131                	beqz	a0,800059a6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	dbe080e7          	jalr	-578(ra) # 80003722 <ilock>
  if(ip->type != T_DIR){
    8000596c:	04449703          	lh	a4,68(s1)
    80005970:	4785                	li	a5,1
    80005972:	04f71063          	bne	a4,a5,800059b2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005976:	8526                	mv	a0,s1
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	e6c080e7          	jalr	-404(ra) # 800037e4 <iunlock>
  iput(p->cwd);
    80005980:	15093503          	ld	a0,336(s2)
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	f58080e7          	jalr	-168(ra) # 800038dc <iput>
  end_op();
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	7ec080e7          	jalr	2028(ra) # 80004178 <end_op>
  p->cwd = ip;
    80005994:	14993823          	sd	s1,336(s2)
  return 0;
    80005998:	4501                	li	a0,0
}
    8000599a:	60ea                	ld	ra,152(sp)
    8000599c:	644a                	ld	s0,144(sp)
    8000599e:	64aa                	ld	s1,136(sp)
    800059a0:	690a                	ld	s2,128(sp)
    800059a2:	610d                	addi	sp,sp,160
    800059a4:	8082                	ret
    end_op();
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	7d2080e7          	jalr	2002(ra) # 80004178 <end_op>
    return -1;
    800059ae:	557d                	li	a0,-1
    800059b0:	b7ed                	j	8000599a <sys_chdir+0x7a>
    iunlockput(ip);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	fd0080e7          	jalr	-48(ra) # 80003984 <iunlockput>
    end_op();
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	7bc080e7          	jalr	1980(ra) # 80004178 <end_op>
    return -1;
    800059c4:	557d                	li	a0,-1
    800059c6:	bfd1                	j	8000599a <sys_chdir+0x7a>

00000000800059c8 <sys_exec>:

uint64
sys_exec(void)
{
    800059c8:	7145                	addi	sp,sp,-464
    800059ca:	e786                	sd	ra,456(sp)
    800059cc:	e3a2                	sd	s0,448(sp)
    800059ce:	ff26                	sd	s1,440(sp)
    800059d0:	fb4a                	sd	s2,432(sp)
    800059d2:	f74e                	sd	s3,424(sp)
    800059d4:	f352                	sd	s4,416(sp)
    800059d6:	ef56                	sd	s5,408(sp)
    800059d8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059da:	08000613          	li	a2,128
    800059de:	f4040593          	addi	a1,s0,-192
    800059e2:	4501                	li	a0,0
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	11a080e7          	jalr	282(ra) # 80002afe <argstr>
    return -1;
    800059ec:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059ee:	0c054a63          	bltz	a0,80005ac2 <sys_exec+0xfa>
    800059f2:	e3840593          	addi	a1,s0,-456
    800059f6:	4505                	li	a0,1
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	0e4080e7          	jalr	228(ra) # 80002adc <argaddr>
    80005a00:	0c054163          	bltz	a0,80005ac2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a04:	10000613          	li	a2,256
    80005a08:	4581                	li	a1,0
    80005a0a:	e4040513          	addi	a0,s0,-448
    80005a0e:	ffffb097          	auipc	ra,0xffffb
    80005a12:	2b0080e7          	jalr	688(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a16:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a1a:	89a6                	mv	s3,s1
    80005a1c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a1e:	02000a13          	li	s4,32
    80005a22:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a26:	00391793          	slli	a5,s2,0x3
    80005a2a:	e3040593          	addi	a1,s0,-464
    80005a2e:	e3843503          	ld	a0,-456(s0)
    80005a32:	953e                	add	a0,a0,a5
    80005a34:	ffffd097          	auipc	ra,0xffffd
    80005a38:	fec080e7          	jalr	-20(ra) # 80002a20 <fetchaddr>
    80005a3c:	02054a63          	bltz	a0,80005a70 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a40:	e3043783          	ld	a5,-464(s0)
    80005a44:	c3b9                	beqz	a5,80005a8a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a46:	ffffb097          	auipc	ra,0xffffb
    80005a4a:	08c080e7          	jalr	140(ra) # 80000ad2 <kalloc>
    80005a4e:	85aa                	mv	a1,a0
    80005a50:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a54:	cd11                	beqz	a0,80005a70 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a56:	6605                	lui	a2,0x1
    80005a58:	e3043503          	ld	a0,-464(s0)
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	016080e7          	jalr	22(ra) # 80002a72 <fetchstr>
    80005a64:	00054663          	bltz	a0,80005a70 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a68:	0905                	addi	s2,s2,1
    80005a6a:	09a1                	addi	s3,s3,8
    80005a6c:	fb491be3          	bne	s2,s4,80005a22 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a70:	10048913          	addi	s2,s1,256
    80005a74:	6088                	ld	a0,0(s1)
    80005a76:	c529                	beqz	a0,80005ac0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a78:	ffffb097          	auipc	ra,0xffffb
    80005a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a80:	04a1                	addi	s1,s1,8
    80005a82:	ff2499e3          	bne	s1,s2,80005a74 <sys_exec+0xac>
  return -1;
    80005a86:	597d                	li	s2,-1
    80005a88:	a82d                	j	80005ac2 <sys_exec+0xfa>
      argv[i] = 0;
    80005a8a:	0a8e                	slli	s5,s5,0x3
    80005a8c:	fc040793          	addi	a5,s0,-64
    80005a90:	9abe                	add	s5,s5,a5
    80005a92:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005a96:	e4040593          	addi	a1,s0,-448
    80005a9a:	f4040513          	addi	a0,s0,-192
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	178080e7          	jalr	376(ra) # 80004c16 <exec>
    80005aa6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa8:	10048993          	addi	s3,s1,256
    80005aac:	6088                	ld	a0,0(s1)
    80005aae:	c911                	beqz	a0,80005ac2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ab0:	ffffb097          	auipc	ra,0xffffb
    80005ab4:	f26080e7          	jalr	-218(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab8:	04a1                	addi	s1,s1,8
    80005aba:	ff3499e3          	bne	s1,s3,80005aac <sys_exec+0xe4>
    80005abe:	a011                	j	80005ac2 <sys_exec+0xfa>
  return -1;
    80005ac0:	597d                	li	s2,-1
}
    80005ac2:	854a                	mv	a0,s2
    80005ac4:	60be                	ld	ra,456(sp)
    80005ac6:	641e                	ld	s0,448(sp)
    80005ac8:	74fa                	ld	s1,440(sp)
    80005aca:	795a                	ld	s2,432(sp)
    80005acc:	79ba                	ld	s3,424(sp)
    80005ace:	7a1a                	ld	s4,416(sp)
    80005ad0:	6afa                	ld	s5,408(sp)
    80005ad2:	6179                	addi	sp,sp,464
    80005ad4:	8082                	ret

0000000080005ad6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ad6:	7139                	addi	sp,sp,-64
    80005ad8:	fc06                	sd	ra,56(sp)
    80005ada:	f822                	sd	s0,48(sp)
    80005adc:	f426                	sd	s1,40(sp)
    80005ade:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ae0:	ffffc097          	auipc	ra,0xffffc
    80005ae4:	eb2080e7          	jalr	-334(ra) # 80001992 <myproc>
    80005ae8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005aea:	fd840593          	addi	a1,s0,-40
    80005aee:	4501                	li	a0,0
    80005af0:	ffffd097          	auipc	ra,0xffffd
    80005af4:	fec080e7          	jalr	-20(ra) # 80002adc <argaddr>
    return -1;
    80005af8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005afa:	0e054063          	bltz	a0,80005bda <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005afe:	fc840593          	addi	a1,s0,-56
    80005b02:	fd040513          	addi	a0,s0,-48
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	dee080e7          	jalr	-530(ra) # 800048f4 <pipealloc>
    return -1;
    80005b0e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b10:	0c054563          	bltz	a0,80005bda <sys_pipe+0x104>
  fd0 = -1;
    80005b14:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b18:	fd043503          	ld	a0,-48(s0)
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	50a080e7          	jalr	1290(ra) # 80005026 <fdalloc>
    80005b24:	fca42223          	sw	a0,-60(s0)
    80005b28:	08054c63          	bltz	a0,80005bc0 <sys_pipe+0xea>
    80005b2c:	fc843503          	ld	a0,-56(s0)
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	4f6080e7          	jalr	1270(ra) # 80005026 <fdalloc>
    80005b38:	fca42023          	sw	a0,-64(s0)
    80005b3c:	06054863          	bltz	a0,80005bac <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b40:	4691                	li	a3,4
    80005b42:	fc440613          	addi	a2,s0,-60
    80005b46:	fd843583          	ld	a1,-40(s0)
    80005b4a:	68a8                	ld	a0,80(s1)
    80005b4c:	ffffc097          	auipc	ra,0xffffc
    80005b50:	af2080e7          	jalr	-1294(ra) # 8000163e <copyout>
    80005b54:	02054063          	bltz	a0,80005b74 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b58:	4691                	li	a3,4
    80005b5a:	fc040613          	addi	a2,s0,-64
    80005b5e:	fd843583          	ld	a1,-40(s0)
    80005b62:	0591                	addi	a1,a1,4
    80005b64:	68a8                	ld	a0,80(s1)
    80005b66:	ffffc097          	auipc	ra,0xffffc
    80005b6a:	ad8080e7          	jalr	-1320(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b6e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b70:	06055563          	bgez	a0,80005bda <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b74:	fc442783          	lw	a5,-60(s0)
    80005b78:	07e9                	addi	a5,a5,26
    80005b7a:	078e                	slli	a5,a5,0x3
    80005b7c:	97a6                	add	a5,a5,s1
    80005b7e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b82:	fc042503          	lw	a0,-64(s0)
    80005b86:	0569                	addi	a0,a0,26
    80005b88:	050e                	slli	a0,a0,0x3
    80005b8a:	9526                	add	a0,a0,s1
    80005b8c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b90:	fd043503          	ld	a0,-48(s0)
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	a30080e7          	jalr	-1488(ra) # 800045c4 <fileclose>
    fileclose(wf);
    80005b9c:	fc843503          	ld	a0,-56(s0)
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	a24080e7          	jalr	-1500(ra) # 800045c4 <fileclose>
    return -1;
    80005ba8:	57fd                	li	a5,-1
    80005baa:	a805                	j	80005bda <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bac:	fc442783          	lw	a5,-60(s0)
    80005bb0:	0007c863          	bltz	a5,80005bc0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bb4:	01a78513          	addi	a0,a5,26
    80005bb8:	050e                	slli	a0,a0,0x3
    80005bba:	9526                	add	a0,a0,s1
    80005bbc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bc0:	fd043503          	ld	a0,-48(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	a00080e7          	jalr	-1536(ra) # 800045c4 <fileclose>
    fileclose(wf);
    80005bcc:	fc843503          	ld	a0,-56(s0)
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	9f4080e7          	jalr	-1548(ra) # 800045c4 <fileclose>
    return -1;
    80005bd8:	57fd                	li	a5,-1
}
    80005bda:	853e                	mv	a0,a5
    80005bdc:	70e2                	ld	ra,56(sp)
    80005bde:	7442                	ld	s0,48(sp)
    80005be0:	74a2                	ld	s1,40(sp)
    80005be2:	6121                	addi	sp,sp,64
    80005be4:	8082                	ret
	...

0000000080005bf0 <kernelvec>:
    80005bf0:	7111                	addi	sp,sp,-256
    80005bf2:	e006                	sd	ra,0(sp)
    80005bf4:	e40a                	sd	sp,8(sp)
    80005bf6:	e80e                	sd	gp,16(sp)
    80005bf8:	ec12                	sd	tp,24(sp)
    80005bfa:	f016                	sd	t0,32(sp)
    80005bfc:	f41a                	sd	t1,40(sp)
    80005bfe:	f81e                	sd	t2,48(sp)
    80005c00:	fc22                	sd	s0,56(sp)
    80005c02:	e0a6                	sd	s1,64(sp)
    80005c04:	e4aa                	sd	a0,72(sp)
    80005c06:	e8ae                	sd	a1,80(sp)
    80005c08:	ecb2                	sd	a2,88(sp)
    80005c0a:	f0b6                	sd	a3,96(sp)
    80005c0c:	f4ba                	sd	a4,104(sp)
    80005c0e:	f8be                	sd	a5,112(sp)
    80005c10:	fcc2                	sd	a6,120(sp)
    80005c12:	e146                	sd	a7,128(sp)
    80005c14:	e54a                	sd	s2,136(sp)
    80005c16:	e94e                	sd	s3,144(sp)
    80005c18:	ed52                	sd	s4,152(sp)
    80005c1a:	f156                	sd	s5,160(sp)
    80005c1c:	f55a                	sd	s6,168(sp)
    80005c1e:	f95e                	sd	s7,176(sp)
    80005c20:	fd62                	sd	s8,184(sp)
    80005c22:	e1e6                	sd	s9,192(sp)
    80005c24:	e5ea                	sd	s10,200(sp)
    80005c26:	e9ee                	sd	s11,208(sp)
    80005c28:	edf2                	sd	t3,216(sp)
    80005c2a:	f1f6                	sd	t4,224(sp)
    80005c2c:	f5fa                	sd	t5,232(sp)
    80005c2e:	f9fe                	sd	t6,240(sp)
    80005c30:	cbdfc0ef          	jal	ra,800028ec <kerneltrap>
    80005c34:	6082                	ld	ra,0(sp)
    80005c36:	6122                	ld	sp,8(sp)
    80005c38:	61c2                	ld	gp,16(sp)
    80005c3a:	7282                	ld	t0,32(sp)
    80005c3c:	7322                	ld	t1,40(sp)
    80005c3e:	73c2                	ld	t2,48(sp)
    80005c40:	7462                	ld	s0,56(sp)
    80005c42:	6486                	ld	s1,64(sp)
    80005c44:	6526                	ld	a0,72(sp)
    80005c46:	65c6                	ld	a1,80(sp)
    80005c48:	6666                	ld	a2,88(sp)
    80005c4a:	7686                	ld	a3,96(sp)
    80005c4c:	7726                	ld	a4,104(sp)
    80005c4e:	77c6                	ld	a5,112(sp)
    80005c50:	7866                	ld	a6,120(sp)
    80005c52:	688a                	ld	a7,128(sp)
    80005c54:	692a                	ld	s2,136(sp)
    80005c56:	69ca                	ld	s3,144(sp)
    80005c58:	6a6a                	ld	s4,152(sp)
    80005c5a:	7a8a                	ld	s5,160(sp)
    80005c5c:	7b2a                	ld	s6,168(sp)
    80005c5e:	7bca                	ld	s7,176(sp)
    80005c60:	7c6a                	ld	s8,184(sp)
    80005c62:	6c8e                	ld	s9,192(sp)
    80005c64:	6d2e                	ld	s10,200(sp)
    80005c66:	6dce                	ld	s11,208(sp)
    80005c68:	6e6e                	ld	t3,216(sp)
    80005c6a:	7e8e                	ld	t4,224(sp)
    80005c6c:	7f2e                	ld	t5,232(sp)
    80005c6e:	7fce                	ld	t6,240(sp)
    80005c70:	6111                	addi	sp,sp,256
    80005c72:	10200073          	sret
    80005c76:	00000013          	nop
    80005c7a:	00000013          	nop
    80005c7e:	0001                	nop

0000000080005c80 <timervec>:
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	e10c                	sd	a1,0(a0)
    80005c86:	e510                	sd	a2,8(a0)
    80005c88:	e914                	sd	a3,16(a0)
    80005c8a:	6d0c                	ld	a1,24(a0)
    80005c8c:	7110                	ld	a2,32(a0)
    80005c8e:	6194                	ld	a3,0(a1)
    80005c90:	96b2                	add	a3,a3,a2
    80005c92:	e194                	sd	a3,0(a1)
    80005c94:	4589                	li	a1,2
    80005c96:	14459073          	csrw	sip,a1
    80005c9a:	6914                	ld	a3,16(a0)
    80005c9c:	6510                	ld	a2,8(a0)
    80005c9e:	610c                	ld	a1,0(a0)
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	30200073          	mret
	...

0000000080005caa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005caa:	1141                	addi	sp,sp,-16
    80005cac:	e422                	sd	s0,8(sp)
    80005cae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cb0:	0c0007b7          	lui	a5,0xc000
    80005cb4:	4705                	li	a4,1
    80005cb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cb8:	c3d8                	sw	a4,4(a5)
}
    80005cba:	6422                	ld	s0,8(sp)
    80005cbc:	0141                	addi	sp,sp,16
    80005cbe:	8082                	ret

0000000080005cc0 <plicinithart>:

void
plicinithart(void)
{
    80005cc0:	1141                	addi	sp,sp,-16
    80005cc2:	e406                	sd	ra,8(sp)
    80005cc4:	e022                	sd	s0,0(sp)
    80005cc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	c9e080e7          	jalr	-866(ra) # 80001966 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cd0:	0085171b          	slliw	a4,a0,0x8
    80005cd4:	0c0027b7          	lui	a5,0xc002
    80005cd8:	97ba                	add	a5,a5,a4
    80005cda:	40200713          	li	a4,1026
    80005cde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ce2:	00d5151b          	slliw	a0,a0,0xd
    80005ce6:	0c2017b7          	lui	a5,0xc201
    80005cea:	953e                	add	a0,a0,a5
    80005cec:	00052023          	sw	zero,0(a0)
}
    80005cf0:	60a2                	ld	ra,8(sp)
    80005cf2:	6402                	ld	s0,0(sp)
    80005cf4:	0141                	addi	sp,sp,16
    80005cf6:	8082                	ret

0000000080005cf8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cf8:	1141                	addi	sp,sp,-16
    80005cfa:	e406                	sd	ra,8(sp)
    80005cfc:	e022                	sd	s0,0(sp)
    80005cfe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	c66080e7          	jalr	-922(ra) # 80001966 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d08:	00d5179b          	slliw	a5,a0,0xd
    80005d0c:	0c201537          	lui	a0,0xc201
    80005d10:	953e                	add	a0,a0,a5
  return irq;
}
    80005d12:	4148                	lw	a0,4(a0)
    80005d14:	60a2                	ld	ra,8(sp)
    80005d16:	6402                	ld	s0,0(sp)
    80005d18:	0141                	addi	sp,sp,16
    80005d1a:	8082                	ret

0000000080005d1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d1c:	1101                	addi	sp,sp,-32
    80005d1e:	ec06                	sd	ra,24(sp)
    80005d20:	e822                	sd	s0,16(sp)
    80005d22:	e426                	sd	s1,8(sp)
    80005d24:	1000                	addi	s0,sp,32
    80005d26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	c3e080e7          	jalr	-962(ra) # 80001966 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d30:	00d5151b          	slliw	a0,a0,0xd
    80005d34:	0c2017b7          	lui	a5,0xc201
    80005d38:	97aa                	add	a5,a5,a0
    80005d3a:	c3c4                	sw	s1,4(a5)
}
    80005d3c:	60e2                	ld	ra,24(sp)
    80005d3e:	6442                	ld	s0,16(sp)
    80005d40:	64a2                	ld	s1,8(sp)
    80005d42:	6105                	addi	sp,sp,32
    80005d44:	8082                	ret

0000000080005d46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d46:	1141                	addi	sp,sp,-16
    80005d48:	e406                	sd	ra,8(sp)
    80005d4a:	e022                	sd	s0,0(sp)
    80005d4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d4e:	479d                	li	a5,7
    80005d50:	06a7c963          	blt	a5,a0,80005dc2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d54:	0001d797          	auipc	a5,0x1d
    80005d58:	2ac78793          	addi	a5,a5,684 # 80023000 <disk>
    80005d5c:	00a78733          	add	a4,a5,a0
    80005d60:	6789                	lui	a5,0x2
    80005d62:	97ba                	add	a5,a5,a4
    80005d64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d68:	e7ad                	bnez	a5,80005dd2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d6a:	00451793          	slli	a5,a0,0x4
    80005d6e:	0001f717          	auipc	a4,0x1f
    80005d72:	29270713          	addi	a4,a4,658 # 80025000 <disk+0x2000>
    80005d76:	6314                	ld	a3,0(a4)
    80005d78:	96be                	add	a3,a3,a5
    80005d7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d7e:	6314                	ld	a3,0(a4)
    80005d80:	96be                	add	a3,a3,a5
    80005d82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d86:	6314                	ld	a3,0(a4)
    80005d88:	96be                	add	a3,a3,a5
    80005d8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d8e:	6318                	ld	a4,0(a4)
    80005d90:	97ba                	add	a5,a5,a4
    80005d92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d96:	0001d797          	auipc	a5,0x1d
    80005d9a:	26a78793          	addi	a5,a5,618 # 80023000 <disk>
    80005d9e:	97aa                	add	a5,a5,a0
    80005da0:	6509                	lui	a0,0x2
    80005da2:	953e                	add	a0,a0,a5
    80005da4:	4785                	li	a5,1
    80005da6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005daa:	0001f517          	auipc	a0,0x1f
    80005dae:	26e50513          	addi	a0,a0,622 # 80025018 <disk+0x2018>
    80005db2:	ffffc097          	auipc	ra,0xffffc
    80005db6:	438080e7          	jalr	1080(ra) # 800021ea <wakeup>
}
    80005dba:	60a2                	ld	ra,8(sp)
    80005dbc:	6402                	ld	s0,0(sp)
    80005dbe:	0141                	addi	sp,sp,16
    80005dc0:	8082                	ret
    panic("free_desc 1");
    80005dc2:	00003517          	auipc	a0,0x3
    80005dc6:	bce50513          	addi	a0,a0,-1074 # 80008990 <syscalls_str+0x328>
    80005dca:	ffffa097          	auipc	ra,0xffffa
    80005dce:	760080e7          	jalr	1888(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005dd2:	00003517          	auipc	a0,0x3
    80005dd6:	bce50513          	addi	a0,a0,-1074 # 800089a0 <syscalls_str+0x338>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	750080e7          	jalr	1872(ra) # 8000052a <panic>

0000000080005de2 <virtio_disk_init>:
{
    80005de2:	1101                	addi	sp,sp,-32
    80005de4:	ec06                	sd	ra,24(sp)
    80005de6:	e822                	sd	s0,16(sp)
    80005de8:	e426                	sd	s1,8(sp)
    80005dea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dec:	00003597          	auipc	a1,0x3
    80005df0:	bc458593          	addi	a1,a1,-1084 # 800089b0 <syscalls_str+0x348>
    80005df4:	0001f517          	auipc	a0,0x1f
    80005df8:	33450513          	addi	a0,a0,820 # 80025128 <disk+0x2128>
    80005dfc:	ffffb097          	auipc	ra,0xffffb
    80005e00:	d36080e7          	jalr	-714(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e04:	100017b7          	lui	a5,0x10001
    80005e08:	4398                	lw	a4,0(a5)
    80005e0a:	2701                	sext.w	a4,a4
    80005e0c:	747277b7          	lui	a5,0x74727
    80005e10:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e14:	0ef71163          	bne	a4,a5,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e18:	100017b7          	lui	a5,0x10001
    80005e1c:	43dc                	lw	a5,4(a5)
    80005e1e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e20:	4705                	li	a4,1
    80005e22:	0ce79a63          	bne	a5,a4,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e26:	100017b7          	lui	a5,0x10001
    80005e2a:	479c                	lw	a5,8(a5)
    80005e2c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e2e:	4709                	li	a4,2
    80005e30:	0ce79363          	bne	a5,a4,80005ef6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e34:	100017b7          	lui	a5,0x10001
    80005e38:	47d8                	lw	a4,12(a5)
    80005e3a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3c:	554d47b7          	lui	a5,0x554d4
    80005e40:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e44:	0af71963          	bne	a4,a5,80005ef6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e48:	100017b7          	lui	a5,0x10001
    80005e4c:	4705                	li	a4,1
    80005e4e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e50:	470d                	li	a4,3
    80005e52:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e54:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e56:	c7ffe737          	lui	a4,0xc7ffe
    80005e5a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e5e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e60:	2701                	sext.w	a4,a4
    80005e62:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e64:	472d                	li	a4,11
    80005e66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e68:	473d                	li	a4,15
    80005e6a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e6c:	6705                	lui	a4,0x1
    80005e6e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e74:	5bdc                	lw	a5,52(a5)
    80005e76:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e78:	c7d9                	beqz	a5,80005f06 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e7a:	471d                	li	a4,7
    80005e7c:	08f77d63          	bgeu	a4,a5,80005f16 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e80:	100014b7          	lui	s1,0x10001
    80005e84:	47a1                	li	a5,8
    80005e86:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e88:	6609                	lui	a2,0x2
    80005e8a:	4581                	li	a1,0
    80005e8c:	0001d517          	auipc	a0,0x1d
    80005e90:	17450513          	addi	a0,a0,372 # 80023000 <disk>
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	e2a080e7          	jalr	-470(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e9c:	0001d717          	auipc	a4,0x1d
    80005ea0:	16470713          	addi	a4,a4,356 # 80023000 <disk>
    80005ea4:	00c75793          	srli	a5,a4,0xc
    80005ea8:	2781                	sext.w	a5,a5
    80005eaa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005eac:	0001f797          	auipc	a5,0x1f
    80005eb0:	15478793          	addi	a5,a5,340 # 80025000 <disk+0x2000>
    80005eb4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005eb6:	0001d717          	auipc	a4,0x1d
    80005eba:	1ca70713          	addi	a4,a4,458 # 80023080 <disk+0x80>
    80005ebe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005ec0:	0001e717          	auipc	a4,0x1e
    80005ec4:	14070713          	addi	a4,a4,320 # 80024000 <disk+0x1000>
    80005ec8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eca:	4705                	li	a4,1
    80005ecc:	00e78c23          	sb	a4,24(a5)
    80005ed0:	00e78ca3          	sb	a4,25(a5)
    80005ed4:	00e78d23          	sb	a4,26(a5)
    80005ed8:	00e78da3          	sb	a4,27(a5)
    80005edc:	00e78e23          	sb	a4,28(a5)
    80005ee0:	00e78ea3          	sb	a4,29(a5)
    80005ee4:	00e78f23          	sb	a4,30(a5)
    80005ee8:	00e78fa3          	sb	a4,31(a5)
}
    80005eec:	60e2                	ld	ra,24(sp)
    80005eee:	6442                	ld	s0,16(sp)
    80005ef0:	64a2                	ld	s1,8(sp)
    80005ef2:	6105                	addi	sp,sp,32
    80005ef4:	8082                	ret
    panic("could not find virtio disk");
    80005ef6:	00003517          	auipc	a0,0x3
    80005efa:	aca50513          	addi	a0,a0,-1334 # 800089c0 <syscalls_str+0x358>
    80005efe:	ffffa097          	auipc	ra,0xffffa
    80005f02:	62c080e7          	jalr	1580(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005f06:	00003517          	auipc	a0,0x3
    80005f0a:	ada50513          	addi	a0,a0,-1318 # 800089e0 <syscalls_str+0x378>
    80005f0e:	ffffa097          	auipc	ra,0xffffa
    80005f12:	61c080e7          	jalr	1564(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005f16:	00003517          	auipc	a0,0x3
    80005f1a:	aea50513          	addi	a0,a0,-1302 # 80008a00 <syscalls_str+0x398>
    80005f1e:	ffffa097          	auipc	ra,0xffffa
    80005f22:	60c080e7          	jalr	1548(ra) # 8000052a <panic>

0000000080005f26 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f26:	7119                	addi	sp,sp,-128
    80005f28:	fc86                	sd	ra,120(sp)
    80005f2a:	f8a2                	sd	s0,112(sp)
    80005f2c:	f4a6                	sd	s1,104(sp)
    80005f2e:	f0ca                	sd	s2,96(sp)
    80005f30:	ecce                	sd	s3,88(sp)
    80005f32:	e8d2                	sd	s4,80(sp)
    80005f34:	e4d6                	sd	s5,72(sp)
    80005f36:	e0da                	sd	s6,64(sp)
    80005f38:	fc5e                	sd	s7,56(sp)
    80005f3a:	f862                	sd	s8,48(sp)
    80005f3c:	f466                	sd	s9,40(sp)
    80005f3e:	f06a                	sd	s10,32(sp)
    80005f40:	ec6e                	sd	s11,24(sp)
    80005f42:	0100                	addi	s0,sp,128
    80005f44:	8aaa                	mv	s5,a0
    80005f46:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f48:	00c52c83          	lw	s9,12(a0)
    80005f4c:	001c9c9b          	slliw	s9,s9,0x1
    80005f50:	1c82                	slli	s9,s9,0x20
    80005f52:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f56:	0001f517          	auipc	a0,0x1f
    80005f5a:	1d250513          	addi	a0,a0,466 # 80025128 <disk+0x2128>
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	c64080e7          	jalr	-924(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005f66:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f68:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f6a:	0001dc17          	auipc	s8,0x1d
    80005f6e:	096c0c13          	addi	s8,s8,150 # 80023000 <disk>
    80005f72:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f74:	4b0d                	li	s6,3
    80005f76:	a0ad                	j	80005fe0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f78:	00fc0733          	add	a4,s8,a5
    80005f7c:	975e                	add	a4,a4,s7
    80005f7e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f82:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f84:	0207c563          	bltz	a5,80005fae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f88:	2905                	addiw	s2,s2,1
    80005f8a:	0611                	addi	a2,a2,4
    80005f8c:	19690d63          	beq	s2,s6,80006126 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f90:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f92:	0001f717          	auipc	a4,0x1f
    80005f96:	08670713          	addi	a4,a4,134 # 80025018 <disk+0x2018>
    80005f9a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f9c:	00074683          	lbu	a3,0(a4)
    80005fa0:	fee1                	bnez	a3,80005f78 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fa2:	2785                	addiw	a5,a5,1
    80005fa4:	0705                	addi	a4,a4,1
    80005fa6:	fe979be3          	bne	a5,s1,80005f9c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005faa:	57fd                	li	a5,-1
    80005fac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fae:	01205d63          	blez	s2,80005fc8 <virtio_disk_rw+0xa2>
    80005fb2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fb4:	000a2503          	lw	a0,0(s4)
    80005fb8:	00000097          	auipc	ra,0x0
    80005fbc:	d8e080e7          	jalr	-626(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fc0:	2d85                	addiw	s11,s11,1
    80005fc2:	0a11                	addi	s4,s4,4
    80005fc4:	ffb918e3          	bne	s2,s11,80005fb4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fc8:	0001f597          	auipc	a1,0x1f
    80005fcc:	16058593          	addi	a1,a1,352 # 80025128 <disk+0x2128>
    80005fd0:	0001f517          	auipc	a0,0x1f
    80005fd4:	04850513          	addi	a0,a0,72 # 80025018 <disk+0x2018>
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	086080e7          	jalr	134(ra) # 8000205e <sleep>
  for(int i = 0; i < 3; i++){
    80005fe0:	f8040a13          	addi	s4,s0,-128
{
    80005fe4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fe6:	894e                	mv	s2,s3
    80005fe8:	b765                	j	80005f90 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fea:	0001f697          	auipc	a3,0x1f
    80005fee:	0166b683          	ld	a3,22(a3) # 80025000 <disk+0x2000>
    80005ff2:	96ba                	add	a3,a3,a4
    80005ff4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ff8:	0001d817          	auipc	a6,0x1d
    80005ffc:	00880813          	addi	a6,a6,8 # 80023000 <disk>
    80006000:	0001f697          	auipc	a3,0x1f
    80006004:	00068693          	mv	a3,a3
    80006008:	6290                	ld	a2,0(a3)
    8000600a:	963a                	add	a2,a2,a4
    8000600c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006010:	0015e593          	ori	a1,a1,1
    80006014:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006018:	f8842603          	lw	a2,-120(s0)
    8000601c:	628c                	ld	a1,0(a3)
    8000601e:	972e                	add	a4,a4,a1
    80006020:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006024:	20050593          	addi	a1,a0,512
    80006028:	0592                	slli	a1,a1,0x4
    8000602a:	95c2                	add	a1,a1,a6
    8000602c:	577d                	li	a4,-1
    8000602e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006032:	00461713          	slli	a4,a2,0x4
    80006036:	6290                	ld	a2,0(a3)
    80006038:	963a                	add	a2,a2,a4
    8000603a:	03078793          	addi	a5,a5,48
    8000603e:	97c2                	add	a5,a5,a6
    80006040:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006042:	629c                	ld	a5,0(a3)
    80006044:	97ba                	add	a5,a5,a4
    80006046:	4605                	li	a2,1
    80006048:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000604a:	629c                	ld	a5,0(a3)
    8000604c:	97ba                	add	a5,a5,a4
    8000604e:	4809                	li	a6,2
    80006050:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006054:	629c                	ld	a5,0(a3)
    80006056:	973e                	add	a4,a4,a5
    80006058:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000605c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006060:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006064:	6698                	ld	a4,8(a3)
    80006066:	00275783          	lhu	a5,2(a4)
    8000606a:	8b9d                	andi	a5,a5,7
    8000606c:	0786                	slli	a5,a5,0x1
    8000606e:	97ba                	add	a5,a5,a4
    80006070:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006074:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006078:	6698                	ld	a4,8(a3)
    8000607a:	00275783          	lhu	a5,2(a4)
    8000607e:	2785                	addiw	a5,a5,1
    80006080:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006084:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006088:	100017b7          	lui	a5,0x10001
    8000608c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006090:	004aa783          	lw	a5,4(s5)
    80006094:	02c79163          	bne	a5,a2,800060b6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006098:	0001f917          	auipc	s2,0x1f
    8000609c:	09090913          	addi	s2,s2,144 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800060a0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060a2:	85ca                	mv	a1,s2
    800060a4:	8556                	mv	a0,s5
    800060a6:	ffffc097          	auipc	ra,0xffffc
    800060aa:	fb8080e7          	jalr	-72(ra) # 8000205e <sleep>
  while(b->disk == 1) {
    800060ae:	004aa783          	lw	a5,4(s5)
    800060b2:	fe9788e3          	beq	a5,s1,800060a2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060b6:	f8042903          	lw	s2,-128(s0)
    800060ba:	20090793          	addi	a5,s2,512
    800060be:	00479713          	slli	a4,a5,0x4
    800060c2:	0001d797          	auipc	a5,0x1d
    800060c6:	f3e78793          	addi	a5,a5,-194 # 80023000 <disk>
    800060ca:	97ba                	add	a5,a5,a4
    800060cc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060d0:	0001f997          	auipc	s3,0x1f
    800060d4:	f3098993          	addi	s3,s3,-208 # 80025000 <disk+0x2000>
    800060d8:	00491713          	slli	a4,s2,0x4
    800060dc:	0009b783          	ld	a5,0(s3)
    800060e0:	97ba                	add	a5,a5,a4
    800060e2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060e6:	854a                	mv	a0,s2
    800060e8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060ec:	00000097          	auipc	ra,0x0
    800060f0:	c5a080e7          	jalr	-934(ra) # 80005d46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060f4:	8885                	andi	s1,s1,1
    800060f6:	f0ed                	bnez	s1,800060d8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060f8:	0001f517          	auipc	a0,0x1f
    800060fc:	03050513          	addi	a0,a0,48 # 80025128 <disk+0x2128>
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	b76080e7          	jalr	-1162(ra) # 80000c76 <release>
}
    80006108:	70e6                	ld	ra,120(sp)
    8000610a:	7446                	ld	s0,112(sp)
    8000610c:	74a6                	ld	s1,104(sp)
    8000610e:	7906                	ld	s2,96(sp)
    80006110:	69e6                	ld	s3,88(sp)
    80006112:	6a46                	ld	s4,80(sp)
    80006114:	6aa6                	ld	s5,72(sp)
    80006116:	6b06                	ld	s6,64(sp)
    80006118:	7be2                	ld	s7,56(sp)
    8000611a:	7c42                	ld	s8,48(sp)
    8000611c:	7ca2                	ld	s9,40(sp)
    8000611e:	7d02                	ld	s10,32(sp)
    80006120:	6de2                	ld	s11,24(sp)
    80006122:	6109                	addi	sp,sp,128
    80006124:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006126:	f8042503          	lw	a0,-128(s0)
    8000612a:	20050793          	addi	a5,a0,512
    8000612e:	0792                	slli	a5,a5,0x4
  if(write)
    80006130:	0001d817          	auipc	a6,0x1d
    80006134:	ed080813          	addi	a6,a6,-304 # 80023000 <disk>
    80006138:	00f80733          	add	a4,a6,a5
    8000613c:	01a036b3          	snez	a3,s10
    80006140:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006144:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006148:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000614c:	7679                	lui	a2,0xffffe
    8000614e:	963e                	add	a2,a2,a5
    80006150:	0001f697          	auipc	a3,0x1f
    80006154:	eb068693          	addi	a3,a3,-336 # 80025000 <disk+0x2000>
    80006158:	6298                	ld	a4,0(a3)
    8000615a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000615c:	0a878593          	addi	a1,a5,168
    80006160:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006162:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006164:	6298                	ld	a4,0(a3)
    80006166:	9732                	add	a4,a4,a2
    80006168:	45c1                	li	a1,16
    8000616a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000616c:	6298                	ld	a4,0(a3)
    8000616e:	9732                	add	a4,a4,a2
    80006170:	4585                	li	a1,1
    80006172:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006176:	f8442703          	lw	a4,-124(s0)
    8000617a:	628c                	ld	a1,0(a3)
    8000617c:	962e                	add	a2,a2,a1
    8000617e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006182:	0712                	slli	a4,a4,0x4
    80006184:	6290                	ld	a2,0(a3)
    80006186:	963a                	add	a2,a2,a4
    80006188:	058a8593          	addi	a1,s5,88
    8000618c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000618e:	6294                	ld	a3,0(a3)
    80006190:	96ba                	add	a3,a3,a4
    80006192:	40000613          	li	a2,1024
    80006196:	c690                	sw	a2,8(a3)
  if(write)
    80006198:	e40d19e3          	bnez	s10,80005fea <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000619c:	0001f697          	auipc	a3,0x1f
    800061a0:	e646b683          	ld	a3,-412(a3) # 80025000 <disk+0x2000>
    800061a4:	96ba                	add	a3,a3,a4
    800061a6:	4609                	li	a2,2
    800061a8:	00c69623          	sh	a2,12(a3)
    800061ac:	b5b1                	j	80005ff8 <virtio_disk_rw+0xd2>

00000000800061ae <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061ae:	1101                	addi	sp,sp,-32
    800061b0:	ec06                	sd	ra,24(sp)
    800061b2:	e822                	sd	s0,16(sp)
    800061b4:	e426                	sd	s1,8(sp)
    800061b6:	e04a                	sd	s2,0(sp)
    800061b8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061ba:	0001f517          	auipc	a0,0x1f
    800061be:	f6e50513          	addi	a0,a0,-146 # 80025128 <disk+0x2128>
    800061c2:	ffffb097          	auipc	ra,0xffffb
    800061c6:	a00080e7          	jalr	-1536(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061ca:	10001737          	lui	a4,0x10001
    800061ce:	533c                	lw	a5,96(a4)
    800061d0:	8b8d                	andi	a5,a5,3
    800061d2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061d4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061d8:	0001f797          	auipc	a5,0x1f
    800061dc:	e2878793          	addi	a5,a5,-472 # 80025000 <disk+0x2000>
    800061e0:	6b94                	ld	a3,16(a5)
    800061e2:	0207d703          	lhu	a4,32(a5)
    800061e6:	0026d783          	lhu	a5,2(a3)
    800061ea:	06f70163          	beq	a4,a5,8000624c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061ee:	0001d917          	auipc	s2,0x1d
    800061f2:	e1290913          	addi	s2,s2,-494 # 80023000 <disk>
    800061f6:	0001f497          	auipc	s1,0x1f
    800061fa:	e0a48493          	addi	s1,s1,-502 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061fe:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006202:	6898                	ld	a4,16(s1)
    80006204:	0204d783          	lhu	a5,32(s1)
    80006208:	8b9d                	andi	a5,a5,7
    8000620a:	078e                	slli	a5,a5,0x3
    8000620c:	97ba                	add	a5,a5,a4
    8000620e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006210:	20078713          	addi	a4,a5,512
    80006214:	0712                	slli	a4,a4,0x4
    80006216:	974a                	add	a4,a4,s2
    80006218:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000621c:	e731                	bnez	a4,80006268 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000621e:	20078793          	addi	a5,a5,512
    80006222:	0792                	slli	a5,a5,0x4
    80006224:	97ca                	add	a5,a5,s2
    80006226:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006228:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000622c:	ffffc097          	auipc	ra,0xffffc
    80006230:	fbe080e7          	jalr	-66(ra) # 800021ea <wakeup>

    disk.used_idx += 1;
    80006234:	0204d783          	lhu	a5,32(s1)
    80006238:	2785                	addiw	a5,a5,1
    8000623a:	17c2                	slli	a5,a5,0x30
    8000623c:	93c1                	srli	a5,a5,0x30
    8000623e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006242:	6898                	ld	a4,16(s1)
    80006244:	00275703          	lhu	a4,2(a4)
    80006248:	faf71be3          	bne	a4,a5,800061fe <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000624c:	0001f517          	auipc	a0,0x1f
    80006250:	edc50513          	addi	a0,a0,-292 # 80025128 <disk+0x2128>
    80006254:	ffffb097          	auipc	ra,0xffffb
    80006258:	a22080e7          	jalr	-1502(ra) # 80000c76 <release>
}
    8000625c:	60e2                	ld	ra,24(sp)
    8000625e:	6442                	ld	s0,16(sp)
    80006260:	64a2                	ld	s1,8(sp)
    80006262:	6902                	ld	s2,0(sp)
    80006264:	6105                	addi	sp,sp,32
    80006266:	8082                	ret
      panic("virtio_disk_intr status");
    80006268:	00002517          	auipc	a0,0x2
    8000626c:	7b850513          	addi	a0,a0,1976 # 80008a20 <syscalls_str+0x3b8>
    80006270:	ffffa097          	auipc	ra,0xffffa
    80006274:	2ba080e7          	jalr	698(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
