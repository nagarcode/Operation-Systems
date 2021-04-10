
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
    80000068:	cfc78793          	addi	a5,a5,-772 # 80005d60 <timervec>
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
    80000122:	400080e7          	jalr	1024(ra) # 8000251e <either_copyin>
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
    800001c6:	eca080e7          	jalr	-310(ra) # 8000208c <sleep>
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
    80000202:	2ca080e7          	jalr	714(ra) # 800024c8 <either_copyout>
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
    800002e2:	296080e7          	jalr	662(ra) # 80002574 <procdump>
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
    80000436:	de6080e7          	jalr	-538(ra) # 80002218 <wakeup>
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
    80000468:	0b478793          	addi	a5,a5,180 # 80021518 <devsw>
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
    80000882:	99a080e7          	jalr	-1638(ra) # 80002218 <wakeup>
    
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
    8000090e:	782080e7          	jalr	1922(ra) # 8000208c <sleep>
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
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	804080e7          	jalr	-2044(ra) # 800026b6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	ee6080e7          	jalr	-282(ra) # 80005da0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	018080e7          	jalr	24(ra) # 80001eda <scheduler>
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
    80000f2e:	764080e7          	jalr	1892(ra) # 8000268e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	784080e7          	jalr	1924(ra) # 800026b6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	e50080e7          	jalr	-432(ra) # 80005d8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	e5e080e7          	jalr	-418(ra) # 80005da0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	02c080e7          	jalr	44(ra) # 80002f76 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	6be080e7          	jalr	1726(ra) # 80003610 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	66c080e7          	jalr	1644(ra) # 800045c6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f60080e7          	jalr	-160(ra) # 80005ec2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d32080e7          	jalr	-718(ra) # 80001c9c <userinit>
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
    80001854:	a80a0a13          	addi	s4,s4,-1408 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001858:	fffff097          	auipc	ra,0xfffff
    8000185c:	27a080e7          	jalr	634(ra) # 80000ad2 <kalloc>
    80001860:	862a                	mv	a2,a0
    if (pa == 0)
    80001862:	c131                	beqz	a0,800018a6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001864:	416485b3          	sub	a1,s1,s6
    80001868:	8591                	srai	a1,a1,0x4
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
    8000188a:	17048493          	addi	s1,s1,368
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
    8000191c:	00016997          	auipc	s3,0x16
    80001920:	9b498993          	addi	s3,s3,-1612 # 800172d0 <tickslock>
    initlock(&p->lock, "proc");
    80001924:	85da                	mv	a1,s6
    80001926:	8526                	mv	a0,s1
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	20a080e7          	jalr	522(ra) # 80000b32 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001930:	415487b3          	sub	a5,s1,s5
    80001934:	8791                	srai	a5,a5,0x4
    80001936:	000a3703          	ld	a4,0(s4)
    8000193a:	02e787b3          	mul	a5,a5,a4
    8000193e:	2785                	addiw	a5,a5,1
    80001940:	00d7979b          	slliw	a5,a5,0xd
    80001944:	40f907b3          	sub	a5,s2,a5
    80001948:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000194a:	17048493          	addi	s1,s1,368
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
    800019f0:	ce2080e7          	jalr	-798(ra) # 800026ce <usertrapret>
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
    80001a0a:	b8a080e7          	jalr	-1142(ra) # 80003590 <fsinit>
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
    80001bb4:	72090913          	addi	s2,s2,1824 # 800172d0 <tickslock>
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
    80001bd0:	17048493          	addi	s1,s1,368
    80001bd4:	ff2492e3          	bne	s1,s2,80001bb8 <allocproc+0x1c>
  return 0;
    80001bd8:	4481                	li	s1,0
    80001bda:	a051                	j	80001c5e <allocproc+0xc2>
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
    80001bf6:	c93d                	beqz	a0,80001c6c <allocproc+0xd0>
  p->pagetable = proc_pagetable(p);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e5c080e7          	jalr	-420(ra) # 80001a56 <proc_pagetable>
    80001c02:	892a                	mv	s2,a0
    80001c04:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c06:	cd3d                	beqz	a0,80001c84 <allocproc+0xe8>
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
  acquire(&tickslock);
    80001c30:	00015517          	auipc	a0,0x15
    80001c34:	6a050513          	addi	a0,a0,1696 # 800172d0 <tickslock>
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	f8a080e7          	jalr	-118(ra) # 80000bc2 <acquire>
  p->performance->ctime = ticks;
    80001c40:	1684b783          	ld	a5,360(s1)
    80001c44:	00007717          	auipc	a4,0x7
    80001c48:	3ec72703          	lw	a4,1004(a4) # 80009030 <ticks>
    80001c4c:	c398                	sw	a4,0(a5)
  release(&tickslock);
    80001c4e:	00015517          	auipc	a0,0x15
    80001c52:	68250513          	addi	a0,a0,1666 # 800172d0 <tickslock>
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	020080e7          	jalr	32(ra) # 80000c76 <release>
}
    80001c5e:	8526                	mv	a0,s1
    80001c60:	60e2                	ld	ra,24(sp)
    80001c62:	6442                	ld	s0,16(sp)
    80001c64:	64a2                	ld	s1,8(sp)
    80001c66:	6902                	ld	s2,0(sp)
    80001c68:	6105                	addi	sp,sp,32
    80001c6a:	8082                	ret
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ed6080e7          	jalr	-298(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	ffe080e7          	jalr	-2(ra) # 80000c76 <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	bff1                	j	80001c5e <allocproc+0xc2>
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	ebe080e7          	jalr	-322(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	fe6080e7          	jalr	-26(ra) # 80000c76 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	b7d1                	j	80001c5e <allocproc+0xc2>

0000000080001c9c <userinit>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	ef6080e7          	jalr	-266(ra) # 80001b9c <allocproc>
    80001cae:	84aa                	mv	s1,a0
  initproc = p;
    80001cb0:	00007797          	auipc	a5,0x7
    80001cb4:	36a7bc23          	sd	a0,888(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb8:	03400613          	li	a2,52
    80001cbc:	00007597          	auipc	a1,0x7
    80001cc0:	d9458593          	addi	a1,a1,-620 # 80008a50 <initcode>
    80001cc4:	6928                	ld	a0,80(a0)
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	66e080e7          	jalr	1646(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001cce:	6785                	lui	a5,0x1
    80001cd0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cd2:	6cb8                	ld	a4,88(s1)
    80001cd4:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cd8:	6cb8                	ld	a4,88(s1)
    80001cda:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cdc:	4641                	li	a2,16
    80001cde:	00006597          	auipc	a1,0x6
    80001ce2:	50a58593          	addi	a1,a1,1290 # 800081e8 <digits+0x1a8>
    80001ce6:	15848513          	addi	a0,s1,344
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	126080e7          	jalr	294(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cf2:	00006517          	auipc	a0,0x6
    80001cf6:	50650513          	addi	a0,a0,1286 # 800081f8 <digits+0x1b8>
    80001cfa:	00002097          	auipc	ra,0x2
    80001cfe:	2c4080e7          	jalr	708(ra) # 80003fbe <namei>
    80001d02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d06:	478d                	li	a5,3
    80001d08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f6a080e7          	jalr	-150(ra) # 80000c76 <release>
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	addi	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <growproc>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
    80001d2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	c66080e7          	jalr	-922(ra) # 80001992 <myproc>
    80001d34:	892a                	mv	s2,a0
  sz = p->sz;
    80001d36:	652c                	ld	a1,72(a0)
    80001d38:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d3c:	00904f63          	bgtz	s1,80001d5a <growproc+0x3c>
  else if (n < 0)
    80001d40:	0204cc63          	bltz	s1,80001d78 <growproc+0x5a>
  p->sz = sz;
    80001d44:	1602                	slli	a2,a2,0x20
    80001d46:	9201                	srli	a2,a2,0x20
    80001d48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d5a:	9e25                	addw	a2,a2,s1
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	1582                	slli	a1,a1,0x20
    80001d62:	9181                	srli	a1,a1,0x20
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	688080e7          	jalr	1672(ra) # 800013ee <uvmalloc>
    80001d6e:	0005061b          	sext.w	a2,a0
    80001d72:	fa69                	bnez	a2,80001d44 <growproc+0x26>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bfe1                	j	80001d4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	9e25                	addw	a2,a2,s1
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	622080e7          	jalr	1570(ra) # 800013a6 <uvmdealloc>
    80001d8c:	0005061b          	sext.w	a2,a0
    80001d90:	bf55                	j	80001d44 <growproc+0x26>

0000000080001d92 <fork>:
{
    80001d92:	7139                	addi	sp,sp,-64
    80001d94:	fc06                	sd	ra,56(sp)
    80001d96:	f822                	sd	s0,48(sp)
    80001d98:	f426                	sd	s1,40(sp)
    80001d9a:	f04a                	sd	s2,32(sp)
    80001d9c:	ec4e                	sd	s3,24(sp)
    80001d9e:	e852                	sd	s4,16(sp)
    80001da0:	e456                	sd	s5,8(sp)
    80001da2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	bee080e7          	jalr	-1042(ra) # 80001992 <myproc>
    80001dac:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	dee080e7          	jalr	-530(ra) # 80001b9c <allocproc>
    80001db6:	12050063          	beqz	a0,80001ed6 <fork+0x144>
    80001dba:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dbc:	048ab603          	ld	a2,72(s5)
    80001dc0:	692c                	ld	a1,80(a0)
    80001dc2:	050ab503          	ld	a0,80(s5)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	774080e7          	jalr	1908(ra) # 8000153a <uvmcopy>
    80001dce:	04054863          	bltz	a0,80001e1e <fork+0x8c>
  np->sz = p->sz;
    80001dd2:	048ab783          	ld	a5,72(s5)
    80001dd6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dda:	058ab683          	ld	a3,88(s5)
    80001dde:	87b6                	mv	a5,a3
    80001de0:	0589b703          	ld	a4,88(s3)
    80001de4:	12068693          	addi	a3,a3,288
    80001de8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dec:	6788                	ld	a0,8(a5)
    80001dee:	6b8c                	ld	a1,16(a5)
    80001df0:	6f90                	ld	a2,24(a5)
    80001df2:	01073023          	sd	a6,0(a4)
    80001df6:	e708                	sd	a0,8(a4)
    80001df8:	eb0c                	sd	a1,16(a4)
    80001dfa:	ef10                	sd	a2,24(a4)
    80001dfc:	02078793          	addi	a5,a5,32
    80001e00:	02070713          	addi	a4,a4,32
    80001e04:	fed792e3          	bne	a5,a3,80001de8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e08:	0589b783          	ld	a5,88(s3)
    80001e0c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e10:	0d0a8493          	addi	s1,s5,208
    80001e14:	0d098913          	addi	s2,s3,208
    80001e18:	150a8a13          	addi	s4,s5,336
    80001e1c:	a00d                	j	80001e3e <fork+0xac>
    freeproc(np);
    80001e1e:	854e                	mv	a0,s3
    80001e20:	00000097          	auipc	ra,0x0
    80001e24:	d24080e7          	jalr	-732(ra) # 80001b44 <freeproc>
    release(&np->lock);
    80001e28:	854e                	mv	a0,s3
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	e4c080e7          	jalr	-436(ra) # 80000c76 <release>
    return -1;
    80001e32:	597d                	li	s2,-1
    80001e34:	a079                	j	80001ec2 <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80001e36:	04a1                	addi	s1,s1,8
    80001e38:	0921                	addi	s2,s2,8
    80001e3a:	01448b63          	beq	s1,s4,80001e50 <fork+0xbe>
    if (p->ofile[i])
    80001e3e:	6088                	ld	a0,0(s1)
    80001e40:	d97d                	beqz	a0,80001e36 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e42:	00003097          	auipc	ra,0x3
    80001e46:	816080e7          	jalr	-2026(ra) # 80004658 <filedup>
    80001e4a:	00a93023          	sd	a0,0(s2)
    80001e4e:	b7e5                	j	80001e36 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e50:	150ab503          	ld	a0,336(s5)
    80001e54:	00002097          	auipc	ra,0x2
    80001e58:	976080e7          	jalr	-1674(ra) # 800037ca <idup>
    80001e5c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e60:	4641                	li	a2,16
    80001e62:	158a8593          	addi	a1,s5,344
    80001e66:	15898513          	addi	a0,s3,344
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	fa6080e7          	jalr	-90(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e72:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e76:	854e                	mv	a0,s3
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	dfe080e7          	jalr	-514(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e80:	0000f497          	auipc	s1,0xf
    80001e84:	43848493          	addi	s1,s1,1080 # 800112b8 <wait_lock>
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d38080e7          	jalr	-712(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e92:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	dde080e7          	jalr	-546(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	d20080e7          	jalr	-736(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001eaa:	478d                	li	a5,3
    80001eac:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb0:	854e                	mv	a0,s3
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	dc4080e7          	jalr	-572(ra) # 80000c76 <release>
  np->traceMask = p->traceMask;
    80001eba:	034aa783          	lw	a5,52(s5)
    80001ebe:	02f9aa23          	sw	a5,52(s3)
}
    80001ec2:	854a                	mv	a0,s2
    80001ec4:	70e2                	ld	ra,56(sp)
    80001ec6:	7442                	ld	s0,48(sp)
    80001ec8:	74a2                	ld	s1,40(sp)
    80001eca:	7902                	ld	s2,32(sp)
    80001ecc:	69e2                	ld	s3,24(sp)
    80001ece:	6a42                	ld	s4,16(sp)
    80001ed0:	6aa2                	ld	s5,8(sp)
    80001ed2:	6121                	addi	sp,sp,64
    80001ed4:	8082                	ret
    return -1;
    80001ed6:	597d                	li	s2,-1
    80001ed8:	b7ed                	j	80001ec2 <fork+0x130>

0000000080001eda <scheduler>:
{
    80001eda:	7139                	addi	sp,sp,-64
    80001edc:	fc06                	sd	ra,56(sp)
    80001ede:	f822                	sd	s0,48(sp)
    80001ee0:	f426                	sd	s1,40(sp)
    80001ee2:	f04a                	sd	s2,32(sp)
    80001ee4:	ec4e                	sd	s3,24(sp)
    80001ee6:	e852                	sd	s4,16(sp)
    80001ee8:	e456                	sd	s5,8(sp)
    80001eea:	e05a                	sd	s6,0(sp)
    80001eec:	0080                	addi	s0,sp,64
    80001eee:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ef2:	00779a93          	slli	s5,a5,0x7
    80001ef6:	0000f717          	auipc	a4,0xf
    80001efa:	3aa70713          	addi	a4,a4,938 # 800112a0 <pid_lock>
    80001efe:	9756                	add	a4,a4,s5
    80001f00:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f04:	0000f717          	auipc	a4,0xf
    80001f08:	3d470713          	addi	a4,a4,980 # 800112d8 <cpus+0x8>
    80001f0c:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f0e:	498d                	li	s3,3
        p->state = RUNNING;
    80001f10:	4b11                	li	s6,4
        c->proc = p;
    80001f12:	079e                	slli	a5,a5,0x7
    80001f14:	0000fa17          	auipc	s4,0xf
    80001f18:	38ca0a13          	addi	s4,s4,908 # 800112a0 <pid_lock>
    80001f1c:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f1e:	00015917          	auipc	s2,0x15
    80001f22:	3b290913          	addi	s2,s2,946 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f2a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f2e:	10079073          	csrw	sstatus,a5
    80001f32:	0000f497          	auipc	s1,0xf
    80001f36:	79e48493          	addi	s1,s1,1950 # 800116d0 <proc>
    80001f3a:	a811                	j	80001f4e <scheduler+0x74>
      release(&p->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	d38080e7          	jalr	-712(ra) # 80000c76 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f46:	17048493          	addi	s1,s1,368
    80001f4a:	fd248ee3          	beq	s1,s2,80001f26 <scheduler+0x4c>
      acquire(&p->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	c72080e7          	jalr	-910(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    80001f58:	4c9c                	lw	a5,24(s1)
    80001f5a:	ff3791e3          	bne	a5,s3,80001f3c <scheduler+0x62>
        p->state = RUNNING;
    80001f5e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f62:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f66:	06048593          	addi	a1,s1,96
    80001f6a:	8556                	mv	a0,s5
    80001f6c:	00000097          	auipc	ra,0x0
    80001f70:	6b8080e7          	jalr	1720(ra) # 80002624 <swtch>
        c->proc = 0;
    80001f74:	020a3823          	sd	zero,48(s4)
    80001f78:	b7d1                	j	80001f3c <scheduler+0x62>

0000000080001f7a <sched>:
{
    80001f7a:	7179                	addi	sp,sp,-48
    80001f7c:	f406                	sd	ra,40(sp)
    80001f7e:	f022                	sd	s0,32(sp)
    80001f80:	ec26                	sd	s1,24(sp)
    80001f82:	e84a                	sd	s2,16(sp)
    80001f84:	e44e                	sd	s3,8(sp)
    80001f86:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	a0a080e7          	jalr	-1526(ra) # 80001992 <myproc>
    80001f90:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	bb6080e7          	jalr	-1098(ra) # 80000b48 <holding>
    80001f9a:	c93d                	beqz	a0,80002010 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f9c:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f9e:	2781                	sext.w	a5,a5
    80001fa0:	079e                	slli	a5,a5,0x7
    80001fa2:	0000f717          	auipc	a4,0xf
    80001fa6:	2fe70713          	addi	a4,a4,766 # 800112a0 <pid_lock>
    80001faa:	97ba                	add	a5,a5,a4
    80001fac:	0a87a703          	lw	a4,168(a5)
    80001fb0:	4785                	li	a5,1
    80001fb2:	06f71763          	bne	a4,a5,80002020 <sched+0xa6>
  if (p->state == RUNNING)
    80001fb6:	4c98                	lw	a4,24(s1)
    80001fb8:	4791                	li	a5,4
    80001fba:	06f70b63          	beq	a4,a5,80002030 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fc2:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fc4:	efb5                	bnez	a5,80002040 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fc6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fc8:	0000f917          	auipc	s2,0xf
    80001fcc:	2d890913          	addi	s2,s2,728 # 800112a0 <pid_lock>
    80001fd0:	2781                	sext.w	a5,a5
    80001fd2:	079e                	slli	a5,a5,0x7
    80001fd4:	97ca                	add	a5,a5,s2
    80001fd6:	0ac7a983          	lw	s3,172(a5)
    80001fda:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fdc:	2781                	sext.w	a5,a5
    80001fde:	079e                	slli	a5,a5,0x7
    80001fe0:	0000f597          	auipc	a1,0xf
    80001fe4:	2f858593          	addi	a1,a1,760 # 800112d8 <cpus+0x8>
    80001fe8:	95be                	add	a1,a1,a5
    80001fea:	06048513          	addi	a0,s1,96
    80001fee:	00000097          	auipc	ra,0x0
    80001ff2:	636080e7          	jalr	1590(ra) # 80002624 <swtch>
    80001ff6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ff8:	2781                	sext.w	a5,a5
    80001ffa:	079e                	slli	a5,a5,0x7
    80001ffc:	97ca                	add	a5,a5,s2
    80001ffe:	0b37a623          	sw	s3,172(a5)
}
    80002002:	70a2                	ld	ra,40(sp)
    80002004:	7402                	ld	s0,32(sp)
    80002006:	64e2                	ld	s1,24(sp)
    80002008:	6942                	ld	s2,16(sp)
    8000200a:	69a2                	ld	s3,8(sp)
    8000200c:	6145                	addi	sp,sp,48
    8000200e:	8082                	ret
    panic("sched p->lock");
    80002010:	00006517          	auipc	a0,0x6
    80002014:	1f050513          	addi	a0,a0,496 # 80008200 <digits+0x1c0>
    80002018:	ffffe097          	auipc	ra,0xffffe
    8000201c:	512080e7          	jalr	1298(ra) # 8000052a <panic>
    panic("sched locks");
    80002020:	00006517          	auipc	a0,0x6
    80002024:	1f050513          	addi	a0,a0,496 # 80008210 <digits+0x1d0>
    80002028:	ffffe097          	auipc	ra,0xffffe
    8000202c:	502080e7          	jalr	1282(ra) # 8000052a <panic>
    panic("sched running");
    80002030:	00006517          	auipc	a0,0x6
    80002034:	1f050513          	addi	a0,a0,496 # 80008220 <digits+0x1e0>
    80002038:	ffffe097          	auipc	ra,0xffffe
    8000203c:	4f2080e7          	jalr	1266(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	1f050513          	addi	a0,a0,496 # 80008230 <digits+0x1f0>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4e2080e7          	jalr	1250(ra) # 8000052a <panic>

0000000080002050 <yield>:
{
    80002050:	1101                	addi	sp,sp,-32
    80002052:	ec06                	sd	ra,24(sp)
    80002054:	e822                	sd	s0,16(sp)
    80002056:	e426                	sd	s1,8(sp)
    80002058:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	938080e7          	jalr	-1736(ra) # 80001992 <myproc>
    80002062:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	b5e080e7          	jalr	-1186(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000206c:	478d                	li	a5,3
    8000206e:	cc9c                	sw	a5,24(s1)
  sched();
    80002070:	00000097          	auipc	ra,0x0
    80002074:	f0a080e7          	jalr	-246(ra) # 80001f7a <sched>
  release(&p->lock);
    80002078:	8526                	mv	a0,s1
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	bfc080e7          	jalr	-1028(ra) # 80000c76 <release>
}
    80002082:	60e2                	ld	ra,24(sp)
    80002084:	6442                	ld	s0,16(sp)
    80002086:	64a2                	ld	s1,8(sp)
    80002088:	6105                	addi	sp,sp,32
    8000208a:	8082                	ret

000000008000208c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000208c:	7179                	addi	sp,sp,-48
    8000208e:	f406                	sd	ra,40(sp)
    80002090:	f022                	sd	s0,32(sp)
    80002092:	ec26                	sd	s1,24(sp)
    80002094:	e84a                	sd	s2,16(sp)
    80002096:	e44e                	sd	s3,8(sp)
    80002098:	1800                	addi	s0,sp,48
    8000209a:	89aa                	mv	s3,a0
    8000209c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	8f4080e7          	jalr	-1804(ra) # 80001992 <myproc>
    800020a6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	b1a080e7          	jalr	-1254(ra) # 80000bc2 <acquire>
  release(lk);
    800020b0:	854a                	mv	a0,s2
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	bc4080e7          	jalr	-1084(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020ba:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020be:	4789                	li	a5,2
    800020c0:	cc9c                	sw	a5,24(s1)

  sched();
    800020c2:	00000097          	auipc	ra,0x0
    800020c6:	eb8080e7          	jalr	-328(ra) # 80001f7a <sched>

  // Tidy up.
  p->chan = 0;
    800020ca:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ce:	8526                	mv	a0,s1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	ba6080e7          	jalr	-1114(ra) # 80000c76 <release>
  acquire(lk);
    800020d8:	854a                	mv	a0,s2
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	ae8080e7          	jalr	-1304(ra) # 80000bc2 <acquire>
}
    800020e2:	70a2                	ld	ra,40(sp)
    800020e4:	7402                	ld	s0,32(sp)
    800020e6:	64e2                	ld	s1,24(sp)
    800020e8:	6942                	ld	s2,16(sp)
    800020ea:	69a2                	ld	s3,8(sp)
    800020ec:	6145                	addi	sp,sp,48
    800020ee:	8082                	ret

00000000800020f0 <wait>:
{
    800020f0:	715d                	addi	sp,sp,-80
    800020f2:	e486                	sd	ra,72(sp)
    800020f4:	e0a2                	sd	s0,64(sp)
    800020f6:	fc26                	sd	s1,56(sp)
    800020f8:	f84a                	sd	s2,48(sp)
    800020fa:	f44e                	sd	s3,40(sp)
    800020fc:	f052                	sd	s4,32(sp)
    800020fe:	ec56                	sd	s5,24(sp)
    80002100:	e85a                	sd	s6,16(sp)
    80002102:	e45e                	sd	s7,8(sp)
    80002104:	e062                	sd	s8,0(sp)
    80002106:	0880                	addi	s0,sp,80
    80002108:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000210a:	00000097          	auipc	ra,0x0
    8000210e:	888080e7          	jalr	-1912(ra) # 80001992 <myproc>
    80002112:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002114:	0000f517          	auipc	a0,0xf
    80002118:	1a450513          	addi	a0,a0,420 # 800112b8 <wait_lock>
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	aa6080e7          	jalr	-1370(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002124:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002126:	4a15                	li	s4,5
        havekids = 1;
    80002128:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000212a:	00015997          	auipc	s3,0x15
    8000212e:	1a698993          	addi	s3,s3,422 # 800172d0 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002132:	0000fc17          	auipc	s8,0xf
    80002136:	186c0c13          	addi	s8,s8,390 # 800112b8 <wait_lock>
    havekids = 0;
    8000213a:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000213c:	0000f497          	auipc	s1,0xf
    80002140:	59448493          	addi	s1,s1,1428 # 800116d0 <proc>
    80002144:	a0bd                	j	800021b2 <wait+0xc2>
          pid = np->pid;
    80002146:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000214a:	000b0e63          	beqz	s6,80002166 <wait+0x76>
    8000214e:	4691                	li	a3,4
    80002150:	02c48613          	addi	a2,s1,44
    80002154:	85da                	mv	a1,s6
    80002156:	05093503          	ld	a0,80(s2)
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	4e4080e7          	jalr	1252(ra) # 8000163e <copyout>
    80002162:	02054563          	bltz	a0,8000218c <wait+0x9c>
          freeproc(np);
    80002166:	8526                	mv	a0,s1
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	9dc080e7          	jalr	-1572(ra) # 80001b44 <freeproc>
          release(&np->lock);
    80002170:	8526                	mv	a0,s1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	b04080e7          	jalr	-1276(ra) # 80000c76 <release>
          release(&wait_lock);
    8000217a:	0000f517          	auipc	a0,0xf
    8000217e:	13e50513          	addi	a0,a0,318 # 800112b8 <wait_lock>
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	af4080e7          	jalr	-1292(ra) # 80000c76 <release>
          return pid;
    8000218a:	a09d                	j	800021f0 <wait+0x100>
            release(&np->lock);
    8000218c:	8526                	mv	a0,s1
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	ae8080e7          	jalr	-1304(ra) # 80000c76 <release>
            release(&wait_lock);
    80002196:	0000f517          	auipc	a0,0xf
    8000219a:	12250513          	addi	a0,a0,290 # 800112b8 <wait_lock>
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	ad8080e7          	jalr	-1320(ra) # 80000c76 <release>
            return -1;
    800021a6:	59fd                	li	s3,-1
    800021a8:	a0a1                	j	800021f0 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800021aa:	17048493          	addi	s1,s1,368
    800021ae:	03348463          	beq	s1,s3,800021d6 <wait+0xe6>
      if (np->parent == p)
    800021b2:	7c9c                	ld	a5,56(s1)
    800021b4:	ff279be3          	bne	a5,s2,800021aa <wait+0xba>
        acquire(&np->lock);
    800021b8:	8526                	mv	a0,s1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	a08080e7          	jalr	-1528(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    800021c2:	4c9c                	lw	a5,24(s1)
    800021c4:	f94781e3          	beq	a5,s4,80002146 <wait+0x56>
        release(&np->lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	aac080e7          	jalr	-1364(ra) # 80000c76 <release>
        havekids = 1;
    800021d2:	8756                	mv	a4,s5
    800021d4:	bfd9                	j	800021aa <wait+0xba>
    if (!havekids || p->killed)
    800021d6:	c701                	beqz	a4,800021de <wait+0xee>
    800021d8:	02892783          	lw	a5,40(s2)
    800021dc:	c79d                	beqz	a5,8000220a <wait+0x11a>
      release(&wait_lock);
    800021de:	0000f517          	auipc	a0,0xf
    800021e2:	0da50513          	addi	a0,a0,218 # 800112b8 <wait_lock>
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	a90080e7          	jalr	-1392(ra) # 80000c76 <release>
      return -1;
    800021ee:	59fd                	li	s3,-1
}
    800021f0:	854e                	mv	a0,s3
    800021f2:	60a6                	ld	ra,72(sp)
    800021f4:	6406                	ld	s0,64(sp)
    800021f6:	74e2                	ld	s1,56(sp)
    800021f8:	7942                	ld	s2,48(sp)
    800021fa:	79a2                	ld	s3,40(sp)
    800021fc:	7a02                	ld	s4,32(sp)
    800021fe:	6ae2                	ld	s5,24(sp)
    80002200:	6b42                	ld	s6,16(sp)
    80002202:	6ba2                	ld	s7,8(sp)
    80002204:	6c02                	ld	s8,0(sp)
    80002206:	6161                	addi	sp,sp,80
    80002208:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000220a:	85e2                	mv	a1,s8
    8000220c:	854a                	mv	a0,s2
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	e7e080e7          	jalr	-386(ra) # 8000208c <sleep>
    havekids = 0;
    80002216:	b715                	j	8000213a <wait+0x4a>

0000000080002218 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002218:	7139                	addi	sp,sp,-64
    8000221a:	fc06                	sd	ra,56(sp)
    8000221c:	f822                	sd	s0,48(sp)
    8000221e:	f426                	sd	s1,40(sp)
    80002220:	f04a                	sd	s2,32(sp)
    80002222:	ec4e                	sd	s3,24(sp)
    80002224:	e852                	sd	s4,16(sp)
    80002226:	e456                	sd	s5,8(sp)
    80002228:	0080                	addi	s0,sp,64
    8000222a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000222c:	0000f497          	auipc	s1,0xf
    80002230:	4a448493          	addi	s1,s1,1188 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002234:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002236:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002238:	00015917          	auipc	s2,0x15
    8000223c:	09890913          	addi	s2,s2,152 # 800172d0 <tickslock>
    80002240:	a811                	j	80002254 <wakeup+0x3c>
      }
      release(&p->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a32080e7          	jalr	-1486(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000224c:	17048493          	addi	s1,s1,368
    80002250:	03248663          	beq	s1,s2,8000227c <wakeup+0x64>
    if (p != myproc())
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	73e080e7          	jalr	1854(ra) # 80001992 <myproc>
    8000225c:	fea488e3          	beq	s1,a0,8000224c <wakeup+0x34>
      acquire(&p->lock);
    80002260:	8526                	mv	a0,s1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	960080e7          	jalr	-1696(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000226a:	4c9c                	lw	a5,24(s1)
    8000226c:	fd379be3          	bne	a5,s3,80002242 <wakeup+0x2a>
    80002270:	709c                	ld	a5,32(s1)
    80002272:	fd4798e3          	bne	a5,s4,80002242 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002276:	0154ac23          	sw	s5,24(s1)
    8000227a:	b7e1                	j	80002242 <wakeup+0x2a>
    }
  }
}
    8000227c:	70e2                	ld	ra,56(sp)
    8000227e:	7442                	ld	s0,48(sp)
    80002280:	74a2                	ld	s1,40(sp)
    80002282:	7902                	ld	s2,32(sp)
    80002284:	69e2                	ld	s3,24(sp)
    80002286:	6a42                	ld	s4,16(sp)
    80002288:	6aa2                	ld	s5,8(sp)
    8000228a:	6121                	addi	sp,sp,64
    8000228c:	8082                	ret

000000008000228e <reparent>:
{
    8000228e:	7179                	addi	sp,sp,-48
    80002290:	f406                	sd	ra,40(sp)
    80002292:	f022                	sd	s0,32(sp)
    80002294:	ec26                	sd	s1,24(sp)
    80002296:	e84a                	sd	s2,16(sp)
    80002298:	e44e                	sd	s3,8(sp)
    8000229a:	e052                	sd	s4,0(sp)
    8000229c:	1800                	addi	s0,sp,48
    8000229e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022a0:	0000f497          	auipc	s1,0xf
    800022a4:	43048493          	addi	s1,s1,1072 # 800116d0 <proc>
      pp->parent = initproc;
    800022a8:	00007a17          	auipc	s4,0x7
    800022ac:	d80a0a13          	addi	s4,s4,-640 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022b0:	00015997          	auipc	s3,0x15
    800022b4:	02098993          	addi	s3,s3,32 # 800172d0 <tickslock>
    800022b8:	a029                	j	800022c2 <reparent+0x34>
    800022ba:	17048493          	addi	s1,s1,368
    800022be:	01348d63          	beq	s1,s3,800022d8 <reparent+0x4a>
    if (pp->parent == p)
    800022c2:	7c9c                	ld	a5,56(s1)
    800022c4:	ff279be3          	bne	a5,s2,800022ba <reparent+0x2c>
      pp->parent = initproc;
    800022c8:	000a3503          	ld	a0,0(s4)
    800022cc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	f4a080e7          	jalr	-182(ra) # 80002218 <wakeup>
    800022d6:	b7d5                	j	800022ba <reparent+0x2c>
}
    800022d8:	70a2                	ld	ra,40(sp)
    800022da:	7402                	ld	s0,32(sp)
    800022dc:	64e2                	ld	s1,24(sp)
    800022de:	6942                	ld	s2,16(sp)
    800022e0:	69a2                	ld	s3,8(sp)
    800022e2:	6a02                	ld	s4,0(sp)
    800022e4:	6145                	addi	sp,sp,48
    800022e6:	8082                	ret

00000000800022e8 <exit>:
{
    800022e8:	7179                	addi	sp,sp,-48
    800022ea:	f406                	sd	ra,40(sp)
    800022ec:	f022                	sd	s0,32(sp)
    800022ee:	ec26                	sd	s1,24(sp)
    800022f0:	e84a                	sd	s2,16(sp)
    800022f2:	e44e                	sd	s3,8(sp)
    800022f4:	e052                	sd	s4,0(sp)
    800022f6:	1800                	addi	s0,sp,48
    800022f8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	698080e7          	jalr	1688(ra) # 80001992 <myproc>
    80002302:	89aa                	mv	s3,a0
  acquire(&tickslock);
    80002304:	00015517          	auipc	a0,0x15
    80002308:	fcc50513          	addi	a0,a0,-52 # 800172d0 <tickslock>
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	8b6080e7          	jalr	-1866(ra) # 80000bc2 <acquire>
  p->performance->ttime = ticks;
    80002314:	1689b783          	ld	a5,360(s3)
    80002318:	00007717          	auipc	a4,0x7
    8000231c:	d1872703          	lw	a4,-744(a4) # 80009030 <ticks>
    80002320:	c3d8                	sw	a4,4(a5)
  release(&tickslock);
    80002322:	00015517          	auipc	a0,0x15
    80002326:	fae50513          	addi	a0,a0,-82 # 800172d0 <tickslock>
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	94c080e7          	jalr	-1716(ra) # 80000c76 <release>
  if (p == initproc)
    80002332:	00007797          	auipc	a5,0x7
    80002336:	cf67b783          	ld	a5,-778(a5) # 80009028 <initproc>
    8000233a:	0d098493          	addi	s1,s3,208
    8000233e:	15098913          	addi	s2,s3,336
    80002342:	03379363          	bne	a5,s3,80002368 <exit+0x80>
    panic("init exiting");
    80002346:	00006517          	auipc	a0,0x6
    8000234a:	f0250513          	addi	a0,a0,-254 # 80008248 <digits+0x208>
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	1dc080e7          	jalr	476(ra) # 8000052a <panic>
      fileclose(f);
    80002356:	00002097          	auipc	ra,0x2
    8000235a:	354080e7          	jalr	852(ra) # 800046aa <fileclose>
      p->ofile[fd] = 0;
    8000235e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002362:	04a1                	addi	s1,s1,8
    80002364:	01248563          	beq	s1,s2,8000236e <exit+0x86>
    if (p->ofile[fd])
    80002368:	6088                	ld	a0,0(s1)
    8000236a:	f575                	bnez	a0,80002356 <exit+0x6e>
    8000236c:	bfdd                	j	80002362 <exit+0x7a>
  begin_op();
    8000236e:	00002097          	auipc	ra,0x2
    80002372:	e70080e7          	jalr	-400(ra) # 800041de <begin_op>
  iput(p->cwd);
    80002376:	1509b503          	ld	a0,336(s3)
    8000237a:	00001097          	auipc	ra,0x1
    8000237e:	648080e7          	jalr	1608(ra) # 800039c2 <iput>
  end_op();
    80002382:	00002097          	auipc	ra,0x2
    80002386:	edc080e7          	jalr	-292(ra) # 8000425e <end_op>
  p->cwd = 0;
    8000238a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000238e:	0000f497          	auipc	s1,0xf
    80002392:	f2a48493          	addi	s1,s1,-214 # 800112b8 <wait_lock>
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	82a080e7          	jalr	-2006(ra) # 80000bc2 <acquire>
  reparent(p);
    800023a0:	854e                	mv	a0,s3
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	eec080e7          	jalr	-276(ra) # 8000228e <reparent>
  wakeup(p->parent);
    800023aa:	0389b503          	ld	a0,56(s3)
    800023ae:	00000097          	auipc	ra,0x0
    800023b2:	e6a080e7          	jalr	-406(ra) # 80002218 <wakeup>
  acquire(&p->lock);
    800023b6:	854e                	mv	a0,s3
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	80a080e7          	jalr	-2038(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800023c0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023c4:	4795                	li	a5,5
    800023c6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8aa080e7          	jalr	-1878(ra) # 80000c76 <release>
  sched();
    800023d4:	00000097          	auipc	ra,0x0
    800023d8:	ba6080e7          	jalr	-1114(ra) # 80001f7a <sched>
  panic("zombie exit");
    800023dc:	00006517          	auipc	a0,0x6
    800023e0:	e7c50513          	addi	a0,a0,-388 # 80008258 <digits+0x218>
    800023e4:	ffffe097          	auipc	ra,0xffffe
    800023e8:	146080e7          	jalr	326(ra) # 8000052a <panic>

00000000800023ec <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023ec:	7179                	addi	sp,sp,-48
    800023ee:	f406                	sd	ra,40(sp)
    800023f0:	f022                	sd	s0,32(sp)
    800023f2:	ec26                	sd	s1,24(sp)
    800023f4:	e84a                	sd	s2,16(sp)
    800023f6:	e44e                	sd	s3,8(sp)
    800023f8:	1800                	addi	s0,sp,48
    800023fa:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023fc:	0000f497          	auipc	s1,0xf
    80002400:	2d448493          	addi	s1,s1,724 # 800116d0 <proc>
    80002404:	00015997          	auipc	s3,0x15
    80002408:	ecc98993          	addi	s3,s3,-308 # 800172d0 <tickslock>
  {
    acquire(&p->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7b4080e7          	jalr	1972(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    80002416:	589c                	lw	a5,48(s1)
    80002418:	01278d63          	beq	a5,s2,80002432 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	858080e7          	jalr	-1960(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002426:	17048493          	addi	s1,s1,368
    8000242a:	ff3491e3          	bne	s1,s3,8000240c <kill+0x20>
  }
  return -1;
    8000242e:	557d                	li	a0,-1
    80002430:	a829                	j	8000244a <kill+0x5e>
      p->killed = 1;
    80002432:	4785                	li	a5,1
    80002434:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002436:	4c98                	lw	a4,24(s1)
    80002438:	4789                	li	a5,2
    8000243a:	00f70f63          	beq	a4,a5,80002458 <kill+0x6c>
      release(&p->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	836080e7          	jalr	-1994(ra) # 80000c76 <release>
      return 0;
    80002448:	4501                	li	a0,0
}
    8000244a:	70a2                	ld	ra,40(sp)
    8000244c:	7402                	ld	s0,32(sp)
    8000244e:	64e2                	ld	s1,24(sp)
    80002450:	6942                	ld	s2,16(sp)
    80002452:	69a2                	ld	s3,8(sp)
    80002454:	6145                	addi	sp,sp,48
    80002456:	8082                	ret
        p->state = RUNNABLE;
    80002458:	478d                	li	a5,3
    8000245a:	cc9c                	sw	a5,24(s1)
    8000245c:	b7cd                	j	8000243e <kill+0x52>

000000008000245e <trace>:

int trace(int mask, int pid)
{
    8000245e:	7179                	addi	sp,sp,-48
    80002460:	f406                	sd	ra,40(sp)
    80002462:	f022                	sd	s0,32(sp)
    80002464:	ec26                	sd	s1,24(sp)
    80002466:	e84a                	sd	s2,16(sp)
    80002468:	e44e                	sd	s3,8(sp)
    8000246a:	e052                	sd	s4,0(sp)
    8000246c:	1800                	addi	s0,sp,48
    8000246e:	8a2a                	mv	s4,a0
    80002470:	892e                	mv	s2,a1
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002472:	0000f497          	auipc	s1,0xf
    80002476:	25e48493          	addi	s1,s1,606 # 800116d0 <proc>
    8000247a:	00015997          	auipc	s3,0x15
    8000247e:	e5698993          	addi	s3,s3,-426 # 800172d0 <tickslock>
  {
    acquire(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	73e080e7          	jalr	1854(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    8000248c:	589c                	lw	a5,48(s1)
    8000248e:	01278d63          	beq	a5,s2,800024a8 <trace+0x4a>
    {
      p->traceMask = mask;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002492:	8526                	mv	a0,s1
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	7e2080e7          	jalr	2018(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000249c:	17048493          	addi	s1,s1,368
    800024a0:	ff3491e3          	bne	s1,s3,80002482 <trace+0x24>
  }
  return -1;
    800024a4:	557d                	li	a0,-1
    800024a6:	a809                	j	800024b8 <trace+0x5a>
      p->traceMask = mask;
    800024a8:	0344aa23          	sw	s4,52(s1)
      release(&p->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7c8080e7          	jalr	1992(ra) # 80000c76 <release>
      return 0;
    800024b6:	4501                	li	a0,0
}
    800024b8:	70a2                	ld	ra,40(sp)
    800024ba:	7402                	ld	s0,32(sp)
    800024bc:	64e2                	ld	s1,24(sp)
    800024be:	6942                	ld	s2,16(sp)
    800024c0:	69a2                	ld	s3,8(sp)
    800024c2:	6a02                	ld	s4,0(sp)
    800024c4:	6145                	addi	sp,sp,48
    800024c6:	8082                	ret

00000000800024c8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024c8:	7179                	addi	sp,sp,-48
    800024ca:	f406                	sd	ra,40(sp)
    800024cc:	f022                	sd	s0,32(sp)
    800024ce:	ec26                	sd	s1,24(sp)
    800024d0:	e84a                	sd	s2,16(sp)
    800024d2:	e44e                	sd	s3,8(sp)
    800024d4:	e052                	sd	s4,0(sp)
    800024d6:	1800                	addi	s0,sp,48
    800024d8:	84aa                	mv	s1,a0
    800024da:	892e                	mv	s2,a1
    800024dc:	89b2                	mv	s3,a2
    800024de:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	4b2080e7          	jalr	1202(ra) # 80001992 <myproc>
  if (user_dst)
    800024e8:	c08d                	beqz	s1,8000250a <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024ea:	86d2                	mv	a3,s4
    800024ec:	864e                	mv	a2,s3
    800024ee:	85ca                	mv	a1,s2
    800024f0:	6928                	ld	a0,80(a0)
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	14c080e7          	jalr	332(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024fa:	70a2                	ld	ra,40(sp)
    800024fc:	7402                	ld	s0,32(sp)
    800024fe:	64e2                	ld	s1,24(sp)
    80002500:	6942                	ld	s2,16(sp)
    80002502:	69a2                	ld	s3,8(sp)
    80002504:	6a02                	ld	s4,0(sp)
    80002506:	6145                	addi	sp,sp,48
    80002508:	8082                	ret
    memmove((char *)dst, src, len);
    8000250a:	000a061b          	sext.w	a2,s4
    8000250e:	85ce                	mv	a1,s3
    80002510:	854a                	mv	a0,s2
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	808080e7          	jalr	-2040(ra) # 80000d1a <memmove>
    return 0;
    8000251a:	8526                	mv	a0,s1
    8000251c:	bff9                	j	800024fa <either_copyout+0x32>

000000008000251e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000251e:	7179                	addi	sp,sp,-48
    80002520:	f406                	sd	ra,40(sp)
    80002522:	f022                	sd	s0,32(sp)
    80002524:	ec26                	sd	s1,24(sp)
    80002526:	e84a                	sd	s2,16(sp)
    80002528:	e44e                	sd	s3,8(sp)
    8000252a:	e052                	sd	s4,0(sp)
    8000252c:	1800                	addi	s0,sp,48
    8000252e:	892a                	mv	s2,a0
    80002530:	84ae                	mv	s1,a1
    80002532:	89b2                	mv	s3,a2
    80002534:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	45c080e7          	jalr	1116(ra) # 80001992 <myproc>
  if (user_src)
    8000253e:	c08d                	beqz	s1,80002560 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002540:	86d2                	mv	a3,s4
    80002542:	864e                	mv	a2,s3
    80002544:	85ca                	mv	a1,s2
    80002546:	6928                	ld	a0,80(a0)
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	182080e7          	jalr	386(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002550:	70a2                	ld	ra,40(sp)
    80002552:	7402                	ld	s0,32(sp)
    80002554:	64e2                	ld	s1,24(sp)
    80002556:	6942                	ld	s2,16(sp)
    80002558:	69a2                	ld	s3,8(sp)
    8000255a:	6a02                	ld	s4,0(sp)
    8000255c:	6145                	addi	sp,sp,48
    8000255e:	8082                	ret
    memmove(dst, (char *)src, len);
    80002560:	000a061b          	sext.w	a2,s4
    80002564:	85ce                	mv	a1,s3
    80002566:	854a                	mv	a0,s2
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	7b2080e7          	jalr	1970(ra) # 80000d1a <memmove>
    return 0;
    80002570:	8526                	mv	a0,s1
    80002572:	bff9                	j	80002550 <either_copyin+0x32>

0000000080002574 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002574:	715d                	addi	sp,sp,-80
    80002576:	e486                	sd	ra,72(sp)
    80002578:	e0a2                	sd	s0,64(sp)
    8000257a:	fc26                	sd	s1,56(sp)
    8000257c:	f84a                	sd	s2,48(sp)
    8000257e:	f44e                	sd	s3,40(sp)
    80002580:	f052                	sd	s4,32(sp)
    80002582:	ec56                	sd	s5,24(sp)
    80002584:	e85a                	sd	s6,16(sp)
    80002586:	e45e                	sd	s7,8(sp)
    80002588:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000258a:	00006517          	auipc	a0,0x6
    8000258e:	b3e50513          	addi	a0,a0,-1218 # 800080c8 <digits+0x88>
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	fe2080e7          	jalr	-30(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000259a:	0000f497          	auipc	s1,0xf
    8000259e:	28e48493          	addi	s1,s1,654 # 80011828 <proc+0x158>
    800025a2:	00015917          	auipc	s2,0x15
    800025a6:	e8690913          	addi	s2,s2,-378 # 80017428 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025aa:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025ac:	00006997          	auipc	s3,0x6
    800025b0:	cbc98993          	addi	s3,s3,-836 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025b4:	00006a97          	auipc	s5,0x6
    800025b8:	cbca8a93          	addi	s5,s5,-836 # 80008270 <digits+0x230>
    printf("\n");
    800025bc:	00006a17          	auipc	s4,0x6
    800025c0:	b0ca0a13          	addi	s4,s4,-1268 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c4:	00006b97          	auipc	s7,0x6
    800025c8:	ce4b8b93          	addi	s7,s7,-796 # 800082a8 <states.0>
    800025cc:	a00d                	j	800025ee <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ce:	ed86a583          	lw	a1,-296(a3)
    800025d2:	8556                	mv	a0,s5
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	fa0080e7          	jalr	-96(ra) # 80000574 <printf>
    printf("\n");
    800025dc:	8552                	mv	a0,s4
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	f96080e7          	jalr	-106(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025e6:	17048493          	addi	s1,s1,368
    800025ea:	03248263          	beq	s1,s2,8000260e <procdump+0x9a>
    if (p->state == UNUSED)
    800025ee:	86a6                	mv	a3,s1
    800025f0:	ec04a783          	lw	a5,-320(s1)
    800025f4:	dbed                	beqz	a5,800025e6 <procdump+0x72>
      state = "???";
    800025f6:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f8:	fcfb6be3          	bltu	s6,a5,800025ce <procdump+0x5a>
    800025fc:	02079713          	slli	a4,a5,0x20
    80002600:	01d75793          	srli	a5,a4,0x1d
    80002604:	97de                	add	a5,a5,s7
    80002606:	6390                	ld	a2,0(a5)
    80002608:	f279                	bnez	a2,800025ce <procdump+0x5a>
      state = "???";
    8000260a:	864e                	mv	a2,s3
    8000260c:	b7c9                	j	800025ce <procdump+0x5a>
  }
}
    8000260e:	60a6                	ld	ra,72(sp)
    80002610:	6406                	ld	s0,64(sp)
    80002612:	74e2                	ld	s1,56(sp)
    80002614:	7942                	ld	s2,48(sp)
    80002616:	79a2                	ld	s3,40(sp)
    80002618:	7a02                	ld	s4,32(sp)
    8000261a:	6ae2                	ld	s5,24(sp)
    8000261c:	6b42                	ld	s6,16(sp)
    8000261e:	6ba2                	ld	s7,8(sp)
    80002620:	6161                	addi	sp,sp,80
    80002622:	8082                	ret

0000000080002624 <swtch>:
    80002624:	00153023          	sd	ra,0(a0)
    80002628:	00253423          	sd	sp,8(a0)
    8000262c:	e900                	sd	s0,16(a0)
    8000262e:	ed04                	sd	s1,24(a0)
    80002630:	03253023          	sd	s2,32(a0)
    80002634:	03353423          	sd	s3,40(a0)
    80002638:	03453823          	sd	s4,48(a0)
    8000263c:	03553c23          	sd	s5,56(a0)
    80002640:	05653023          	sd	s6,64(a0)
    80002644:	05753423          	sd	s7,72(a0)
    80002648:	05853823          	sd	s8,80(a0)
    8000264c:	05953c23          	sd	s9,88(a0)
    80002650:	07a53023          	sd	s10,96(a0)
    80002654:	07b53423          	sd	s11,104(a0)
    80002658:	0005b083          	ld	ra,0(a1)
    8000265c:	0085b103          	ld	sp,8(a1)
    80002660:	6980                	ld	s0,16(a1)
    80002662:	6d84                	ld	s1,24(a1)
    80002664:	0205b903          	ld	s2,32(a1)
    80002668:	0285b983          	ld	s3,40(a1)
    8000266c:	0305ba03          	ld	s4,48(a1)
    80002670:	0385ba83          	ld	s5,56(a1)
    80002674:	0405bb03          	ld	s6,64(a1)
    80002678:	0485bb83          	ld	s7,72(a1)
    8000267c:	0505bc03          	ld	s8,80(a1)
    80002680:	0585bc83          	ld	s9,88(a1)
    80002684:	0605bd03          	ld	s10,96(a1)
    80002688:	0685bd83          	ld	s11,104(a1)
    8000268c:	8082                	ret

000000008000268e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000268e:	1141                	addi	sp,sp,-16
    80002690:	e406                	sd	ra,8(sp)
    80002692:	e022                	sd	s0,0(sp)
    80002694:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002696:	00006597          	auipc	a1,0x6
    8000269a:	c4258593          	addi	a1,a1,-958 # 800082d8 <states.0+0x30>
    8000269e:	00015517          	auipc	a0,0x15
    800026a2:	c3250513          	addi	a0,a0,-974 # 800172d0 <tickslock>
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	48c080e7          	jalr	1164(ra) # 80000b32 <initlock>
}
    800026ae:	60a2                	ld	ra,8(sp)
    800026b0:	6402                	ld	s0,0(sp)
    800026b2:	0141                	addi	sp,sp,16
    800026b4:	8082                	ret

00000000800026b6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026b6:	1141                	addi	sp,sp,-16
    800026b8:	e422                	sd	s0,8(sp)
    800026ba:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026bc:	00003797          	auipc	a5,0x3
    800026c0:	61478793          	addi	a5,a5,1556 # 80005cd0 <kernelvec>
    800026c4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026c8:	6422                	ld	s0,8(sp)
    800026ca:	0141                	addi	sp,sp,16
    800026cc:	8082                	ret

00000000800026ce <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ce:	1141                	addi	sp,sp,-16
    800026d0:	e406                	sd	ra,8(sp)
    800026d2:	e022                	sd	s0,0(sp)
    800026d4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	2bc080e7          	jalr	700(ra) # 80001992 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026de:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026e2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026e8:	00005617          	auipc	a2,0x5
    800026ec:	91860613          	addi	a2,a2,-1768 # 80007000 <_trampoline>
    800026f0:	00005697          	auipc	a3,0x5
    800026f4:	91068693          	addi	a3,a3,-1776 # 80007000 <_trampoline>
    800026f8:	8e91                	sub	a3,a3,a2
    800026fa:	040007b7          	lui	a5,0x4000
    800026fe:	17fd                	addi	a5,a5,-1
    80002700:	07b2                	slli	a5,a5,0xc
    80002702:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002704:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002708:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000270a:	180026f3          	csrr	a3,satp
    8000270e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002710:	6d38                	ld	a4,88(a0)
    80002712:	6134                	ld	a3,64(a0)
    80002714:	6585                	lui	a1,0x1
    80002716:	96ae                	add	a3,a3,a1
    80002718:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000271a:	6d38                	ld	a4,88(a0)
    8000271c:	00000697          	auipc	a3,0x0
    80002720:	1c268693          	addi	a3,a3,450 # 800028de <usertrap>
    80002724:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002726:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002728:	8692                	mv	a3,tp
    8000272a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002730:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002734:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002738:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000273c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000273e:	6f18                	ld	a4,24(a4)
    80002740:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002744:	692c                	ld	a1,80(a0)
    80002746:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002748:	00005717          	auipc	a4,0x5
    8000274c:	94870713          	addi	a4,a4,-1720 # 80007090 <userret>
    80002750:	8f11                	sub	a4,a4,a2
    80002752:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002754:	577d                	li	a4,-1
    80002756:	177e                	slli	a4,a4,0x3f
    80002758:	8dd9                	or	a1,a1,a4
    8000275a:	02000537          	lui	a0,0x2000
    8000275e:	157d                	addi	a0,a0,-1
    80002760:	0536                	slli	a0,a0,0xd
    80002762:	9782                	jalr	a5
}
    80002764:	60a2                	ld	ra,8(sp)
    80002766:	6402                	ld	s0,0(sp)
    80002768:	0141                	addi	sp,sp,16
    8000276a:	8082                	ret

000000008000276c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000276c:	7139                	addi	sp,sp,-64
    8000276e:	fc06                	sd	ra,56(sp)
    80002770:	f822                	sd	s0,48(sp)
    80002772:	f426                	sd	s1,40(sp)
    80002774:	f04a                	sd	s2,32(sp)
    80002776:	ec4e                	sd	s3,24(sp)
    80002778:	e852                	sd	s4,16(sp)
    8000277a:	e456                	sd	s5,8(sp)
    8000277c:	0080                	addi	s0,sp,64
  acquire(&tickslock);
    8000277e:	00015517          	auipc	a0,0x15
    80002782:	b5250513          	addi	a0,a0,-1198 # 800172d0 <tickslock>
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	43c080e7          	jalr	1084(ra) # 80000bc2 <acquire>
  ticks++;
    8000278e:	00007717          	auipc	a4,0x7
    80002792:	8a270713          	addi	a4,a4,-1886 # 80009030 <ticks>
    80002796:	431c                	lw	a5,0(a4)
    80002798:	2785                	addiw	a5,a5,1
    8000279a:	c31c                	sw	a5,0(a4)
  //start add UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE
  struct proc *p;
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    8000279c:	fffff097          	auipc	ra,0xfffff
    800027a0:	070080e7          	jalr	112(ra) # 8000180c <getProc>
    800027a4:	84aa                	mv	s1,a0
    800027a6:	6919                	lui	s2,0x6
    800027a8:	c0090913          	addi	s2,s2,-1024 # 5c00 <_entry-0x7fffa400>
    acquire(&p->lock);

    enum procstate state = p->state;
    switch (state)
    800027ac:	4a8d                	li	s5,3
    800027ae:	4a11                	li	s4,4
    800027b0:	4989                	li	s3,2
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    800027b2:	a829                	j	800027cc <clockintr+0x60>
      break;
    case SLEEPING:
      p->performance->stime += 1;
      break;
    case RUNNABLE:
      p->performance->retime += 1;
    800027b4:	1684b703          	ld	a4,360(s1)
    800027b8:	475c                	lw	a5,12(a4)
    800027ba:	2785                	addiw	a5,a5,1
    800027bc:	c75c                	sw	a5,12(a4)
    case ZOMBIE:   
      break; 
    default:
      break;
    }
    release(&p->lock);
    800027be:	8526                	mv	a0,s1
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	4b6080e7          	jalr	1206(ra) # 80000c76 <release>
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    800027c8:	17048493          	addi	s1,s1,368
    800027cc:	fffff097          	auipc	ra,0xfffff
    800027d0:	040080e7          	jalr	64(ra) # 8000180c <getProc>
    800027d4:	954a                	add	a0,a0,s2
    800027d6:	02a4fa63          	bgeu	s1,a0,8000280a <clockintr+0x9e>
    acquire(&p->lock);
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	3e6080e7          	jalr	998(ra) # 80000bc2 <acquire>
    enum procstate state = p->state;
    800027e4:	4c9c                	lw	a5,24(s1)
    switch (state)
    800027e6:	fd5787e3          	beq	a5,s5,800027b4 <clockintr+0x48>
    800027ea:	01478a63          	beq	a5,s4,800027fe <clockintr+0x92>
    800027ee:	fd3798e3          	bne	a5,s3,800027be <clockintr+0x52>
      p->performance->stime += 1;
    800027f2:	1684b703          	ld	a4,360(s1)
    800027f6:	471c                	lw	a5,8(a4)
    800027f8:	2785                	addiw	a5,a5,1
    800027fa:	c71c                	sw	a5,8(a4)
      break;
    800027fc:	b7c9                	j	800027be <clockintr+0x52>
      p->performance->runtime += 1;
    800027fe:	1684b703          	ld	a4,360(s1)
    80002802:	4b1c                	lw	a5,16(a4)
    80002804:	2785                	addiw	a5,a5,1
    80002806:	cb1c                	sw	a5,16(a4)
      break;
    80002808:	bf5d                	j	800027be <clockintr+0x52>
  }
  //end add
  wakeup(&ticks);
    8000280a:	00007517          	auipc	a0,0x7
    8000280e:	82650513          	addi	a0,a0,-2010 # 80009030 <ticks>
    80002812:	00000097          	auipc	ra,0x0
    80002816:	a06080e7          	jalr	-1530(ra) # 80002218 <wakeup>
  release(&tickslock);
    8000281a:	00015517          	auipc	a0,0x15
    8000281e:	ab650513          	addi	a0,a0,-1354 # 800172d0 <tickslock>
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	454080e7          	jalr	1108(ra) # 80000c76 <release>
}
    8000282a:	70e2                	ld	ra,56(sp)
    8000282c:	7442                	ld	s0,48(sp)
    8000282e:	74a2                	ld	s1,40(sp)
    80002830:	7902                	ld	s2,32(sp)
    80002832:	69e2                	ld	s3,24(sp)
    80002834:	6a42                	ld	s4,16(sp)
    80002836:	6aa2                	ld	s5,8(sp)
    80002838:	6121                	addi	sp,sp,64
    8000283a:	8082                	ret

000000008000283c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000283c:	1101                	addi	sp,sp,-32
    8000283e:	ec06                	sd	ra,24(sp)
    80002840:	e822                	sd	s0,16(sp)
    80002842:	e426                	sd	s1,8(sp)
    80002844:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002846:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000284a:	00074d63          	bltz	a4,80002864 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000284e:	57fd                	li	a5,-1
    80002850:	17fe                	slli	a5,a5,0x3f
    80002852:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002854:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002856:	06f70363          	beq	a4,a5,800028bc <devintr+0x80>
  }
}
    8000285a:	60e2                	ld	ra,24(sp)
    8000285c:	6442                	ld	s0,16(sp)
    8000285e:	64a2                	ld	s1,8(sp)
    80002860:	6105                	addi	sp,sp,32
    80002862:	8082                	ret
     (scause & 0xff) == 9){
    80002864:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002868:	46a5                	li	a3,9
    8000286a:	fed792e3          	bne	a5,a3,8000284e <devintr+0x12>
    int irq = plic_claim();
    8000286e:	00003097          	auipc	ra,0x3
    80002872:	56a080e7          	jalr	1386(ra) # 80005dd8 <plic_claim>
    80002876:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002878:	47a9                	li	a5,10
    8000287a:	02f50763          	beq	a0,a5,800028a8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000287e:	4785                	li	a5,1
    80002880:	02f50963          	beq	a0,a5,800028b2 <devintr+0x76>
    return 1;
    80002884:	4505                	li	a0,1
    } else if(irq){
    80002886:	d8f1                	beqz	s1,8000285a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002888:	85a6                	mv	a1,s1
    8000288a:	00006517          	auipc	a0,0x6
    8000288e:	a5650513          	addi	a0,a0,-1450 # 800082e0 <states.0+0x38>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	ce2080e7          	jalr	-798(ra) # 80000574 <printf>
      plic_complete(irq);
    8000289a:	8526                	mv	a0,s1
    8000289c:	00003097          	auipc	ra,0x3
    800028a0:	560080e7          	jalr	1376(ra) # 80005dfc <plic_complete>
    return 1;
    800028a4:	4505                	li	a0,1
    800028a6:	bf55                	j	8000285a <devintr+0x1e>
      uartintr();
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	0de080e7          	jalr	222(ra) # 80000986 <uartintr>
    800028b0:	b7ed                	j	8000289a <devintr+0x5e>
      virtio_disk_intr();
    800028b2:	00004097          	auipc	ra,0x4
    800028b6:	9dc080e7          	jalr	-1572(ra) # 8000628e <virtio_disk_intr>
    800028ba:	b7c5                	j	8000289a <devintr+0x5e>
    if(cpuid() == 0){
    800028bc:	fffff097          	auipc	ra,0xfffff
    800028c0:	0aa080e7          	jalr	170(ra) # 80001966 <cpuid>
    800028c4:	c901                	beqz	a0,800028d4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028c6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028cc:	14479073          	csrw	sip,a5
    return 2;
    800028d0:	4509                	li	a0,2
    800028d2:	b761                	j	8000285a <devintr+0x1e>
      clockintr();
    800028d4:	00000097          	auipc	ra,0x0
    800028d8:	e98080e7          	jalr	-360(ra) # 8000276c <clockintr>
    800028dc:	b7ed                	j	800028c6 <devintr+0x8a>

00000000800028de <usertrap>:
{
    800028de:	1101                	addi	sp,sp,-32
    800028e0:	ec06                	sd	ra,24(sp)
    800028e2:	e822                	sd	s0,16(sp)
    800028e4:	e426                	sd	s1,8(sp)
    800028e6:	e04a                	sd	s2,0(sp)
    800028e8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ea:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028ee:	1007f793          	andi	a5,a5,256
    800028f2:	e3ad                	bnez	a5,80002954 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f4:	00003797          	auipc	a5,0x3
    800028f8:	3dc78793          	addi	a5,a5,988 # 80005cd0 <kernelvec>
    800028fc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002900:	fffff097          	auipc	ra,0xfffff
    80002904:	092080e7          	jalr	146(ra) # 80001992 <myproc>
    80002908:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000290a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000290c:	14102773          	csrr	a4,sepc
    80002910:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002912:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002916:	47a1                	li	a5,8
    80002918:	04f71c63          	bne	a4,a5,80002970 <usertrap+0x92>
    if(p->killed)
    8000291c:	551c                	lw	a5,40(a0)
    8000291e:	e3b9                	bnez	a5,80002964 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002920:	6cb8                	ld	a4,88(s1)
    80002922:	6f1c                	ld	a5,24(a4)
    80002924:	0791                	addi	a5,a5,4
    80002926:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002928:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000292c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002930:	10079073          	csrw	sstatus,a5
    syscall();
    80002934:	00000097          	auipc	ra,0x0
    80002938:	2e0080e7          	jalr	736(ra) # 80002c14 <syscall>
  if(p->killed)
    8000293c:	549c                	lw	a5,40(s1)
    8000293e:	ebc1                	bnez	a5,800029ce <usertrap+0xf0>
  usertrapret();
    80002940:	00000097          	auipc	ra,0x0
    80002944:	d8e080e7          	jalr	-626(ra) # 800026ce <usertrapret>
}
    80002948:	60e2                	ld	ra,24(sp)
    8000294a:	6442                	ld	s0,16(sp)
    8000294c:	64a2                	ld	s1,8(sp)
    8000294e:	6902                	ld	s2,0(sp)
    80002950:	6105                	addi	sp,sp,32
    80002952:	8082                	ret
    panic("usertrap: not from user mode");
    80002954:	00006517          	auipc	a0,0x6
    80002958:	9ac50513          	addi	a0,a0,-1620 # 80008300 <states.0+0x58>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	bce080e7          	jalr	-1074(ra) # 8000052a <panic>
      exit(-1);
    80002964:	557d                	li	a0,-1
    80002966:	00000097          	auipc	ra,0x0
    8000296a:	982080e7          	jalr	-1662(ra) # 800022e8 <exit>
    8000296e:	bf4d                	j	80002920 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002970:	00000097          	auipc	ra,0x0
    80002974:	ecc080e7          	jalr	-308(ra) # 8000283c <devintr>
    80002978:	892a                	mv	s2,a0
    8000297a:	c501                	beqz	a0,80002982 <usertrap+0xa4>
  if(p->killed)
    8000297c:	549c                	lw	a5,40(s1)
    8000297e:	c3a1                	beqz	a5,800029be <usertrap+0xe0>
    80002980:	a815                	j	800029b4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002982:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002986:	5890                	lw	a2,48(s1)
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	99850513          	addi	a0,a0,-1640 # 80008320 <states.0+0x78>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	be4080e7          	jalr	-1052(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002998:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000299c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	9b050513          	addi	a0,a0,-1616 # 80008350 <states.0+0xa8>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	bcc080e7          	jalr	-1076(ra) # 80000574 <printf>
    p->killed = 1;
    800029b0:	4785                	li	a5,1
    800029b2:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029b4:	557d                	li	a0,-1
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	932080e7          	jalr	-1742(ra) # 800022e8 <exit>
  if(which_dev == 2)
    800029be:	4789                	li	a5,2
    800029c0:	f8f910e3          	bne	s2,a5,80002940 <usertrap+0x62>
    yield();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	68c080e7          	jalr	1676(ra) # 80002050 <yield>
    800029cc:	bf95                	j	80002940 <usertrap+0x62>
  int which_dev = 0;
    800029ce:	4901                	li	s2,0
    800029d0:	b7d5                	j	800029b4 <usertrap+0xd6>

00000000800029d2 <kerneltrap>:
{
    800029d2:	7179                	addi	sp,sp,-48
    800029d4:	f406                	sd	ra,40(sp)
    800029d6:	f022                	sd	s0,32(sp)
    800029d8:	ec26                	sd	s1,24(sp)
    800029da:	e84a                	sd	s2,16(sp)
    800029dc:	e44e                	sd	s3,8(sp)
    800029de:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ec:	1004f793          	andi	a5,s1,256
    800029f0:	cb85                	beqz	a5,80002a20 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029f6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029f8:	ef85                	bnez	a5,80002a30 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	e42080e7          	jalr	-446(ra) # 8000283c <devintr>
    80002a02:	cd1d                	beqz	a0,80002a40 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a04:	4789                	li	a5,2
    80002a06:	06f50a63          	beq	a0,a5,80002a7a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a0a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0e:	10049073          	csrw	sstatus,s1
}
    80002a12:	70a2                	ld	ra,40(sp)
    80002a14:	7402                	ld	s0,32(sp)
    80002a16:	64e2                	ld	s1,24(sp)
    80002a18:	6942                	ld	s2,16(sp)
    80002a1a:	69a2                	ld	s3,8(sp)
    80002a1c:	6145                	addi	sp,sp,48
    80002a1e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a20:	00006517          	auipc	a0,0x6
    80002a24:	95050513          	addi	a0,a0,-1712 # 80008370 <states.0+0xc8>
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	b02080e7          	jalr	-1278(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	96850513          	addi	a0,a0,-1688 # 80008398 <states.0+0xf0>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	af2080e7          	jalr	-1294(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002a40:	85ce                	mv	a1,s3
    80002a42:	00006517          	auipc	a0,0x6
    80002a46:	97650513          	addi	a0,a0,-1674 # 800083b8 <states.0+0x110>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	b2a080e7          	jalr	-1238(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a52:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a56:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a5a:	00006517          	auipc	a0,0x6
    80002a5e:	96e50513          	addi	a0,a0,-1682 # 800083c8 <states.0+0x120>
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	b12080e7          	jalr	-1262(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	97650513          	addi	a0,a0,-1674 # 800083e0 <states.0+0x138>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	ab8080e7          	jalr	-1352(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	f18080e7          	jalr	-232(ra) # 80001992 <myproc>
    80002a82:	d541                	beqz	a0,80002a0a <kerneltrap+0x38>
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	f0e080e7          	jalr	-242(ra) # 80001992 <myproc>
    80002a8c:	4d18                	lw	a4,24(a0)
    80002a8e:	4791                	li	a5,4
    80002a90:	f6f71de3          	bne	a4,a5,80002a0a <kerneltrap+0x38>
    yield();
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	5bc080e7          	jalr	1468(ra) # 80002050 <yield>
    80002a9c:	b7bd                	j	80002a0a <kerneltrap+0x38>

0000000080002a9e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a9e:	1101                	addi	sp,sp,-32
    80002aa0:	ec06                	sd	ra,24(sp)
    80002aa2:	e822                	sd	s0,16(sp)
    80002aa4:	e426                	sd	s1,8(sp)
    80002aa6:	1000                	addi	s0,sp,32
    80002aa8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	ee8080e7          	jalr	-280(ra) # 80001992 <myproc>
  switch (n)
    80002ab2:	4795                	li	a5,5
    80002ab4:	0497e163          	bltu	a5,s1,80002af6 <argraw+0x58>
    80002ab8:	048a                	slli	s1,s1,0x2
    80002aba:	00006717          	auipc	a4,0x6
    80002abe:	ade70713          	addi	a4,a4,-1314 # 80008598 <states.0+0x2f0>
    80002ac2:	94ba                	add	s1,s1,a4
    80002ac4:	409c                	lw	a5,0(s1)
    80002ac6:	97ba                	add	a5,a5,a4
    80002ac8:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002aca:	6d3c                	ld	a5,88(a0)
    80002acc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ace:	60e2                	ld	ra,24(sp)
    80002ad0:	6442                	ld	s0,16(sp)
    80002ad2:	64a2                	ld	s1,8(sp)
    80002ad4:	6105                	addi	sp,sp,32
    80002ad6:	8082                	ret
    return p->trapframe->a1;
    80002ad8:	6d3c                	ld	a5,88(a0)
    80002ada:	7fa8                	ld	a0,120(a5)
    80002adc:	bfcd                	j	80002ace <argraw+0x30>
    return p->trapframe->a2;
    80002ade:	6d3c                	ld	a5,88(a0)
    80002ae0:	63c8                	ld	a0,128(a5)
    80002ae2:	b7f5                	j	80002ace <argraw+0x30>
    return p->trapframe->a3;
    80002ae4:	6d3c                	ld	a5,88(a0)
    80002ae6:	67c8                	ld	a0,136(a5)
    80002ae8:	b7dd                	j	80002ace <argraw+0x30>
    return p->trapframe->a4;
    80002aea:	6d3c                	ld	a5,88(a0)
    80002aec:	6bc8                	ld	a0,144(a5)
    80002aee:	b7c5                	j	80002ace <argraw+0x30>
    return p->trapframe->a5;
    80002af0:	6d3c                	ld	a5,88(a0)
    80002af2:	6fc8                	ld	a0,152(a5)
    80002af4:	bfe9                	j	80002ace <argraw+0x30>
  panic("argraw");
    80002af6:	00006517          	auipc	a0,0x6
    80002afa:	8fa50513          	addi	a0,a0,-1798 # 800083f0 <states.0+0x148>
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a2c080e7          	jalr	-1492(ra) # 8000052a <panic>

0000000080002b06 <fetchaddr>:
{
    80002b06:	1101                	addi	sp,sp,-32
    80002b08:	ec06                	sd	ra,24(sp)
    80002b0a:	e822                	sd	s0,16(sp)
    80002b0c:	e426                	sd	s1,8(sp)
    80002b0e:	e04a                	sd	s2,0(sp)
    80002b10:	1000                	addi	s0,sp,32
    80002b12:	84aa                	mv	s1,a0
    80002b14:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	e7c080e7          	jalr	-388(ra) # 80001992 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002b1e:	653c                	ld	a5,72(a0)
    80002b20:	02f4f863          	bgeu	s1,a5,80002b50 <fetchaddr+0x4a>
    80002b24:	00848713          	addi	a4,s1,8
    80002b28:	02e7e663          	bltu	a5,a4,80002b54 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b2c:	46a1                	li	a3,8
    80002b2e:	8626                	mv	a2,s1
    80002b30:	85ca                	mv	a1,s2
    80002b32:	6928                	ld	a0,80(a0)
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	b96080e7          	jalr	-1130(ra) # 800016ca <copyin>
    80002b3c:	00a03533          	snez	a0,a0
    80002b40:	40a00533          	neg	a0,a0
}
    80002b44:	60e2                	ld	ra,24(sp)
    80002b46:	6442                	ld	s0,16(sp)
    80002b48:	64a2                	ld	s1,8(sp)
    80002b4a:	6902                	ld	s2,0(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret
    return -1;
    80002b50:	557d                	li	a0,-1
    80002b52:	bfcd                	j	80002b44 <fetchaddr+0x3e>
    80002b54:	557d                	li	a0,-1
    80002b56:	b7fd                	j	80002b44 <fetchaddr+0x3e>

0000000080002b58 <fetchstr>:
{
    80002b58:	7179                	addi	sp,sp,-48
    80002b5a:	f406                	sd	ra,40(sp)
    80002b5c:	f022                	sd	s0,32(sp)
    80002b5e:	ec26                	sd	s1,24(sp)
    80002b60:	e84a                	sd	s2,16(sp)
    80002b62:	e44e                	sd	s3,8(sp)
    80002b64:	1800                	addi	s0,sp,48
    80002b66:	892a                	mv	s2,a0
    80002b68:	84ae                	mv	s1,a1
    80002b6a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	e26080e7          	jalr	-474(ra) # 80001992 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b74:	86ce                	mv	a3,s3
    80002b76:	864a                	mv	a2,s2
    80002b78:	85a6                	mv	a1,s1
    80002b7a:	6928                	ld	a0,80(a0)
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	bdc080e7          	jalr	-1060(ra) # 80001758 <copyinstr>
  if (err < 0)
    80002b84:	00054763          	bltz	a0,80002b92 <fetchstr+0x3a>
  return strlen(buf);
    80002b88:	8526                	mv	a0,s1
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	2b8080e7          	jalr	696(ra) # 80000e42 <strlen>
}
    80002b92:	70a2                	ld	ra,40(sp)
    80002b94:	7402                	ld	s0,32(sp)
    80002b96:	64e2                	ld	s1,24(sp)
    80002b98:	6942                	ld	s2,16(sp)
    80002b9a:	69a2                	ld	s3,8(sp)
    80002b9c:	6145                	addi	sp,sp,48
    80002b9e:	8082                	ret

0000000080002ba0 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002ba0:	1101                	addi	sp,sp,-32
    80002ba2:	ec06                	sd	ra,24(sp)
    80002ba4:	e822                	sd	s0,16(sp)
    80002ba6:	e426                	sd	s1,8(sp)
    80002ba8:	1000                	addi	s0,sp,32
    80002baa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	ef2080e7          	jalr	-270(ra) # 80002a9e <argraw>
    80002bb4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bb6:	4501                	li	a0,0
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	64a2                	ld	s1,8(sp)
    80002bbe:	6105                	addi	sp,sp,32
    80002bc0:	8082                	ret

0000000080002bc2 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	1000                	addi	s0,sp,32
    80002bcc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	ed0080e7          	jalr	-304(ra) # 80002a9e <argraw>
    80002bd6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bd8:	4501                	li	a0,0
    80002bda:	60e2                	ld	ra,24(sp)
    80002bdc:	6442                	ld	s0,16(sp)
    80002bde:	64a2                	ld	s1,8(sp)
    80002be0:	6105                	addi	sp,sp,32
    80002be2:	8082                	ret

0000000080002be4 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002be4:	1101                	addi	sp,sp,-32
    80002be6:	ec06                	sd	ra,24(sp)
    80002be8:	e822                	sd	s0,16(sp)
    80002bea:	e426                	sd	s1,8(sp)
    80002bec:	e04a                	sd	s2,0(sp)
    80002bee:	1000                	addi	s0,sp,32
    80002bf0:	84ae                	mv	s1,a1
    80002bf2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	eaa080e7          	jalr	-342(ra) # 80002a9e <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bfc:	864a                	mv	a2,s2
    80002bfe:	85a6                	mv	a1,s1
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	f58080e7          	jalr	-168(ra) # 80002b58 <fetchstr>
}
    80002c08:	60e2                	ld	ra,24(sp)
    80002c0a:	6442                	ld	s0,16(sp)
    80002c0c:	64a2                	ld	s1,8(sp)
    80002c0e:	6902                	ld	s2,0(sp)
    80002c10:	6105                	addi	sp,sp,32
    80002c12:	8082                	ret

0000000080002c14 <syscall>:
    [SYS_mkdir] "sys_mkdir",
    [SYS_close] "sys_close",
    [SYS_trace] "sys_trace",
};
void syscall(void)
{
    80002c14:	7139                	addi	sp,sp,-64
    80002c16:	fc06                	sd	ra,56(sp)
    80002c18:	f822                	sd	s0,48(sp)
    80002c1a:	f426                	sd	s1,40(sp)
    80002c1c:	f04a                	sd	s2,32(sp)
    80002c1e:	ec4e                	sd	s3,24(sp)
    80002c20:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	d70080e7          	jalr	-656(ra) # 80001992 <myproc>
    80002c2a:	84aa                	mv	s1,a0
  int firstArg;
  num = p->trapframe->a7;
    80002c2c:	05853903          	ld	s2,88(a0)
    80002c30:	0a893783          	ld	a5,168(s2)
    80002c34:	0007899b          	sext.w	s3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002c38:	37fd                	addiw	a5,a5,-1
    80002c3a:	4755                	li	a4,21
    80002c3c:	0cf76563          	bltu	a4,a5,80002d06 <syscall+0xf2>
    80002c40:	00399713          	slli	a4,s3,0x3
    80002c44:	00006797          	auipc	a5,0x6
    80002c48:	96c78793          	addi	a5,a5,-1684 # 800085b0 <syscalls>
    80002c4c:	97ba                	add	a5,a5,a4
    80002c4e:	639c                	ld	a5,0(a5)
    80002c50:	cbdd                	beqz	a5,80002d06 <syscall+0xf2>
  {
    p->trapframe->a0 = syscalls[num]();
    80002c52:	9782                	jalr	a5
    80002c54:	06a93823          	sd	a0,112(s2)
    //start messing with code
    if ((p->traceMask & (1 << num)))
    80002c58:	58dc                	lw	a5,52(s1)
    80002c5a:	4137d7bb          	sraw	a5,a5,s3
    80002c5e:	8b85                	andi	a5,a5,1
    80002c60:	c3f1                	beqz	a5,80002d24 <syscall+0x110>
    {
      printf("%d: syscall %s ", p->pid, syscalls_str[num]);
    80002c62:	00399713          	slli	a4,s3,0x3
    80002c66:	00006797          	auipc	a5,0x6
    80002c6a:	94a78793          	addi	a5,a5,-1718 # 800085b0 <syscalls>
    80002c6e:	97ba                	add	a5,a5,a4
    80002c70:	7fd0                	ld	a2,184(a5)
    80002c72:	588c                	lw	a1,48(s1)
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	78450513          	addi	a0,a0,1924 # 800083f8 <states.0+0x150>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	8f8080e7          	jalr	-1800(ra) # 80000574 <printf>
      if (num == SYS_fork)
    80002c84:	4785                	li	a5,1
    80002c86:	02f98363          	beq	s3,a5,80002cac <syscall+0x98>
      {
        printf("NULL ");
      }
      if (num == SYS_kill)
    80002c8a:	4799                	li	a5,6
    80002c8c:	02f98963          	beq	s3,a5,80002cbe <syscall+0xaa>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      if (num == SYS_sbrk)
    80002c90:	47b1                	li	a5,12
    80002c92:	04f98863          	beq	s3,a5,80002ce2 <syscall+0xce>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      printf("-> %d\n", p->trapframe->a0);
    80002c96:	6cbc                	ld	a5,88(s1)
    80002c98:	7bac                	ld	a1,112(a5)
    80002c9a:	00005517          	auipc	a0,0x5
    80002c9e:	77e50513          	addi	a0,a0,1918 # 80008418 <states.0+0x170>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	8d2080e7          	jalr	-1838(ra) # 80000574 <printf>
    80002caa:	a8ad                	j	80002d24 <syscall+0x110>
        printf("NULL ");
    80002cac:	00005517          	auipc	a0,0x5
    80002cb0:	75c50513          	addi	a0,a0,1884 # 80008408 <states.0+0x160>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	8c0080e7          	jalr	-1856(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002cbc:	bfe9                	j	80002c96 <syscall+0x82>
        argint(0, &firstArg);
    80002cbe:	fcc40593          	addi	a1,s0,-52
    80002cc2:	4501                	li	a0,0
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	edc080e7          	jalr	-292(ra) # 80002ba0 <argint>
        printf("%d ", firstArg);
    80002ccc:	fcc42583          	lw	a1,-52(s0)
    80002cd0:	00005517          	auipc	a0,0x5
    80002cd4:	74050513          	addi	a0,a0,1856 # 80008410 <states.0+0x168>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	89c080e7          	jalr	-1892(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002ce0:	bf5d                	j	80002c96 <syscall+0x82>
        argint(0, &firstArg);
    80002ce2:	fcc40593          	addi	a1,s0,-52
    80002ce6:	4501                	li	a0,0
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	eb8080e7          	jalr	-328(ra) # 80002ba0 <argint>
        printf("%d ", firstArg);
    80002cf0:	fcc42583          	lw	a1,-52(s0)
    80002cf4:	00005517          	auipc	a0,0x5
    80002cf8:	71c50513          	addi	a0,a0,1820 # 80008410 <states.0+0x168>
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	878080e7          	jalr	-1928(ra) # 80000574 <printf>
    80002d04:	bf49                	j	80002c96 <syscall+0x82>
    }
    //end messing with code
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002d06:	86ce                	mv	a3,s3
    80002d08:	15848613          	addi	a2,s1,344
    80002d0c:	588c                	lw	a1,48(s1)
    80002d0e:	00005517          	auipc	a0,0x5
    80002d12:	71250513          	addi	a0,a0,1810 # 80008420 <states.0+0x178>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	85e080e7          	jalr	-1954(ra) # 80000574 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d1e:	6cbc                	ld	a5,88(s1)
    80002d20:	577d                	li	a4,-1
    80002d22:	fbb8                	sd	a4,112(a5)
  }
}
    80002d24:	70e2                	ld	ra,56(sp)
    80002d26:	7442                	ld	s0,48(sp)
    80002d28:	74a2                	ld	s1,40(sp)
    80002d2a:	7902                	ld	s2,32(sp)
    80002d2c:	69e2                	ld	s3,24(sp)
    80002d2e:	6121                	addi	sp,sp,64
    80002d30:	8082                	ret

0000000080002d32 <sys_trace>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_trace(void)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	1000                	addi	s0,sp,32
  int mask;
  int pid;
  argint(0, &mask);
    80002d3a:	fec40593          	addi	a1,s0,-20
    80002d3e:	4501                	li	a0,0
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	e60080e7          	jalr	-416(ra) # 80002ba0 <argint>
  if(argint(1, &pid) < 0)
    80002d48:	fe840593          	addi	a1,s0,-24
    80002d4c:	4505                	li	a0,1
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	e52080e7          	jalr	-430(ra) # 80002ba0 <argint>
    80002d56:	87aa                	mv	a5,a0
    return -1;
    80002d58:	557d                	li	a0,-1
  if(argint(1, &pid) < 0)
    80002d5a:	0007ca63          	bltz	a5,80002d6e <sys_trace+0x3c>
  return trace(mask, pid);
    80002d5e:	fe842583          	lw	a1,-24(s0)
    80002d62:	fec42503          	lw	a0,-20(s0)
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	6f8080e7          	jalr	1784(ra) # 8000245e <trace>
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	6105                	addi	sp,sp,32
    80002d74:	8082                	ret

0000000080002d76 <sys_exit>:

uint64
sys_exit(void)
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d7e:	fec40593          	addi	a1,s0,-20
    80002d82:	4501                	li	a0,0
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	e1c080e7          	jalr	-484(ra) # 80002ba0 <argint>
    return -1;
    80002d8c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d8e:	00054963          	bltz	a0,80002da0 <sys_exit+0x2a>
  exit(n);
    80002d92:	fec42503          	lw	a0,-20(s0)
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	552080e7          	jalr	1362(ra) # 800022e8 <exit>
  return 0;  // not reached
    80002d9e:	4781                	li	a5,0
}
    80002da0:	853e                	mv	a0,a5
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret

0000000080002daa <sys_getpid>:

uint64
sys_getpid(void)
{
    80002daa:	1141                	addi	sp,sp,-16
    80002dac:	e406                	sd	ra,8(sp)
    80002dae:	e022                	sd	s0,0(sp)
    80002db0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	be0080e7          	jalr	-1056(ra) # 80001992 <myproc>
}
    80002dba:	5908                	lw	a0,48(a0)
    80002dbc:	60a2                	ld	ra,8(sp)
    80002dbe:	6402                	ld	s0,0(sp)
    80002dc0:	0141                	addi	sp,sp,16
    80002dc2:	8082                	ret

0000000080002dc4 <sys_fork>:

uint64
sys_fork(void)
{
    80002dc4:	1141                	addi	sp,sp,-16
    80002dc6:	e406                	sd	ra,8(sp)
    80002dc8:	e022                	sd	s0,0(sp)
    80002dca:	0800                	addi	s0,sp,16
  return fork();
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	fc6080e7          	jalr	-58(ra) # 80001d92 <fork>
}
    80002dd4:	60a2                	ld	ra,8(sp)
    80002dd6:	6402                	ld	s0,0(sp)
    80002dd8:	0141                	addi	sp,sp,16
    80002dda:	8082                	ret

0000000080002ddc <sys_wait>:

uint64
sys_wait(void)
{
    80002ddc:	1101                	addi	sp,sp,-32
    80002dde:	ec06                	sd	ra,24(sp)
    80002de0:	e822                	sd	s0,16(sp)
    80002de2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002de4:	fe840593          	addi	a1,s0,-24
    80002de8:	4501                	li	a0,0
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	dd8080e7          	jalr	-552(ra) # 80002bc2 <argaddr>
    80002df2:	87aa                	mv	a5,a0
    return -1;
    80002df4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002df6:	0007c863          	bltz	a5,80002e06 <sys_wait+0x2a>
  return wait(p);
    80002dfa:	fe843503          	ld	a0,-24(s0)
    80002dfe:	fffff097          	auipc	ra,0xfffff
    80002e02:	2f2080e7          	jalr	754(ra) # 800020f0 <wait>
}
    80002e06:	60e2                	ld	ra,24(sp)
    80002e08:	6442                	ld	s0,16(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e0e:	7179                	addi	sp,sp,-48
    80002e10:	f406                	sd	ra,40(sp)
    80002e12:	f022                	sd	s0,32(sp)
    80002e14:	ec26                	sd	s1,24(sp)
    80002e16:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e18:	fdc40593          	addi	a1,s0,-36
    80002e1c:	4501                	li	a0,0
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	d82080e7          	jalr	-638(ra) # 80002ba0 <argint>
    return -1;
    80002e26:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002e28:	00054f63          	bltz	a0,80002e46 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	b66080e7          	jalr	-1178(ra) # 80001992 <myproc>
    80002e34:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e36:	fdc42503          	lw	a0,-36(s0)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	ee4080e7          	jalr	-284(ra) # 80001d1e <growproc>
    80002e42:	00054863          	bltz	a0,80002e52 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002e46:	8526                	mv	a0,s1
    80002e48:	70a2                	ld	ra,40(sp)
    80002e4a:	7402                	ld	s0,32(sp)
    80002e4c:	64e2                	ld	s1,24(sp)
    80002e4e:	6145                	addi	sp,sp,48
    80002e50:	8082                	ret
    return -1;
    80002e52:	54fd                	li	s1,-1
    80002e54:	bfcd                	j	80002e46 <sys_sbrk+0x38>

0000000080002e56 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e56:	7139                	addi	sp,sp,-64
    80002e58:	fc06                	sd	ra,56(sp)
    80002e5a:	f822                	sd	s0,48(sp)
    80002e5c:	f426                	sd	s1,40(sp)
    80002e5e:	f04a                	sd	s2,32(sp)
    80002e60:	ec4e                	sd	s3,24(sp)
    80002e62:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e64:	fcc40593          	addi	a1,s0,-52
    80002e68:	4501                	li	a0,0
    80002e6a:	00000097          	auipc	ra,0x0
    80002e6e:	d36080e7          	jalr	-714(ra) # 80002ba0 <argint>
    return -1;
    80002e72:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e74:	06054563          	bltz	a0,80002ede <sys_sleep+0x88>
  acquire(&tickslock);
    80002e78:	00014517          	auipc	a0,0x14
    80002e7c:	45850513          	addi	a0,a0,1112 # 800172d0 <tickslock>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	d42080e7          	jalr	-702(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002e88:	00006917          	auipc	s2,0x6
    80002e8c:	1a892903          	lw	s2,424(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e90:	fcc42783          	lw	a5,-52(s0)
    80002e94:	cf85                	beqz	a5,80002ecc <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e96:	00014997          	auipc	s3,0x14
    80002e9a:	43a98993          	addi	s3,s3,1082 # 800172d0 <tickslock>
    80002e9e:	00006497          	auipc	s1,0x6
    80002ea2:	19248493          	addi	s1,s1,402 # 80009030 <ticks>
    if(myproc()->killed){
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	aec080e7          	jalr	-1300(ra) # 80001992 <myproc>
    80002eae:	551c                	lw	a5,40(a0)
    80002eb0:	ef9d                	bnez	a5,80002eee <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002eb2:	85ce                	mv	a1,s3
    80002eb4:	8526                	mv	a0,s1
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	1d6080e7          	jalr	470(ra) # 8000208c <sleep>
  while(ticks - ticks0 < n){
    80002ebe:	409c                	lw	a5,0(s1)
    80002ec0:	412787bb          	subw	a5,a5,s2
    80002ec4:	fcc42703          	lw	a4,-52(s0)
    80002ec8:	fce7efe3          	bltu	a5,a4,80002ea6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ecc:	00014517          	auipc	a0,0x14
    80002ed0:	40450513          	addi	a0,a0,1028 # 800172d0 <tickslock>
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	da2080e7          	jalr	-606(ra) # 80000c76 <release>
  return 0;
    80002edc:	4781                	li	a5,0
}
    80002ede:	853e                	mv	a0,a5
    80002ee0:	70e2                	ld	ra,56(sp)
    80002ee2:	7442                	ld	s0,48(sp)
    80002ee4:	74a2                	ld	s1,40(sp)
    80002ee6:	7902                	ld	s2,32(sp)
    80002ee8:	69e2                	ld	s3,24(sp)
    80002eea:	6121                	addi	sp,sp,64
    80002eec:	8082                	ret
      release(&tickslock);
    80002eee:	00014517          	auipc	a0,0x14
    80002ef2:	3e250513          	addi	a0,a0,994 # 800172d0 <tickslock>
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	d80080e7          	jalr	-640(ra) # 80000c76 <release>
      return -1;
    80002efe:	57fd                	li	a5,-1
    80002f00:	bff9                	j	80002ede <sys_sleep+0x88>

0000000080002f02 <sys_kill>:

uint64
sys_kill(void)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f0a:	fec40593          	addi	a1,s0,-20
    80002f0e:	4501                	li	a0,0
    80002f10:	00000097          	auipc	ra,0x0
    80002f14:	c90080e7          	jalr	-880(ra) # 80002ba0 <argint>
    80002f18:	87aa                	mv	a5,a0
    return -1;
    80002f1a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f1c:	0007c863          	bltz	a5,80002f2c <sys_kill+0x2a>
  return kill(pid);
    80002f20:	fec42503          	lw	a0,-20(s0)
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	4c8080e7          	jalr	1224(ra) # 800023ec <kill>
}
    80002f2c:	60e2                	ld	ra,24(sp)
    80002f2e:	6442                	ld	s0,16(sp)
    80002f30:	6105                	addi	sp,sp,32
    80002f32:	8082                	ret

0000000080002f34 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f34:	1101                	addi	sp,sp,-32
    80002f36:	ec06                	sd	ra,24(sp)
    80002f38:	e822                	sd	s0,16(sp)
    80002f3a:	e426                	sd	s1,8(sp)
    80002f3c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f3e:	00014517          	auipc	a0,0x14
    80002f42:	39250513          	addi	a0,a0,914 # 800172d0 <tickslock>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	c7c080e7          	jalr	-900(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002f4e:	00006497          	auipc	s1,0x6
    80002f52:	0e24a483          	lw	s1,226(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f56:	00014517          	auipc	a0,0x14
    80002f5a:	37a50513          	addi	a0,a0,890 # 800172d0 <tickslock>
    80002f5e:	ffffe097          	auipc	ra,0xffffe
    80002f62:	d18080e7          	jalr	-744(ra) # 80000c76 <release>
  return xticks;
}
    80002f66:	02049513          	slli	a0,s1,0x20
    80002f6a:	9101                	srli	a0,a0,0x20
    80002f6c:	60e2                	ld	ra,24(sp)
    80002f6e:	6442                	ld	s0,16(sp)
    80002f70:	64a2                	ld	s1,8(sp)
    80002f72:	6105                	addi	sp,sp,32
    80002f74:	8082                	ret

0000000080002f76 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f76:	7179                	addi	sp,sp,-48
    80002f78:	f406                	sd	ra,40(sp)
    80002f7a:	f022                	sd	s0,32(sp)
    80002f7c:	ec26                	sd	s1,24(sp)
    80002f7e:	e84a                	sd	s2,16(sp)
    80002f80:	e44e                	sd	s3,8(sp)
    80002f82:	e052                	sd	s4,0(sp)
    80002f84:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f86:	00005597          	auipc	a1,0x5
    80002f8a:	79a58593          	addi	a1,a1,1946 # 80008720 <syscalls_str+0xb8>
    80002f8e:	00014517          	auipc	a0,0x14
    80002f92:	35a50513          	addi	a0,a0,858 # 800172e8 <bcache>
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	b9c080e7          	jalr	-1124(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f9e:	0001c797          	auipc	a5,0x1c
    80002fa2:	34a78793          	addi	a5,a5,842 # 8001f2e8 <bcache+0x8000>
    80002fa6:	0001c717          	auipc	a4,0x1c
    80002faa:	5aa70713          	addi	a4,a4,1450 # 8001f550 <bcache+0x8268>
    80002fae:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fb2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fb6:	00014497          	auipc	s1,0x14
    80002fba:	34a48493          	addi	s1,s1,842 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002fbe:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fc0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fc2:	00005a17          	auipc	s4,0x5
    80002fc6:	766a0a13          	addi	s4,s4,1894 # 80008728 <syscalls_str+0xc0>
    b->next = bcache.head.next;
    80002fca:	2b893783          	ld	a5,696(s2)
    80002fce:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fd0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fd4:	85d2                	mv	a1,s4
    80002fd6:	01048513          	addi	a0,s1,16
    80002fda:	00001097          	auipc	ra,0x1
    80002fde:	4c2080e7          	jalr	1218(ra) # 8000449c <initsleeplock>
    bcache.head.next->prev = b;
    80002fe2:	2b893783          	ld	a5,696(s2)
    80002fe6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fe8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fec:	45848493          	addi	s1,s1,1112
    80002ff0:	fd349de3          	bne	s1,s3,80002fca <binit+0x54>
  }
}
    80002ff4:	70a2                	ld	ra,40(sp)
    80002ff6:	7402                	ld	s0,32(sp)
    80002ff8:	64e2                	ld	s1,24(sp)
    80002ffa:	6942                	ld	s2,16(sp)
    80002ffc:	69a2                	ld	s3,8(sp)
    80002ffe:	6a02                	ld	s4,0(sp)
    80003000:	6145                	addi	sp,sp,48
    80003002:	8082                	ret

0000000080003004 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003004:	7179                	addi	sp,sp,-48
    80003006:	f406                	sd	ra,40(sp)
    80003008:	f022                	sd	s0,32(sp)
    8000300a:	ec26                	sd	s1,24(sp)
    8000300c:	e84a                	sd	s2,16(sp)
    8000300e:	e44e                	sd	s3,8(sp)
    80003010:	1800                	addi	s0,sp,48
    80003012:	892a                	mv	s2,a0
    80003014:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003016:	00014517          	auipc	a0,0x14
    8000301a:	2d250513          	addi	a0,a0,722 # 800172e8 <bcache>
    8000301e:	ffffe097          	auipc	ra,0xffffe
    80003022:	ba4080e7          	jalr	-1116(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003026:	0001c497          	auipc	s1,0x1c
    8000302a:	57a4b483          	ld	s1,1402(s1) # 8001f5a0 <bcache+0x82b8>
    8000302e:	0001c797          	auipc	a5,0x1c
    80003032:	52278793          	addi	a5,a5,1314 # 8001f550 <bcache+0x8268>
    80003036:	02f48f63          	beq	s1,a5,80003074 <bread+0x70>
    8000303a:	873e                	mv	a4,a5
    8000303c:	a021                	j	80003044 <bread+0x40>
    8000303e:	68a4                	ld	s1,80(s1)
    80003040:	02e48a63          	beq	s1,a4,80003074 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003044:	449c                	lw	a5,8(s1)
    80003046:	ff279ce3          	bne	a5,s2,8000303e <bread+0x3a>
    8000304a:	44dc                	lw	a5,12(s1)
    8000304c:	ff3799e3          	bne	a5,s3,8000303e <bread+0x3a>
      b->refcnt++;
    80003050:	40bc                	lw	a5,64(s1)
    80003052:	2785                	addiw	a5,a5,1
    80003054:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003056:	00014517          	auipc	a0,0x14
    8000305a:	29250513          	addi	a0,a0,658 # 800172e8 <bcache>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	c18080e7          	jalr	-1000(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003066:	01048513          	addi	a0,s1,16
    8000306a:	00001097          	auipc	ra,0x1
    8000306e:	46c080e7          	jalr	1132(ra) # 800044d6 <acquiresleep>
      return b;
    80003072:	a8b9                	j	800030d0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003074:	0001c497          	auipc	s1,0x1c
    80003078:	5244b483          	ld	s1,1316(s1) # 8001f598 <bcache+0x82b0>
    8000307c:	0001c797          	auipc	a5,0x1c
    80003080:	4d478793          	addi	a5,a5,1236 # 8001f550 <bcache+0x8268>
    80003084:	00f48863          	beq	s1,a5,80003094 <bread+0x90>
    80003088:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000308a:	40bc                	lw	a5,64(s1)
    8000308c:	cf81                	beqz	a5,800030a4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000308e:	64a4                	ld	s1,72(s1)
    80003090:	fee49de3          	bne	s1,a4,8000308a <bread+0x86>
  panic("bget: no buffers");
    80003094:	00005517          	auipc	a0,0x5
    80003098:	69c50513          	addi	a0,a0,1692 # 80008730 <syscalls_str+0xc8>
    8000309c:	ffffd097          	auipc	ra,0xffffd
    800030a0:	48e080e7          	jalr	1166(ra) # 8000052a <panic>
      b->dev = dev;
    800030a4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030a8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030ac:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030b0:	4785                	li	a5,1
    800030b2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030b4:	00014517          	auipc	a0,0x14
    800030b8:	23450513          	addi	a0,a0,564 # 800172e8 <bcache>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	bba080e7          	jalr	-1094(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800030c4:	01048513          	addi	a0,s1,16
    800030c8:	00001097          	auipc	ra,0x1
    800030cc:	40e080e7          	jalr	1038(ra) # 800044d6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030d0:	409c                	lw	a5,0(s1)
    800030d2:	cb89                	beqz	a5,800030e4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030d4:	8526                	mv	a0,s1
    800030d6:	70a2                	ld	ra,40(sp)
    800030d8:	7402                	ld	s0,32(sp)
    800030da:	64e2                	ld	s1,24(sp)
    800030dc:	6942                	ld	s2,16(sp)
    800030de:	69a2                	ld	s3,8(sp)
    800030e0:	6145                	addi	sp,sp,48
    800030e2:	8082                	ret
    virtio_disk_rw(b, 0);
    800030e4:	4581                	li	a1,0
    800030e6:	8526                	mv	a0,s1
    800030e8:	00003097          	auipc	ra,0x3
    800030ec:	f1e080e7          	jalr	-226(ra) # 80006006 <virtio_disk_rw>
    b->valid = 1;
    800030f0:	4785                	li	a5,1
    800030f2:	c09c                	sw	a5,0(s1)
  return b;
    800030f4:	b7c5                	j	800030d4 <bread+0xd0>

00000000800030f6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030f6:	1101                	addi	sp,sp,-32
    800030f8:	ec06                	sd	ra,24(sp)
    800030fa:	e822                	sd	s0,16(sp)
    800030fc:	e426                	sd	s1,8(sp)
    800030fe:	1000                	addi	s0,sp,32
    80003100:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003102:	0541                	addi	a0,a0,16
    80003104:	00001097          	auipc	ra,0x1
    80003108:	46c080e7          	jalr	1132(ra) # 80004570 <holdingsleep>
    8000310c:	cd01                	beqz	a0,80003124 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000310e:	4585                	li	a1,1
    80003110:	8526                	mv	a0,s1
    80003112:	00003097          	auipc	ra,0x3
    80003116:	ef4080e7          	jalr	-268(ra) # 80006006 <virtio_disk_rw>
}
    8000311a:	60e2                	ld	ra,24(sp)
    8000311c:	6442                	ld	s0,16(sp)
    8000311e:	64a2                	ld	s1,8(sp)
    80003120:	6105                	addi	sp,sp,32
    80003122:	8082                	ret
    panic("bwrite");
    80003124:	00005517          	auipc	a0,0x5
    80003128:	62450513          	addi	a0,a0,1572 # 80008748 <syscalls_str+0xe0>
    8000312c:	ffffd097          	auipc	ra,0xffffd
    80003130:	3fe080e7          	jalr	1022(ra) # 8000052a <panic>

0000000080003134 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	e426                	sd	s1,8(sp)
    8000313c:	e04a                	sd	s2,0(sp)
    8000313e:	1000                	addi	s0,sp,32
    80003140:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003142:	01050913          	addi	s2,a0,16
    80003146:	854a                	mv	a0,s2
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	428080e7          	jalr	1064(ra) # 80004570 <holdingsleep>
    80003150:	c92d                	beqz	a0,800031c2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003152:	854a                	mv	a0,s2
    80003154:	00001097          	auipc	ra,0x1
    80003158:	3d8080e7          	jalr	984(ra) # 8000452c <releasesleep>

  acquire(&bcache.lock);
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	18c50513          	addi	a0,a0,396 # 800172e8 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	a5e080e7          	jalr	-1442(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000316c:	40bc                	lw	a5,64(s1)
    8000316e:	37fd                	addiw	a5,a5,-1
    80003170:	0007871b          	sext.w	a4,a5
    80003174:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003176:	eb05                	bnez	a4,800031a6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003178:	68bc                	ld	a5,80(s1)
    8000317a:	64b8                	ld	a4,72(s1)
    8000317c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000317e:	64bc                	ld	a5,72(s1)
    80003180:	68b8                	ld	a4,80(s1)
    80003182:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003184:	0001c797          	auipc	a5,0x1c
    80003188:	16478793          	addi	a5,a5,356 # 8001f2e8 <bcache+0x8000>
    8000318c:	2b87b703          	ld	a4,696(a5)
    80003190:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003192:	0001c717          	auipc	a4,0x1c
    80003196:	3be70713          	addi	a4,a4,958 # 8001f550 <bcache+0x8268>
    8000319a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000319c:	2b87b703          	ld	a4,696(a5)
    800031a0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031a2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031a6:	00014517          	auipc	a0,0x14
    800031aa:	14250513          	addi	a0,a0,322 # 800172e8 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	ac8080e7          	jalr	-1336(ra) # 80000c76 <release>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6902                	ld	s2,0(sp)
    800031be:	6105                	addi	sp,sp,32
    800031c0:	8082                	ret
    panic("brelse");
    800031c2:	00005517          	auipc	a0,0x5
    800031c6:	58e50513          	addi	a0,a0,1422 # 80008750 <syscalls_str+0xe8>
    800031ca:	ffffd097          	auipc	ra,0xffffd
    800031ce:	360080e7          	jalr	864(ra) # 8000052a <panic>

00000000800031d2 <bpin>:

void
bpin(struct buf *b) {
    800031d2:	1101                	addi	sp,sp,-32
    800031d4:	ec06                	sd	ra,24(sp)
    800031d6:	e822                	sd	s0,16(sp)
    800031d8:	e426                	sd	s1,8(sp)
    800031da:	1000                	addi	s0,sp,32
    800031dc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	10a50513          	addi	a0,a0,266 # 800172e8 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	9dc080e7          	jalr	-1572(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800031ee:	40bc                	lw	a5,64(s1)
    800031f0:	2785                	addiw	a5,a5,1
    800031f2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031f4:	00014517          	auipc	a0,0x14
    800031f8:	0f450513          	addi	a0,a0,244 # 800172e8 <bcache>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	a7a080e7          	jalr	-1414(ra) # 80000c76 <release>
}
    80003204:	60e2                	ld	ra,24(sp)
    80003206:	6442                	ld	s0,16(sp)
    80003208:	64a2                	ld	s1,8(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret

000000008000320e <bunpin>:

void
bunpin(struct buf *b) {
    8000320e:	1101                	addi	sp,sp,-32
    80003210:	ec06                	sd	ra,24(sp)
    80003212:	e822                	sd	s0,16(sp)
    80003214:	e426                	sd	s1,8(sp)
    80003216:	1000                	addi	s0,sp,32
    80003218:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	0ce50513          	addi	a0,a0,206 # 800172e8 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	9a0080e7          	jalr	-1632(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000322a:	40bc                	lw	a5,64(s1)
    8000322c:	37fd                	addiw	a5,a5,-1
    8000322e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003230:	00014517          	auipc	a0,0x14
    80003234:	0b850513          	addi	a0,a0,184 # 800172e8 <bcache>
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	a3e080e7          	jalr	-1474(ra) # 80000c76 <release>
}
    80003240:	60e2                	ld	ra,24(sp)
    80003242:	6442                	ld	s0,16(sp)
    80003244:	64a2                	ld	s1,8(sp)
    80003246:	6105                	addi	sp,sp,32
    80003248:	8082                	ret

000000008000324a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000324a:	1101                	addi	sp,sp,-32
    8000324c:	ec06                	sd	ra,24(sp)
    8000324e:	e822                	sd	s0,16(sp)
    80003250:	e426                	sd	s1,8(sp)
    80003252:	e04a                	sd	s2,0(sp)
    80003254:	1000                	addi	s0,sp,32
    80003256:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003258:	00d5d59b          	srliw	a1,a1,0xd
    8000325c:	0001c797          	auipc	a5,0x1c
    80003260:	7687a783          	lw	a5,1896(a5) # 8001f9c4 <sb+0x1c>
    80003264:	9dbd                	addw	a1,a1,a5
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	d9e080e7          	jalr	-610(ra) # 80003004 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000326e:	0074f713          	andi	a4,s1,7
    80003272:	4785                	li	a5,1
    80003274:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003278:	14ce                	slli	s1,s1,0x33
    8000327a:	90d9                	srli	s1,s1,0x36
    8000327c:	00950733          	add	a4,a0,s1
    80003280:	05874703          	lbu	a4,88(a4)
    80003284:	00e7f6b3          	and	a3,a5,a4
    80003288:	c69d                	beqz	a3,800032b6 <bfree+0x6c>
    8000328a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000328c:	94aa                	add	s1,s1,a0
    8000328e:	fff7c793          	not	a5,a5
    80003292:	8ff9                	and	a5,a5,a4
    80003294:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003298:	00001097          	auipc	ra,0x1
    8000329c:	11e080e7          	jalr	286(ra) # 800043b6 <log_write>
  brelse(bp);
    800032a0:	854a                	mv	a0,s2
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	e92080e7          	jalr	-366(ra) # 80003134 <brelse>
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6902                	ld	s2,0(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret
    panic("freeing free block");
    800032b6:	00005517          	auipc	a0,0x5
    800032ba:	4a250513          	addi	a0,a0,1186 # 80008758 <syscalls_str+0xf0>
    800032be:	ffffd097          	auipc	ra,0xffffd
    800032c2:	26c080e7          	jalr	620(ra) # 8000052a <panic>

00000000800032c6 <balloc>:
{
    800032c6:	711d                	addi	sp,sp,-96
    800032c8:	ec86                	sd	ra,88(sp)
    800032ca:	e8a2                	sd	s0,80(sp)
    800032cc:	e4a6                	sd	s1,72(sp)
    800032ce:	e0ca                	sd	s2,64(sp)
    800032d0:	fc4e                	sd	s3,56(sp)
    800032d2:	f852                	sd	s4,48(sp)
    800032d4:	f456                	sd	s5,40(sp)
    800032d6:	f05a                	sd	s6,32(sp)
    800032d8:	ec5e                	sd	s7,24(sp)
    800032da:	e862                	sd	s8,16(sp)
    800032dc:	e466                	sd	s9,8(sp)
    800032de:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032e0:	0001c797          	auipc	a5,0x1c
    800032e4:	6cc7a783          	lw	a5,1740(a5) # 8001f9ac <sb+0x4>
    800032e8:	cbd1                	beqz	a5,8000337c <balloc+0xb6>
    800032ea:	8baa                	mv	s7,a0
    800032ec:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032ee:	0001cb17          	auipc	s6,0x1c
    800032f2:	6bab0b13          	addi	s6,s6,1722 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032f8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032fa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032fc:	6c89                	lui	s9,0x2
    800032fe:	a831                	j	8000331a <balloc+0x54>
    brelse(bp);
    80003300:	854a                	mv	a0,s2
    80003302:	00000097          	auipc	ra,0x0
    80003306:	e32080e7          	jalr	-462(ra) # 80003134 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000330a:	015c87bb          	addw	a5,s9,s5
    8000330e:	00078a9b          	sext.w	s5,a5
    80003312:	004b2703          	lw	a4,4(s6)
    80003316:	06eaf363          	bgeu	s5,a4,8000337c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000331a:	41fad79b          	sraiw	a5,s5,0x1f
    8000331e:	0137d79b          	srliw	a5,a5,0x13
    80003322:	015787bb          	addw	a5,a5,s5
    80003326:	40d7d79b          	sraiw	a5,a5,0xd
    8000332a:	01cb2583          	lw	a1,28(s6)
    8000332e:	9dbd                	addw	a1,a1,a5
    80003330:	855e                	mv	a0,s7
    80003332:	00000097          	auipc	ra,0x0
    80003336:	cd2080e7          	jalr	-814(ra) # 80003004 <bread>
    8000333a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333c:	004b2503          	lw	a0,4(s6)
    80003340:	000a849b          	sext.w	s1,s5
    80003344:	8662                	mv	a2,s8
    80003346:	faa4fde3          	bgeu	s1,a0,80003300 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000334a:	41f6579b          	sraiw	a5,a2,0x1f
    8000334e:	01d7d69b          	srliw	a3,a5,0x1d
    80003352:	00c6873b          	addw	a4,a3,a2
    80003356:	00777793          	andi	a5,a4,7
    8000335a:	9f95                	subw	a5,a5,a3
    8000335c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003360:	4037571b          	sraiw	a4,a4,0x3
    80003364:	00e906b3          	add	a3,s2,a4
    80003368:	0586c683          	lbu	a3,88(a3)
    8000336c:	00d7f5b3          	and	a1,a5,a3
    80003370:	cd91                	beqz	a1,8000338c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003372:	2605                	addiw	a2,a2,1
    80003374:	2485                	addiw	s1,s1,1
    80003376:	fd4618e3          	bne	a2,s4,80003346 <balloc+0x80>
    8000337a:	b759                	j	80003300 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000337c:	00005517          	auipc	a0,0x5
    80003380:	3f450513          	addi	a0,a0,1012 # 80008770 <syscalls_str+0x108>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	1a6080e7          	jalr	422(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000338c:	974a                	add	a4,a4,s2
    8000338e:	8fd5                	or	a5,a5,a3
    80003390:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003394:	854a                	mv	a0,s2
    80003396:	00001097          	auipc	ra,0x1
    8000339a:	020080e7          	jalr	32(ra) # 800043b6 <log_write>
        brelse(bp);
    8000339e:	854a                	mv	a0,s2
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	d94080e7          	jalr	-620(ra) # 80003134 <brelse>
  bp = bread(dev, bno);
    800033a8:	85a6                	mv	a1,s1
    800033aa:	855e                	mv	a0,s7
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	c58080e7          	jalr	-936(ra) # 80003004 <bread>
    800033b4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033b6:	40000613          	li	a2,1024
    800033ba:	4581                	li	a1,0
    800033bc:	05850513          	addi	a0,a0,88
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	8fe080e7          	jalr	-1794(ra) # 80000cbe <memset>
  log_write(bp);
    800033c8:	854a                	mv	a0,s2
    800033ca:	00001097          	auipc	ra,0x1
    800033ce:	fec080e7          	jalr	-20(ra) # 800043b6 <log_write>
  brelse(bp);
    800033d2:	854a                	mv	a0,s2
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	d60080e7          	jalr	-672(ra) # 80003134 <brelse>
}
    800033dc:	8526                	mv	a0,s1
    800033de:	60e6                	ld	ra,88(sp)
    800033e0:	6446                	ld	s0,80(sp)
    800033e2:	64a6                	ld	s1,72(sp)
    800033e4:	6906                	ld	s2,64(sp)
    800033e6:	79e2                	ld	s3,56(sp)
    800033e8:	7a42                	ld	s4,48(sp)
    800033ea:	7aa2                	ld	s5,40(sp)
    800033ec:	7b02                	ld	s6,32(sp)
    800033ee:	6be2                	ld	s7,24(sp)
    800033f0:	6c42                	ld	s8,16(sp)
    800033f2:	6ca2                	ld	s9,8(sp)
    800033f4:	6125                	addi	sp,sp,96
    800033f6:	8082                	ret

00000000800033f8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033f8:	7179                	addi	sp,sp,-48
    800033fa:	f406                	sd	ra,40(sp)
    800033fc:	f022                	sd	s0,32(sp)
    800033fe:	ec26                	sd	s1,24(sp)
    80003400:	e84a                	sd	s2,16(sp)
    80003402:	e44e                	sd	s3,8(sp)
    80003404:	e052                	sd	s4,0(sp)
    80003406:	1800                	addi	s0,sp,48
    80003408:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000340a:	47ad                	li	a5,11
    8000340c:	04b7fe63          	bgeu	a5,a1,80003468 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003410:	ff45849b          	addiw	s1,a1,-12
    80003414:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003418:	0ff00793          	li	a5,255
    8000341c:	0ae7e463          	bltu	a5,a4,800034c4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003420:	08052583          	lw	a1,128(a0)
    80003424:	c5b5                	beqz	a1,80003490 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003426:	00092503          	lw	a0,0(s2)
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	bda080e7          	jalr	-1062(ra) # 80003004 <bread>
    80003432:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003434:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003438:	02049713          	slli	a4,s1,0x20
    8000343c:	01e75593          	srli	a1,a4,0x1e
    80003440:	00b784b3          	add	s1,a5,a1
    80003444:	0004a983          	lw	s3,0(s1)
    80003448:	04098e63          	beqz	s3,800034a4 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000344c:	8552                	mv	a0,s4
    8000344e:	00000097          	auipc	ra,0x0
    80003452:	ce6080e7          	jalr	-794(ra) # 80003134 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003456:	854e                	mv	a0,s3
    80003458:	70a2                	ld	ra,40(sp)
    8000345a:	7402                	ld	s0,32(sp)
    8000345c:	64e2                	ld	s1,24(sp)
    8000345e:	6942                	ld	s2,16(sp)
    80003460:	69a2                	ld	s3,8(sp)
    80003462:	6a02                	ld	s4,0(sp)
    80003464:	6145                	addi	sp,sp,48
    80003466:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003468:	02059793          	slli	a5,a1,0x20
    8000346c:	01e7d593          	srli	a1,a5,0x1e
    80003470:	00b504b3          	add	s1,a0,a1
    80003474:	0504a983          	lw	s3,80(s1)
    80003478:	fc099fe3          	bnez	s3,80003456 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000347c:	4108                	lw	a0,0(a0)
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	e48080e7          	jalr	-440(ra) # 800032c6 <balloc>
    80003486:	0005099b          	sext.w	s3,a0
    8000348a:	0534a823          	sw	s3,80(s1)
    8000348e:	b7e1                	j	80003456 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003490:	4108                	lw	a0,0(a0)
    80003492:	00000097          	auipc	ra,0x0
    80003496:	e34080e7          	jalr	-460(ra) # 800032c6 <balloc>
    8000349a:	0005059b          	sext.w	a1,a0
    8000349e:	08b92023          	sw	a1,128(s2)
    800034a2:	b751                	j	80003426 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034a4:	00092503          	lw	a0,0(s2)
    800034a8:	00000097          	auipc	ra,0x0
    800034ac:	e1e080e7          	jalr	-482(ra) # 800032c6 <balloc>
    800034b0:	0005099b          	sext.w	s3,a0
    800034b4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034b8:	8552                	mv	a0,s4
    800034ba:	00001097          	auipc	ra,0x1
    800034be:	efc080e7          	jalr	-260(ra) # 800043b6 <log_write>
    800034c2:	b769                	j	8000344c <bmap+0x54>
  panic("bmap: out of range");
    800034c4:	00005517          	auipc	a0,0x5
    800034c8:	2c450513          	addi	a0,a0,708 # 80008788 <syscalls_str+0x120>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	05e080e7          	jalr	94(ra) # 8000052a <panic>

00000000800034d4 <iget>:
{
    800034d4:	7179                	addi	sp,sp,-48
    800034d6:	f406                	sd	ra,40(sp)
    800034d8:	f022                	sd	s0,32(sp)
    800034da:	ec26                	sd	s1,24(sp)
    800034dc:	e84a                	sd	s2,16(sp)
    800034de:	e44e                	sd	s3,8(sp)
    800034e0:	e052                	sd	s4,0(sp)
    800034e2:	1800                	addi	s0,sp,48
    800034e4:	89aa                	mv	s3,a0
    800034e6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034e8:	0001c517          	auipc	a0,0x1c
    800034ec:	4e050513          	addi	a0,a0,1248 # 8001f9c8 <itable>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	6d2080e7          	jalr	1746(ra) # 80000bc2 <acquire>
  empty = 0;
    800034f8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034fa:	0001c497          	auipc	s1,0x1c
    800034fe:	4e648493          	addi	s1,s1,1254 # 8001f9e0 <itable+0x18>
    80003502:	0001e697          	auipc	a3,0x1e
    80003506:	f6e68693          	addi	a3,a3,-146 # 80021470 <log>
    8000350a:	a039                	j	80003518 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000350c:	02090b63          	beqz	s2,80003542 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003510:	08848493          	addi	s1,s1,136
    80003514:	02d48a63          	beq	s1,a3,80003548 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003518:	449c                	lw	a5,8(s1)
    8000351a:	fef059e3          	blez	a5,8000350c <iget+0x38>
    8000351e:	4098                	lw	a4,0(s1)
    80003520:	ff3716e3          	bne	a4,s3,8000350c <iget+0x38>
    80003524:	40d8                	lw	a4,4(s1)
    80003526:	ff4713e3          	bne	a4,s4,8000350c <iget+0x38>
      ip->ref++;
    8000352a:	2785                	addiw	a5,a5,1
    8000352c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000352e:	0001c517          	auipc	a0,0x1c
    80003532:	49a50513          	addi	a0,a0,1178 # 8001f9c8 <itable>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	740080e7          	jalr	1856(ra) # 80000c76 <release>
      return ip;
    8000353e:	8926                	mv	s2,s1
    80003540:	a03d                	j	8000356e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003542:	f7f9                	bnez	a5,80003510 <iget+0x3c>
    80003544:	8926                	mv	s2,s1
    80003546:	b7e9                	j	80003510 <iget+0x3c>
  if(empty == 0)
    80003548:	02090c63          	beqz	s2,80003580 <iget+0xac>
  ip->dev = dev;
    8000354c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003550:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003554:	4785                	li	a5,1
    80003556:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000355a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000355e:	0001c517          	auipc	a0,0x1c
    80003562:	46a50513          	addi	a0,a0,1130 # 8001f9c8 <itable>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	710080e7          	jalr	1808(ra) # 80000c76 <release>
}
    8000356e:	854a                	mv	a0,s2
    80003570:	70a2                	ld	ra,40(sp)
    80003572:	7402                	ld	s0,32(sp)
    80003574:	64e2                	ld	s1,24(sp)
    80003576:	6942                	ld	s2,16(sp)
    80003578:	69a2                	ld	s3,8(sp)
    8000357a:	6a02                	ld	s4,0(sp)
    8000357c:	6145                	addi	sp,sp,48
    8000357e:	8082                	ret
    panic("iget: no inodes");
    80003580:	00005517          	auipc	a0,0x5
    80003584:	22050513          	addi	a0,a0,544 # 800087a0 <syscalls_str+0x138>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	fa2080e7          	jalr	-94(ra) # 8000052a <panic>

0000000080003590 <fsinit>:
fsinit(int dev) {
    80003590:	7179                	addi	sp,sp,-48
    80003592:	f406                	sd	ra,40(sp)
    80003594:	f022                	sd	s0,32(sp)
    80003596:	ec26                	sd	s1,24(sp)
    80003598:	e84a                	sd	s2,16(sp)
    8000359a:	e44e                	sd	s3,8(sp)
    8000359c:	1800                	addi	s0,sp,48
    8000359e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035a0:	4585                	li	a1,1
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	a62080e7          	jalr	-1438(ra) # 80003004 <bread>
    800035aa:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035ac:	0001c997          	auipc	s3,0x1c
    800035b0:	3fc98993          	addi	s3,s3,1020 # 8001f9a8 <sb>
    800035b4:	02000613          	li	a2,32
    800035b8:	05850593          	addi	a1,a0,88
    800035bc:	854e                	mv	a0,s3
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	75c080e7          	jalr	1884(ra) # 80000d1a <memmove>
  brelse(bp);
    800035c6:	8526                	mv	a0,s1
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	b6c080e7          	jalr	-1172(ra) # 80003134 <brelse>
  if(sb.magic != FSMAGIC)
    800035d0:	0009a703          	lw	a4,0(s3)
    800035d4:	102037b7          	lui	a5,0x10203
    800035d8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035dc:	02f71263          	bne	a4,a5,80003600 <fsinit+0x70>
  initlog(dev, &sb);
    800035e0:	0001c597          	auipc	a1,0x1c
    800035e4:	3c858593          	addi	a1,a1,968 # 8001f9a8 <sb>
    800035e8:	854a                	mv	a0,s2
    800035ea:	00001097          	auipc	ra,0x1
    800035ee:	b4e080e7          	jalr	-1202(ra) # 80004138 <initlog>
}
    800035f2:	70a2                	ld	ra,40(sp)
    800035f4:	7402                	ld	s0,32(sp)
    800035f6:	64e2                	ld	s1,24(sp)
    800035f8:	6942                	ld	s2,16(sp)
    800035fa:	69a2                	ld	s3,8(sp)
    800035fc:	6145                	addi	sp,sp,48
    800035fe:	8082                	ret
    panic("invalid file system");
    80003600:	00005517          	auipc	a0,0x5
    80003604:	1b050513          	addi	a0,a0,432 # 800087b0 <syscalls_str+0x148>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	f22080e7          	jalr	-222(ra) # 8000052a <panic>

0000000080003610 <iinit>:
{
    80003610:	7179                	addi	sp,sp,-48
    80003612:	f406                	sd	ra,40(sp)
    80003614:	f022                	sd	s0,32(sp)
    80003616:	ec26                	sd	s1,24(sp)
    80003618:	e84a                	sd	s2,16(sp)
    8000361a:	e44e                	sd	s3,8(sp)
    8000361c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000361e:	00005597          	auipc	a1,0x5
    80003622:	1aa58593          	addi	a1,a1,426 # 800087c8 <syscalls_str+0x160>
    80003626:	0001c517          	auipc	a0,0x1c
    8000362a:	3a250513          	addi	a0,a0,930 # 8001f9c8 <itable>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	504080e7          	jalr	1284(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003636:	0001c497          	auipc	s1,0x1c
    8000363a:	3ba48493          	addi	s1,s1,954 # 8001f9f0 <itable+0x28>
    8000363e:	0001e997          	auipc	s3,0x1e
    80003642:	e4298993          	addi	s3,s3,-446 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003646:	00005917          	auipc	s2,0x5
    8000364a:	18a90913          	addi	s2,s2,394 # 800087d0 <syscalls_str+0x168>
    8000364e:	85ca                	mv	a1,s2
    80003650:	8526                	mv	a0,s1
    80003652:	00001097          	auipc	ra,0x1
    80003656:	e4a080e7          	jalr	-438(ra) # 8000449c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000365a:	08848493          	addi	s1,s1,136
    8000365e:	ff3498e3          	bne	s1,s3,8000364e <iinit+0x3e>
}
    80003662:	70a2                	ld	ra,40(sp)
    80003664:	7402                	ld	s0,32(sp)
    80003666:	64e2                	ld	s1,24(sp)
    80003668:	6942                	ld	s2,16(sp)
    8000366a:	69a2                	ld	s3,8(sp)
    8000366c:	6145                	addi	sp,sp,48
    8000366e:	8082                	ret

0000000080003670 <ialloc>:
{
    80003670:	715d                	addi	sp,sp,-80
    80003672:	e486                	sd	ra,72(sp)
    80003674:	e0a2                	sd	s0,64(sp)
    80003676:	fc26                	sd	s1,56(sp)
    80003678:	f84a                	sd	s2,48(sp)
    8000367a:	f44e                	sd	s3,40(sp)
    8000367c:	f052                	sd	s4,32(sp)
    8000367e:	ec56                	sd	s5,24(sp)
    80003680:	e85a                	sd	s6,16(sp)
    80003682:	e45e                	sd	s7,8(sp)
    80003684:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003686:	0001c717          	auipc	a4,0x1c
    8000368a:	32e72703          	lw	a4,814(a4) # 8001f9b4 <sb+0xc>
    8000368e:	4785                	li	a5,1
    80003690:	04e7fa63          	bgeu	a5,a4,800036e4 <ialloc+0x74>
    80003694:	8aaa                	mv	s5,a0
    80003696:	8bae                	mv	s7,a1
    80003698:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000369a:	0001ca17          	auipc	s4,0x1c
    8000369e:	30ea0a13          	addi	s4,s4,782 # 8001f9a8 <sb>
    800036a2:	00048b1b          	sext.w	s6,s1
    800036a6:	0044d793          	srli	a5,s1,0x4
    800036aa:	018a2583          	lw	a1,24(s4)
    800036ae:	9dbd                	addw	a1,a1,a5
    800036b0:	8556                	mv	a0,s5
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	952080e7          	jalr	-1710(ra) # 80003004 <bread>
    800036ba:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036bc:	05850993          	addi	s3,a0,88
    800036c0:	00f4f793          	andi	a5,s1,15
    800036c4:	079a                	slli	a5,a5,0x6
    800036c6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036c8:	00099783          	lh	a5,0(s3)
    800036cc:	c785                	beqz	a5,800036f4 <ialloc+0x84>
    brelse(bp);
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	a66080e7          	jalr	-1434(ra) # 80003134 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036d6:	0485                	addi	s1,s1,1
    800036d8:	00ca2703          	lw	a4,12(s4)
    800036dc:	0004879b          	sext.w	a5,s1
    800036e0:	fce7e1e3          	bltu	a5,a4,800036a2 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036e4:	00005517          	auipc	a0,0x5
    800036e8:	0f450513          	addi	a0,a0,244 # 800087d8 <syscalls_str+0x170>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	e3e080e7          	jalr	-450(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800036f4:	04000613          	li	a2,64
    800036f8:	4581                	li	a1,0
    800036fa:	854e                	mv	a0,s3
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	5c2080e7          	jalr	1474(ra) # 80000cbe <memset>
      dip->type = type;
    80003704:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003708:	854a                	mv	a0,s2
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	cac080e7          	jalr	-852(ra) # 800043b6 <log_write>
      brelse(bp);
    80003712:	854a                	mv	a0,s2
    80003714:	00000097          	auipc	ra,0x0
    80003718:	a20080e7          	jalr	-1504(ra) # 80003134 <brelse>
      return iget(dev, inum);
    8000371c:	85da                	mv	a1,s6
    8000371e:	8556                	mv	a0,s5
    80003720:	00000097          	auipc	ra,0x0
    80003724:	db4080e7          	jalr	-588(ra) # 800034d4 <iget>
}
    80003728:	60a6                	ld	ra,72(sp)
    8000372a:	6406                	ld	s0,64(sp)
    8000372c:	74e2                	ld	s1,56(sp)
    8000372e:	7942                	ld	s2,48(sp)
    80003730:	79a2                	ld	s3,40(sp)
    80003732:	7a02                	ld	s4,32(sp)
    80003734:	6ae2                	ld	s5,24(sp)
    80003736:	6b42                	ld	s6,16(sp)
    80003738:	6ba2                	ld	s7,8(sp)
    8000373a:	6161                	addi	sp,sp,80
    8000373c:	8082                	ret

000000008000373e <iupdate>:
{
    8000373e:	1101                	addi	sp,sp,-32
    80003740:	ec06                	sd	ra,24(sp)
    80003742:	e822                	sd	s0,16(sp)
    80003744:	e426                	sd	s1,8(sp)
    80003746:	e04a                	sd	s2,0(sp)
    80003748:	1000                	addi	s0,sp,32
    8000374a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000374c:	415c                	lw	a5,4(a0)
    8000374e:	0047d79b          	srliw	a5,a5,0x4
    80003752:	0001c597          	auipc	a1,0x1c
    80003756:	26e5a583          	lw	a1,622(a1) # 8001f9c0 <sb+0x18>
    8000375a:	9dbd                	addw	a1,a1,a5
    8000375c:	4108                	lw	a0,0(a0)
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	8a6080e7          	jalr	-1882(ra) # 80003004 <bread>
    80003766:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003768:	05850793          	addi	a5,a0,88
    8000376c:	40c8                	lw	a0,4(s1)
    8000376e:	893d                	andi	a0,a0,15
    80003770:	051a                	slli	a0,a0,0x6
    80003772:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003774:	04449703          	lh	a4,68(s1)
    80003778:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000377c:	04649703          	lh	a4,70(s1)
    80003780:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003784:	04849703          	lh	a4,72(s1)
    80003788:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000378c:	04a49703          	lh	a4,74(s1)
    80003790:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003794:	44f8                	lw	a4,76(s1)
    80003796:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003798:	03400613          	li	a2,52
    8000379c:	05048593          	addi	a1,s1,80
    800037a0:	0531                	addi	a0,a0,12
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	578080e7          	jalr	1400(ra) # 80000d1a <memmove>
  log_write(bp);
    800037aa:	854a                	mv	a0,s2
    800037ac:	00001097          	auipc	ra,0x1
    800037b0:	c0a080e7          	jalr	-1014(ra) # 800043b6 <log_write>
  brelse(bp);
    800037b4:	854a                	mv	a0,s2
    800037b6:	00000097          	auipc	ra,0x0
    800037ba:	97e080e7          	jalr	-1666(ra) # 80003134 <brelse>
}
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6902                	ld	s2,0(sp)
    800037c6:	6105                	addi	sp,sp,32
    800037c8:	8082                	ret

00000000800037ca <idup>:
{
    800037ca:	1101                	addi	sp,sp,-32
    800037cc:	ec06                	sd	ra,24(sp)
    800037ce:	e822                	sd	s0,16(sp)
    800037d0:	e426                	sd	s1,8(sp)
    800037d2:	1000                	addi	s0,sp,32
    800037d4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037d6:	0001c517          	auipc	a0,0x1c
    800037da:	1f250513          	addi	a0,a0,498 # 8001f9c8 <itable>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	3e4080e7          	jalr	996(ra) # 80000bc2 <acquire>
  ip->ref++;
    800037e6:	449c                	lw	a5,8(s1)
    800037e8:	2785                	addiw	a5,a5,1
    800037ea:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037ec:	0001c517          	auipc	a0,0x1c
    800037f0:	1dc50513          	addi	a0,a0,476 # 8001f9c8 <itable>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	482080e7          	jalr	1154(ra) # 80000c76 <release>
}
    800037fc:	8526                	mv	a0,s1
    800037fe:	60e2                	ld	ra,24(sp)
    80003800:	6442                	ld	s0,16(sp)
    80003802:	64a2                	ld	s1,8(sp)
    80003804:	6105                	addi	sp,sp,32
    80003806:	8082                	ret

0000000080003808 <ilock>:
{
    80003808:	1101                	addi	sp,sp,-32
    8000380a:	ec06                	sd	ra,24(sp)
    8000380c:	e822                	sd	s0,16(sp)
    8000380e:	e426                	sd	s1,8(sp)
    80003810:	e04a                	sd	s2,0(sp)
    80003812:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003814:	c115                	beqz	a0,80003838 <ilock+0x30>
    80003816:	84aa                	mv	s1,a0
    80003818:	451c                	lw	a5,8(a0)
    8000381a:	00f05f63          	blez	a5,80003838 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000381e:	0541                	addi	a0,a0,16
    80003820:	00001097          	auipc	ra,0x1
    80003824:	cb6080e7          	jalr	-842(ra) # 800044d6 <acquiresleep>
  if(ip->valid == 0){
    80003828:	40bc                	lw	a5,64(s1)
    8000382a:	cf99                	beqz	a5,80003848 <ilock+0x40>
}
    8000382c:	60e2                	ld	ra,24(sp)
    8000382e:	6442                	ld	s0,16(sp)
    80003830:	64a2                	ld	s1,8(sp)
    80003832:	6902                	ld	s2,0(sp)
    80003834:	6105                	addi	sp,sp,32
    80003836:	8082                	ret
    panic("ilock");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	fb850513          	addi	a0,a0,-72 # 800087f0 <syscalls_str+0x188>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	cea080e7          	jalr	-790(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003848:	40dc                	lw	a5,4(s1)
    8000384a:	0047d79b          	srliw	a5,a5,0x4
    8000384e:	0001c597          	auipc	a1,0x1c
    80003852:	1725a583          	lw	a1,370(a1) # 8001f9c0 <sb+0x18>
    80003856:	9dbd                	addw	a1,a1,a5
    80003858:	4088                	lw	a0,0(s1)
    8000385a:	fffff097          	auipc	ra,0xfffff
    8000385e:	7aa080e7          	jalr	1962(ra) # 80003004 <bread>
    80003862:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003864:	05850593          	addi	a1,a0,88
    80003868:	40dc                	lw	a5,4(s1)
    8000386a:	8bbd                	andi	a5,a5,15
    8000386c:	079a                	slli	a5,a5,0x6
    8000386e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003870:	00059783          	lh	a5,0(a1)
    80003874:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003878:	00259783          	lh	a5,2(a1)
    8000387c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003880:	00459783          	lh	a5,4(a1)
    80003884:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003888:	00659783          	lh	a5,6(a1)
    8000388c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003890:	459c                	lw	a5,8(a1)
    80003892:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003894:	03400613          	li	a2,52
    80003898:	05b1                	addi	a1,a1,12
    8000389a:	05048513          	addi	a0,s1,80
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	47c080e7          	jalr	1148(ra) # 80000d1a <memmove>
    brelse(bp);
    800038a6:	854a                	mv	a0,s2
    800038a8:	00000097          	auipc	ra,0x0
    800038ac:	88c080e7          	jalr	-1908(ra) # 80003134 <brelse>
    ip->valid = 1;
    800038b0:	4785                	li	a5,1
    800038b2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038b4:	04449783          	lh	a5,68(s1)
    800038b8:	fbb5                	bnez	a5,8000382c <ilock+0x24>
      panic("ilock: no type");
    800038ba:	00005517          	auipc	a0,0x5
    800038be:	f3e50513          	addi	a0,a0,-194 # 800087f8 <syscalls_str+0x190>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	c68080e7          	jalr	-920(ra) # 8000052a <panic>

00000000800038ca <iunlock>:
{
    800038ca:	1101                	addi	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	e426                	sd	s1,8(sp)
    800038d2:	e04a                	sd	s2,0(sp)
    800038d4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038d6:	c905                	beqz	a0,80003906 <iunlock+0x3c>
    800038d8:	84aa                	mv	s1,a0
    800038da:	01050913          	addi	s2,a0,16
    800038de:	854a                	mv	a0,s2
    800038e0:	00001097          	auipc	ra,0x1
    800038e4:	c90080e7          	jalr	-880(ra) # 80004570 <holdingsleep>
    800038e8:	cd19                	beqz	a0,80003906 <iunlock+0x3c>
    800038ea:	449c                	lw	a5,8(s1)
    800038ec:	00f05d63          	blez	a5,80003906 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038f0:	854a                	mv	a0,s2
    800038f2:	00001097          	auipc	ra,0x1
    800038f6:	c3a080e7          	jalr	-966(ra) # 8000452c <releasesleep>
}
    800038fa:	60e2                	ld	ra,24(sp)
    800038fc:	6442                	ld	s0,16(sp)
    800038fe:	64a2                	ld	s1,8(sp)
    80003900:	6902                	ld	s2,0(sp)
    80003902:	6105                	addi	sp,sp,32
    80003904:	8082                	ret
    panic("iunlock");
    80003906:	00005517          	auipc	a0,0x5
    8000390a:	f0250513          	addi	a0,a0,-254 # 80008808 <syscalls_str+0x1a0>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	c1c080e7          	jalr	-996(ra) # 8000052a <panic>

0000000080003916 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003916:	7179                	addi	sp,sp,-48
    80003918:	f406                	sd	ra,40(sp)
    8000391a:	f022                	sd	s0,32(sp)
    8000391c:	ec26                	sd	s1,24(sp)
    8000391e:	e84a                	sd	s2,16(sp)
    80003920:	e44e                	sd	s3,8(sp)
    80003922:	e052                	sd	s4,0(sp)
    80003924:	1800                	addi	s0,sp,48
    80003926:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003928:	05050493          	addi	s1,a0,80
    8000392c:	08050913          	addi	s2,a0,128
    80003930:	a021                	j	80003938 <itrunc+0x22>
    80003932:	0491                	addi	s1,s1,4
    80003934:	01248d63          	beq	s1,s2,8000394e <itrunc+0x38>
    if(ip->addrs[i]){
    80003938:	408c                	lw	a1,0(s1)
    8000393a:	dde5                	beqz	a1,80003932 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000393c:	0009a503          	lw	a0,0(s3)
    80003940:	00000097          	auipc	ra,0x0
    80003944:	90a080e7          	jalr	-1782(ra) # 8000324a <bfree>
      ip->addrs[i] = 0;
    80003948:	0004a023          	sw	zero,0(s1)
    8000394c:	b7dd                	j	80003932 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000394e:	0809a583          	lw	a1,128(s3)
    80003952:	e185                	bnez	a1,80003972 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003954:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003958:	854e                	mv	a0,s3
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	de4080e7          	jalr	-540(ra) # 8000373e <iupdate>
}
    80003962:	70a2                	ld	ra,40(sp)
    80003964:	7402                	ld	s0,32(sp)
    80003966:	64e2                	ld	s1,24(sp)
    80003968:	6942                	ld	s2,16(sp)
    8000396a:	69a2                	ld	s3,8(sp)
    8000396c:	6a02                	ld	s4,0(sp)
    8000396e:	6145                	addi	sp,sp,48
    80003970:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003972:	0009a503          	lw	a0,0(s3)
    80003976:	fffff097          	auipc	ra,0xfffff
    8000397a:	68e080e7          	jalr	1678(ra) # 80003004 <bread>
    8000397e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003980:	05850493          	addi	s1,a0,88
    80003984:	45850913          	addi	s2,a0,1112
    80003988:	a021                	j	80003990 <itrunc+0x7a>
    8000398a:	0491                	addi	s1,s1,4
    8000398c:	01248b63          	beq	s1,s2,800039a2 <itrunc+0x8c>
      if(a[j])
    80003990:	408c                	lw	a1,0(s1)
    80003992:	dde5                	beqz	a1,8000398a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003994:	0009a503          	lw	a0,0(s3)
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	8b2080e7          	jalr	-1870(ra) # 8000324a <bfree>
    800039a0:	b7ed                	j	8000398a <itrunc+0x74>
    brelse(bp);
    800039a2:	8552                	mv	a0,s4
    800039a4:	fffff097          	auipc	ra,0xfffff
    800039a8:	790080e7          	jalr	1936(ra) # 80003134 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039ac:	0809a583          	lw	a1,128(s3)
    800039b0:	0009a503          	lw	a0,0(s3)
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	896080e7          	jalr	-1898(ra) # 8000324a <bfree>
    ip->addrs[NDIRECT] = 0;
    800039bc:	0809a023          	sw	zero,128(s3)
    800039c0:	bf51                	j	80003954 <itrunc+0x3e>

00000000800039c2 <iput>:
{
    800039c2:	1101                	addi	sp,sp,-32
    800039c4:	ec06                	sd	ra,24(sp)
    800039c6:	e822                	sd	s0,16(sp)
    800039c8:	e426                	sd	s1,8(sp)
    800039ca:	e04a                	sd	s2,0(sp)
    800039cc:	1000                	addi	s0,sp,32
    800039ce:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039d0:	0001c517          	auipc	a0,0x1c
    800039d4:	ff850513          	addi	a0,a0,-8 # 8001f9c8 <itable>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	1ea080e7          	jalr	490(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039e0:	4498                	lw	a4,8(s1)
    800039e2:	4785                	li	a5,1
    800039e4:	02f70363          	beq	a4,a5,80003a0a <iput+0x48>
  ip->ref--;
    800039e8:	449c                	lw	a5,8(s1)
    800039ea:	37fd                	addiw	a5,a5,-1
    800039ec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ee:	0001c517          	auipc	a0,0x1c
    800039f2:	fda50513          	addi	a0,a0,-38 # 8001f9c8 <itable>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	280080e7          	jalr	640(ra) # 80000c76 <release>
}
    800039fe:	60e2                	ld	ra,24(sp)
    80003a00:	6442                	ld	s0,16(sp)
    80003a02:	64a2                	ld	s1,8(sp)
    80003a04:	6902                	ld	s2,0(sp)
    80003a06:	6105                	addi	sp,sp,32
    80003a08:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a0a:	40bc                	lw	a5,64(s1)
    80003a0c:	dff1                	beqz	a5,800039e8 <iput+0x26>
    80003a0e:	04a49783          	lh	a5,74(s1)
    80003a12:	fbf9                	bnez	a5,800039e8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a14:	01048913          	addi	s2,s1,16
    80003a18:	854a                	mv	a0,s2
    80003a1a:	00001097          	auipc	ra,0x1
    80003a1e:	abc080e7          	jalr	-1348(ra) # 800044d6 <acquiresleep>
    release(&itable.lock);
    80003a22:	0001c517          	auipc	a0,0x1c
    80003a26:	fa650513          	addi	a0,a0,-90 # 8001f9c8 <itable>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	24c080e7          	jalr	588(ra) # 80000c76 <release>
    itrunc(ip);
    80003a32:	8526                	mv	a0,s1
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	ee2080e7          	jalr	-286(ra) # 80003916 <itrunc>
    ip->type = 0;
    80003a3c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a40:	8526                	mv	a0,s1
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	cfc080e7          	jalr	-772(ra) # 8000373e <iupdate>
    ip->valid = 0;
    80003a4a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a4e:	854a                	mv	a0,s2
    80003a50:	00001097          	auipc	ra,0x1
    80003a54:	adc080e7          	jalr	-1316(ra) # 8000452c <releasesleep>
    acquire(&itable.lock);
    80003a58:	0001c517          	auipc	a0,0x1c
    80003a5c:	f7050513          	addi	a0,a0,-144 # 8001f9c8 <itable>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	162080e7          	jalr	354(ra) # 80000bc2 <acquire>
    80003a68:	b741                	j	800039e8 <iput+0x26>

0000000080003a6a <iunlockput>:
{
    80003a6a:	1101                	addi	sp,sp,-32
    80003a6c:	ec06                	sd	ra,24(sp)
    80003a6e:	e822                	sd	s0,16(sp)
    80003a70:	e426                	sd	s1,8(sp)
    80003a72:	1000                	addi	s0,sp,32
    80003a74:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	e54080e7          	jalr	-428(ra) # 800038ca <iunlock>
  iput(ip);
    80003a7e:	8526                	mv	a0,s1
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	f42080e7          	jalr	-190(ra) # 800039c2 <iput>
}
    80003a88:	60e2                	ld	ra,24(sp)
    80003a8a:	6442                	ld	s0,16(sp)
    80003a8c:	64a2                	ld	s1,8(sp)
    80003a8e:	6105                	addi	sp,sp,32
    80003a90:	8082                	ret

0000000080003a92 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a92:	1141                	addi	sp,sp,-16
    80003a94:	e422                	sd	s0,8(sp)
    80003a96:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a98:	411c                	lw	a5,0(a0)
    80003a9a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a9c:	415c                	lw	a5,4(a0)
    80003a9e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aa0:	04451783          	lh	a5,68(a0)
    80003aa4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003aa8:	04a51783          	lh	a5,74(a0)
    80003aac:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ab0:	04c56783          	lwu	a5,76(a0)
    80003ab4:	e99c                	sd	a5,16(a1)
}
    80003ab6:	6422                	ld	s0,8(sp)
    80003ab8:	0141                	addi	sp,sp,16
    80003aba:	8082                	ret

0000000080003abc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003abc:	457c                	lw	a5,76(a0)
    80003abe:	0ed7e963          	bltu	a5,a3,80003bb0 <readi+0xf4>
{
    80003ac2:	7159                	addi	sp,sp,-112
    80003ac4:	f486                	sd	ra,104(sp)
    80003ac6:	f0a2                	sd	s0,96(sp)
    80003ac8:	eca6                	sd	s1,88(sp)
    80003aca:	e8ca                	sd	s2,80(sp)
    80003acc:	e4ce                	sd	s3,72(sp)
    80003ace:	e0d2                	sd	s4,64(sp)
    80003ad0:	fc56                	sd	s5,56(sp)
    80003ad2:	f85a                	sd	s6,48(sp)
    80003ad4:	f45e                	sd	s7,40(sp)
    80003ad6:	f062                	sd	s8,32(sp)
    80003ad8:	ec66                	sd	s9,24(sp)
    80003ada:	e86a                	sd	s10,16(sp)
    80003adc:	e46e                	sd	s11,8(sp)
    80003ade:	1880                	addi	s0,sp,112
    80003ae0:	8baa                	mv	s7,a0
    80003ae2:	8c2e                	mv	s8,a1
    80003ae4:	8ab2                	mv	s5,a2
    80003ae6:	84b6                	mv	s1,a3
    80003ae8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aea:	9f35                	addw	a4,a4,a3
    return 0;
    80003aec:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aee:	0ad76063          	bltu	a4,a3,80003b8e <readi+0xd2>
  if(off + n > ip->size)
    80003af2:	00e7f463          	bgeu	a5,a4,80003afa <readi+0x3e>
    n = ip->size - off;
    80003af6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003afa:	0a0b0963          	beqz	s6,80003bac <readi+0xf0>
    80003afe:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b00:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b04:	5cfd                	li	s9,-1
    80003b06:	a82d                	j	80003b40 <readi+0x84>
    80003b08:	020a1d93          	slli	s11,s4,0x20
    80003b0c:	020ddd93          	srli	s11,s11,0x20
    80003b10:	05890793          	addi	a5,s2,88
    80003b14:	86ee                	mv	a3,s11
    80003b16:	963e                	add	a2,a2,a5
    80003b18:	85d6                	mv	a1,s5
    80003b1a:	8562                	mv	a0,s8
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	9ac080e7          	jalr	-1620(ra) # 800024c8 <either_copyout>
    80003b24:	05950d63          	beq	a0,s9,80003b7e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b28:	854a                	mv	a0,s2
    80003b2a:	fffff097          	auipc	ra,0xfffff
    80003b2e:	60a080e7          	jalr	1546(ra) # 80003134 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b32:	013a09bb          	addw	s3,s4,s3
    80003b36:	009a04bb          	addw	s1,s4,s1
    80003b3a:	9aee                	add	s5,s5,s11
    80003b3c:	0569f763          	bgeu	s3,s6,80003b8a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b40:	000ba903          	lw	s2,0(s7)
    80003b44:	00a4d59b          	srliw	a1,s1,0xa
    80003b48:	855e                	mv	a0,s7
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	8ae080e7          	jalr	-1874(ra) # 800033f8 <bmap>
    80003b52:	0005059b          	sext.w	a1,a0
    80003b56:	854a                	mv	a0,s2
    80003b58:	fffff097          	auipc	ra,0xfffff
    80003b5c:	4ac080e7          	jalr	1196(ra) # 80003004 <bread>
    80003b60:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b62:	3ff4f613          	andi	a2,s1,1023
    80003b66:	40cd07bb          	subw	a5,s10,a2
    80003b6a:	413b073b          	subw	a4,s6,s3
    80003b6e:	8a3e                	mv	s4,a5
    80003b70:	2781                	sext.w	a5,a5
    80003b72:	0007069b          	sext.w	a3,a4
    80003b76:	f8f6f9e3          	bgeu	a3,a5,80003b08 <readi+0x4c>
    80003b7a:	8a3a                	mv	s4,a4
    80003b7c:	b771                	j	80003b08 <readi+0x4c>
      brelse(bp);
    80003b7e:	854a                	mv	a0,s2
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	5b4080e7          	jalr	1460(ra) # 80003134 <brelse>
      tot = -1;
    80003b88:	59fd                	li	s3,-1
  }
  return tot;
    80003b8a:	0009851b          	sext.w	a0,s3
}
    80003b8e:	70a6                	ld	ra,104(sp)
    80003b90:	7406                	ld	s0,96(sp)
    80003b92:	64e6                	ld	s1,88(sp)
    80003b94:	6946                	ld	s2,80(sp)
    80003b96:	69a6                	ld	s3,72(sp)
    80003b98:	6a06                	ld	s4,64(sp)
    80003b9a:	7ae2                	ld	s5,56(sp)
    80003b9c:	7b42                	ld	s6,48(sp)
    80003b9e:	7ba2                	ld	s7,40(sp)
    80003ba0:	7c02                	ld	s8,32(sp)
    80003ba2:	6ce2                	ld	s9,24(sp)
    80003ba4:	6d42                	ld	s10,16(sp)
    80003ba6:	6da2                	ld	s11,8(sp)
    80003ba8:	6165                	addi	sp,sp,112
    80003baa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bac:	89da                	mv	s3,s6
    80003bae:	bff1                	j	80003b8a <readi+0xce>
    return 0;
    80003bb0:	4501                	li	a0,0
}
    80003bb2:	8082                	ret

0000000080003bb4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb4:	457c                	lw	a5,76(a0)
    80003bb6:	10d7e863          	bltu	a5,a3,80003cc6 <writei+0x112>
{
    80003bba:	7159                	addi	sp,sp,-112
    80003bbc:	f486                	sd	ra,104(sp)
    80003bbe:	f0a2                	sd	s0,96(sp)
    80003bc0:	eca6                	sd	s1,88(sp)
    80003bc2:	e8ca                	sd	s2,80(sp)
    80003bc4:	e4ce                	sd	s3,72(sp)
    80003bc6:	e0d2                	sd	s4,64(sp)
    80003bc8:	fc56                	sd	s5,56(sp)
    80003bca:	f85a                	sd	s6,48(sp)
    80003bcc:	f45e                	sd	s7,40(sp)
    80003bce:	f062                	sd	s8,32(sp)
    80003bd0:	ec66                	sd	s9,24(sp)
    80003bd2:	e86a                	sd	s10,16(sp)
    80003bd4:	e46e                	sd	s11,8(sp)
    80003bd6:	1880                	addi	s0,sp,112
    80003bd8:	8b2a                	mv	s6,a0
    80003bda:	8c2e                	mv	s8,a1
    80003bdc:	8ab2                	mv	s5,a2
    80003bde:	8936                	mv	s2,a3
    80003be0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003be2:	00e687bb          	addw	a5,a3,a4
    80003be6:	0ed7e263          	bltu	a5,a3,80003cca <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bea:	00043737          	lui	a4,0x43
    80003bee:	0ef76063          	bltu	a4,a5,80003cce <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf2:	0c0b8863          	beqz	s7,80003cc2 <writei+0x10e>
    80003bf6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bfc:	5cfd                	li	s9,-1
    80003bfe:	a091                	j	80003c42 <writei+0x8e>
    80003c00:	02099d93          	slli	s11,s3,0x20
    80003c04:	020ddd93          	srli	s11,s11,0x20
    80003c08:	05848793          	addi	a5,s1,88
    80003c0c:	86ee                	mv	a3,s11
    80003c0e:	8656                	mv	a2,s5
    80003c10:	85e2                	mv	a1,s8
    80003c12:	953e                	add	a0,a0,a5
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	90a080e7          	jalr	-1782(ra) # 8000251e <either_copyin>
    80003c1c:	07950263          	beq	a0,s9,80003c80 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c20:	8526                	mv	a0,s1
    80003c22:	00000097          	auipc	ra,0x0
    80003c26:	794080e7          	jalr	1940(ra) # 800043b6 <log_write>
    brelse(bp);
    80003c2a:	8526                	mv	a0,s1
    80003c2c:	fffff097          	auipc	ra,0xfffff
    80003c30:	508080e7          	jalr	1288(ra) # 80003134 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c34:	01498a3b          	addw	s4,s3,s4
    80003c38:	0129893b          	addw	s2,s3,s2
    80003c3c:	9aee                	add	s5,s5,s11
    80003c3e:	057a7663          	bgeu	s4,s7,80003c8a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c42:	000b2483          	lw	s1,0(s6)
    80003c46:	00a9559b          	srliw	a1,s2,0xa
    80003c4a:	855a                	mv	a0,s6
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	7ac080e7          	jalr	1964(ra) # 800033f8 <bmap>
    80003c54:	0005059b          	sext.w	a1,a0
    80003c58:	8526                	mv	a0,s1
    80003c5a:	fffff097          	auipc	ra,0xfffff
    80003c5e:	3aa080e7          	jalr	938(ra) # 80003004 <bread>
    80003c62:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c64:	3ff97513          	andi	a0,s2,1023
    80003c68:	40ad07bb          	subw	a5,s10,a0
    80003c6c:	414b873b          	subw	a4,s7,s4
    80003c70:	89be                	mv	s3,a5
    80003c72:	2781                	sext.w	a5,a5
    80003c74:	0007069b          	sext.w	a3,a4
    80003c78:	f8f6f4e3          	bgeu	a3,a5,80003c00 <writei+0x4c>
    80003c7c:	89ba                	mv	s3,a4
    80003c7e:	b749                	j	80003c00 <writei+0x4c>
      brelse(bp);
    80003c80:	8526                	mv	a0,s1
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	4b2080e7          	jalr	1202(ra) # 80003134 <brelse>
  }

  if(off > ip->size)
    80003c8a:	04cb2783          	lw	a5,76(s6)
    80003c8e:	0127f463          	bgeu	a5,s2,80003c96 <writei+0xe2>
    ip->size = off;
    80003c92:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c96:	855a                	mv	a0,s6
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	aa6080e7          	jalr	-1370(ra) # 8000373e <iupdate>

  return tot;
    80003ca0:	000a051b          	sext.w	a0,s4
}
    80003ca4:	70a6                	ld	ra,104(sp)
    80003ca6:	7406                	ld	s0,96(sp)
    80003ca8:	64e6                	ld	s1,88(sp)
    80003caa:	6946                	ld	s2,80(sp)
    80003cac:	69a6                	ld	s3,72(sp)
    80003cae:	6a06                	ld	s4,64(sp)
    80003cb0:	7ae2                	ld	s5,56(sp)
    80003cb2:	7b42                	ld	s6,48(sp)
    80003cb4:	7ba2                	ld	s7,40(sp)
    80003cb6:	7c02                	ld	s8,32(sp)
    80003cb8:	6ce2                	ld	s9,24(sp)
    80003cba:	6d42                	ld	s10,16(sp)
    80003cbc:	6da2                	ld	s11,8(sp)
    80003cbe:	6165                	addi	sp,sp,112
    80003cc0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc2:	8a5e                	mv	s4,s7
    80003cc4:	bfc9                	j	80003c96 <writei+0xe2>
    return -1;
    80003cc6:	557d                	li	a0,-1
}
    80003cc8:	8082                	ret
    return -1;
    80003cca:	557d                	li	a0,-1
    80003ccc:	bfe1                	j	80003ca4 <writei+0xf0>
    return -1;
    80003cce:	557d                	li	a0,-1
    80003cd0:	bfd1                	j	80003ca4 <writei+0xf0>

0000000080003cd2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cd2:	1141                	addi	sp,sp,-16
    80003cd4:	e406                	sd	ra,8(sp)
    80003cd6:	e022                	sd	s0,0(sp)
    80003cd8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cda:	4639                	li	a2,14
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	0ba080e7          	jalr	186(ra) # 80000d96 <strncmp>
}
    80003ce4:	60a2                	ld	ra,8(sp)
    80003ce6:	6402                	ld	s0,0(sp)
    80003ce8:	0141                	addi	sp,sp,16
    80003cea:	8082                	ret

0000000080003cec <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cec:	7139                	addi	sp,sp,-64
    80003cee:	fc06                	sd	ra,56(sp)
    80003cf0:	f822                	sd	s0,48(sp)
    80003cf2:	f426                	sd	s1,40(sp)
    80003cf4:	f04a                	sd	s2,32(sp)
    80003cf6:	ec4e                	sd	s3,24(sp)
    80003cf8:	e852                	sd	s4,16(sp)
    80003cfa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cfc:	04451703          	lh	a4,68(a0)
    80003d00:	4785                	li	a5,1
    80003d02:	00f71a63          	bne	a4,a5,80003d16 <dirlookup+0x2a>
    80003d06:	892a                	mv	s2,a0
    80003d08:	89ae                	mv	s3,a1
    80003d0a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d0c:	457c                	lw	a5,76(a0)
    80003d0e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d10:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d12:	e79d                	bnez	a5,80003d40 <dirlookup+0x54>
    80003d14:	a8a5                	j	80003d8c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d16:	00005517          	auipc	a0,0x5
    80003d1a:	afa50513          	addi	a0,a0,-1286 # 80008810 <syscalls_str+0x1a8>
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	80c080e7          	jalr	-2036(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003d26:	00005517          	auipc	a0,0x5
    80003d2a:	b0250513          	addi	a0,a0,-1278 # 80008828 <syscalls_str+0x1c0>
    80003d2e:	ffffc097          	auipc	ra,0xffffc
    80003d32:	7fc080e7          	jalr	2044(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d36:	24c1                	addiw	s1,s1,16
    80003d38:	04c92783          	lw	a5,76(s2)
    80003d3c:	04f4f763          	bgeu	s1,a5,80003d8a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d40:	4741                	li	a4,16
    80003d42:	86a6                	mv	a3,s1
    80003d44:	fc040613          	addi	a2,s0,-64
    80003d48:	4581                	li	a1,0
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	d70080e7          	jalr	-656(ra) # 80003abc <readi>
    80003d54:	47c1                	li	a5,16
    80003d56:	fcf518e3          	bne	a0,a5,80003d26 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d5a:	fc045783          	lhu	a5,-64(s0)
    80003d5e:	dfe1                	beqz	a5,80003d36 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d60:	fc240593          	addi	a1,s0,-62
    80003d64:	854e                	mv	a0,s3
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	f6c080e7          	jalr	-148(ra) # 80003cd2 <namecmp>
    80003d6e:	f561                	bnez	a0,80003d36 <dirlookup+0x4a>
      if(poff)
    80003d70:	000a0463          	beqz	s4,80003d78 <dirlookup+0x8c>
        *poff = off;
    80003d74:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d78:	fc045583          	lhu	a1,-64(s0)
    80003d7c:	00092503          	lw	a0,0(s2)
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	754080e7          	jalr	1876(ra) # 800034d4 <iget>
    80003d88:	a011                	j	80003d8c <dirlookup+0xa0>
  return 0;
    80003d8a:	4501                	li	a0,0
}
    80003d8c:	70e2                	ld	ra,56(sp)
    80003d8e:	7442                	ld	s0,48(sp)
    80003d90:	74a2                	ld	s1,40(sp)
    80003d92:	7902                	ld	s2,32(sp)
    80003d94:	69e2                	ld	s3,24(sp)
    80003d96:	6a42                	ld	s4,16(sp)
    80003d98:	6121                	addi	sp,sp,64
    80003d9a:	8082                	ret

0000000080003d9c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d9c:	711d                	addi	sp,sp,-96
    80003d9e:	ec86                	sd	ra,88(sp)
    80003da0:	e8a2                	sd	s0,80(sp)
    80003da2:	e4a6                	sd	s1,72(sp)
    80003da4:	e0ca                	sd	s2,64(sp)
    80003da6:	fc4e                	sd	s3,56(sp)
    80003da8:	f852                	sd	s4,48(sp)
    80003daa:	f456                	sd	s5,40(sp)
    80003dac:	f05a                	sd	s6,32(sp)
    80003dae:	ec5e                	sd	s7,24(sp)
    80003db0:	e862                	sd	s8,16(sp)
    80003db2:	e466                	sd	s9,8(sp)
    80003db4:	1080                	addi	s0,sp,96
    80003db6:	84aa                	mv	s1,a0
    80003db8:	8aae                	mv	s5,a1
    80003dba:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dbc:	00054703          	lbu	a4,0(a0)
    80003dc0:	02f00793          	li	a5,47
    80003dc4:	02f70363          	beq	a4,a5,80003dea <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dc8:	ffffe097          	auipc	ra,0xffffe
    80003dcc:	bca080e7          	jalr	-1078(ra) # 80001992 <myproc>
    80003dd0:	15053503          	ld	a0,336(a0)
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	9f6080e7          	jalr	-1546(ra) # 800037ca <idup>
    80003ddc:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dde:	02f00913          	li	s2,47
  len = path - s;
    80003de2:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003de4:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003de6:	4b85                	li	s7,1
    80003de8:	a865                	j	80003ea0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003dea:	4585                	li	a1,1
    80003dec:	4505                	li	a0,1
    80003dee:	fffff097          	auipc	ra,0xfffff
    80003df2:	6e6080e7          	jalr	1766(ra) # 800034d4 <iget>
    80003df6:	89aa                	mv	s3,a0
    80003df8:	b7dd                	j	80003dde <namex+0x42>
      iunlockput(ip);
    80003dfa:	854e                	mv	a0,s3
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	c6e080e7          	jalr	-914(ra) # 80003a6a <iunlockput>
      return 0;
    80003e04:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e06:	854e                	mv	a0,s3
    80003e08:	60e6                	ld	ra,88(sp)
    80003e0a:	6446                	ld	s0,80(sp)
    80003e0c:	64a6                	ld	s1,72(sp)
    80003e0e:	6906                	ld	s2,64(sp)
    80003e10:	79e2                	ld	s3,56(sp)
    80003e12:	7a42                	ld	s4,48(sp)
    80003e14:	7aa2                	ld	s5,40(sp)
    80003e16:	7b02                	ld	s6,32(sp)
    80003e18:	6be2                	ld	s7,24(sp)
    80003e1a:	6c42                	ld	s8,16(sp)
    80003e1c:	6ca2                	ld	s9,8(sp)
    80003e1e:	6125                	addi	sp,sp,96
    80003e20:	8082                	ret
      iunlock(ip);
    80003e22:	854e                	mv	a0,s3
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	aa6080e7          	jalr	-1370(ra) # 800038ca <iunlock>
      return ip;
    80003e2c:	bfe9                	j	80003e06 <namex+0x6a>
      iunlockput(ip);
    80003e2e:	854e                	mv	a0,s3
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	c3a080e7          	jalr	-966(ra) # 80003a6a <iunlockput>
      return 0;
    80003e38:	89e6                	mv	s3,s9
    80003e3a:	b7f1                	j	80003e06 <namex+0x6a>
  len = path - s;
    80003e3c:	40b48633          	sub	a2,s1,a1
    80003e40:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e44:	099c5463          	bge	s8,s9,80003ecc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e48:	4639                	li	a2,14
    80003e4a:	8552                	mv	a0,s4
    80003e4c:	ffffd097          	auipc	ra,0xffffd
    80003e50:	ece080e7          	jalr	-306(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003e54:	0004c783          	lbu	a5,0(s1)
    80003e58:	01279763          	bne	a5,s2,80003e66 <namex+0xca>
    path++;
    80003e5c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e5e:	0004c783          	lbu	a5,0(s1)
    80003e62:	ff278de3          	beq	a5,s2,80003e5c <namex+0xc0>
    ilock(ip);
    80003e66:	854e                	mv	a0,s3
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	9a0080e7          	jalr	-1632(ra) # 80003808 <ilock>
    if(ip->type != T_DIR){
    80003e70:	04499783          	lh	a5,68(s3)
    80003e74:	f97793e3          	bne	a5,s7,80003dfa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e78:	000a8563          	beqz	s5,80003e82 <namex+0xe6>
    80003e7c:	0004c783          	lbu	a5,0(s1)
    80003e80:	d3cd                	beqz	a5,80003e22 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e82:	865a                	mv	a2,s6
    80003e84:	85d2                	mv	a1,s4
    80003e86:	854e                	mv	a0,s3
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	e64080e7          	jalr	-412(ra) # 80003cec <dirlookup>
    80003e90:	8caa                	mv	s9,a0
    80003e92:	dd51                	beqz	a0,80003e2e <namex+0x92>
    iunlockput(ip);
    80003e94:	854e                	mv	a0,s3
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	bd4080e7          	jalr	-1068(ra) # 80003a6a <iunlockput>
    ip = next;
    80003e9e:	89e6                	mv	s3,s9
  while(*path == '/')
    80003ea0:	0004c783          	lbu	a5,0(s1)
    80003ea4:	05279763          	bne	a5,s2,80003ef2 <namex+0x156>
    path++;
    80003ea8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eaa:	0004c783          	lbu	a5,0(s1)
    80003eae:	ff278de3          	beq	a5,s2,80003ea8 <namex+0x10c>
  if(*path == 0)
    80003eb2:	c79d                	beqz	a5,80003ee0 <namex+0x144>
    path++;
    80003eb4:	85a6                	mv	a1,s1
  len = path - s;
    80003eb6:	8cda                	mv	s9,s6
    80003eb8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003eba:	01278963          	beq	a5,s2,80003ecc <namex+0x130>
    80003ebe:	dfbd                	beqz	a5,80003e3c <namex+0xa0>
    path++;
    80003ec0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ec2:	0004c783          	lbu	a5,0(s1)
    80003ec6:	ff279ce3          	bne	a5,s2,80003ebe <namex+0x122>
    80003eca:	bf8d                	j	80003e3c <namex+0xa0>
    memmove(name, s, len);
    80003ecc:	2601                	sext.w	a2,a2
    80003ece:	8552                	mv	a0,s4
    80003ed0:	ffffd097          	auipc	ra,0xffffd
    80003ed4:	e4a080e7          	jalr	-438(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003ed8:	9cd2                	add	s9,s9,s4
    80003eda:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003ede:	bf9d                	j	80003e54 <namex+0xb8>
  if(nameiparent){
    80003ee0:	f20a83e3          	beqz	s5,80003e06 <namex+0x6a>
    iput(ip);
    80003ee4:	854e                	mv	a0,s3
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	adc080e7          	jalr	-1316(ra) # 800039c2 <iput>
    return 0;
    80003eee:	4981                	li	s3,0
    80003ef0:	bf19                	j	80003e06 <namex+0x6a>
  if(*path == 0)
    80003ef2:	d7fd                	beqz	a5,80003ee0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ef4:	0004c783          	lbu	a5,0(s1)
    80003ef8:	85a6                	mv	a1,s1
    80003efa:	b7d1                	j	80003ebe <namex+0x122>

0000000080003efc <dirlink>:
{
    80003efc:	7139                	addi	sp,sp,-64
    80003efe:	fc06                	sd	ra,56(sp)
    80003f00:	f822                	sd	s0,48(sp)
    80003f02:	f426                	sd	s1,40(sp)
    80003f04:	f04a                	sd	s2,32(sp)
    80003f06:	ec4e                	sd	s3,24(sp)
    80003f08:	e852                	sd	s4,16(sp)
    80003f0a:	0080                	addi	s0,sp,64
    80003f0c:	892a                	mv	s2,a0
    80003f0e:	8a2e                	mv	s4,a1
    80003f10:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f12:	4601                	li	a2,0
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	dd8080e7          	jalr	-552(ra) # 80003cec <dirlookup>
    80003f1c:	e93d                	bnez	a0,80003f92 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f1e:	04c92483          	lw	s1,76(s2)
    80003f22:	c49d                	beqz	s1,80003f50 <dirlink+0x54>
    80003f24:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f26:	4741                	li	a4,16
    80003f28:	86a6                	mv	a3,s1
    80003f2a:	fc040613          	addi	a2,s0,-64
    80003f2e:	4581                	li	a1,0
    80003f30:	854a                	mv	a0,s2
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	b8a080e7          	jalr	-1142(ra) # 80003abc <readi>
    80003f3a:	47c1                	li	a5,16
    80003f3c:	06f51163          	bne	a0,a5,80003f9e <dirlink+0xa2>
    if(de.inum == 0)
    80003f40:	fc045783          	lhu	a5,-64(s0)
    80003f44:	c791                	beqz	a5,80003f50 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f46:	24c1                	addiw	s1,s1,16
    80003f48:	04c92783          	lw	a5,76(s2)
    80003f4c:	fcf4ede3          	bltu	s1,a5,80003f26 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f50:	4639                	li	a2,14
    80003f52:	85d2                	mv	a1,s4
    80003f54:	fc240513          	addi	a0,s0,-62
    80003f58:	ffffd097          	auipc	ra,0xffffd
    80003f5c:	e7a080e7          	jalr	-390(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003f60:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f64:	4741                	li	a4,16
    80003f66:	86a6                	mv	a3,s1
    80003f68:	fc040613          	addi	a2,s0,-64
    80003f6c:	4581                	li	a1,0
    80003f6e:	854a                	mv	a0,s2
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	c44080e7          	jalr	-956(ra) # 80003bb4 <writei>
    80003f78:	872a                	mv	a4,a0
    80003f7a:	47c1                	li	a5,16
  return 0;
    80003f7c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7e:	02f71863          	bne	a4,a5,80003fae <dirlink+0xb2>
}
    80003f82:	70e2                	ld	ra,56(sp)
    80003f84:	7442                	ld	s0,48(sp)
    80003f86:	74a2                	ld	s1,40(sp)
    80003f88:	7902                	ld	s2,32(sp)
    80003f8a:	69e2                	ld	s3,24(sp)
    80003f8c:	6a42                	ld	s4,16(sp)
    80003f8e:	6121                	addi	sp,sp,64
    80003f90:	8082                	ret
    iput(ip);
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	a30080e7          	jalr	-1488(ra) # 800039c2 <iput>
    return -1;
    80003f9a:	557d                	li	a0,-1
    80003f9c:	b7dd                	j	80003f82 <dirlink+0x86>
      panic("dirlink read");
    80003f9e:	00005517          	auipc	a0,0x5
    80003fa2:	89a50513          	addi	a0,a0,-1894 # 80008838 <syscalls_str+0x1d0>
    80003fa6:	ffffc097          	auipc	ra,0xffffc
    80003faa:	584080e7          	jalr	1412(ra) # 8000052a <panic>
    panic("dirlink");
    80003fae:	00005517          	auipc	a0,0x5
    80003fb2:	99a50513          	addi	a0,a0,-1638 # 80008948 <syscalls_str+0x2e0>
    80003fb6:	ffffc097          	auipc	ra,0xffffc
    80003fba:	574080e7          	jalr	1396(ra) # 8000052a <panic>

0000000080003fbe <namei>:

struct inode*
namei(char *path)
{
    80003fbe:	1101                	addi	sp,sp,-32
    80003fc0:	ec06                	sd	ra,24(sp)
    80003fc2:	e822                	sd	s0,16(sp)
    80003fc4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fc6:	fe040613          	addi	a2,s0,-32
    80003fca:	4581                	li	a1,0
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	dd0080e7          	jalr	-560(ra) # 80003d9c <namex>
}
    80003fd4:	60e2                	ld	ra,24(sp)
    80003fd6:	6442                	ld	s0,16(sp)
    80003fd8:	6105                	addi	sp,sp,32
    80003fda:	8082                	ret

0000000080003fdc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fdc:	1141                	addi	sp,sp,-16
    80003fde:	e406                	sd	ra,8(sp)
    80003fe0:	e022                	sd	s0,0(sp)
    80003fe2:	0800                	addi	s0,sp,16
    80003fe4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fe6:	4585                	li	a1,1
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	db4080e7          	jalr	-588(ra) # 80003d9c <namex>
}
    80003ff0:	60a2                	ld	ra,8(sp)
    80003ff2:	6402                	ld	s0,0(sp)
    80003ff4:	0141                	addi	sp,sp,16
    80003ff6:	8082                	ret

0000000080003ff8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ff8:	1101                	addi	sp,sp,-32
    80003ffa:	ec06                	sd	ra,24(sp)
    80003ffc:	e822                	sd	s0,16(sp)
    80003ffe:	e426                	sd	s1,8(sp)
    80004000:	e04a                	sd	s2,0(sp)
    80004002:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004004:	0001d917          	auipc	s2,0x1d
    80004008:	46c90913          	addi	s2,s2,1132 # 80021470 <log>
    8000400c:	01892583          	lw	a1,24(s2)
    80004010:	02892503          	lw	a0,40(s2)
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	ff0080e7          	jalr	-16(ra) # 80003004 <bread>
    8000401c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000401e:	02c92683          	lw	a3,44(s2)
    80004022:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004024:	02d05863          	blez	a3,80004054 <write_head+0x5c>
    80004028:	0001d797          	auipc	a5,0x1d
    8000402c:	47878793          	addi	a5,a5,1144 # 800214a0 <log+0x30>
    80004030:	05c50713          	addi	a4,a0,92
    80004034:	36fd                	addiw	a3,a3,-1
    80004036:	02069613          	slli	a2,a3,0x20
    8000403a:	01e65693          	srli	a3,a2,0x1e
    8000403e:	0001d617          	auipc	a2,0x1d
    80004042:	46660613          	addi	a2,a2,1126 # 800214a4 <log+0x34>
    80004046:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004048:	4390                	lw	a2,0(a5)
    8000404a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000404c:	0791                	addi	a5,a5,4
    8000404e:	0711                	addi	a4,a4,4
    80004050:	fed79ce3          	bne	a5,a3,80004048 <write_head+0x50>
  }
  bwrite(buf);
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	0a0080e7          	jalr	160(ra) # 800030f6 <bwrite>
  brelse(buf);
    8000405e:	8526                	mv	a0,s1
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	0d4080e7          	jalr	212(ra) # 80003134 <brelse>
}
    80004068:	60e2                	ld	ra,24(sp)
    8000406a:	6442                	ld	s0,16(sp)
    8000406c:	64a2                	ld	s1,8(sp)
    8000406e:	6902                	ld	s2,0(sp)
    80004070:	6105                	addi	sp,sp,32
    80004072:	8082                	ret

0000000080004074 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004074:	0001d797          	auipc	a5,0x1d
    80004078:	4287a783          	lw	a5,1064(a5) # 8002149c <log+0x2c>
    8000407c:	0af05d63          	blez	a5,80004136 <install_trans+0xc2>
{
    80004080:	7139                	addi	sp,sp,-64
    80004082:	fc06                	sd	ra,56(sp)
    80004084:	f822                	sd	s0,48(sp)
    80004086:	f426                	sd	s1,40(sp)
    80004088:	f04a                	sd	s2,32(sp)
    8000408a:	ec4e                	sd	s3,24(sp)
    8000408c:	e852                	sd	s4,16(sp)
    8000408e:	e456                	sd	s5,8(sp)
    80004090:	e05a                	sd	s6,0(sp)
    80004092:	0080                	addi	s0,sp,64
    80004094:	8b2a                	mv	s6,a0
    80004096:	0001da97          	auipc	s5,0x1d
    8000409a:	40aa8a93          	addi	s5,s5,1034 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000409e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040a0:	0001d997          	auipc	s3,0x1d
    800040a4:	3d098993          	addi	s3,s3,976 # 80021470 <log>
    800040a8:	a00d                	j	800040ca <install_trans+0x56>
    brelse(lbuf);
    800040aa:	854a                	mv	a0,s2
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	088080e7          	jalr	136(ra) # 80003134 <brelse>
    brelse(dbuf);
    800040b4:	8526                	mv	a0,s1
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	07e080e7          	jalr	126(ra) # 80003134 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040be:	2a05                	addiw	s4,s4,1
    800040c0:	0a91                	addi	s5,s5,4
    800040c2:	02c9a783          	lw	a5,44(s3)
    800040c6:	04fa5e63          	bge	s4,a5,80004122 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ca:	0189a583          	lw	a1,24(s3)
    800040ce:	014585bb          	addw	a1,a1,s4
    800040d2:	2585                	addiw	a1,a1,1
    800040d4:	0289a503          	lw	a0,40(s3)
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	f2c080e7          	jalr	-212(ra) # 80003004 <bread>
    800040e0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040e2:	000aa583          	lw	a1,0(s5)
    800040e6:	0289a503          	lw	a0,40(s3)
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	f1a080e7          	jalr	-230(ra) # 80003004 <bread>
    800040f2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040f4:	40000613          	li	a2,1024
    800040f8:	05890593          	addi	a1,s2,88
    800040fc:	05850513          	addi	a0,a0,88
    80004100:	ffffd097          	auipc	ra,0xffffd
    80004104:	c1a080e7          	jalr	-998(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004108:	8526                	mv	a0,s1
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	fec080e7          	jalr	-20(ra) # 800030f6 <bwrite>
    if(recovering == 0)
    80004112:	f80b1ce3          	bnez	s6,800040aa <install_trans+0x36>
      bunpin(dbuf);
    80004116:	8526                	mv	a0,s1
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	0f6080e7          	jalr	246(ra) # 8000320e <bunpin>
    80004120:	b769                	j	800040aa <install_trans+0x36>
}
    80004122:	70e2                	ld	ra,56(sp)
    80004124:	7442                	ld	s0,48(sp)
    80004126:	74a2                	ld	s1,40(sp)
    80004128:	7902                	ld	s2,32(sp)
    8000412a:	69e2                	ld	s3,24(sp)
    8000412c:	6a42                	ld	s4,16(sp)
    8000412e:	6aa2                	ld	s5,8(sp)
    80004130:	6b02                	ld	s6,0(sp)
    80004132:	6121                	addi	sp,sp,64
    80004134:	8082                	ret
    80004136:	8082                	ret

0000000080004138 <initlog>:
{
    80004138:	7179                	addi	sp,sp,-48
    8000413a:	f406                	sd	ra,40(sp)
    8000413c:	f022                	sd	s0,32(sp)
    8000413e:	ec26                	sd	s1,24(sp)
    80004140:	e84a                	sd	s2,16(sp)
    80004142:	e44e                	sd	s3,8(sp)
    80004144:	1800                	addi	s0,sp,48
    80004146:	892a                	mv	s2,a0
    80004148:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000414a:	0001d497          	auipc	s1,0x1d
    8000414e:	32648493          	addi	s1,s1,806 # 80021470 <log>
    80004152:	00004597          	auipc	a1,0x4
    80004156:	6f658593          	addi	a1,a1,1782 # 80008848 <syscalls_str+0x1e0>
    8000415a:	8526                	mv	a0,s1
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	9d6080e7          	jalr	-1578(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004164:	0149a583          	lw	a1,20(s3)
    80004168:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000416a:	0109a783          	lw	a5,16(s3)
    8000416e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004170:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004174:	854a                	mv	a0,s2
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	e8e080e7          	jalr	-370(ra) # 80003004 <bread>
  log.lh.n = lh->n;
    8000417e:	4d34                	lw	a3,88(a0)
    80004180:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004182:	02d05663          	blez	a3,800041ae <initlog+0x76>
    80004186:	05c50793          	addi	a5,a0,92
    8000418a:	0001d717          	auipc	a4,0x1d
    8000418e:	31670713          	addi	a4,a4,790 # 800214a0 <log+0x30>
    80004192:	36fd                	addiw	a3,a3,-1
    80004194:	02069613          	slli	a2,a3,0x20
    80004198:	01e65693          	srli	a3,a2,0x1e
    8000419c:	06050613          	addi	a2,a0,96
    800041a0:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041a2:	4390                	lw	a2,0(a5)
    800041a4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041a6:	0791                	addi	a5,a5,4
    800041a8:	0711                	addi	a4,a4,4
    800041aa:	fed79ce3          	bne	a5,a3,800041a2 <initlog+0x6a>
  brelse(buf);
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	f86080e7          	jalr	-122(ra) # 80003134 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041b6:	4505                	li	a0,1
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	ebc080e7          	jalr	-324(ra) # 80004074 <install_trans>
  log.lh.n = 0;
    800041c0:	0001d797          	auipc	a5,0x1d
    800041c4:	2c07ae23          	sw	zero,732(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	e30080e7          	jalr	-464(ra) # 80003ff8 <write_head>
}
    800041d0:	70a2                	ld	ra,40(sp)
    800041d2:	7402                	ld	s0,32(sp)
    800041d4:	64e2                	ld	s1,24(sp)
    800041d6:	6942                	ld	s2,16(sp)
    800041d8:	69a2                	ld	s3,8(sp)
    800041da:	6145                	addi	sp,sp,48
    800041dc:	8082                	ret

00000000800041de <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041de:	1101                	addi	sp,sp,-32
    800041e0:	ec06                	sd	ra,24(sp)
    800041e2:	e822                	sd	s0,16(sp)
    800041e4:	e426                	sd	s1,8(sp)
    800041e6:	e04a                	sd	s2,0(sp)
    800041e8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041ea:	0001d517          	auipc	a0,0x1d
    800041ee:	28650513          	addi	a0,a0,646 # 80021470 <log>
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	9d0080e7          	jalr	-1584(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800041fa:	0001d497          	auipc	s1,0x1d
    800041fe:	27648493          	addi	s1,s1,630 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004202:	4979                	li	s2,30
    80004204:	a039                	j	80004212 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004206:	85a6                	mv	a1,s1
    80004208:	8526                	mv	a0,s1
    8000420a:	ffffe097          	auipc	ra,0xffffe
    8000420e:	e82080e7          	jalr	-382(ra) # 8000208c <sleep>
    if(log.committing){
    80004212:	50dc                	lw	a5,36(s1)
    80004214:	fbed                	bnez	a5,80004206 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004216:	509c                	lw	a5,32(s1)
    80004218:	0017871b          	addiw	a4,a5,1
    8000421c:	0007069b          	sext.w	a3,a4
    80004220:	0027179b          	slliw	a5,a4,0x2
    80004224:	9fb9                	addw	a5,a5,a4
    80004226:	0017979b          	slliw	a5,a5,0x1
    8000422a:	54d8                	lw	a4,44(s1)
    8000422c:	9fb9                	addw	a5,a5,a4
    8000422e:	00f95963          	bge	s2,a5,80004240 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004232:	85a6                	mv	a1,s1
    80004234:	8526                	mv	a0,s1
    80004236:	ffffe097          	auipc	ra,0xffffe
    8000423a:	e56080e7          	jalr	-426(ra) # 8000208c <sleep>
    8000423e:	bfd1                	j	80004212 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004240:	0001d517          	auipc	a0,0x1d
    80004244:	23050513          	addi	a0,a0,560 # 80021470 <log>
    80004248:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	a2c080e7          	jalr	-1492(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004252:	60e2                	ld	ra,24(sp)
    80004254:	6442                	ld	s0,16(sp)
    80004256:	64a2                	ld	s1,8(sp)
    80004258:	6902                	ld	s2,0(sp)
    8000425a:	6105                	addi	sp,sp,32
    8000425c:	8082                	ret

000000008000425e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000425e:	7139                	addi	sp,sp,-64
    80004260:	fc06                	sd	ra,56(sp)
    80004262:	f822                	sd	s0,48(sp)
    80004264:	f426                	sd	s1,40(sp)
    80004266:	f04a                	sd	s2,32(sp)
    80004268:	ec4e                	sd	s3,24(sp)
    8000426a:	e852                	sd	s4,16(sp)
    8000426c:	e456                	sd	s5,8(sp)
    8000426e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004270:	0001d497          	auipc	s1,0x1d
    80004274:	20048493          	addi	s1,s1,512 # 80021470 <log>
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	948080e7          	jalr	-1720(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004282:	509c                	lw	a5,32(s1)
    80004284:	37fd                	addiw	a5,a5,-1
    80004286:	0007891b          	sext.w	s2,a5
    8000428a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000428c:	50dc                	lw	a5,36(s1)
    8000428e:	e7b9                	bnez	a5,800042dc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004290:	04091e63          	bnez	s2,800042ec <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004294:	0001d497          	auipc	s1,0x1d
    80004298:	1dc48493          	addi	s1,s1,476 # 80021470 <log>
    8000429c:	4785                	li	a5,1
    8000429e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042a0:	8526                	mv	a0,s1
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	9d4080e7          	jalr	-1580(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042aa:	54dc                	lw	a5,44(s1)
    800042ac:	06f04763          	bgtz	a5,8000431a <end_op+0xbc>
    acquire(&log.lock);
    800042b0:	0001d497          	auipc	s1,0x1d
    800042b4:	1c048493          	addi	s1,s1,448 # 80021470 <log>
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	908080e7          	jalr	-1784(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800042c2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042c6:	8526                	mv	a0,s1
    800042c8:	ffffe097          	auipc	ra,0xffffe
    800042cc:	f50080e7          	jalr	-176(ra) # 80002218 <wakeup>
    release(&log.lock);
    800042d0:	8526                	mv	a0,s1
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	9a4080e7          	jalr	-1628(ra) # 80000c76 <release>
}
    800042da:	a03d                	j	80004308 <end_op+0xaa>
    panic("log.committing");
    800042dc:	00004517          	auipc	a0,0x4
    800042e0:	57450513          	addi	a0,a0,1396 # 80008850 <syscalls_str+0x1e8>
    800042e4:	ffffc097          	auipc	ra,0xffffc
    800042e8:	246080e7          	jalr	582(ra) # 8000052a <panic>
    wakeup(&log);
    800042ec:	0001d497          	auipc	s1,0x1d
    800042f0:	18448493          	addi	s1,s1,388 # 80021470 <log>
    800042f4:	8526                	mv	a0,s1
    800042f6:	ffffe097          	auipc	ra,0xffffe
    800042fa:	f22080e7          	jalr	-222(ra) # 80002218 <wakeup>
  release(&log.lock);
    800042fe:	8526                	mv	a0,s1
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	976080e7          	jalr	-1674(ra) # 80000c76 <release>
}
    80004308:	70e2                	ld	ra,56(sp)
    8000430a:	7442                	ld	s0,48(sp)
    8000430c:	74a2                	ld	s1,40(sp)
    8000430e:	7902                	ld	s2,32(sp)
    80004310:	69e2                	ld	s3,24(sp)
    80004312:	6a42                	ld	s4,16(sp)
    80004314:	6aa2                	ld	s5,8(sp)
    80004316:	6121                	addi	sp,sp,64
    80004318:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431a:	0001da97          	auipc	s5,0x1d
    8000431e:	186a8a93          	addi	s5,s5,390 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004322:	0001da17          	auipc	s4,0x1d
    80004326:	14ea0a13          	addi	s4,s4,334 # 80021470 <log>
    8000432a:	018a2583          	lw	a1,24(s4)
    8000432e:	012585bb          	addw	a1,a1,s2
    80004332:	2585                	addiw	a1,a1,1
    80004334:	028a2503          	lw	a0,40(s4)
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	ccc080e7          	jalr	-820(ra) # 80003004 <bread>
    80004340:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004342:	000aa583          	lw	a1,0(s5)
    80004346:	028a2503          	lw	a0,40(s4)
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	cba080e7          	jalr	-838(ra) # 80003004 <bread>
    80004352:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004354:	40000613          	li	a2,1024
    80004358:	05850593          	addi	a1,a0,88
    8000435c:	05848513          	addi	a0,s1,88
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	9ba080e7          	jalr	-1606(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004368:	8526                	mv	a0,s1
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	d8c080e7          	jalr	-628(ra) # 800030f6 <bwrite>
    brelse(from);
    80004372:	854e                	mv	a0,s3
    80004374:	fffff097          	auipc	ra,0xfffff
    80004378:	dc0080e7          	jalr	-576(ra) # 80003134 <brelse>
    brelse(to);
    8000437c:	8526                	mv	a0,s1
    8000437e:	fffff097          	auipc	ra,0xfffff
    80004382:	db6080e7          	jalr	-586(ra) # 80003134 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004386:	2905                	addiw	s2,s2,1
    80004388:	0a91                	addi	s5,s5,4
    8000438a:	02ca2783          	lw	a5,44(s4)
    8000438e:	f8f94ee3          	blt	s2,a5,8000432a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004392:	00000097          	auipc	ra,0x0
    80004396:	c66080e7          	jalr	-922(ra) # 80003ff8 <write_head>
    install_trans(0); // Now install writes to home locations
    8000439a:	4501                	li	a0,0
    8000439c:	00000097          	auipc	ra,0x0
    800043a0:	cd8080e7          	jalr	-808(ra) # 80004074 <install_trans>
    log.lh.n = 0;
    800043a4:	0001d797          	auipc	a5,0x1d
    800043a8:	0e07ac23          	sw	zero,248(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	c4c080e7          	jalr	-948(ra) # 80003ff8 <write_head>
    800043b4:	bdf5                	j	800042b0 <end_op+0x52>

00000000800043b6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043b6:	1101                	addi	sp,sp,-32
    800043b8:	ec06                	sd	ra,24(sp)
    800043ba:	e822                	sd	s0,16(sp)
    800043bc:	e426                	sd	s1,8(sp)
    800043be:	e04a                	sd	s2,0(sp)
    800043c0:	1000                	addi	s0,sp,32
    800043c2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043c4:	0001d917          	auipc	s2,0x1d
    800043c8:	0ac90913          	addi	s2,s2,172 # 80021470 <log>
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffc097          	auipc	ra,0xffffc
    800043d2:	7f4080e7          	jalr	2036(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043d6:	02c92603          	lw	a2,44(s2)
    800043da:	47f5                	li	a5,29
    800043dc:	06c7c563          	blt	a5,a2,80004446 <log_write+0x90>
    800043e0:	0001d797          	auipc	a5,0x1d
    800043e4:	0ac7a783          	lw	a5,172(a5) # 8002148c <log+0x1c>
    800043e8:	37fd                	addiw	a5,a5,-1
    800043ea:	04f65e63          	bge	a2,a5,80004446 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043ee:	0001d797          	auipc	a5,0x1d
    800043f2:	0a27a783          	lw	a5,162(a5) # 80021490 <log+0x20>
    800043f6:	06f05063          	blez	a5,80004456 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043fa:	4781                	li	a5,0
    800043fc:	06c05563          	blez	a2,80004466 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004400:	44cc                	lw	a1,12(s1)
    80004402:	0001d717          	auipc	a4,0x1d
    80004406:	09e70713          	addi	a4,a4,158 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000440a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000440c:	4314                	lw	a3,0(a4)
    8000440e:	04b68c63          	beq	a3,a1,80004466 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004412:	2785                	addiw	a5,a5,1
    80004414:	0711                	addi	a4,a4,4
    80004416:	fef61be3          	bne	a2,a5,8000440c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000441a:	0621                	addi	a2,a2,8
    8000441c:	060a                	slli	a2,a2,0x2
    8000441e:	0001d797          	auipc	a5,0x1d
    80004422:	05278793          	addi	a5,a5,82 # 80021470 <log>
    80004426:	963e                	add	a2,a2,a5
    80004428:	44dc                	lw	a5,12(s1)
    8000442a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000442c:	8526                	mv	a0,s1
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	da4080e7          	jalr	-604(ra) # 800031d2 <bpin>
    log.lh.n++;
    80004436:	0001d717          	auipc	a4,0x1d
    8000443a:	03a70713          	addi	a4,a4,58 # 80021470 <log>
    8000443e:	575c                	lw	a5,44(a4)
    80004440:	2785                	addiw	a5,a5,1
    80004442:	d75c                	sw	a5,44(a4)
    80004444:	a835                	j	80004480 <log_write+0xca>
    panic("too big a transaction");
    80004446:	00004517          	auipc	a0,0x4
    8000444a:	41a50513          	addi	a0,a0,1050 # 80008860 <syscalls_str+0x1f8>
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	0dc080e7          	jalr	220(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004456:	00004517          	auipc	a0,0x4
    8000445a:	42250513          	addi	a0,a0,1058 # 80008878 <syscalls_str+0x210>
    8000445e:	ffffc097          	auipc	ra,0xffffc
    80004462:	0cc080e7          	jalr	204(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004466:	00878713          	addi	a4,a5,8
    8000446a:	00271693          	slli	a3,a4,0x2
    8000446e:	0001d717          	auipc	a4,0x1d
    80004472:	00270713          	addi	a4,a4,2 # 80021470 <log>
    80004476:	9736                	add	a4,a4,a3
    80004478:	44d4                	lw	a3,12(s1)
    8000447a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000447c:	faf608e3          	beq	a2,a5,8000442c <log_write+0x76>
  }
  release(&log.lock);
    80004480:	0001d517          	auipc	a0,0x1d
    80004484:	ff050513          	addi	a0,a0,-16 # 80021470 <log>
    80004488:	ffffc097          	auipc	ra,0xffffc
    8000448c:	7ee080e7          	jalr	2030(ra) # 80000c76 <release>
}
    80004490:	60e2                	ld	ra,24(sp)
    80004492:	6442                	ld	s0,16(sp)
    80004494:	64a2                	ld	s1,8(sp)
    80004496:	6902                	ld	s2,0(sp)
    80004498:	6105                	addi	sp,sp,32
    8000449a:	8082                	ret

000000008000449c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000449c:	1101                	addi	sp,sp,-32
    8000449e:	ec06                	sd	ra,24(sp)
    800044a0:	e822                	sd	s0,16(sp)
    800044a2:	e426                	sd	s1,8(sp)
    800044a4:	e04a                	sd	s2,0(sp)
    800044a6:	1000                	addi	s0,sp,32
    800044a8:	84aa                	mv	s1,a0
    800044aa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044ac:	00004597          	auipc	a1,0x4
    800044b0:	3ec58593          	addi	a1,a1,1004 # 80008898 <syscalls_str+0x230>
    800044b4:	0521                	addi	a0,a0,8
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	67c080e7          	jalr	1660(ra) # 80000b32 <initlock>
  lk->name = name;
    800044be:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044c6:	0204a423          	sw	zero,40(s1)
}
    800044ca:	60e2                	ld	ra,24(sp)
    800044cc:	6442                	ld	s0,16(sp)
    800044ce:	64a2                	ld	s1,8(sp)
    800044d0:	6902                	ld	s2,0(sp)
    800044d2:	6105                	addi	sp,sp,32
    800044d4:	8082                	ret

00000000800044d6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044d6:	1101                	addi	sp,sp,-32
    800044d8:	ec06                	sd	ra,24(sp)
    800044da:	e822                	sd	s0,16(sp)
    800044dc:	e426                	sd	s1,8(sp)
    800044de:	e04a                	sd	s2,0(sp)
    800044e0:	1000                	addi	s0,sp,32
    800044e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e4:	00850913          	addi	s2,a0,8
    800044e8:	854a                	mv	a0,s2
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	6d8080e7          	jalr	1752(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800044f2:	409c                	lw	a5,0(s1)
    800044f4:	cb89                	beqz	a5,80004506 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044f6:	85ca                	mv	a1,s2
    800044f8:	8526                	mv	a0,s1
    800044fa:	ffffe097          	auipc	ra,0xffffe
    800044fe:	b92080e7          	jalr	-1134(ra) # 8000208c <sleep>
  while (lk->locked) {
    80004502:	409c                	lw	a5,0(s1)
    80004504:	fbed                	bnez	a5,800044f6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004506:	4785                	li	a5,1
    80004508:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	488080e7          	jalr	1160(ra) # 80001992 <myproc>
    80004512:	591c                	lw	a5,48(a0)
    80004514:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004516:	854a                	mv	a0,s2
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	75e080e7          	jalr	1886(ra) # 80000c76 <release>
}
    80004520:	60e2                	ld	ra,24(sp)
    80004522:	6442                	ld	s0,16(sp)
    80004524:	64a2                	ld	s1,8(sp)
    80004526:	6902                	ld	s2,0(sp)
    80004528:	6105                	addi	sp,sp,32
    8000452a:	8082                	ret

000000008000452c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000452c:	1101                	addi	sp,sp,-32
    8000452e:	ec06                	sd	ra,24(sp)
    80004530:	e822                	sd	s0,16(sp)
    80004532:	e426                	sd	s1,8(sp)
    80004534:	e04a                	sd	s2,0(sp)
    80004536:	1000                	addi	s0,sp,32
    80004538:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000453a:	00850913          	addi	s2,a0,8
    8000453e:	854a                	mv	a0,s2
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	682080e7          	jalr	1666(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004548:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000454c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004550:	8526                	mv	a0,s1
    80004552:	ffffe097          	auipc	ra,0xffffe
    80004556:	cc6080e7          	jalr	-826(ra) # 80002218 <wakeup>
  release(&lk->lk);
    8000455a:	854a                	mv	a0,s2
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	71a080e7          	jalr	1818(ra) # 80000c76 <release>
}
    80004564:	60e2                	ld	ra,24(sp)
    80004566:	6442                	ld	s0,16(sp)
    80004568:	64a2                	ld	s1,8(sp)
    8000456a:	6902                	ld	s2,0(sp)
    8000456c:	6105                	addi	sp,sp,32
    8000456e:	8082                	ret

0000000080004570 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004570:	7179                	addi	sp,sp,-48
    80004572:	f406                	sd	ra,40(sp)
    80004574:	f022                	sd	s0,32(sp)
    80004576:	ec26                	sd	s1,24(sp)
    80004578:	e84a                	sd	s2,16(sp)
    8000457a:	e44e                	sd	s3,8(sp)
    8000457c:	1800                	addi	s0,sp,48
    8000457e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004580:	00850913          	addi	s2,a0,8
    80004584:	854a                	mv	a0,s2
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	63c080e7          	jalr	1596(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000458e:	409c                	lw	a5,0(s1)
    80004590:	ef99                	bnez	a5,800045ae <holdingsleep+0x3e>
    80004592:	4481                	li	s1,0
  release(&lk->lk);
    80004594:	854a                	mv	a0,s2
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	6e0080e7          	jalr	1760(ra) # 80000c76 <release>
  return r;
}
    8000459e:	8526                	mv	a0,s1
    800045a0:	70a2                	ld	ra,40(sp)
    800045a2:	7402                	ld	s0,32(sp)
    800045a4:	64e2                	ld	s1,24(sp)
    800045a6:	6942                	ld	s2,16(sp)
    800045a8:	69a2                	ld	s3,8(sp)
    800045aa:	6145                	addi	sp,sp,48
    800045ac:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045ae:	0284a983          	lw	s3,40(s1)
    800045b2:	ffffd097          	auipc	ra,0xffffd
    800045b6:	3e0080e7          	jalr	992(ra) # 80001992 <myproc>
    800045ba:	5904                	lw	s1,48(a0)
    800045bc:	413484b3          	sub	s1,s1,s3
    800045c0:	0014b493          	seqz	s1,s1
    800045c4:	bfc1                	j	80004594 <holdingsleep+0x24>

00000000800045c6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045c6:	1141                	addi	sp,sp,-16
    800045c8:	e406                	sd	ra,8(sp)
    800045ca:	e022                	sd	s0,0(sp)
    800045cc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045ce:	00004597          	auipc	a1,0x4
    800045d2:	2da58593          	addi	a1,a1,730 # 800088a8 <syscalls_str+0x240>
    800045d6:	0001d517          	auipc	a0,0x1d
    800045da:	fe250513          	addi	a0,a0,-30 # 800215b8 <ftable>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	554080e7          	jalr	1364(ra) # 80000b32 <initlock>
}
    800045e6:	60a2                	ld	ra,8(sp)
    800045e8:	6402                	ld	s0,0(sp)
    800045ea:	0141                	addi	sp,sp,16
    800045ec:	8082                	ret

00000000800045ee <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045ee:	1101                	addi	sp,sp,-32
    800045f0:	ec06                	sd	ra,24(sp)
    800045f2:	e822                	sd	s0,16(sp)
    800045f4:	e426                	sd	s1,8(sp)
    800045f6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045f8:	0001d517          	auipc	a0,0x1d
    800045fc:	fc050513          	addi	a0,a0,-64 # 800215b8 <ftable>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	5c2080e7          	jalr	1474(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004608:	0001d497          	auipc	s1,0x1d
    8000460c:	fc848493          	addi	s1,s1,-56 # 800215d0 <ftable+0x18>
    80004610:	0001e717          	auipc	a4,0x1e
    80004614:	f6070713          	addi	a4,a4,-160 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004618:	40dc                	lw	a5,4(s1)
    8000461a:	cf99                	beqz	a5,80004638 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000461c:	02848493          	addi	s1,s1,40
    80004620:	fee49ce3          	bne	s1,a4,80004618 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004624:	0001d517          	auipc	a0,0x1d
    80004628:	f9450513          	addi	a0,a0,-108 # 800215b8 <ftable>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	64a080e7          	jalr	1610(ra) # 80000c76 <release>
  return 0;
    80004634:	4481                	li	s1,0
    80004636:	a819                	j	8000464c <filealloc+0x5e>
      f->ref = 1;
    80004638:	4785                	li	a5,1
    8000463a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000463c:	0001d517          	auipc	a0,0x1d
    80004640:	f7c50513          	addi	a0,a0,-132 # 800215b8 <ftable>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	632080e7          	jalr	1586(ra) # 80000c76 <release>
}
    8000464c:	8526                	mv	a0,s1
    8000464e:	60e2                	ld	ra,24(sp)
    80004650:	6442                	ld	s0,16(sp)
    80004652:	64a2                	ld	s1,8(sp)
    80004654:	6105                	addi	sp,sp,32
    80004656:	8082                	ret

0000000080004658 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004658:	1101                	addi	sp,sp,-32
    8000465a:	ec06                	sd	ra,24(sp)
    8000465c:	e822                	sd	s0,16(sp)
    8000465e:	e426                	sd	s1,8(sp)
    80004660:	1000                	addi	s0,sp,32
    80004662:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004664:	0001d517          	auipc	a0,0x1d
    80004668:	f5450513          	addi	a0,a0,-172 # 800215b8 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	556080e7          	jalr	1366(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004674:	40dc                	lw	a5,4(s1)
    80004676:	02f05263          	blez	a5,8000469a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000467a:	2785                	addiw	a5,a5,1
    8000467c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000467e:	0001d517          	auipc	a0,0x1d
    80004682:	f3a50513          	addi	a0,a0,-198 # 800215b8 <ftable>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	5f0080e7          	jalr	1520(ra) # 80000c76 <release>
  return f;
}
    8000468e:	8526                	mv	a0,s1
    80004690:	60e2                	ld	ra,24(sp)
    80004692:	6442                	ld	s0,16(sp)
    80004694:	64a2                	ld	s1,8(sp)
    80004696:	6105                	addi	sp,sp,32
    80004698:	8082                	ret
    panic("filedup");
    8000469a:	00004517          	auipc	a0,0x4
    8000469e:	21650513          	addi	a0,a0,534 # 800088b0 <syscalls_str+0x248>
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	e88080e7          	jalr	-376(ra) # 8000052a <panic>

00000000800046aa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046aa:	7139                	addi	sp,sp,-64
    800046ac:	fc06                	sd	ra,56(sp)
    800046ae:	f822                	sd	s0,48(sp)
    800046b0:	f426                	sd	s1,40(sp)
    800046b2:	f04a                	sd	s2,32(sp)
    800046b4:	ec4e                	sd	s3,24(sp)
    800046b6:	e852                	sd	s4,16(sp)
    800046b8:	e456                	sd	s5,8(sp)
    800046ba:	0080                	addi	s0,sp,64
    800046bc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046be:	0001d517          	auipc	a0,0x1d
    800046c2:	efa50513          	addi	a0,a0,-262 # 800215b8 <ftable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	4fc080e7          	jalr	1276(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800046ce:	40dc                	lw	a5,4(s1)
    800046d0:	06f05163          	blez	a5,80004732 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046d4:	37fd                	addiw	a5,a5,-1
    800046d6:	0007871b          	sext.w	a4,a5
    800046da:	c0dc                	sw	a5,4(s1)
    800046dc:	06e04363          	bgtz	a4,80004742 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046e0:	0004a903          	lw	s2,0(s1)
    800046e4:	0094ca83          	lbu	s5,9(s1)
    800046e8:	0104ba03          	ld	s4,16(s1)
    800046ec:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046f0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046f4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046f8:	0001d517          	auipc	a0,0x1d
    800046fc:	ec050513          	addi	a0,a0,-320 # 800215b8 <ftable>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	576080e7          	jalr	1398(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004708:	4785                	li	a5,1
    8000470a:	04f90d63          	beq	s2,a5,80004764 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000470e:	3979                	addiw	s2,s2,-2
    80004710:	4785                	li	a5,1
    80004712:	0527e063          	bltu	a5,s2,80004752 <fileclose+0xa8>
    begin_op();
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	ac8080e7          	jalr	-1336(ra) # 800041de <begin_op>
    iput(ff.ip);
    8000471e:	854e                	mv	a0,s3
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	2a2080e7          	jalr	674(ra) # 800039c2 <iput>
    end_op();
    80004728:	00000097          	auipc	ra,0x0
    8000472c:	b36080e7          	jalr	-1226(ra) # 8000425e <end_op>
    80004730:	a00d                	j	80004752 <fileclose+0xa8>
    panic("fileclose");
    80004732:	00004517          	auipc	a0,0x4
    80004736:	18650513          	addi	a0,a0,390 # 800088b8 <syscalls_str+0x250>
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	df0080e7          	jalr	-528(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004742:	0001d517          	auipc	a0,0x1d
    80004746:	e7650513          	addi	a0,a0,-394 # 800215b8 <ftable>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
  }
}
    80004752:	70e2                	ld	ra,56(sp)
    80004754:	7442                	ld	s0,48(sp)
    80004756:	74a2                	ld	s1,40(sp)
    80004758:	7902                	ld	s2,32(sp)
    8000475a:	69e2                	ld	s3,24(sp)
    8000475c:	6a42                	ld	s4,16(sp)
    8000475e:	6aa2                	ld	s5,8(sp)
    80004760:	6121                	addi	sp,sp,64
    80004762:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004764:	85d6                	mv	a1,s5
    80004766:	8552                	mv	a0,s4
    80004768:	00000097          	auipc	ra,0x0
    8000476c:	34c080e7          	jalr	844(ra) # 80004ab4 <pipeclose>
    80004770:	b7cd                	j	80004752 <fileclose+0xa8>

0000000080004772 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004772:	715d                	addi	sp,sp,-80
    80004774:	e486                	sd	ra,72(sp)
    80004776:	e0a2                	sd	s0,64(sp)
    80004778:	fc26                	sd	s1,56(sp)
    8000477a:	f84a                	sd	s2,48(sp)
    8000477c:	f44e                	sd	s3,40(sp)
    8000477e:	0880                	addi	s0,sp,80
    80004780:	84aa                	mv	s1,a0
    80004782:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004784:	ffffd097          	auipc	ra,0xffffd
    80004788:	20e080e7          	jalr	526(ra) # 80001992 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000478c:	409c                	lw	a5,0(s1)
    8000478e:	37f9                	addiw	a5,a5,-2
    80004790:	4705                	li	a4,1
    80004792:	04f76763          	bltu	a4,a5,800047e0 <filestat+0x6e>
    80004796:	892a                	mv	s2,a0
    ilock(f->ip);
    80004798:	6c88                	ld	a0,24(s1)
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	06e080e7          	jalr	110(ra) # 80003808 <ilock>
    stati(f->ip, &st);
    800047a2:	fb840593          	addi	a1,s0,-72
    800047a6:	6c88                	ld	a0,24(s1)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	2ea080e7          	jalr	746(ra) # 80003a92 <stati>
    iunlock(f->ip);
    800047b0:	6c88                	ld	a0,24(s1)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	118080e7          	jalr	280(ra) # 800038ca <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047ba:	46e1                	li	a3,24
    800047bc:	fb840613          	addi	a2,s0,-72
    800047c0:	85ce                	mv	a1,s3
    800047c2:	05093503          	ld	a0,80(s2)
    800047c6:	ffffd097          	auipc	ra,0xffffd
    800047ca:	e78080e7          	jalr	-392(ra) # 8000163e <copyout>
    800047ce:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047d2:	60a6                	ld	ra,72(sp)
    800047d4:	6406                	ld	s0,64(sp)
    800047d6:	74e2                	ld	s1,56(sp)
    800047d8:	7942                	ld	s2,48(sp)
    800047da:	79a2                	ld	s3,40(sp)
    800047dc:	6161                	addi	sp,sp,80
    800047de:	8082                	ret
  return -1;
    800047e0:	557d                	li	a0,-1
    800047e2:	bfc5                	j	800047d2 <filestat+0x60>

00000000800047e4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047e4:	7179                	addi	sp,sp,-48
    800047e6:	f406                	sd	ra,40(sp)
    800047e8:	f022                	sd	s0,32(sp)
    800047ea:	ec26                	sd	s1,24(sp)
    800047ec:	e84a                	sd	s2,16(sp)
    800047ee:	e44e                	sd	s3,8(sp)
    800047f0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047f2:	00854783          	lbu	a5,8(a0)
    800047f6:	c3d5                	beqz	a5,8000489a <fileread+0xb6>
    800047f8:	84aa                	mv	s1,a0
    800047fa:	89ae                	mv	s3,a1
    800047fc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047fe:	411c                	lw	a5,0(a0)
    80004800:	4705                	li	a4,1
    80004802:	04e78963          	beq	a5,a4,80004854 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004806:	470d                	li	a4,3
    80004808:	04e78d63          	beq	a5,a4,80004862 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000480c:	4709                	li	a4,2
    8000480e:	06e79e63          	bne	a5,a4,8000488a <fileread+0xa6>
    ilock(f->ip);
    80004812:	6d08                	ld	a0,24(a0)
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	ff4080e7          	jalr	-12(ra) # 80003808 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000481c:	874a                	mv	a4,s2
    8000481e:	5094                	lw	a3,32(s1)
    80004820:	864e                	mv	a2,s3
    80004822:	4585                	li	a1,1
    80004824:	6c88                	ld	a0,24(s1)
    80004826:	fffff097          	auipc	ra,0xfffff
    8000482a:	296080e7          	jalr	662(ra) # 80003abc <readi>
    8000482e:	892a                	mv	s2,a0
    80004830:	00a05563          	blez	a0,8000483a <fileread+0x56>
      f->off += r;
    80004834:	509c                	lw	a5,32(s1)
    80004836:	9fa9                	addw	a5,a5,a0
    80004838:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000483a:	6c88                	ld	a0,24(s1)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	08e080e7          	jalr	142(ra) # 800038ca <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004844:	854a                	mv	a0,s2
    80004846:	70a2                	ld	ra,40(sp)
    80004848:	7402                	ld	s0,32(sp)
    8000484a:	64e2                	ld	s1,24(sp)
    8000484c:	6942                	ld	s2,16(sp)
    8000484e:	69a2                	ld	s3,8(sp)
    80004850:	6145                	addi	sp,sp,48
    80004852:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004854:	6908                	ld	a0,16(a0)
    80004856:	00000097          	auipc	ra,0x0
    8000485a:	3c0080e7          	jalr	960(ra) # 80004c16 <piperead>
    8000485e:	892a                	mv	s2,a0
    80004860:	b7d5                	j	80004844 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004862:	02451783          	lh	a5,36(a0)
    80004866:	03079693          	slli	a3,a5,0x30
    8000486a:	92c1                	srli	a3,a3,0x30
    8000486c:	4725                	li	a4,9
    8000486e:	02d76863          	bltu	a4,a3,8000489e <fileread+0xba>
    80004872:	0792                	slli	a5,a5,0x4
    80004874:	0001d717          	auipc	a4,0x1d
    80004878:	ca470713          	addi	a4,a4,-860 # 80021518 <devsw>
    8000487c:	97ba                	add	a5,a5,a4
    8000487e:	639c                	ld	a5,0(a5)
    80004880:	c38d                	beqz	a5,800048a2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004882:	4505                	li	a0,1
    80004884:	9782                	jalr	a5
    80004886:	892a                	mv	s2,a0
    80004888:	bf75                	j	80004844 <fileread+0x60>
    panic("fileread");
    8000488a:	00004517          	auipc	a0,0x4
    8000488e:	03e50513          	addi	a0,a0,62 # 800088c8 <syscalls_str+0x260>
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	c98080e7          	jalr	-872(ra) # 8000052a <panic>
    return -1;
    8000489a:	597d                	li	s2,-1
    8000489c:	b765                	j	80004844 <fileread+0x60>
      return -1;
    8000489e:	597d                	li	s2,-1
    800048a0:	b755                	j	80004844 <fileread+0x60>
    800048a2:	597d                	li	s2,-1
    800048a4:	b745                	j	80004844 <fileread+0x60>

00000000800048a6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048a6:	715d                	addi	sp,sp,-80
    800048a8:	e486                	sd	ra,72(sp)
    800048aa:	e0a2                	sd	s0,64(sp)
    800048ac:	fc26                	sd	s1,56(sp)
    800048ae:	f84a                	sd	s2,48(sp)
    800048b0:	f44e                	sd	s3,40(sp)
    800048b2:	f052                	sd	s4,32(sp)
    800048b4:	ec56                	sd	s5,24(sp)
    800048b6:	e85a                	sd	s6,16(sp)
    800048b8:	e45e                	sd	s7,8(sp)
    800048ba:	e062                	sd	s8,0(sp)
    800048bc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048be:	00954783          	lbu	a5,9(a0)
    800048c2:	10078663          	beqz	a5,800049ce <filewrite+0x128>
    800048c6:	892a                	mv	s2,a0
    800048c8:	8aae                	mv	s5,a1
    800048ca:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048cc:	411c                	lw	a5,0(a0)
    800048ce:	4705                	li	a4,1
    800048d0:	02e78263          	beq	a5,a4,800048f4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d4:	470d                	li	a4,3
    800048d6:	02e78663          	beq	a5,a4,80004902 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048da:	4709                	li	a4,2
    800048dc:	0ee79163          	bne	a5,a4,800049be <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048e0:	0ac05d63          	blez	a2,8000499a <filewrite+0xf4>
    int i = 0;
    800048e4:	4981                	li	s3,0
    800048e6:	6b05                	lui	s6,0x1
    800048e8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048ec:	6b85                	lui	s7,0x1
    800048ee:	c00b8b9b          	addiw	s7,s7,-1024
    800048f2:	a861                	j	8000498a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048f4:	6908                	ld	a0,16(a0)
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	22e080e7          	jalr	558(ra) # 80004b24 <pipewrite>
    800048fe:	8a2a                	mv	s4,a0
    80004900:	a045                	j	800049a0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004902:	02451783          	lh	a5,36(a0)
    80004906:	03079693          	slli	a3,a5,0x30
    8000490a:	92c1                	srli	a3,a3,0x30
    8000490c:	4725                	li	a4,9
    8000490e:	0cd76263          	bltu	a4,a3,800049d2 <filewrite+0x12c>
    80004912:	0792                	slli	a5,a5,0x4
    80004914:	0001d717          	auipc	a4,0x1d
    80004918:	c0470713          	addi	a4,a4,-1020 # 80021518 <devsw>
    8000491c:	97ba                	add	a5,a5,a4
    8000491e:	679c                	ld	a5,8(a5)
    80004920:	cbdd                	beqz	a5,800049d6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004922:	4505                	li	a0,1
    80004924:	9782                	jalr	a5
    80004926:	8a2a                	mv	s4,a0
    80004928:	a8a5                	j	800049a0 <filewrite+0xfa>
    8000492a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000492e:	00000097          	auipc	ra,0x0
    80004932:	8b0080e7          	jalr	-1872(ra) # 800041de <begin_op>
      ilock(f->ip);
    80004936:	01893503          	ld	a0,24(s2)
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	ece080e7          	jalr	-306(ra) # 80003808 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004942:	8762                	mv	a4,s8
    80004944:	02092683          	lw	a3,32(s2)
    80004948:	01598633          	add	a2,s3,s5
    8000494c:	4585                	li	a1,1
    8000494e:	01893503          	ld	a0,24(s2)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	262080e7          	jalr	610(ra) # 80003bb4 <writei>
    8000495a:	84aa                	mv	s1,a0
    8000495c:	00a05763          	blez	a0,8000496a <filewrite+0xc4>
        f->off += r;
    80004960:	02092783          	lw	a5,32(s2)
    80004964:	9fa9                	addw	a5,a5,a0
    80004966:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000496a:	01893503          	ld	a0,24(s2)
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	f5c080e7          	jalr	-164(ra) # 800038ca <iunlock>
      end_op();
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	8e8080e7          	jalr	-1816(ra) # 8000425e <end_op>

      if(r != n1){
    8000497e:	009c1f63          	bne	s8,s1,8000499c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004982:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004986:	0149db63          	bge	s3,s4,8000499c <filewrite+0xf6>
      int n1 = n - i;
    8000498a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000498e:	84be                	mv	s1,a5
    80004990:	2781                	sext.w	a5,a5
    80004992:	f8fb5ce3          	bge	s6,a5,8000492a <filewrite+0x84>
    80004996:	84de                	mv	s1,s7
    80004998:	bf49                	j	8000492a <filewrite+0x84>
    int i = 0;
    8000499a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000499c:	013a1f63          	bne	s4,s3,800049ba <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049a0:	8552                	mv	a0,s4
    800049a2:	60a6                	ld	ra,72(sp)
    800049a4:	6406                	ld	s0,64(sp)
    800049a6:	74e2                	ld	s1,56(sp)
    800049a8:	7942                	ld	s2,48(sp)
    800049aa:	79a2                	ld	s3,40(sp)
    800049ac:	7a02                	ld	s4,32(sp)
    800049ae:	6ae2                	ld	s5,24(sp)
    800049b0:	6b42                	ld	s6,16(sp)
    800049b2:	6ba2                	ld	s7,8(sp)
    800049b4:	6c02                	ld	s8,0(sp)
    800049b6:	6161                	addi	sp,sp,80
    800049b8:	8082                	ret
    ret = (i == n ? n : -1);
    800049ba:	5a7d                	li	s4,-1
    800049bc:	b7d5                	j	800049a0 <filewrite+0xfa>
    panic("filewrite");
    800049be:	00004517          	auipc	a0,0x4
    800049c2:	f1a50513          	addi	a0,a0,-230 # 800088d8 <syscalls_str+0x270>
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	b64080e7          	jalr	-1180(ra) # 8000052a <panic>
    return -1;
    800049ce:	5a7d                	li	s4,-1
    800049d0:	bfc1                	j	800049a0 <filewrite+0xfa>
      return -1;
    800049d2:	5a7d                	li	s4,-1
    800049d4:	b7f1                	j	800049a0 <filewrite+0xfa>
    800049d6:	5a7d                	li	s4,-1
    800049d8:	b7e1                	j	800049a0 <filewrite+0xfa>

00000000800049da <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049da:	7179                	addi	sp,sp,-48
    800049dc:	f406                	sd	ra,40(sp)
    800049de:	f022                	sd	s0,32(sp)
    800049e0:	ec26                	sd	s1,24(sp)
    800049e2:	e84a                	sd	s2,16(sp)
    800049e4:	e44e                	sd	s3,8(sp)
    800049e6:	e052                	sd	s4,0(sp)
    800049e8:	1800                	addi	s0,sp,48
    800049ea:	84aa                	mv	s1,a0
    800049ec:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049ee:	0005b023          	sd	zero,0(a1)
    800049f2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049f6:	00000097          	auipc	ra,0x0
    800049fa:	bf8080e7          	jalr	-1032(ra) # 800045ee <filealloc>
    800049fe:	e088                	sd	a0,0(s1)
    80004a00:	c551                	beqz	a0,80004a8c <pipealloc+0xb2>
    80004a02:	00000097          	auipc	ra,0x0
    80004a06:	bec080e7          	jalr	-1044(ra) # 800045ee <filealloc>
    80004a0a:	00aa3023          	sd	a0,0(s4)
    80004a0e:	c92d                	beqz	a0,80004a80 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	0c2080e7          	jalr	194(ra) # 80000ad2 <kalloc>
    80004a18:	892a                	mv	s2,a0
    80004a1a:	c125                	beqz	a0,80004a7a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a1c:	4985                	li	s3,1
    80004a1e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a22:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a26:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a2a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a2e:	00004597          	auipc	a1,0x4
    80004a32:	eba58593          	addi	a1,a1,-326 # 800088e8 <syscalls_str+0x280>
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	0fc080e7          	jalr	252(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004a3e:	609c                	ld	a5,0(s1)
    80004a40:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a44:	609c                	ld	a5,0(s1)
    80004a46:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a4a:	609c                	ld	a5,0(s1)
    80004a4c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a50:	609c                	ld	a5,0(s1)
    80004a52:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a56:	000a3783          	ld	a5,0(s4)
    80004a5a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a5e:	000a3783          	ld	a5,0(s4)
    80004a62:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a66:	000a3783          	ld	a5,0(s4)
    80004a6a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a6e:	000a3783          	ld	a5,0(s4)
    80004a72:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a76:	4501                	li	a0,0
    80004a78:	a025                	j	80004aa0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a7a:	6088                	ld	a0,0(s1)
    80004a7c:	e501                	bnez	a0,80004a84 <pipealloc+0xaa>
    80004a7e:	a039                	j	80004a8c <pipealloc+0xb2>
    80004a80:	6088                	ld	a0,0(s1)
    80004a82:	c51d                	beqz	a0,80004ab0 <pipealloc+0xd6>
    fileclose(*f0);
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	c26080e7          	jalr	-986(ra) # 800046aa <fileclose>
  if(*f1)
    80004a8c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a90:	557d                	li	a0,-1
  if(*f1)
    80004a92:	c799                	beqz	a5,80004aa0 <pipealloc+0xc6>
    fileclose(*f1);
    80004a94:	853e                	mv	a0,a5
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	c14080e7          	jalr	-1004(ra) # 800046aa <fileclose>
  return -1;
    80004a9e:	557d                	li	a0,-1
}
    80004aa0:	70a2                	ld	ra,40(sp)
    80004aa2:	7402                	ld	s0,32(sp)
    80004aa4:	64e2                	ld	s1,24(sp)
    80004aa6:	6942                	ld	s2,16(sp)
    80004aa8:	69a2                	ld	s3,8(sp)
    80004aaa:	6a02                	ld	s4,0(sp)
    80004aac:	6145                	addi	sp,sp,48
    80004aae:	8082                	ret
  return -1;
    80004ab0:	557d                	li	a0,-1
    80004ab2:	b7fd                	j	80004aa0 <pipealloc+0xc6>

0000000080004ab4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ab4:	1101                	addi	sp,sp,-32
    80004ab6:	ec06                	sd	ra,24(sp)
    80004ab8:	e822                	sd	s0,16(sp)
    80004aba:	e426                	sd	s1,8(sp)
    80004abc:	e04a                	sd	s2,0(sp)
    80004abe:	1000                	addi	s0,sp,32
    80004ac0:	84aa                	mv	s1,a0
    80004ac2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	0fe080e7          	jalr	254(ra) # 80000bc2 <acquire>
  if(writable){
    80004acc:	02090d63          	beqz	s2,80004b06 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ad0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ad4:	21848513          	addi	a0,s1,536
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	740080e7          	jalr	1856(ra) # 80002218 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ae0:	2204b783          	ld	a5,544(s1)
    80004ae4:	eb95                	bnez	a5,80004b18 <pipeclose+0x64>
    release(&pi->lock);
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	18e080e7          	jalr	398(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004af0:	8526                	mv	a0,s1
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	ee4080e7          	jalr	-284(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004afa:	60e2                	ld	ra,24(sp)
    80004afc:	6442                	ld	s0,16(sp)
    80004afe:	64a2                	ld	s1,8(sp)
    80004b00:	6902                	ld	s2,0(sp)
    80004b02:	6105                	addi	sp,sp,32
    80004b04:	8082                	ret
    pi->readopen = 0;
    80004b06:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b0a:	21c48513          	addi	a0,s1,540
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	70a080e7          	jalr	1802(ra) # 80002218 <wakeup>
    80004b16:	b7e9                	j	80004ae0 <pipeclose+0x2c>
    release(&pi->lock);
    80004b18:	8526                	mv	a0,s1
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	15c080e7          	jalr	348(ra) # 80000c76 <release>
}
    80004b22:	bfe1                	j	80004afa <pipeclose+0x46>

0000000080004b24 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b24:	711d                	addi	sp,sp,-96
    80004b26:	ec86                	sd	ra,88(sp)
    80004b28:	e8a2                	sd	s0,80(sp)
    80004b2a:	e4a6                	sd	s1,72(sp)
    80004b2c:	e0ca                	sd	s2,64(sp)
    80004b2e:	fc4e                	sd	s3,56(sp)
    80004b30:	f852                	sd	s4,48(sp)
    80004b32:	f456                	sd	s5,40(sp)
    80004b34:	f05a                	sd	s6,32(sp)
    80004b36:	ec5e                	sd	s7,24(sp)
    80004b38:	e862                	sd	s8,16(sp)
    80004b3a:	1080                	addi	s0,sp,96
    80004b3c:	84aa                	mv	s1,a0
    80004b3e:	8aae                	mv	s5,a1
    80004b40:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b42:	ffffd097          	auipc	ra,0xffffd
    80004b46:	e50080e7          	jalr	-432(ra) # 80001992 <myproc>
    80004b4a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	074080e7          	jalr	116(ra) # 80000bc2 <acquire>
  while(i < n){
    80004b56:	0b405363          	blez	s4,80004bfc <pipewrite+0xd8>
  int i = 0;
    80004b5a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b5c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b5e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b62:	21c48b93          	addi	s7,s1,540
    80004b66:	a089                	j	80004ba8 <pipewrite+0x84>
      release(&pi->lock);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	10c080e7          	jalr	268(ra) # 80000c76 <release>
      return -1;
    80004b72:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b74:	854a                	mv	a0,s2
    80004b76:	60e6                	ld	ra,88(sp)
    80004b78:	6446                	ld	s0,80(sp)
    80004b7a:	64a6                	ld	s1,72(sp)
    80004b7c:	6906                	ld	s2,64(sp)
    80004b7e:	79e2                	ld	s3,56(sp)
    80004b80:	7a42                	ld	s4,48(sp)
    80004b82:	7aa2                	ld	s5,40(sp)
    80004b84:	7b02                	ld	s6,32(sp)
    80004b86:	6be2                	ld	s7,24(sp)
    80004b88:	6c42                	ld	s8,16(sp)
    80004b8a:	6125                	addi	sp,sp,96
    80004b8c:	8082                	ret
      wakeup(&pi->nread);
    80004b8e:	8562                	mv	a0,s8
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	688080e7          	jalr	1672(ra) # 80002218 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b98:	85a6                	mv	a1,s1
    80004b9a:	855e                	mv	a0,s7
    80004b9c:	ffffd097          	auipc	ra,0xffffd
    80004ba0:	4f0080e7          	jalr	1264(ra) # 8000208c <sleep>
  while(i < n){
    80004ba4:	05495d63          	bge	s2,s4,80004bfe <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004ba8:	2204a783          	lw	a5,544(s1)
    80004bac:	dfd5                	beqz	a5,80004b68 <pipewrite+0x44>
    80004bae:	0289a783          	lw	a5,40(s3)
    80004bb2:	fbdd                	bnez	a5,80004b68 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bb4:	2184a783          	lw	a5,536(s1)
    80004bb8:	21c4a703          	lw	a4,540(s1)
    80004bbc:	2007879b          	addiw	a5,a5,512
    80004bc0:	fcf707e3          	beq	a4,a5,80004b8e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bc4:	4685                	li	a3,1
    80004bc6:	01590633          	add	a2,s2,s5
    80004bca:	faf40593          	addi	a1,s0,-81
    80004bce:	0509b503          	ld	a0,80(s3)
    80004bd2:	ffffd097          	auipc	ra,0xffffd
    80004bd6:	af8080e7          	jalr	-1288(ra) # 800016ca <copyin>
    80004bda:	03650263          	beq	a0,s6,80004bfe <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bde:	21c4a783          	lw	a5,540(s1)
    80004be2:	0017871b          	addiw	a4,a5,1
    80004be6:	20e4ae23          	sw	a4,540(s1)
    80004bea:	1ff7f793          	andi	a5,a5,511
    80004bee:	97a6                	add	a5,a5,s1
    80004bf0:	faf44703          	lbu	a4,-81(s0)
    80004bf4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bf8:	2905                	addiw	s2,s2,1
    80004bfa:	b76d                	j	80004ba4 <pipewrite+0x80>
  int i = 0;
    80004bfc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004bfe:	21848513          	addi	a0,s1,536
    80004c02:	ffffd097          	auipc	ra,0xffffd
    80004c06:	616080e7          	jalr	1558(ra) # 80002218 <wakeup>
  release(&pi->lock);
    80004c0a:	8526                	mv	a0,s1
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	06a080e7          	jalr	106(ra) # 80000c76 <release>
  return i;
    80004c14:	b785                	j	80004b74 <pipewrite+0x50>

0000000080004c16 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c16:	715d                	addi	sp,sp,-80
    80004c18:	e486                	sd	ra,72(sp)
    80004c1a:	e0a2                	sd	s0,64(sp)
    80004c1c:	fc26                	sd	s1,56(sp)
    80004c1e:	f84a                	sd	s2,48(sp)
    80004c20:	f44e                	sd	s3,40(sp)
    80004c22:	f052                	sd	s4,32(sp)
    80004c24:	ec56                	sd	s5,24(sp)
    80004c26:	e85a                	sd	s6,16(sp)
    80004c28:	0880                	addi	s0,sp,80
    80004c2a:	84aa                	mv	s1,a0
    80004c2c:	892e                	mv	s2,a1
    80004c2e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c30:	ffffd097          	auipc	ra,0xffffd
    80004c34:	d62080e7          	jalr	-670(ra) # 80001992 <myproc>
    80004c38:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	f86080e7          	jalr	-122(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c44:	2184a703          	lw	a4,536(s1)
    80004c48:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c4c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c50:	02f71463          	bne	a4,a5,80004c78 <piperead+0x62>
    80004c54:	2244a783          	lw	a5,548(s1)
    80004c58:	c385                	beqz	a5,80004c78 <piperead+0x62>
    if(pr->killed){
    80004c5a:	028a2783          	lw	a5,40(s4)
    80004c5e:	ebc1                	bnez	a5,80004cee <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c60:	85a6                	mv	a1,s1
    80004c62:	854e                	mv	a0,s3
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	428080e7          	jalr	1064(ra) # 8000208c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c6c:	2184a703          	lw	a4,536(s1)
    80004c70:	21c4a783          	lw	a5,540(s1)
    80004c74:	fef700e3          	beq	a4,a5,80004c54 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c78:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c7a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c7c:	05505363          	blez	s5,80004cc2 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004c80:	2184a783          	lw	a5,536(s1)
    80004c84:	21c4a703          	lw	a4,540(s1)
    80004c88:	02f70d63          	beq	a4,a5,80004cc2 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c8c:	0017871b          	addiw	a4,a5,1
    80004c90:	20e4ac23          	sw	a4,536(s1)
    80004c94:	1ff7f793          	andi	a5,a5,511
    80004c98:	97a6                	add	a5,a5,s1
    80004c9a:	0187c783          	lbu	a5,24(a5)
    80004c9e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ca2:	4685                	li	a3,1
    80004ca4:	fbf40613          	addi	a2,s0,-65
    80004ca8:	85ca                	mv	a1,s2
    80004caa:	050a3503          	ld	a0,80(s4)
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	990080e7          	jalr	-1648(ra) # 8000163e <copyout>
    80004cb6:	01650663          	beq	a0,s6,80004cc2 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cba:	2985                	addiw	s3,s3,1
    80004cbc:	0905                	addi	s2,s2,1
    80004cbe:	fd3a91e3          	bne	s5,s3,80004c80 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cc2:	21c48513          	addi	a0,s1,540
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	552080e7          	jalr	1362(ra) # 80002218 <wakeup>
  release(&pi->lock);
    80004cce:	8526                	mv	a0,s1
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	fa6080e7          	jalr	-90(ra) # 80000c76 <release>
  return i;
}
    80004cd8:	854e                	mv	a0,s3
    80004cda:	60a6                	ld	ra,72(sp)
    80004cdc:	6406                	ld	s0,64(sp)
    80004cde:	74e2                	ld	s1,56(sp)
    80004ce0:	7942                	ld	s2,48(sp)
    80004ce2:	79a2                	ld	s3,40(sp)
    80004ce4:	7a02                	ld	s4,32(sp)
    80004ce6:	6ae2                	ld	s5,24(sp)
    80004ce8:	6b42                	ld	s6,16(sp)
    80004cea:	6161                	addi	sp,sp,80
    80004cec:	8082                	ret
      release(&pi->lock);
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	f86080e7          	jalr	-122(ra) # 80000c76 <release>
      return -1;
    80004cf8:	59fd                	li	s3,-1
    80004cfa:	bff9                	j	80004cd8 <piperead+0xc2>

0000000080004cfc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cfc:	de010113          	addi	sp,sp,-544
    80004d00:	20113c23          	sd	ra,536(sp)
    80004d04:	20813823          	sd	s0,528(sp)
    80004d08:	20913423          	sd	s1,520(sp)
    80004d0c:	21213023          	sd	s2,512(sp)
    80004d10:	ffce                	sd	s3,504(sp)
    80004d12:	fbd2                	sd	s4,496(sp)
    80004d14:	f7d6                	sd	s5,488(sp)
    80004d16:	f3da                	sd	s6,480(sp)
    80004d18:	efde                	sd	s7,472(sp)
    80004d1a:	ebe2                	sd	s8,464(sp)
    80004d1c:	e7e6                	sd	s9,456(sp)
    80004d1e:	e3ea                	sd	s10,448(sp)
    80004d20:	ff6e                	sd	s11,440(sp)
    80004d22:	1400                	addi	s0,sp,544
    80004d24:	892a                	mv	s2,a0
    80004d26:	dea43423          	sd	a0,-536(s0)
    80004d2a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d2e:	ffffd097          	auipc	ra,0xffffd
    80004d32:	c64080e7          	jalr	-924(ra) # 80001992 <myproc>
    80004d36:	84aa                	mv	s1,a0

  begin_op();
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	4a6080e7          	jalr	1190(ra) # 800041de <begin_op>

  if((ip = namei(path)) == 0){
    80004d40:	854a                	mv	a0,s2
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	27c080e7          	jalr	636(ra) # 80003fbe <namei>
    80004d4a:	c93d                	beqz	a0,80004dc0 <exec+0xc4>
    80004d4c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	aba080e7          	jalr	-1350(ra) # 80003808 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d56:	04000713          	li	a4,64
    80004d5a:	4681                	li	a3,0
    80004d5c:	e4840613          	addi	a2,s0,-440
    80004d60:	4581                	li	a1,0
    80004d62:	8556                	mv	a0,s5
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	d58080e7          	jalr	-680(ra) # 80003abc <readi>
    80004d6c:	04000793          	li	a5,64
    80004d70:	00f51a63          	bne	a0,a5,80004d84 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d74:	e4842703          	lw	a4,-440(s0)
    80004d78:	464c47b7          	lui	a5,0x464c4
    80004d7c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d80:	04f70663          	beq	a4,a5,80004dcc <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d84:	8556                	mv	a0,s5
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	ce4080e7          	jalr	-796(ra) # 80003a6a <iunlockput>
    end_op();
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	4d0080e7          	jalr	1232(ra) # 8000425e <end_op>
  }
  return -1;
    80004d96:	557d                	li	a0,-1
}
    80004d98:	21813083          	ld	ra,536(sp)
    80004d9c:	21013403          	ld	s0,528(sp)
    80004da0:	20813483          	ld	s1,520(sp)
    80004da4:	20013903          	ld	s2,512(sp)
    80004da8:	79fe                	ld	s3,504(sp)
    80004daa:	7a5e                	ld	s4,496(sp)
    80004dac:	7abe                	ld	s5,488(sp)
    80004dae:	7b1e                	ld	s6,480(sp)
    80004db0:	6bfe                	ld	s7,472(sp)
    80004db2:	6c5e                	ld	s8,464(sp)
    80004db4:	6cbe                	ld	s9,456(sp)
    80004db6:	6d1e                	ld	s10,448(sp)
    80004db8:	7dfa                	ld	s11,440(sp)
    80004dba:	22010113          	addi	sp,sp,544
    80004dbe:	8082                	ret
    end_op();
    80004dc0:	fffff097          	auipc	ra,0xfffff
    80004dc4:	49e080e7          	jalr	1182(ra) # 8000425e <end_op>
    return -1;
    80004dc8:	557d                	li	a0,-1
    80004dca:	b7f9                	j	80004d98 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dcc:	8526                	mv	a0,s1
    80004dce:	ffffd097          	auipc	ra,0xffffd
    80004dd2:	c88080e7          	jalr	-888(ra) # 80001a56 <proc_pagetable>
    80004dd6:	8b2a                	mv	s6,a0
    80004dd8:	d555                	beqz	a0,80004d84 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dda:	e6842783          	lw	a5,-408(s0)
    80004dde:	e8045703          	lhu	a4,-384(s0)
    80004de2:	c735                	beqz	a4,80004e4e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004de4:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004dea:	6a05                	lui	s4,0x1
    80004dec:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004df0:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004df4:	6d85                	lui	s11,0x1
    80004df6:	7d7d                	lui	s10,0xfffff
    80004df8:	ac1d                	j	8000502e <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dfa:	00004517          	auipc	a0,0x4
    80004dfe:	af650513          	addi	a0,a0,-1290 # 800088f0 <syscalls_str+0x288>
    80004e02:	ffffb097          	auipc	ra,0xffffb
    80004e06:	728080e7          	jalr	1832(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e0a:	874a                	mv	a4,s2
    80004e0c:	009c86bb          	addw	a3,s9,s1
    80004e10:	4581                	li	a1,0
    80004e12:	8556                	mv	a0,s5
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	ca8080e7          	jalr	-856(ra) # 80003abc <readi>
    80004e1c:	2501                	sext.w	a0,a0
    80004e1e:	1aa91863          	bne	s2,a0,80004fce <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e22:	009d84bb          	addw	s1,s11,s1
    80004e26:	013d09bb          	addw	s3,s10,s3
    80004e2a:	1f74f263          	bgeu	s1,s7,8000500e <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e2e:	02049593          	slli	a1,s1,0x20
    80004e32:	9181                	srli	a1,a1,0x20
    80004e34:	95e2                	add	a1,a1,s8
    80004e36:	855a                	mv	a0,s6
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	214080e7          	jalr	532(ra) # 8000104c <walkaddr>
    80004e40:	862a                	mv	a2,a0
    if(pa == 0)
    80004e42:	dd45                	beqz	a0,80004dfa <exec+0xfe>
      n = PGSIZE;
    80004e44:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e46:	fd49f2e3          	bgeu	s3,s4,80004e0a <exec+0x10e>
      n = sz - i;
    80004e4a:	894e                	mv	s2,s3
    80004e4c:	bf7d                	j	80004e0a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e4e:	4481                	li	s1,0
  iunlockput(ip);
    80004e50:	8556                	mv	a0,s5
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	c18080e7          	jalr	-1000(ra) # 80003a6a <iunlockput>
  end_op();
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	404080e7          	jalr	1028(ra) # 8000425e <end_op>
  p = myproc();
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	b30080e7          	jalr	-1232(ra) # 80001992 <myproc>
    80004e6a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e6c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e70:	6785                	lui	a5,0x1
    80004e72:	17fd                	addi	a5,a5,-1
    80004e74:	94be                	add	s1,s1,a5
    80004e76:	77fd                	lui	a5,0xfffff
    80004e78:	8fe5                	and	a5,a5,s1
    80004e7a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e7e:	6609                	lui	a2,0x2
    80004e80:	963e                	add	a2,a2,a5
    80004e82:	85be                	mv	a1,a5
    80004e84:	855a                	mv	a0,s6
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	568080e7          	jalr	1384(ra) # 800013ee <uvmalloc>
    80004e8e:	8c2a                	mv	s8,a0
  ip = 0;
    80004e90:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e92:	12050e63          	beqz	a0,80004fce <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e96:	75f9                	lui	a1,0xffffe
    80004e98:	95aa                	add	a1,a1,a0
    80004e9a:	855a                	mv	a0,s6
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	770080e7          	jalr	1904(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004ea4:	7afd                	lui	s5,0xfffff
    80004ea6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ea8:	df043783          	ld	a5,-528(s0)
    80004eac:	6388                	ld	a0,0(a5)
    80004eae:	c925                	beqz	a0,80004f1e <exec+0x222>
    80004eb0:	e8840993          	addi	s3,s0,-376
    80004eb4:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004eb8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eba:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	f86080e7          	jalr	-122(ra) # 80000e42 <strlen>
    80004ec4:	0015079b          	addiw	a5,a0,1
    80004ec8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ecc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ed0:	13596363          	bltu	s2,s5,80004ff6 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ed4:	df043d83          	ld	s11,-528(s0)
    80004ed8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004edc:	8552                	mv	a0,s4
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	f64080e7          	jalr	-156(ra) # 80000e42 <strlen>
    80004ee6:	0015069b          	addiw	a3,a0,1
    80004eea:	8652                	mv	a2,s4
    80004eec:	85ca                	mv	a1,s2
    80004eee:	855a                	mv	a0,s6
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	74e080e7          	jalr	1870(ra) # 8000163e <copyout>
    80004ef8:	10054363          	bltz	a0,80004ffe <exec+0x302>
    ustack[argc] = sp;
    80004efc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f00:	0485                	addi	s1,s1,1
    80004f02:	008d8793          	addi	a5,s11,8
    80004f06:	def43823          	sd	a5,-528(s0)
    80004f0a:	008db503          	ld	a0,8(s11)
    80004f0e:	c911                	beqz	a0,80004f22 <exec+0x226>
    if(argc >= MAXARG)
    80004f10:	09a1                	addi	s3,s3,8
    80004f12:	fb3c95e3          	bne	s9,s3,80004ebc <exec+0x1c0>
  sz = sz1;
    80004f16:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f1a:	4a81                	li	s5,0
    80004f1c:	a84d                	j	80004fce <exec+0x2d2>
  sp = sz;
    80004f1e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f20:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f22:	00349793          	slli	a5,s1,0x3
    80004f26:	f9040713          	addi	a4,s0,-112
    80004f2a:	97ba                	add	a5,a5,a4
    80004f2c:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f30:	00148693          	addi	a3,s1,1
    80004f34:	068e                	slli	a3,a3,0x3
    80004f36:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f3a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f3e:	01597663          	bgeu	s2,s5,80004f4a <exec+0x24e>
  sz = sz1;
    80004f42:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f46:	4a81                	li	s5,0
    80004f48:	a059                	j	80004fce <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f4a:	e8840613          	addi	a2,s0,-376
    80004f4e:	85ca                	mv	a1,s2
    80004f50:	855a                	mv	a0,s6
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	6ec080e7          	jalr	1772(ra) # 8000163e <copyout>
    80004f5a:	0a054663          	bltz	a0,80005006 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f5e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f62:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f66:	de843783          	ld	a5,-536(s0)
    80004f6a:	0007c703          	lbu	a4,0(a5)
    80004f6e:	cf11                	beqz	a4,80004f8a <exec+0x28e>
    80004f70:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f72:	02f00693          	li	a3,47
    80004f76:	a039                	j	80004f84 <exec+0x288>
      last = s+1;
    80004f78:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f7c:	0785                	addi	a5,a5,1
    80004f7e:	fff7c703          	lbu	a4,-1(a5)
    80004f82:	c701                	beqz	a4,80004f8a <exec+0x28e>
    if(*s == '/')
    80004f84:	fed71ce3          	bne	a4,a3,80004f7c <exec+0x280>
    80004f88:	bfc5                	j	80004f78 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f8a:	4641                	li	a2,16
    80004f8c:	de843583          	ld	a1,-536(s0)
    80004f90:	158b8513          	addi	a0,s7,344
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	e7c080e7          	jalr	-388(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f9c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fa0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004fa4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fa8:	058bb783          	ld	a5,88(s7)
    80004fac:	e6043703          	ld	a4,-416(s0)
    80004fb0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fb2:	058bb783          	ld	a5,88(s7)
    80004fb6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fba:	85ea                	mv	a1,s10
    80004fbc:	ffffd097          	auipc	ra,0xffffd
    80004fc0:	b36080e7          	jalr	-1226(ra) # 80001af2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fc4:	0004851b          	sext.w	a0,s1
    80004fc8:	bbc1                	j	80004d98 <exec+0x9c>
    80004fca:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fce:	df843583          	ld	a1,-520(s0)
    80004fd2:	855a                	mv	a0,s6
    80004fd4:	ffffd097          	auipc	ra,0xffffd
    80004fd8:	b1e080e7          	jalr	-1250(ra) # 80001af2 <proc_freepagetable>
  if(ip){
    80004fdc:	da0a94e3          	bnez	s5,80004d84 <exec+0x88>
  return -1;
    80004fe0:	557d                	li	a0,-1
    80004fe2:	bb5d                	j	80004d98 <exec+0x9c>
    80004fe4:	de943c23          	sd	s1,-520(s0)
    80004fe8:	b7dd                	j	80004fce <exec+0x2d2>
    80004fea:	de943c23          	sd	s1,-520(s0)
    80004fee:	b7c5                	j	80004fce <exec+0x2d2>
    80004ff0:	de943c23          	sd	s1,-520(s0)
    80004ff4:	bfe9                	j	80004fce <exec+0x2d2>
  sz = sz1;
    80004ff6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ffa:	4a81                	li	s5,0
    80004ffc:	bfc9                	j	80004fce <exec+0x2d2>
  sz = sz1;
    80004ffe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005002:	4a81                	li	s5,0
    80005004:	b7e9                	j	80004fce <exec+0x2d2>
  sz = sz1;
    80005006:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000500a:	4a81                	li	s5,0
    8000500c:	b7c9                	j	80004fce <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000500e:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005012:	e0843783          	ld	a5,-504(s0)
    80005016:	0017869b          	addiw	a3,a5,1
    8000501a:	e0d43423          	sd	a3,-504(s0)
    8000501e:	e0043783          	ld	a5,-512(s0)
    80005022:	0387879b          	addiw	a5,a5,56
    80005026:	e8045703          	lhu	a4,-384(s0)
    8000502a:	e2e6d3e3          	bge	a3,a4,80004e50 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000502e:	2781                	sext.w	a5,a5
    80005030:	e0f43023          	sd	a5,-512(s0)
    80005034:	03800713          	li	a4,56
    80005038:	86be                	mv	a3,a5
    8000503a:	e1040613          	addi	a2,s0,-496
    8000503e:	4581                	li	a1,0
    80005040:	8556                	mv	a0,s5
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	a7a080e7          	jalr	-1414(ra) # 80003abc <readi>
    8000504a:	03800793          	li	a5,56
    8000504e:	f6f51ee3          	bne	a0,a5,80004fca <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005052:	e1042783          	lw	a5,-496(s0)
    80005056:	4705                	li	a4,1
    80005058:	fae79de3          	bne	a5,a4,80005012 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000505c:	e3843603          	ld	a2,-456(s0)
    80005060:	e3043783          	ld	a5,-464(s0)
    80005064:	f8f660e3          	bltu	a2,a5,80004fe4 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005068:	e2043783          	ld	a5,-480(s0)
    8000506c:	963e                	add	a2,a2,a5
    8000506e:	f6f66ee3          	bltu	a2,a5,80004fea <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005072:	85a6                	mv	a1,s1
    80005074:	855a                	mv	a0,s6
    80005076:	ffffc097          	auipc	ra,0xffffc
    8000507a:	378080e7          	jalr	888(ra) # 800013ee <uvmalloc>
    8000507e:	dea43c23          	sd	a0,-520(s0)
    80005082:	d53d                	beqz	a0,80004ff0 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005084:	e2043c03          	ld	s8,-480(s0)
    80005088:	de043783          	ld	a5,-544(s0)
    8000508c:	00fc77b3          	and	a5,s8,a5
    80005090:	ff9d                	bnez	a5,80004fce <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005092:	e1842c83          	lw	s9,-488(s0)
    80005096:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000509a:	f60b8ae3          	beqz	s7,8000500e <exec+0x312>
    8000509e:	89de                	mv	s3,s7
    800050a0:	4481                	li	s1,0
    800050a2:	b371                	j	80004e2e <exec+0x132>

00000000800050a4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050a4:	7179                	addi	sp,sp,-48
    800050a6:	f406                	sd	ra,40(sp)
    800050a8:	f022                	sd	s0,32(sp)
    800050aa:	ec26                	sd	s1,24(sp)
    800050ac:	e84a                	sd	s2,16(sp)
    800050ae:	1800                	addi	s0,sp,48
    800050b0:	892e                	mv	s2,a1
    800050b2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050b4:	fdc40593          	addi	a1,s0,-36
    800050b8:	ffffe097          	auipc	ra,0xffffe
    800050bc:	ae8080e7          	jalr	-1304(ra) # 80002ba0 <argint>
    800050c0:	04054063          	bltz	a0,80005100 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050c4:	fdc42703          	lw	a4,-36(s0)
    800050c8:	47bd                	li	a5,15
    800050ca:	02e7ed63          	bltu	a5,a4,80005104 <argfd+0x60>
    800050ce:	ffffd097          	auipc	ra,0xffffd
    800050d2:	8c4080e7          	jalr	-1852(ra) # 80001992 <myproc>
    800050d6:	fdc42703          	lw	a4,-36(s0)
    800050da:	01a70793          	addi	a5,a4,26
    800050de:	078e                	slli	a5,a5,0x3
    800050e0:	953e                	add	a0,a0,a5
    800050e2:	611c                	ld	a5,0(a0)
    800050e4:	c395                	beqz	a5,80005108 <argfd+0x64>
    return -1;
  if(pfd)
    800050e6:	00090463          	beqz	s2,800050ee <argfd+0x4a>
    *pfd = fd;
    800050ea:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050ee:	4501                	li	a0,0
  if(pf)
    800050f0:	c091                	beqz	s1,800050f4 <argfd+0x50>
    *pf = f;
    800050f2:	e09c                	sd	a5,0(s1)
}
    800050f4:	70a2                	ld	ra,40(sp)
    800050f6:	7402                	ld	s0,32(sp)
    800050f8:	64e2                	ld	s1,24(sp)
    800050fa:	6942                	ld	s2,16(sp)
    800050fc:	6145                	addi	sp,sp,48
    800050fe:	8082                	ret
    return -1;
    80005100:	557d                	li	a0,-1
    80005102:	bfcd                	j	800050f4 <argfd+0x50>
    return -1;
    80005104:	557d                	li	a0,-1
    80005106:	b7fd                	j	800050f4 <argfd+0x50>
    80005108:	557d                	li	a0,-1
    8000510a:	b7ed                	j	800050f4 <argfd+0x50>

000000008000510c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000510c:	1101                	addi	sp,sp,-32
    8000510e:	ec06                	sd	ra,24(sp)
    80005110:	e822                	sd	s0,16(sp)
    80005112:	e426                	sd	s1,8(sp)
    80005114:	1000                	addi	s0,sp,32
    80005116:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	87a080e7          	jalr	-1926(ra) # 80001992 <myproc>
    80005120:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005122:	0d050793          	addi	a5,a0,208
    80005126:	4501                	li	a0,0
    80005128:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000512a:	6398                	ld	a4,0(a5)
    8000512c:	cb19                	beqz	a4,80005142 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000512e:	2505                	addiw	a0,a0,1
    80005130:	07a1                	addi	a5,a5,8
    80005132:	fed51ce3          	bne	a0,a3,8000512a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005136:	557d                	li	a0,-1
}
    80005138:	60e2                	ld	ra,24(sp)
    8000513a:	6442                	ld	s0,16(sp)
    8000513c:	64a2                	ld	s1,8(sp)
    8000513e:	6105                	addi	sp,sp,32
    80005140:	8082                	ret
      p->ofile[fd] = f;
    80005142:	01a50793          	addi	a5,a0,26
    80005146:	078e                	slli	a5,a5,0x3
    80005148:	963e                	add	a2,a2,a5
    8000514a:	e204                	sd	s1,0(a2)
      return fd;
    8000514c:	b7f5                	j	80005138 <fdalloc+0x2c>

000000008000514e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000514e:	715d                	addi	sp,sp,-80
    80005150:	e486                	sd	ra,72(sp)
    80005152:	e0a2                	sd	s0,64(sp)
    80005154:	fc26                	sd	s1,56(sp)
    80005156:	f84a                	sd	s2,48(sp)
    80005158:	f44e                	sd	s3,40(sp)
    8000515a:	f052                	sd	s4,32(sp)
    8000515c:	ec56                	sd	s5,24(sp)
    8000515e:	0880                	addi	s0,sp,80
    80005160:	89ae                	mv	s3,a1
    80005162:	8ab2                	mv	s5,a2
    80005164:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005166:	fb040593          	addi	a1,s0,-80
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	e72080e7          	jalr	-398(ra) # 80003fdc <nameiparent>
    80005172:	892a                	mv	s2,a0
    80005174:	12050e63          	beqz	a0,800052b0 <create+0x162>
    return 0;

  ilock(dp);
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	690080e7          	jalr	1680(ra) # 80003808 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005180:	4601                	li	a2,0
    80005182:	fb040593          	addi	a1,s0,-80
    80005186:	854a                	mv	a0,s2
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	b64080e7          	jalr	-1180(ra) # 80003cec <dirlookup>
    80005190:	84aa                	mv	s1,a0
    80005192:	c921                	beqz	a0,800051e2 <create+0x94>
    iunlockput(dp);
    80005194:	854a                	mv	a0,s2
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	8d4080e7          	jalr	-1836(ra) # 80003a6a <iunlockput>
    ilock(ip);
    8000519e:	8526                	mv	a0,s1
    800051a0:	ffffe097          	auipc	ra,0xffffe
    800051a4:	668080e7          	jalr	1640(ra) # 80003808 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051a8:	2981                	sext.w	s3,s3
    800051aa:	4789                	li	a5,2
    800051ac:	02f99463          	bne	s3,a5,800051d4 <create+0x86>
    800051b0:	0444d783          	lhu	a5,68(s1)
    800051b4:	37f9                	addiw	a5,a5,-2
    800051b6:	17c2                	slli	a5,a5,0x30
    800051b8:	93c1                	srli	a5,a5,0x30
    800051ba:	4705                	li	a4,1
    800051bc:	00f76c63          	bltu	a4,a5,800051d4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051c0:	8526                	mv	a0,s1
    800051c2:	60a6                	ld	ra,72(sp)
    800051c4:	6406                	ld	s0,64(sp)
    800051c6:	74e2                	ld	s1,56(sp)
    800051c8:	7942                	ld	s2,48(sp)
    800051ca:	79a2                	ld	s3,40(sp)
    800051cc:	7a02                	ld	s4,32(sp)
    800051ce:	6ae2                	ld	s5,24(sp)
    800051d0:	6161                	addi	sp,sp,80
    800051d2:	8082                	ret
    iunlockput(ip);
    800051d4:	8526                	mv	a0,s1
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	894080e7          	jalr	-1900(ra) # 80003a6a <iunlockput>
    return 0;
    800051de:	4481                	li	s1,0
    800051e0:	b7c5                	j	800051c0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051e2:	85ce                	mv	a1,s3
    800051e4:	00092503          	lw	a0,0(s2)
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	488080e7          	jalr	1160(ra) # 80003670 <ialloc>
    800051f0:	84aa                	mv	s1,a0
    800051f2:	c521                	beqz	a0,8000523a <create+0xec>
  ilock(ip);
    800051f4:	ffffe097          	auipc	ra,0xffffe
    800051f8:	614080e7          	jalr	1556(ra) # 80003808 <ilock>
  ip->major = major;
    800051fc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005200:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005204:	4a05                	li	s4,1
    80005206:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000520a:	8526                	mv	a0,s1
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	532080e7          	jalr	1330(ra) # 8000373e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005214:	2981                	sext.w	s3,s3
    80005216:	03498a63          	beq	s3,s4,8000524a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000521a:	40d0                	lw	a2,4(s1)
    8000521c:	fb040593          	addi	a1,s0,-80
    80005220:	854a                	mv	a0,s2
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	cda080e7          	jalr	-806(ra) # 80003efc <dirlink>
    8000522a:	06054b63          	bltz	a0,800052a0 <create+0x152>
  iunlockput(dp);
    8000522e:	854a                	mv	a0,s2
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	83a080e7          	jalr	-1990(ra) # 80003a6a <iunlockput>
  return ip;
    80005238:	b761                	j	800051c0 <create+0x72>
    panic("create: ialloc");
    8000523a:	00003517          	auipc	a0,0x3
    8000523e:	6d650513          	addi	a0,a0,1750 # 80008910 <syscalls_str+0x2a8>
    80005242:	ffffb097          	auipc	ra,0xffffb
    80005246:	2e8080e7          	jalr	744(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000524a:	04a95783          	lhu	a5,74(s2)
    8000524e:	2785                	addiw	a5,a5,1
    80005250:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005254:	854a                	mv	a0,s2
    80005256:	ffffe097          	auipc	ra,0xffffe
    8000525a:	4e8080e7          	jalr	1256(ra) # 8000373e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000525e:	40d0                	lw	a2,4(s1)
    80005260:	00003597          	auipc	a1,0x3
    80005264:	6c058593          	addi	a1,a1,1728 # 80008920 <syscalls_str+0x2b8>
    80005268:	8526                	mv	a0,s1
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	c92080e7          	jalr	-878(ra) # 80003efc <dirlink>
    80005272:	00054f63          	bltz	a0,80005290 <create+0x142>
    80005276:	00492603          	lw	a2,4(s2)
    8000527a:	00003597          	auipc	a1,0x3
    8000527e:	6ae58593          	addi	a1,a1,1710 # 80008928 <syscalls_str+0x2c0>
    80005282:	8526                	mv	a0,s1
    80005284:	fffff097          	auipc	ra,0xfffff
    80005288:	c78080e7          	jalr	-904(ra) # 80003efc <dirlink>
    8000528c:	f80557e3          	bgez	a0,8000521a <create+0xcc>
      panic("create dots");
    80005290:	00003517          	auipc	a0,0x3
    80005294:	6a050513          	addi	a0,a0,1696 # 80008930 <syscalls_str+0x2c8>
    80005298:	ffffb097          	auipc	ra,0xffffb
    8000529c:	292080e7          	jalr	658(ra) # 8000052a <panic>
    panic("create: dirlink");
    800052a0:	00003517          	auipc	a0,0x3
    800052a4:	6a050513          	addi	a0,a0,1696 # 80008940 <syscalls_str+0x2d8>
    800052a8:	ffffb097          	auipc	ra,0xffffb
    800052ac:	282080e7          	jalr	642(ra) # 8000052a <panic>
    return 0;
    800052b0:	84aa                	mv	s1,a0
    800052b2:	b739                	j	800051c0 <create+0x72>

00000000800052b4 <sys_dup>:
{
    800052b4:	7179                	addi	sp,sp,-48
    800052b6:	f406                	sd	ra,40(sp)
    800052b8:	f022                	sd	s0,32(sp)
    800052ba:	ec26                	sd	s1,24(sp)
    800052bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052be:	fd840613          	addi	a2,s0,-40
    800052c2:	4581                	li	a1,0
    800052c4:	4501                	li	a0,0
    800052c6:	00000097          	auipc	ra,0x0
    800052ca:	dde080e7          	jalr	-546(ra) # 800050a4 <argfd>
    return -1;
    800052ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052d0:	02054363          	bltz	a0,800052f6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052d4:	fd843503          	ld	a0,-40(s0)
    800052d8:	00000097          	auipc	ra,0x0
    800052dc:	e34080e7          	jalr	-460(ra) # 8000510c <fdalloc>
    800052e0:	84aa                	mv	s1,a0
    return -1;
    800052e2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052e4:	00054963          	bltz	a0,800052f6 <sys_dup+0x42>
  filedup(f);
    800052e8:	fd843503          	ld	a0,-40(s0)
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	36c080e7          	jalr	876(ra) # 80004658 <filedup>
  return fd;
    800052f4:	87a6                	mv	a5,s1
}
    800052f6:	853e                	mv	a0,a5
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	64e2                	ld	s1,24(sp)
    800052fe:	6145                	addi	sp,sp,48
    80005300:	8082                	ret

0000000080005302 <sys_read>:
{
    80005302:	7179                	addi	sp,sp,-48
    80005304:	f406                	sd	ra,40(sp)
    80005306:	f022                	sd	s0,32(sp)
    80005308:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530a:	fe840613          	addi	a2,s0,-24
    8000530e:	4581                	li	a1,0
    80005310:	4501                	li	a0,0
    80005312:	00000097          	auipc	ra,0x0
    80005316:	d92080e7          	jalr	-622(ra) # 800050a4 <argfd>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531c:	04054163          	bltz	a0,8000535e <sys_read+0x5c>
    80005320:	fe440593          	addi	a1,s0,-28
    80005324:	4509                	li	a0,2
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	87a080e7          	jalr	-1926(ra) # 80002ba0 <argint>
    return -1;
    8000532e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005330:	02054763          	bltz	a0,8000535e <sys_read+0x5c>
    80005334:	fd840593          	addi	a1,s0,-40
    80005338:	4505                	li	a0,1
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	888080e7          	jalr	-1912(ra) # 80002bc2 <argaddr>
    return -1;
    80005342:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005344:	00054d63          	bltz	a0,8000535e <sys_read+0x5c>
  return fileread(f, p, n);
    80005348:	fe442603          	lw	a2,-28(s0)
    8000534c:	fd843583          	ld	a1,-40(s0)
    80005350:	fe843503          	ld	a0,-24(s0)
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	490080e7          	jalr	1168(ra) # 800047e4 <fileread>
    8000535c:	87aa                	mv	a5,a0
}
    8000535e:	853e                	mv	a0,a5
    80005360:	70a2                	ld	ra,40(sp)
    80005362:	7402                	ld	s0,32(sp)
    80005364:	6145                	addi	sp,sp,48
    80005366:	8082                	ret

0000000080005368 <sys_write>:
{
    80005368:	7179                	addi	sp,sp,-48
    8000536a:	f406                	sd	ra,40(sp)
    8000536c:	f022                	sd	s0,32(sp)
    8000536e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005370:	fe840613          	addi	a2,s0,-24
    80005374:	4581                	li	a1,0
    80005376:	4501                	li	a0,0
    80005378:	00000097          	auipc	ra,0x0
    8000537c:	d2c080e7          	jalr	-724(ra) # 800050a4 <argfd>
    return -1;
    80005380:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005382:	04054163          	bltz	a0,800053c4 <sys_write+0x5c>
    80005386:	fe440593          	addi	a1,s0,-28
    8000538a:	4509                	li	a0,2
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	814080e7          	jalr	-2028(ra) # 80002ba0 <argint>
    return -1;
    80005394:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005396:	02054763          	bltz	a0,800053c4 <sys_write+0x5c>
    8000539a:	fd840593          	addi	a1,s0,-40
    8000539e:	4505                	li	a0,1
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	822080e7          	jalr	-2014(ra) # 80002bc2 <argaddr>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053aa:	00054d63          	bltz	a0,800053c4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053ae:	fe442603          	lw	a2,-28(s0)
    800053b2:	fd843583          	ld	a1,-40(s0)
    800053b6:	fe843503          	ld	a0,-24(s0)
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	4ec080e7          	jalr	1260(ra) # 800048a6 <filewrite>
    800053c2:	87aa                	mv	a5,a0
}
    800053c4:	853e                	mv	a0,a5
    800053c6:	70a2                	ld	ra,40(sp)
    800053c8:	7402                	ld	s0,32(sp)
    800053ca:	6145                	addi	sp,sp,48
    800053cc:	8082                	ret

00000000800053ce <sys_close>:
{
    800053ce:	1101                	addi	sp,sp,-32
    800053d0:	ec06                	sd	ra,24(sp)
    800053d2:	e822                	sd	s0,16(sp)
    800053d4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053d6:	fe040613          	addi	a2,s0,-32
    800053da:	fec40593          	addi	a1,s0,-20
    800053de:	4501                	li	a0,0
    800053e0:	00000097          	auipc	ra,0x0
    800053e4:	cc4080e7          	jalr	-828(ra) # 800050a4 <argfd>
    return -1;
    800053e8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ea:	02054463          	bltz	a0,80005412 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053ee:	ffffc097          	auipc	ra,0xffffc
    800053f2:	5a4080e7          	jalr	1444(ra) # 80001992 <myproc>
    800053f6:	fec42783          	lw	a5,-20(s0)
    800053fa:	07e9                	addi	a5,a5,26
    800053fc:	078e                	slli	a5,a5,0x3
    800053fe:	97aa                	add	a5,a5,a0
    80005400:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005404:	fe043503          	ld	a0,-32(s0)
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	2a2080e7          	jalr	674(ra) # 800046aa <fileclose>
  return 0;
    80005410:	4781                	li	a5,0
}
    80005412:	853e                	mv	a0,a5
    80005414:	60e2                	ld	ra,24(sp)
    80005416:	6442                	ld	s0,16(sp)
    80005418:	6105                	addi	sp,sp,32
    8000541a:	8082                	ret

000000008000541c <sys_fstat>:
{
    8000541c:	1101                	addi	sp,sp,-32
    8000541e:	ec06                	sd	ra,24(sp)
    80005420:	e822                	sd	s0,16(sp)
    80005422:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005424:	fe840613          	addi	a2,s0,-24
    80005428:	4581                	li	a1,0
    8000542a:	4501                	li	a0,0
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	c78080e7          	jalr	-904(ra) # 800050a4 <argfd>
    return -1;
    80005434:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005436:	02054563          	bltz	a0,80005460 <sys_fstat+0x44>
    8000543a:	fe040593          	addi	a1,s0,-32
    8000543e:	4505                	li	a0,1
    80005440:	ffffd097          	auipc	ra,0xffffd
    80005444:	782080e7          	jalr	1922(ra) # 80002bc2 <argaddr>
    return -1;
    80005448:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000544a:	00054b63          	bltz	a0,80005460 <sys_fstat+0x44>
  return filestat(f, st);
    8000544e:	fe043583          	ld	a1,-32(s0)
    80005452:	fe843503          	ld	a0,-24(s0)
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	31c080e7          	jalr	796(ra) # 80004772 <filestat>
    8000545e:	87aa                	mv	a5,a0
}
    80005460:	853e                	mv	a0,a5
    80005462:	60e2                	ld	ra,24(sp)
    80005464:	6442                	ld	s0,16(sp)
    80005466:	6105                	addi	sp,sp,32
    80005468:	8082                	ret

000000008000546a <sys_link>:
{
    8000546a:	7169                	addi	sp,sp,-304
    8000546c:	f606                	sd	ra,296(sp)
    8000546e:	f222                	sd	s0,288(sp)
    80005470:	ee26                	sd	s1,280(sp)
    80005472:	ea4a                	sd	s2,272(sp)
    80005474:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005476:	08000613          	li	a2,128
    8000547a:	ed040593          	addi	a1,s0,-304
    8000547e:	4501                	li	a0,0
    80005480:	ffffd097          	auipc	ra,0xffffd
    80005484:	764080e7          	jalr	1892(ra) # 80002be4 <argstr>
    return -1;
    80005488:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000548a:	10054e63          	bltz	a0,800055a6 <sys_link+0x13c>
    8000548e:	08000613          	li	a2,128
    80005492:	f5040593          	addi	a1,s0,-176
    80005496:	4505                	li	a0,1
    80005498:	ffffd097          	auipc	ra,0xffffd
    8000549c:	74c080e7          	jalr	1868(ra) # 80002be4 <argstr>
    return -1;
    800054a0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a2:	10054263          	bltz	a0,800055a6 <sys_link+0x13c>
  begin_op();
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	d38080e7          	jalr	-712(ra) # 800041de <begin_op>
  if((ip = namei(old)) == 0){
    800054ae:	ed040513          	addi	a0,s0,-304
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	b0c080e7          	jalr	-1268(ra) # 80003fbe <namei>
    800054ba:	84aa                	mv	s1,a0
    800054bc:	c551                	beqz	a0,80005548 <sys_link+0xde>
  ilock(ip);
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	34a080e7          	jalr	842(ra) # 80003808 <ilock>
  if(ip->type == T_DIR){
    800054c6:	04449703          	lh	a4,68(s1)
    800054ca:	4785                	li	a5,1
    800054cc:	08f70463          	beq	a4,a5,80005554 <sys_link+0xea>
  ip->nlink++;
    800054d0:	04a4d783          	lhu	a5,74(s1)
    800054d4:	2785                	addiw	a5,a5,1
    800054d6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054da:	8526                	mv	a0,s1
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	262080e7          	jalr	610(ra) # 8000373e <iupdate>
  iunlock(ip);
    800054e4:	8526                	mv	a0,s1
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	3e4080e7          	jalr	996(ra) # 800038ca <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054ee:	fd040593          	addi	a1,s0,-48
    800054f2:	f5040513          	addi	a0,s0,-176
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	ae6080e7          	jalr	-1306(ra) # 80003fdc <nameiparent>
    800054fe:	892a                	mv	s2,a0
    80005500:	c935                	beqz	a0,80005574 <sys_link+0x10a>
  ilock(dp);
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	306080e7          	jalr	774(ra) # 80003808 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000550a:	00092703          	lw	a4,0(s2)
    8000550e:	409c                	lw	a5,0(s1)
    80005510:	04f71d63          	bne	a4,a5,8000556a <sys_link+0x100>
    80005514:	40d0                	lw	a2,4(s1)
    80005516:	fd040593          	addi	a1,s0,-48
    8000551a:	854a                	mv	a0,s2
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	9e0080e7          	jalr	-1568(ra) # 80003efc <dirlink>
    80005524:	04054363          	bltz	a0,8000556a <sys_link+0x100>
  iunlockput(dp);
    80005528:	854a                	mv	a0,s2
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	540080e7          	jalr	1344(ra) # 80003a6a <iunlockput>
  iput(ip);
    80005532:	8526                	mv	a0,s1
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	48e080e7          	jalr	1166(ra) # 800039c2 <iput>
  end_op();
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	d22080e7          	jalr	-734(ra) # 8000425e <end_op>
  return 0;
    80005544:	4781                	li	a5,0
    80005546:	a085                	j	800055a6 <sys_link+0x13c>
    end_op();
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	d16080e7          	jalr	-746(ra) # 8000425e <end_op>
    return -1;
    80005550:	57fd                	li	a5,-1
    80005552:	a891                	j	800055a6 <sys_link+0x13c>
    iunlockput(ip);
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	514080e7          	jalr	1300(ra) # 80003a6a <iunlockput>
    end_op();
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	d00080e7          	jalr	-768(ra) # 8000425e <end_op>
    return -1;
    80005566:	57fd                	li	a5,-1
    80005568:	a83d                	j	800055a6 <sys_link+0x13c>
    iunlockput(dp);
    8000556a:	854a                	mv	a0,s2
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	4fe080e7          	jalr	1278(ra) # 80003a6a <iunlockput>
  ilock(ip);
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	292080e7          	jalr	658(ra) # 80003808 <ilock>
  ip->nlink--;
    8000557e:	04a4d783          	lhu	a5,74(s1)
    80005582:	37fd                	addiw	a5,a5,-1
    80005584:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	1b4080e7          	jalr	436(ra) # 8000373e <iupdate>
  iunlockput(ip);
    80005592:	8526                	mv	a0,s1
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	4d6080e7          	jalr	1238(ra) # 80003a6a <iunlockput>
  end_op();
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	cc2080e7          	jalr	-830(ra) # 8000425e <end_op>
  return -1;
    800055a4:	57fd                	li	a5,-1
}
    800055a6:	853e                	mv	a0,a5
    800055a8:	70b2                	ld	ra,296(sp)
    800055aa:	7412                	ld	s0,288(sp)
    800055ac:	64f2                	ld	s1,280(sp)
    800055ae:	6952                	ld	s2,272(sp)
    800055b0:	6155                	addi	sp,sp,304
    800055b2:	8082                	ret

00000000800055b4 <sys_unlink>:
{
    800055b4:	7151                	addi	sp,sp,-240
    800055b6:	f586                	sd	ra,232(sp)
    800055b8:	f1a2                	sd	s0,224(sp)
    800055ba:	eda6                	sd	s1,216(sp)
    800055bc:	e9ca                	sd	s2,208(sp)
    800055be:	e5ce                	sd	s3,200(sp)
    800055c0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055c2:	08000613          	li	a2,128
    800055c6:	f3040593          	addi	a1,s0,-208
    800055ca:	4501                	li	a0,0
    800055cc:	ffffd097          	auipc	ra,0xffffd
    800055d0:	618080e7          	jalr	1560(ra) # 80002be4 <argstr>
    800055d4:	18054163          	bltz	a0,80005756 <sys_unlink+0x1a2>
  begin_op();
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	c06080e7          	jalr	-1018(ra) # 800041de <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055e0:	fb040593          	addi	a1,s0,-80
    800055e4:	f3040513          	addi	a0,s0,-208
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	9f4080e7          	jalr	-1548(ra) # 80003fdc <nameiparent>
    800055f0:	84aa                	mv	s1,a0
    800055f2:	c979                	beqz	a0,800056c8 <sys_unlink+0x114>
  ilock(dp);
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	214080e7          	jalr	532(ra) # 80003808 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055fc:	00003597          	auipc	a1,0x3
    80005600:	32458593          	addi	a1,a1,804 # 80008920 <syscalls_str+0x2b8>
    80005604:	fb040513          	addi	a0,s0,-80
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	6ca080e7          	jalr	1738(ra) # 80003cd2 <namecmp>
    80005610:	14050a63          	beqz	a0,80005764 <sys_unlink+0x1b0>
    80005614:	00003597          	auipc	a1,0x3
    80005618:	31458593          	addi	a1,a1,788 # 80008928 <syscalls_str+0x2c0>
    8000561c:	fb040513          	addi	a0,s0,-80
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	6b2080e7          	jalr	1714(ra) # 80003cd2 <namecmp>
    80005628:	12050e63          	beqz	a0,80005764 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000562c:	f2c40613          	addi	a2,s0,-212
    80005630:	fb040593          	addi	a1,s0,-80
    80005634:	8526                	mv	a0,s1
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	6b6080e7          	jalr	1718(ra) # 80003cec <dirlookup>
    8000563e:	892a                	mv	s2,a0
    80005640:	12050263          	beqz	a0,80005764 <sys_unlink+0x1b0>
  ilock(ip);
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	1c4080e7          	jalr	452(ra) # 80003808 <ilock>
  if(ip->nlink < 1)
    8000564c:	04a91783          	lh	a5,74(s2)
    80005650:	08f05263          	blez	a5,800056d4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005654:	04491703          	lh	a4,68(s2)
    80005658:	4785                	li	a5,1
    8000565a:	08f70563          	beq	a4,a5,800056e4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000565e:	4641                	li	a2,16
    80005660:	4581                	li	a1,0
    80005662:	fc040513          	addi	a0,s0,-64
    80005666:	ffffb097          	auipc	ra,0xffffb
    8000566a:	658080e7          	jalr	1624(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000566e:	4741                	li	a4,16
    80005670:	f2c42683          	lw	a3,-212(s0)
    80005674:	fc040613          	addi	a2,s0,-64
    80005678:	4581                	li	a1,0
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	538080e7          	jalr	1336(ra) # 80003bb4 <writei>
    80005684:	47c1                	li	a5,16
    80005686:	0af51563          	bne	a0,a5,80005730 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000568a:	04491703          	lh	a4,68(s2)
    8000568e:	4785                	li	a5,1
    80005690:	0af70863          	beq	a4,a5,80005740 <sys_unlink+0x18c>
  iunlockput(dp);
    80005694:	8526                	mv	a0,s1
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	3d4080e7          	jalr	980(ra) # 80003a6a <iunlockput>
  ip->nlink--;
    8000569e:	04a95783          	lhu	a5,74(s2)
    800056a2:	37fd                	addiw	a5,a5,-1
    800056a4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056a8:	854a                	mv	a0,s2
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	094080e7          	jalr	148(ra) # 8000373e <iupdate>
  iunlockput(ip);
    800056b2:	854a                	mv	a0,s2
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	3b6080e7          	jalr	950(ra) # 80003a6a <iunlockput>
  end_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	ba2080e7          	jalr	-1118(ra) # 8000425e <end_op>
  return 0;
    800056c4:	4501                	li	a0,0
    800056c6:	a84d                	j	80005778 <sys_unlink+0x1c4>
    end_op();
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	b96080e7          	jalr	-1130(ra) # 8000425e <end_op>
    return -1;
    800056d0:	557d                	li	a0,-1
    800056d2:	a05d                	j	80005778 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056d4:	00003517          	auipc	a0,0x3
    800056d8:	27c50513          	addi	a0,a0,636 # 80008950 <syscalls_str+0x2e8>
    800056dc:	ffffb097          	auipc	ra,0xffffb
    800056e0:	e4e080e7          	jalr	-434(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e4:	04c92703          	lw	a4,76(s2)
    800056e8:	02000793          	li	a5,32
    800056ec:	f6e7f9e3          	bgeu	a5,a4,8000565e <sys_unlink+0xaa>
    800056f0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056f4:	4741                	li	a4,16
    800056f6:	86ce                	mv	a3,s3
    800056f8:	f1840613          	addi	a2,s0,-232
    800056fc:	4581                	li	a1,0
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	3bc080e7          	jalr	956(ra) # 80003abc <readi>
    80005708:	47c1                	li	a5,16
    8000570a:	00f51b63          	bne	a0,a5,80005720 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000570e:	f1845783          	lhu	a5,-232(s0)
    80005712:	e7a1                	bnez	a5,8000575a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005714:	29c1                	addiw	s3,s3,16
    80005716:	04c92783          	lw	a5,76(s2)
    8000571a:	fcf9ede3          	bltu	s3,a5,800056f4 <sys_unlink+0x140>
    8000571e:	b781                	j	8000565e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005720:	00003517          	auipc	a0,0x3
    80005724:	24850513          	addi	a0,a0,584 # 80008968 <syscalls_str+0x300>
    80005728:	ffffb097          	auipc	ra,0xffffb
    8000572c:	e02080e7          	jalr	-510(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005730:	00003517          	auipc	a0,0x3
    80005734:	25050513          	addi	a0,a0,592 # 80008980 <syscalls_str+0x318>
    80005738:	ffffb097          	auipc	ra,0xffffb
    8000573c:	df2080e7          	jalr	-526(ra) # 8000052a <panic>
    dp->nlink--;
    80005740:	04a4d783          	lhu	a5,74(s1)
    80005744:	37fd                	addiw	a5,a5,-1
    80005746:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	ff2080e7          	jalr	-14(ra) # 8000373e <iupdate>
    80005754:	b781                	j	80005694 <sys_unlink+0xe0>
    return -1;
    80005756:	557d                	li	a0,-1
    80005758:	a005                	j	80005778 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000575a:	854a                	mv	a0,s2
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	30e080e7          	jalr	782(ra) # 80003a6a <iunlockput>
  iunlockput(dp);
    80005764:	8526                	mv	a0,s1
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	304080e7          	jalr	772(ra) # 80003a6a <iunlockput>
  end_op();
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	af0080e7          	jalr	-1296(ra) # 8000425e <end_op>
  return -1;
    80005776:	557d                	li	a0,-1
}
    80005778:	70ae                	ld	ra,232(sp)
    8000577a:	740e                	ld	s0,224(sp)
    8000577c:	64ee                	ld	s1,216(sp)
    8000577e:	694e                	ld	s2,208(sp)
    80005780:	69ae                	ld	s3,200(sp)
    80005782:	616d                	addi	sp,sp,240
    80005784:	8082                	ret

0000000080005786 <sys_open>:

uint64
sys_open(void)
{
    80005786:	7131                	addi	sp,sp,-192
    80005788:	fd06                	sd	ra,184(sp)
    8000578a:	f922                	sd	s0,176(sp)
    8000578c:	f526                	sd	s1,168(sp)
    8000578e:	f14a                	sd	s2,160(sp)
    80005790:	ed4e                	sd	s3,152(sp)
    80005792:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005794:	08000613          	li	a2,128
    80005798:	f5040593          	addi	a1,s0,-176
    8000579c:	4501                	li	a0,0
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	446080e7          	jalr	1094(ra) # 80002be4 <argstr>
    return -1;
    800057a6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057a8:	0c054163          	bltz	a0,8000586a <sys_open+0xe4>
    800057ac:	f4c40593          	addi	a1,s0,-180
    800057b0:	4505                	li	a0,1
    800057b2:	ffffd097          	auipc	ra,0xffffd
    800057b6:	3ee080e7          	jalr	1006(ra) # 80002ba0 <argint>
    800057ba:	0a054863          	bltz	a0,8000586a <sys_open+0xe4>

  begin_op();
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	a20080e7          	jalr	-1504(ra) # 800041de <begin_op>

  if(omode & O_CREATE){
    800057c6:	f4c42783          	lw	a5,-180(s0)
    800057ca:	2007f793          	andi	a5,a5,512
    800057ce:	cbdd                	beqz	a5,80005884 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057d0:	4681                	li	a3,0
    800057d2:	4601                	li	a2,0
    800057d4:	4589                	li	a1,2
    800057d6:	f5040513          	addi	a0,s0,-176
    800057da:	00000097          	auipc	ra,0x0
    800057de:	974080e7          	jalr	-1676(ra) # 8000514e <create>
    800057e2:	892a                	mv	s2,a0
    if(ip == 0){
    800057e4:	c959                	beqz	a0,8000587a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057e6:	04491703          	lh	a4,68(s2)
    800057ea:	478d                	li	a5,3
    800057ec:	00f71763          	bne	a4,a5,800057fa <sys_open+0x74>
    800057f0:	04695703          	lhu	a4,70(s2)
    800057f4:	47a5                	li	a5,9
    800057f6:	0ce7ec63          	bltu	a5,a4,800058ce <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	df4080e7          	jalr	-524(ra) # 800045ee <filealloc>
    80005802:	89aa                	mv	s3,a0
    80005804:	10050263          	beqz	a0,80005908 <sys_open+0x182>
    80005808:	00000097          	auipc	ra,0x0
    8000580c:	904080e7          	jalr	-1788(ra) # 8000510c <fdalloc>
    80005810:	84aa                	mv	s1,a0
    80005812:	0e054663          	bltz	a0,800058fe <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005816:	04491703          	lh	a4,68(s2)
    8000581a:	478d                	li	a5,3
    8000581c:	0cf70463          	beq	a4,a5,800058e4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005820:	4789                	li	a5,2
    80005822:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005826:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000582a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000582e:	f4c42783          	lw	a5,-180(s0)
    80005832:	0017c713          	xori	a4,a5,1
    80005836:	8b05                	andi	a4,a4,1
    80005838:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000583c:	0037f713          	andi	a4,a5,3
    80005840:	00e03733          	snez	a4,a4
    80005844:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005848:	4007f793          	andi	a5,a5,1024
    8000584c:	c791                	beqz	a5,80005858 <sys_open+0xd2>
    8000584e:	04491703          	lh	a4,68(s2)
    80005852:	4789                	li	a5,2
    80005854:	08f70f63          	beq	a4,a5,800058f2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005858:	854a                	mv	a0,s2
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	070080e7          	jalr	112(ra) # 800038ca <iunlock>
  end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	9fc080e7          	jalr	-1540(ra) # 8000425e <end_op>

  return fd;
}
    8000586a:	8526                	mv	a0,s1
    8000586c:	70ea                	ld	ra,184(sp)
    8000586e:	744a                	ld	s0,176(sp)
    80005870:	74aa                	ld	s1,168(sp)
    80005872:	790a                	ld	s2,160(sp)
    80005874:	69ea                	ld	s3,152(sp)
    80005876:	6129                	addi	sp,sp,192
    80005878:	8082                	ret
      end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	9e4080e7          	jalr	-1564(ra) # 8000425e <end_op>
      return -1;
    80005882:	b7e5                	j	8000586a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005884:	f5040513          	addi	a0,s0,-176
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	736080e7          	jalr	1846(ra) # 80003fbe <namei>
    80005890:	892a                	mv	s2,a0
    80005892:	c905                	beqz	a0,800058c2 <sys_open+0x13c>
    ilock(ip);
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	f74080e7          	jalr	-140(ra) # 80003808 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000589c:	04491703          	lh	a4,68(s2)
    800058a0:	4785                	li	a5,1
    800058a2:	f4f712e3          	bne	a4,a5,800057e6 <sys_open+0x60>
    800058a6:	f4c42783          	lw	a5,-180(s0)
    800058aa:	dba1                	beqz	a5,800057fa <sys_open+0x74>
      iunlockput(ip);
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	1bc080e7          	jalr	444(ra) # 80003a6a <iunlockput>
      end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	9a8080e7          	jalr	-1624(ra) # 8000425e <end_op>
      return -1;
    800058be:	54fd                	li	s1,-1
    800058c0:	b76d                	j	8000586a <sys_open+0xe4>
      end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	99c080e7          	jalr	-1636(ra) # 8000425e <end_op>
      return -1;
    800058ca:	54fd                	li	s1,-1
    800058cc:	bf79                	j	8000586a <sys_open+0xe4>
    iunlockput(ip);
    800058ce:	854a                	mv	a0,s2
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	19a080e7          	jalr	410(ra) # 80003a6a <iunlockput>
    end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	986080e7          	jalr	-1658(ra) # 8000425e <end_op>
    return -1;
    800058e0:	54fd                	li	s1,-1
    800058e2:	b761                	j	8000586a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058e4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058e8:	04691783          	lh	a5,70(s2)
    800058ec:	02f99223          	sh	a5,36(s3)
    800058f0:	bf2d                	j	8000582a <sys_open+0xa4>
    itrunc(ip);
    800058f2:	854a                	mv	a0,s2
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	022080e7          	jalr	34(ra) # 80003916 <itrunc>
    800058fc:	bfb1                	j	80005858 <sys_open+0xd2>
      fileclose(f);
    800058fe:	854e                	mv	a0,s3
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	daa080e7          	jalr	-598(ra) # 800046aa <fileclose>
    iunlockput(ip);
    80005908:	854a                	mv	a0,s2
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	160080e7          	jalr	352(ra) # 80003a6a <iunlockput>
    end_op();
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	94c080e7          	jalr	-1716(ra) # 8000425e <end_op>
    return -1;
    8000591a:	54fd                	li	s1,-1
    8000591c:	b7b9                	j	8000586a <sys_open+0xe4>

000000008000591e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000591e:	7175                	addi	sp,sp,-144
    80005920:	e506                	sd	ra,136(sp)
    80005922:	e122                	sd	s0,128(sp)
    80005924:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	8b8080e7          	jalr	-1864(ra) # 800041de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000592e:	08000613          	li	a2,128
    80005932:	f7040593          	addi	a1,s0,-144
    80005936:	4501                	li	a0,0
    80005938:	ffffd097          	auipc	ra,0xffffd
    8000593c:	2ac080e7          	jalr	684(ra) # 80002be4 <argstr>
    80005940:	02054963          	bltz	a0,80005972 <sys_mkdir+0x54>
    80005944:	4681                	li	a3,0
    80005946:	4601                	li	a2,0
    80005948:	4585                	li	a1,1
    8000594a:	f7040513          	addi	a0,s0,-144
    8000594e:	00000097          	auipc	ra,0x0
    80005952:	800080e7          	jalr	-2048(ra) # 8000514e <create>
    80005956:	cd11                	beqz	a0,80005972 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	112080e7          	jalr	274(ra) # 80003a6a <iunlockput>
  end_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	8fe080e7          	jalr	-1794(ra) # 8000425e <end_op>
  return 0;
    80005968:	4501                	li	a0,0
}
    8000596a:	60aa                	ld	ra,136(sp)
    8000596c:	640a                	ld	s0,128(sp)
    8000596e:	6149                	addi	sp,sp,144
    80005970:	8082                	ret
    end_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	8ec080e7          	jalr	-1812(ra) # 8000425e <end_op>
    return -1;
    8000597a:	557d                	li	a0,-1
    8000597c:	b7fd                	j	8000596a <sys_mkdir+0x4c>

000000008000597e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000597e:	7135                	addi	sp,sp,-160
    80005980:	ed06                	sd	ra,152(sp)
    80005982:	e922                	sd	s0,144(sp)
    80005984:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	858080e7          	jalr	-1960(ra) # 800041de <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000598e:	08000613          	li	a2,128
    80005992:	f7040593          	addi	a1,s0,-144
    80005996:	4501                	li	a0,0
    80005998:	ffffd097          	auipc	ra,0xffffd
    8000599c:	24c080e7          	jalr	588(ra) # 80002be4 <argstr>
    800059a0:	04054a63          	bltz	a0,800059f4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059a4:	f6c40593          	addi	a1,s0,-148
    800059a8:	4505                	li	a0,1
    800059aa:	ffffd097          	auipc	ra,0xffffd
    800059ae:	1f6080e7          	jalr	502(ra) # 80002ba0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b2:	04054163          	bltz	a0,800059f4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059b6:	f6840593          	addi	a1,s0,-152
    800059ba:	4509                	li	a0,2
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	1e4080e7          	jalr	484(ra) # 80002ba0 <argint>
     argint(1, &major) < 0 ||
    800059c4:	02054863          	bltz	a0,800059f4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059c8:	f6841683          	lh	a3,-152(s0)
    800059cc:	f6c41603          	lh	a2,-148(s0)
    800059d0:	458d                	li	a1,3
    800059d2:	f7040513          	addi	a0,s0,-144
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	778080e7          	jalr	1912(ra) # 8000514e <create>
     argint(2, &minor) < 0 ||
    800059de:	c919                	beqz	a0,800059f4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	08a080e7          	jalr	138(ra) # 80003a6a <iunlockput>
  end_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	876080e7          	jalr	-1930(ra) # 8000425e <end_op>
  return 0;
    800059f0:	4501                	li	a0,0
    800059f2:	a031                	j	800059fe <sys_mknod+0x80>
    end_op();
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	86a080e7          	jalr	-1942(ra) # 8000425e <end_op>
    return -1;
    800059fc:	557d                	li	a0,-1
}
    800059fe:	60ea                	ld	ra,152(sp)
    80005a00:	644a                	ld	s0,144(sp)
    80005a02:	610d                	addi	sp,sp,160
    80005a04:	8082                	ret

0000000080005a06 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a06:	7135                	addi	sp,sp,-160
    80005a08:	ed06                	sd	ra,152(sp)
    80005a0a:	e922                	sd	s0,144(sp)
    80005a0c:	e526                	sd	s1,136(sp)
    80005a0e:	e14a                	sd	s2,128(sp)
    80005a10:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a12:	ffffc097          	auipc	ra,0xffffc
    80005a16:	f80080e7          	jalr	-128(ra) # 80001992 <myproc>
    80005a1a:	892a                	mv	s2,a0
  
  begin_op();
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	7c2080e7          	jalr	1986(ra) # 800041de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a24:	08000613          	li	a2,128
    80005a28:	f6040593          	addi	a1,s0,-160
    80005a2c:	4501                	li	a0,0
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	1b6080e7          	jalr	438(ra) # 80002be4 <argstr>
    80005a36:	04054b63          	bltz	a0,80005a8c <sys_chdir+0x86>
    80005a3a:	f6040513          	addi	a0,s0,-160
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	580080e7          	jalr	1408(ra) # 80003fbe <namei>
    80005a46:	84aa                	mv	s1,a0
    80005a48:	c131                	beqz	a0,80005a8c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	dbe080e7          	jalr	-578(ra) # 80003808 <ilock>
  if(ip->type != T_DIR){
    80005a52:	04449703          	lh	a4,68(s1)
    80005a56:	4785                	li	a5,1
    80005a58:	04f71063          	bne	a4,a5,80005a98 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a5c:	8526                	mv	a0,s1
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	e6c080e7          	jalr	-404(ra) # 800038ca <iunlock>
  iput(p->cwd);
    80005a66:	15093503          	ld	a0,336(s2)
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	f58080e7          	jalr	-168(ra) # 800039c2 <iput>
  end_op();
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	7ec080e7          	jalr	2028(ra) # 8000425e <end_op>
  p->cwd = ip;
    80005a7a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a7e:	4501                	li	a0,0
}
    80005a80:	60ea                	ld	ra,152(sp)
    80005a82:	644a                	ld	s0,144(sp)
    80005a84:	64aa                	ld	s1,136(sp)
    80005a86:	690a                	ld	s2,128(sp)
    80005a88:	610d                	addi	sp,sp,160
    80005a8a:	8082                	ret
    end_op();
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	7d2080e7          	jalr	2002(ra) # 8000425e <end_op>
    return -1;
    80005a94:	557d                	li	a0,-1
    80005a96:	b7ed                	j	80005a80 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a98:	8526                	mv	a0,s1
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	fd0080e7          	jalr	-48(ra) # 80003a6a <iunlockput>
    end_op();
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	7bc080e7          	jalr	1980(ra) # 8000425e <end_op>
    return -1;
    80005aaa:	557d                	li	a0,-1
    80005aac:	bfd1                	j	80005a80 <sys_chdir+0x7a>

0000000080005aae <sys_exec>:

uint64
sys_exec(void)
{
    80005aae:	7145                	addi	sp,sp,-464
    80005ab0:	e786                	sd	ra,456(sp)
    80005ab2:	e3a2                	sd	s0,448(sp)
    80005ab4:	ff26                	sd	s1,440(sp)
    80005ab6:	fb4a                	sd	s2,432(sp)
    80005ab8:	f74e                	sd	s3,424(sp)
    80005aba:	f352                	sd	s4,416(sp)
    80005abc:	ef56                	sd	s5,408(sp)
    80005abe:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ac0:	08000613          	li	a2,128
    80005ac4:	f4040593          	addi	a1,s0,-192
    80005ac8:	4501                	li	a0,0
    80005aca:	ffffd097          	auipc	ra,0xffffd
    80005ace:	11a080e7          	jalr	282(ra) # 80002be4 <argstr>
    return -1;
    80005ad2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ad4:	0c054a63          	bltz	a0,80005ba8 <sys_exec+0xfa>
    80005ad8:	e3840593          	addi	a1,s0,-456
    80005adc:	4505                	li	a0,1
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	0e4080e7          	jalr	228(ra) # 80002bc2 <argaddr>
    80005ae6:	0c054163          	bltz	a0,80005ba8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005aea:	10000613          	li	a2,256
    80005aee:	4581                	li	a1,0
    80005af0:	e4040513          	addi	a0,s0,-448
    80005af4:	ffffb097          	auipc	ra,0xffffb
    80005af8:	1ca080e7          	jalr	458(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005afc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b00:	89a6                	mv	s3,s1
    80005b02:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b04:	02000a13          	li	s4,32
    80005b08:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b0c:	00391793          	slli	a5,s2,0x3
    80005b10:	e3040593          	addi	a1,s0,-464
    80005b14:	e3843503          	ld	a0,-456(s0)
    80005b18:	953e                	add	a0,a0,a5
    80005b1a:	ffffd097          	auipc	ra,0xffffd
    80005b1e:	fec080e7          	jalr	-20(ra) # 80002b06 <fetchaddr>
    80005b22:	02054a63          	bltz	a0,80005b56 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b26:	e3043783          	ld	a5,-464(s0)
    80005b2a:	c3b9                	beqz	a5,80005b70 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b2c:	ffffb097          	auipc	ra,0xffffb
    80005b30:	fa6080e7          	jalr	-90(ra) # 80000ad2 <kalloc>
    80005b34:	85aa                	mv	a1,a0
    80005b36:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b3a:	cd11                	beqz	a0,80005b56 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b3c:	6605                	lui	a2,0x1
    80005b3e:	e3043503          	ld	a0,-464(s0)
    80005b42:	ffffd097          	auipc	ra,0xffffd
    80005b46:	016080e7          	jalr	22(ra) # 80002b58 <fetchstr>
    80005b4a:	00054663          	bltz	a0,80005b56 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b4e:	0905                	addi	s2,s2,1
    80005b50:	09a1                	addi	s3,s3,8
    80005b52:	fb491be3          	bne	s2,s4,80005b08 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b56:	10048913          	addi	s2,s1,256
    80005b5a:	6088                	ld	a0,0(s1)
    80005b5c:	c529                	beqz	a0,80005ba6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b5e:	ffffb097          	auipc	ra,0xffffb
    80005b62:	e78080e7          	jalr	-392(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b66:	04a1                	addi	s1,s1,8
    80005b68:	ff2499e3          	bne	s1,s2,80005b5a <sys_exec+0xac>
  return -1;
    80005b6c:	597d                	li	s2,-1
    80005b6e:	a82d                	j	80005ba8 <sys_exec+0xfa>
      argv[i] = 0;
    80005b70:	0a8e                	slli	s5,s5,0x3
    80005b72:	fc040793          	addi	a5,s0,-64
    80005b76:	9abe                	add	s5,s5,a5
    80005b78:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005b7c:	e4040593          	addi	a1,s0,-448
    80005b80:	f4040513          	addi	a0,s0,-192
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	178080e7          	jalr	376(ra) # 80004cfc <exec>
    80005b8c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8e:	10048993          	addi	s3,s1,256
    80005b92:	6088                	ld	a0,0(s1)
    80005b94:	c911                	beqz	a0,80005ba8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b96:	ffffb097          	auipc	ra,0xffffb
    80005b9a:	e40080e7          	jalr	-448(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9e:	04a1                	addi	s1,s1,8
    80005ba0:	ff3499e3          	bne	s1,s3,80005b92 <sys_exec+0xe4>
    80005ba4:	a011                	j	80005ba8 <sys_exec+0xfa>
  return -1;
    80005ba6:	597d                	li	s2,-1
}
    80005ba8:	854a                	mv	a0,s2
    80005baa:	60be                	ld	ra,456(sp)
    80005bac:	641e                	ld	s0,448(sp)
    80005bae:	74fa                	ld	s1,440(sp)
    80005bb0:	795a                	ld	s2,432(sp)
    80005bb2:	79ba                	ld	s3,424(sp)
    80005bb4:	7a1a                	ld	s4,416(sp)
    80005bb6:	6afa                	ld	s5,408(sp)
    80005bb8:	6179                	addi	sp,sp,464
    80005bba:	8082                	ret

0000000080005bbc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bbc:	7139                	addi	sp,sp,-64
    80005bbe:	fc06                	sd	ra,56(sp)
    80005bc0:	f822                	sd	s0,48(sp)
    80005bc2:	f426                	sd	s1,40(sp)
    80005bc4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bc6:	ffffc097          	auipc	ra,0xffffc
    80005bca:	dcc080e7          	jalr	-564(ra) # 80001992 <myproc>
    80005bce:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bd0:	fd840593          	addi	a1,s0,-40
    80005bd4:	4501                	li	a0,0
    80005bd6:	ffffd097          	auipc	ra,0xffffd
    80005bda:	fec080e7          	jalr	-20(ra) # 80002bc2 <argaddr>
    return -1;
    80005bde:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005be0:	0e054063          	bltz	a0,80005cc0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005be4:	fc840593          	addi	a1,s0,-56
    80005be8:	fd040513          	addi	a0,s0,-48
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	dee080e7          	jalr	-530(ra) # 800049da <pipealloc>
    return -1;
    80005bf4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bf6:	0c054563          	bltz	a0,80005cc0 <sys_pipe+0x104>
  fd0 = -1;
    80005bfa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bfe:	fd043503          	ld	a0,-48(s0)
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	50a080e7          	jalr	1290(ra) # 8000510c <fdalloc>
    80005c0a:	fca42223          	sw	a0,-60(s0)
    80005c0e:	08054c63          	bltz	a0,80005ca6 <sys_pipe+0xea>
    80005c12:	fc843503          	ld	a0,-56(s0)
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	4f6080e7          	jalr	1270(ra) # 8000510c <fdalloc>
    80005c1e:	fca42023          	sw	a0,-64(s0)
    80005c22:	06054863          	bltz	a0,80005c92 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c26:	4691                	li	a3,4
    80005c28:	fc440613          	addi	a2,s0,-60
    80005c2c:	fd843583          	ld	a1,-40(s0)
    80005c30:	68a8                	ld	a0,80(s1)
    80005c32:	ffffc097          	auipc	ra,0xffffc
    80005c36:	a0c080e7          	jalr	-1524(ra) # 8000163e <copyout>
    80005c3a:	02054063          	bltz	a0,80005c5a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c3e:	4691                	li	a3,4
    80005c40:	fc040613          	addi	a2,s0,-64
    80005c44:	fd843583          	ld	a1,-40(s0)
    80005c48:	0591                	addi	a1,a1,4
    80005c4a:	68a8                	ld	a0,80(s1)
    80005c4c:	ffffc097          	auipc	ra,0xffffc
    80005c50:	9f2080e7          	jalr	-1550(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c54:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c56:	06055563          	bgez	a0,80005cc0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c5a:	fc442783          	lw	a5,-60(s0)
    80005c5e:	07e9                	addi	a5,a5,26
    80005c60:	078e                	slli	a5,a5,0x3
    80005c62:	97a6                	add	a5,a5,s1
    80005c64:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c68:	fc042503          	lw	a0,-64(s0)
    80005c6c:	0569                	addi	a0,a0,26
    80005c6e:	050e                	slli	a0,a0,0x3
    80005c70:	9526                	add	a0,a0,s1
    80005c72:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c76:	fd043503          	ld	a0,-48(s0)
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	a30080e7          	jalr	-1488(ra) # 800046aa <fileclose>
    fileclose(wf);
    80005c82:	fc843503          	ld	a0,-56(s0)
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	a24080e7          	jalr	-1500(ra) # 800046aa <fileclose>
    return -1;
    80005c8e:	57fd                	li	a5,-1
    80005c90:	a805                	j	80005cc0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c92:	fc442783          	lw	a5,-60(s0)
    80005c96:	0007c863          	bltz	a5,80005ca6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c9a:	01a78513          	addi	a0,a5,26
    80005c9e:	050e                	slli	a0,a0,0x3
    80005ca0:	9526                	add	a0,a0,s1
    80005ca2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ca6:	fd043503          	ld	a0,-48(s0)
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	a00080e7          	jalr	-1536(ra) # 800046aa <fileclose>
    fileclose(wf);
    80005cb2:	fc843503          	ld	a0,-56(s0)
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	9f4080e7          	jalr	-1548(ra) # 800046aa <fileclose>
    return -1;
    80005cbe:	57fd                	li	a5,-1
}
    80005cc0:	853e                	mv	a0,a5
    80005cc2:	70e2                	ld	ra,56(sp)
    80005cc4:	7442                	ld	s0,48(sp)
    80005cc6:	74a2                	ld	s1,40(sp)
    80005cc8:	6121                	addi	sp,sp,64
    80005cca:	8082                	ret
    80005ccc:	0000                	unimp
	...

0000000080005cd0 <kernelvec>:
    80005cd0:	7111                	addi	sp,sp,-256
    80005cd2:	e006                	sd	ra,0(sp)
    80005cd4:	e40a                	sd	sp,8(sp)
    80005cd6:	e80e                	sd	gp,16(sp)
    80005cd8:	ec12                	sd	tp,24(sp)
    80005cda:	f016                	sd	t0,32(sp)
    80005cdc:	f41a                	sd	t1,40(sp)
    80005cde:	f81e                	sd	t2,48(sp)
    80005ce0:	fc22                	sd	s0,56(sp)
    80005ce2:	e0a6                	sd	s1,64(sp)
    80005ce4:	e4aa                	sd	a0,72(sp)
    80005ce6:	e8ae                	sd	a1,80(sp)
    80005ce8:	ecb2                	sd	a2,88(sp)
    80005cea:	f0b6                	sd	a3,96(sp)
    80005cec:	f4ba                	sd	a4,104(sp)
    80005cee:	f8be                	sd	a5,112(sp)
    80005cf0:	fcc2                	sd	a6,120(sp)
    80005cf2:	e146                	sd	a7,128(sp)
    80005cf4:	e54a                	sd	s2,136(sp)
    80005cf6:	e94e                	sd	s3,144(sp)
    80005cf8:	ed52                	sd	s4,152(sp)
    80005cfa:	f156                	sd	s5,160(sp)
    80005cfc:	f55a                	sd	s6,168(sp)
    80005cfe:	f95e                	sd	s7,176(sp)
    80005d00:	fd62                	sd	s8,184(sp)
    80005d02:	e1e6                	sd	s9,192(sp)
    80005d04:	e5ea                	sd	s10,200(sp)
    80005d06:	e9ee                	sd	s11,208(sp)
    80005d08:	edf2                	sd	t3,216(sp)
    80005d0a:	f1f6                	sd	t4,224(sp)
    80005d0c:	f5fa                	sd	t5,232(sp)
    80005d0e:	f9fe                	sd	t6,240(sp)
    80005d10:	cc3fc0ef          	jal	ra,800029d2 <kerneltrap>
    80005d14:	6082                	ld	ra,0(sp)
    80005d16:	6122                	ld	sp,8(sp)
    80005d18:	61c2                	ld	gp,16(sp)
    80005d1a:	7282                	ld	t0,32(sp)
    80005d1c:	7322                	ld	t1,40(sp)
    80005d1e:	73c2                	ld	t2,48(sp)
    80005d20:	7462                	ld	s0,56(sp)
    80005d22:	6486                	ld	s1,64(sp)
    80005d24:	6526                	ld	a0,72(sp)
    80005d26:	65c6                	ld	a1,80(sp)
    80005d28:	6666                	ld	a2,88(sp)
    80005d2a:	7686                	ld	a3,96(sp)
    80005d2c:	7726                	ld	a4,104(sp)
    80005d2e:	77c6                	ld	a5,112(sp)
    80005d30:	7866                	ld	a6,120(sp)
    80005d32:	688a                	ld	a7,128(sp)
    80005d34:	692a                	ld	s2,136(sp)
    80005d36:	69ca                	ld	s3,144(sp)
    80005d38:	6a6a                	ld	s4,152(sp)
    80005d3a:	7a8a                	ld	s5,160(sp)
    80005d3c:	7b2a                	ld	s6,168(sp)
    80005d3e:	7bca                	ld	s7,176(sp)
    80005d40:	7c6a                	ld	s8,184(sp)
    80005d42:	6c8e                	ld	s9,192(sp)
    80005d44:	6d2e                	ld	s10,200(sp)
    80005d46:	6dce                	ld	s11,208(sp)
    80005d48:	6e6e                	ld	t3,216(sp)
    80005d4a:	7e8e                	ld	t4,224(sp)
    80005d4c:	7f2e                	ld	t5,232(sp)
    80005d4e:	7fce                	ld	t6,240(sp)
    80005d50:	6111                	addi	sp,sp,256
    80005d52:	10200073          	sret
    80005d56:	00000013          	nop
    80005d5a:	00000013          	nop
    80005d5e:	0001                	nop

0000000080005d60 <timervec>:
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	e10c                	sd	a1,0(a0)
    80005d66:	e510                	sd	a2,8(a0)
    80005d68:	e914                	sd	a3,16(a0)
    80005d6a:	6d0c                	ld	a1,24(a0)
    80005d6c:	7110                	ld	a2,32(a0)
    80005d6e:	6194                	ld	a3,0(a1)
    80005d70:	96b2                	add	a3,a3,a2
    80005d72:	e194                	sd	a3,0(a1)
    80005d74:	4589                	li	a1,2
    80005d76:	14459073          	csrw	sip,a1
    80005d7a:	6914                	ld	a3,16(a0)
    80005d7c:	6510                	ld	a2,8(a0)
    80005d7e:	610c                	ld	a1,0(a0)
    80005d80:	34051573          	csrrw	a0,mscratch,a0
    80005d84:	30200073          	mret
	...

0000000080005d8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d8a:	1141                	addi	sp,sp,-16
    80005d8c:	e422                	sd	s0,8(sp)
    80005d8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d90:	0c0007b7          	lui	a5,0xc000
    80005d94:	4705                	li	a4,1
    80005d96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d98:	c3d8                	sw	a4,4(a5)
}
    80005d9a:	6422                	ld	s0,8(sp)
    80005d9c:	0141                	addi	sp,sp,16
    80005d9e:	8082                	ret

0000000080005da0 <plicinithart>:

void
plicinithart(void)
{
    80005da0:	1141                	addi	sp,sp,-16
    80005da2:	e406                	sd	ra,8(sp)
    80005da4:	e022                	sd	s0,0(sp)
    80005da6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	bbe080e7          	jalr	-1090(ra) # 80001966 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005db0:	0085171b          	slliw	a4,a0,0x8
    80005db4:	0c0027b7          	lui	a5,0xc002
    80005db8:	97ba                	add	a5,a5,a4
    80005dba:	40200713          	li	a4,1026
    80005dbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005dc2:	00d5151b          	slliw	a0,a0,0xd
    80005dc6:	0c2017b7          	lui	a5,0xc201
    80005dca:	953e                	add	a0,a0,a5
    80005dcc:	00052023          	sw	zero,0(a0)
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret

0000000080005dd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dd8:	1141                	addi	sp,sp,-16
    80005dda:	e406                	sd	ra,8(sp)
    80005ddc:	e022                	sd	s0,0(sp)
    80005dde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de0:	ffffc097          	auipc	ra,0xffffc
    80005de4:	b86080e7          	jalr	-1146(ra) # 80001966 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005de8:	00d5179b          	slliw	a5,a0,0xd
    80005dec:	0c201537          	lui	a0,0xc201
    80005df0:	953e                	add	a0,a0,a5
  return irq;
}
    80005df2:	4148                	lw	a0,4(a0)
    80005df4:	60a2                	ld	ra,8(sp)
    80005df6:	6402                	ld	s0,0(sp)
    80005df8:	0141                	addi	sp,sp,16
    80005dfa:	8082                	ret

0000000080005dfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dfc:	1101                	addi	sp,sp,-32
    80005dfe:	ec06                	sd	ra,24(sp)
    80005e00:	e822                	sd	s0,16(sp)
    80005e02:	e426                	sd	s1,8(sp)
    80005e04:	1000                	addi	s0,sp,32
    80005e06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	b5e080e7          	jalr	-1186(ra) # 80001966 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e10:	00d5151b          	slliw	a0,a0,0xd
    80005e14:	0c2017b7          	lui	a5,0xc201
    80005e18:	97aa                	add	a5,a5,a0
    80005e1a:	c3c4                	sw	s1,4(a5)
}
    80005e1c:	60e2                	ld	ra,24(sp)
    80005e1e:	6442                	ld	s0,16(sp)
    80005e20:	64a2                	ld	s1,8(sp)
    80005e22:	6105                	addi	sp,sp,32
    80005e24:	8082                	ret

0000000080005e26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e26:	1141                	addi	sp,sp,-16
    80005e28:	e406                	sd	ra,8(sp)
    80005e2a:	e022                	sd	s0,0(sp)
    80005e2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e2e:	479d                	li	a5,7
    80005e30:	06a7c963          	blt	a5,a0,80005ea2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e34:	0001d797          	auipc	a5,0x1d
    80005e38:	1cc78793          	addi	a5,a5,460 # 80023000 <disk>
    80005e3c:	00a78733          	add	a4,a5,a0
    80005e40:	6789                	lui	a5,0x2
    80005e42:	97ba                	add	a5,a5,a4
    80005e44:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e48:	e7ad                	bnez	a5,80005eb2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e4a:	00451793          	slli	a5,a0,0x4
    80005e4e:	0001f717          	auipc	a4,0x1f
    80005e52:	1b270713          	addi	a4,a4,434 # 80025000 <disk+0x2000>
    80005e56:	6314                	ld	a3,0(a4)
    80005e58:	96be                	add	a3,a3,a5
    80005e5a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e5e:	6314                	ld	a3,0(a4)
    80005e60:	96be                	add	a3,a3,a5
    80005e62:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e66:	6314                	ld	a3,0(a4)
    80005e68:	96be                	add	a3,a3,a5
    80005e6a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e6e:	6318                	ld	a4,0(a4)
    80005e70:	97ba                	add	a5,a5,a4
    80005e72:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e76:	0001d797          	auipc	a5,0x1d
    80005e7a:	18a78793          	addi	a5,a5,394 # 80023000 <disk>
    80005e7e:	97aa                	add	a5,a5,a0
    80005e80:	6509                	lui	a0,0x2
    80005e82:	953e                	add	a0,a0,a5
    80005e84:	4785                	li	a5,1
    80005e86:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e8a:	0001f517          	auipc	a0,0x1f
    80005e8e:	18e50513          	addi	a0,a0,398 # 80025018 <disk+0x2018>
    80005e92:	ffffc097          	auipc	ra,0xffffc
    80005e96:	386080e7          	jalr	902(ra) # 80002218 <wakeup>
}
    80005e9a:	60a2                	ld	ra,8(sp)
    80005e9c:	6402                	ld	s0,0(sp)
    80005e9e:	0141                	addi	sp,sp,16
    80005ea0:	8082                	ret
    panic("free_desc 1");
    80005ea2:	00003517          	auipc	a0,0x3
    80005ea6:	aee50513          	addi	a0,a0,-1298 # 80008990 <syscalls_str+0x328>
    80005eaa:	ffffa097          	auipc	ra,0xffffa
    80005eae:	680080e7          	jalr	1664(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	aee50513          	addi	a0,a0,-1298 # 800089a0 <syscalls_str+0x338>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	670080e7          	jalr	1648(ra) # 8000052a <panic>

0000000080005ec2 <virtio_disk_init>:
{
    80005ec2:	1101                	addi	sp,sp,-32
    80005ec4:	ec06                	sd	ra,24(sp)
    80005ec6:	e822                	sd	s0,16(sp)
    80005ec8:	e426                	sd	s1,8(sp)
    80005eca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ecc:	00003597          	auipc	a1,0x3
    80005ed0:	ae458593          	addi	a1,a1,-1308 # 800089b0 <syscalls_str+0x348>
    80005ed4:	0001f517          	auipc	a0,0x1f
    80005ed8:	25450513          	addi	a0,a0,596 # 80025128 <disk+0x2128>
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	c56080e7          	jalr	-938(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ee4:	100017b7          	lui	a5,0x10001
    80005ee8:	4398                	lw	a4,0(a5)
    80005eea:	2701                	sext.w	a4,a4
    80005eec:	747277b7          	lui	a5,0x74727
    80005ef0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ef4:	0ef71163          	bne	a4,a5,80005fd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ef8:	100017b7          	lui	a5,0x10001
    80005efc:	43dc                	lw	a5,4(a5)
    80005efe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f00:	4705                	li	a4,1
    80005f02:	0ce79a63          	bne	a5,a4,80005fd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f06:	100017b7          	lui	a5,0x10001
    80005f0a:	479c                	lw	a5,8(a5)
    80005f0c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f0e:	4709                	li	a4,2
    80005f10:	0ce79363          	bne	a5,a4,80005fd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f14:	100017b7          	lui	a5,0x10001
    80005f18:	47d8                	lw	a4,12(a5)
    80005f1a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f1c:	554d47b7          	lui	a5,0x554d4
    80005f20:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f24:	0af71963          	bne	a4,a5,80005fd6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f28:	100017b7          	lui	a5,0x10001
    80005f2c:	4705                	li	a4,1
    80005f2e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f30:	470d                	li	a4,3
    80005f32:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f34:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f36:	c7ffe737          	lui	a4,0xc7ffe
    80005f3a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f3e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f40:	2701                	sext.w	a4,a4
    80005f42:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f44:	472d                	li	a4,11
    80005f46:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f48:	473d                	li	a4,15
    80005f4a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f4c:	6705                	lui	a4,0x1
    80005f4e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f50:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f54:	5bdc                	lw	a5,52(a5)
    80005f56:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f58:	c7d9                	beqz	a5,80005fe6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f5a:	471d                	li	a4,7
    80005f5c:	08f77d63          	bgeu	a4,a5,80005ff6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f60:	100014b7          	lui	s1,0x10001
    80005f64:	47a1                	li	a5,8
    80005f66:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f68:	6609                	lui	a2,0x2
    80005f6a:	4581                	li	a1,0
    80005f6c:	0001d517          	auipc	a0,0x1d
    80005f70:	09450513          	addi	a0,a0,148 # 80023000 <disk>
    80005f74:	ffffb097          	auipc	ra,0xffffb
    80005f78:	d4a080e7          	jalr	-694(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f7c:	0001d717          	auipc	a4,0x1d
    80005f80:	08470713          	addi	a4,a4,132 # 80023000 <disk>
    80005f84:	00c75793          	srli	a5,a4,0xc
    80005f88:	2781                	sext.w	a5,a5
    80005f8a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f8c:	0001f797          	auipc	a5,0x1f
    80005f90:	07478793          	addi	a5,a5,116 # 80025000 <disk+0x2000>
    80005f94:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f96:	0001d717          	auipc	a4,0x1d
    80005f9a:	0ea70713          	addi	a4,a4,234 # 80023080 <disk+0x80>
    80005f9e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fa0:	0001e717          	auipc	a4,0x1e
    80005fa4:	06070713          	addi	a4,a4,96 # 80024000 <disk+0x1000>
    80005fa8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005faa:	4705                	li	a4,1
    80005fac:	00e78c23          	sb	a4,24(a5)
    80005fb0:	00e78ca3          	sb	a4,25(a5)
    80005fb4:	00e78d23          	sb	a4,26(a5)
    80005fb8:	00e78da3          	sb	a4,27(a5)
    80005fbc:	00e78e23          	sb	a4,28(a5)
    80005fc0:	00e78ea3          	sb	a4,29(a5)
    80005fc4:	00e78f23          	sb	a4,30(a5)
    80005fc8:	00e78fa3          	sb	a4,31(a5)
}
    80005fcc:	60e2                	ld	ra,24(sp)
    80005fce:	6442                	ld	s0,16(sp)
    80005fd0:	64a2                	ld	s1,8(sp)
    80005fd2:	6105                	addi	sp,sp,32
    80005fd4:	8082                	ret
    panic("could not find virtio disk");
    80005fd6:	00003517          	auipc	a0,0x3
    80005fda:	9ea50513          	addi	a0,a0,-1558 # 800089c0 <syscalls_str+0x358>
    80005fde:	ffffa097          	auipc	ra,0xffffa
    80005fe2:	54c080e7          	jalr	1356(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005fe6:	00003517          	auipc	a0,0x3
    80005fea:	9fa50513          	addi	a0,a0,-1542 # 800089e0 <syscalls_str+0x378>
    80005fee:	ffffa097          	auipc	ra,0xffffa
    80005ff2:	53c080e7          	jalr	1340(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005ff6:	00003517          	auipc	a0,0x3
    80005ffa:	a0a50513          	addi	a0,a0,-1526 # 80008a00 <syscalls_str+0x398>
    80005ffe:	ffffa097          	auipc	ra,0xffffa
    80006002:	52c080e7          	jalr	1324(ra) # 8000052a <panic>

0000000080006006 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006006:	7119                	addi	sp,sp,-128
    80006008:	fc86                	sd	ra,120(sp)
    8000600a:	f8a2                	sd	s0,112(sp)
    8000600c:	f4a6                	sd	s1,104(sp)
    8000600e:	f0ca                	sd	s2,96(sp)
    80006010:	ecce                	sd	s3,88(sp)
    80006012:	e8d2                	sd	s4,80(sp)
    80006014:	e4d6                	sd	s5,72(sp)
    80006016:	e0da                	sd	s6,64(sp)
    80006018:	fc5e                	sd	s7,56(sp)
    8000601a:	f862                	sd	s8,48(sp)
    8000601c:	f466                	sd	s9,40(sp)
    8000601e:	f06a                	sd	s10,32(sp)
    80006020:	ec6e                	sd	s11,24(sp)
    80006022:	0100                	addi	s0,sp,128
    80006024:	8aaa                	mv	s5,a0
    80006026:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006028:	00c52c83          	lw	s9,12(a0)
    8000602c:	001c9c9b          	slliw	s9,s9,0x1
    80006030:	1c82                	slli	s9,s9,0x20
    80006032:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006036:	0001f517          	auipc	a0,0x1f
    8000603a:	0f250513          	addi	a0,a0,242 # 80025128 <disk+0x2128>
    8000603e:	ffffb097          	auipc	ra,0xffffb
    80006042:	b84080e7          	jalr	-1148(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006046:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006048:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000604a:	0001dc17          	auipc	s8,0x1d
    8000604e:	fb6c0c13          	addi	s8,s8,-74 # 80023000 <disk>
    80006052:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006054:	4b0d                	li	s6,3
    80006056:	a0ad                	j	800060c0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006058:	00fc0733          	add	a4,s8,a5
    8000605c:	975e                	add	a4,a4,s7
    8000605e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006062:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006064:	0207c563          	bltz	a5,8000608e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006068:	2905                	addiw	s2,s2,1
    8000606a:	0611                	addi	a2,a2,4
    8000606c:	19690d63          	beq	s2,s6,80006206 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006070:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006072:	0001f717          	auipc	a4,0x1f
    80006076:	fa670713          	addi	a4,a4,-90 # 80025018 <disk+0x2018>
    8000607a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000607c:	00074683          	lbu	a3,0(a4)
    80006080:	fee1                	bnez	a3,80006058 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006082:	2785                	addiw	a5,a5,1
    80006084:	0705                	addi	a4,a4,1
    80006086:	fe979be3          	bne	a5,s1,8000607c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000608a:	57fd                	li	a5,-1
    8000608c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000608e:	01205d63          	blez	s2,800060a8 <virtio_disk_rw+0xa2>
    80006092:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006094:	000a2503          	lw	a0,0(s4)
    80006098:	00000097          	auipc	ra,0x0
    8000609c:	d8e080e7          	jalr	-626(ra) # 80005e26 <free_desc>
      for(int j = 0; j < i; j++)
    800060a0:	2d85                	addiw	s11,s11,1
    800060a2:	0a11                	addi	s4,s4,4
    800060a4:	ffb918e3          	bne	s2,s11,80006094 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060a8:	0001f597          	auipc	a1,0x1f
    800060ac:	08058593          	addi	a1,a1,128 # 80025128 <disk+0x2128>
    800060b0:	0001f517          	auipc	a0,0x1f
    800060b4:	f6850513          	addi	a0,a0,-152 # 80025018 <disk+0x2018>
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	fd4080e7          	jalr	-44(ra) # 8000208c <sleep>
  for(int i = 0; i < 3; i++){
    800060c0:	f8040a13          	addi	s4,s0,-128
{
    800060c4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060c6:	894e                	mv	s2,s3
    800060c8:	b765                	j	80006070 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060ca:	0001f697          	auipc	a3,0x1f
    800060ce:	f366b683          	ld	a3,-202(a3) # 80025000 <disk+0x2000>
    800060d2:	96ba                	add	a3,a3,a4
    800060d4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060d8:	0001d817          	auipc	a6,0x1d
    800060dc:	f2880813          	addi	a6,a6,-216 # 80023000 <disk>
    800060e0:	0001f697          	auipc	a3,0x1f
    800060e4:	f2068693          	addi	a3,a3,-224 # 80025000 <disk+0x2000>
    800060e8:	6290                	ld	a2,0(a3)
    800060ea:	963a                	add	a2,a2,a4
    800060ec:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800060f0:	0015e593          	ori	a1,a1,1
    800060f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800060f8:	f8842603          	lw	a2,-120(s0)
    800060fc:	628c                	ld	a1,0(a3)
    800060fe:	972e                	add	a4,a4,a1
    80006100:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006104:	20050593          	addi	a1,a0,512
    80006108:	0592                	slli	a1,a1,0x4
    8000610a:	95c2                	add	a1,a1,a6
    8000610c:	577d                	li	a4,-1
    8000610e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006112:	00461713          	slli	a4,a2,0x4
    80006116:	6290                	ld	a2,0(a3)
    80006118:	963a                	add	a2,a2,a4
    8000611a:	03078793          	addi	a5,a5,48
    8000611e:	97c2                	add	a5,a5,a6
    80006120:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006122:	629c                	ld	a5,0(a3)
    80006124:	97ba                	add	a5,a5,a4
    80006126:	4605                	li	a2,1
    80006128:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000612a:	629c                	ld	a5,0(a3)
    8000612c:	97ba                	add	a5,a5,a4
    8000612e:	4809                	li	a6,2
    80006130:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006134:	629c                	ld	a5,0(a3)
    80006136:	973e                	add	a4,a4,a5
    80006138:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000613c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006140:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006144:	6698                	ld	a4,8(a3)
    80006146:	00275783          	lhu	a5,2(a4)
    8000614a:	8b9d                	andi	a5,a5,7
    8000614c:	0786                	slli	a5,a5,0x1
    8000614e:	97ba                	add	a5,a5,a4
    80006150:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006154:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006158:	6698                	ld	a4,8(a3)
    8000615a:	00275783          	lhu	a5,2(a4)
    8000615e:	2785                	addiw	a5,a5,1
    80006160:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006164:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006168:	100017b7          	lui	a5,0x10001
    8000616c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006170:	004aa783          	lw	a5,4(s5)
    80006174:	02c79163          	bne	a5,a2,80006196 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006178:	0001f917          	auipc	s2,0x1f
    8000617c:	fb090913          	addi	s2,s2,-80 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006180:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006182:	85ca                	mv	a1,s2
    80006184:	8556                	mv	a0,s5
    80006186:	ffffc097          	auipc	ra,0xffffc
    8000618a:	f06080e7          	jalr	-250(ra) # 8000208c <sleep>
  while(b->disk == 1) {
    8000618e:	004aa783          	lw	a5,4(s5)
    80006192:	fe9788e3          	beq	a5,s1,80006182 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006196:	f8042903          	lw	s2,-128(s0)
    8000619a:	20090793          	addi	a5,s2,512
    8000619e:	00479713          	slli	a4,a5,0x4
    800061a2:	0001d797          	auipc	a5,0x1d
    800061a6:	e5e78793          	addi	a5,a5,-418 # 80023000 <disk>
    800061aa:	97ba                	add	a5,a5,a4
    800061ac:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061b0:	0001f997          	auipc	s3,0x1f
    800061b4:	e5098993          	addi	s3,s3,-432 # 80025000 <disk+0x2000>
    800061b8:	00491713          	slli	a4,s2,0x4
    800061bc:	0009b783          	ld	a5,0(s3)
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061c6:	854a                	mv	a0,s2
    800061c8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061cc:	00000097          	auipc	ra,0x0
    800061d0:	c5a080e7          	jalr	-934(ra) # 80005e26 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061d4:	8885                	andi	s1,s1,1
    800061d6:	f0ed                	bnez	s1,800061b8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061d8:	0001f517          	auipc	a0,0x1f
    800061dc:	f5050513          	addi	a0,a0,-176 # 80025128 <disk+0x2128>
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	a96080e7          	jalr	-1386(ra) # 80000c76 <release>
}
    800061e8:	70e6                	ld	ra,120(sp)
    800061ea:	7446                	ld	s0,112(sp)
    800061ec:	74a6                	ld	s1,104(sp)
    800061ee:	7906                	ld	s2,96(sp)
    800061f0:	69e6                	ld	s3,88(sp)
    800061f2:	6a46                	ld	s4,80(sp)
    800061f4:	6aa6                	ld	s5,72(sp)
    800061f6:	6b06                	ld	s6,64(sp)
    800061f8:	7be2                	ld	s7,56(sp)
    800061fa:	7c42                	ld	s8,48(sp)
    800061fc:	7ca2                	ld	s9,40(sp)
    800061fe:	7d02                	ld	s10,32(sp)
    80006200:	6de2                	ld	s11,24(sp)
    80006202:	6109                	addi	sp,sp,128
    80006204:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006206:	f8042503          	lw	a0,-128(s0)
    8000620a:	20050793          	addi	a5,a0,512
    8000620e:	0792                	slli	a5,a5,0x4
  if(write)
    80006210:	0001d817          	auipc	a6,0x1d
    80006214:	df080813          	addi	a6,a6,-528 # 80023000 <disk>
    80006218:	00f80733          	add	a4,a6,a5
    8000621c:	01a036b3          	snez	a3,s10
    80006220:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006224:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006228:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000622c:	7679                	lui	a2,0xffffe
    8000622e:	963e                	add	a2,a2,a5
    80006230:	0001f697          	auipc	a3,0x1f
    80006234:	dd068693          	addi	a3,a3,-560 # 80025000 <disk+0x2000>
    80006238:	6298                	ld	a4,0(a3)
    8000623a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000623c:	0a878593          	addi	a1,a5,168
    80006240:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006242:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006244:	6298                	ld	a4,0(a3)
    80006246:	9732                	add	a4,a4,a2
    80006248:	45c1                	li	a1,16
    8000624a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000624c:	6298                	ld	a4,0(a3)
    8000624e:	9732                	add	a4,a4,a2
    80006250:	4585                	li	a1,1
    80006252:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006256:	f8442703          	lw	a4,-124(s0)
    8000625a:	628c                	ld	a1,0(a3)
    8000625c:	962e                	add	a2,a2,a1
    8000625e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006262:	0712                	slli	a4,a4,0x4
    80006264:	6290                	ld	a2,0(a3)
    80006266:	963a                	add	a2,a2,a4
    80006268:	058a8593          	addi	a1,s5,88
    8000626c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000626e:	6294                	ld	a3,0(a3)
    80006270:	96ba                	add	a3,a3,a4
    80006272:	40000613          	li	a2,1024
    80006276:	c690                	sw	a2,8(a3)
  if(write)
    80006278:	e40d19e3          	bnez	s10,800060ca <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000627c:	0001f697          	auipc	a3,0x1f
    80006280:	d846b683          	ld	a3,-636(a3) # 80025000 <disk+0x2000>
    80006284:	96ba                	add	a3,a3,a4
    80006286:	4609                	li	a2,2
    80006288:	00c69623          	sh	a2,12(a3)
    8000628c:	b5b1                	j	800060d8 <virtio_disk_rw+0xd2>

000000008000628e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000628e:	1101                	addi	sp,sp,-32
    80006290:	ec06                	sd	ra,24(sp)
    80006292:	e822                	sd	s0,16(sp)
    80006294:	e426                	sd	s1,8(sp)
    80006296:	e04a                	sd	s2,0(sp)
    80006298:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000629a:	0001f517          	auipc	a0,0x1f
    8000629e:	e8e50513          	addi	a0,a0,-370 # 80025128 <disk+0x2128>
    800062a2:	ffffb097          	auipc	ra,0xffffb
    800062a6:	920080e7          	jalr	-1760(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062aa:	10001737          	lui	a4,0x10001
    800062ae:	533c                	lw	a5,96(a4)
    800062b0:	8b8d                	andi	a5,a5,3
    800062b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062b8:	0001f797          	auipc	a5,0x1f
    800062bc:	d4878793          	addi	a5,a5,-696 # 80025000 <disk+0x2000>
    800062c0:	6b94                	ld	a3,16(a5)
    800062c2:	0207d703          	lhu	a4,32(a5)
    800062c6:	0026d783          	lhu	a5,2(a3)
    800062ca:	06f70163          	beq	a4,a5,8000632c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062ce:	0001d917          	auipc	s2,0x1d
    800062d2:	d3290913          	addi	s2,s2,-718 # 80023000 <disk>
    800062d6:	0001f497          	auipc	s1,0x1f
    800062da:	d2a48493          	addi	s1,s1,-726 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062de:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062e2:	6898                	ld	a4,16(s1)
    800062e4:	0204d783          	lhu	a5,32(s1)
    800062e8:	8b9d                	andi	a5,a5,7
    800062ea:	078e                	slli	a5,a5,0x3
    800062ec:	97ba                	add	a5,a5,a4
    800062ee:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062f0:	20078713          	addi	a4,a5,512
    800062f4:	0712                	slli	a4,a4,0x4
    800062f6:	974a                	add	a4,a4,s2
    800062f8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062fc:	e731                	bnez	a4,80006348 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062fe:	20078793          	addi	a5,a5,512
    80006302:	0792                	slli	a5,a5,0x4
    80006304:	97ca                	add	a5,a5,s2
    80006306:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006308:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000630c:	ffffc097          	auipc	ra,0xffffc
    80006310:	f0c080e7          	jalr	-244(ra) # 80002218 <wakeup>

    disk.used_idx += 1;
    80006314:	0204d783          	lhu	a5,32(s1)
    80006318:	2785                	addiw	a5,a5,1
    8000631a:	17c2                	slli	a5,a5,0x30
    8000631c:	93c1                	srli	a5,a5,0x30
    8000631e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006322:	6898                	ld	a4,16(s1)
    80006324:	00275703          	lhu	a4,2(a4)
    80006328:	faf71be3          	bne	a4,a5,800062de <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000632c:	0001f517          	auipc	a0,0x1f
    80006330:	dfc50513          	addi	a0,a0,-516 # 80025128 <disk+0x2128>
    80006334:	ffffb097          	auipc	ra,0xffffb
    80006338:	942080e7          	jalr	-1726(ra) # 80000c76 <release>
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6902                	ld	s2,0(sp)
    80006344:	6105                	addi	sp,sp,32
    80006346:	8082                	ret
      panic("virtio_disk_intr status");
    80006348:	00002517          	auipc	a0,0x2
    8000634c:	6d850513          	addi	a0,a0,1752 # 80008a20 <syscalls_str+0x3b8>
    80006350:	ffffa097          	auipc	ra,0xffffa
    80006354:	1da080e7          	jalr	474(ra) # 8000052a <panic>
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
