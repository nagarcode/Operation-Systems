
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
    80000068:	ecc78793          	addi	a5,a5,-308 # 80005f30 <timervec>
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
    80000122:	596080e7          	jalr	1430(ra) # 800026b4 <either_copyin>
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
    800001c6:	f0c080e7          	jalr	-244(ra) # 800020ce <sleep>
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
    80000202:	460080e7          	jalr	1120(ra) # 8000265e <either_copyout>
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
    800002e2:	42c080e7          	jalr	1068(ra) # 8000270a <procdump>
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
    80000436:	e28080e7          	jalr	-472(ra) # 8000225a <wakeup>
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
    80000468:	4b478793          	addi	a5,a5,1204 # 80021918 <devsw>
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
    80000882:	9dc080e7          	jalr	-1572(ra) # 8000225a <wakeup>
    
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
    8000090e:	7c4080e7          	jalr	1988(ra) # 800020ce <sleep>
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
    80000eb6:	99a080e7          	jalr	-1638(ra) # 8000284c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	0b6080e7          	jalr	182(ra) # 80005f70 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	02e080e7          	jalr	46(ra) # 80001ef0 <scheduler>
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
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	8fa080e7          	jalr	-1798(ra) # 80002824 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	91a080e7          	jalr	-1766(ra) # 8000284c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	020080e7          	jalr	32(ra) # 80005f5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	02e080e7          	jalr	46(ra) # 80005f70 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	1fa080e7          	jalr	506(ra) # 80003144 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	88c080e7          	jalr	-1908(ra) # 800037de <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	83a080e7          	jalr	-1990(ra) # 80004794 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	130080e7          	jalr	304(ra) # 80006092 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d48080e7          	jalr	-696(ra) # 80001cb2 <userinit>
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
    80001854:	e80a0a13          	addi	s4,s4,-384 # 800176d0 <tickslock>
    char *pa = kalloc();
    80001858:	fffff097          	auipc	ra,0xfffff
    8000185c:	27a080e7          	jalr	634(ra) # 80000ad2 <kalloc>
    80001860:	862a                	mv	a2,a0
    if (pa == 0)
    80001862:	c131                	beqz	a0,800018a6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001864:	416485b3          	sub	a1,s1,s6
    80001868:	859d                	srai	a1,a1,0x7
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
    8000188a:	18048493          	addi	s1,s1,384
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
    80001920:	db498993          	addi	s3,s3,-588 # 800176d0 <tickslock>
    initlock(&p->lock, "proc");
    80001924:	85da                	mv	a1,s6
    80001926:	8526                	mv	a0,s1
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	20a080e7          	jalr	522(ra) # 80000b32 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001930:	415487b3          	sub	a5,s1,s5
    80001934:	879d                	srai	a5,a5,0x7
    80001936:	000a3703          	ld	a4,0(s4)
    8000193a:	02e787b3          	mul	a5,a5,a4
    8000193e:	2785                	addiw	a5,a5,1
    80001940:	00d7979b          	slliw	a5,a5,0xd
    80001944:	40f907b3          	sub	a5,s2,a5
    80001948:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000194a:	18048493          	addi	s1,s1,384
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
    800019e6:	07e7a783          	lw	a5,126(a5) # 80008a60 <first.1>
    800019ea:	eb89                	bnez	a5,800019fc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ec:	00001097          	auipc	ra,0x1
    800019f0:	e78080e7          	jalr	-392(ra) # 80002864 <usertrapret>
}
    800019f4:	60a2                	ld	ra,8(sp)
    800019f6:	6402                	ld	s0,0(sp)
    800019f8:	0141                	addi	sp,sp,16
    800019fa:	8082                	ret
    first = 0;
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	0607a223          	sw	zero,100(a5) # 80008a60 <first.1>
    fsinit(ROOTDEV);
    80001a04:	4505                	li	a0,1
    80001a06:	00002097          	auipc	ra,0x2
    80001a0a:	d58080e7          	jalr	-680(ra) # 8000375e <fsinit>
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
    80001a32:	03678793          	addi	a5,a5,54 # 80008a64 <nextpid>
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
    80001bb0:	00016917          	auipc	s2,0x16
    80001bb4:	b2090913          	addi	s2,s2,-1248 # 800176d0 <tickslock>
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
    80001bd0:	18048493          	addi	s1,s1,384
    80001bd4:	ff2492e3          	bne	s1,s2,80001bb8 <allocproc+0x1c>
  return 0;
    80001bd8:	4481                	li	s1,0
    80001bda:	a869                	j	80001c74 <allocproc+0xd8>
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
    80001bf6:	c551                	beqz	a0,80001c82 <allocproc+0xe6>
  p->pagetable = proc_pagetable(p);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e5c080e7          	jalr	-420(ra) # 80001a56 <proc_pagetable>
    80001c02:	892a                	mv	s2,a0
    80001c04:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c06:	c951                	beqz	a0,80001c9a <allocproc+0xfe>
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
  p->retime = 0;
    80001c30:	1604aa23          	sw	zero,372(s1)
  p->runtime = 0;
    80001c34:	1604ac23          	sw	zero,376(s1)
  p->stime = 0;
    80001c38:	1604a823          	sw	zero,368(s1)
  p->ttime = -1;
    80001c3c:	57fd                	li	a5,-1
    80001c3e:	16f4a623          	sw	a5,364(s1)
  p->average_bursttime = QUANTUM;
    80001c42:	4785                	li	a5,1
    80001c44:	16f4ae23          	sw	a5,380(s1)
  acquire(&tickslock);
    80001c48:	00016517          	auipc	a0,0x16
    80001c4c:	a8850513          	addi	a0,a0,-1400 # 800176d0 <tickslock>
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	f72080e7          	jalr	-142(ra) # 80000bc2 <acquire>
  p->ctime = ticks;
    80001c58:	00007797          	auipc	a5,0x7
    80001c5c:	3d87a783          	lw	a5,984(a5) # 80009030 <ticks>
    80001c60:	16f4a423          	sw	a5,360(s1)
  release(&tickslock);
    80001c64:	00016517          	auipc	a0,0x16
    80001c68:	a6c50513          	addi	a0,a0,-1428 # 800176d0 <tickslock>
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	00a080e7          	jalr	10(ra) # 80000c76 <release>
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6902                	ld	s2,0(sp)
    80001c7e:	6105                	addi	sp,sp,32
    80001c80:	8082                	ret
    freeproc(p);
    80001c82:	8526                	mv	a0,s1
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	ec0080e7          	jalr	-320(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	fe8080e7          	jalr	-24(ra) # 80000c76 <release>
    return 0;
    80001c96:	84ca                	mv	s1,s2
    80001c98:	bff1                	j	80001c74 <allocproc+0xd8>
    freeproc(p);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	ea8080e7          	jalr	-344(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	fd0080e7          	jalr	-48(ra) # 80000c76 <release>
    return 0;
    80001cae:	84ca                	mv	s1,s2
    80001cb0:	b7d1                	j	80001c74 <allocproc+0xd8>

0000000080001cb2 <userinit>:
{
    80001cb2:	1101                	addi	sp,sp,-32
    80001cb4:	ec06                	sd	ra,24(sp)
    80001cb6:	e822                	sd	s0,16(sp)
    80001cb8:	e426                	sd	s1,8(sp)
    80001cba:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	ee0080e7          	jalr	-288(ra) # 80001b9c <allocproc>
    80001cc4:	84aa                	mv	s1,a0
  initproc = p;
    80001cc6:	00007797          	auipc	a5,0x7
    80001cca:	36a7b123          	sd	a0,866(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cce:	03400613          	li	a2,52
    80001cd2:	00007597          	auipc	a1,0x7
    80001cd6:	d9e58593          	addi	a1,a1,-610 # 80008a70 <initcode>
    80001cda:	6928                	ld	a0,80(a0)
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	658080e7          	jalr	1624(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001ce4:	6785                	lui	a5,0x1
    80001ce6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ce8:	6cb8                	ld	a4,88(s1)
    80001cea:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cee:	6cb8                	ld	a4,88(s1)
    80001cf0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf2:	4641                	li	a2,16
    80001cf4:	00006597          	auipc	a1,0x6
    80001cf8:	4f458593          	addi	a1,a1,1268 # 800081e8 <digits+0x1a8>
    80001cfc:	15848513          	addi	a0,s1,344
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	110080e7          	jalr	272(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001d08:	00006517          	auipc	a0,0x6
    80001d0c:	4f050513          	addi	a0,a0,1264 # 800081f8 <digits+0x1b8>
    80001d10:	00002097          	auipc	ra,0x2
    80001d14:	47c080e7          	jalr	1148(ra) # 8000418c <namei>
    80001d18:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1c:	478d                	li	a5,3
    80001d1e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	f54080e7          	jalr	-172(ra) # 80000c76 <release>
}
    80001d2a:	60e2                	ld	ra,24(sp)
    80001d2c:	6442                	ld	s0,16(sp)
    80001d2e:	64a2                	ld	s1,8(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret

0000000080001d34 <growproc>:
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	e04a                	sd	s2,0(sp)
    80001d3e:	1000                	addi	s0,sp,32
    80001d40:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	c50080e7          	jalr	-944(ra) # 80001992 <myproc>
    80001d4a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d4c:	652c                	ld	a1,72(a0)
    80001d4e:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d52:	00904f63          	bgtz	s1,80001d70 <growproc+0x3c>
  else if (n < 0)
    80001d56:	0204cc63          	bltz	s1,80001d8e <growproc+0x5a>
  p->sz = sz;
    80001d5a:	1602                	slli	a2,a2,0x20
    80001d5c:	9201                	srli	a2,a2,0x20
    80001d5e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d62:	4501                	li	a0,0
}
    80001d64:	60e2                	ld	ra,24(sp)
    80001d66:	6442                	ld	s0,16(sp)
    80001d68:	64a2                	ld	s1,8(sp)
    80001d6a:	6902                	ld	s2,0(sp)
    80001d6c:	6105                	addi	sp,sp,32
    80001d6e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d70:	9e25                	addw	a2,a2,s1
    80001d72:	1602                	slli	a2,a2,0x20
    80001d74:	9201                	srli	a2,a2,0x20
    80001d76:	1582                	slli	a1,a1,0x20
    80001d78:	9181                	srli	a1,a1,0x20
    80001d7a:	6928                	ld	a0,80(a0)
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	672080e7          	jalr	1650(ra) # 800013ee <uvmalloc>
    80001d84:	0005061b          	sext.w	a2,a0
    80001d88:	fa69                	bnez	a2,80001d5a <growproc+0x26>
      return -1;
    80001d8a:	557d                	li	a0,-1
    80001d8c:	bfe1                	j	80001d64 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d8e:	9e25                	addw	a2,a2,s1
    80001d90:	1602                	slli	a2,a2,0x20
    80001d92:	9201                	srli	a2,a2,0x20
    80001d94:	1582                	slli	a1,a1,0x20
    80001d96:	9181                	srli	a1,a1,0x20
    80001d98:	6928                	ld	a0,80(a0)
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	60c080e7          	jalr	1548(ra) # 800013a6 <uvmdealloc>
    80001da2:	0005061b          	sext.w	a2,a0
    80001da6:	bf55                	j	80001d5a <growproc+0x26>

0000000080001da8 <fork>:
{
    80001da8:	7139                	addi	sp,sp,-64
    80001daa:	fc06                	sd	ra,56(sp)
    80001dac:	f822                	sd	s0,48(sp)
    80001dae:	f426                	sd	s1,40(sp)
    80001db0:	f04a                	sd	s2,32(sp)
    80001db2:	ec4e                	sd	s3,24(sp)
    80001db4:	e852                	sd	s4,16(sp)
    80001db6:	e456                	sd	s5,8(sp)
    80001db8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	bd8080e7          	jalr	-1064(ra) # 80001992 <myproc>
    80001dc2:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	dd8080e7          	jalr	-552(ra) # 80001b9c <allocproc>
    80001dcc:	12050063          	beqz	a0,80001eec <fork+0x144>
    80001dd0:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dd2:	048ab603          	ld	a2,72(s5)
    80001dd6:	692c                	ld	a1,80(a0)
    80001dd8:	050ab503          	ld	a0,80(s5)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	75e080e7          	jalr	1886(ra) # 8000153a <uvmcopy>
    80001de4:	04054863          	bltz	a0,80001e34 <fork+0x8c>
  np->sz = p->sz;
    80001de8:	048ab783          	ld	a5,72(s5)
    80001dec:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df0:	058ab683          	ld	a3,88(s5)
    80001df4:	87b6                	mv	a5,a3
    80001df6:	0589b703          	ld	a4,88(s3)
    80001dfa:	12068693          	addi	a3,a3,288
    80001dfe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e02:	6788                	ld	a0,8(a5)
    80001e04:	6b8c                	ld	a1,16(a5)
    80001e06:	6f90                	ld	a2,24(a5)
    80001e08:	01073023          	sd	a6,0(a4)
    80001e0c:	e708                	sd	a0,8(a4)
    80001e0e:	eb0c                	sd	a1,16(a4)
    80001e10:	ef10                	sd	a2,24(a4)
    80001e12:	02078793          	addi	a5,a5,32
    80001e16:	02070713          	addi	a4,a4,32
    80001e1a:	fed792e3          	bne	a5,a3,80001dfe <fork+0x56>
  np->trapframe->a0 = 0;
    80001e1e:	0589b783          	ld	a5,88(s3)
    80001e22:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e26:	0d0a8493          	addi	s1,s5,208
    80001e2a:	0d098913          	addi	s2,s3,208
    80001e2e:	150a8a13          	addi	s4,s5,336
    80001e32:	a00d                	j	80001e54 <fork+0xac>
    freeproc(np);
    80001e34:	854e                	mv	a0,s3
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	d0e080e7          	jalr	-754(ra) # 80001b44 <freeproc>
    release(&np->lock);
    80001e3e:	854e                	mv	a0,s3
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	e36080e7          	jalr	-458(ra) # 80000c76 <release>
    return -1;
    80001e48:	597d                	li	s2,-1
    80001e4a:	a079                	j	80001ed8 <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80001e4c:	04a1                	addi	s1,s1,8
    80001e4e:	0921                	addi	s2,s2,8
    80001e50:	01448b63          	beq	s1,s4,80001e66 <fork+0xbe>
    if (p->ofile[i])
    80001e54:	6088                	ld	a0,0(s1)
    80001e56:	d97d                	beqz	a0,80001e4c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e58:	00003097          	auipc	ra,0x3
    80001e5c:	9ce080e7          	jalr	-1586(ra) # 80004826 <filedup>
    80001e60:	00a93023          	sd	a0,0(s2)
    80001e64:	b7e5                	j	80001e4c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e66:	150ab503          	ld	a0,336(s5)
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	b2e080e7          	jalr	-1234(ra) # 80003998 <idup>
    80001e72:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e76:	4641                	li	a2,16
    80001e78:	158a8593          	addi	a1,s5,344
    80001e7c:	15898513          	addi	a0,s3,344
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	f90080e7          	jalr	-112(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e88:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e8c:	854e                	mv	a0,s3
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	de8080e7          	jalr	-536(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e96:	0000f497          	auipc	s1,0xf
    80001e9a:	42248493          	addi	s1,s1,1058 # 800112b8 <wait_lock>
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	d22080e7          	jalr	-734(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001ea8:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001eac:	8526                	mv	a0,s1
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	dc8080e7          	jalr	-568(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001eb6:	854e                	mv	a0,s3
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	d0a080e7          	jalr	-758(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001ec0:	478d                	li	a5,3
    80001ec2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ec6:	854e                	mv	a0,s3
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dae080e7          	jalr	-594(ra) # 80000c76 <release>
  np->traceMask = p->traceMask;
    80001ed0:	034aa783          	lw	a5,52(s5)
    80001ed4:	02f9aa23          	sw	a5,52(s3)
}
    80001ed8:	854a                	mv	a0,s2
    80001eda:	70e2                	ld	ra,56(sp)
    80001edc:	7442                	ld	s0,48(sp)
    80001ede:	74a2                	ld	s1,40(sp)
    80001ee0:	7902                	ld	s2,32(sp)
    80001ee2:	69e2                	ld	s3,24(sp)
    80001ee4:	6a42                	ld	s4,16(sp)
    80001ee6:	6aa2                	ld	s5,8(sp)
    80001ee8:	6121                	addi	sp,sp,64
    80001eea:	8082                	ret
    return -1;
    80001eec:	597d                	li	s2,-1
    80001eee:	b7ed                	j	80001ed8 <fork+0x130>

0000000080001ef0 <scheduler>:
{
    80001ef0:	715d                	addi	sp,sp,-80
    80001ef2:	e486                	sd	ra,72(sp)
    80001ef4:	e0a2                	sd	s0,64(sp)
    80001ef6:	fc26                	sd	s1,56(sp)
    80001ef8:	f84a                	sd	s2,48(sp)
    80001efa:	f44e                	sd	s3,40(sp)
    80001efc:	f052                	sd	s4,32(sp)
    80001efe:	ec56                	sd	s5,24(sp)
    80001f00:	e85a                	sd	s6,16(sp)
    80001f02:	e45e                	sd	s7,8(sp)
    80001f04:	e062                	sd	s8,0(sp)
    80001f06:	0880                	addi	s0,sp,80
    80001f08:	8792                	mv	a5,tp
  int id = r_tp();
    80001f0a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0c:	00779b13          	slli	s6,a5,0x7
    80001f10:	0000f717          	auipc	a4,0xf
    80001f14:	39070713          	addi	a4,a4,912 # 800112a0 <pid_lock>
    80001f18:	975a                	add	a4,a4,s6
    80001f1a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f1e:	0000f717          	auipc	a4,0xf
    80001f22:	3ba70713          	addi	a4,a4,954 # 800112d8 <cpus+0x8>
    80001f26:	9b3a                	add	s6,s6,a4
      if (p->state == RUNNABLE)
    80001f28:	498d                	li	s3,3
        p->state = RUNNING;
    80001f2a:	4b91                	li	s7,4
        c->proc = p;
    80001f2c:	079e                	slli	a5,a5,0x7
    80001f2e:	0000fa17          	auipc	s4,0xf
    80001f32:	372a0a13          	addi	s4,s4,882 # 800112a0 <pid_lock>
    80001f36:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f38:	00015917          	auipc	s2,0x15
    80001f3c:	79890913          	addi	s2,s2,1944 # 800176d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f44:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f48:	10079073          	csrw	sstatus,a5
    80001f4c:	0000f497          	auipc	s1,0xf
    80001f50:	78448493          	addi	s1,s1,1924 # 800116d0 <proc>
        p->average_bursttime = (ALPHA*curr_burst) + (((100-ALPHA)*avg)/100);
    80001f54:	03200a93          	li	s5,50
    80001f58:	a811                	j	80001f6c <scheduler+0x7c>
      release(&p->lock);
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	d1a080e7          	jalr	-742(ra) # 80000c76 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f64:	18048493          	addi	s1,s1,384
    80001f68:	fd248ce3          	beq	s1,s2,80001f40 <scheduler+0x50>
      acquire(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	c54080e7          	jalr	-940(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    80001f76:	4c9c                	lw	a5,24(s1)
    80001f78:	ff3791e3          	bne	a5,s3,80001f5a <scheduler+0x6a>
        p->state = RUNNING;
    80001f7c:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f80:	029a3823          	sd	s1,48(s4)
        int old_runtime = p->runtime;
    80001f84:	1784ac03          	lw	s8,376(s1)
        swtch(&c->context, &p->context);
    80001f88:	06048593          	addi	a1,s1,96
    80001f8c:	855a                	mv	a0,s6
    80001f8e:	00001097          	auipc	ra,0x1
    80001f92:	82c080e7          	jalr	-2004(ra) # 800027ba <swtch>
        int curr_burst = p->runtime - old_runtime;
    80001f96:	1784a783          	lw	a5,376(s1)
    80001f9a:	418787bb          	subw	a5,a5,s8
        p->average_bursttime = (ALPHA*curr_burst) + (((100-ALPHA)*avg)/100);
    80001f9e:	035787bb          	mulw	a5,a5,s5
    80001fa2:	17c4a683          	lw	a3,380(s1)
    80001fa6:	01f6d71b          	srliw	a4,a3,0x1f
    80001faa:	9f35                	addw	a4,a4,a3
    80001fac:	4017571b          	sraiw	a4,a4,0x1
    80001fb0:	9fb9                	addw	a5,a5,a4
    80001fb2:	16f4ae23          	sw	a5,380(s1)
        c->proc = 0;
    80001fb6:	020a3823          	sd	zero,48(s4)
    80001fba:	b745                	j	80001f5a <scheduler+0x6a>

0000000080001fbc <sched>:
{
    80001fbc:	7179                	addi	sp,sp,-48
    80001fbe:	f406                	sd	ra,40(sp)
    80001fc0:	f022                	sd	s0,32(sp)
    80001fc2:	ec26                	sd	s1,24(sp)
    80001fc4:	e84a                	sd	s2,16(sp)
    80001fc6:	e44e                	sd	s3,8(sp)
    80001fc8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	9c8080e7          	jalr	-1592(ra) # 80001992 <myproc>
    80001fd2:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	b74080e7          	jalr	-1164(ra) # 80000b48 <holding>
    80001fdc:	c93d                	beqz	a0,80002052 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fde:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fe0:	2781                	sext.w	a5,a5
    80001fe2:	079e                	slli	a5,a5,0x7
    80001fe4:	0000f717          	auipc	a4,0xf
    80001fe8:	2bc70713          	addi	a4,a4,700 # 800112a0 <pid_lock>
    80001fec:	97ba                	add	a5,a5,a4
    80001fee:	0a87a703          	lw	a4,168(a5)
    80001ff2:	4785                	li	a5,1
    80001ff4:	06f71763          	bne	a4,a5,80002062 <sched+0xa6>
  if (p->state == RUNNING)
    80001ff8:	4c98                	lw	a4,24(s1)
    80001ffa:	4791                	li	a5,4
    80001ffc:	06f70b63          	beq	a4,a5,80002072 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002000:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002004:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002006:	efb5                	bnez	a5,80002082 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002008:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000200a:	0000f917          	auipc	s2,0xf
    8000200e:	29690913          	addi	s2,s2,662 # 800112a0 <pid_lock>
    80002012:	2781                	sext.w	a5,a5
    80002014:	079e                	slli	a5,a5,0x7
    80002016:	97ca                	add	a5,a5,s2
    80002018:	0ac7a983          	lw	s3,172(a5)
    8000201c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000201e:	2781                	sext.w	a5,a5
    80002020:	079e                	slli	a5,a5,0x7
    80002022:	0000f597          	auipc	a1,0xf
    80002026:	2b658593          	addi	a1,a1,694 # 800112d8 <cpus+0x8>
    8000202a:	95be                	add	a1,a1,a5
    8000202c:	06048513          	addi	a0,s1,96
    80002030:	00000097          	auipc	ra,0x0
    80002034:	78a080e7          	jalr	1930(ra) # 800027ba <swtch>
    80002038:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000203a:	2781                	sext.w	a5,a5
    8000203c:	079e                	slli	a5,a5,0x7
    8000203e:	97ca                	add	a5,a5,s2
    80002040:	0b37a623          	sw	s3,172(a5)
}
    80002044:	70a2                	ld	ra,40(sp)
    80002046:	7402                	ld	s0,32(sp)
    80002048:	64e2                	ld	s1,24(sp)
    8000204a:	6942                	ld	s2,16(sp)
    8000204c:	69a2                	ld	s3,8(sp)
    8000204e:	6145                	addi	sp,sp,48
    80002050:	8082                	ret
    panic("sched p->lock");
    80002052:	00006517          	auipc	a0,0x6
    80002056:	1ae50513          	addi	a0,a0,430 # 80008200 <digits+0x1c0>
    8000205a:	ffffe097          	auipc	ra,0xffffe
    8000205e:	4d0080e7          	jalr	1232(ra) # 8000052a <panic>
    panic("sched locks");
    80002062:	00006517          	auipc	a0,0x6
    80002066:	1ae50513          	addi	a0,a0,430 # 80008210 <digits+0x1d0>
    8000206a:	ffffe097          	auipc	ra,0xffffe
    8000206e:	4c0080e7          	jalr	1216(ra) # 8000052a <panic>
    panic("sched running");
    80002072:	00006517          	auipc	a0,0x6
    80002076:	1ae50513          	addi	a0,a0,430 # 80008220 <digits+0x1e0>
    8000207a:	ffffe097          	auipc	ra,0xffffe
    8000207e:	4b0080e7          	jalr	1200(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002082:	00006517          	auipc	a0,0x6
    80002086:	1ae50513          	addi	a0,a0,430 # 80008230 <digits+0x1f0>
    8000208a:	ffffe097          	auipc	ra,0xffffe
    8000208e:	4a0080e7          	jalr	1184(ra) # 8000052a <panic>

0000000080002092 <yield>:
{
    80002092:	1101                	addi	sp,sp,-32
    80002094:	ec06                	sd	ra,24(sp)
    80002096:	e822                	sd	s0,16(sp)
    80002098:	e426                	sd	s1,8(sp)
    8000209a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	8f6080e7          	jalr	-1802(ra) # 80001992 <myproc>
    800020a4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	b1c080e7          	jalr	-1252(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    800020ae:	478d                	li	a5,3
    800020b0:	cc9c                	sw	a5,24(s1)
  sched();
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	f0a080e7          	jalr	-246(ra) # 80001fbc <sched>
  release(&p->lock);
    800020ba:	8526                	mv	a0,s1
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	bba080e7          	jalr	-1094(ra) # 80000c76 <release>
}
    800020c4:	60e2                	ld	ra,24(sp)
    800020c6:	6442                	ld	s0,16(sp)
    800020c8:	64a2                	ld	s1,8(sp)
    800020ca:	6105                	addi	sp,sp,32
    800020cc:	8082                	ret

00000000800020ce <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020ce:	7179                	addi	sp,sp,-48
    800020d0:	f406                	sd	ra,40(sp)
    800020d2:	f022                	sd	s0,32(sp)
    800020d4:	ec26                	sd	s1,24(sp)
    800020d6:	e84a                	sd	s2,16(sp)
    800020d8:	e44e                	sd	s3,8(sp)
    800020da:	1800                	addi	s0,sp,48
    800020dc:	89aa                	mv	s3,a0
    800020de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	8b2080e7          	jalr	-1870(ra) # 80001992 <myproc>
    800020e8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	ad8080e7          	jalr	-1320(ra) # 80000bc2 <acquire>
  release(lk);
    800020f2:	854a                	mv	a0,s2
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	b82080e7          	jalr	-1150(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020fc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002100:	4789                	li	a5,2
    80002102:	cc9c                	sw	a5,24(s1)

  sched();
    80002104:	00000097          	auipc	ra,0x0
    80002108:	eb8080e7          	jalr	-328(ra) # 80001fbc <sched>

  // Tidy up.
  p->chan = 0;
    8000210c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b64080e7          	jalr	-1180(ra) # 80000c76 <release>
  acquire(lk);
    8000211a:	854a                	mv	a0,s2
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	aa6080e7          	jalr	-1370(ra) # 80000bc2 <acquire>
}
    80002124:	70a2                	ld	ra,40(sp)
    80002126:	7402                	ld	s0,32(sp)
    80002128:	64e2                	ld	s1,24(sp)
    8000212a:	6942                	ld	s2,16(sp)
    8000212c:	69a2                	ld	s3,8(sp)
    8000212e:	6145                	addi	sp,sp,48
    80002130:	8082                	ret

0000000080002132 <wait>:
{
    80002132:	715d                	addi	sp,sp,-80
    80002134:	e486                	sd	ra,72(sp)
    80002136:	e0a2                	sd	s0,64(sp)
    80002138:	fc26                	sd	s1,56(sp)
    8000213a:	f84a                	sd	s2,48(sp)
    8000213c:	f44e                	sd	s3,40(sp)
    8000213e:	f052                	sd	s4,32(sp)
    80002140:	ec56                	sd	s5,24(sp)
    80002142:	e85a                	sd	s6,16(sp)
    80002144:	e45e                	sd	s7,8(sp)
    80002146:	e062                	sd	s8,0(sp)
    80002148:	0880                	addi	s0,sp,80
    8000214a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	846080e7          	jalr	-1978(ra) # 80001992 <myproc>
    80002154:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002156:	0000f517          	auipc	a0,0xf
    8000215a:	16250513          	addi	a0,a0,354 # 800112b8 <wait_lock>
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	a64080e7          	jalr	-1436(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002166:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002168:	4a15                	li	s4,5
        havekids = 1;
    8000216a:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000216c:	00015997          	auipc	s3,0x15
    80002170:	56498993          	addi	s3,s3,1380 # 800176d0 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002174:	0000fc17          	auipc	s8,0xf
    80002178:	144c0c13          	addi	s8,s8,324 # 800112b8 <wait_lock>
    havekids = 0;
    8000217c:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000217e:	0000f497          	auipc	s1,0xf
    80002182:	55248493          	addi	s1,s1,1362 # 800116d0 <proc>
    80002186:	a0bd                	j	800021f4 <wait+0xc2>
          pid = np->pid;
    80002188:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000218c:	000b0e63          	beqz	s6,800021a8 <wait+0x76>
    80002190:	4691                	li	a3,4
    80002192:	02c48613          	addi	a2,s1,44
    80002196:	85da                	mv	a1,s6
    80002198:	05093503          	ld	a0,80(s2)
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	4a2080e7          	jalr	1186(ra) # 8000163e <copyout>
    800021a4:	02054563          	bltz	a0,800021ce <wait+0x9c>
          freeproc(np);
    800021a8:	8526                	mv	a0,s1
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	99a080e7          	jalr	-1638(ra) # 80001b44 <freeproc>
          release(&np->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	ac2080e7          	jalr	-1342(ra) # 80000c76 <release>
          release(&wait_lock);
    800021bc:	0000f517          	auipc	a0,0xf
    800021c0:	0fc50513          	addi	a0,a0,252 # 800112b8 <wait_lock>
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ab2080e7          	jalr	-1358(ra) # 80000c76 <release>
          return pid;
    800021cc:	a09d                	j	80002232 <wait+0x100>
            release(&np->lock);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	aa6080e7          	jalr	-1370(ra) # 80000c76 <release>
            release(&wait_lock);
    800021d8:	0000f517          	auipc	a0,0xf
    800021dc:	0e050513          	addi	a0,a0,224 # 800112b8 <wait_lock>
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	a96080e7          	jalr	-1386(ra) # 80000c76 <release>
            return -1;
    800021e8:	59fd                	li	s3,-1
    800021ea:	a0a1                	j	80002232 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800021ec:	18048493          	addi	s1,s1,384
    800021f0:	03348463          	beq	s1,s3,80002218 <wait+0xe6>
      if (np->parent == p)
    800021f4:	7c9c                	ld	a5,56(s1)
    800021f6:	ff279be3          	bne	a5,s2,800021ec <wait+0xba>
        acquire(&np->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	9c6080e7          	jalr	-1594(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    80002204:	4c9c                	lw	a5,24(s1)
    80002206:	f94781e3          	beq	a5,s4,80002188 <wait+0x56>
        release(&np->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a6a080e7          	jalr	-1430(ra) # 80000c76 <release>
        havekids = 1;
    80002214:	8756                	mv	a4,s5
    80002216:	bfd9                	j	800021ec <wait+0xba>
    if (!havekids || p->killed)
    80002218:	c701                	beqz	a4,80002220 <wait+0xee>
    8000221a:	02892783          	lw	a5,40(s2)
    8000221e:	c79d                	beqz	a5,8000224c <wait+0x11a>
      release(&wait_lock);
    80002220:	0000f517          	auipc	a0,0xf
    80002224:	09850513          	addi	a0,a0,152 # 800112b8 <wait_lock>
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a4e080e7          	jalr	-1458(ra) # 80000c76 <release>
      return -1;
    80002230:	59fd                	li	s3,-1
}
    80002232:	854e                	mv	a0,s3
    80002234:	60a6                	ld	ra,72(sp)
    80002236:	6406                	ld	s0,64(sp)
    80002238:	74e2                	ld	s1,56(sp)
    8000223a:	7942                	ld	s2,48(sp)
    8000223c:	79a2                	ld	s3,40(sp)
    8000223e:	7a02                	ld	s4,32(sp)
    80002240:	6ae2                	ld	s5,24(sp)
    80002242:	6b42                	ld	s6,16(sp)
    80002244:	6ba2                	ld	s7,8(sp)
    80002246:	6c02                	ld	s8,0(sp)
    80002248:	6161                	addi	sp,sp,80
    8000224a:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000224c:	85e2                	mv	a1,s8
    8000224e:	854a                	mv	a0,s2
    80002250:	00000097          	auipc	ra,0x0
    80002254:	e7e080e7          	jalr	-386(ra) # 800020ce <sleep>
    havekids = 0;
    80002258:	b715                	j	8000217c <wait+0x4a>

000000008000225a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000225a:	7139                	addi	sp,sp,-64
    8000225c:	fc06                	sd	ra,56(sp)
    8000225e:	f822                	sd	s0,48(sp)
    80002260:	f426                	sd	s1,40(sp)
    80002262:	f04a                	sd	s2,32(sp)
    80002264:	ec4e                	sd	s3,24(sp)
    80002266:	e852                	sd	s4,16(sp)
    80002268:	e456                	sd	s5,8(sp)
    8000226a:	0080                	addi	s0,sp,64
    8000226c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	46248493          	addi	s1,s1,1122 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002276:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002278:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000227a:	00015917          	auipc	s2,0x15
    8000227e:	45690913          	addi	s2,s2,1110 # 800176d0 <tickslock>
    80002282:	a811                	j	80002296 <wakeup+0x3c>
      }
      release(&p->lock);
    80002284:	8526                	mv	a0,s1
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	9f0080e7          	jalr	-1552(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	18048493          	addi	s1,s1,384
    80002292:	03248663          	beq	s1,s2,800022be <wakeup+0x64>
    if (p != myproc())
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	6fc080e7          	jalr	1788(ra) # 80001992 <myproc>
    8000229e:	fea488e3          	beq	s1,a0,8000228e <wakeup+0x34>
      acquire(&p->lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	91e080e7          	jalr	-1762(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800022ac:	4c9c                	lw	a5,24(s1)
    800022ae:	fd379be3          	bne	a5,s3,80002284 <wakeup+0x2a>
    800022b2:	709c                	ld	a5,32(s1)
    800022b4:	fd4798e3          	bne	a5,s4,80002284 <wakeup+0x2a>
        p->state = RUNNABLE;
    800022b8:	0154ac23          	sw	s5,24(s1)
    800022bc:	b7e1                	j	80002284 <wakeup+0x2a>
    }
  }
}
    800022be:	70e2                	ld	ra,56(sp)
    800022c0:	7442                	ld	s0,48(sp)
    800022c2:	74a2                	ld	s1,40(sp)
    800022c4:	7902                	ld	s2,32(sp)
    800022c6:	69e2                	ld	s3,24(sp)
    800022c8:	6a42                	ld	s4,16(sp)
    800022ca:	6aa2                	ld	s5,8(sp)
    800022cc:	6121                	addi	sp,sp,64
    800022ce:	8082                	ret

00000000800022d0 <reparent>:
{
    800022d0:	7179                	addi	sp,sp,-48
    800022d2:	f406                	sd	ra,40(sp)
    800022d4:	f022                	sd	s0,32(sp)
    800022d6:	ec26                	sd	s1,24(sp)
    800022d8:	e84a                	sd	s2,16(sp)
    800022da:	e44e                	sd	s3,8(sp)
    800022dc:	e052                	sd	s4,0(sp)
    800022de:	1800                	addi	s0,sp,48
    800022e0:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022e2:	0000f497          	auipc	s1,0xf
    800022e6:	3ee48493          	addi	s1,s1,1006 # 800116d0 <proc>
      pp->parent = initproc;
    800022ea:	00007a17          	auipc	s4,0x7
    800022ee:	d3ea0a13          	addi	s4,s4,-706 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022f2:	00015997          	auipc	s3,0x15
    800022f6:	3de98993          	addi	s3,s3,990 # 800176d0 <tickslock>
    800022fa:	a029                	j	80002304 <reparent+0x34>
    800022fc:	18048493          	addi	s1,s1,384
    80002300:	01348d63          	beq	s1,s3,8000231a <reparent+0x4a>
    if (pp->parent == p)
    80002304:	7c9c                	ld	a5,56(s1)
    80002306:	ff279be3          	bne	a5,s2,800022fc <reparent+0x2c>
      pp->parent = initproc;
    8000230a:	000a3503          	ld	a0,0(s4)
    8000230e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002310:	00000097          	auipc	ra,0x0
    80002314:	f4a080e7          	jalr	-182(ra) # 8000225a <wakeup>
    80002318:	b7d5                	j	800022fc <reparent+0x2c>
}
    8000231a:	70a2                	ld	ra,40(sp)
    8000231c:	7402                	ld	s0,32(sp)
    8000231e:	64e2                	ld	s1,24(sp)
    80002320:	6942                	ld	s2,16(sp)
    80002322:	69a2                	ld	s3,8(sp)
    80002324:	6a02                	ld	s4,0(sp)
    80002326:	6145                	addi	sp,sp,48
    80002328:	8082                	ret

000000008000232a <exit>:
{
    8000232a:	7179                	addi	sp,sp,-48
    8000232c:	f406                	sd	ra,40(sp)
    8000232e:	f022                	sd	s0,32(sp)
    80002330:	ec26                	sd	s1,24(sp)
    80002332:	e84a                	sd	s2,16(sp)
    80002334:	e44e                	sd	s3,8(sp)
    80002336:	e052                	sd	s4,0(sp)
    80002338:	1800                	addi	s0,sp,48
    8000233a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	656080e7          	jalr	1622(ra) # 80001992 <myproc>
    80002344:	89aa                	mv	s3,a0
  acquire(&tickslock);
    80002346:	00015517          	auipc	a0,0x15
    8000234a:	38a50513          	addi	a0,a0,906 # 800176d0 <tickslock>
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	874080e7          	jalr	-1932(ra) # 80000bc2 <acquire>
  p->ttime = ticks;
    80002356:	00007797          	auipc	a5,0x7
    8000235a:	cda7a783          	lw	a5,-806(a5) # 80009030 <ticks>
    8000235e:	16f9a623          	sw	a5,364(s3)
  release(&tickslock);
    80002362:	00015517          	auipc	a0,0x15
    80002366:	36e50513          	addi	a0,a0,878 # 800176d0 <tickslock>
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	90c080e7          	jalr	-1780(ra) # 80000c76 <release>
  if (p == initproc)
    80002372:	00007797          	auipc	a5,0x7
    80002376:	cb67b783          	ld	a5,-842(a5) # 80009028 <initproc>
    8000237a:	0d098493          	addi	s1,s3,208
    8000237e:	15098913          	addi	s2,s3,336
    80002382:	03379363          	bne	a5,s3,800023a8 <exit+0x7e>
    panic("init exiting");
    80002386:	00006517          	auipc	a0,0x6
    8000238a:	ec250513          	addi	a0,a0,-318 # 80008248 <digits+0x208>
    8000238e:	ffffe097          	auipc	ra,0xffffe
    80002392:	19c080e7          	jalr	412(ra) # 8000052a <panic>
      fileclose(f);
    80002396:	00002097          	auipc	ra,0x2
    8000239a:	4e2080e7          	jalr	1250(ra) # 80004878 <fileclose>
      p->ofile[fd] = 0;
    8000239e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023a2:	04a1                	addi	s1,s1,8
    800023a4:	01248563          	beq	s1,s2,800023ae <exit+0x84>
    if (p->ofile[fd])
    800023a8:	6088                	ld	a0,0(s1)
    800023aa:	f575                	bnez	a0,80002396 <exit+0x6c>
    800023ac:	bfdd                	j	800023a2 <exit+0x78>
  begin_op();
    800023ae:	00002097          	auipc	ra,0x2
    800023b2:	ffe080e7          	jalr	-2(ra) # 800043ac <begin_op>
  iput(p->cwd);
    800023b6:	1509b503          	ld	a0,336(s3)
    800023ba:	00001097          	auipc	ra,0x1
    800023be:	7d6080e7          	jalr	2006(ra) # 80003b90 <iput>
  end_op();
    800023c2:	00002097          	auipc	ra,0x2
    800023c6:	06a080e7          	jalr	106(ra) # 8000442c <end_op>
  p->cwd = 0;
    800023ca:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023ce:	0000f497          	auipc	s1,0xf
    800023d2:	eea48493          	addi	s1,s1,-278 # 800112b8 <wait_lock>
    800023d6:	8526                	mv	a0,s1
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	7ea080e7          	jalr	2026(ra) # 80000bc2 <acquire>
  reparent(p);
    800023e0:	854e                	mv	a0,s3
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	eee080e7          	jalr	-274(ra) # 800022d0 <reparent>
  wakeup(p->parent);
    800023ea:	0389b503          	ld	a0,56(s3)
    800023ee:	00000097          	auipc	ra,0x0
    800023f2:	e6c080e7          	jalr	-404(ra) # 8000225a <wakeup>
  acquire(&p->lock);
    800023f6:	854e                	mv	a0,s3
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7ca080e7          	jalr	1994(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002400:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002404:	4795                	li	a5,5
    80002406:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	86a080e7          	jalr	-1942(ra) # 80000c76 <release>
  sched();
    80002414:	00000097          	auipc	ra,0x0
    80002418:	ba8080e7          	jalr	-1112(ra) # 80001fbc <sched>
  panic("zombie exit");
    8000241c:	00006517          	auipc	a0,0x6
    80002420:	e3c50513          	addi	a0,a0,-452 # 80008258 <digits+0x218>
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	106080e7          	jalr	262(ra) # 8000052a <panic>

000000008000242c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000242c:	7179                	addi	sp,sp,-48
    8000242e:	f406                	sd	ra,40(sp)
    80002430:	f022                	sd	s0,32(sp)
    80002432:	ec26                	sd	s1,24(sp)
    80002434:	e84a                	sd	s2,16(sp)
    80002436:	e44e                	sd	s3,8(sp)
    80002438:	1800                	addi	s0,sp,48
    8000243a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000243c:	0000f497          	auipc	s1,0xf
    80002440:	29448493          	addi	s1,s1,660 # 800116d0 <proc>
    80002444:	00015997          	auipc	s3,0x15
    80002448:	28c98993          	addi	s3,s3,652 # 800176d0 <tickslock>
  {
    acquire(&p->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	774080e7          	jalr	1908(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    80002456:	589c                	lw	a5,48(s1)
    80002458:	01278d63          	beq	a5,s2,80002472 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	818080e7          	jalr	-2024(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002466:	18048493          	addi	s1,s1,384
    8000246a:	ff3491e3          	bne	s1,s3,8000244c <kill+0x20>
  }
  return -1;
    8000246e:	557d                	li	a0,-1
    80002470:	a829                	j	8000248a <kill+0x5e>
      p->killed = 1;
    80002472:	4785                	li	a5,1
    80002474:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002476:	4c98                	lw	a4,24(s1)
    80002478:	4789                	li	a5,2
    8000247a:	00f70f63          	beq	a4,a5,80002498 <kill+0x6c>
      release(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	7f6080e7          	jalr	2038(ra) # 80000c76 <release>
      return 0;
    80002488:	4501                	li	a0,0
}
    8000248a:	70a2                	ld	ra,40(sp)
    8000248c:	7402                	ld	s0,32(sp)
    8000248e:	64e2                	ld	s1,24(sp)
    80002490:	6942                	ld	s2,16(sp)
    80002492:	69a2                	ld	s3,8(sp)
    80002494:	6145                	addi	sp,sp,48
    80002496:	8082                	ret
        p->state = RUNNABLE;
    80002498:	478d                	li	a5,3
    8000249a:	cc9c                	sw	a5,24(s1)
    8000249c:	b7cd                	j	8000247e <kill+0x52>

000000008000249e <wait_stat>:
int wait_stat(int* status, struct perf *performance){
    8000249e:	711d                	addi	sp,sp,-96
    800024a0:	ec86                	sd	ra,88(sp)
    800024a2:	e8a2                	sd	s0,80(sp)
    800024a4:	e4a6                	sd	s1,72(sp)
    800024a6:	e0ca                	sd	s2,64(sp)
    800024a8:	fc4e                	sd	s3,56(sp)
    800024aa:	f852                	sd	s4,48(sp)
    800024ac:	f456                	sd	s5,40(sp)
    800024ae:	f05a                	sd	s6,32(sp)
    800024b0:	ec5e                	sd	s7,24(sp)
    800024b2:	e862                	sd	s8,16(sp)
    800024b4:	e466                	sd	s9,8(sp)
    800024b6:	1080                	addi	s0,sp,96
    800024b8:	8baa                	mv	s7,a0
    800024ba:	8b2e                	mv	s6,a1
  //TODO: IMPLEMENT!
    struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	4d6080e7          	jalr	1238(ra) # 80001992 <myproc>
    800024c4:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800024c6:	0000f517          	auipc	a0,0xf
    800024ca:	df250513          	addi	a0,a0,-526 # 800112b8 <wait_lock>
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	6f4080e7          	jalr	1780(ra) # 80000bc2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800024d6:	4c01                	li	s8,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800024d8:	4a15                	li	s4,5
        havekids = 1;
    800024da:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800024dc:	00015997          	auipc	s3,0x15
    800024e0:	1f498993          	addi	s3,s3,500 # 800176d0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); //DOC: wait-sleep
    800024e4:	0000fc97          	auipc	s9,0xf
    800024e8:	dd4c8c93          	addi	s9,s9,-556 # 800112b8 <wait_lock>
    havekids = 0;
    800024ec:	8762                	mv	a4,s8
    for (np = proc; np < &proc[NPROC]; np++)
    800024ee:	0000f497          	auipc	s1,0xf
    800024f2:	1e248493          	addi	s1,s1,482 # 800116d0 <proc>
    800024f6:	a859                	j	8000258c <wait_stat+0xee>
          pid = np->pid;
    800024f8:	0304a983          	lw	s3,48(s1)
          performance->ctime = np->ctime;
    800024fc:	1684a783          	lw	a5,360(s1)
    80002500:	00fb2023          	sw	a5,0(s6)
          performance->ttime = np->ttime;
    80002504:	16c4a783          	lw	a5,364(s1)
    80002508:	00fb2223          	sw	a5,4(s6)
          performance->retime = np->retime;
    8000250c:	1744a783          	lw	a5,372(s1)
    80002510:	00fb2623          	sw	a5,12(s6)
          performance->rutime = np->runtime;
    80002514:	1784a783          	lw	a5,376(s1)
    80002518:	00fb2823          	sw	a5,16(s6)
          performance->average_bursttime = np->average_bursttime;
    8000251c:	17c4a783          	lw	a5,380(s1)
    80002520:	00fb2a23          	sw	a5,20(s6)
          if (status != 0 && copyout(p->pagetable, (uint64)status, (char *)&np->xstate,
    80002524:	000b8e63          	beqz	s7,80002540 <wait_stat+0xa2>
    80002528:	4691                	li	a3,4
    8000252a:	02c48613          	addi	a2,s1,44
    8000252e:	85de                	mv	a1,s7
    80002530:	05093503          	ld	a0,80(s2)
    80002534:	fffff097          	auipc	ra,0xfffff
    80002538:	10a080e7          	jalr	266(ra) # 8000163e <copyout>
    8000253c:	02054563          	bltz	a0,80002566 <wait_stat+0xc8>
          freeproc(np);
    80002540:	8526                	mv	a0,s1
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	602080e7          	jalr	1538(ra) # 80001b44 <freeproc>
          release(&np->lock);
    8000254a:	8526                	mv	a0,s1
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	72a080e7          	jalr	1834(ra) # 80000c76 <release>
          release(&wait_lock);
    80002554:	0000f517          	auipc	a0,0xf
    80002558:	d6450513          	addi	a0,a0,-668 # 800112b8 <wait_lock>
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	71a080e7          	jalr	1818(ra) # 80000c76 <release>
          return pid;
    80002564:	a09d                	j	800025ca <wait_stat+0x12c>
            release(&np->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	70e080e7          	jalr	1806(ra) # 80000c76 <release>
            release(&wait_lock);
    80002570:	0000f517          	auipc	a0,0xf
    80002574:	d4850513          	addi	a0,a0,-696 # 800112b8 <wait_lock>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	6fe080e7          	jalr	1790(ra) # 80000c76 <release>
            return -1;
    80002580:	59fd                	li	s3,-1
    80002582:	a0a1                	j	800025ca <wait_stat+0x12c>
    for (np = proc; np < &proc[NPROC]; np++)
    80002584:	18048493          	addi	s1,s1,384
    80002588:	03348463          	beq	s1,s3,800025b0 <wait_stat+0x112>
      if (np->parent == p)
    8000258c:	7c9c                	ld	a5,56(s1)
    8000258e:	ff279be3          	bne	a5,s2,80002584 <wait_stat+0xe6>
        acquire(&np->lock);
    80002592:	8526                	mv	a0,s1
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	62e080e7          	jalr	1582(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    8000259c:	4c9c                	lw	a5,24(s1)
    8000259e:	f5478de3          	beq	a5,s4,800024f8 <wait_stat+0x5a>
        release(&np->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6d2080e7          	jalr	1746(ra) # 80000c76 <release>
        havekids = 1;
    800025ac:	8756                	mv	a4,s5
    800025ae:	bfd9                	j	80002584 <wait_stat+0xe6>
    if (!havekids || p->killed)
    800025b0:	c701                	beqz	a4,800025b8 <wait_stat+0x11a>
    800025b2:	02892783          	lw	a5,40(s2)
    800025b6:	cb85                	beqz	a5,800025e6 <wait_stat+0x148>
      release(&wait_lock);
    800025b8:	0000f517          	auipc	a0,0xf
    800025bc:	d0050513          	addi	a0,a0,-768 # 800112b8 <wait_lock>
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	6b6080e7          	jalr	1718(ra) # 80000c76 <release>
      return -1;
    800025c8:	59fd                	li	s3,-1
  }
}
    800025ca:	854e                	mv	a0,s3
    800025cc:	60e6                	ld	ra,88(sp)
    800025ce:	6446                	ld	s0,80(sp)
    800025d0:	64a6                	ld	s1,72(sp)
    800025d2:	6906                	ld	s2,64(sp)
    800025d4:	79e2                	ld	s3,56(sp)
    800025d6:	7a42                	ld	s4,48(sp)
    800025d8:	7aa2                	ld	s5,40(sp)
    800025da:	7b02                	ld	s6,32(sp)
    800025dc:	6be2                	ld	s7,24(sp)
    800025de:	6c42                	ld	s8,16(sp)
    800025e0:	6ca2                	ld	s9,8(sp)
    800025e2:	6125                	addi	sp,sp,96
    800025e4:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800025e6:	85e6                	mv	a1,s9
    800025e8:	854a                	mv	a0,s2
    800025ea:	00000097          	auipc	ra,0x0
    800025ee:	ae4080e7          	jalr	-1308(ra) # 800020ce <sleep>
    havekids = 0;
    800025f2:	bded                	j	800024ec <wait_stat+0x4e>

00000000800025f4 <trace>:
int trace(int mask, int pid)
{
    800025f4:	7179                	addi	sp,sp,-48
    800025f6:	f406                	sd	ra,40(sp)
    800025f8:	f022                	sd	s0,32(sp)
    800025fa:	ec26                	sd	s1,24(sp)
    800025fc:	e84a                	sd	s2,16(sp)
    800025fe:	e44e                	sd	s3,8(sp)
    80002600:	e052                	sd	s4,0(sp)
    80002602:	1800                	addi	s0,sp,48
    80002604:	8a2a                	mv	s4,a0
    80002606:	892e                	mv	s2,a1
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002608:	0000f497          	auipc	s1,0xf
    8000260c:	0c848493          	addi	s1,s1,200 # 800116d0 <proc>
    80002610:	00015997          	auipc	s3,0x15
    80002614:	0c098993          	addi	s3,s3,192 # 800176d0 <tickslock>
  {
    acquire(&p->lock);
    80002618:	8526                	mv	a0,s1
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	5a8080e7          	jalr	1448(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    80002622:	589c                	lw	a5,48(s1)
    80002624:	01278d63          	beq	a5,s2,8000263e <trace+0x4a>
    {
      p->traceMask = mask;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002628:	8526                	mv	a0,s1
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	64c080e7          	jalr	1612(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002632:	18048493          	addi	s1,s1,384
    80002636:	ff3491e3          	bne	s1,s3,80002618 <trace+0x24>
  }
  return -1;
    8000263a:	557d                	li	a0,-1
    8000263c:	a809                	j	8000264e <trace+0x5a>
      p->traceMask = mask;
    8000263e:	0344aa23          	sw	s4,52(s1)
      release(&p->lock);
    80002642:	8526                	mv	a0,s1
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	632080e7          	jalr	1586(ra) # 80000c76 <release>
      return 0;
    8000264c:	4501                	li	a0,0
}
    8000264e:	70a2                	ld	ra,40(sp)
    80002650:	7402                	ld	s0,32(sp)
    80002652:	64e2                	ld	s1,24(sp)
    80002654:	6942                	ld	s2,16(sp)
    80002656:	69a2                	ld	s3,8(sp)
    80002658:	6a02                	ld	s4,0(sp)
    8000265a:	6145                	addi	sp,sp,48
    8000265c:	8082                	ret

000000008000265e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000265e:	7179                	addi	sp,sp,-48
    80002660:	f406                	sd	ra,40(sp)
    80002662:	f022                	sd	s0,32(sp)
    80002664:	ec26                	sd	s1,24(sp)
    80002666:	e84a                	sd	s2,16(sp)
    80002668:	e44e                	sd	s3,8(sp)
    8000266a:	e052                	sd	s4,0(sp)
    8000266c:	1800                	addi	s0,sp,48
    8000266e:	84aa                	mv	s1,a0
    80002670:	892e                	mv	s2,a1
    80002672:	89b2                	mv	s3,a2
    80002674:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002676:	fffff097          	auipc	ra,0xfffff
    8000267a:	31c080e7          	jalr	796(ra) # 80001992 <myproc>
  if (user_dst)
    8000267e:	c08d                	beqz	s1,800026a0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002680:	86d2                	mv	a3,s4
    80002682:	864e                	mv	a2,s3
    80002684:	85ca                	mv	a1,s2
    80002686:	6928                	ld	a0,80(a0)
    80002688:	fffff097          	auipc	ra,0xfffff
    8000268c:	fb6080e7          	jalr	-74(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002690:	70a2                	ld	ra,40(sp)
    80002692:	7402                	ld	s0,32(sp)
    80002694:	64e2                	ld	s1,24(sp)
    80002696:	6942                	ld	s2,16(sp)
    80002698:	69a2                	ld	s3,8(sp)
    8000269a:	6a02                	ld	s4,0(sp)
    8000269c:	6145                	addi	sp,sp,48
    8000269e:	8082                	ret
    memmove((char *)dst, src, len);
    800026a0:	000a061b          	sext.w	a2,s4
    800026a4:	85ce                	mv	a1,s3
    800026a6:	854a                	mv	a0,s2
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	672080e7          	jalr	1650(ra) # 80000d1a <memmove>
    return 0;
    800026b0:	8526                	mv	a0,s1
    800026b2:	bff9                	j	80002690 <either_copyout+0x32>

00000000800026b4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026b4:	7179                	addi	sp,sp,-48
    800026b6:	f406                	sd	ra,40(sp)
    800026b8:	f022                	sd	s0,32(sp)
    800026ba:	ec26                	sd	s1,24(sp)
    800026bc:	e84a                	sd	s2,16(sp)
    800026be:	e44e                	sd	s3,8(sp)
    800026c0:	e052                	sd	s4,0(sp)
    800026c2:	1800                	addi	s0,sp,48
    800026c4:	892a                	mv	s2,a0
    800026c6:	84ae                	mv	s1,a1
    800026c8:	89b2                	mv	s3,a2
    800026ca:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026cc:	fffff097          	auipc	ra,0xfffff
    800026d0:	2c6080e7          	jalr	710(ra) # 80001992 <myproc>
  if (user_src)
    800026d4:	c08d                	beqz	s1,800026f6 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026d6:	86d2                	mv	a3,s4
    800026d8:	864e                	mv	a2,s3
    800026da:	85ca                	mv	a1,s2
    800026dc:	6928                	ld	a0,80(a0)
    800026de:	fffff097          	auipc	ra,0xfffff
    800026e2:	fec080e7          	jalr	-20(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026e6:	70a2                	ld	ra,40(sp)
    800026e8:	7402                	ld	s0,32(sp)
    800026ea:	64e2                	ld	s1,24(sp)
    800026ec:	6942                	ld	s2,16(sp)
    800026ee:	69a2                	ld	s3,8(sp)
    800026f0:	6a02                	ld	s4,0(sp)
    800026f2:	6145                	addi	sp,sp,48
    800026f4:	8082                	ret
    memmove(dst, (char *)src, len);
    800026f6:	000a061b          	sext.w	a2,s4
    800026fa:	85ce                	mv	a1,s3
    800026fc:	854a                	mv	a0,s2
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	61c080e7          	jalr	1564(ra) # 80000d1a <memmove>
    return 0;
    80002706:	8526                	mv	a0,s1
    80002708:	bff9                	j	800026e6 <either_copyin+0x32>

000000008000270a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000270a:	715d                	addi	sp,sp,-80
    8000270c:	e486                	sd	ra,72(sp)
    8000270e:	e0a2                	sd	s0,64(sp)
    80002710:	fc26                	sd	s1,56(sp)
    80002712:	f84a                	sd	s2,48(sp)
    80002714:	f44e                	sd	s3,40(sp)
    80002716:	f052                	sd	s4,32(sp)
    80002718:	ec56                	sd	s5,24(sp)
    8000271a:	e85a                	sd	s6,16(sp)
    8000271c:	e45e                	sd	s7,8(sp)
    8000271e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002720:	00006517          	auipc	a0,0x6
    80002724:	9a850513          	addi	a0,a0,-1624 # 800080c8 <digits+0x88>
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	e4c080e7          	jalr	-436(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002730:	0000f497          	auipc	s1,0xf
    80002734:	0f848493          	addi	s1,s1,248 # 80011828 <proc+0x158>
    80002738:	00015917          	auipc	s2,0x15
    8000273c:	0f090913          	addi	s2,s2,240 # 80017828 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002740:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002742:	00006997          	auipc	s3,0x6
    80002746:	b2698993          	addi	s3,s3,-1242 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000274a:	00006a97          	auipc	s5,0x6
    8000274e:	b26a8a93          	addi	s5,s5,-1242 # 80008270 <digits+0x230>
    printf("\n");
    80002752:	00006a17          	auipc	s4,0x6
    80002756:	976a0a13          	addi	s4,s4,-1674 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000275a:	00006b97          	auipc	s7,0x6
    8000275e:	b4eb8b93          	addi	s7,s7,-1202 # 800082a8 <states.0>
    80002762:	a00d                	j	80002784 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002764:	ed86a583          	lw	a1,-296(a3)
    80002768:	8556                	mv	a0,s5
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	e0a080e7          	jalr	-502(ra) # 80000574 <printf>
    printf("\n");
    80002772:	8552                	mv	a0,s4
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	e00080e7          	jalr	-512(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000277c:	18048493          	addi	s1,s1,384
    80002780:	03248263          	beq	s1,s2,800027a4 <procdump+0x9a>
    if (p->state == UNUSED)
    80002784:	86a6                	mv	a3,s1
    80002786:	ec04a783          	lw	a5,-320(s1)
    8000278a:	dbed                	beqz	a5,8000277c <procdump+0x72>
      state = "???";
    8000278c:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278e:	fcfb6be3          	bltu	s6,a5,80002764 <procdump+0x5a>
    80002792:	02079713          	slli	a4,a5,0x20
    80002796:	01d75793          	srli	a5,a4,0x1d
    8000279a:	97de                	add	a5,a5,s7
    8000279c:	6390                	ld	a2,0(a5)
    8000279e:	f279                	bnez	a2,80002764 <procdump+0x5a>
      state = "???";
    800027a0:	864e                	mv	a2,s3
    800027a2:	b7c9                	j	80002764 <procdump+0x5a>
  }
}
    800027a4:	60a6                	ld	ra,72(sp)
    800027a6:	6406                	ld	s0,64(sp)
    800027a8:	74e2                	ld	s1,56(sp)
    800027aa:	7942                	ld	s2,48(sp)
    800027ac:	79a2                	ld	s3,40(sp)
    800027ae:	7a02                	ld	s4,32(sp)
    800027b0:	6ae2                	ld	s5,24(sp)
    800027b2:	6b42                	ld	s6,16(sp)
    800027b4:	6ba2                	ld	s7,8(sp)
    800027b6:	6161                	addi	sp,sp,80
    800027b8:	8082                	ret

00000000800027ba <swtch>:
    800027ba:	00153023          	sd	ra,0(a0)
    800027be:	00253423          	sd	sp,8(a0)
    800027c2:	e900                	sd	s0,16(a0)
    800027c4:	ed04                	sd	s1,24(a0)
    800027c6:	03253023          	sd	s2,32(a0)
    800027ca:	03353423          	sd	s3,40(a0)
    800027ce:	03453823          	sd	s4,48(a0)
    800027d2:	03553c23          	sd	s5,56(a0)
    800027d6:	05653023          	sd	s6,64(a0)
    800027da:	05753423          	sd	s7,72(a0)
    800027de:	05853823          	sd	s8,80(a0)
    800027e2:	05953c23          	sd	s9,88(a0)
    800027e6:	07a53023          	sd	s10,96(a0)
    800027ea:	07b53423          	sd	s11,104(a0)
    800027ee:	0005b083          	ld	ra,0(a1)
    800027f2:	0085b103          	ld	sp,8(a1)
    800027f6:	6980                	ld	s0,16(a1)
    800027f8:	6d84                	ld	s1,24(a1)
    800027fa:	0205b903          	ld	s2,32(a1)
    800027fe:	0285b983          	ld	s3,40(a1)
    80002802:	0305ba03          	ld	s4,48(a1)
    80002806:	0385ba83          	ld	s5,56(a1)
    8000280a:	0405bb03          	ld	s6,64(a1)
    8000280e:	0485bb83          	ld	s7,72(a1)
    80002812:	0505bc03          	ld	s8,80(a1)
    80002816:	0585bc83          	ld	s9,88(a1)
    8000281a:	0605bd03          	ld	s10,96(a1)
    8000281e:	0685bd83          	ld	s11,104(a1)
    80002822:	8082                	ret

0000000080002824 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002824:	1141                	addi	sp,sp,-16
    80002826:	e406                	sd	ra,8(sp)
    80002828:	e022                	sd	s0,0(sp)
    8000282a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000282c:	00006597          	auipc	a1,0x6
    80002830:	aac58593          	addi	a1,a1,-1364 # 800082d8 <states.0+0x30>
    80002834:	00015517          	auipc	a0,0x15
    80002838:	e9c50513          	addi	a0,a0,-356 # 800176d0 <tickslock>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	2f6080e7          	jalr	758(ra) # 80000b32 <initlock>
}
    80002844:	60a2                	ld	ra,8(sp)
    80002846:	6402                	ld	s0,0(sp)
    80002848:	0141                	addi	sp,sp,16
    8000284a:	8082                	ret

000000008000284c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000284c:	1141                	addi	sp,sp,-16
    8000284e:	e422                	sd	s0,8(sp)
    80002850:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002852:	00003797          	auipc	a5,0x3
    80002856:	64e78793          	addi	a5,a5,1614 # 80005ea0 <kernelvec>
    8000285a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000285e:	6422                	ld	s0,8(sp)
    80002860:	0141                	addi	sp,sp,16
    80002862:	8082                	ret

0000000080002864 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002864:	1141                	addi	sp,sp,-16
    80002866:	e406                	sd	ra,8(sp)
    80002868:	e022                	sd	s0,0(sp)
    8000286a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	126080e7          	jalr	294(ra) # 80001992 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002874:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002878:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000287a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000287e:	00004617          	auipc	a2,0x4
    80002882:	78260613          	addi	a2,a2,1922 # 80007000 <_trampoline>
    80002886:	00004697          	auipc	a3,0x4
    8000288a:	77a68693          	addi	a3,a3,1914 # 80007000 <_trampoline>
    8000288e:	8e91                	sub	a3,a3,a2
    80002890:	040007b7          	lui	a5,0x4000
    80002894:	17fd                	addi	a5,a5,-1
    80002896:	07b2                	slli	a5,a5,0xc
    80002898:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000289a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000289e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028a0:	180026f3          	csrr	a3,satp
    800028a4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028a6:	6d38                	ld	a4,88(a0)
    800028a8:	6134                	ld	a3,64(a0)
    800028aa:	6585                	lui	a1,0x1
    800028ac:	96ae                	add	a3,a3,a1
    800028ae:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028b0:	6d38                	ld	a4,88(a0)
    800028b2:	00000697          	auipc	a3,0x0
    800028b6:	1be68693          	addi	a3,a3,446 # 80002a70 <usertrap>
    800028ba:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028bc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028be:	8692                	mv	a3,tp
    800028c0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028c6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028ca:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ce:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028d2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028d4:	6f18                	ld	a4,24(a4)
    800028d6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028da:	692c                	ld	a1,80(a0)
    800028dc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028de:	00004717          	auipc	a4,0x4
    800028e2:	7b270713          	addi	a4,a4,1970 # 80007090 <userret>
    800028e6:	8f11                	sub	a4,a4,a2
    800028e8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028ea:	577d                	li	a4,-1
    800028ec:	177e                	slli	a4,a4,0x3f
    800028ee:	8dd9                	or	a1,a1,a4
    800028f0:	02000537          	lui	a0,0x2000
    800028f4:	157d                	addi	a0,a0,-1
    800028f6:	0536                	slli	a0,a0,0xd
    800028f8:	9782                	jalr	a5
}
    800028fa:	60a2                	ld	ra,8(sp)
    800028fc:	6402                	ld	s0,0(sp)
    800028fe:	0141                	addi	sp,sp,16
    80002900:	8082                	ret

0000000080002902 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002902:	7139                	addi	sp,sp,-64
    80002904:	fc06                	sd	ra,56(sp)
    80002906:	f822                	sd	s0,48(sp)
    80002908:	f426                	sd	s1,40(sp)
    8000290a:	f04a                	sd	s2,32(sp)
    8000290c:	ec4e                	sd	s3,24(sp)
    8000290e:	e852                	sd	s4,16(sp)
    80002910:	e456                	sd	s5,8(sp)
    80002912:	0080                	addi	s0,sp,64
  acquire(&tickslock);
    80002914:	00015517          	auipc	a0,0x15
    80002918:	dbc50513          	addi	a0,a0,-580 # 800176d0 <tickslock>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	2a6080e7          	jalr	678(ra) # 80000bc2 <acquire>
  ticks++;
    80002924:	00006717          	auipc	a4,0x6
    80002928:	70c70713          	addi	a4,a4,1804 # 80009030 <ticks>
    8000292c:	431c                	lw	a5,0(a4)
    8000292e:	2785                	addiw	a5,a5,1
    80002930:	c31c                	sw	a5,0(a4)
  //start add UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE
  struct proc *p;
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	eda080e7          	jalr	-294(ra) # 8000180c <getProc>
    8000293a:	84aa                	mv	s1,a0
    8000293c:	6919                	lui	s2,0x6
    acquire(&p->lock);

    enum procstate state = p->state;
    switch (state)
    8000293e:	4a8d                	li	s5,3
    80002940:	4a11                	li	s4,4
    80002942:	4989                	li	s3,2
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    80002944:	a829                	j	8000295e <clockintr+0x5c>
        break;
      case SLEEPING:
        p->stime += 1;
        break;
      case RUNNABLE:
        p->retime += 1;
    80002946:	1744a783          	lw	a5,372(s1)
    8000294a:	2785                	addiw	a5,a5,1
    8000294c:	16f4aa23          	sw	a5,372(s1)
      case ZOMBIE:   
        break; 
      default:
        break;
    }
    release(&p->lock);
    80002950:	8526                	mv	a0,s1
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	324080e7          	jalr	804(ra) # 80000c76 <release>
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    8000295a:	18048493          	addi	s1,s1,384
    8000295e:	fffff097          	auipc	ra,0xfffff
    80002962:	eae080e7          	jalr	-338(ra) # 8000180c <getProc>
    80002966:	954a                	add	a0,a0,s2
    80002968:	02a4fa63          	bgeu	s1,a0,8000299c <clockintr+0x9a>
    acquire(&p->lock);
    8000296c:	8526                	mv	a0,s1
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	254080e7          	jalr	596(ra) # 80000bc2 <acquire>
    enum procstate state = p->state;
    80002976:	4c9c                	lw	a5,24(s1)
    switch (state)
    80002978:	fd5787e3          	beq	a5,s5,80002946 <clockintr+0x44>
    8000297c:	01478a63          	beq	a5,s4,80002990 <clockintr+0x8e>
    80002980:	fd3798e3          	bne	a5,s3,80002950 <clockintr+0x4e>
        p->stime += 1;
    80002984:	1704a783          	lw	a5,368(s1)
    80002988:	2785                	addiw	a5,a5,1
    8000298a:	16f4a823          	sw	a5,368(s1)
        break;
    8000298e:	b7c9                	j	80002950 <clockintr+0x4e>
        p->runtime += 1;
    80002990:	1784a783          	lw	a5,376(s1)
    80002994:	2785                	addiw	a5,a5,1
    80002996:	16f4ac23          	sw	a5,376(s1)
        break;
    8000299a:	bf5d                	j	80002950 <clockintr+0x4e>
  }
  // end add
  wakeup(&ticks);
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	69450513          	addi	a0,a0,1684 # 80009030 <ticks>
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	8b6080e7          	jalr	-1866(ra) # 8000225a <wakeup>
  release(&tickslock);
    800029ac:	00015517          	auipc	a0,0x15
    800029b0:	d2450513          	addi	a0,a0,-732 # 800176d0 <tickslock>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	2c2080e7          	jalr	706(ra) # 80000c76 <release>
}
    800029bc:	70e2                	ld	ra,56(sp)
    800029be:	7442                	ld	s0,48(sp)
    800029c0:	74a2                	ld	s1,40(sp)
    800029c2:	7902                	ld	s2,32(sp)
    800029c4:	69e2                	ld	s3,24(sp)
    800029c6:	6a42                	ld	s4,16(sp)
    800029c8:	6aa2                	ld	s5,8(sp)
    800029ca:	6121                	addi	sp,sp,64
    800029cc:	8082                	ret

00000000800029ce <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029ce:	1101                	addi	sp,sp,-32
    800029d0:	ec06                	sd	ra,24(sp)
    800029d2:	e822                	sd	s0,16(sp)
    800029d4:	e426                	sd	s1,8(sp)
    800029d6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029dc:	00074d63          	bltz	a4,800029f6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029e0:	57fd                	li	a5,-1
    800029e2:	17fe                	slli	a5,a5,0x3f
    800029e4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029e6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029e8:	06f70363          	beq	a4,a5,80002a4e <devintr+0x80>
  }
}
    800029ec:	60e2                	ld	ra,24(sp)
    800029ee:	6442                	ld	s0,16(sp)
    800029f0:	64a2                	ld	s1,8(sp)
    800029f2:	6105                	addi	sp,sp,32
    800029f4:	8082                	ret
     (scause & 0xff) == 9){
    800029f6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029fa:	46a5                	li	a3,9
    800029fc:	fed792e3          	bne	a5,a3,800029e0 <devintr+0x12>
    int irq = plic_claim();
    80002a00:	00003097          	auipc	ra,0x3
    80002a04:	5a8080e7          	jalr	1448(ra) # 80005fa8 <plic_claim>
    80002a08:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a0a:	47a9                	li	a5,10
    80002a0c:	02f50763          	beq	a0,a5,80002a3a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a10:	4785                	li	a5,1
    80002a12:	02f50963          	beq	a0,a5,80002a44 <devintr+0x76>
    return 1;
    80002a16:	4505                	li	a0,1
    } else if(irq){
    80002a18:	d8f1                	beqz	s1,800029ec <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a1a:	85a6                	mv	a1,s1
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	8c450513          	addi	a0,a0,-1852 # 800082e0 <states.0+0x38>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b50080e7          	jalr	-1200(ra) # 80000574 <printf>
      plic_complete(irq);
    80002a2c:	8526                	mv	a0,s1
    80002a2e:	00003097          	auipc	ra,0x3
    80002a32:	59e080e7          	jalr	1438(ra) # 80005fcc <plic_complete>
    return 1;
    80002a36:	4505                	li	a0,1
    80002a38:	bf55                	j	800029ec <devintr+0x1e>
      uartintr();
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	f4c080e7          	jalr	-180(ra) # 80000986 <uartintr>
    80002a42:	b7ed                	j	80002a2c <devintr+0x5e>
      virtio_disk_intr();
    80002a44:	00004097          	auipc	ra,0x4
    80002a48:	a1a080e7          	jalr	-1510(ra) # 8000645e <virtio_disk_intr>
    80002a4c:	b7c5                	j	80002a2c <devintr+0x5e>
    if(cpuid() == 0){
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	f18080e7          	jalr	-232(ra) # 80001966 <cpuid>
    80002a56:	c901                	beqz	a0,80002a66 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a58:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a5c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a5e:	14479073          	csrw	sip,a5
    return 2;
    80002a62:	4509                	li	a0,2
    80002a64:	b761                	j	800029ec <devintr+0x1e>
      clockintr();
    80002a66:	00000097          	auipc	ra,0x0
    80002a6a:	e9c080e7          	jalr	-356(ra) # 80002902 <clockintr>
    80002a6e:	b7ed                	j	80002a58 <devintr+0x8a>

0000000080002a70 <usertrap>:
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	e04a                	sd	s2,0(sp)
    80002a7a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a80:	1007f793          	andi	a5,a5,256
    80002a84:	e3ad                	bnez	a5,80002ae6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a86:	00003797          	auipc	a5,0x3
    80002a8a:	41a78793          	addi	a5,a5,1050 # 80005ea0 <kernelvec>
    80002a8e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	f00080e7          	jalr	-256(ra) # 80001992 <myproc>
    80002a9a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a9c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9e:	14102773          	csrr	a4,sepc
    80002aa2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002aa8:	47a1                	li	a5,8
    80002aaa:	04f71c63          	bne	a4,a5,80002b02 <usertrap+0x92>
    if(p->killed)
    80002aae:	551c                	lw	a5,40(a0)
    80002ab0:	e3b9                	bnez	a5,80002af6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ab2:	6cb8                	ld	a4,88(s1)
    80002ab4:	6f1c                	ld	a5,24(a4)
    80002ab6:	0791                	addi	a5,a5,4
    80002ab8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002abe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac2:	10079073          	csrw	sstatus,a5
    syscall();
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	2e0080e7          	jalr	736(ra) # 80002da6 <syscall>
  if(p->killed)
    80002ace:	549c                	lw	a5,40(s1)
    80002ad0:	ebc1                	bnez	a5,80002b60 <usertrap+0xf0>
  usertrapret();
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	d92080e7          	jalr	-622(ra) # 80002864 <usertrapret>
}
    80002ada:	60e2                	ld	ra,24(sp)
    80002adc:	6442                	ld	s0,16(sp)
    80002ade:	64a2                	ld	s1,8(sp)
    80002ae0:	6902                	ld	s2,0(sp)
    80002ae2:	6105                	addi	sp,sp,32
    80002ae4:	8082                	ret
    panic("usertrap: not from user mode");
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	81a50513          	addi	a0,a0,-2022 # 80008300 <states.0+0x58>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a3c080e7          	jalr	-1476(ra) # 8000052a <panic>
      exit(-1);
    80002af6:	557d                	li	a0,-1
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	832080e7          	jalr	-1998(ra) # 8000232a <exit>
    80002b00:	bf4d                	j	80002ab2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b02:	00000097          	auipc	ra,0x0
    80002b06:	ecc080e7          	jalr	-308(ra) # 800029ce <devintr>
    80002b0a:	892a                	mv	s2,a0
    80002b0c:	c501                	beqz	a0,80002b14 <usertrap+0xa4>
  if(p->killed)
    80002b0e:	549c                	lw	a5,40(s1)
    80002b10:	c3a1                	beqz	a5,80002b50 <usertrap+0xe0>
    80002b12:	a815                	j	80002b46 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b14:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b18:	5890                	lw	a2,48(s1)
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	80650513          	addi	a0,a0,-2042 # 80008320 <states.0+0x78>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a52080e7          	jalr	-1454(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b2a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b2e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b32:	00006517          	auipc	a0,0x6
    80002b36:	81e50513          	addi	a0,a0,-2018 # 80008350 <states.0+0xa8>
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	a3a080e7          	jalr	-1478(ra) # 80000574 <printf>
    p->killed = 1;
    80002b42:	4785                	li	a5,1
    80002b44:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b46:	557d                	li	a0,-1
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	7e2080e7          	jalr	2018(ra) # 8000232a <exit>
  if(which_dev == 2)
    80002b50:	4789                	li	a5,2
    80002b52:	f8f910e3          	bne	s2,a5,80002ad2 <usertrap+0x62>
    yield();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	53c080e7          	jalr	1340(ra) # 80002092 <yield>
    80002b5e:	bf95                	j	80002ad2 <usertrap+0x62>
  int which_dev = 0;
    80002b60:	4901                	li	s2,0
    80002b62:	b7d5                	j	80002b46 <usertrap+0xd6>

0000000080002b64 <kerneltrap>:
{
    80002b64:	7179                	addi	sp,sp,-48
    80002b66:	f406                	sd	ra,40(sp)
    80002b68:	f022                	sd	s0,32(sp)
    80002b6a:	ec26                	sd	s1,24(sp)
    80002b6c:	e84a                	sd	s2,16(sp)
    80002b6e:	e44e                	sd	s3,8(sp)
    80002b70:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b72:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b76:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b7a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b7e:	1004f793          	andi	a5,s1,256
    80002b82:	cb85                	beqz	a5,80002bb2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b84:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b88:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b8a:	ef85                	bnez	a5,80002bc2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	e42080e7          	jalr	-446(ra) # 800029ce <devintr>
    80002b94:	cd1d                	beqz	a0,80002bd2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b96:	4789                	li	a5,2
    80002b98:	06f50a63          	beq	a0,a5,80002c0c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b9c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ba0:	10049073          	csrw	sstatus,s1
}
    80002ba4:	70a2                	ld	ra,40(sp)
    80002ba6:	7402                	ld	s0,32(sp)
    80002ba8:	64e2                	ld	s1,24(sp)
    80002baa:	6942                	ld	s2,16(sp)
    80002bac:	69a2                	ld	s3,8(sp)
    80002bae:	6145                	addi	sp,sp,48
    80002bb0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bb2:	00005517          	auipc	a0,0x5
    80002bb6:	7be50513          	addi	a0,a0,1982 # 80008370 <states.0+0xc8>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	970080e7          	jalr	-1680(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002bc2:	00005517          	auipc	a0,0x5
    80002bc6:	7d650513          	addi	a0,a0,2006 # 80008398 <states.0+0xf0>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	960080e7          	jalr	-1696(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002bd2:	85ce                	mv	a1,s3
    80002bd4:	00005517          	auipc	a0,0x5
    80002bd8:	7e450513          	addi	a0,a0,2020 # 800083b8 <states.0+0x110>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	998080e7          	jalr	-1640(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002be8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bec:	00005517          	auipc	a0,0x5
    80002bf0:	7dc50513          	addi	a0,a0,2012 # 800083c8 <states.0+0x120>
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	980080e7          	jalr	-1664(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002bfc:	00005517          	auipc	a0,0x5
    80002c00:	7e450513          	addi	a0,a0,2020 # 800083e0 <states.0+0x138>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	926080e7          	jalr	-1754(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	d86080e7          	jalr	-634(ra) # 80001992 <myproc>
    80002c14:	d541                	beqz	a0,80002b9c <kerneltrap+0x38>
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	d7c080e7          	jalr	-644(ra) # 80001992 <myproc>
    80002c1e:	4d18                	lw	a4,24(a0)
    80002c20:	4791                	li	a5,4
    80002c22:	f6f71de3          	bne	a4,a5,80002b9c <kerneltrap+0x38>
    yield();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	46c080e7          	jalr	1132(ra) # 80002092 <yield>
    80002c2e:	b7bd                	j	80002b9c <kerneltrap+0x38>

0000000080002c30 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c30:	1101                	addi	sp,sp,-32
    80002c32:	ec06                	sd	ra,24(sp)
    80002c34:	e822                	sd	s0,16(sp)
    80002c36:	e426                	sd	s1,8(sp)
    80002c38:	1000                	addi	s0,sp,32
    80002c3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c3c:	fffff097          	auipc	ra,0xfffff
    80002c40:	d56080e7          	jalr	-682(ra) # 80001992 <myproc>
  switch (n)
    80002c44:	4795                	li	a5,5
    80002c46:	0497e163          	bltu	a5,s1,80002c88 <argraw+0x58>
    80002c4a:	048a                	slli	s1,s1,0x2
    80002c4c:	00006717          	auipc	a4,0x6
    80002c50:	95c70713          	addi	a4,a4,-1700 # 800085a8 <states.0+0x300>
    80002c54:	94ba                	add	s1,s1,a4
    80002c56:	409c                	lw	a5,0(s1)
    80002c58:	97ba                	add	a5,a5,a4
    80002c5a:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002c5c:	6d3c                	ld	a5,88(a0)
    80002c5e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c60:	60e2                	ld	ra,24(sp)
    80002c62:	6442                	ld	s0,16(sp)
    80002c64:	64a2                	ld	s1,8(sp)
    80002c66:	6105                	addi	sp,sp,32
    80002c68:	8082                	ret
    return p->trapframe->a1;
    80002c6a:	6d3c                	ld	a5,88(a0)
    80002c6c:	7fa8                	ld	a0,120(a5)
    80002c6e:	bfcd                	j	80002c60 <argraw+0x30>
    return p->trapframe->a2;
    80002c70:	6d3c                	ld	a5,88(a0)
    80002c72:	63c8                	ld	a0,128(a5)
    80002c74:	b7f5                	j	80002c60 <argraw+0x30>
    return p->trapframe->a3;
    80002c76:	6d3c                	ld	a5,88(a0)
    80002c78:	67c8                	ld	a0,136(a5)
    80002c7a:	b7dd                	j	80002c60 <argraw+0x30>
    return p->trapframe->a4;
    80002c7c:	6d3c                	ld	a5,88(a0)
    80002c7e:	6bc8                	ld	a0,144(a5)
    80002c80:	b7c5                	j	80002c60 <argraw+0x30>
    return p->trapframe->a5;
    80002c82:	6d3c                	ld	a5,88(a0)
    80002c84:	6fc8                	ld	a0,152(a5)
    80002c86:	bfe9                	j	80002c60 <argraw+0x30>
  panic("argraw");
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	76850513          	addi	a0,a0,1896 # 800083f0 <states.0+0x148>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	89a080e7          	jalr	-1894(ra) # 8000052a <panic>

0000000080002c98 <fetchaddr>:
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	e426                	sd	s1,8(sp)
    80002ca0:	e04a                	sd	s2,0(sp)
    80002ca2:	1000                	addi	s0,sp,32
    80002ca4:	84aa                	mv	s1,a0
    80002ca6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	cea080e7          	jalr	-790(ra) # 80001992 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002cb0:	653c                	ld	a5,72(a0)
    80002cb2:	02f4f863          	bgeu	s1,a5,80002ce2 <fetchaddr+0x4a>
    80002cb6:	00848713          	addi	a4,s1,8
    80002cba:	02e7e663          	bltu	a5,a4,80002ce6 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cbe:	46a1                	li	a3,8
    80002cc0:	8626                	mv	a2,s1
    80002cc2:	85ca                	mv	a1,s2
    80002cc4:	6928                	ld	a0,80(a0)
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	a04080e7          	jalr	-1532(ra) # 800016ca <copyin>
    80002cce:	00a03533          	snez	a0,a0
    80002cd2:	40a00533          	neg	a0,a0
}
    80002cd6:	60e2                	ld	ra,24(sp)
    80002cd8:	6442                	ld	s0,16(sp)
    80002cda:	64a2                	ld	s1,8(sp)
    80002cdc:	6902                	ld	s2,0(sp)
    80002cde:	6105                	addi	sp,sp,32
    80002ce0:	8082                	ret
    return -1;
    80002ce2:	557d                	li	a0,-1
    80002ce4:	bfcd                	j	80002cd6 <fetchaddr+0x3e>
    80002ce6:	557d                	li	a0,-1
    80002ce8:	b7fd                	j	80002cd6 <fetchaddr+0x3e>

0000000080002cea <fetchstr>:
{
    80002cea:	7179                	addi	sp,sp,-48
    80002cec:	f406                	sd	ra,40(sp)
    80002cee:	f022                	sd	s0,32(sp)
    80002cf0:	ec26                	sd	s1,24(sp)
    80002cf2:	e84a                	sd	s2,16(sp)
    80002cf4:	e44e                	sd	s3,8(sp)
    80002cf6:	1800                	addi	s0,sp,48
    80002cf8:	892a                	mv	s2,a0
    80002cfa:	84ae                	mv	s1,a1
    80002cfc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	c94080e7          	jalr	-876(ra) # 80001992 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d06:	86ce                	mv	a3,s3
    80002d08:	864a                	mv	a2,s2
    80002d0a:	85a6                	mv	a1,s1
    80002d0c:	6928                	ld	a0,80(a0)
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	a4a080e7          	jalr	-1462(ra) # 80001758 <copyinstr>
  if (err < 0)
    80002d16:	00054763          	bltz	a0,80002d24 <fetchstr+0x3a>
  return strlen(buf);
    80002d1a:	8526                	mv	a0,s1
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	126080e7          	jalr	294(ra) # 80000e42 <strlen>
}
    80002d24:	70a2                	ld	ra,40(sp)
    80002d26:	7402                	ld	s0,32(sp)
    80002d28:	64e2                	ld	s1,24(sp)
    80002d2a:	6942                	ld	s2,16(sp)
    80002d2c:	69a2                	ld	s3,8(sp)
    80002d2e:	6145                	addi	sp,sp,48
    80002d30:	8082                	ret

0000000080002d32 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	e426                	sd	s1,8(sp)
    80002d3a:	1000                	addi	s0,sp,32
    80002d3c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	ef2080e7          	jalr	-270(ra) # 80002c30 <argraw>
    80002d46:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d48:	4501                	li	a0,0
    80002d4a:	60e2                	ld	ra,24(sp)
    80002d4c:	6442                	ld	s0,16(sp)
    80002d4e:	64a2                	ld	s1,8(sp)
    80002d50:	6105                	addi	sp,sp,32
    80002d52:	8082                	ret

0000000080002d54 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002d54:	1101                	addi	sp,sp,-32
    80002d56:	ec06                	sd	ra,24(sp)
    80002d58:	e822                	sd	s0,16(sp)
    80002d5a:	e426                	sd	s1,8(sp)
    80002d5c:	1000                	addi	s0,sp,32
    80002d5e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	ed0080e7          	jalr	-304(ra) # 80002c30 <argraw>
    80002d68:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d6a:	4501                	li	a0,0
    80002d6c:	60e2                	ld	ra,24(sp)
    80002d6e:	6442                	ld	s0,16(sp)
    80002d70:	64a2                	ld	s1,8(sp)
    80002d72:	6105                	addi	sp,sp,32
    80002d74:	8082                	ret

0000000080002d76 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	e426                	sd	s1,8(sp)
    80002d7e:	e04a                	sd	s2,0(sp)
    80002d80:	1000                	addi	s0,sp,32
    80002d82:	84ae                	mv	s1,a1
    80002d84:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	eaa080e7          	jalr	-342(ra) # 80002c30 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d8e:	864a                	mv	a2,s2
    80002d90:	85a6                	mv	a1,s1
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	f58080e7          	jalr	-168(ra) # 80002cea <fetchstr>
}
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	64a2                	ld	s1,8(sp)
    80002da0:	6902                	ld	s2,0(sp)
    80002da2:	6105                	addi	sp,sp,32
    80002da4:	8082                	ret

0000000080002da6 <syscall>:
    [SYS_close] "sys_close",
    [SYS_trace] "sys_trace",
    [SYS_wait_stat] "sys_wait_stat",
};
void syscall(void)
{
    80002da6:	7139                	addi	sp,sp,-64
    80002da8:	fc06                	sd	ra,56(sp)
    80002daa:	f822                	sd	s0,48(sp)
    80002dac:	f426                	sd	s1,40(sp)
    80002dae:	f04a                	sd	s2,32(sp)
    80002db0:	ec4e                	sd	s3,24(sp)
    80002db2:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	bde080e7          	jalr	-1058(ra) # 80001992 <myproc>
    80002dbc:	84aa                	mv	s1,a0
  int firstArg;
  num = p->trapframe->a7;
    80002dbe:	05853903          	ld	s2,88(a0)
    80002dc2:	0a893783          	ld	a5,168(s2) # 60a8 <_entry-0x7fff9f58>
    80002dc6:	0007899b          	sext.w	s3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002dca:	37fd                	addiw	a5,a5,-1
    80002dcc:	4759                	li	a4,22
    80002dce:	0cf76563          	bltu	a4,a5,80002e98 <syscall+0xf2>
    80002dd2:	00399713          	slli	a4,s3,0x3
    80002dd6:	00005797          	auipc	a5,0x5
    80002dda:	7ea78793          	addi	a5,a5,2026 # 800085c0 <syscalls>
    80002dde:	97ba                	add	a5,a5,a4
    80002de0:	639c                	ld	a5,0(a5)
    80002de2:	cbdd                	beqz	a5,80002e98 <syscall+0xf2>
  {
    p->trapframe->a0 = syscalls[num]();
    80002de4:	9782                	jalr	a5
    80002de6:	06a93823          	sd	a0,112(s2)
    //start messing with code
    if ((p->traceMask & (1 << num)))
    80002dea:	58dc                	lw	a5,52(s1)
    80002dec:	4137d7bb          	sraw	a5,a5,s3
    80002df0:	8b85                	andi	a5,a5,1
    80002df2:	c3f1                	beqz	a5,80002eb6 <syscall+0x110>
    {
      printf("%d: syscall %s ", p->pid, syscalls_str[num]);
    80002df4:	00399713          	slli	a4,s3,0x3
    80002df8:	00005797          	auipc	a5,0x5
    80002dfc:	7c878793          	addi	a5,a5,1992 # 800085c0 <syscalls>
    80002e00:	97ba                	add	a5,a5,a4
    80002e02:	63f0                	ld	a2,192(a5)
    80002e04:	588c                	lw	a1,48(s1)
    80002e06:	00005517          	auipc	a0,0x5
    80002e0a:	5f250513          	addi	a0,a0,1522 # 800083f8 <states.0+0x150>
    80002e0e:	ffffd097          	auipc	ra,0xffffd
    80002e12:	766080e7          	jalr	1894(ra) # 80000574 <printf>
      if (num == SYS_fork)
    80002e16:	4785                	li	a5,1
    80002e18:	02f98363          	beq	s3,a5,80002e3e <syscall+0x98>
      {
        printf("NULL ");
      }
      if (num == SYS_kill)
    80002e1c:	4799                	li	a5,6
    80002e1e:	02f98963          	beq	s3,a5,80002e50 <syscall+0xaa>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      if (num == SYS_sbrk)
    80002e22:	47b1                	li	a5,12
    80002e24:	04f98863          	beq	s3,a5,80002e74 <syscall+0xce>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      printf("-> %d\n", p->trapframe->a0);
    80002e28:	6cbc                	ld	a5,88(s1)
    80002e2a:	7bac                	ld	a1,112(a5)
    80002e2c:	00005517          	auipc	a0,0x5
    80002e30:	5ec50513          	addi	a0,a0,1516 # 80008418 <states.0+0x170>
    80002e34:	ffffd097          	auipc	ra,0xffffd
    80002e38:	740080e7          	jalr	1856(ra) # 80000574 <printf>
    80002e3c:	a8ad                	j	80002eb6 <syscall+0x110>
        printf("NULL ");
    80002e3e:	00005517          	auipc	a0,0x5
    80002e42:	5ca50513          	addi	a0,a0,1482 # 80008408 <states.0+0x160>
    80002e46:	ffffd097          	auipc	ra,0xffffd
    80002e4a:	72e080e7          	jalr	1838(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002e4e:	bfe9                	j	80002e28 <syscall+0x82>
        argint(0, &firstArg);
    80002e50:	fcc40593          	addi	a1,s0,-52
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	edc080e7          	jalr	-292(ra) # 80002d32 <argint>
        printf("%d ", firstArg);
    80002e5e:	fcc42583          	lw	a1,-52(s0)
    80002e62:	00005517          	auipc	a0,0x5
    80002e66:	5ae50513          	addi	a0,a0,1454 # 80008410 <states.0+0x168>
    80002e6a:	ffffd097          	auipc	ra,0xffffd
    80002e6e:	70a080e7          	jalr	1802(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002e72:	bf5d                	j	80002e28 <syscall+0x82>
        argint(0, &firstArg);
    80002e74:	fcc40593          	addi	a1,s0,-52
    80002e78:	4501                	li	a0,0
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	eb8080e7          	jalr	-328(ra) # 80002d32 <argint>
        printf("%d ", firstArg);
    80002e82:	fcc42583          	lw	a1,-52(s0)
    80002e86:	00005517          	auipc	a0,0x5
    80002e8a:	58a50513          	addi	a0,a0,1418 # 80008410 <states.0+0x168>
    80002e8e:	ffffd097          	auipc	ra,0xffffd
    80002e92:	6e6080e7          	jalr	1766(ra) # 80000574 <printf>
    80002e96:	bf49                	j	80002e28 <syscall+0x82>
    }
    //end messing with code
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002e98:	86ce                	mv	a3,s3
    80002e9a:	15848613          	addi	a2,s1,344
    80002e9e:	588c                	lw	a1,48(s1)
    80002ea0:	00005517          	auipc	a0,0x5
    80002ea4:	58050513          	addi	a0,a0,1408 # 80008420 <states.0+0x178>
    80002ea8:	ffffd097          	auipc	ra,0xffffd
    80002eac:	6cc080e7          	jalr	1740(ra) # 80000574 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eb0:	6cbc                	ld	a5,88(s1)
    80002eb2:	577d                	li	a4,-1
    80002eb4:	fbb8                	sd	a4,112(a5)
  }
}
    80002eb6:	70e2                	ld	ra,56(sp)
    80002eb8:	7442                	ld	s0,48(sp)
    80002eba:	74a2                	ld	s1,40(sp)
    80002ebc:	7902                	ld	s2,32(sp)
    80002ebe:	69e2                	ld	s3,24(sp)
    80002ec0:	6121                	addi	sp,sp,64
    80002ec2:	8082                	ret

0000000080002ec4 <sys_wait_stat>:
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_wait_stat(void){
    80002ec4:	1101                	addi	sp,sp,-32
    80002ec6:	ec06                	sd	ra,24(sp)
    80002ec8:	e822                	sd	s0,16(sp)
    80002eca:	1000                	addi	s0,sp,32
  int* status ;
  struct perf* performance;
  argint(0, (int*)&status);
    80002ecc:	fe840593          	addi	a1,s0,-24
    80002ed0:	4501                	li	a0,0
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	e60080e7          	jalr	-416(ra) # 80002d32 <argint>
  argint(1, (int*)&performance);
    80002eda:	fe040593          	addi	a1,s0,-32
    80002ede:	4505                	li	a0,1
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	e52080e7          	jalr	-430(ra) # 80002d32 <argint>
  return wait_stat((int*)status, performance);
    80002ee8:	fe043583          	ld	a1,-32(s0)
    80002eec:	fe843503          	ld	a0,-24(s0)
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	5ae080e7          	jalr	1454(ra) # 8000249e <wait_stat>
}
    80002ef8:	60e2                	ld	ra,24(sp)
    80002efa:	6442                	ld	s0,16(sp)
    80002efc:	6105                	addi	sp,sp,32
    80002efe:	8082                	ret

0000000080002f00 <sys_trace>:

uint64
sys_trace(void)
{
    80002f00:	1101                	addi	sp,sp,-32
    80002f02:	ec06                	sd	ra,24(sp)
    80002f04:	e822                	sd	s0,16(sp)
    80002f06:	1000                	addi	s0,sp,32
  int mask;
  int pid;
  argint(0, &mask);
    80002f08:	fec40593          	addi	a1,s0,-20
    80002f0c:	4501                	li	a0,0
    80002f0e:	00000097          	auipc	ra,0x0
    80002f12:	e24080e7          	jalr	-476(ra) # 80002d32 <argint>
  if(argint(1, &pid) < 0)
    80002f16:	fe840593          	addi	a1,s0,-24
    80002f1a:	4505                	li	a0,1
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	e16080e7          	jalr	-490(ra) # 80002d32 <argint>
    80002f24:	87aa                	mv	a5,a0
    return -1;
    80002f26:	557d                	li	a0,-1
  if(argint(1, &pid) < 0)
    80002f28:	0007ca63          	bltz	a5,80002f3c <sys_trace+0x3c>
  return trace(mask, pid);
    80002f2c:	fe842583          	lw	a1,-24(s0)
    80002f30:	fec42503          	lw	a0,-20(s0)
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	6c0080e7          	jalr	1728(ra) # 800025f4 <trace>
}
    80002f3c:	60e2                	ld	ra,24(sp)
    80002f3e:	6442                	ld	s0,16(sp)
    80002f40:	6105                	addi	sp,sp,32
    80002f42:	8082                	ret

0000000080002f44 <sys_exit>:

uint64
sys_exit(void)
{
    80002f44:	1101                	addi	sp,sp,-32
    80002f46:	ec06                	sd	ra,24(sp)
    80002f48:	e822                	sd	s0,16(sp)
    80002f4a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f4c:	fec40593          	addi	a1,s0,-20
    80002f50:	4501                	li	a0,0
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	de0080e7          	jalr	-544(ra) # 80002d32 <argint>
    return -1;
    80002f5a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f5c:	00054963          	bltz	a0,80002f6e <sys_exit+0x2a>
  exit(n);
    80002f60:	fec42503          	lw	a0,-20(s0)
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	3c6080e7          	jalr	966(ra) # 8000232a <exit>
  return 0;  // not reached
    80002f6c:	4781                	li	a5,0
}
    80002f6e:	853e                	mv	a0,a5
    80002f70:	60e2                	ld	ra,24(sp)
    80002f72:	6442                	ld	s0,16(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret

0000000080002f78 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f78:	1141                	addi	sp,sp,-16
    80002f7a:	e406                	sd	ra,8(sp)
    80002f7c:	e022                	sd	s0,0(sp)
    80002f7e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	a12080e7          	jalr	-1518(ra) # 80001992 <myproc>
}
    80002f88:	5908                	lw	a0,48(a0)
    80002f8a:	60a2                	ld	ra,8(sp)
    80002f8c:	6402                	ld	s0,0(sp)
    80002f8e:	0141                	addi	sp,sp,16
    80002f90:	8082                	ret

0000000080002f92 <sys_fork>:

uint64
sys_fork(void)
{
    80002f92:	1141                	addi	sp,sp,-16
    80002f94:	e406                	sd	ra,8(sp)
    80002f96:	e022                	sd	s0,0(sp)
    80002f98:	0800                	addi	s0,sp,16
  return fork();
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	e0e080e7          	jalr	-498(ra) # 80001da8 <fork>
}
    80002fa2:	60a2                	ld	ra,8(sp)
    80002fa4:	6402                	ld	s0,0(sp)
    80002fa6:	0141                	addi	sp,sp,16
    80002fa8:	8082                	ret

0000000080002faa <sys_wait>:

uint64
sys_wait(void)
{
    80002faa:	1101                	addi	sp,sp,-32
    80002fac:	ec06                	sd	ra,24(sp)
    80002fae:	e822                	sd	s0,16(sp)
    80002fb0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fb2:	fe840593          	addi	a1,s0,-24
    80002fb6:	4501                	li	a0,0
    80002fb8:	00000097          	auipc	ra,0x0
    80002fbc:	d9c080e7          	jalr	-612(ra) # 80002d54 <argaddr>
    80002fc0:	87aa                	mv	a5,a0
    return -1;
    80002fc2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fc4:	0007c863          	bltz	a5,80002fd4 <sys_wait+0x2a>
  return wait(p);
    80002fc8:	fe843503          	ld	a0,-24(s0)
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	166080e7          	jalr	358(ra) # 80002132 <wait>
}
    80002fd4:	60e2                	ld	ra,24(sp)
    80002fd6:	6442                	ld	s0,16(sp)
    80002fd8:	6105                	addi	sp,sp,32
    80002fda:	8082                	ret

0000000080002fdc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fdc:	7179                	addi	sp,sp,-48
    80002fde:	f406                	sd	ra,40(sp)
    80002fe0:	f022                	sd	s0,32(sp)
    80002fe2:	ec26                	sd	s1,24(sp)
    80002fe4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fe6:	fdc40593          	addi	a1,s0,-36
    80002fea:	4501                	li	a0,0
    80002fec:	00000097          	auipc	ra,0x0
    80002ff0:	d46080e7          	jalr	-698(ra) # 80002d32 <argint>
    return -1;
    80002ff4:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002ff6:	00054f63          	bltz	a0,80003014 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	998080e7          	jalr	-1640(ra) # 80001992 <myproc>
    80003002:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003004:	fdc42503          	lw	a0,-36(s0)
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	d2c080e7          	jalr	-724(ra) # 80001d34 <growproc>
    80003010:	00054863          	bltz	a0,80003020 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80003014:	8526                	mv	a0,s1
    80003016:	70a2                	ld	ra,40(sp)
    80003018:	7402                	ld	s0,32(sp)
    8000301a:	64e2                	ld	s1,24(sp)
    8000301c:	6145                	addi	sp,sp,48
    8000301e:	8082                	ret
    return -1;
    80003020:	54fd                	li	s1,-1
    80003022:	bfcd                	j	80003014 <sys_sbrk+0x38>

0000000080003024 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003024:	7139                	addi	sp,sp,-64
    80003026:	fc06                	sd	ra,56(sp)
    80003028:	f822                	sd	s0,48(sp)
    8000302a:	f426                	sd	s1,40(sp)
    8000302c:	f04a                	sd	s2,32(sp)
    8000302e:	ec4e                	sd	s3,24(sp)
    80003030:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003032:	fcc40593          	addi	a1,s0,-52
    80003036:	4501                	li	a0,0
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	cfa080e7          	jalr	-774(ra) # 80002d32 <argint>
    return -1;
    80003040:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003042:	06054563          	bltz	a0,800030ac <sys_sleep+0x88>
  acquire(&tickslock);
    80003046:	00014517          	auipc	a0,0x14
    8000304a:	68a50513          	addi	a0,a0,1674 # 800176d0 <tickslock>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	b74080e7          	jalr	-1164(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003056:	00006917          	auipc	s2,0x6
    8000305a:	fda92903          	lw	s2,-38(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000305e:	fcc42783          	lw	a5,-52(s0)
    80003062:	cf85                	beqz	a5,8000309a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003064:	00014997          	auipc	s3,0x14
    80003068:	66c98993          	addi	s3,s3,1644 # 800176d0 <tickslock>
    8000306c:	00006497          	auipc	s1,0x6
    80003070:	fc448493          	addi	s1,s1,-60 # 80009030 <ticks>
    if(myproc()->killed){
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	91e080e7          	jalr	-1762(ra) # 80001992 <myproc>
    8000307c:	551c                	lw	a5,40(a0)
    8000307e:	ef9d                	bnez	a5,800030bc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003080:	85ce                	mv	a1,s3
    80003082:	8526                	mv	a0,s1
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	04a080e7          	jalr	74(ra) # 800020ce <sleep>
  while(ticks - ticks0 < n){
    8000308c:	409c                	lw	a5,0(s1)
    8000308e:	412787bb          	subw	a5,a5,s2
    80003092:	fcc42703          	lw	a4,-52(s0)
    80003096:	fce7efe3          	bltu	a5,a4,80003074 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000309a:	00014517          	auipc	a0,0x14
    8000309e:	63650513          	addi	a0,a0,1590 # 800176d0 <tickslock>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	bd4080e7          	jalr	-1068(ra) # 80000c76 <release>
  return 0;
    800030aa:	4781                	li	a5,0
}
    800030ac:	853e                	mv	a0,a5
    800030ae:	70e2                	ld	ra,56(sp)
    800030b0:	7442                	ld	s0,48(sp)
    800030b2:	74a2                	ld	s1,40(sp)
    800030b4:	7902                	ld	s2,32(sp)
    800030b6:	69e2                	ld	s3,24(sp)
    800030b8:	6121                	addi	sp,sp,64
    800030ba:	8082                	ret
      release(&tickslock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	61450513          	addi	a0,a0,1556 # 800176d0 <tickslock>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	bb2080e7          	jalr	-1102(ra) # 80000c76 <release>
      return -1;
    800030cc:	57fd                	li	a5,-1
    800030ce:	bff9                	j	800030ac <sys_sleep+0x88>

00000000800030d0 <sys_kill>:

uint64
sys_kill(void)
{
    800030d0:	1101                	addi	sp,sp,-32
    800030d2:	ec06                	sd	ra,24(sp)
    800030d4:	e822                	sd	s0,16(sp)
    800030d6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030d8:	fec40593          	addi	a1,s0,-20
    800030dc:	4501                	li	a0,0
    800030de:	00000097          	auipc	ra,0x0
    800030e2:	c54080e7          	jalr	-940(ra) # 80002d32 <argint>
    800030e6:	87aa                	mv	a5,a0
    return -1;
    800030e8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030ea:	0007c863          	bltz	a5,800030fa <sys_kill+0x2a>
  return kill(pid);
    800030ee:	fec42503          	lw	a0,-20(s0)
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	33a080e7          	jalr	826(ra) # 8000242c <kill>
}
    800030fa:	60e2                	ld	ra,24(sp)
    800030fc:	6442                	ld	s0,16(sp)
    800030fe:	6105                	addi	sp,sp,32
    80003100:	8082                	ret

0000000080003102 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003102:	1101                	addi	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	e426                	sd	s1,8(sp)
    8000310a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000310c:	00014517          	auipc	a0,0x14
    80003110:	5c450513          	addi	a0,a0,1476 # 800176d0 <tickslock>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	aae080e7          	jalr	-1362(ra) # 80000bc2 <acquire>
  xticks = ticks;
    8000311c:	00006497          	auipc	s1,0x6
    80003120:	f144a483          	lw	s1,-236(s1) # 80009030 <ticks>
  release(&tickslock);
    80003124:	00014517          	auipc	a0,0x14
    80003128:	5ac50513          	addi	a0,a0,1452 # 800176d0 <tickslock>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	b4a080e7          	jalr	-1206(ra) # 80000c76 <release>
  return xticks;
}
    80003134:	02049513          	slli	a0,s1,0x20
    80003138:	9101                	srli	a0,a0,0x20
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	64a2                	ld	s1,8(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret

0000000080003144 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003144:	7179                	addi	sp,sp,-48
    80003146:	f406                	sd	ra,40(sp)
    80003148:	f022                	sd	s0,32(sp)
    8000314a:	ec26                	sd	s1,24(sp)
    8000314c:	e84a                	sd	s2,16(sp)
    8000314e:	e44e                	sd	s3,8(sp)
    80003150:	e052                	sd	s4,0(sp)
    80003152:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003154:	00005597          	auipc	a1,0x5
    80003158:	5ec58593          	addi	a1,a1,1516 # 80008740 <syscalls_str+0xc0>
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	58c50513          	addi	a0,a0,1420 # 800176e8 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	9ce080e7          	jalr	-1586(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000316c:	0001c797          	auipc	a5,0x1c
    80003170:	57c78793          	addi	a5,a5,1404 # 8001f6e8 <bcache+0x8000>
    80003174:	0001c717          	auipc	a4,0x1c
    80003178:	7dc70713          	addi	a4,a4,2012 # 8001f950 <bcache+0x8268>
    8000317c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003180:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003184:	00014497          	auipc	s1,0x14
    80003188:	57c48493          	addi	s1,s1,1404 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    8000318c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000318e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003190:	00005a17          	auipc	s4,0x5
    80003194:	5b8a0a13          	addi	s4,s4,1464 # 80008748 <syscalls_str+0xc8>
    b->next = bcache.head.next;
    80003198:	2b893783          	ld	a5,696(s2)
    8000319c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000319e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031a2:	85d2                	mv	a1,s4
    800031a4:	01048513          	addi	a0,s1,16
    800031a8:	00001097          	auipc	ra,0x1
    800031ac:	4c2080e7          	jalr	1218(ra) # 8000466a <initsleeplock>
    bcache.head.next->prev = b;
    800031b0:	2b893783          	ld	a5,696(s2)
    800031b4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031b6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ba:	45848493          	addi	s1,s1,1112
    800031be:	fd349de3          	bne	s1,s3,80003198 <binit+0x54>
  }
}
    800031c2:	70a2                	ld	ra,40(sp)
    800031c4:	7402                	ld	s0,32(sp)
    800031c6:	64e2                	ld	s1,24(sp)
    800031c8:	6942                	ld	s2,16(sp)
    800031ca:	69a2                	ld	s3,8(sp)
    800031cc:	6a02                	ld	s4,0(sp)
    800031ce:	6145                	addi	sp,sp,48
    800031d0:	8082                	ret

00000000800031d2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031d2:	7179                	addi	sp,sp,-48
    800031d4:	f406                	sd	ra,40(sp)
    800031d6:	f022                	sd	s0,32(sp)
    800031d8:	ec26                	sd	s1,24(sp)
    800031da:	e84a                	sd	s2,16(sp)
    800031dc:	e44e                	sd	s3,8(sp)
    800031de:	1800                	addi	s0,sp,48
    800031e0:	892a                	mv	s2,a0
    800031e2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031e4:	00014517          	auipc	a0,0x14
    800031e8:	50450513          	addi	a0,a0,1284 # 800176e8 <bcache>
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	9d6080e7          	jalr	-1578(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031f4:	0001c497          	auipc	s1,0x1c
    800031f8:	7ac4b483          	ld	s1,1964(s1) # 8001f9a0 <bcache+0x82b8>
    800031fc:	0001c797          	auipc	a5,0x1c
    80003200:	75478793          	addi	a5,a5,1876 # 8001f950 <bcache+0x8268>
    80003204:	02f48f63          	beq	s1,a5,80003242 <bread+0x70>
    80003208:	873e                	mv	a4,a5
    8000320a:	a021                	j	80003212 <bread+0x40>
    8000320c:	68a4                	ld	s1,80(s1)
    8000320e:	02e48a63          	beq	s1,a4,80003242 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003212:	449c                	lw	a5,8(s1)
    80003214:	ff279ce3          	bne	a5,s2,8000320c <bread+0x3a>
    80003218:	44dc                	lw	a5,12(s1)
    8000321a:	ff3799e3          	bne	a5,s3,8000320c <bread+0x3a>
      b->refcnt++;
    8000321e:	40bc                	lw	a5,64(s1)
    80003220:	2785                	addiw	a5,a5,1
    80003222:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003224:	00014517          	auipc	a0,0x14
    80003228:	4c450513          	addi	a0,a0,1220 # 800176e8 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	a4a080e7          	jalr	-1462(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003234:	01048513          	addi	a0,s1,16
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	46c080e7          	jalr	1132(ra) # 800046a4 <acquiresleep>
      return b;
    80003240:	a8b9                	j	8000329e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003242:	0001c497          	auipc	s1,0x1c
    80003246:	7564b483          	ld	s1,1878(s1) # 8001f998 <bcache+0x82b0>
    8000324a:	0001c797          	auipc	a5,0x1c
    8000324e:	70678793          	addi	a5,a5,1798 # 8001f950 <bcache+0x8268>
    80003252:	00f48863          	beq	s1,a5,80003262 <bread+0x90>
    80003256:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003258:	40bc                	lw	a5,64(s1)
    8000325a:	cf81                	beqz	a5,80003272 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000325c:	64a4                	ld	s1,72(s1)
    8000325e:	fee49de3          	bne	s1,a4,80003258 <bread+0x86>
  panic("bget: no buffers");
    80003262:	00005517          	auipc	a0,0x5
    80003266:	4ee50513          	addi	a0,a0,1262 # 80008750 <syscalls_str+0xd0>
    8000326a:	ffffd097          	auipc	ra,0xffffd
    8000326e:	2c0080e7          	jalr	704(ra) # 8000052a <panic>
      b->dev = dev;
    80003272:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003276:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000327a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000327e:	4785                	li	a5,1
    80003280:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003282:	00014517          	auipc	a0,0x14
    80003286:	46650513          	addi	a0,a0,1126 # 800176e8 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	9ec080e7          	jalr	-1556(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003292:	01048513          	addi	a0,s1,16
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	40e080e7          	jalr	1038(ra) # 800046a4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000329e:	409c                	lw	a5,0(s1)
    800032a0:	cb89                	beqz	a5,800032b2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032a2:	8526                	mv	a0,s1
    800032a4:	70a2                	ld	ra,40(sp)
    800032a6:	7402                	ld	s0,32(sp)
    800032a8:	64e2                	ld	s1,24(sp)
    800032aa:	6942                	ld	s2,16(sp)
    800032ac:	69a2                	ld	s3,8(sp)
    800032ae:	6145                	addi	sp,sp,48
    800032b0:	8082                	ret
    virtio_disk_rw(b, 0);
    800032b2:	4581                	li	a1,0
    800032b4:	8526                	mv	a0,s1
    800032b6:	00003097          	auipc	ra,0x3
    800032ba:	f20080e7          	jalr	-224(ra) # 800061d6 <virtio_disk_rw>
    b->valid = 1;
    800032be:	4785                	li	a5,1
    800032c0:	c09c                	sw	a5,0(s1)
  return b;
    800032c2:	b7c5                	j	800032a2 <bread+0xd0>

00000000800032c4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032c4:	1101                	addi	sp,sp,-32
    800032c6:	ec06                	sd	ra,24(sp)
    800032c8:	e822                	sd	s0,16(sp)
    800032ca:	e426                	sd	s1,8(sp)
    800032cc:	1000                	addi	s0,sp,32
    800032ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032d0:	0541                	addi	a0,a0,16
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	46c080e7          	jalr	1132(ra) # 8000473e <holdingsleep>
    800032da:	cd01                	beqz	a0,800032f2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032dc:	4585                	li	a1,1
    800032de:	8526                	mv	a0,s1
    800032e0:	00003097          	auipc	ra,0x3
    800032e4:	ef6080e7          	jalr	-266(ra) # 800061d6 <virtio_disk_rw>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret
    panic("bwrite");
    800032f2:	00005517          	auipc	a0,0x5
    800032f6:	47650513          	addi	a0,a0,1142 # 80008768 <syscalls_str+0xe8>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	230080e7          	jalr	560(ra) # 8000052a <panic>

0000000080003302 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003302:	1101                	addi	sp,sp,-32
    80003304:	ec06                	sd	ra,24(sp)
    80003306:	e822                	sd	s0,16(sp)
    80003308:	e426                	sd	s1,8(sp)
    8000330a:	e04a                	sd	s2,0(sp)
    8000330c:	1000                	addi	s0,sp,32
    8000330e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003310:	01050913          	addi	s2,a0,16
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	428080e7          	jalr	1064(ra) # 8000473e <holdingsleep>
    8000331e:	c92d                	beqz	a0,80003390 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003320:	854a                	mv	a0,s2
    80003322:	00001097          	auipc	ra,0x1
    80003326:	3d8080e7          	jalr	984(ra) # 800046fa <releasesleep>

  acquire(&bcache.lock);
    8000332a:	00014517          	auipc	a0,0x14
    8000332e:	3be50513          	addi	a0,a0,958 # 800176e8 <bcache>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	890080e7          	jalr	-1904(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000333a:	40bc                	lw	a5,64(s1)
    8000333c:	37fd                	addiw	a5,a5,-1
    8000333e:	0007871b          	sext.w	a4,a5
    80003342:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003344:	eb05                	bnez	a4,80003374 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003346:	68bc                	ld	a5,80(s1)
    80003348:	64b8                	ld	a4,72(s1)
    8000334a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000334c:	64bc                	ld	a5,72(s1)
    8000334e:	68b8                	ld	a4,80(s1)
    80003350:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003352:	0001c797          	auipc	a5,0x1c
    80003356:	39678793          	addi	a5,a5,918 # 8001f6e8 <bcache+0x8000>
    8000335a:	2b87b703          	ld	a4,696(a5)
    8000335e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003360:	0001c717          	auipc	a4,0x1c
    80003364:	5f070713          	addi	a4,a4,1520 # 8001f950 <bcache+0x8268>
    80003368:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000336a:	2b87b703          	ld	a4,696(a5)
    8000336e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003370:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003374:	00014517          	auipc	a0,0x14
    80003378:	37450513          	addi	a0,a0,884 # 800176e8 <bcache>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	8fa080e7          	jalr	-1798(ra) # 80000c76 <release>
}
    80003384:	60e2                	ld	ra,24(sp)
    80003386:	6442                	ld	s0,16(sp)
    80003388:	64a2                	ld	s1,8(sp)
    8000338a:	6902                	ld	s2,0(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret
    panic("brelse");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	3e050513          	addi	a0,a0,992 # 80008770 <syscalls_str+0xf0>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	192080e7          	jalr	402(ra) # 8000052a <panic>

00000000800033a0 <bpin>:

void
bpin(struct buf *b) {
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
    800033aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ac:	00014517          	auipc	a0,0x14
    800033b0:	33c50513          	addi	a0,a0,828 # 800176e8 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	80e080e7          	jalr	-2034(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800033bc:	40bc                	lw	a5,64(s1)
    800033be:	2785                	addiw	a5,a5,1
    800033c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033c2:	00014517          	auipc	a0,0x14
    800033c6:	32650513          	addi	a0,a0,806 # 800176e8 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	8ac080e7          	jalr	-1876(ra) # 80000c76 <release>
}
    800033d2:	60e2                	ld	ra,24(sp)
    800033d4:	6442                	ld	s0,16(sp)
    800033d6:	64a2                	ld	s1,8(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret

00000000800033dc <bunpin>:

void
bunpin(struct buf *b) {
    800033dc:	1101                	addi	sp,sp,-32
    800033de:	ec06                	sd	ra,24(sp)
    800033e0:	e822                	sd	s0,16(sp)
    800033e2:	e426                	sd	s1,8(sp)
    800033e4:	1000                	addi	s0,sp,32
    800033e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033e8:	00014517          	auipc	a0,0x14
    800033ec:	30050513          	addi	a0,a0,768 # 800176e8 <bcache>
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	7d2080e7          	jalr	2002(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800033f8:	40bc                	lw	a5,64(s1)
    800033fa:	37fd                	addiw	a5,a5,-1
    800033fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033fe:	00014517          	auipc	a0,0x14
    80003402:	2ea50513          	addi	a0,a0,746 # 800176e8 <bcache>
    80003406:	ffffe097          	auipc	ra,0xffffe
    8000340a:	870080e7          	jalr	-1936(ra) # 80000c76 <release>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6105                	addi	sp,sp,32
    80003416:	8082                	ret

0000000080003418 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003418:	1101                	addi	sp,sp,-32
    8000341a:	ec06                	sd	ra,24(sp)
    8000341c:	e822                	sd	s0,16(sp)
    8000341e:	e426                	sd	s1,8(sp)
    80003420:	e04a                	sd	s2,0(sp)
    80003422:	1000                	addi	s0,sp,32
    80003424:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003426:	00d5d59b          	srliw	a1,a1,0xd
    8000342a:	0001d797          	auipc	a5,0x1d
    8000342e:	99a7a783          	lw	a5,-1638(a5) # 8001fdc4 <sb+0x1c>
    80003432:	9dbd                	addw	a1,a1,a5
    80003434:	00000097          	auipc	ra,0x0
    80003438:	d9e080e7          	jalr	-610(ra) # 800031d2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000343c:	0074f713          	andi	a4,s1,7
    80003440:	4785                	li	a5,1
    80003442:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003446:	14ce                	slli	s1,s1,0x33
    80003448:	90d9                	srli	s1,s1,0x36
    8000344a:	00950733          	add	a4,a0,s1
    8000344e:	05874703          	lbu	a4,88(a4)
    80003452:	00e7f6b3          	and	a3,a5,a4
    80003456:	c69d                	beqz	a3,80003484 <bfree+0x6c>
    80003458:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000345a:	94aa                	add	s1,s1,a0
    8000345c:	fff7c793          	not	a5,a5
    80003460:	8ff9                	and	a5,a5,a4
    80003462:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	11e080e7          	jalr	286(ra) # 80004584 <log_write>
  brelse(bp);
    8000346e:	854a                	mv	a0,s2
    80003470:	00000097          	auipc	ra,0x0
    80003474:	e92080e7          	jalr	-366(ra) # 80003302 <brelse>
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6902                	ld	s2,0(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret
    panic("freeing free block");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	2f450513          	addi	a0,a0,756 # 80008778 <syscalls_str+0xf8>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	09e080e7          	jalr	158(ra) # 8000052a <panic>

0000000080003494 <balloc>:
{
    80003494:	711d                	addi	sp,sp,-96
    80003496:	ec86                	sd	ra,88(sp)
    80003498:	e8a2                	sd	s0,80(sp)
    8000349a:	e4a6                	sd	s1,72(sp)
    8000349c:	e0ca                	sd	s2,64(sp)
    8000349e:	fc4e                	sd	s3,56(sp)
    800034a0:	f852                	sd	s4,48(sp)
    800034a2:	f456                	sd	s5,40(sp)
    800034a4:	f05a                	sd	s6,32(sp)
    800034a6:	ec5e                	sd	s7,24(sp)
    800034a8:	e862                	sd	s8,16(sp)
    800034aa:	e466                	sd	s9,8(sp)
    800034ac:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034ae:	0001d797          	auipc	a5,0x1d
    800034b2:	8fe7a783          	lw	a5,-1794(a5) # 8001fdac <sb+0x4>
    800034b6:	cbd1                	beqz	a5,8000354a <balloc+0xb6>
    800034b8:	8baa                	mv	s7,a0
    800034ba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034bc:	0001db17          	auipc	s6,0x1d
    800034c0:	8ecb0b13          	addi	s6,s6,-1812 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034c6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034ca:	6c89                	lui	s9,0x2
    800034cc:	a831                	j	800034e8 <balloc+0x54>
    brelse(bp);
    800034ce:	854a                	mv	a0,s2
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	e32080e7          	jalr	-462(ra) # 80003302 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034d8:	015c87bb          	addw	a5,s9,s5
    800034dc:	00078a9b          	sext.w	s5,a5
    800034e0:	004b2703          	lw	a4,4(s6)
    800034e4:	06eaf363          	bgeu	s5,a4,8000354a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034e8:	41fad79b          	sraiw	a5,s5,0x1f
    800034ec:	0137d79b          	srliw	a5,a5,0x13
    800034f0:	015787bb          	addw	a5,a5,s5
    800034f4:	40d7d79b          	sraiw	a5,a5,0xd
    800034f8:	01cb2583          	lw	a1,28(s6)
    800034fc:	9dbd                	addw	a1,a1,a5
    800034fe:	855e                	mv	a0,s7
    80003500:	00000097          	auipc	ra,0x0
    80003504:	cd2080e7          	jalr	-814(ra) # 800031d2 <bread>
    80003508:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000350a:	004b2503          	lw	a0,4(s6)
    8000350e:	000a849b          	sext.w	s1,s5
    80003512:	8662                	mv	a2,s8
    80003514:	faa4fde3          	bgeu	s1,a0,800034ce <balloc+0x3a>
      m = 1 << (bi % 8);
    80003518:	41f6579b          	sraiw	a5,a2,0x1f
    8000351c:	01d7d69b          	srliw	a3,a5,0x1d
    80003520:	00c6873b          	addw	a4,a3,a2
    80003524:	00777793          	andi	a5,a4,7
    80003528:	9f95                	subw	a5,a5,a3
    8000352a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000352e:	4037571b          	sraiw	a4,a4,0x3
    80003532:	00e906b3          	add	a3,s2,a4
    80003536:	0586c683          	lbu	a3,88(a3)
    8000353a:	00d7f5b3          	and	a1,a5,a3
    8000353e:	cd91                	beqz	a1,8000355a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003540:	2605                	addiw	a2,a2,1
    80003542:	2485                	addiw	s1,s1,1
    80003544:	fd4618e3          	bne	a2,s4,80003514 <balloc+0x80>
    80003548:	b759                	j	800034ce <balloc+0x3a>
  panic("balloc: out of blocks");
    8000354a:	00005517          	auipc	a0,0x5
    8000354e:	24650513          	addi	a0,a0,582 # 80008790 <syscalls_str+0x110>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	fd8080e7          	jalr	-40(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000355a:	974a                	add	a4,a4,s2
    8000355c:	8fd5                	or	a5,a5,a3
    8000355e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003562:	854a                	mv	a0,s2
    80003564:	00001097          	auipc	ra,0x1
    80003568:	020080e7          	jalr	32(ra) # 80004584 <log_write>
        brelse(bp);
    8000356c:	854a                	mv	a0,s2
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	d94080e7          	jalr	-620(ra) # 80003302 <brelse>
  bp = bread(dev, bno);
    80003576:	85a6                	mv	a1,s1
    80003578:	855e                	mv	a0,s7
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	c58080e7          	jalr	-936(ra) # 800031d2 <bread>
    80003582:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003584:	40000613          	li	a2,1024
    80003588:	4581                	li	a1,0
    8000358a:	05850513          	addi	a0,a0,88
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	730080e7          	jalr	1840(ra) # 80000cbe <memset>
  log_write(bp);
    80003596:	854a                	mv	a0,s2
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	fec080e7          	jalr	-20(ra) # 80004584 <log_write>
  brelse(bp);
    800035a0:	854a                	mv	a0,s2
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	d60080e7          	jalr	-672(ra) # 80003302 <brelse>
}
    800035aa:	8526                	mv	a0,s1
    800035ac:	60e6                	ld	ra,88(sp)
    800035ae:	6446                	ld	s0,80(sp)
    800035b0:	64a6                	ld	s1,72(sp)
    800035b2:	6906                	ld	s2,64(sp)
    800035b4:	79e2                	ld	s3,56(sp)
    800035b6:	7a42                	ld	s4,48(sp)
    800035b8:	7aa2                	ld	s5,40(sp)
    800035ba:	7b02                	ld	s6,32(sp)
    800035bc:	6be2                	ld	s7,24(sp)
    800035be:	6c42                	ld	s8,16(sp)
    800035c0:	6ca2                	ld	s9,8(sp)
    800035c2:	6125                	addi	sp,sp,96
    800035c4:	8082                	ret

00000000800035c6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035c6:	7179                	addi	sp,sp,-48
    800035c8:	f406                	sd	ra,40(sp)
    800035ca:	f022                	sd	s0,32(sp)
    800035cc:	ec26                	sd	s1,24(sp)
    800035ce:	e84a                	sd	s2,16(sp)
    800035d0:	e44e                	sd	s3,8(sp)
    800035d2:	e052                	sd	s4,0(sp)
    800035d4:	1800                	addi	s0,sp,48
    800035d6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035d8:	47ad                	li	a5,11
    800035da:	04b7fe63          	bgeu	a5,a1,80003636 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035de:	ff45849b          	addiw	s1,a1,-12
    800035e2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035e6:	0ff00793          	li	a5,255
    800035ea:	0ae7e463          	bltu	a5,a4,80003692 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035ee:	08052583          	lw	a1,128(a0)
    800035f2:	c5b5                	beqz	a1,8000365e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035f4:	00092503          	lw	a0,0(s2)
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	bda080e7          	jalr	-1062(ra) # 800031d2 <bread>
    80003600:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003602:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003606:	02049713          	slli	a4,s1,0x20
    8000360a:	01e75593          	srli	a1,a4,0x1e
    8000360e:	00b784b3          	add	s1,a5,a1
    80003612:	0004a983          	lw	s3,0(s1)
    80003616:	04098e63          	beqz	s3,80003672 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000361a:	8552                	mv	a0,s4
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	ce6080e7          	jalr	-794(ra) # 80003302 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003624:	854e                	mv	a0,s3
    80003626:	70a2                	ld	ra,40(sp)
    80003628:	7402                	ld	s0,32(sp)
    8000362a:	64e2                	ld	s1,24(sp)
    8000362c:	6942                	ld	s2,16(sp)
    8000362e:	69a2                	ld	s3,8(sp)
    80003630:	6a02                	ld	s4,0(sp)
    80003632:	6145                	addi	sp,sp,48
    80003634:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003636:	02059793          	slli	a5,a1,0x20
    8000363a:	01e7d593          	srli	a1,a5,0x1e
    8000363e:	00b504b3          	add	s1,a0,a1
    80003642:	0504a983          	lw	s3,80(s1)
    80003646:	fc099fe3          	bnez	s3,80003624 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000364a:	4108                	lw	a0,0(a0)
    8000364c:	00000097          	auipc	ra,0x0
    80003650:	e48080e7          	jalr	-440(ra) # 80003494 <balloc>
    80003654:	0005099b          	sext.w	s3,a0
    80003658:	0534a823          	sw	s3,80(s1)
    8000365c:	b7e1                	j	80003624 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000365e:	4108                	lw	a0,0(a0)
    80003660:	00000097          	auipc	ra,0x0
    80003664:	e34080e7          	jalr	-460(ra) # 80003494 <balloc>
    80003668:	0005059b          	sext.w	a1,a0
    8000366c:	08b92023          	sw	a1,128(s2)
    80003670:	b751                	j	800035f4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003672:	00092503          	lw	a0,0(s2)
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	e1e080e7          	jalr	-482(ra) # 80003494 <balloc>
    8000367e:	0005099b          	sext.w	s3,a0
    80003682:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003686:	8552                	mv	a0,s4
    80003688:	00001097          	auipc	ra,0x1
    8000368c:	efc080e7          	jalr	-260(ra) # 80004584 <log_write>
    80003690:	b769                	j	8000361a <bmap+0x54>
  panic("bmap: out of range");
    80003692:	00005517          	auipc	a0,0x5
    80003696:	11650513          	addi	a0,a0,278 # 800087a8 <syscalls_str+0x128>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	e90080e7          	jalr	-368(ra) # 8000052a <panic>

00000000800036a2 <iget>:
{
    800036a2:	7179                	addi	sp,sp,-48
    800036a4:	f406                	sd	ra,40(sp)
    800036a6:	f022                	sd	s0,32(sp)
    800036a8:	ec26                	sd	s1,24(sp)
    800036aa:	e84a                	sd	s2,16(sp)
    800036ac:	e44e                	sd	s3,8(sp)
    800036ae:	e052                	sd	s4,0(sp)
    800036b0:	1800                	addi	s0,sp,48
    800036b2:	89aa                	mv	s3,a0
    800036b4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036b6:	0001c517          	auipc	a0,0x1c
    800036ba:	71250513          	addi	a0,a0,1810 # 8001fdc8 <itable>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	504080e7          	jalr	1284(ra) # 80000bc2 <acquire>
  empty = 0;
    800036c6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036c8:	0001c497          	auipc	s1,0x1c
    800036cc:	71848493          	addi	s1,s1,1816 # 8001fde0 <itable+0x18>
    800036d0:	0001e697          	auipc	a3,0x1e
    800036d4:	1a068693          	addi	a3,a3,416 # 80021870 <log>
    800036d8:	a039                	j	800036e6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036da:	02090b63          	beqz	s2,80003710 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036de:	08848493          	addi	s1,s1,136
    800036e2:	02d48a63          	beq	s1,a3,80003716 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036e6:	449c                	lw	a5,8(s1)
    800036e8:	fef059e3          	blez	a5,800036da <iget+0x38>
    800036ec:	4098                	lw	a4,0(s1)
    800036ee:	ff3716e3          	bne	a4,s3,800036da <iget+0x38>
    800036f2:	40d8                	lw	a4,4(s1)
    800036f4:	ff4713e3          	bne	a4,s4,800036da <iget+0x38>
      ip->ref++;
    800036f8:	2785                	addiw	a5,a5,1
    800036fa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036fc:	0001c517          	auipc	a0,0x1c
    80003700:	6cc50513          	addi	a0,a0,1740 # 8001fdc8 <itable>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	572080e7          	jalr	1394(ra) # 80000c76 <release>
      return ip;
    8000370c:	8926                	mv	s2,s1
    8000370e:	a03d                	j	8000373c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003710:	f7f9                	bnez	a5,800036de <iget+0x3c>
    80003712:	8926                	mv	s2,s1
    80003714:	b7e9                	j	800036de <iget+0x3c>
  if(empty == 0)
    80003716:	02090c63          	beqz	s2,8000374e <iget+0xac>
  ip->dev = dev;
    8000371a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000371e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003722:	4785                	li	a5,1
    80003724:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003728:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000372c:	0001c517          	auipc	a0,0x1c
    80003730:	69c50513          	addi	a0,a0,1692 # 8001fdc8 <itable>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	542080e7          	jalr	1346(ra) # 80000c76 <release>
}
    8000373c:	854a                	mv	a0,s2
    8000373e:	70a2                	ld	ra,40(sp)
    80003740:	7402                	ld	s0,32(sp)
    80003742:	64e2                	ld	s1,24(sp)
    80003744:	6942                	ld	s2,16(sp)
    80003746:	69a2                	ld	s3,8(sp)
    80003748:	6a02                	ld	s4,0(sp)
    8000374a:	6145                	addi	sp,sp,48
    8000374c:	8082                	ret
    panic("iget: no inodes");
    8000374e:	00005517          	auipc	a0,0x5
    80003752:	07250513          	addi	a0,a0,114 # 800087c0 <syscalls_str+0x140>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	dd4080e7          	jalr	-556(ra) # 8000052a <panic>

000000008000375e <fsinit>:
fsinit(int dev) {
    8000375e:	7179                	addi	sp,sp,-48
    80003760:	f406                	sd	ra,40(sp)
    80003762:	f022                	sd	s0,32(sp)
    80003764:	ec26                	sd	s1,24(sp)
    80003766:	e84a                	sd	s2,16(sp)
    80003768:	e44e                	sd	s3,8(sp)
    8000376a:	1800                	addi	s0,sp,48
    8000376c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000376e:	4585                	li	a1,1
    80003770:	00000097          	auipc	ra,0x0
    80003774:	a62080e7          	jalr	-1438(ra) # 800031d2 <bread>
    80003778:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000377a:	0001c997          	auipc	s3,0x1c
    8000377e:	62e98993          	addi	s3,s3,1582 # 8001fda8 <sb>
    80003782:	02000613          	li	a2,32
    80003786:	05850593          	addi	a1,a0,88
    8000378a:	854e                	mv	a0,s3
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	58e080e7          	jalr	1422(ra) # 80000d1a <memmove>
  brelse(bp);
    80003794:	8526                	mv	a0,s1
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	b6c080e7          	jalr	-1172(ra) # 80003302 <brelse>
  if(sb.magic != FSMAGIC)
    8000379e:	0009a703          	lw	a4,0(s3)
    800037a2:	102037b7          	lui	a5,0x10203
    800037a6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037aa:	02f71263          	bne	a4,a5,800037ce <fsinit+0x70>
  initlog(dev, &sb);
    800037ae:	0001c597          	auipc	a1,0x1c
    800037b2:	5fa58593          	addi	a1,a1,1530 # 8001fda8 <sb>
    800037b6:	854a                	mv	a0,s2
    800037b8:	00001097          	auipc	ra,0x1
    800037bc:	b4e080e7          	jalr	-1202(ra) # 80004306 <initlog>
}
    800037c0:	70a2                	ld	ra,40(sp)
    800037c2:	7402                	ld	s0,32(sp)
    800037c4:	64e2                	ld	s1,24(sp)
    800037c6:	6942                	ld	s2,16(sp)
    800037c8:	69a2                	ld	s3,8(sp)
    800037ca:	6145                	addi	sp,sp,48
    800037cc:	8082                	ret
    panic("invalid file system");
    800037ce:	00005517          	auipc	a0,0x5
    800037d2:	00250513          	addi	a0,a0,2 # 800087d0 <syscalls_str+0x150>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	d54080e7          	jalr	-684(ra) # 8000052a <panic>

00000000800037de <iinit>:
{
    800037de:	7179                	addi	sp,sp,-48
    800037e0:	f406                	sd	ra,40(sp)
    800037e2:	f022                	sd	s0,32(sp)
    800037e4:	ec26                	sd	s1,24(sp)
    800037e6:	e84a                	sd	s2,16(sp)
    800037e8:	e44e                	sd	s3,8(sp)
    800037ea:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037ec:	00005597          	auipc	a1,0x5
    800037f0:	ffc58593          	addi	a1,a1,-4 # 800087e8 <syscalls_str+0x168>
    800037f4:	0001c517          	auipc	a0,0x1c
    800037f8:	5d450513          	addi	a0,a0,1492 # 8001fdc8 <itable>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	336080e7          	jalr	822(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003804:	0001c497          	auipc	s1,0x1c
    80003808:	5ec48493          	addi	s1,s1,1516 # 8001fdf0 <itable+0x28>
    8000380c:	0001e997          	auipc	s3,0x1e
    80003810:	07498993          	addi	s3,s3,116 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003814:	00005917          	auipc	s2,0x5
    80003818:	fdc90913          	addi	s2,s2,-36 # 800087f0 <syscalls_str+0x170>
    8000381c:	85ca                	mv	a1,s2
    8000381e:	8526                	mv	a0,s1
    80003820:	00001097          	auipc	ra,0x1
    80003824:	e4a080e7          	jalr	-438(ra) # 8000466a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003828:	08848493          	addi	s1,s1,136
    8000382c:	ff3498e3          	bne	s1,s3,8000381c <iinit+0x3e>
}
    80003830:	70a2                	ld	ra,40(sp)
    80003832:	7402                	ld	s0,32(sp)
    80003834:	64e2                	ld	s1,24(sp)
    80003836:	6942                	ld	s2,16(sp)
    80003838:	69a2                	ld	s3,8(sp)
    8000383a:	6145                	addi	sp,sp,48
    8000383c:	8082                	ret

000000008000383e <ialloc>:
{
    8000383e:	715d                	addi	sp,sp,-80
    80003840:	e486                	sd	ra,72(sp)
    80003842:	e0a2                	sd	s0,64(sp)
    80003844:	fc26                	sd	s1,56(sp)
    80003846:	f84a                	sd	s2,48(sp)
    80003848:	f44e                	sd	s3,40(sp)
    8000384a:	f052                	sd	s4,32(sp)
    8000384c:	ec56                	sd	s5,24(sp)
    8000384e:	e85a                	sd	s6,16(sp)
    80003850:	e45e                	sd	s7,8(sp)
    80003852:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003854:	0001c717          	auipc	a4,0x1c
    80003858:	56072703          	lw	a4,1376(a4) # 8001fdb4 <sb+0xc>
    8000385c:	4785                	li	a5,1
    8000385e:	04e7fa63          	bgeu	a5,a4,800038b2 <ialloc+0x74>
    80003862:	8aaa                	mv	s5,a0
    80003864:	8bae                	mv	s7,a1
    80003866:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003868:	0001ca17          	auipc	s4,0x1c
    8000386c:	540a0a13          	addi	s4,s4,1344 # 8001fda8 <sb>
    80003870:	00048b1b          	sext.w	s6,s1
    80003874:	0044d793          	srli	a5,s1,0x4
    80003878:	018a2583          	lw	a1,24(s4)
    8000387c:	9dbd                	addw	a1,a1,a5
    8000387e:	8556                	mv	a0,s5
    80003880:	00000097          	auipc	ra,0x0
    80003884:	952080e7          	jalr	-1710(ra) # 800031d2 <bread>
    80003888:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000388a:	05850993          	addi	s3,a0,88
    8000388e:	00f4f793          	andi	a5,s1,15
    80003892:	079a                	slli	a5,a5,0x6
    80003894:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003896:	00099783          	lh	a5,0(s3)
    8000389a:	c785                	beqz	a5,800038c2 <ialloc+0x84>
    brelse(bp);
    8000389c:	00000097          	auipc	ra,0x0
    800038a0:	a66080e7          	jalr	-1434(ra) # 80003302 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038a4:	0485                	addi	s1,s1,1
    800038a6:	00ca2703          	lw	a4,12(s4)
    800038aa:	0004879b          	sext.w	a5,s1
    800038ae:	fce7e1e3          	bltu	a5,a4,80003870 <ialloc+0x32>
  panic("ialloc: no inodes");
    800038b2:	00005517          	auipc	a0,0x5
    800038b6:	f4650513          	addi	a0,a0,-186 # 800087f8 <syscalls_str+0x178>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	c70080e7          	jalr	-912(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800038c2:	04000613          	li	a2,64
    800038c6:	4581                	li	a1,0
    800038c8:	854e                	mv	a0,s3
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	3f4080e7          	jalr	1012(ra) # 80000cbe <memset>
      dip->type = type;
    800038d2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038d6:	854a                	mv	a0,s2
    800038d8:	00001097          	auipc	ra,0x1
    800038dc:	cac080e7          	jalr	-852(ra) # 80004584 <log_write>
      brelse(bp);
    800038e0:	854a                	mv	a0,s2
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	a20080e7          	jalr	-1504(ra) # 80003302 <brelse>
      return iget(dev, inum);
    800038ea:	85da                	mv	a1,s6
    800038ec:	8556                	mv	a0,s5
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	db4080e7          	jalr	-588(ra) # 800036a2 <iget>
}
    800038f6:	60a6                	ld	ra,72(sp)
    800038f8:	6406                	ld	s0,64(sp)
    800038fa:	74e2                	ld	s1,56(sp)
    800038fc:	7942                	ld	s2,48(sp)
    800038fe:	79a2                	ld	s3,40(sp)
    80003900:	7a02                	ld	s4,32(sp)
    80003902:	6ae2                	ld	s5,24(sp)
    80003904:	6b42                	ld	s6,16(sp)
    80003906:	6ba2                	ld	s7,8(sp)
    80003908:	6161                	addi	sp,sp,80
    8000390a:	8082                	ret

000000008000390c <iupdate>:
{
    8000390c:	1101                	addi	sp,sp,-32
    8000390e:	ec06                	sd	ra,24(sp)
    80003910:	e822                	sd	s0,16(sp)
    80003912:	e426                	sd	s1,8(sp)
    80003914:	e04a                	sd	s2,0(sp)
    80003916:	1000                	addi	s0,sp,32
    80003918:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000391a:	415c                	lw	a5,4(a0)
    8000391c:	0047d79b          	srliw	a5,a5,0x4
    80003920:	0001c597          	auipc	a1,0x1c
    80003924:	4a05a583          	lw	a1,1184(a1) # 8001fdc0 <sb+0x18>
    80003928:	9dbd                	addw	a1,a1,a5
    8000392a:	4108                	lw	a0,0(a0)
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	8a6080e7          	jalr	-1882(ra) # 800031d2 <bread>
    80003934:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003936:	05850793          	addi	a5,a0,88
    8000393a:	40c8                	lw	a0,4(s1)
    8000393c:	893d                	andi	a0,a0,15
    8000393e:	051a                	slli	a0,a0,0x6
    80003940:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003942:	04449703          	lh	a4,68(s1)
    80003946:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000394a:	04649703          	lh	a4,70(s1)
    8000394e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003952:	04849703          	lh	a4,72(s1)
    80003956:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000395a:	04a49703          	lh	a4,74(s1)
    8000395e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003962:	44f8                	lw	a4,76(s1)
    80003964:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003966:	03400613          	li	a2,52
    8000396a:	05048593          	addi	a1,s1,80
    8000396e:	0531                	addi	a0,a0,12
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	3aa080e7          	jalr	938(ra) # 80000d1a <memmove>
  log_write(bp);
    80003978:	854a                	mv	a0,s2
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	c0a080e7          	jalr	-1014(ra) # 80004584 <log_write>
  brelse(bp);
    80003982:	854a                	mv	a0,s2
    80003984:	00000097          	auipc	ra,0x0
    80003988:	97e080e7          	jalr	-1666(ra) # 80003302 <brelse>
}
    8000398c:	60e2                	ld	ra,24(sp)
    8000398e:	6442                	ld	s0,16(sp)
    80003990:	64a2                	ld	s1,8(sp)
    80003992:	6902                	ld	s2,0(sp)
    80003994:	6105                	addi	sp,sp,32
    80003996:	8082                	ret

0000000080003998 <idup>:
{
    80003998:	1101                	addi	sp,sp,-32
    8000399a:	ec06                	sd	ra,24(sp)
    8000399c:	e822                	sd	s0,16(sp)
    8000399e:	e426                	sd	s1,8(sp)
    800039a0:	1000                	addi	s0,sp,32
    800039a2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039a4:	0001c517          	auipc	a0,0x1c
    800039a8:	42450513          	addi	a0,a0,1060 # 8001fdc8 <itable>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	216080e7          	jalr	534(ra) # 80000bc2 <acquire>
  ip->ref++;
    800039b4:	449c                	lw	a5,8(s1)
    800039b6:	2785                	addiw	a5,a5,1
    800039b8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ba:	0001c517          	auipc	a0,0x1c
    800039be:	40e50513          	addi	a0,a0,1038 # 8001fdc8 <itable>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	2b4080e7          	jalr	692(ra) # 80000c76 <release>
}
    800039ca:	8526                	mv	a0,s1
    800039cc:	60e2                	ld	ra,24(sp)
    800039ce:	6442                	ld	s0,16(sp)
    800039d0:	64a2                	ld	s1,8(sp)
    800039d2:	6105                	addi	sp,sp,32
    800039d4:	8082                	ret

00000000800039d6 <ilock>:
{
    800039d6:	1101                	addi	sp,sp,-32
    800039d8:	ec06                	sd	ra,24(sp)
    800039da:	e822                	sd	s0,16(sp)
    800039dc:	e426                	sd	s1,8(sp)
    800039de:	e04a                	sd	s2,0(sp)
    800039e0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039e2:	c115                	beqz	a0,80003a06 <ilock+0x30>
    800039e4:	84aa                	mv	s1,a0
    800039e6:	451c                	lw	a5,8(a0)
    800039e8:	00f05f63          	blez	a5,80003a06 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039ec:	0541                	addi	a0,a0,16
    800039ee:	00001097          	auipc	ra,0x1
    800039f2:	cb6080e7          	jalr	-842(ra) # 800046a4 <acquiresleep>
  if(ip->valid == 0){
    800039f6:	40bc                	lw	a5,64(s1)
    800039f8:	cf99                	beqz	a5,80003a16 <ilock+0x40>
}
    800039fa:	60e2                	ld	ra,24(sp)
    800039fc:	6442                	ld	s0,16(sp)
    800039fe:	64a2                	ld	s1,8(sp)
    80003a00:	6902                	ld	s2,0(sp)
    80003a02:	6105                	addi	sp,sp,32
    80003a04:	8082                	ret
    panic("ilock");
    80003a06:	00005517          	auipc	a0,0x5
    80003a0a:	e0a50513          	addi	a0,a0,-502 # 80008810 <syscalls_str+0x190>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	b1c080e7          	jalr	-1252(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a16:	40dc                	lw	a5,4(s1)
    80003a18:	0047d79b          	srliw	a5,a5,0x4
    80003a1c:	0001c597          	auipc	a1,0x1c
    80003a20:	3a45a583          	lw	a1,932(a1) # 8001fdc0 <sb+0x18>
    80003a24:	9dbd                	addw	a1,a1,a5
    80003a26:	4088                	lw	a0,0(s1)
    80003a28:	fffff097          	auipc	ra,0xfffff
    80003a2c:	7aa080e7          	jalr	1962(ra) # 800031d2 <bread>
    80003a30:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a32:	05850593          	addi	a1,a0,88
    80003a36:	40dc                	lw	a5,4(s1)
    80003a38:	8bbd                	andi	a5,a5,15
    80003a3a:	079a                	slli	a5,a5,0x6
    80003a3c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a3e:	00059783          	lh	a5,0(a1)
    80003a42:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a46:	00259783          	lh	a5,2(a1)
    80003a4a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a4e:	00459783          	lh	a5,4(a1)
    80003a52:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a56:	00659783          	lh	a5,6(a1)
    80003a5a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a5e:	459c                	lw	a5,8(a1)
    80003a60:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a62:	03400613          	li	a2,52
    80003a66:	05b1                	addi	a1,a1,12
    80003a68:	05048513          	addi	a0,s1,80
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	2ae080e7          	jalr	686(ra) # 80000d1a <memmove>
    brelse(bp);
    80003a74:	854a                	mv	a0,s2
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	88c080e7          	jalr	-1908(ra) # 80003302 <brelse>
    ip->valid = 1;
    80003a7e:	4785                	li	a5,1
    80003a80:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a82:	04449783          	lh	a5,68(s1)
    80003a86:	fbb5                	bnez	a5,800039fa <ilock+0x24>
      panic("ilock: no type");
    80003a88:	00005517          	auipc	a0,0x5
    80003a8c:	d9050513          	addi	a0,a0,-624 # 80008818 <syscalls_str+0x198>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	a9a080e7          	jalr	-1382(ra) # 8000052a <panic>

0000000080003a98 <iunlock>:
{
    80003a98:	1101                	addi	sp,sp,-32
    80003a9a:	ec06                	sd	ra,24(sp)
    80003a9c:	e822                	sd	s0,16(sp)
    80003a9e:	e426                	sd	s1,8(sp)
    80003aa0:	e04a                	sd	s2,0(sp)
    80003aa2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003aa4:	c905                	beqz	a0,80003ad4 <iunlock+0x3c>
    80003aa6:	84aa                	mv	s1,a0
    80003aa8:	01050913          	addi	s2,a0,16
    80003aac:	854a                	mv	a0,s2
    80003aae:	00001097          	auipc	ra,0x1
    80003ab2:	c90080e7          	jalr	-880(ra) # 8000473e <holdingsleep>
    80003ab6:	cd19                	beqz	a0,80003ad4 <iunlock+0x3c>
    80003ab8:	449c                	lw	a5,8(s1)
    80003aba:	00f05d63          	blez	a5,80003ad4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003abe:	854a                	mv	a0,s2
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	c3a080e7          	jalr	-966(ra) # 800046fa <releasesleep>
}
    80003ac8:	60e2                	ld	ra,24(sp)
    80003aca:	6442                	ld	s0,16(sp)
    80003acc:	64a2                	ld	s1,8(sp)
    80003ace:	6902                	ld	s2,0(sp)
    80003ad0:	6105                	addi	sp,sp,32
    80003ad2:	8082                	ret
    panic("iunlock");
    80003ad4:	00005517          	auipc	a0,0x5
    80003ad8:	d5450513          	addi	a0,a0,-684 # 80008828 <syscalls_str+0x1a8>
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	a4e080e7          	jalr	-1458(ra) # 8000052a <panic>

0000000080003ae4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ae4:	7179                	addi	sp,sp,-48
    80003ae6:	f406                	sd	ra,40(sp)
    80003ae8:	f022                	sd	s0,32(sp)
    80003aea:	ec26                	sd	s1,24(sp)
    80003aec:	e84a                	sd	s2,16(sp)
    80003aee:	e44e                	sd	s3,8(sp)
    80003af0:	e052                	sd	s4,0(sp)
    80003af2:	1800                	addi	s0,sp,48
    80003af4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003af6:	05050493          	addi	s1,a0,80
    80003afa:	08050913          	addi	s2,a0,128
    80003afe:	a021                	j	80003b06 <itrunc+0x22>
    80003b00:	0491                	addi	s1,s1,4
    80003b02:	01248d63          	beq	s1,s2,80003b1c <itrunc+0x38>
    if(ip->addrs[i]){
    80003b06:	408c                	lw	a1,0(s1)
    80003b08:	dde5                	beqz	a1,80003b00 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b0a:	0009a503          	lw	a0,0(s3)
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	90a080e7          	jalr	-1782(ra) # 80003418 <bfree>
      ip->addrs[i] = 0;
    80003b16:	0004a023          	sw	zero,0(s1)
    80003b1a:	b7dd                	j	80003b00 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b1c:	0809a583          	lw	a1,128(s3)
    80003b20:	e185                	bnez	a1,80003b40 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b22:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b26:	854e                	mv	a0,s3
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	de4080e7          	jalr	-540(ra) # 8000390c <iupdate>
}
    80003b30:	70a2                	ld	ra,40(sp)
    80003b32:	7402                	ld	s0,32(sp)
    80003b34:	64e2                	ld	s1,24(sp)
    80003b36:	6942                	ld	s2,16(sp)
    80003b38:	69a2                	ld	s3,8(sp)
    80003b3a:	6a02                	ld	s4,0(sp)
    80003b3c:	6145                	addi	sp,sp,48
    80003b3e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b40:	0009a503          	lw	a0,0(s3)
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	68e080e7          	jalr	1678(ra) # 800031d2 <bread>
    80003b4c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b4e:	05850493          	addi	s1,a0,88
    80003b52:	45850913          	addi	s2,a0,1112
    80003b56:	a021                	j	80003b5e <itrunc+0x7a>
    80003b58:	0491                	addi	s1,s1,4
    80003b5a:	01248b63          	beq	s1,s2,80003b70 <itrunc+0x8c>
      if(a[j])
    80003b5e:	408c                	lw	a1,0(s1)
    80003b60:	dde5                	beqz	a1,80003b58 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b62:	0009a503          	lw	a0,0(s3)
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	8b2080e7          	jalr	-1870(ra) # 80003418 <bfree>
    80003b6e:	b7ed                	j	80003b58 <itrunc+0x74>
    brelse(bp);
    80003b70:	8552                	mv	a0,s4
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	790080e7          	jalr	1936(ra) # 80003302 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b7a:	0809a583          	lw	a1,128(s3)
    80003b7e:	0009a503          	lw	a0,0(s3)
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	896080e7          	jalr	-1898(ra) # 80003418 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b8a:	0809a023          	sw	zero,128(s3)
    80003b8e:	bf51                	j	80003b22 <itrunc+0x3e>

0000000080003b90 <iput>:
{
    80003b90:	1101                	addi	sp,sp,-32
    80003b92:	ec06                	sd	ra,24(sp)
    80003b94:	e822                	sd	s0,16(sp)
    80003b96:	e426                	sd	s1,8(sp)
    80003b98:	e04a                	sd	s2,0(sp)
    80003b9a:	1000                	addi	s0,sp,32
    80003b9c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b9e:	0001c517          	auipc	a0,0x1c
    80003ba2:	22a50513          	addi	a0,a0,554 # 8001fdc8 <itable>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	01c080e7          	jalr	28(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bae:	4498                	lw	a4,8(s1)
    80003bb0:	4785                	li	a5,1
    80003bb2:	02f70363          	beq	a4,a5,80003bd8 <iput+0x48>
  ip->ref--;
    80003bb6:	449c                	lw	a5,8(s1)
    80003bb8:	37fd                	addiw	a5,a5,-1
    80003bba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bbc:	0001c517          	auipc	a0,0x1c
    80003bc0:	20c50513          	addi	a0,a0,524 # 8001fdc8 <itable>
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	0b2080e7          	jalr	178(ra) # 80000c76 <release>
}
    80003bcc:	60e2                	ld	ra,24(sp)
    80003bce:	6442                	ld	s0,16(sp)
    80003bd0:	64a2                	ld	s1,8(sp)
    80003bd2:	6902                	ld	s2,0(sp)
    80003bd4:	6105                	addi	sp,sp,32
    80003bd6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bd8:	40bc                	lw	a5,64(s1)
    80003bda:	dff1                	beqz	a5,80003bb6 <iput+0x26>
    80003bdc:	04a49783          	lh	a5,74(s1)
    80003be0:	fbf9                	bnez	a5,80003bb6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003be2:	01048913          	addi	s2,s1,16
    80003be6:	854a                	mv	a0,s2
    80003be8:	00001097          	auipc	ra,0x1
    80003bec:	abc080e7          	jalr	-1348(ra) # 800046a4 <acquiresleep>
    release(&itable.lock);
    80003bf0:	0001c517          	auipc	a0,0x1c
    80003bf4:	1d850513          	addi	a0,a0,472 # 8001fdc8 <itable>
    80003bf8:	ffffd097          	auipc	ra,0xffffd
    80003bfc:	07e080e7          	jalr	126(ra) # 80000c76 <release>
    itrunc(ip);
    80003c00:	8526                	mv	a0,s1
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	ee2080e7          	jalr	-286(ra) # 80003ae4 <itrunc>
    ip->type = 0;
    80003c0a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c0e:	8526                	mv	a0,s1
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	cfc080e7          	jalr	-772(ra) # 8000390c <iupdate>
    ip->valid = 0;
    80003c18:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	00001097          	auipc	ra,0x1
    80003c22:	adc080e7          	jalr	-1316(ra) # 800046fa <releasesleep>
    acquire(&itable.lock);
    80003c26:	0001c517          	auipc	a0,0x1c
    80003c2a:	1a250513          	addi	a0,a0,418 # 8001fdc8 <itable>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	f94080e7          	jalr	-108(ra) # 80000bc2 <acquire>
    80003c36:	b741                	j	80003bb6 <iput+0x26>

0000000080003c38 <iunlockput>:
{
    80003c38:	1101                	addi	sp,sp,-32
    80003c3a:	ec06                	sd	ra,24(sp)
    80003c3c:	e822                	sd	s0,16(sp)
    80003c3e:	e426                	sd	s1,8(sp)
    80003c40:	1000                	addi	s0,sp,32
    80003c42:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	e54080e7          	jalr	-428(ra) # 80003a98 <iunlock>
  iput(ip);
    80003c4c:	8526                	mv	a0,s1
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	f42080e7          	jalr	-190(ra) # 80003b90 <iput>
}
    80003c56:	60e2                	ld	ra,24(sp)
    80003c58:	6442                	ld	s0,16(sp)
    80003c5a:	64a2                	ld	s1,8(sp)
    80003c5c:	6105                	addi	sp,sp,32
    80003c5e:	8082                	ret

0000000080003c60 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c60:	1141                	addi	sp,sp,-16
    80003c62:	e422                	sd	s0,8(sp)
    80003c64:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c66:	411c                	lw	a5,0(a0)
    80003c68:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c6a:	415c                	lw	a5,4(a0)
    80003c6c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c6e:	04451783          	lh	a5,68(a0)
    80003c72:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c76:	04a51783          	lh	a5,74(a0)
    80003c7a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c7e:	04c56783          	lwu	a5,76(a0)
    80003c82:	e99c                	sd	a5,16(a1)
}
    80003c84:	6422                	ld	s0,8(sp)
    80003c86:	0141                	addi	sp,sp,16
    80003c88:	8082                	ret

0000000080003c8a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c8a:	457c                	lw	a5,76(a0)
    80003c8c:	0ed7e963          	bltu	a5,a3,80003d7e <readi+0xf4>
{
    80003c90:	7159                	addi	sp,sp,-112
    80003c92:	f486                	sd	ra,104(sp)
    80003c94:	f0a2                	sd	s0,96(sp)
    80003c96:	eca6                	sd	s1,88(sp)
    80003c98:	e8ca                	sd	s2,80(sp)
    80003c9a:	e4ce                	sd	s3,72(sp)
    80003c9c:	e0d2                	sd	s4,64(sp)
    80003c9e:	fc56                	sd	s5,56(sp)
    80003ca0:	f85a                	sd	s6,48(sp)
    80003ca2:	f45e                	sd	s7,40(sp)
    80003ca4:	f062                	sd	s8,32(sp)
    80003ca6:	ec66                	sd	s9,24(sp)
    80003ca8:	e86a                	sd	s10,16(sp)
    80003caa:	e46e                	sd	s11,8(sp)
    80003cac:	1880                	addi	s0,sp,112
    80003cae:	8baa                	mv	s7,a0
    80003cb0:	8c2e                	mv	s8,a1
    80003cb2:	8ab2                	mv	s5,a2
    80003cb4:	84b6                	mv	s1,a3
    80003cb6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cb8:	9f35                	addw	a4,a4,a3
    return 0;
    80003cba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cbc:	0ad76063          	bltu	a4,a3,80003d5c <readi+0xd2>
  if(off + n > ip->size)
    80003cc0:	00e7f463          	bgeu	a5,a4,80003cc8 <readi+0x3e>
    n = ip->size - off;
    80003cc4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cc8:	0a0b0963          	beqz	s6,80003d7a <readi+0xf0>
    80003ccc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cce:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cd2:	5cfd                	li	s9,-1
    80003cd4:	a82d                	j	80003d0e <readi+0x84>
    80003cd6:	020a1d93          	slli	s11,s4,0x20
    80003cda:	020ddd93          	srli	s11,s11,0x20
    80003cde:	05890793          	addi	a5,s2,88
    80003ce2:	86ee                	mv	a3,s11
    80003ce4:	963e                	add	a2,a2,a5
    80003ce6:	85d6                	mv	a1,s5
    80003ce8:	8562                	mv	a0,s8
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	974080e7          	jalr	-1676(ra) # 8000265e <either_copyout>
    80003cf2:	05950d63          	beq	a0,s9,80003d4c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cf6:	854a                	mv	a0,s2
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	60a080e7          	jalr	1546(ra) # 80003302 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d00:	013a09bb          	addw	s3,s4,s3
    80003d04:	009a04bb          	addw	s1,s4,s1
    80003d08:	9aee                	add	s5,s5,s11
    80003d0a:	0569f763          	bgeu	s3,s6,80003d58 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d0e:	000ba903          	lw	s2,0(s7)
    80003d12:	00a4d59b          	srliw	a1,s1,0xa
    80003d16:	855e                	mv	a0,s7
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	8ae080e7          	jalr	-1874(ra) # 800035c6 <bmap>
    80003d20:	0005059b          	sext.w	a1,a0
    80003d24:	854a                	mv	a0,s2
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	4ac080e7          	jalr	1196(ra) # 800031d2 <bread>
    80003d2e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d30:	3ff4f613          	andi	a2,s1,1023
    80003d34:	40cd07bb          	subw	a5,s10,a2
    80003d38:	413b073b          	subw	a4,s6,s3
    80003d3c:	8a3e                	mv	s4,a5
    80003d3e:	2781                	sext.w	a5,a5
    80003d40:	0007069b          	sext.w	a3,a4
    80003d44:	f8f6f9e3          	bgeu	a3,a5,80003cd6 <readi+0x4c>
    80003d48:	8a3a                	mv	s4,a4
    80003d4a:	b771                	j	80003cd6 <readi+0x4c>
      brelse(bp);
    80003d4c:	854a                	mv	a0,s2
    80003d4e:	fffff097          	auipc	ra,0xfffff
    80003d52:	5b4080e7          	jalr	1460(ra) # 80003302 <brelse>
      tot = -1;
    80003d56:	59fd                	li	s3,-1
  }
  return tot;
    80003d58:	0009851b          	sext.w	a0,s3
}
    80003d5c:	70a6                	ld	ra,104(sp)
    80003d5e:	7406                	ld	s0,96(sp)
    80003d60:	64e6                	ld	s1,88(sp)
    80003d62:	6946                	ld	s2,80(sp)
    80003d64:	69a6                	ld	s3,72(sp)
    80003d66:	6a06                	ld	s4,64(sp)
    80003d68:	7ae2                	ld	s5,56(sp)
    80003d6a:	7b42                	ld	s6,48(sp)
    80003d6c:	7ba2                	ld	s7,40(sp)
    80003d6e:	7c02                	ld	s8,32(sp)
    80003d70:	6ce2                	ld	s9,24(sp)
    80003d72:	6d42                	ld	s10,16(sp)
    80003d74:	6da2                	ld	s11,8(sp)
    80003d76:	6165                	addi	sp,sp,112
    80003d78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d7a:	89da                	mv	s3,s6
    80003d7c:	bff1                	j	80003d58 <readi+0xce>
    return 0;
    80003d7e:	4501                	li	a0,0
}
    80003d80:	8082                	ret

0000000080003d82 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d82:	457c                	lw	a5,76(a0)
    80003d84:	10d7e863          	bltu	a5,a3,80003e94 <writei+0x112>
{
    80003d88:	7159                	addi	sp,sp,-112
    80003d8a:	f486                	sd	ra,104(sp)
    80003d8c:	f0a2                	sd	s0,96(sp)
    80003d8e:	eca6                	sd	s1,88(sp)
    80003d90:	e8ca                	sd	s2,80(sp)
    80003d92:	e4ce                	sd	s3,72(sp)
    80003d94:	e0d2                	sd	s4,64(sp)
    80003d96:	fc56                	sd	s5,56(sp)
    80003d98:	f85a                	sd	s6,48(sp)
    80003d9a:	f45e                	sd	s7,40(sp)
    80003d9c:	f062                	sd	s8,32(sp)
    80003d9e:	ec66                	sd	s9,24(sp)
    80003da0:	e86a                	sd	s10,16(sp)
    80003da2:	e46e                	sd	s11,8(sp)
    80003da4:	1880                	addi	s0,sp,112
    80003da6:	8b2a                	mv	s6,a0
    80003da8:	8c2e                	mv	s8,a1
    80003daa:	8ab2                	mv	s5,a2
    80003dac:	8936                	mv	s2,a3
    80003dae:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003db0:	00e687bb          	addw	a5,a3,a4
    80003db4:	0ed7e263          	bltu	a5,a3,80003e98 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003db8:	00043737          	lui	a4,0x43
    80003dbc:	0ef76063          	bltu	a4,a5,80003e9c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dc0:	0c0b8863          	beqz	s7,80003e90 <writei+0x10e>
    80003dc4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dca:	5cfd                	li	s9,-1
    80003dcc:	a091                	j	80003e10 <writei+0x8e>
    80003dce:	02099d93          	slli	s11,s3,0x20
    80003dd2:	020ddd93          	srli	s11,s11,0x20
    80003dd6:	05848793          	addi	a5,s1,88
    80003dda:	86ee                	mv	a3,s11
    80003ddc:	8656                	mv	a2,s5
    80003dde:	85e2                	mv	a1,s8
    80003de0:	953e                	add	a0,a0,a5
    80003de2:	fffff097          	auipc	ra,0xfffff
    80003de6:	8d2080e7          	jalr	-1838(ra) # 800026b4 <either_copyin>
    80003dea:	07950263          	beq	a0,s9,80003e4e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dee:	8526                	mv	a0,s1
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	794080e7          	jalr	1940(ra) # 80004584 <log_write>
    brelse(bp);
    80003df8:	8526                	mv	a0,s1
    80003dfa:	fffff097          	auipc	ra,0xfffff
    80003dfe:	508080e7          	jalr	1288(ra) # 80003302 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e02:	01498a3b          	addw	s4,s3,s4
    80003e06:	0129893b          	addw	s2,s3,s2
    80003e0a:	9aee                	add	s5,s5,s11
    80003e0c:	057a7663          	bgeu	s4,s7,80003e58 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e10:	000b2483          	lw	s1,0(s6)
    80003e14:	00a9559b          	srliw	a1,s2,0xa
    80003e18:	855a                	mv	a0,s6
    80003e1a:	fffff097          	auipc	ra,0xfffff
    80003e1e:	7ac080e7          	jalr	1964(ra) # 800035c6 <bmap>
    80003e22:	0005059b          	sext.w	a1,a0
    80003e26:	8526                	mv	a0,s1
    80003e28:	fffff097          	auipc	ra,0xfffff
    80003e2c:	3aa080e7          	jalr	938(ra) # 800031d2 <bread>
    80003e30:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e32:	3ff97513          	andi	a0,s2,1023
    80003e36:	40ad07bb          	subw	a5,s10,a0
    80003e3a:	414b873b          	subw	a4,s7,s4
    80003e3e:	89be                	mv	s3,a5
    80003e40:	2781                	sext.w	a5,a5
    80003e42:	0007069b          	sext.w	a3,a4
    80003e46:	f8f6f4e3          	bgeu	a3,a5,80003dce <writei+0x4c>
    80003e4a:	89ba                	mv	s3,a4
    80003e4c:	b749                	j	80003dce <writei+0x4c>
      brelse(bp);
    80003e4e:	8526                	mv	a0,s1
    80003e50:	fffff097          	auipc	ra,0xfffff
    80003e54:	4b2080e7          	jalr	1202(ra) # 80003302 <brelse>
  }

  if(off > ip->size)
    80003e58:	04cb2783          	lw	a5,76(s6)
    80003e5c:	0127f463          	bgeu	a5,s2,80003e64 <writei+0xe2>
    ip->size = off;
    80003e60:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e64:	855a                	mv	a0,s6
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	aa6080e7          	jalr	-1370(ra) # 8000390c <iupdate>

  return tot;
    80003e6e:	000a051b          	sext.w	a0,s4
}
    80003e72:	70a6                	ld	ra,104(sp)
    80003e74:	7406                	ld	s0,96(sp)
    80003e76:	64e6                	ld	s1,88(sp)
    80003e78:	6946                	ld	s2,80(sp)
    80003e7a:	69a6                	ld	s3,72(sp)
    80003e7c:	6a06                	ld	s4,64(sp)
    80003e7e:	7ae2                	ld	s5,56(sp)
    80003e80:	7b42                	ld	s6,48(sp)
    80003e82:	7ba2                	ld	s7,40(sp)
    80003e84:	7c02                	ld	s8,32(sp)
    80003e86:	6ce2                	ld	s9,24(sp)
    80003e88:	6d42                	ld	s10,16(sp)
    80003e8a:	6da2                	ld	s11,8(sp)
    80003e8c:	6165                	addi	sp,sp,112
    80003e8e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e90:	8a5e                	mv	s4,s7
    80003e92:	bfc9                	j	80003e64 <writei+0xe2>
    return -1;
    80003e94:	557d                	li	a0,-1
}
    80003e96:	8082                	ret
    return -1;
    80003e98:	557d                	li	a0,-1
    80003e9a:	bfe1                	j	80003e72 <writei+0xf0>
    return -1;
    80003e9c:	557d                	li	a0,-1
    80003e9e:	bfd1                	j	80003e72 <writei+0xf0>

0000000080003ea0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ea0:	1141                	addi	sp,sp,-16
    80003ea2:	e406                	sd	ra,8(sp)
    80003ea4:	e022                	sd	s0,0(sp)
    80003ea6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ea8:	4639                	li	a2,14
    80003eaa:	ffffd097          	auipc	ra,0xffffd
    80003eae:	eec080e7          	jalr	-276(ra) # 80000d96 <strncmp>
}
    80003eb2:	60a2                	ld	ra,8(sp)
    80003eb4:	6402                	ld	s0,0(sp)
    80003eb6:	0141                	addi	sp,sp,16
    80003eb8:	8082                	ret

0000000080003eba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003eba:	7139                	addi	sp,sp,-64
    80003ebc:	fc06                	sd	ra,56(sp)
    80003ebe:	f822                	sd	s0,48(sp)
    80003ec0:	f426                	sd	s1,40(sp)
    80003ec2:	f04a                	sd	s2,32(sp)
    80003ec4:	ec4e                	sd	s3,24(sp)
    80003ec6:	e852                	sd	s4,16(sp)
    80003ec8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eca:	04451703          	lh	a4,68(a0)
    80003ece:	4785                	li	a5,1
    80003ed0:	00f71a63          	bne	a4,a5,80003ee4 <dirlookup+0x2a>
    80003ed4:	892a                	mv	s2,a0
    80003ed6:	89ae                	mv	s3,a1
    80003ed8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eda:	457c                	lw	a5,76(a0)
    80003edc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ede:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee0:	e79d                	bnez	a5,80003f0e <dirlookup+0x54>
    80003ee2:	a8a5                	j	80003f5a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ee4:	00005517          	auipc	a0,0x5
    80003ee8:	94c50513          	addi	a0,a0,-1716 # 80008830 <syscalls_str+0x1b0>
    80003eec:	ffffc097          	auipc	ra,0xffffc
    80003ef0:	63e080e7          	jalr	1598(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003ef4:	00005517          	auipc	a0,0x5
    80003ef8:	95450513          	addi	a0,a0,-1708 # 80008848 <syscalls_str+0x1c8>
    80003efc:	ffffc097          	auipc	ra,0xffffc
    80003f00:	62e080e7          	jalr	1582(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f04:	24c1                	addiw	s1,s1,16
    80003f06:	04c92783          	lw	a5,76(s2)
    80003f0a:	04f4f763          	bgeu	s1,a5,80003f58 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0e:	4741                	li	a4,16
    80003f10:	86a6                	mv	a3,s1
    80003f12:	fc040613          	addi	a2,s0,-64
    80003f16:	4581                	li	a1,0
    80003f18:	854a                	mv	a0,s2
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	d70080e7          	jalr	-656(ra) # 80003c8a <readi>
    80003f22:	47c1                	li	a5,16
    80003f24:	fcf518e3          	bne	a0,a5,80003ef4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f28:	fc045783          	lhu	a5,-64(s0)
    80003f2c:	dfe1                	beqz	a5,80003f04 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f2e:	fc240593          	addi	a1,s0,-62
    80003f32:	854e                	mv	a0,s3
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	f6c080e7          	jalr	-148(ra) # 80003ea0 <namecmp>
    80003f3c:	f561                	bnez	a0,80003f04 <dirlookup+0x4a>
      if(poff)
    80003f3e:	000a0463          	beqz	s4,80003f46 <dirlookup+0x8c>
        *poff = off;
    80003f42:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f46:	fc045583          	lhu	a1,-64(s0)
    80003f4a:	00092503          	lw	a0,0(s2)
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	754080e7          	jalr	1876(ra) # 800036a2 <iget>
    80003f56:	a011                	j	80003f5a <dirlookup+0xa0>
  return 0;
    80003f58:	4501                	li	a0,0
}
    80003f5a:	70e2                	ld	ra,56(sp)
    80003f5c:	7442                	ld	s0,48(sp)
    80003f5e:	74a2                	ld	s1,40(sp)
    80003f60:	7902                	ld	s2,32(sp)
    80003f62:	69e2                	ld	s3,24(sp)
    80003f64:	6a42                	ld	s4,16(sp)
    80003f66:	6121                	addi	sp,sp,64
    80003f68:	8082                	ret

0000000080003f6a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f6a:	711d                	addi	sp,sp,-96
    80003f6c:	ec86                	sd	ra,88(sp)
    80003f6e:	e8a2                	sd	s0,80(sp)
    80003f70:	e4a6                	sd	s1,72(sp)
    80003f72:	e0ca                	sd	s2,64(sp)
    80003f74:	fc4e                	sd	s3,56(sp)
    80003f76:	f852                	sd	s4,48(sp)
    80003f78:	f456                	sd	s5,40(sp)
    80003f7a:	f05a                	sd	s6,32(sp)
    80003f7c:	ec5e                	sd	s7,24(sp)
    80003f7e:	e862                	sd	s8,16(sp)
    80003f80:	e466                	sd	s9,8(sp)
    80003f82:	1080                	addi	s0,sp,96
    80003f84:	84aa                	mv	s1,a0
    80003f86:	8aae                	mv	s5,a1
    80003f88:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f8a:	00054703          	lbu	a4,0(a0)
    80003f8e:	02f00793          	li	a5,47
    80003f92:	02f70363          	beq	a4,a5,80003fb8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f96:	ffffe097          	auipc	ra,0xffffe
    80003f9a:	9fc080e7          	jalr	-1540(ra) # 80001992 <myproc>
    80003f9e:	15053503          	ld	a0,336(a0)
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	9f6080e7          	jalr	-1546(ra) # 80003998 <idup>
    80003faa:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fac:	02f00913          	li	s2,47
  len = path - s;
    80003fb0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003fb2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fb4:	4b85                	li	s7,1
    80003fb6:	a865                	j	8000406e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fb8:	4585                	li	a1,1
    80003fba:	4505                	li	a0,1
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	6e6080e7          	jalr	1766(ra) # 800036a2 <iget>
    80003fc4:	89aa                	mv	s3,a0
    80003fc6:	b7dd                	j	80003fac <namex+0x42>
      iunlockput(ip);
    80003fc8:	854e                	mv	a0,s3
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	c6e080e7          	jalr	-914(ra) # 80003c38 <iunlockput>
      return 0;
    80003fd2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fd4:	854e                	mv	a0,s3
    80003fd6:	60e6                	ld	ra,88(sp)
    80003fd8:	6446                	ld	s0,80(sp)
    80003fda:	64a6                	ld	s1,72(sp)
    80003fdc:	6906                	ld	s2,64(sp)
    80003fde:	79e2                	ld	s3,56(sp)
    80003fe0:	7a42                	ld	s4,48(sp)
    80003fe2:	7aa2                	ld	s5,40(sp)
    80003fe4:	7b02                	ld	s6,32(sp)
    80003fe6:	6be2                	ld	s7,24(sp)
    80003fe8:	6c42                	ld	s8,16(sp)
    80003fea:	6ca2                	ld	s9,8(sp)
    80003fec:	6125                	addi	sp,sp,96
    80003fee:	8082                	ret
      iunlock(ip);
    80003ff0:	854e                	mv	a0,s3
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	aa6080e7          	jalr	-1370(ra) # 80003a98 <iunlock>
      return ip;
    80003ffa:	bfe9                	j	80003fd4 <namex+0x6a>
      iunlockput(ip);
    80003ffc:	854e                	mv	a0,s3
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	c3a080e7          	jalr	-966(ra) # 80003c38 <iunlockput>
      return 0;
    80004006:	89e6                	mv	s3,s9
    80004008:	b7f1                	j	80003fd4 <namex+0x6a>
  len = path - s;
    8000400a:	40b48633          	sub	a2,s1,a1
    8000400e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004012:	099c5463          	bge	s8,s9,8000409a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004016:	4639                	li	a2,14
    80004018:	8552                	mv	a0,s4
    8000401a:	ffffd097          	auipc	ra,0xffffd
    8000401e:	d00080e7          	jalr	-768(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004022:	0004c783          	lbu	a5,0(s1)
    80004026:	01279763          	bne	a5,s2,80004034 <namex+0xca>
    path++;
    8000402a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000402c:	0004c783          	lbu	a5,0(s1)
    80004030:	ff278de3          	beq	a5,s2,8000402a <namex+0xc0>
    ilock(ip);
    80004034:	854e                	mv	a0,s3
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	9a0080e7          	jalr	-1632(ra) # 800039d6 <ilock>
    if(ip->type != T_DIR){
    8000403e:	04499783          	lh	a5,68(s3)
    80004042:	f97793e3          	bne	a5,s7,80003fc8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004046:	000a8563          	beqz	s5,80004050 <namex+0xe6>
    8000404a:	0004c783          	lbu	a5,0(s1)
    8000404e:	d3cd                	beqz	a5,80003ff0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004050:	865a                	mv	a2,s6
    80004052:	85d2                	mv	a1,s4
    80004054:	854e                	mv	a0,s3
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	e64080e7          	jalr	-412(ra) # 80003eba <dirlookup>
    8000405e:	8caa                	mv	s9,a0
    80004060:	dd51                	beqz	a0,80003ffc <namex+0x92>
    iunlockput(ip);
    80004062:	854e                	mv	a0,s3
    80004064:	00000097          	auipc	ra,0x0
    80004068:	bd4080e7          	jalr	-1068(ra) # 80003c38 <iunlockput>
    ip = next;
    8000406c:	89e6                	mv	s3,s9
  while(*path == '/')
    8000406e:	0004c783          	lbu	a5,0(s1)
    80004072:	05279763          	bne	a5,s2,800040c0 <namex+0x156>
    path++;
    80004076:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004078:	0004c783          	lbu	a5,0(s1)
    8000407c:	ff278de3          	beq	a5,s2,80004076 <namex+0x10c>
  if(*path == 0)
    80004080:	c79d                	beqz	a5,800040ae <namex+0x144>
    path++;
    80004082:	85a6                	mv	a1,s1
  len = path - s;
    80004084:	8cda                	mv	s9,s6
    80004086:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004088:	01278963          	beq	a5,s2,8000409a <namex+0x130>
    8000408c:	dfbd                	beqz	a5,8000400a <namex+0xa0>
    path++;
    8000408e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004090:	0004c783          	lbu	a5,0(s1)
    80004094:	ff279ce3          	bne	a5,s2,8000408c <namex+0x122>
    80004098:	bf8d                	j	8000400a <namex+0xa0>
    memmove(name, s, len);
    8000409a:	2601                	sext.w	a2,a2
    8000409c:	8552                	mv	a0,s4
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	c7c080e7          	jalr	-900(ra) # 80000d1a <memmove>
    name[len] = 0;
    800040a6:	9cd2                	add	s9,s9,s4
    800040a8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800040ac:	bf9d                	j	80004022 <namex+0xb8>
  if(nameiparent){
    800040ae:	f20a83e3          	beqz	s5,80003fd4 <namex+0x6a>
    iput(ip);
    800040b2:	854e                	mv	a0,s3
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	adc080e7          	jalr	-1316(ra) # 80003b90 <iput>
    return 0;
    800040bc:	4981                	li	s3,0
    800040be:	bf19                	j	80003fd4 <namex+0x6a>
  if(*path == 0)
    800040c0:	d7fd                	beqz	a5,800040ae <namex+0x144>
  while(*path != '/' && *path != 0)
    800040c2:	0004c783          	lbu	a5,0(s1)
    800040c6:	85a6                	mv	a1,s1
    800040c8:	b7d1                	j	8000408c <namex+0x122>

00000000800040ca <dirlink>:
{
    800040ca:	7139                	addi	sp,sp,-64
    800040cc:	fc06                	sd	ra,56(sp)
    800040ce:	f822                	sd	s0,48(sp)
    800040d0:	f426                	sd	s1,40(sp)
    800040d2:	f04a                	sd	s2,32(sp)
    800040d4:	ec4e                	sd	s3,24(sp)
    800040d6:	e852                	sd	s4,16(sp)
    800040d8:	0080                	addi	s0,sp,64
    800040da:	892a                	mv	s2,a0
    800040dc:	8a2e                	mv	s4,a1
    800040de:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040e0:	4601                	li	a2,0
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	dd8080e7          	jalr	-552(ra) # 80003eba <dirlookup>
    800040ea:	e93d                	bnez	a0,80004160 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ec:	04c92483          	lw	s1,76(s2)
    800040f0:	c49d                	beqz	s1,8000411e <dirlink+0x54>
    800040f2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f4:	4741                	li	a4,16
    800040f6:	86a6                	mv	a3,s1
    800040f8:	fc040613          	addi	a2,s0,-64
    800040fc:	4581                	li	a1,0
    800040fe:	854a                	mv	a0,s2
    80004100:	00000097          	auipc	ra,0x0
    80004104:	b8a080e7          	jalr	-1142(ra) # 80003c8a <readi>
    80004108:	47c1                	li	a5,16
    8000410a:	06f51163          	bne	a0,a5,8000416c <dirlink+0xa2>
    if(de.inum == 0)
    8000410e:	fc045783          	lhu	a5,-64(s0)
    80004112:	c791                	beqz	a5,8000411e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004114:	24c1                	addiw	s1,s1,16
    80004116:	04c92783          	lw	a5,76(s2)
    8000411a:	fcf4ede3          	bltu	s1,a5,800040f4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000411e:	4639                	li	a2,14
    80004120:	85d2                	mv	a1,s4
    80004122:	fc240513          	addi	a0,s0,-62
    80004126:	ffffd097          	auipc	ra,0xffffd
    8000412a:	cac080e7          	jalr	-852(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    8000412e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004132:	4741                	li	a4,16
    80004134:	86a6                	mv	a3,s1
    80004136:	fc040613          	addi	a2,s0,-64
    8000413a:	4581                	li	a1,0
    8000413c:	854a                	mv	a0,s2
    8000413e:	00000097          	auipc	ra,0x0
    80004142:	c44080e7          	jalr	-956(ra) # 80003d82 <writei>
    80004146:	872a                	mv	a4,a0
    80004148:	47c1                	li	a5,16
  return 0;
    8000414a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000414c:	02f71863          	bne	a4,a5,8000417c <dirlink+0xb2>
}
    80004150:	70e2                	ld	ra,56(sp)
    80004152:	7442                	ld	s0,48(sp)
    80004154:	74a2                	ld	s1,40(sp)
    80004156:	7902                	ld	s2,32(sp)
    80004158:	69e2                	ld	s3,24(sp)
    8000415a:	6a42                	ld	s4,16(sp)
    8000415c:	6121                	addi	sp,sp,64
    8000415e:	8082                	ret
    iput(ip);
    80004160:	00000097          	auipc	ra,0x0
    80004164:	a30080e7          	jalr	-1488(ra) # 80003b90 <iput>
    return -1;
    80004168:	557d                	li	a0,-1
    8000416a:	b7dd                	j	80004150 <dirlink+0x86>
      panic("dirlink read");
    8000416c:	00004517          	auipc	a0,0x4
    80004170:	6ec50513          	addi	a0,a0,1772 # 80008858 <syscalls_str+0x1d8>
    80004174:	ffffc097          	auipc	ra,0xffffc
    80004178:	3b6080e7          	jalr	950(ra) # 8000052a <panic>
    panic("dirlink");
    8000417c:	00004517          	auipc	a0,0x4
    80004180:	7ec50513          	addi	a0,a0,2028 # 80008968 <syscalls_str+0x2e8>
    80004184:	ffffc097          	auipc	ra,0xffffc
    80004188:	3a6080e7          	jalr	934(ra) # 8000052a <panic>

000000008000418c <namei>:

struct inode*
namei(char *path)
{
    8000418c:	1101                	addi	sp,sp,-32
    8000418e:	ec06                	sd	ra,24(sp)
    80004190:	e822                	sd	s0,16(sp)
    80004192:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004194:	fe040613          	addi	a2,s0,-32
    80004198:	4581                	li	a1,0
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	dd0080e7          	jalr	-560(ra) # 80003f6a <namex>
}
    800041a2:	60e2                	ld	ra,24(sp)
    800041a4:	6442                	ld	s0,16(sp)
    800041a6:	6105                	addi	sp,sp,32
    800041a8:	8082                	ret

00000000800041aa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041aa:	1141                	addi	sp,sp,-16
    800041ac:	e406                	sd	ra,8(sp)
    800041ae:	e022                	sd	s0,0(sp)
    800041b0:	0800                	addi	s0,sp,16
    800041b2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041b4:	4585                	li	a1,1
    800041b6:	00000097          	auipc	ra,0x0
    800041ba:	db4080e7          	jalr	-588(ra) # 80003f6a <namex>
}
    800041be:	60a2                	ld	ra,8(sp)
    800041c0:	6402                	ld	s0,0(sp)
    800041c2:	0141                	addi	sp,sp,16
    800041c4:	8082                	ret

00000000800041c6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041c6:	1101                	addi	sp,sp,-32
    800041c8:	ec06                	sd	ra,24(sp)
    800041ca:	e822                	sd	s0,16(sp)
    800041cc:	e426                	sd	s1,8(sp)
    800041ce:	e04a                	sd	s2,0(sp)
    800041d0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041d2:	0001d917          	auipc	s2,0x1d
    800041d6:	69e90913          	addi	s2,s2,1694 # 80021870 <log>
    800041da:	01892583          	lw	a1,24(s2)
    800041de:	02892503          	lw	a0,40(s2)
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	ff0080e7          	jalr	-16(ra) # 800031d2 <bread>
    800041ea:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041ec:	02c92683          	lw	a3,44(s2)
    800041f0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041f2:	02d05863          	blez	a3,80004222 <write_head+0x5c>
    800041f6:	0001d797          	auipc	a5,0x1d
    800041fa:	6aa78793          	addi	a5,a5,1706 # 800218a0 <log+0x30>
    800041fe:	05c50713          	addi	a4,a0,92
    80004202:	36fd                	addiw	a3,a3,-1
    80004204:	02069613          	slli	a2,a3,0x20
    80004208:	01e65693          	srli	a3,a2,0x1e
    8000420c:	0001d617          	auipc	a2,0x1d
    80004210:	69860613          	addi	a2,a2,1688 # 800218a4 <log+0x34>
    80004214:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004216:	4390                	lw	a2,0(a5)
    80004218:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000421a:	0791                	addi	a5,a5,4
    8000421c:	0711                	addi	a4,a4,4
    8000421e:	fed79ce3          	bne	a5,a3,80004216 <write_head+0x50>
  }
  bwrite(buf);
    80004222:	8526                	mv	a0,s1
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	0a0080e7          	jalr	160(ra) # 800032c4 <bwrite>
  brelse(buf);
    8000422c:	8526                	mv	a0,s1
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	0d4080e7          	jalr	212(ra) # 80003302 <brelse>
}
    80004236:	60e2                	ld	ra,24(sp)
    80004238:	6442                	ld	s0,16(sp)
    8000423a:	64a2                	ld	s1,8(sp)
    8000423c:	6902                	ld	s2,0(sp)
    8000423e:	6105                	addi	sp,sp,32
    80004240:	8082                	ret

0000000080004242 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004242:	0001d797          	auipc	a5,0x1d
    80004246:	65a7a783          	lw	a5,1626(a5) # 8002189c <log+0x2c>
    8000424a:	0af05d63          	blez	a5,80004304 <install_trans+0xc2>
{
    8000424e:	7139                	addi	sp,sp,-64
    80004250:	fc06                	sd	ra,56(sp)
    80004252:	f822                	sd	s0,48(sp)
    80004254:	f426                	sd	s1,40(sp)
    80004256:	f04a                	sd	s2,32(sp)
    80004258:	ec4e                	sd	s3,24(sp)
    8000425a:	e852                	sd	s4,16(sp)
    8000425c:	e456                	sd	s5,8(sp)
    8000425e:	e05a                	sd	s6,0(sp)
    80004260:	0080                	addi	s0,sp,64
    80004262:	8b2a                	mv	s6,a0
    80004264:	0001da97          	auipc	s5,0x1d
    80004268:	63ca8a93          	addi	s5,s5,1596 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000426e:	0001d997          	auipc	s3,0x1d
    80004272:	60298993          	addi	s3,s3,1538 # 80021870 <log>
    80004276:	a00d                	j	80004298 <install_trans+0x56>
    brelse(lbuf);
    80004278:	854a                	mv	a0,s2
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	088080e7          	jalr	136(ra) # 80003302 <brelse>
    brelse(dbuf);
    80004282:	8526                	mv	a0,s1
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	07e080e7          	jalr	126(ra) # 80003302 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428c:	2a05                	addiw	s4,s4,1
    8000428e:	0a91                	addi	s5,s5,4
    80004290:	02c9a783          	lw	a5,44(s3)
    80004294:	04fa5e63          	bge	s4,a5,800042f0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004298:	0189a583          	lw	a1,24(s3)
    8000429c:	014585bb          	addw	a1,a1,s4
    800042a0:	2585                	addiw	a1,a1,1
    800042a2:	0289a503          	lw	a0,40(s3)
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	f2c080e7          	jalr	-212(ra) # 800031d2 <bread>
    800042ae:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042b0:	000aa583          	lw	a1,0(s5)
    800042b4:	0289a503          	lw	a0,40(s3)
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	f1a080e7          	jalr	-230(ra) # 800031d2 <bread>
    800042c0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042c2:	40000613          	li	a2,1024
    800042c6:	05890593          	addi	a1,s2,88
    800042ca:	05850513          	addi	a0,a0,88
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	a4c080e7          	jalr	-1460(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800042d6:	8526                	mv	a0,s1
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	fec080e7          	jalr	-20(ra) # 800032c4 <bwrite>
    if(recovering == 0)
    800042e0:	f80b1ce3          	bnez	s6,80004278 <install_trans+0x36>
      bunpin(dbuf);
    800042e4:	8526                	mv	a0,s1
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	0f6080e7          	jalr	246(ra) # 800033dc <bunpin>
    800042ee:	b769                	j	80004278 <install_trans+0x36>
}
    800042f0:	70e2                	ld	ra,56(sp)
    800042f2:	7442                	ld	s0,48(sp)
    800042f4:	74a2                	ld	s1,40(sp)
    800042f6:	7902                	ld	s2,32(sp)
    800042f8:	69e2                	ld	s3,24(sp)
    800042fa:	6a42                	ld	s4,16(sp)
    800042fc:	6aa2                	ld	s5,8(sp)
    800042fe:	6b02                	ld	s6,0(sp)
    80004300:	6121                	addi	sp,sp,64
    80004302:	8082                	ret
    80004304:	8082                	ret

0000000080004306 <initlog>:
{
    80004306:	7179                	addi	sp,sp,-48
    80004308:	f406                	sd	ra,40(sp)
    8000430a:	f022                	sd	s0,32(sp)
    8000430c:	ec26                	sd	s1,24(sp)
    8000430e:	e84a                	sd	s2,16(sp)
    80004310:	e44e                	sd	s3,8(sp)
    80004312:	1800                	addi	s0,sp,48
    80004314:	892a                	mv	s2,a0
    80004316:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004318:	0001d497          	auipc	s1,0x1d
    8000431c:	55848493          	addi	s1,s1,1368 # 80021870 <log>
    80004320:	00004597          	auipc	a1,0x4
    80004324:	54858593          	addi	a1,a1,1352 # 80008868 <syscalls_str+0x1e8>
    80004328:	8526                	mv	a0,s1
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	808080e7          	jalr	-2040(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004332:	0149a583          	lw	a1,20(s3)
    80004336:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004338:	0109a783          	lw	a5,16(s3)
    8000433c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000433e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004342:	854a                	mv	a0,s2
    80004344:	fffff097          	auipc	ra,0xfffff
    80004348:	e8e080e7          	jalr	-370(ra) # 800031d2 <bread>
  log.lh.n = lh->n;
    8000434c:	4d34                	lw	a3,88(a0)
    8000434e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004350:	02d05663          	blez	a3,8000437c <initlog+0x76>
    80004354:	05c50793          	addi	a5,a0,92
    80004358:	0001d717          	auipc	a4,0x1d
    8000435c:	54870713          	addi	a4,a4,1352 # 800218a0 <log+0x30>
    80004360:	36fd                	addiw	a3,a3,-1
    80004362:	02069613          	slli	a2,a3,0x20
    80004366:	01e65693          	srli	a3,a2,0x1e
    8000436a:	06050613          	addi	a2,a0,96
    8000436e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004370:	4390                	lw	a2,0(a5)
    80004372:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004374:	0791                	addi	a5,a5,4
    80004376:	0711                	addi	a4,a4,4
    80004378:	fed79ce3          	bne	a5,a3,80004370 <initlog+0x6a>
  brelse(buf);
    8000437c:	fffff097          	auipc	ra,0xfffff
    80004380:	f86080e7          	jalr	-122(ra) # 80003302 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004384:	4505                	li	a0,1
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	ebc080e7          	jalr	-324(ra) # 80004242 <install_trans>
  log.lh.n = 0;
    8000438e:	0001d797          	auipc	a5,0x1d
    80004392:	5007a723          	sw	zero,1294(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	e30080e7          	jalr	-464(ra) # 800041c6 <write_head>
}
    8000439e:	70a2                	ld	ra,40(sp)
    800043a0:	7402                	ld	s0,32(sp)
    800043a2:	64e2                	ld	s1,24(sp)
    800043a4:	6942                	ld	s2,16(sp)
    800043a6:	69a2                	ld	s3,8(sp)
    800043a8:	6145                	addi	sp,sp,48
    800043aa:	8082                	ret

00000000800043ac <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043ac:	1101                	addi	sp,sp,-32
    800043ae:	ec06                	sd	ra,24(sp)
    800043b0:	e822                	sd	s0,16(sp)
    800043b2:	e426                	sd	s1,8(sp)
    800043b4:	e04a                	sd	s2,0(sp)
    800043b6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043b8:	0001d517          	auipc	a0,0x1d
    800043bc:	4b850513          	addi	a0,a0,1208 # 80021870 <log>
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	802080e7          	jalr	-2046(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800043c8:	0001d497          	auipc	s1,0x1d
    800043cc:	4a848493          	addi	s1,s1,1192 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043d0:	4979                	li	s2,30
    800043d2:	a039                	j	800043e0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043d4:	85a6                	mv	a1,s1
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	cf6080e7          	jalr	-778(ra) # 800020ce <sleep>
    if(log.committing){
    800043e0:	50dc                	lw	a5,36(s1)
    800043e2:	fbed                	bnez	a5,800043d4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043e4:	509c                	lw	a5,32(s1)
    800043e6:	0017871b          	addiw	a4,a5,1
    800043ea:	0007069b          	sext.w	a3,a4
    800043ee:	0027179b          	slliw	a5,a4,0x2
    800043f2:	9fb9                	addw	a5,a5,a4
    800043f4:	0017979b          	slliw	a5,a5,0x1
    800043f8:	54d8                	lw	a4,44(s1)
    800043fa:	9fb9                	addw	a5,a5,a4
    800043fc:	00f95963          	bge	s2,a5,8000440e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004400:	85a6                	mv	a1,s1
    80004402:	8526                	mv	a0,s1
    80004404:	ffffe097          	auipc	ra,0xffffe
    80004408:	cca080e7          	jalr	-822(ra) # 800020ce <sleep>
    8000440c:	bfd1                	j	800043e0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000440e:	0001d517          	auipc	a0,0x1d
    80004412:	46250513          	addi	a0,a0,1122 # 80021870 <log>
    80004416:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	85e080e7          	jalr	-1954(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004420:	60e2                	ld	ra,24(sp)
    80004422:	6442                	ld	s0,16(sp)
    80004424:	64a2                	ld	s1,8(sp)
    80004426:	6902                	ld	s2,0(sp)
    80004428:	6105                	addi	sp,sp,32
    8000442a:	8082                	ret

000000008000442c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000442c:	7139                	addi	sp,sp,-64
    8000442e:	fc06                	sd	ra,56(sp)
    80004430:	f822                	sd	s0,48(sp)
    80004432:	f426                	sd	s1,40(sp)
    80004434:	f04a                	sd	s2,32(sp)
    80004436:	ec4e                	sd	s3,24(sp)
    80004438:	e852                	sd	s4,16(sp)
    8000443a:	e456                	sd	s5,8(sp)
    8000443c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000443e:	0001d497          	auipc	s1,0x1d
    80004442:	43248493          	addi	s1,s1,1074 # 80021870 <log>
    80004446:	8526                	mv	a0,s1
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	77a080e7          	jalr	1914(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004450:	509c                	lw	a5,32(s1)
    80004452:	37fd                	addiw	a5,a5,-1
    80004454:	0007891b          	sext.w	s2,a5
    80004458:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000445a:	50dc                	lw	a5,36(s1)
    8000445c:	e7b9                	bnez	a5,800044aa <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000445e:	04091e63          	bnez	s2,800044ba <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004462:	0001d497          	auipc	s1,0x1d
    80004466:	40e48493          	addi	s1,s1,1038 # 80021870 <log>
    8000446a:	4785                	li	a5,1
    8000446c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000446e:	8526                	mv	a0,s1
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	806080e7          	jalr	-2042(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004478:	54dc                	lw	a5,44(s1)
    8000447a:	06f04763          	bgtz	a5,800044e8 <end_op+0xbc>
    acquire(&log.lock);
    8000447e:	0001d497          	auipc	s1,0x1d
    80004482:	3f248493          	addi	s1,s1,1010 # 80021870 <log>
    80004486:	8526                	mv	a0,s1
    80004488:	ffffc097          	auipc	ra,0xffffc
    8000448c:	73a080e7          	jalr	1850(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004490:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004494:	8526                	mv	a0,s1
    80004496:	ffffe097          	auipc	ra,0xffffe
    8000449a:	dc4080e7          	jalr	-572(ra) # 8000225a <wakeup>
    release(&log.lock);
    8000449e:	8526                	mv	a0,s1
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	7d6080e7          	jalr	2006(ra) # 80000c76 <release>
}
    800044a8:	a03d                	j	800044d6 <end_op+0xaa>
    panic("log.committing");
    800044aa:	00004517          	auipc	a0,0x4
    800044ae:	3c650513          	addi	a0,a0,966 # 80008870 <syscalls_str+0x1f0>
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	078080e7          	jalr	120(ra) # 8000052a <panic>
    wakeup(&log);
    800044ba:	0001d497          	auipc	s1,0x1d
    800044be:	3b648493          	addi	s1,s1,950 # 80021870 <log>
    800044c2:	8526                	mv	a0,s1
    800044c4:	ffffe097          	auipc	ra,0xffffe
    800044c8:	d96080e7          	jalr	-618(ra) # 8000225a <wakeup>
  release(&log.lock);
    800044cc:	8526                	mv	a0,s1
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	7a8080e7          	jalr	1960(ra) # 80000c76 <release>
}
    800044d6:	70e2                	ld	ra,56(sp)
    800044d8:	7442                	ld	s0,48(sp)
    800044da:	74a2                	ld	s1,40(sp)
    800044dc:	7902                	ld	s2,32(sp)
    800044de:	69e2                	ld	s3,24(sp)
    800044e0:	6a42                	ld	s4,16(sp)
    800044e2:	6aa2                	ld	s5,8(sp)
    800044e4:	6121                	addi	sp,sp,64
    800044e6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e8:	0001da97          	auipc	s5,0x1d
    800044ec:	3b8a8a93          	addi	s5,s5,952 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044f0:	0001da17          	auipc	s4,0x1d
    800044f4:	380a0a13          	addi	s4,s4,896 # 80021870 <log>
    800044f8:	018a2583          	lw	a1,24(s4)
    800044fc:	012585bb          	addw	a1,a1,s2
    80004500:	2585                	addiw	a1,a1,1
    80004502:	028a2503          	lw	a0,40(s4)
    80004506:	fffff097          	auipc	ra,0xfffff
    8000450a:	ccc080e7          	jalr	-820(ra) # 800031d2 <bread>
    8000450e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004510:	000aa583          	lw	a1,0(s5)
    80004514:	028a2503          	lw	a0,40(s4)
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	cba080e7          	jalr	-838(ra) # 800031d2 <bread>
    80004520:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004522:	40000613          	li	a2,1024
    80004526:	05850593          	addi	a1,a0,88
    8000452a:	05848513          	addi	a0,s1,88
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	7ec080e7          	jalr	2028(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004536:	8526                	mv	a0,s1
    80004538:	fffff097          	auipc	ra,0xfffff
    8000453c:	d8c080e7          	jalr	-628(ra) # 800032c4 <bwrite>
    brelse(from);
    80004540:	854e                	mv	a0,s3
    80004542:	fffff097          	auipc	ra,0xfffff
    80004546:	dc0080e7          	jalr	-576(ra) # 80003302 <brelse>
    brelse(to);
    8000454a:	8526                	mv	a0,s1
    8000454c:	fffff097          	auipc	ra,0xfffff
    80004550:	db6080e7          	jalr	-586(ra) # 80003302 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004554:	2905                	addiw	s2,s2,1
    80004556:	0a91                	addi	s5,s5,4
    80004558:	02ca2783          	lw	a5,44(s4)
    8000455c:	f8f94ee3          	blt	s2,a5,800044f8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004560:	00000097          	auipc	ra,0x0
    80004564:	c66080e7          	jalr	-922(ra) # 800041c6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004568:	4501                	li	a0,0
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	cd8080e7          	jalr	-808(ra) # 80004242 <install_trans>
    log.lh.n = 0;
    80004572:	0001d797          	auipc	a5,0x1d
    80004576:	3207a523          	sw	zero,810(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	c4c080e7          	jalr	-948(ra) # 800041c6 <write_head>
    80004582:	bdf5                	j	8000447e <end_op+0x52>

0000000080004584 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004584:	1101                	addi	sp,sp,-32
    80004586:	ec06                	sd	ra,24(sp)
    80004588:	e822                	sd	s0,16(sp)
    8000458a:	e426                	sd	s1,8(sp)
    8000458c:	e04a                	sd	s2,0(sp)
    8000458e:	1000                	addi	s0,sp,32
    80004590:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004592:	0001d917          	auipc	s2,0x1d
    80004596:	2de90913          	addi	s2,s2,734 # 80021870 <log>
    8000459a:	854a                	mv	a0,s2
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	626080e7          	jalr	1574(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045a4:	02c92603          	lw	a2,44(s2)
    800045a8:	47f5                	li	a5,29
    800045aa:	06c7c563          	blt	a5,a2,80004614 <log_write+0x90>
    800045ae:	0001d797          	auipc	a5,0x1d
    800045b2:	2de7a783          	lw	a5,734(a5) # 8002188c <log+0x1c>
    800045b6:	37fd                	addiw	a5,a5,-1
    800045b8:	04f65e63          	bge	a2,a5,80004614 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045bc:	0001d797          	auipc	a5,0x1d
    800045c0:	2d47a783          	lw	a5,724(a5) # 80021890 <log+0x20>
    800045c4:	06f05063          	blez	a5,80004624 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045c8:	4781                	li	a5,0
    800045ca:	06c05563          	blez	a2,80004634 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045ce:	44cc                	lw	a1,12(s1)
    800045d0:	0001d717          	auipc	a4,0x1d
    800045d4:	2d070713          	addi	a4,a4,720 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045d8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045da:	4314                	lw	a3,0(a4)
    800045dc:	04b68c63          	beq	a3,a1,80004634 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045e0:	2785                	addiw	a5,a5,1
    800045e2:	0711                	addi	a4,a4,4
    800045e4:	fef61be3          	bne	a2,a5,800045da <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045e8:	0621                	addi	a2,a2,8
    800045ea:	060a                	slli	a2,a2,0x2
    800045ec:	0001d797          	auipc	a5,0x1d
    800045f0:	28478793          	addi	a5,a5,644 # 80021870 <log>
    800045f4:	963e                	add	a2,a2,a5
    800045f6:	44dc                	lw	a5,12(s1)
    800045f8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045fa:	8526                	mv	a0,s1
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	da4080e7          	jalr	-604(ra) # 800033a0 <bpin>
    log.lh.n++;
    80004604:	0001d717          	auipc	a4,0x1d
    80004608:	26c70713          	addi	a4,a4,620 # 80021870 <log>
    8000460c:	575c                	lw	a5,44(a4)
    8000460e:	2785                	addiw	a5,a5,1
    80004610:	d75c                	sw	a5,44(a4)
    80004612:	a835                	j	8000464e <log_write+0xca>
    panic("too big a transaction");
    80004614:	00004517          	auipc	a0,0x4
    80004618:	26c50513          	addi	a0,a0,620 # 80008880 <syscalls_str+0x200>
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	f0e080e7          	jalr	-242(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004624:	00004517          	auipc	a0,0x4
    80004628:	27450513          	addi	a0,a0,628 # 80008898 <syscalls_str+0x218>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	efe080e7          	jalr	-258(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004634:	00878713          	addi	a4,a5,8
    80004638:	00271693          	slli	a3,a4,0x2
    8000463c:	0001d717          	auipc	a4,0x1d
    80004640:	23470713          	addi	a4,a4,564 # 80021870 <log>
    80004644:	9736                	add	a4,a4,a3
    80004646:	44d4                	lw	a3,12(s1)
    80004648:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000464a:	faf608e3          	beq	a2,a5,800045fa <log_write+0x76>
  }
  release(&log.lock);
    8000464e:	0001d517          	auipc	a0,0x1d
    80004652:	22250513          	addi	a0,a0,546 # 80021870 <log>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	620080e7          	jalr	1568(ra) # 80000c76 <release>
}
    8000465e:	60e2                	ld	ra,24(sp)
    80004660:	6442                	ld	s0,16(sp)
    80004662:	64a2                	ld	s1,8(sp)
    80004664:	6902                	ld	s2,0(sp)
    80004666:	6105                	addi	sp,sp,32
    80004668:	8082                	ret

000000008000466a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000466a:	1101                	addi	sp,sp,-32
    8000466c:	ec06                	sd	ra,24(sp)
    8000466e:	e822                	sd	s0,16(sp)
    80004670:	e426                	sd	s1,8(sp)
    80004672:	e04a                	sd	s2,0(sp)
    80004674:	1000                	addi	s0,sp,32
    80004676:	84aa                	mv	s1,a0
    80004678:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000467a:	00004597          	auipc	a1,0x4
    8000467e:	23e58593          	addi	a1,a1,574 # 800088b8 <syscalls_str+0x238>
    80004682:	0521                	addi	a0,a0,8
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	4ae080e7          	jalr	1198(ra) # 80000b32 <initlock>
  lk->name = name;
    8000468c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004690:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004694:	0204a423          	sw	zero,40(s1)
}
    80004698:	60e2                	ld	ra,24(sp)
    8000469a:	6442                	ld	s0,16(sp)
    8000469c:	64a2                	ld	s1,8(sp)
    8000469e:	6902                	ld	s2,0(sp)
    800046a0:	6105                	addi	sp,sp,32
    800046a2:	8082                	ret

00000000800046a4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046a4:	1101                	addi	sp,sp,-32
    800046a6:	ec06                	sd	ra,24(sp)
    800046a8:	e822                	sd	s0,16(sp)
    800046aa:	e426                	sd	s1,8(sp)
    800046ac:	e04a                	sd	s2,0(sp)
    800046ae:	1000                	addi	s0,sp,32
    800046b0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046b2:	00850913          	addi	s2,a0,8
    800046b6:	854a                	mv	a0,s2
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	50a080e7          	jalr	1290(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800046c0:	409c                	lw	a5,0(s1)
    800046c2:	cb89                	beqz	a5,800046d4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046c4:	85ca                	mv	a1,s2
    800046c6:	8526                	mv	a0,s1
    800046c8:	ffffe097          	auipc	ra,0xffffe
    800046cc:	a06080e7          	jalr	-1530(ra) # 800020ce <sleep>
  while (lk->locked) {
    800046d0:	409c                	lw	a5,0(s1)
    800046d2:	fbed                	bnez	a5,800046c4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046d4:	4785                	li	a5,1
    800046d6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046d8:	ffffd097          	auipc	ra,0xffffd
    800046dc:	2ba080e7          	jalr	698(ra) # 80001992 <myproc>
    800046e0:	591c                	lw	a5,48(a0)
    800046e2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046e4:	854a                	mv	a0,s2
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	590080e7          	jalr	1424(ra) # 80000c76 <release>
}
    800046ee:	60e2                	ld	ra,24(sp)
    800046f0:	6442                	ld	s0,16(sp)
    800046f2:	64a2                	ld	s1,8(sp)
    800046f4:	6902                	ld	s2,0(sp)
    800046f6:	6105                	addi	sp,sp,32
    800046f8:	8082                	ret

00000000800046fa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046fa:	1101                	addi	sp,sp,-32
    800046fc:	ec06                	sd	ra,24(sp)
    800046fe:	e822                	sd	s0,16(sp)
    80004700:	e426                	sd	s1,8(sp)
    80004702:	e04a                	sd	s2,0(sp)
    80004704:	1000                	addi	s0,sp,32
    80004706:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004708:	00850913          	addi	s2,a0,8
    8000470c:	854a                	mv	a0,s2
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	4b4080e7          	jalr	1204(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004716:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000471a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000471e:	8526                	mv	a0,s1
    80004720:	ffffe097          	auipc	ra,0xffffe
    80004724:	b3a080e7          	jalr	-1222(ra) # 8000225a <wakeup>
  release(&lk->lk);
    80004728:	854a                	mv	a0,s2
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	54c080e7          	jalr	1356(ra) # 80000c76 <release>
}
    80004732:	60e2                	ld	ra,24(sp)
    80004734:	6442                	ld	s0,16(sp)
    80004736:	64a2                	ld	s1,8(sp)
    80004738:	6902                	ld	s2,0(sp)
    8000473a:	6105                	addi	sp,sp,32
    8000473c:	8082                	ret

000000008000473e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000473e:	7179                	addi	sp,sp,-48
    80004740:	f406                	sd	ra,40(sp)
    80004742:	f022                	sd	s0,32(sp)
    80004744:	ec26                	sd	s1,24(sp)
    80004746:	e84a                	sd	s2,16(sp)
    80004748:	e44e                	sd	s3,8(sp)
    8000474a:	1800                	addi	s0,sp,48
    8000474c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000474e:	00850913          	addi	s2,a0,8
    80004752:	854a                	mv	a0,s2
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	46e080e7          	jalr	1134(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000475c:	409c                	lw	a5,0(s1)
    8000475e:	ef99                	bnez	a5,8000477c <holdingsleep+0x3e>
    80004760:	4481                	li	s1,0
  release(&lk->lk);
    80004762:	854a                	mv	a0,s2
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	512080e7          	jalr	1298(ra) # 80000c76 <release>
  return r;
}
    8000476c:	8526                	mv	a0,s1
    8000476e:	70a2                	ld	ra,40(sp)
    80004770:	7402                	ld	s0,32(sp)
    80004772:	64e2                	ld	s1,24(sp)
    80004774:	6942                	ld	s2,16(sp)
    80004776:	69a2                	ld	s3,8(sp)
    80004778:	6145                	addi	sp,sp,48
    8000477a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000477c:	0284a983          	lw	s3,40(s1)
    80004780:	ffffd097          	auipc	ra,0xffffd
    80004784:	212080e7          	jalr	530(ra) # 80001992 <myproc>
    80004788:	5904                	lw	s1,48(a0)
    8000478a:	413484b3          	sub	s1,s1,s3
    8000478e:	0014b493          	seqz	s1,s1
    80004792:	bfc1                	j	80004762 <holdingsleep+0x24>

0000000080004794 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004794:	1141                	addi	sp,sp,-16
    80004796:	e406                	sd	ra,8(sp)
    80004798:	e022                	sd	s0,0(sp)
    8000479a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000479c:	00004597          	auipc	a1,0x4
    800047a0:	12c58593          	addi	a1,a1,300 # 800088c8 <syscalls_str+0x248>
    800047a4:	0001d517          	auipc	a0,0x1d
    800047a8:	21450513          	addi	a0,a0,532 # 800219b8 <ftable>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	386080e7          	jalr	902(ra) # 80000b32 <initlock>
}
    800047b4:	60a2                	ld	ra,8(sp)
    800047b6:	6402                	ld	s0,0(sp)
    800047b8:	0141                	addi	sp,sp,16
    800047ba:	8082                	ret

00000000800047bc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047bc:	1101                	addi	sp,sp,-32
    800047be:	ec06                	sd	ra,24(sp)
    800047c0:	e822                	sd	s0,16(sp)
    800047c2:	e426                	sd	s1,8(sp)
    800047c4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	1f250513          	addi	a0,a0,498 # 800219b8 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	3f4080e7          	jalr	1012(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047d6:	0001d497          	auipc	s1,0x1d
    800047da:	1fa48493          	addi	s1,s1,506 # 800219d0 <ftable+0x18>
    800047de:	0001e717          	auipc	a4,0x1e
    800047e2:	19270713          	addi	a4,a4,402 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    800047e6:	40dc                	lw	a5,4(s1)
    800047e8:	cf99                	beqz	a5,80004806 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047ea:	02848493          	addi	s1,s1,40
    800047ee:	fee49ce3          	bne	s1,a4,800047e6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047f2:	0001d517          	auipc	a0,0x1d
    800047f6:	1c650513          	addi	a0,a0,454 # 800219b8 <ftable>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	47c080e7          	jalr	1148(ra) # 80000c76 <release>
  return 0;
    80004802:	4481                	li	s1,0
    80004804:	a819                	j	8000481a <filealloc+0x5e>
      f->ref = 1;
    80004806:	4785                	li	a5,1
    80004808:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000480a:	0001d517          	auipc	a0,0x1d
    8000480e:	1ae50513          	addi	a0,a0,430 # 800219b8 <ftable>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	464080e7          	jalr	1124(ra) # 80000c76 <release>
}
    8000481a:	8526                	mv	a0,s1
    8000481c:	60e2                	ld	ra,24(sp)
    8000481e:	6442                	ld	s0,16(sp)
    80004820:	64a2                	ld	s1,8(sp)
    80004822:	6105                	addi	sp,sp,32
    80004824:	8082                	ret

0000000080004826 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004826:	1101                	addi	sp,sp,-32
    80004828:	ec06                	sd	ra,24(sp)
    8000482a:	e822                	sd	s0,16(sp)
    8000482c:	e426                	sd	s1,8(sp)
    8000482e:	1000                	addi	s0,sp,32
    80004830:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004832:	0001d517          	auipc	a0,0x1d
    80004836:	18650513          	addi	a0,a0,390 # 800219b8 <ftable>
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	388080e7          	jalr	904(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004842:	40dc                	lw	a5,4(s1)
    80004844:	02f05263          	blez	a5,80004868 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004848:	2785                	addiw	a5,a5,1
    8000484a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000484c:	0001d517          	auipc	a0,0x1d
    80004850:	16c50513          	addi	a0,a0,364 # 800219b8 <ftable>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	422080e7          	jalr	1058(ra) # 80000c76 <release>
  return f;
}
    8000485c:	8526                	mv	a0,s1
    8000485e:	60e2                	ld	ra,24(sp)
    80004860:	6442                	ld	s0,16(sp)
    80004862:	64a2                	ld	s1,8(sp)
    80004864:	6105                	addi	sp,sp,32
    80004866:	8082                	ret
    panic("filedup");
    80004868:	00004517          	auipc	a0,0x4
    8000486c:	06850513          	addi	a0,a0,104 # 800088d0 <syscalls_str+0x250>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	cba080e7          	jalr	-838(ra) # 8000052a <panic>

0000000080004878 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004878:	7139                	addi	sp,sp,-64
    8000487a:	fc06                	sd	ra,56(sp)
    8000487c:	f822                	sd	s0,48(sp)
    8000487e:	f426                	sd	s1,40(sp)
    80004880:	f04a                	sd	s2,32(sp)
    80004882:	ec4e                	sd	s3,24(sp)
    80004884:	e852                	sd	s4,16(sp)
    80004886:	e456                	sd	s5,8(sp)
    80004888:	0080                	addi	s0,sp,64
    8000488a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000488c:	0001d517          	auipc	a0,0x1d
    80004890:	12c50513          	addi	a0,a0,300 # 800219b8 <ftable>
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	32e080e7          	jalr	814(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000489c:	40dc                	lw	a5,4(s1)
    8000489e:	06f05163          	blez	a5,80004900 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048a2:	37fd                	addiw	a5,a5,-1
    800048a4:	0007871b          	sext.w	a4,a5
    800048a8:	c0dc                	sw	a5,4(s1)
    800048aa:	06e04363          	bgtz	a4,80004910 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048ae:	0004a903          	lw	s2,0(s1)
    800048b2:	0094ca83          	lbu	s5,9(s1)
    800048b6:	0104ba03          	ld	s4,16(s1)
    800048ba:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048be:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048c2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048c6:	0001d517          	auipc	a0,0x1d
    800048ca:	0f250513          	addi	a0,a0,242 # 800219b8 <ftable>
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	3a8080e7          	jalr	936(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800048d6:	4785                	li	a5,1
    800048d8:	04f90d63          	beq	s2,a5,80004932 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048dc:	3979                	addiw	s2,s2,-2
    800048de:	4785                	li	a5,1
    800048e0:	0527e063          	bltu	a5,s2,80004920 <fileclose+0xa8>
    begin_op();
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	ac8080e7          	jalr	-1336(ra) # 800043ac <begin_op>
    iput(ff.ip);
    800048ec:	854e                	mv	a0,s3
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	2a2080e7          	jalr	674(ra) # 80003b90 <iput>
    end_op();
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	b36080e7          	jalr	-1226(ra) # 8000442c <end_op>
    800048fe:	a00d                	j	80004920 <fileclose+0xa8>
    panic("fileclose");
    80004900:	00004517          	auipc	a0,0x4
    80004904:	fd850513          	addi	a0,a0,-40 # 800088d8 <syscalls_str+0x258>
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	c22080e7          	jalr	-990(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004910:	0001d517          	auipc	a0,0x1d
    80004914:	0a850513          	addi	a0,a0,168 # 800219b8 <ftable>
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	35e080e7          	jalr	862(ra) # 80000c76 <release>
  }
}
    80004920:	70e2                	ld	ra,56(sp)
    80004922:	7442                	ld	s0,48(sp)
    80004924:	74a2                	ld	s1,40(sp)
    80004926:	7902                	ld	s2,32(sp)
    80004928:	69e2                	ld	s3,24(sp)
    8000492a:	6a42                	ld	s4,16(sp)
    8000492c:	6aa2                	ld	s5,8(sp)
    8000492e:	6121                	addi	sp,sp,64
    80004930:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004932:	85d6                	mv	a1,s5
    80004934:	8552                	mv	a0,s4
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	34c080e7          	jalr	844(ra) # 80004c82 <pipeclose>
    8000493e:	b7cd                	j	80004920 <fileclose+0xa8>

0000000080004940 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004940:	715d                	addi	sp,sp,-80
    80004942:	e486                	sd	ra,72(sp)
    80004944:	e0a2                	sd	s0,64(sp)
    80004946:	fc26                	sd	s1,56(sp)
    80004948:	f84a                	sd	s2,48(sp)
    8000494a:	f44e                	sd	s3,40(sp)
    8000494c:	0880                	addi	s0,sp,80
    8000494e:	84aa                	mv	s1,a0
    80004950:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004952:	ffffd097          	auipc	ra,0xffffd
    80004956:	040080e7          	jalr	64(ra) # 80001992 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000495a:	409c                	lw	a5,0(s1)
    8000495c:	37f9                	addiw	a5,a5,-2
    8000495e:	4705                	li	a4,1
    80004960:	04f76763          	bltu	a4,a5,800049ae <filestat+0x6e>
    80004964:	892a                	mv	s2,a0
    ilock(f->ip);
    80004966:	6c88                	ld	a0,24(s1)
    80004968:	fffff097          	auipc	ra,0xfffff
    8000496c:	06e080e7          	jalr	110(ra) # 800039d6 <ilock>
    stati(f->ip, &st);
    80004970:	fb840593          	addi	a1,s0,-72
    80004974:	6c88                	ld	a0,24(s1)
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	2ea080e7          	jalr	746(ra) # 80003c60 <stati>
    iunlock(f->ip);
    8000497e:	6c88                	ld	a0,24(s1)
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	118080e7          	jalr	280(ra) # 80003a98 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004988:	46e1                	li	a3,24
    8000498a:	fb840613          	addi	a2,s0,-72
    8000498e:	85ce                	mv	a1,s3
    80004990:	05093503          	ld	a0,80(s2)
    80004994:	ffffd097          	auipc	ra,0xffffd
    80004998:	caa080e7          	jalr	-854(ra) # 8000163e <copyout>
    8000499c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049a0:	60a6                	ld	ra,72(sp)
    800049a2:	6406                	ld	s0,64(sp)
    800049a4:	74e2                	ld	s1,56(sp)
    800049a6:	7942                	ld	s2,48(sp)
    800049a8:	79a2                	ld	s3,40(sp)
    800049aa:	6161                	addi	sp,sp,80
    800049ac:	8082                	ret
  return -1;
    800049ae:	557d                	li	a0,-1
    800049b0:	bfc5                	j	800049a0 <filestat+0x60>

00000000800049b2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049b2:	7179                	addi	sp,sp,-48
    800049b4:	f406                	sd	ra,40(sp)
    800049b6:	f022                	sd	s0,32(sp)
    800049b8:	ec26                	sd	s1,24(sp)
    800049ba:	e84a                	sd	s2,16(sp)
    800049bc:	e44e                	sd	s3,8(sp)
    800049be:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049c0:	00854783          	lbu	a5,8(a0)
    800049c4:	c3d5                	beqz	a5,80004a68 <fileread+0xb6>
    800049c6:	84aa                	mv	s1,a0
    800049c8:	89ae                	mv	s3,a1
    800049ca:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049cc:	411c                	lw	a5,0(a0)
    800049ce:	4705                	li	a4,1
    800049d0:	04e78963          	beq	a5,a4,80004a22 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049d4:	470d                	li	a4,3
    800049d6:	04e78d63          	beq	a5,a4,80004a30 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049da:	4709                	li	a4,2
    800049dc:	06e79e63          	bne	a5,a4,80004a58 <fileread+0xa6>
    ilock(f->ip);
    800049e0:	6d08                	ld	a0,24(a0)
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	ff4080e7          	jalr	-12(ra) # 800039d6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049ea:	874a                	mv	a4,s2
    800049ec:	5094                	lw	a3,32(s1)
    800049ee:	864e                	mv	a2,s3
    800049f0:	4585                	li	a1,1
    800049f2:	6c88                	ld	a0,24(s1)
    800049f4:	fffff097          	auipc	ra,0xfffff
    800049f8:	296080e7          	jalr	662(ra) # 80003c8a <readi>
    800049fc:	892a                	mv	s2,a0
    800049fe:	00a05563          	blez	a0,80004a08 <fileread+0x56>
      f->off += r;
    80004a02:	509c                	lw	a5,32(s1)
    80004a04:	9fa9                	addw	a5,a5,a0
    80004a06:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a08:	6c88                	ld	a0,24(s1)
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	08e080e7          	jalr	142(ra) # 80003a98 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a12:	854a                	mv	a0,s2
    80004a14:	70a2                	ld	ra,40(sp)
    80004a16:	7402                	ld	s0,32(sp)
    80004a18:	64e2                	ld	s1,24(sp)
    80004a1a:	6942                	ld	s2,16(sp)
    80004a1c:	69a2                	ld	s3,8(sp)
    80004a1e:	6145                	addi	sp,sp,48
    80004a20:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a22:	6908                	ld	a0,16(a0)
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	3c0080e7          	jalr	960(ra) # 80004de4 <piperead>
    80004a2c:	892a                	mv	s2,a0
    80004a2e:	b7d5                	j	80004a12 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a30:	02451783          	lh	a5,36(a0)
    80004a34:	03079693          	slli	a3,a5,0x30
    80004a38:	92c1                	srli	a3,a3,0x30
    80004a3a:	4725                	li	a4,9
    80004a3c:	02d76863          	bltu	a4,a3,80004a6c <fileread+0xba>
    80004a40:	0792                	slli	a5,a5,0x4
    80004a42:	0001d717          	auipc	a4,0x1d
    80004a46:	ed670713          	addi	a4,a4,-298 # 80021918 <devsw>
    80004a4a:	97ba                	add	a5,a5,a4
    80004a4c:	639c                	ld	a5,0(a5)
    80004a4e:	c38d                	beqz	a5,80004a70 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a50:	4505                	li	a0,1
    80004a52:	9782                	jalr	a5
    80004a54:	892a                	mv	s2,a0
    80004a56:	bf75                	j	80004a12 <fileread+0x60>
    panic("fileread");
    80004a58:	00004517          	auipc	a0,0x4
    80004a5c:	e9050513          	addi	a0,a0,-368 # 800088e8 <syscalls_str+0x268>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	aca080e7          	jalr	-1334(ra) # 8000052a <panic>
    return -1;
    80004a68:	597d                	li	s2,-1
    80004a6a:	b765                	j	80004a12 <fileread+0x60>
      return -1;
    80004a6c:	597d                	li	s2,-1
    80004a6e:	b755                	j	80004a12 <fileread+0x60>
    80004a70:	597d                	li	s2,-1
    80004a72:	b745                	j	80004a12 <fileread+0x60>

0000000080004a74 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a74:	715d                	addi	sp,sp,-80
    80004a76:	e486                	sd	ra,72(sp)
    80004a78:	e0a2                	sd	s0,64(sp)
    80004a7a:	fc26                	sd	s1,56(sp)
    80004a7c:	f84a                	sd	s2,48(sp)
    80004a7e:	f44e                	sd	s3,40(sp)
    80004a80:	f052                	sd	s4,32(sp)
    80004a82:	ec56                	sd	s5,24(sp)
    80004a84:	e85a                	sd	s6,16(sp)
    80004a86:	e45e                	sd	s7,8(sp)
    80004a88:	e062                	sd	s8,0(sp)
    80004a8a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a8c:	00954783          	lbu	a5,9(a0)
    80004a90:	10078663          	beqz	a5,80004b9c <filewrite+0x128>
    80004a94:	892a                	mv	s2,a0
    80004a96:	8aae                	mv	s5,a1
    80004a98:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a9a:	411c                	lw	a5,0(a0)
    80004a9c:	4705                	li	a4,1
    80004a9e:	02e78263          	beq	a5,a4,80004ac2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aa2:	470d                	li	a4,3
    80004aa4:	02e78663          	beq	a5,a4,80004ad0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aa8:	4709                	li	a4,2
    80004aaa:	0ee79163          	bne	a5,a4,80004b8c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004aae:	0ac05d63          	blez	a2,80004b68 <filewrite+0xf4>
    int i = 0;
    80004ab2:	4981                	li	s3,0
    80004ab4:	6b05                	lui	s6,0x1
    80004ab6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004aba:	6b85                	lui	s7,0x1
    80004abc:	c00b8b9b          	addiw	s7,s7,-1024
    80004ac0:	a861                	j	80004b58 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ac2:	6908                	ld	a0,16(a0)
    80004ac4:	00000097          	auipc	ra,0x0
    80004ac8:	22e080e7          	jalr	558(ra) # 80004cf2 <pipewrite>
    80004acc:	8a2a                	mv	s4,a0
    80004ace:	a045                	j	80004b6e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ad0:	02451783          	lh	a5,36(a0)
    80004ad4:	03079693          	slli	a3,a5,0x30
    80004ad8:	92c1                	srli	a3,a3,0x30
    80004ada:	4725                	li	a4,9
    80004adc:	0cd76263          	bltu	a4,a3,80004ba0 <filewrite+0x12c>
    80004ae0:	0792                	slli	a5,a5,0x4
    80004ae2:	0001d717          	auipc	a4,0x1d
    80004ae6:	e3670713          	addi	a4,a4,-458 # 80021918 <devsw>
    80004aea:	97ba                	add	a5,a5,a4
    80004aec:	679c                	ld	a5,8(a5)
    80004aee:	cbdd                	beqz	a5,80004ba4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004af0:	4505                	li	a0,1
    80004af2:	9782                	jalr	a5
    80004af4:	8a2a                	mv	s4,a0
    80004af6:	a8a5                	j	80004b6e <filewrite+0xfa>
    80004af8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	8b0080e7          	jalr	-1872(ra) # 800043ac <begin_op>
      ilock(f->ip);
    80004b04:	01893503          	ld	a0,24(s2)
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	ece080e7          	jalr	-306(ra) # 800039d6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b10:	8762                	mv	a4,s8
    80004b12:	02092683          	lw	a3,32(s2)
    80004b16:	01598633          	add	a2,s3,s5
    80004b1a:	4585                	li	a1,1
    80004b1c:	01893503          	ld	a0,24(s2)
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	262080e7          	jalr	610(ra) # 80003d82 <writei>
    80004b28:	84aa                	mv	s1,a0
    80004b2a:	00a05763          	blez	a0,80004b38 <filewrite+0xc4>
        f->off += r;
    80004b2e:	02092783          	lw	a5,32(s2)
    80004b32:	9fa9                	addw	a5,a5,a0
    80004b34:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b38:	01893503          	ld	a0,24(s2)
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	f5c080e7          	jalr	-164(ra) # 80003a98 <iunlock>
      end_op();
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	8e8080e7          	jalr	-1816(ra) # 8000442c <end_op>

      if(r != n1){
    80004b4c:	009c1f63          	bne	s8,s1,80004b6a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b50:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b54:	0149db63          	bge	s3,s4,80004b6a <filewrite+0xf6>
      int n1 = n - i;
    80004b58:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b5c:	84be                	mv	s1,a5
    80004b5e:	2781                	sext.w	a5,a5
    80004b60:	f8fb5ce3          	bge	s6,a5,80004af8 <filewrite+0x84>
    80004b64:	84de                	mv	s1,s7
    80004b66:	bf49                	j	80004af8 <filewrite+0x84>
    int i = 0;
    80004b68:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b6a:	013a1f63          	bne	s4,s3,80004b88 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b6e:	8552                	mv	a0,s4
    80004b70:	60a6                	ld	ra,72(sp)
    80004b72:	6406                	ld	s0,64(sp)
    80004b74:	74e2                	ld	s1,56(sp)
    80004b76:	7942                	ld	s2,48(sp)
    80004b78:	79a2                	ld	s3,40(sp)
    80004b7a:	7a02                	ld	s4,32(sp)
    80004b7c:	6ae2                	ld	s5,24(sp)
    80004b7e:	6b42                	ld	s6,16(sp)
    80004b80:	6ba2                	ld	s7,8(sp)
    80004b82:	6c02                	ld	s8,0(sp)
    80004b84:	6161                	addi	sp,sp,80
    80004b86:	8082                	ret
    ret = (i == n ? n : -1);
    80004b88:	5a7d                	li	s4,-1
    80004b8a:	b7d5                	j	80004b6e <filewrite+0xfa>
    panic("filewrite");
    80004b8c:	00004517          	auipc	a0,0x4
    80004b90:	d6c50513          	addi	a0,a0,-660 # 800088f8 <syscalls_str+0x278>
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	996080e7          	jalr	-1642(ra) # 8000052a <panic>
    return -1;
    80004b9c:	5a7d                	li	s4,-1
    80004b9e:	bfc1                	j	80004b6e <filewrite+0xfa>
      return -1;
    80004ba0:	5a7d                	li	s4,-1
    80004ba2:	b7f1                	j	80004b6e <filewrite+0xfa>
    80004ba4:	5a7d                	li	s4,-1
    80004ba6:	b7e1                	j	80004b6e <filewrite+0xfa>

0000000080004ba8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ba8:	7179                	addi	sp,sp,-48
    80004baa:	f406                	sd	ra,40(sp)
    80004bac:	f022                	sd	s0,32(sp)
    80004bae:	ec26                	sd	s1,24(sp)
    80004bb0:	e84a                	sd	s2,16(sp)
    80004bb2:	e44e                	sd	s3,8(sp)
    80004bb4:	e052                	sd	s4,0(sp)
    80004bb6:	1800                	addi	s0,sp,48
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bbc:	0005b023          	sd	zero,0(a1)
    80004bc0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	bf8080e7          	jalr	-1032(ra) # 800047bc <filealloc>
    80004bcc:	e088                	sd	a0,0(s1)
    80004bce:	c551                	beqz	a0,80004c5a <pipealloc+0xb2>
    80004bd0:	00000097          	auipc	ra,0x0
    80004bd4:	bec080e7          	jalr	-1044(ra) # 800047bc <filealloc>
    80004bd8:	00aa3023          	sd	a0,0(s4)
    80004bdc:	c92d                	beqz	a0,80004c4e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	ef4080e7          	jalr	-268(ra) # 80000ad2 <kalloc>
    80004be6:	892a                	mv	s2,a0
    80004be8:	c125                	beqz	a0,80004c48 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bea:	4985                	li	s3,1
    80004bec:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bf0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bf4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bf8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bfc:	00004597          	auipc	a1,0x4
    80004c00:	d0c58593          	addi	a1,a1,-756 # 80008908 <syscalls_str+0x288>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	f2e080e7          	jalr	-210(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004c0c:	609c                	ld	a5,0(s1)
    80004c0e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c12:	609c                	ld	a5,0(s1)
    80004c14:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c18:	609c                	ld	a5,0(s1)
    80004c1a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c1e:	609c                	ld	a5,0(s1)
    80004c20:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c24:	000a3783          	ld	a5,0(s4)
    80004c28:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c2c:	000a3783          	ld	a5,0(s4)
    80004c30:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c34:	000a3783          	ld	a5,0(s4)
    80004c38:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c3c:	000a3783          	ld	a5,0(s4)
    80004c40:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c44:	4501                	li	a0,0
    80004c46:	a025                	j	80004c6e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c48:	6088                	ld	a0,0(s1)
    80004c4a:	e501                	bnez	a0,80004c52 <pipealloc+0xaa>
    80004c4c:	a039                	j	80004c5a <pipealloc+0xb2>
    80004c4e:	6088                	ld	a0,0(s1)
    80004c50:	c51d                	beqz	a0,80004c7e <pipealloc+0xd6>
    fileclose(*f0);
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	c26080e7          	jalr	-986(ra) # 80004878 <fileclose>
  if(*f1)
    80004c5a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c5e:	557d                	li	a0,-1
  if(*f1)
    80004c60:	c799                	beqz	a5,80004c6e <pipealloc+0xc6>
    fileclose(*f1);
    80004c62:	853e                	mv	a0,a5
    80004c64:	00000097          	auipc	ra,0x0
    80004c68:	c14080e7          	jalr	-1004(ra) # 80004878 <fileclose>
  return -1;
    80004c6c:	557d                	li	a0,-1
}
    80004c6e:	70a2                	ld	ra,40(sp)
    80004c70:	7402                	ld	s0,32(sp)
    80004c72:	64e2                	ld	s1,24(sp)
    80004c74:	6942                	ld	s2,16(sp)
    80004c76:	69a2                	ld	s3,8(sp)
    80004c78:	6a02                	ld	s4,0(sp)
    80004c7a:	6145                	addi	sp,sp,48
    80004c7c:	8082                	ret
  return -1;
    80004c7e:	557d                	li	a0,-1
    80004c80:	b7fd                	j	80004c6e <pipealloc+0xc6>

0000000080004c82 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c82:	1101                	addi	sp,sp,-32
    80004c84:	ec06                	sd	ra,24(sp)
    80004c86:	e822                	sd	s0,16(sp)
    80004c88:	e426                	sd	s1,8(sp)
    80004c8a:	e04a                	sd	s2,0(sp)
    80004c8c:	1000                	addi	s0,sp,32
    80004c8e:	84aa                	mv	s1,a0
    80004c90:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	f30080e7          	jalr	-208(ra) # 80000bc2 <acquire>
  if(writable){
    80004c9a:	02090d63          	beqz	s2,80004cd4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c9e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ca2:	21848513          	addi	a0,s1,536
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	5b4080e7          	jalr	1460(ra) # 8000225a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cae:	2204b783          	ld	a5,544(s1)
    80004cb2:	eb95                	bnez	a5,80004ce6 <pipeclose+0x64>
    release(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	fc0080e7          	jalr	-64(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	d16080e7          	jalr	-746(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004cc8:	60e2                	ld	ra,24(sp)
    80004cca:	6442                	ld	s0,16(sp)
    80004ccc:	64a2                	ld	s1,8(sp)
    80004cce:	6902                	ld	s2,0(sp)
    80004cd0:	6105                	addi	sp,sp,32
    80004cd2:	8082                	ret
    pi->readopen = 0;
    80004cd4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cd8:	21c48513          	addi	a0,s1,540
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	57e080e7          	jalr	1406(ra) # 8000225a <wakeup>
    80004ce4:	b7e9                	j	80004cae <pipeclose+0x2c>
    release(&pi->lock);
    80004ce6:	8526                	mv	a0,s1
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	f8e080e7          	jalr	-114(ra) # 80000c76 <release>
}
    80004cf0:	bfe1                	j	80004cc8 <pipeclose+0x46>

0000000080004cf2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cf2:	711d                	addi	sp,sp,-96
    80004cf4:	ec86                	sd	ra,88(sp)
    80004cf6:	e8a2                	sd	s0,80(sp)
    80004cf8:	e4a6                	sd	s1,72(sp)
    80004cfa:	e0ca                	sd	s2,64(sp)
    80004cfc:	fc4e                	sd	s3,56(sp)
    80004cfe:	f852                	sd	s4,48(sp)
    80004d00:	f456                	sd	s5,40(sp)
    80004d02:	f05a                	sd	s6,32(sp)
    80004d04:	ec5e                	sd	s7,24(sp)
    80004d06:	e862                	sd	s8,16(sp)
    80004d08:	1080                	addi	s0,sp,96
    80004d0a:	84aa                	mv	s1,a0
    80004d0c:	8aae                	mv	s5,a1
    80004d0e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	c82080e7          	jalr	-894(ra) # 80001992 <myproc>
    80004d18:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d1a:	8526                	mv	a0,s1
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	ea6080e7          	jalr	-346(ra) # 80000bc2 <acquire>
  while(i < n){
    80004d24:	0b405363          	blez	s4,80004dca <pipewrite+0xd8>
  int i = 0;
    80004d28:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d2a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d2c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d30:	21c48b93          	addi	s7,s1,540
    80004d34:	a089                	j	80004d76 <pipewrite+0x84>
      release(&pi->lock);
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	f3e080e7          	jalr	-194(ra) # 80000c76 <release>
      return -1;
    80004d40:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d42:	854a                	mv	a0,s2
    80004d44:	60e6                	ld	ra,88(sp)
    80004d46:	6446                	ld	s0,80(sp)
    80004d48:	64a6                	ld	s1,72(sp)
    80004d4a:	6906                	ld	s2,64(sp)
    80004d4c:	79e2                	ld	s3,56(sp)
    80004d4e:	7a42                	ld	s4,48(sp)
    80004d50:	7aa2                	ld	s5,40(sp)
    80004d52:	7b02                	ld	s6,32(sp)
    80004d54:	6be2                	ld	s7,24(sp)
    80004d56:	6c42                	ld	s8,16(sp)
    80004d58:	6125                	addi	sp,sp,96
    80004d5a:	8082                	ret
      wakeup(&pi->nread);
    80004d5c:	8562                	mv	a0,s8
    80004d5e:	ffffd097          	auipc	ra,0xffffd
    80004d62:	4fc080e7          	jalr	1276(ra) # 8000225a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d66:	85a6                	mv	a1,s1
    80004d68:	855e                	mv	a0,s7
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	364080e7          	jalr	868(ra) # 800020ce <sleep>
  while(i < n){
    80004d72:	05495d63          	bge	s2,s4,80004dcc <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004d76:	2204a783          	lw	a5,544(s1)
    80004d7a:	dfd5                	beqz	a5,80004d36 <pipewrite+0x44>
    80004d7c:	0289a783          	lw	a5,40(s3)
    80004d80:	fbdd                	bnez	a5,80004d36 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d82:	2184a783          	lw	a5,536(s1)
    80004d86:	21c4a703          	lw	a4,540(s1)
    80004d8a:	2007879b          	addiw	a5,a5,512
    80004d8e:	fcf707e3          	beq	a4,a5,80004d5c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d92:	4685                	li	a3,1
    80004d94:	01590633          	add	a2,s2,s5
    80004d98:	faf40593          	addi	a1,s0,-81
    80004d9c:	0509b503          	ld	a0,80(s3)
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	92a080e7          	jalr	-1750(ra) # 800016ca <copyin>
    80004da8:	03650263          	beq	a0,s6,80004dcc <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dac:	21c4a783          	lw	a5,540(s1)
    80004db0:	0017871b          	addiw	a4,a5,1
    80004db4:	20e4ae23          	sw	a4,540(s1)
    80004db8:	1ff7f793          	andi	a5,a5,511
    80004dbc:	97a6                	add	a5,a5,s1
    80004dbe:	faf44703          	lbu	a4,-81(s0)
    80004dc2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004dc6:	2905                	addiw	s2,s2,1
    80004dc8:	b76d                	j	80004d72 <pipewrite+0x80>
  int i = 0;
    80004dca:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004dcc:	21848513          	addi	a0,s1,536
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	48a080e7          	jalr	1162(ra) # 8000225a <wakeup>
  release(&pi->lock);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	ffffc097          	auipc	ra,0xffffc
    80004dde:	e9c080e7          	jalr	-356(ra) # 80000c76 <release>
  return i;
    80004de2:	b785                	j	80004d42 <pipewrite+0x50>

0000000080004de4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004de4:	715d                	addi	sp,sp,-80
    80004de6:	e486                	sd	ra,72(sp)
    80004de8:	e0a2                	sd	s0,64(sp)
    80004dea:	fc26                	sd	s1,56(sp)
    80004dec:	f84a                	sd	s2,48(sp)
    80004dee:	f44e                	sd	s3,40(sp)
    80004df0:	f052                	sd	s4,32(sp)
    80004df2:	ec56                	sd	s5,24(sp)
    80004df4:	e85a                	sd	s6,16(sp)
    80004df6:	0880                	addi	s0,sp,80
    80004df8:	84aa                	mv	s1,a0
    80004dfa:	892e                	mv	s2,a1
    80004dfc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	b94080e7          	jalr	-1132(ra) # 80001992 <myproc>
    80004e06:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e08:	8526                	mv	a0,s1
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	db8080e7          	jalr	-584(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e12:	2184a703          	lw	a4,536(s1)
    80004e16:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e1a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e1e:	02f71463          	bne	a4,a5,80004e46 <piperead+0x62>
    80004e22:	2244a783          	lw	a5,548(s1)
    80004e26:	c385                	beqz	a5,80004e46 <piperead+0x62>
    if(pr->killed){
    80004e28:	028a2783          	lw	a5,40(s4)
    80004e2c:	ebc1                	bnez	a5,80004ebc <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e2e:	85a6                	mv	a1,s1
    80004e30:	854e                	mv	a0,s3
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	29c080e7          	jalr	668(ra) # 800020ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e3a:	2184a703          	lw	a4,536(s1)
    80004e3e:	21c4a783          	lw	a5,540(s1)
    80004e42:	fef700e3          	beq	a4,a5,80004e22 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e46:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e48:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e4a:	05505363          	blez	s5,80004e90 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e4e:	2184a783          	lw	a5,536(s1)
    80004e52:	21c4a703          	lw	a4,540(s1)
    80004e56:	02f70d63          	beq	a4,a5,80004e90 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e5a:	0017871b          	addiw	a4,a5,1
    80004e5e:	20e4ac23          	sw	a4,536(s1)
    80004e62:	1ff7f793          	andi	a5,a5,511
    80004e66:	97a6                	add	a5,a5,s1
    80004e68:	0187c783          	lbu	a5,24(a5)
    80004e6c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e70:	4685                	li	a3,1
    80004e72:	fbf40613          	addi	a2,s0,-65
    80004e76:	85ca                	mv	a1,s2
    80004e78:	050a3503          	ld	a0,80(s4)
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	7c2080e7          	jalr	1986(ra) # 8000163e <copyout>
    80004e84:	01650663          	beq	a0,s6,80004e90 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e88:	2985                	addiw	s3,s3,1
    80004e8a:	0905                	addi	s2,s2,1
    80004e8c:	fd3a91e3          	bne	s5,s3,80004e4e <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e90:	21c48513          	addi	a0,s1,540
    80004e94:	ffffd097          	auipc	ra,0xffffd
    80004e98:	3c6080e7          	jalr	966(ra) # 8000225a <wakeup>
  release(&pi->lock);
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	dd8080e7          	jalr	-552(ra) # 80000c76 <release>
  return i;
}
    80004ea6:	854e                	mv	a0,s3
    80004ea8:	60a6                	ld	ra,72(sp)
    80004eaa:	6406                	ld	s0,64(sp)
    80004eac:	74e2                	ld	s1,56(sp)
    80004eae:	7942                	ld	s2,48(sp)
    80004eb0:	79a2                	ld	s3,40(sp)
    80004eb2:	7a02                	ld	s4,32(sp)
    80004eb4:	6ae2                	ld	s5,24(sp)
    80004eb6:	6b42                	ld	s6,16(sp)
    80004eb8:	6161                	addi	sp,sp,80
    80004eba:	8082                	ret
      release(&pi->lock);
    80004ebc:	8526                	mv	a0,s1
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	db8080e7          	jalr	-584(ra) # 80000c76 <release>
      return -1;
    80004ec6:	59fd                	li	s3,-1
    80004ec8:	bff9                	j	80004ea6 <piperead+0xc2>

0000000080004eca <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004eca:	de010113          	addi	sp,sp,-544
    80004ece:	20113c23          	sd	ra,536(sp)
    80004ed2:	20813823          	sd	s0,528(sp)
    80004ed6:	20913423          	sd	s1,520(sp)
    80004eda:	21213023          	sd	s2,512(sp)
    80004ede:	ffce                	sd	s3,504(sp)
    80004ee0:	fbd2                	sd	s4,496(sp)
    80004ee2:	f7d6                	sd	s5,488(sp)
    80004ee4:	f3da                	sd	s6,480(sp)
    80004ee6:	efde                	sd	s7,472(sp)
    80004ee8:	ebe2                	sd	s8,464(sp)
    80004eea:	e7e6                	sd	s9,456(sp)
    80004eec:	e3ea                	sd	s10,448(sp)
    80004eee:	ff6e                	sd	s11,440(sp)
    80004ef0:	1400                	addi	s0,sp,544
    80004ef2:	892a                	mv	s2,a0
    80004ef4:	dea43423          	sd	a0,-536(s0)
    80004ef8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	a96080e7          	jalr	-1386(ra) # 80001992 <myproc>
    80004f04:	84aa                	mv	s1,a0

  begin_op();
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	4a6080e7          	jalr	1190(ra) # 800043ac <begin_op>

  if((ip = namei(path)) == 0){
    80004f0e:	854a                	mv	a0,s2
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	27c080e7          	jalr	636(ra) # 8000418c <namei>
    80004f18:	c93d                	beqz	a0,80004f8e <exec+0xc4>
    80004f1a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f1c:	fffff097          	auipc	ra,0xfffff
    80004f20:	aba080e7          	jalr	-1350(ra) # 800039d6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f24:	04000713          	li	a4,64
    80004f28:	4681                	li	a3,0
    80004f2a:	e4840613          	addi	a2,s0,-440
    80004f2e:	4581                	li	a1,0
    80004f30:	8556                	mv	a0,s5
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	d58080e7          	jalr	-680(ra) # 80003c8a <readi>
    80004f3a:	04000793          	li	a5,64
    80004f3e:	00f51a63          	bne	a0,a5,80004f52 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f42:	e4842703          	lw	a4,-440(s0)
    80004f46:	464c47b7          	lui	a5,0x464c4
    80004f4a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f4e:	04f70663          	beq	a4,a5,80004f9a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f52:	8556                	mv	a0,s5
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	ce4080e7          	jalr	-796(ra) # 80003c38 <iunlockput>
    end_op();
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	4d0080e7          	jalr	1232(ra) # 8000442c <end_op>
  }
  return -1;
    80004f64:	557d                	li	a0,-1
}
    80004f66:	21813083          	ld	ra,536(sp)
    80004f6a:	21013403          	ld	s0,528(sp)
    80004f6e:	20813483          	ld	s1,520(sp)
    80004f72:	20013903          	ld	s2,512(sp)
    80004f76:	79fe                	ld	s3,504(sp)
    80004f78:	7a5e                	ld	s4,496(sp)
    80004f7a:	7abe                	ld	s5,488(sp)
    80004f7c:	7b1e                	ld	s6,480(sp)
    80004f7e:	6bfe                	ld	s7,472(sp)
    80004f80:	6c5e                	ld	s8,464(sp)
    80004f82:	6cbe                	ld	s9,456(sp)
    80004f84:	6d1e                	ld	s10,448(sp)
    80004f86:	7dfa                	ld	s11,440(sp)
    80004f88:	22010113          	addi	sp,sp,544
    80004f8c:	8082                	ret
    end_op();
    80004f8e:	fffff097          	auipc	ra,0xfffff
    80004f92:	49e080e7          	jalr	1182(ra) # 8000442c <end_op>
    return -1;
    80004f96:	557d                	li	a0,-1
    80004f98:	b7f9                	j	80004f66 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f9a:	8526                	mv	a0,s1
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	aba080e7          	jalr	-1350(ra) # 80001a56 <proc_pagetable>
    80004fa4:	8b2a                	mv	s6,a0
    80004fa6:	d555                	beqz	a0,80004f52 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa8:	e6842783          	lw	a5,-408(s0)
    80004fac:	e8045703          	lhu	a4,-384(s0)
    80004fb0:	c735                	beqz	a4,8000501c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fb2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fb8:	6a05                	lui	s4,0x1
    80004fba:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004fbe:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004fc2:	6d85                	lui	s11,0x1
    80004fc4:	7d7d                	lui	s10,0xfffff
    80004fc6:	ac1d                	j	800051fc <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fc8:	00004517          	auipc	a0,0x4
    80004fcc:	94850513          	addi	a0,a0,-1720 # 80008910 <syscalls_str+0x290>
    80004fd0:	ffffb097          	auipc	ra,0xffffb
    80004fd4:	55a080e7          	jalr	1370(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fd8:	874a                	mv	a4,s2
    80004fda:	009c86bb          	addw	a3,s9,s1
    80004fde:	4581                	li	a1,0
    80004fe0:	8556                	mv	a0,s5
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	ca8080e7          	jalr	-856(ra) # 80003c8a <readi>
    80004fea:	2501                	sext.w	a0,a0
    80004fec:	1aa91863          	bne	s2,a0,8000519c <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004ff0:	009d84bb          	addw	s1,s11,s1
    80004ff4:	013d09bb          	addw	s3,s10,s3
    80004ff8:	1f74f263          	bgeu	s1,s7,800051dc <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004ffc:	02049593          	slli	a1,s1,0x20
    80005000:	9181                	srli	a1,a1,0x20
    80005002:	95e2                	add	a1,a1,s8
    80005004:	855a                	mv	a0,s6
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	046080e7          	jalr	70(ra) # 8000104c <walkaddr>
    8000500e:	862a                	mv	a2,a0
    if(pa == 0)
    80005010:	dd45                	beqz	a0,80004fc8 <exec+0xfe>
      n = PGSIZE;
    80005012:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005014:	fd49f2e3          	bgeu	s3,s4,80004fd8 <exec+0x10e>
      n = sz - i;
    80005018:	894e                	mv	s2,s3
    8000501a:	bf7d                	j	80004fd8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000501c:	4481                	li	s1,0
  iunlockput(ip);
    8000501e:	8556                	mv	a0,s5
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	c18080e7          	jalr	-1000(ra) # 80003c38 <iunlockput>
  end_op();
    80005028:	fffff097          	auipc	ra,0xfffff
    8000502c:	404080e7          	jalr	1028(ra) # 8000442c <end_op>
  p = myproc();
    80005030:	ffffd097          	auipc	ra,0xffffd
    80005034:	962080e7          	jalr	-1694(ra) # 80001992 <myproc>
    80005038:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000503a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000503e:	6785                	lui	a5,0x1
    80005040:	17fd                	addi	a5,a5,-1
    80005042:	94be                	add	s1,s1,a5
    80005044:	77fd                	lui	a5,0xfffff
    80005046:	8fe5                	and	a5,a5,s1
    80005048:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000504c:	6609                	lui	a2,0x2
    8000504e:	963e                	add	a2,a2,a5
    80005050:	85be                	mv	a1,a5
    80005052:	855a                	mv	a0,s6
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	39a080e7          	jalr	922(ra) # 800013ee <uvmalloc>
    8000505c:	8c2a                	mv	s8,a0
  ip = 0;
    8000505e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005060:	12050e63          	beqz	a0,8000519c <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005064:	75f9                	lui	a1,0xffffe
    80005066:	95aa                	add	a1,a1,a0
    80005068:	855a                	mv	a0,s6
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	5a2080e7          	jalr	1442(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80005072:	7afd                	lui	s5,0xfffff
    80005074:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005076:	df043783          	ld	a5,-528(s0)
    8000507a:	6388                	ld	a0,0(a5)
    8000507c:	c925                	beqz	a0,800050ec <exec+0x222>
    8000507e:	e8840993          	addi	s3,s0,-376
    80005082:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005086:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005088:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	db8080e7          	jalr	-584(ra) # 80000e42 <strlen>
    80005092:	0015079b          	addiw	a5,a0,1
    80005096:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000509a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000509e:	13596363          	bltu	s2,s5,800051c4 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050a2:	df043d83          	ld	s11,-528(s0)
    800050a6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050aa:	8552                	mv	a0,s4
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	d96080e7          	jalr	-618(ra) # 80000e42 <strlen>
    800050b4:	0015069b          	addiw	a3,a0,1
    800050b8:	8652                	mv	a2,s4
    800050ba:	85ca                	mv	a1,s2
    800050bc:	855a                	mv	a0,s6
    800050be:	ffffc097          	auipc	ra,0xffffc
    800050c2:	580080e7          	jalr	1408(ra) # 8000163e <copyout>
    800050c6:	10054363          	bltz	a0,800051cc <exec+0x302>
    ustack[argc] = sp;
    800050ca:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050ce:	0485                	addi	s1,s1,1
    800050d0:	008d8793          	addi	a5,s11,8
    800050d4:	def43823          	sd	a5,-528(s0)
    800050d8:	008db503          	ld	a0,8(s11)
    800050dc:	c911                	beqz	a0,800050f0 <exec+0x226>
    if(argc >= MAXARG)
    800050de:	09a1                	addi	s3,s3,8
    800050e0:	fb3c95e3          	bne	s9,s3,8000508a <exec+0x1c0>
  sz = sz1;
    800050e4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050e8:	4a81                	li	s5,0
    800050ea:	a84d                	j	8000519c <exec+0x2d2>
  sp = sz;
    800050ec:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050ee:	4481                	li	s1,0
  ustack[argc] = 0;
    800050f0:	00349793          	slli	a5,s1,0x3
    800050f4:	f9040713          	addi	a4,s0,-112
    800050f8:	97ba                	add	a5,a5,a4
    800050fa:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    800050fe:	00148693          	addi	a3,s1,1
    80005102:	068e                	slli	a3,a3,0x3
    80005104:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005108:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000510c:	01597663          	bgeu	s2,s5,80005118 <exec+0x24e>
  sz = sz1;
    80005110:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005114:	4a81                	li	s5,0
    80005116:	a059                	j	8000519c <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005118:	e8840613          	addi	a2,s0,-376
    8000511c:	85ca                	mv	a1,s2
    8000511e:	855a                	mv	a0,s6
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	51e080e7          	jalr	1310(ra) # 8000163e <copyout>
    80005128:	0a054663          	bltz	a0,800051d4 <exec+0x30a>
  p->trapframe->a1 = sp;
    8000512c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005130:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005134:	de843783          	ld	a5,-536(s0)
    80005138:	0007c703          	lbu	a4,0(a5)
    8000513c:	cf11                	beqz	a4,80005158 <exec+0x28e>
    8000513e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005140:	02f00693          	li	a3,47
    80005144:	a039                	j	80005152 <exec+0x288>
      last = s+1;
    80005146:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000514a:	0785                	addi	a5,a5,1
    8000514c:	fff7c703          	lbu	a4,-1(a5)
    80005150:	c701                	beqz	a4,80005158 <exec+0x28e>
    if(*s == '/')
    80005152:	fed71ce3          	bne	a4,a3,8000514a <exec+0x280>
    80005156:	bfc5                	j	80005146 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005158:	4641                	li	a2,16
    8000515a:	de843583          	ld	a1,-536(s0)
    8000515e:	158b8513          	addi	a0,s7,344
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	cae080e7          	jalr	-850(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    8000516a:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000516e:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005172:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005176:	058bb783          	ld	a5,88(s7)
    8000517a:	e6043703          	ld	a4,-416(s0)
    8000517e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005180:	058bb783          	ld	a5,88(s7)
    80005184:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005188:	85ea                	mv	a1,s10
    8000518a:	ffffd097          	auipc	ra,0xffffd
    8000518e:	968080e7          	jalr	-1688(ra) # 80001af2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005192:	0004851b          	sext.w	a0,s1
    80005196:	bbc1                	j	80004f66 <exec+0x9c>
    80005198:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000519c:	df843583          	ld	a1,-520(s0)
    800051a0:	855a                	mv	a0,s6
    800051a2:	ffffd097          	auipc	ra,0xffffd
    800051a6:	950080e7          	jalr	-1712(ra) # 80001af2 <proc_freepagetable>
  if(ip){
    800051aa:	da0a94e3          	bnez	s5,80004f52 <exec+0x88>
  return -1;
    800051ae:	557d                	li	a0,-1
    800051b0:	bb5d                	j	80004f66 <exec+0x9c>
    800051b2:	de943c23          	sd	s1,-520(s0)
    800051b6:	b7dd                	j	8000519c <exec+0x2d2>
    800051b8:	de943c23          	sd	s1,-520(s0)
    800051bc:	b7c5                	j	8000519c <exec+0x2d2>
    800051be:	de943c23          	sd	s1,-520(s0)
    800051c2:	bfe9                	j	8000519c <exec+0x2d2>
  sz = sz1;
    800051c4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051c8:	4a81                	li	s5,0
    800051ca:	bfc9                	j	8000519c <exec+0x2d2>
  sz = sz1;
    800051cc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051d0:	4a81                	li	s5,0
    800051d2:	b7e9                	j	8000519c <exec+0x2d2>
  sz = sz1;
    800051d4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051d8:	4a81                	li	s5,0
    800051da:	b7c9                	j	8000519c <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051dc:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051e0:	e0843783          	ld	a5,-504(s0)
    800051e4:	0017869b          	addiw	a3,a5,1
    800051e8:	e0d43423          	sd	a3,-504(s0)
    800051ec:	e0043783          	ld	a5,-512(s0)
    800051f0:	0387879b          	addiw	a5,a5,56
    800051f4:	e8045703          	lhu	a4,-384(s0)
    800051f8:	e2e6d3e3          	bge	a3,a4,8000501e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051fc:	2781                	sext.w	a5,a5
    800051fe:	e0f43023          	sd	a5,-512(s0)
    80005202:	03800713          	li	a4,56
    80005206:	86be                	mv	a3,a5
    80005208:	e1040613          	addi	a2,s0,-496
    8000520c:	4581                	li	a1,0
    8000520e:	8556                	mv	a0,s5
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	a7a080e7          	jalr	-1414(ra) # 80003c8a <readi>
    80005218:	03800793          	li	a5,56
    8000521c:	f6f51ee3          	bne	a0,a5,80005198 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005220:	e1042783          	lw	a5,-496(s0)
    80005224:	4705                	li	a4,1
    80005226:	fae79de3          	bne	a5,a4,800051e0 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000522a:	e3843603          	ld	a2,-456(s0)
    8000522e:	e3043783          	ld	a5,-464(s0)
    80005232:	f8f660e3          	bltu	a2,a5,800051b2 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005236:	e2043783          	ld	a5,-480(s0)
    8000523a:	963e                	add	a2,a2,a5
    8000523c:	f6f66ee3          	bltu	a2,a5,800051b8 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005240:	85a6                	mv	a1,s1
    80005242:	855a                	mv	a0,s6
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	1aa080e7          	jalr	426(ra) # 800013ee <uvmalloc>
    8000524c:	dea43c23          	sd	a0,-520(s0)
    80005250:	d53d                	beqz	a0,800051be <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005252:	e2043c03          	ld	s8,-480(s0)
    80005256:	de043783          	ld	a5,-544(s0)
    8000525a:	00fc77b3          	and	a5,s8,a5
    8000525e:	ff9d                	bnez	a5,8000519c <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005260:	e1842c83          	lw	s9,-488(s0)
    80005264:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005268:	f60b8ae3          	beqz	s7,800051dc <exec+0x312>
    8000526c:	89de                	mv	s3,s7
    8000526e:	4481                	li	s1,0
    80005270:	b371                	j	80004ffc <exec+0x132>

0000000080005272 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005272:	7179                	addi	sp,sp,-48
    80005274:	f406                	sd	ra,40(sp)
    80005276:	f022                	sd	s0,32(sp)
    80005278:	ec26                	sd	s1,24(sp)
    8000527a:	e84a                	sd	s2,16(sp)
    8000527c:	1800                	addi	s0,sp,48
    8000527e:	892e                	mv	s2,a1
    80005280:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005282:	fdc40593          	addi	a1,s0,-36
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	aac080e7          	jalr	-1364(ra) # 80002d32 <argint>
    8000528e:	04054063          	bltz	a0,800052ce <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005292:	fdc42703          	lw	a4,-36(s0)
    80005296:	47bd                	li	a5,15
    80005298:	02e7ed63          	bltu	a5,a4,800052d2 <argfd+0x60>
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	6f6080e7          	jalr	1782(ra) # 80001992 <myproc>
    800052a4:	fdc42703          	lw	a4,-36(s0)
    800052a8:	01a70793          	addi	a5,a4,26
    800052ac:	078e                	slli	a5,a5,0x3
    800052ae:	953e                	add	a0,a0,a5
    800052b0:	611c                	ld	a5,0(a0)
    800052b2:	c395                	beqz	a5,800052d6 <argfd+0x64>
    return -1;
  if(pfd)
    800052b4:	00090463          	beqz	s2,800052bc <argfd+0x4a>
    *pfd = fd;
    800052b8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052bc:	4501                	li	a0,0
  if(pf)
    800052be:	c091                	beqz	s1,800052c2 <argfd+0x50>
    *pf = f;
    800052c0:	e09c                	sd	a5,0(s1)
}
    800052c2:	70a2                	ld	ra,40(sp)
    800052c4:	7402                	ld	s0,32(sp)
    800052c6:	64e2                	ld	s1,24(sp)
    800052c8:	6942                	ld	s2,16(sp)
    800052ca:	6145                	addi	sp,sp,48
    800052cc:	8082                	ret
    return -1;
    800052ce:	557d                	li	a0,-1
    800052d0:	bfcd                	j	800052c2 <argfd+0x50>
    return -1;
    800052d2:	557d                	li	a0,-1
    800052d4:	b7fd                	j	800052c2 <argfd+0x50>
    800052d6:	557d                	li	a0,-1
    800052d8:	b7ed                	j	800052c2 <argfd+0x50>

00000000800052da <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052da:	1101                	addi	sp,sp,-32
    800052dc:	ec06                	sd	ra,24(sp)
    800052de:	e822                	sd	s0,16(sp)
    800052e0:	e426                	sd	s1,8(sp)
    800052e2:	1000                	addi	s0,sp,32
    800052e4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052e6:	ffffc097          	auipc	ra,0xffffc
    800052ea:	6ac080e7          	jalr	1708(ra) # 80001992 <myproc>
    800052ee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052f0:	0d050793          	addi	a5,a0,208
    800052f4:	4501                	li	a0,0
    800052f6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052f8:	6398                	ld	a4,0(a5)
    800052fa:	cb19                	beqz	a4,80005310 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052fc:	2505                	addiw	a0,a0,1
    800052fe:	07a1                	addi	a5,a5,8
    80005300:	fed51ce3          	bne	a0,a3,800052f8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005304:	557d                	li	a0,-1
}
    80005306:	60e2                	ld	ra,24(sp)
    80005308:	6442                	ld	s0,16(sp)
    8000530a:	64a2                	ld	s1,8(sp)
    8000530c:	6105                	addi	sp,sp,32
    8000530e:	8082                	ret
      p->ofile[fd] = f;
    80005310:	01a50793          	addi	a5,a0,26
    80005314:	078e                	slli	a5,a5,0x3
    80005316:	963e                	add	a2,a2,a5
    80005318:	e204                	sd	s1,0(a2)
      return fd;
    8000531a:	b7f5                	j	80005306 <fdalloc+0x2c>

000000008000531c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000531c:	715d                	addi	sp,sp,-80
    8000531e:	e486                	sd	ra,72(sp)
    80005320:	e0a2                	sd	s0,64(sp)
    80005322:	fc26                	sd	s1,56(sp)
    80005324:	f84a                	sd	s2,48(sp)
    80005326:	f44e                	sd	s3,40(sp)
    80005328:	f052                	sd	s4,32(sp)
    8000532a:	ec56                	sd	s5,24(sp)
    8000532c:	0880                	addi	s0,sp,80
    8000532e:	89ae                	mv	s3,a1
    80005330:	8ab2                	mv	s5,a2
    80005332:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005334:	fb040593          	addi	a1,s0,-80
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	e72080e7          	jalr	-398(ra) # 800041aa <nameiparent>
    80005340:	892a                	mv	s2,a0
    80005342:	12050e63          	beqz	a0,8000547e <create+0x162>
    return 0;

  ilock(dp);
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	690080e7          	jalr	1680(ra) # 800039d6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000534e:	4601                	li	a2,0
    80005350:	fb040593          	addi	a1,s0,-80
    80005354:	854a                	mv	a0,s2
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	b64080e7          	jalr	-1180(ra) # 80003eba <dirlookup>
    8000535e:	84aa                	mv	s1,a0
    80005360:	c921                	beqz	a0,800053b0 <create+0x94>
    iunlockput(dp);
    80005362:	854a                	mv	a0,s2
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	8d4080e7          	jalr	-1836(ra) # 80003c38 <iunlockput>
    ilock(ip);
    8000536c:	8526                	mv	a0,s1
    8000536e:	ffffe097          	auipc	ra,0xffffe
    80005372:	668080e7          	jalr	1640(ra) # 800039d6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005376:	2981                	sext.w	s3,s3
    80005378:	4789                	li	a5,2
    8000537a:	02f99463          	bne	s3,a5,800053a2 <create+0x86>
    8000537e:	0444d783          	lhu	a5,68(s1)
    80005382:	37f9                	addiw	a5,a5,-2
    80005384:	17c2                	slli	a5,a5,0x30
    80005386:	93c1                	srli	a5,a5,0x30
    80005388:	4705                	li	a4,1
    8000538a:	00f76c63          	bltu	a4,a5,800053a2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000538e:	8526                	mv	a0,s1
    80005390:	60a6                	ld	ra,72(sp)
    80005392:	6406                	ld	s0,64(sp)
    80005394:	74e2                	ld	s1,56(sp)
    80005396:	7942                	ld	s2,48(sp)
    80005398:	79a2                	ld	s3,40(sp)
    8000539a:	7a02                	ld	s4,32(sp)
    8000539c:	6ae2                	ld	s5,24(sp)
    8000539e:	6161                	addi	sp,sp,80
    800053a0:	8082                	ret
    iunlockput(ip);
    800053a2:	8526                	mv	a0,s1
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	894080e7          	jalr	-1900(ra) # 80003c38 <iunlockput>
    return 0;
    800053ac:	4481                	li	s1,0
    800053ae:	b7c5                	j	8000538e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053b0:	85ce                	mv	a1,s3
    800053b2:	00092503          	lw	a0,0(s2)
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	488080e7          	jalr	1160(ra) # 8000383e <ialloc>
    800053be:	84aa                	mv	s1,a0
    800053c0:	c521                	beqz	a0,80005408 <create+0xec>
  ilock(ip);
    800053c2:	ffffe097          	auipc	ra,0xffffe
    800053c6:	614080e7          	jalr	1556(ra) # 800039d6 <ilock>
  ip->major = major;
    800053ca:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053ce:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053d2:	4a05                	li	s4,1
    800053d4:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800053d8:	8526                	mv	a0,s1
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	532080e7          	jalr	1330(ra) # 8000390c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053e2:	2981                	sext.w	s3,s3
    800053e4:	03498a63          	beq	s3,s4,80005418 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053e8:	40d0                	lw	a2,4(s1)
    800053ea:	fb040593          	addi	a1,s0,-80
    800053ee:	854a                	mv	a0,s2
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	cda080e7          	jalr	-806(ra) # 800040ca <dirlink>
    800053f8:	06054b63          	bltz	a0,8000546e <create+0x152>
  iunlockput(dp);
    800053fc:	854a                	mv	a0,s2
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	83a080e7          	jalr	-1990(ra) # 80003c38 <iunlockput>
  return ip;
    80005406:	b761                	j	8000538e <create+0x72>
    panic("create: ialloc");
    80005408:	00003517          	auipc	a0,0x3
    8000540c:	52850513          	addi	a0,a0,1320 # 80008930 <syscalls_str+0x2b0>
    80005410:	ffffb097          	auipc	ra,0xffffb
    80005414:	11a080e7          	jalr	282(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005418:	04a95783          	lhu	a5,74(s2)
    8000541c:	2785                	addiw	a5,a5,1
    8000541e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005422:	854a                	mv	a0,s2
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	4e8080e7          	jalr	1256(ra) # 8000390c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000542c:	40d0                	lw	a2,4(s1)
    8000542e:	00003597          	auipc	a1,0x3
    80005432:	51258593          	addi	a1,a1,1298 # 80008940 <syscalls_str+0x2c0>
    80005436:	8526                	mv	a0,s1
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	c92080e7          	jalr	-878(ra) # 800040ca <dirlink>
    80005440:	00054f63          	bltz	a0,8000545e <create+0x142>
    80005444:	00492603          	lw	a2,4(s2)
    80005448:	00003597          	auipc	a1,0x3
    8000544c:	50058593          	addi	a1,a1,1280 # 80008948 <syscalls_str+0x2c8>
    80005450:	8526                	mv	a0,s1
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	c78080e7          	jalr	-904(ra) # 800040ca <dirlink>
    8000545a:	f80557e3          	bgez	a0,800053e8 <create+0xcc>
      panic("create dots");
    8000545e:	00003517          	auipc	a0,0x3
    80005462:	4f250513          	addi	a0,a0,1266 # 80008950 <syscalls_str+0x2d0>
    80005466:	ffffb097          	auipc	ra,0xffffb
    8000546a:	0c4080e7          	jalr	196(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000546e:	00003517          	auipc	a0,0x3
    80005472:	4f250513          	addi	a0,a0,1266 # 80008960 <syscalls_str+0x2e0>
    80005476:	ffffb097          	auipc	ra,0xffffb
    8000547a:	0b4080e7          	jalr	180(ra) # 8000052a <panic>
    return 0;
    8000547e:	84aa                	mv	s1,a0
    80005480:	b739                	j	8000538e <create+0x72>

0000000080005482 <sys_dup>:
{
    80005482:	7179                	addi	sp,sp,-48
    80005484:	f406                	sd	ra,40(sp)
    80005486:	f022                	sd	s0,32(sp)
    80005488:	ec26                	sd	s1,24(sp)
    8000548a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000548c:	fd840613          	addi	a2,s0,-40
    80005490:	4581                	li	a1,0
    80005492:	4501                	li	a0,0
    80005494:	00000097          	auipc	ra,0x0
    80005498:	dde080e7          	jalr	-546(ra) # 80005272 <argfd>
    return -1;
    8000549c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000549e:	02054363          	bltz	a0,800054c4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054a2:	fd843503          	ld	a0,-40(s0)
    800054a6:	00000097          	auipc	ra,0x0
    800054aa:	e34080e7          	jalr	-460(ra) # 800052da <fdalloc>
    800054ae:	84aa                	mv	s1,a0
    return -1;
    800054b0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054b2:	00054963          	bltz	a0,800054c4 <sys_dup+0x42>
  filedup(f);
    800054b6:	fd843503          	ld	a0,-40(s0)
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	36c080e7          	jalr	876(ra) # 80004826 <filedup>
  return fd;
    800054c2:	87a6                	mv	a5,s1
}
    800054c4:	853e                	mv	a0,a5
    800054c6:	70a2                	ld	ra,40(sp)
    800054c8:	7402                	ld	s0,32(sp)
    800054ca:	64e2                	ld	s1,24(sp)
    800054cc:	6145                	addi	sp,sp,48
    800054ce:	8082                	ret

00000000800054d0 <sys_read>:
{
    800054d0:	7179                	addi	sp,sp,-48
    800054d2:	f406                	sd	ra,40(sp)
    800054d4:	f022                	sd	s0,32(sp)
    800054d6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d8:	fe840613          	addi	a2,s0,-24
    800054dc:	4581                	li	a1,0
    800054de:	4501                	li	a0,0
    800054e0:	00000097          	auipc	ra,0x0
    800054e4:	d92080e7          	jalr	-622(ra) # 80005272 <argfd>
    return -1;
    800054e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ea:	04054163          	bltz	a0,8000552c <sys_read+0x5c>
    800054ee:	fe440593          	addi	a1,s0,-28
    800054f2:	4509                	li	a0,2
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	83e080e7          	jalr	-1986(ra) # 80002d32 <argint>
    return -1;
    800054fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fe:	02054763          	bltz	a0,8000552c <sys_read+0x5c>
    80005502:	fd840593          	addi	a1,s0,-40
    80005506:	4505                	li	a0,1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	84c080e7          	jalr	-1972(ra) # 80002d54 <argaddr>
    return -1;
    80005510:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005512:	00054d63          	bltz	a0,8000552c <sys_read+0x5c>
  return fileread(f, p, n);
    80005516:	fe442603          	lw	a2,-28(s0)
    8000551a:	fd843583          	ld	a1,-40(s0)
    8000551e:	fe843503          	ld	a0,-24(s0)
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	490080e7          	jalr	1168(ra) # 800049b2 <fileread>
    8000552a:	87aa                	mv	a5,a0
}
    8000552c:	853e                	mv	a0,a5
    8000552e:	70a2                	ld	ra,40(sp)
    80005530:	7402                	ld	s0,32(sp)
    80005532:	6145                	addi	sp,sp,48
    80005534:	8082                	ret

0000000080005536 <sys_write>:
{
    80005536:	7179                	addi	sp,sp,-48
    80005538:	f406                	sd	ra,40(sp)
    8000553a:	f022                	sd	s0,32(sp)
    8000553c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000553e:	fe840613          	addi	a2,s0,-24
    80005542:	4581                	li	a1,0
    80005544:	4501                	li	a0,0
    80005546:	00000097          	auipc	ra,0x0
    8000554a:	d2c080e7          	jalr	-724(ra) # 80005272 <argfd>
    return -1;
    8000554e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005550:	04054163          	bltz	a0,80005592 <sys_write+0x5c>
    80005554:	fe440593          	addi	a1,s0,-28
    80005558:	4509                	li	a0,2
    8000555a:	ffffd097          	auipc	ra,0xffffd
    8000555e:	7d8080e7          	jalr	2008(ra) # 80002d32 <argint>
    return -1;
    80005562:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005564:	02054763          	bltz	a0,80005592 <sys_write+0x5c>
    80005568:	fd840593          	addi	a1,s0,-40
    8000556c:	4505                	li	a0,1
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	7e6080e7          	jalr	2022(ra) # 80002d54 <argaddr>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005578:	00054d63          	bltz	a0,80005592 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000557c:	fe442603          	lw	a2,-28(s0)
    80005580:	fd843583          	ld	a1,-40(s0)
    80005584:	fe843503          	ld	a0,-24(s0)
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	4ec080e7          	jalr	1260(ra) # 80004a74 <filewrite>
    80005590:	87aa                	mv	a5,a0
}
    80005592:	853e                	mv	a0,a5
    80005594:	70a2                	ld	ra,40(sp)
    80005596:	7402                	ld	s0,32(sp)
    80005598:	6145                	addi	sp,sp,48
    8000559a:	8082                	ret

000000008000559c <sys_close>:
{
    8000559c:	1101                	addi	sp,sp,-32
    8000559e:	ec06                	sd	ra,24(sp)
    800055a0:	e822                	sd	s0,16(sp)
    800055a2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055a4:	fe040613          	addi	a2,s0,-32
    800055a8:	fec40593          	addi	a1,s0,-20
    800055ac:	4501                	li	a0,0
    800055ae:	00000097          	auipc	ra,0x0
    800055b2:	cc4080e7          	jalr	-828(ra) # 80005272 <argfd>
    return -1;
    800055b6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055b8:	02054463          	bltz	a0,800055e0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055bc:	ffffc097          	auipc	ra,0xffffc
    800055c0:	3d6080e7          	jalr	982(ra) # 80001992 <myproc>
    800055c4:	fec42783          	lw	a5,-20(s0)
    800055c8:	07e9                	addi	a5,a5,26
    800055ca:	078e                	slli	a5,a5,0x3
    800055cc:	97aa                	add	a5,a5,a0
    800055ce:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055d2:	fe043503          	ld	a0,-32(s0)
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	2a2080e7          	jalr	674(ra) # 80004878 <fileclose>
  return 0;
    800055de:	4781                	li	a5,0
}
    800055e0:	853e                	mv	a0,a5
    800055e2:	60e2                	ld	ra,24(sp)
    800055e4:	6442                	ld	s0,16(sp)
    800055e6:	6105                	addi	sp,sp,32
    800055e8:	8082                	ret

00000000800055ea <sys_fstat>:
{
    800055ea:	1101                	addi	sp,sp,-32
    800055ec:	ec06                	sd	ra,24(sp)
    800055ee:	e822                	sd	s0,16(sp)
    800055f0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055f2:	fe840613          	addi	a2,s0,-24
    800055f6:	4581                	li	a1,0
    800055f8:	4501                	li	a0,0
    800055fa:	00000097          	auipc	ra,0x0
    800055fe:	c78080e7          	jalr	-904(ra) # 80005272 <argfd>
    return -1;
    80005602:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005604:	02054563          	bltz	a0,8000562e <sys_fstat+0x44>
    80005608:	fe040593          	addi	a1,s0,-32
    8000560c:	4505                	li	a0,1
    8000560e:	ffffd097          	auipc	ra,0xffffd
    80005612:	746080e7          	jalr	1862(ra) # 80002d54 <argaddr>
    return -1;
    80005616:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005618:	00054b63          	bltz	a0,8000562e <sys_fstat+0x44>
  return filestat(f, st);
    8000561c:	fe043583          	ld	a1,-32(s0)
    80005620:	fe843503          	ld	a0,-24(s0)
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	31c080e7          	jalr	796(ra) # 80004940 <filestat>
    8000562c:	87aa                	mv	a5,a0
}
    8000562e:	853e                	mv	a0,a5
    80005630:	60e2                	ld	ra,24(sp)
    80005632:	6442                	ld	s0,16(sp)
    80005634:	6105                	addi	sp,sp,32
    80005636:	8082                	ret

0000000080005638 <sys_link>:
{
    80005638:	7169                	addi	sp,sp,-304
    8000563a:	f606                	sd	ra,296(sp)
    8000563c:	f222                	sd	s0,288(sp)
    8000563e:	ee26                	sd	s1,280(sp)
    80005640:	ea4a                	sd	s2,272(sp)
    80005642:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005644:	08000613          	li	a2,128
    80005648:	ed040593          	addi	a1,s0,-304
    8000564c:	4501                	li	a0,0
    8000564e:	ffffd097          	auipc	ra,0xffffd
    80005652:	728080e7          	jalr	1832(ra) # 80002d76 <argstr>
    return -1;
    80005656:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005658:	10054e63          	bltz	a0,80005774 <sys_link+0x13c>
    8000565c:	08000613          	li	a2,128
    80005660:	f5040593          	addi	a1,s0,-176
    80005664:	4505                	li	a0,1
    80005666:	ffffd097          	auipc	ra,0xffffd
    8000566a:	710080e7          	jalr	1808(ra) # 80002d76 <argstr>
    return -1;
    8000566e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005670:	10054263          	bltz	a0,80005774 <sys_link+0x13c>
  begin_op();
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	d38080e7          	jalr	-712(ra) # 800043ac <begin_op>
  if((ip = namei(old)) == 0){
    8000567c:	ed040513          	addi	a0,s0,-304
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	b0c080e7          	jalr	-1268(ra) # 8000418c <namei>
    80005688:	84aa                	mv	s1,a0
    8000568a:	c551                	beqz	a0,80005716 <sys_link+0xde>
  ilock(ip);
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	34a080e7          	jalr	842(ra) # 800039d6 <ilock>
  if(ip->type == T_DIR){
    80005694:	04449703          	lh	a4,68(s1)
    80005698:	4785                	li	a5,1
    8000569a:	08f70463          	beq	a4,a5,80005722 <sys_link+0xea>
  ip->nlink++;
    8000569e:	04a4d783          	lhu	a5,74(s1)
    800056a2:	2785                	addiw	a5,a5,1
    800056a4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056a8:	8526                	mv	a0,s1
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	262080e7          	jalr	610(ra) # 8000390c <iupdate>
  iunlock(ip);
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	3e4080e7          	jalr	996(ra) # 80003a98 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056bc:	fd040593          	addi	a1,s0,-48
    800056c0:	f5040513          	addi	a0,s0,-176
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	ae6080e7          	jalr	-1306(ra) # 800041aa <nameiparent>
    800056cc:	892a                	mv	s2,a0
    800056ce:	c935                	beqz	a0,80005742 <sys_link+0x10a>
  ilock(dp);
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	306080e7          	jalr	774(ra) # 800039d6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056d8:	00092703          	lw	a4,0(s2)
    800056dc:	409c                	lw	a5,0(s1)
    800056de:	04f71d63          	bne	a4,a5,80005738 <sys_link+0x100>
    800056e2:	40d0                	lw	a2,4(s1)
    800056e4:	fd040593          	addi	a1,s0,-48
    800056e8:	854a                	mv	a0,s2
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	9e0080e7          	jalr	-1568(ra) # 800040ca <dirlink>
    800056f2:	04054363          	bltz	a0,80005738 <sys_link+0x100>
  iunlockput(dp);
    800056f6:	854a                	mv	a0,s2
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	540080e7          	jalr	1344(ra) # 80003c38 <iunlockput>
  iput(ip);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	48e080e7          	jalr	1166(ra) # 80003b90 <iput>
  end_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	d22080e7          	jalr	-734(ra) # 8000442c <end_op>
  return 0;
    80005712:	4781                	li	a5,0
    80005714:	a085                	j	80005774 <sys_link+0x13c>
    end_op();
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	d16080e7          	jalr	-746(ra) # 8000442c <end_op>
    return -1;
    8000571e:	57fd                	li	a5,-1
    80005720:	a891                	j	80005774 <sys_link+0x13c>
    iunlockput(ip);
    80005722:	8526                	mv	a0,s1
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	514080e7          	jalr	1300(ra) # 80003c38 <iunlockput>
    end_op();
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	d00080e7          	jalr	-768(ra) # 8000442c <end_op>
    return -1;
    80005734:	57fd                	li	a5,-1
    80005736:	a83d                	j	80005774 <sys_link+0x13c>
    iunlockput(dp);
    80005738:	854a                	mv	a0,s2
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	4fe080e7          	jalr	1278(ra) # 80003c38 <iunlockput>
  ilock(ip);
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	292080e7          	jalr	658(ra) # 800039d6 <ilock>
  ip->nlink--;
    8000574c:	04a4d783          	lhu	a5,74(s1)
    80005750:	37fd                	addiw	a5,a5,-1
    80005752:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005756:	8526                	mv	a0,s1
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	1b4080e7          	jalr	436(ra) # 8000390c <iupdate>
  iunlockput(ip);
    80005760:	8526                	mv	a0,s1
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	4d6080e7          	jalr	1238(ra) # 80003c38 <iunlockput>
  end_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	cc2080e7          	jalr	-830(ra) # 8000442c <end_op>
  return -1;
    80005772:	57fd                	li	a5,-1
}
    80005774:	853e                	mv	a0,a5
    80005776:	70b2                	ld	ra,296(sp)
    80005778:	7412                	ld	s0,288(sp)
    8000577a:	64f2                	ld	s1,280(sp)
    8000577c:	6952                	ld	s2,272(sp)
    8000577e:	6155                	addi	sp,sp,304
    80005780:	8082                	ret

0000000080005782 <sys_unlink>:
{
    80005782:	7151                	addi	sp,sp,-240
    80005784:	f586                	sd	ra,232(sp)
    80005786:	f1a2                	sd	s0,224(sp)
    80005788:	eda6                	sd	s1,216(sp)
    8000578a:	e9ca                	sd	s2,208(sp)
    8000578c:	e5ce                	sd	s3,200(sp)
    8000578e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005790:	08000613          	li	a2,128
    80005794:	f3040593          	addi	a1,s0,-208
    80005798:	4501                	li	a0,0
    8000579a:	ffffd097          	auipc	ra,0xffffd
    8000579e:	5dc080e7          	jalr	1500(ra) # 80002d76 <argstr>
    800057a2:	18054163          	bltz	a0,80005924 <sys_unlink+0x1a2>
  begin_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	c06080e7          	jalr	-1018(ra) # 800043ac <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057ae:	fb040593          	addi	a1,s0,-80
    800057b2:	f3040513          	addi	a0,s0,-208
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	9f4080e7          	jalr	-1548(ra) # 800041aa <nameiparent>
    800057be:	84aa                	mv	s1,a0
    800057c0:	c979                	beqz	a0,80005896 <sys_unlink+0x114>
  ilock(dp);
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	214080e7          	jalr	532(ra) # 800039d6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057ca:	00003597          	auipc	a1,0x3
    800057ce:	17658593          	addi	a1,a1,374 # 80008940 <syscalls_str+0x2c0>
    800057d2:	fb040513          	addi	a0,s0,-80
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	6ca080e7          	jalr	1738(ra) # 80003ea0 <namecmp>
    800057de:	14050a63          	beqz	a0,80005932 <sys_unlink+0x1b0>
    800057e2:	00003597          	auipc	a1,0x3
    800057e6:	16658593          	addi	a1,a1,358 # 80008948 <syscalls_str+0x2c8>
    800057ea:	fb040513          	addi	a0,s0,-80
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	6b2080e7          	jalr	1714(ra) # 80003ea0 <namecmp>
    800057f6:	12050e63          	beqz	a0,80005932 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057fa:	f2c40613          	addi	a2,s0,-212
    800057fe:	fb040593          	addi	a1,s0,-80
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	6b6080e7          	jalr	1718(ra) # 80003eba <dirlookup>
    8000580c:	892a                	mv	s2,a0
    8000580e:	12050263          	beqz	a0,80005932 <sys_unlink+0x1b0>
  ilock(ip);
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	1c4080e7          	jalr	452(ra) # 800039d6 <ilock>
  if(ip->nlink < 1)
    8000581a:	04a91783          	lh	a5,74(s2)
    8000581e:	08f05263          	blez	a5,800058a2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005822:	04491703          	lh	a4,68(s2)
    80005826:	4785                	li	a5,1
    80005828:	08f70563          	beq	a4,a5,800058b2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000582c:	4641                	li	a2,16
    8000582e:	4581                	li	a1,0
    80005830:	fc040513          	addi	a0,s0,-64
    80005834:	ffffb097          	auipc	ra,0xffffb
    80005838:	48a080e7          	jalr	1162(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000583c:	4741                	li	a4,16
    8000583e:	f2c42683          	lw	a3,-212(s0)
    80005842:	fc040613          	addi	a2,s0,-64
    80005846:	4581                	li	a1,0
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	538080e7          	jalr	1336(ra) # 80003d82 <writei>
    80005852:	47c1                	li	a5,16
    80005854:	0af51563          	bne	a0,a5,800058fe <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005858:	04491703          	lh	a4,68(s2)
    8000585c:	4785                	li	a5,1
    8000585e:	0af70863          	beq	a4,a5,8000590e <sys_unlink+0x18c>
  iunlockput(dp);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	3d4080e7          	jalr	980(ra) # 80003c38 <iunlockput>
  ip->nlink--;
    8000586c:	04a95783          	lhu	a5,74(s2)
    80005870:	37fd                	addiw	a5,a5,-1
    80005872:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	094080e7          	jalr	148(ra) # 8000390c <iupdate>
  iunlockput(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	3b6080e7          	jalr	950(ra) # 80003c38 <iunlockput>
  end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	ba2080e7          	jalr	-1118(ra) # 8000442c <end_op>
  return 0;
    80005892:	4501                	li	a0,0
    80005894:	a84d                	j	80005946 <sys_unlink+0x1c4>
    end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	b96080e7          	jalr	-1130(ra) # 8000442c <end_op>
    return -1;
    8000589e:	557d                	li	a0,-1
    800058a0:	a05d                	j	80005946 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058a2:	00003517          	auipc	a0,0x3
    800058a6:	0ce50513          	addi	a0,a0,206 # 80008970 <syscalls_str+0x2f0>
    800058aa:	ffffb097          	auipc	ra,0xffffb
    800058ae:	c80080e7          	jalr	-896(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058b2:	04c92703          	lw	a4,76(s2)
    800058b6:	02000793          	li	a5,32
    800058ba:	f6e7f9e3          	bgeu	a5,a4,8000582c <sys_unlink+0xaa>
    800058be:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058c2:	4741                	li	a4,16
    800058c4:	86ce                	mv	a3,s3
    800058c6:	f1840613          	addi	a2,s0,-232
    800058ca:	4581                	li	a1,0
    800058cc:	854a                	mv	a0,s2
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	3bc080e7          	jalr	956(ra) # 80003c8a <readi>
    800058d6:	47c1                	li	a5,16
    800058d8:	00f51b63          	bne	a0,a5,800058ee <sys_unlink+0x16c>
    if(de.inum != 0)
    800058dc:	f1845783          	lhu	a5,-232(s0)
    800058e0:	e7a1                	bnez	a5,80005928 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058e2:	29c1                	addiw	s3,s3,16
    800058e4:	04c92783          	lw	a5,76(s2)
    800058e8:	fcf9ede3          	bltu	s3,a5,800058c2 <sys_unlink+0x140>
    800058ec:	b781                	j	8000582c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058ee:	00003517          	auipc	a0,0x3
    800058f2:	09a50513          	addi	a0,a0,154 # 80008988 <syscalls_str+0x308>
    800058f6:	ffffb097          	auipc	ra,0xffffb
    800058fa:	c34080e7          	jalr	-972(ra) # 8000052a <panic>
    panic("unlink: writei");
    800058fe:	00003517          	auipc	a0,0x3
    80005902:	0a250513          	addi	a0,a0,162 # 800089a0 <syscalls_str+0x320>
    80005906:	ffffb097          	auipc	ra,0xffffb
    8000590a:	c24080e7          	jalr	-988(ra) # 8000052a <panic>
    dp->nlink--;
    8000590e:	04a4d783          	lhu	a5,74(s1)
    80005912:	37fd                	addiw	a5,a5,-1
    80005914:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	ff2080e7          	jalr	-14(ra) # 8000390c <iupdate>
    80005922:	b781                	j	80005862 <sys_unlink+0xe0>
    return -1;
    80005924:	557d                	li	a0,-1
    80005926:	a005                	j	80005946 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005928:	854a                	mv	a0,s2
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	30e080e7          	jalr	782(ra) # 80003c38 <iunlockput>
  iunlockput(dp);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	304080e7          	jalr	772(ra) # 80003c38 <iunlockput>
  end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	af0080e7          	jalr	-1296(ra) # 8000442c <end_op>
  return -1;
    80005944:	557d                	li	a0,-1
}
    80005946:	70ae                	ld	ra,232(sp)
    80005948:	740e                	ld	s0,224(sp)
    8000594a:	64ee                	ld	s1,216(sp)
    8000594c:	694e                	ld	s2,208(sp)
    8000594e:	69ae                	ld	s3,200(sp)
    80005950:	616d                	addi	sp,sp,240
    80005952:	8082                	ret

0000000080005954 <sys_open>:

uint64
sys_open(void)
{
    80005954:	7131                	addi	sp,sp,-192
    80005956:	fd06                	sd	ra,184(sp)
    80005958:	f922                	sd	s0,176(sp)
    8000595a:	f526                	sd	s1,168(sp)
    8000595c:	f14a                	sd	s2,160(sp)
    8000595e:	ed4e                	sd	s3,152(sp)
    80005960:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005962:	08000613          	li	a2,128
    80005966:	f5040593          	addi	a1,s0,-176
    8000596a:	4501                	li	a0,0
    8000596c:	ffffd097          	auipc	ra,0xffffd
    80005970:	40a080e7          	jalr	1034(ra) # 80002d76 <argstr>
    return -1;
    80005974:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005976:	0c054163          	bltz	a0,80005a38 <sys_open+0xe4>
    8000597a:	f4c40593          	addi	a1,s0,-180
    8000597e:	4505                	li	a0,1
    80005980:	ffffd097          	auipc	ra,0xffffd
    80005984:	3b2080e7          	jalr	946(ra) # 80002d32 <argint>
    80005988:	0a054863          	bltz	a0,80005a38 <sys_open+0xe4>

  begin_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	a20080e7          	jalr	-1504(ra) # 800043ac <begin_op>

  if(omode & O_CREATE){
    80005994:	f4c42783          	lw	a5,-180(s0)
    80005998:	2007f793          	andi	a5,a5,512
    8000599c:	cbdd                	beqz	a5,80005a52 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000599e:	4681                	li	a3,0
    800059a0:	4601                	li	a2,0
    800059a2:	4589                	li	a1,2
    800059a4:	f5040513          	addi	a0,s0,-176
    800059a8:	00000097          	auipc	ra,0x0
    800059ac:	974080e7          	jalr	-1676(ra) # 8000531c <create>
    800059b0:	892a                	mv	s2,a0
    if(ip == 0){
    800059b2:	c959                	beqz	a0,80005a48 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059b4:	04491703          	lh	a4,68(s2)
    800059b8:	478d                	li	a5,3
    800059ba:	00f71763          	bne	a4,a5,800059c8 <sys_open+0x74>
    800059be:	04695703          	lhu	a4,70(s2)
    800059c2:	47a5                	li	a5,9
    800059c4:	0ce7ec63          	bltu	a5,a4,80005a9c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	df4080e7          	jalr	-524(ra) # 800047bc <filealloc>
    800059d0:	89aa                	mv	s3,a0
    800059d2:	10050263          	beqz	a0,80005ad6 <sys_open+0x182>
    800059d6:	00000097          	auipc	ra,0x0
    800059da:	904080e7          	jalr	-1788(ra) # 800052da <fdalloc>
    800059de:	84aa                	mv	s1,a0
    800059e0:	0e054663          	bltz	a0,80005acc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059e4:	04491703          	lh	a4,68(s2)
    800059e8:	478d                	li	a5,3
    800059ea:	0cf70463          	beq	a4,a5,80005ab2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059ee:	4789                	li	a5,2
    800059f0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059f4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059f8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059fc:	f4c42783          	lw	a5,-180(s0)
    80005a00:	0017c713          	xori	a4,a5,1
    80005a04:	8b05                	andi	a4,a4,1
    80005a06:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a0a:	0037f713          	andi	a4,a5,3
    80005a0e:	00e03733          	snez	a4,a4
    80005a12:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a16:	4007f793          	andi	a5,a5,1024
    80005a1a:	c791                	beqz	a5,80005a26 <sys_open+0xd2>
    80005a1c:	04491703          	lh	a4,68(s2)
    80005a20:	4789                	li	a5,2
    80005a22:	08f70f63          	beq	a4,a5,80005ac0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a26:	854a                	mv	a0,s2
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	070080e7          	jalr	112(ra) # 80003a98 <iunlock>
  end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	9fc080e7          	jalr	-1540(ra) # 8000442c <end_op>

  return fd;
}
    80005a38:	8526                	mv	a0,s1
    80005a3a:	70ea                	ld	ra,184(sp)
    80005a3c:	744a                	ld	s0,176(sp)
    80005a3e:	74aa                	ld	s1,168(sp)
    80005a40:	790a                	ld	s2,160(sp)
    80005a42:	69ea                	ld	s3,152(sp)
    80005a44:	6129                	addi	sp,sp,192
    80005a46:	8082                	ret
      end_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	9e4080e7          	jalr	-1564(ra) # 8000442c <end_op>
      return -1;
    80005a50:	b7e5                	j	80005a38 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a52:	f5040513          	addi	a0,s0,-176
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	736080e7          	jalr	1846(ra) # 8000418c <namei>
    80005a5e:	892a                	mv	s2,a0
    80005a60:	c905                	beqz	a0,80005a90 <sys_open+0x13c>
    ilock(ip);
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	f74080e7          	jalr	-140(ra) # 800039d6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a6a:	04491703          	lh	a4,68(s2)
    80005a6e:	4785                	li	a5,1
    80005a70:	f4f712e3          	bne	a4,a5,800059b4 <sys_open+0x60>
    80005a74:	f4c42783          	lw	a5,-180(s0)
    80005a78:	dba1                	beqz	a5,800059c8 <sys_open+0x74>
      iunlockput(ip);
    80005a7a:	854a                	mv	a0,s2
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	1bc080e7          	jalr	444(ra) # 80003c38 <iunlockput>
      end_op();
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	9a8080e7          	jalr	-1624(ra) # 8000442c <end_op>
      return -1;
    80005a8c:	54fd                	li	s1,-1
    80005a8e:	b76d                	j	80005a38 <sys_open+0xe4>
      end_op();
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	99c080e7          	jalr	-1636(ra) # 8000442c <end_op>
      return -1;
    80005a98:	54fd                	li	s1,-1
    80005a9a:	bf79                	j	80005a38 <sys_open+0xe4>
    iunlockput(ip);
    80005a9c:	854a                	mv	a0,s2
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	19a080e7          	jalr	410(ra) # 80003c38 <iunlockput>
    end_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	986080e7          	jalr	-1658(ra) # 8000442c <end_op>
    return -1;
    80005aae:	54fd                	li	s1,-1
    80005ab0:	b761                	j	80005a38 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ab2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ab6:	04691783          	lh	a5,70(s2)
    80005aba:	02f99223          	sh	a5,36(s3)
    80005abe:	bf2d                	j	800059f8 <sys_open+0xa4>
    itrunc(ip);
    80005ac0:	854a                	mv	a0,s2
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	022080e7          	jalr	34(ra) # 80003ae4 <itrunc>
    80005aca:	bfb1                	j	80005a26 <sys_open+0xd2>
      fileclose(f);
    80005acc:	854e                	mv	a0,s3
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	daa080e7          	jalr	-598(ra) # 80004878 <fileclose>
    iunlockput(ip);
    80005ad6:	854a                	mv	a0,s2
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	160080e7          	jalr	352(ra) # 80003c38 <iunlockput>
    end_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	94c080e7          	jalr	-1716(ra) # 8000442c <end_op>
    return -1;
    80005ae8:	54fd                	li	s1,-1
    80005aea:	b7b9                	j	80005a38 <sys_open+0xe4>

0000000080005aec <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005aec:	7175                	addi	sp,sp,-144
    80005aee:	e506                	sd	ra,136(sp)
    80005af0:	e122                	sd	s0,128(sp)
    80005af2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	8b8080e7          	jalr	-1864(ra) # 800043ac <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005afc:	08000613          	li	a2,128
    80005b00:	f7040593          	addi	a1,s0,-144
    80005b04:	4501                	li	a0,0
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	270080e7          	jalr	624(ra) # 80002d76 <argstr>
    80005b0e:	02054963          	bltz	a0,80005b40 <sys_mkdir+0x54>
    80005b12:	4681                	li	a3,0
    80005b14:	4601                	li	a2,0
    80005b16:	4585                	li	a1,1
    80005b18:	f7040513          	addi	a0,s0,-144
    80005b1c:	00000097          	auipc	ra,0x0
    80005b20:	800080e7          	jalr	-2048(ra) # 8000531c <create>
    80005b24:	cd11                	beqz	a0,80005b40 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	112080e7          	jalr	274(ra) # 80003c38 <iunlockput>
  end_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	8fe080e7          	jalr	-1794(ra) # 8000442c <end_op>
  return 0;
    80005b36:	4501                	li	a0,0
}
    80005b38:	60aa                	ld	ra,136(sp)
    80005b3a:	640a                	ld	s0,128(sp)
    80005b3c:	6149                	addi	sp,sp,144
    80005b3e:	8082                	ret
    end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	8ec080e7          	jalr	-1812(ra) # 8000442c <end_op>
    return -1;
    80005b48:	557d                	li	a0,-1
    80005b4a:	b7fd                	j	80005b38 <sys_mkdir+0x4c>

0000000080005b4c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b4c:	7135                	addi	sp,sp,-160
    80005b4e:	ed06                	sd	ra,152(sp)
    80005b50:	e922                	sd	s0,144(sp)
    80005b52:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	858080e7          	jalr	-1960(ra) # 800043ac <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b5c:	08000613          	li	a2,128
    80005b60:	f7040593          	addi	a1,s0,-144
    80005b64:	4501                	li	a0,0
    80005b66:	ffffd097          	auipc	ra,0xffffd
    80005b6a:	210080e7          	jalr	528(ra) # 80002d76 <argstr>
    80005b6e:	04054a63          	bltz	a0,80005bc2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b72:	f6c40593          	addi	a1,s0,-148
    80005b76:	4505                	li	a0,1
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	1ba080e7          	jalr	442(ra) # 80002d32 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b80:	04054163          	bltz	a0,80005bc2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b84:	f6840593          	addi	a1,s0,-152
    80005b88:	4509                	li	a0,2
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	1a8080e7          	jalr	424(ra) # 80002d32 <argint>
     argint(1, &major) < 0 ||
    80005b92:	02054863          	bltz	a0,80005bc2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b96:	f6841683          	lh	a3,-152(s0)
    80005b9a:	f6c41603          	lh	a2,-148(s0)
    80005b9e:	458d                	li	a1,3
    80005ba0:	f7040513          	addi	a0,s0,-144
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	778080e7          	jalr	1912(ra) # 8000531c <create>
     argint(2, &minor) < 0 ||
    80005bac:	c919                	beqz	a0,80005bc2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	08a080e7          	jalr	138(ra) # 80003c38 <iunlockput>
  end_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	876080e7          	jalr	-1930(ra) # 8000442c <end_op>
  return 0;
    80005bbe:	4501                	li	a0,0
    80005bc0:	a031                	j	80005bcc <sys_mknod+0x80>
    end_op();
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	86a080e7          	jalr	-1942(ra) # 8000442c <end_op>
    return -1;
    80005bca:	557d                	li	a0,-1
}
    80005bcc:	60ea                	ld	ra,152(sp)
    80005bce:	644a                	ld	s0,144(sp)
    80005bd0:	610d                	addi	sp,sp,160
    80005bd2:	8082                	ret

0000000080005bd4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bd4:	7135                	addi	sp,sp,-160
    80005bd6:	ed06                	sd	ra,152(sp)
    80005bd8:	e922                	sd	s0,144(sp)
    80005bda:	e526                	sd	s1,136(sp)
    80005bdc:	e14a                	sd	s2,128(sp)
    80005bde:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005be0:	ffffc097          	auipc	ra,0xffffc
    80005be4:	db2080e7          	jalr	-590(ra) # 80001992 <myproc>
    80005be8:	892a                	mv	s2,a0
  
  begin_op();
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	7c2080e7          	jalr	1986(ra) # 800043ac <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bf2:	08000613          	li	a2,128
    80005bf6:	f6040593          	addi	a1,s0,-160
    80005bfa:	4501                	li	a0,0
    80005bfc:	ffffd097          	auipc	ra,0xffffd
    80005c00:	17a080e7          	jalr	378(ra) # 80002d76 <argstr>
    80005c04:	04054b63          	bltz	a0,80005c5a <sys_chdir+0x86>
    80005c08:	f6040513          	addi	a0,s0,-160
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	580080e7          	jalr	1408(ra) # 8000418c <namei>
    80005c14:	84aa                	mv	s1,a0
    80005c16:	c131                	beqz	a0,80005c5a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	dbe080e7          	jalr	-578(ra) # 800039d6 <ilock>
  if(ip->type != T_DIR){
    80005c20:	04449703          	lh	a4,68(s1)
    80005c24:	4785                	li	a5,1
    80005c26:	04f71063          	bne	a4,a5,80005c66 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c2a:	8526                	mv	a0,s1
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	e6c080e7          	jalr	-404(ra) # 80003a98 <iunlock>
  iput(p->cwd);
    80005c34:	15093503          	ld	a0,336(s2)
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	f58080e7          	jalr	-168(ra) # 80003b90 <iput>
  end_op();
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	7ec080e7          	jalr	2028(ra) # 8000442c <end_op>
  p->cwd = ip;
    80005c48:	14993823          	sd	s1,336(s2)
  return 0;
    80005c4c:	4501                	li	a0,0
}
    80005c4e:	60ea                	ld	ra,152(sp)
    80005c50:	644a                	ld	s0,144(sp)
    80005c52:	64aa                	ld	s1,136(sp)
    80005c54:	690a                	ld	s2,128(sp)
    80005c56:	610d                	addi	sp,sp,160
    80005c58:	8082                	ret
    end_op();
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	7d2080e7          	jalr	2002(ra) # 8000442c <end_op>
    return -1;
    80005c62:	557d                	li	a0,-1
    80005c64:	b7ed                	j	80005c4e <sys_chdir+0x7a>
    iunlockput(ip);
    80005c66:	8526                	mv	a0,s1
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	fd0080e7          	jalr	-48(ra) # 80003c38 <iunlockput>
    end_op();
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	7bc080e7          	jalr	1980(ra) # 8000442c <end_op>
    return -1;
    80005c78:	557d                	li	a0,-1
    80005c7a:	bfd1                	j	80005c4e <sys_chdir+0x7a>

0000000080005c7c <sys_exec>:

uint64
sys_exec(void)
{
    80005c7c:	7145                	addi	sp,sp,-464
    80005c7e:	e786                	sd	ra,456(sp)
    80005c80:	e3a2                	sd	s0,448(sp)
    80005c82:	ff26                	sd	s1,440(sp)
    80005c84:	fb4a                	sd	s2,432(sp)
    80005c86:	f74e                	sd	s3,424(sp)
    80005c88:	f352                	sd	s4,416(sp)
    80005c8a:	ef56                	sd	s5,408(sp)
    80005c8c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c8e:	08000613          	li	a2,128
    80005c92:	f4040593          	addi	a1,s0,-192
    80005c96:	4501                	li	a0,0
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	0de080e7          	jalr	222(ra) # 80002d76 <argstr>
    return -1;
    80005ca0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ca2:	0c054a63          	bltz	a0,80005d76 <sys_exec+0xfa>
    80005ca6:	e3840593          	addi	a1,s0,-456
    80005caa:	4505                	li	a0,1
    80005cac:	ffffd097          	auipc	ra,0xffffd
    80005cb0:	0a8080e7          	jalr	168(ra) # 80002d54 <argaddr>
    80005cb4:	0c054163          	bltz	a0,80005d76 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cb8:	10000613          	li	a2,256
    80005cbc:	4581                	li	a1,0
    80005cbe:	e4040513          	addi	a0,s0,-448
    80005cc2:	ffffb097          	auipc	ra,0xffffb
    80005cc6:	ffc080e7          	jalr	-4(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cca:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cce:	89a6                	mv	s3,s1
    80005cd0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cd2:	02000a13          	li	s4,32
    80005cd6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cda:	00391793          	slli	a5,s2,0x3
    80005cde:	e3040593          	addi	a1,s0,-464
    80005ce2:	e3843503          	ld	a0,-456(s0)
    80005ce6:	953e                	add	a0,a0,a5
    80005ce8:	ffffd097          	auipc	ra,0xffffd
    80005cec:	fb0080e7          	jalr	-80(ra) # 80002c98 <fetchaddr>
    80005cf0:	02054a63          	bltz	a0,80005d24 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cf4:	e3043783          	ld	a5,-464(s0)
    80005cf8:	c3b9                	beqz	a5,80005d3e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	dd8080e7          	jalr	-552(ra) # 80000ad2 <kalloc>
    80005d02:	85aa                	mv	a1,a0
    80005d04:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d08:	cd11                	beqz	a0,80005d24 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d0a:	6605                	lui	a2,0x1
    80005d0c:	e3043503          	ld	a0,-464(s0)
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	fda080e7          	jalr	-38(ra) # 80002cea <fetchstr>
    80005d18:	00054663          	bltz	a0,80005d24 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d1c:	0905                	addi	s2,s2,1
    80005d1e:	09a1                	addi	s3,s3,8
    80005d20:	fb491be3          	bne	s2,s4,80005cd6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d24:	10048913          	addi	s2,s1,256
    80005d28:	6088                	ld	a0,0(s1)
    80005d2a:	c529                	beqz	a0,80005d74 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d2c:	ffffb097          	auipc	ra,0xffffb
    80005d30:	caa080e7          	jalr	-854(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d34:	04a1                	addi	s1,s1,8
    80005d36:	ff2499e3          	bne	s1,s2,80005d28 <sys_exec+0xac>
  return -1;
    80005d3a:	597d                	li	s2,-1
    80005d3c:	a82d                	j	80005d76 <sys_exec+0xfa>
      argv[i] = 0;
    80005d3e:	0a8e                	slli	s5,s5,0x3
    80005d40:	fc040793          	addi	a5,s0,-64
    80005d44:	9abe                	add	s5,s5,a5
    80005d46:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005d4a:	e4040593          	addi	a1,s0,-448
    80005d4e:	f4040513          	addi	a0,s0,-192
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	178080e7          	jalr	376(ra) # 80004eca <exec>
    80005d5a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d5c:	10048993          	addi	s3,s1,256
    80005d60:	6088                	ld	a0,0(s1)
    80005d62:	c911                	beqz	a0,80005d76 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d64:	ffffb097          	auipc	ra,0xffffb
    80005d68:	c72080e7          	jalr	-910(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d6c:	04a1                	addi	s1,s1,8
    80005d6e:	ff3499e3          	bne	s1,s3,80005d60 <sys_exec+0xe4>
    80005d72:	a011                	j	80005d76 <sys_exec+0xfa>
  return -1;
    80005d74:	597d                	li	s2,-1
}
    80005d76:	854a                	mv	a0,s2
    80005d78:	60be                	ld	ra,456(sp)
    80005d7a:	641e                	ld	s0,448(sp)
    80005d7c:	74fa                	ld	s1,440(sp)
    80005d7e:	795a                	ld	s2,432(sp)
    80005d80:	79ba                	ld	s3,424(sp)
    80005d82:	7a1a                	ld	s4,416(sp)
    80005d84:	6afa                	ld	s5,408(sp)
    80005d86:	6179                	addi	sp,sp,464
    80005d88:	8082                	ret

0000000080005d8a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d8a:	7139                	addi	sp,sp,-64
    80005d8c:	fc06                	sd	ra,56(sp)
    80005d8e:	f822                	sd	s0,48(sp)
    80005d90:	f426                	sd	s1,40(sp)
    80005d92:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d94:	ffffc097          	auipc	ra,0xffffc
    80005d98:	bfe080e7          	jalr	-1026(ra) # 80001992 <myproc>
    80005d9c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d9e:	fd840593          	addi	a1,s0,-40
    80005da2:	4501                	li	a0,0
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	fb0080e7          	jalr	-80(ra) # 80002d54 <argaddr>
    return -1;
    80005dac:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005dae:	0e054063          	bltz	a0,80005e8e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005db2:	fc840593          	addi	a1,s0,-56
    80005db6:	fd040513          	addi	a0,s0,-48
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	dee080e7          	jalr	-530(ra) # 80004ba8 <pipealloc>
    return -1;
    80005dc2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dc4:	0c054563          	bltz	a0,80005e8e <sys_pipe+0x104>
  fd0 = -1;
    80005dc8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dcc:	fd043503          	ld	a0,-48(s0)
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	50a080e7          	jalr	1290(ra) # 800052da <fdalloc>
    80005dd8:	fca42223          	sw	a0,-60(s0)
    80005ddc:	08054c63          	bltz	a0,80005e74 <sys_pipe+0xea>
    80005de0:	fc843503          	ld	a0,-56(s0)
    80005de4:	fffff097          	auipc	ra,0xfffff
    80005de8:	4f6080e7          	jalr	1270(ra) # 800052da <fdalloc>
    80005dec:	fca42023          	sw	a0,-64(s0)
    80005df0:	06054863          	bltz	a0,80005e60 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005df4:	4691                	li	a3,4
    80005df6:	fc440613          	addi	a2,s0,-60
    80005dfa:	fd843583          	ld	a1,-40(s0)
    80005dfe:	68a8                	ld	a0,80(s1)
    80005e00:	ffffc097          	auipc	ra,0xffffc
    80005e04:	83e080e7          	jalr	-1986(ra) # 8000163e <copyout>
    80005e08:	02054063          	bltz	a0,80005e28 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e0c:	4691                	li	a3,4
    80005e0e:	fc040613          	addi	a2,s0,-64
    80005e12:	fd843583          	ld	a1,-40(s0)
    80005e16:	0591                	addi	a1,a1,4
    80005e18:	68a8                	ld	a0,80(s1)
    80005e1a:	ffffc097          	auipc	ra,0xffffc
    80005e1e:	824080e7          	jalr	-2012(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e22:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e24:	06055563          	bgez	a0,80005e8e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e28:	fc442783          	lw	a5,-60(s0)
    80005e2c:	07e9                	addi	a5,a5,26
    80005e2e:	078e                	slli	a5,a5,0x3
    80005e30:	97a6                	add	a5,a5,s1
    80005e32:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e36:	fc042503          	lw	a0,-64(s0)
    80005e3a:	0569                	addi	a0,a0,26
    80005e3c:	050e                	slli	a0,a0,0x3
    80005e3e:	9526                	add	a0,a0,s1
    80005e40:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e44:	fd043503          	ld	a0,-48(s0)
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	a30080e7          	jalr	-1488(ra) # 80004878 <fileclose>
    fileclose(wf);
    80005e50:	fc843503          	ld	a0,-56(s0)
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	a24080e7          	jalr	-1500(ra) # 80004878 <fileclose>
    return -1;
    80005e5c:	57fd                	li	a5,-1
    80005e5e:	a805                	j	80005e8e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e60:	fc442783          	lw	a5,-60(s0)
    80005e64:	0007c863          	bltz	a5,80005e74 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e68:	01a78513          	addi	a0,a5,26
    80005e6c:	050e                	slli	a0,a0,0x3
    80005e6e:	9526                	add	a0,a0,s1
    80005e70:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e74:	fd043503          	ld	a0,-48(s0)
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	a00080e7          	jalr	-1536(ra) # 80004878 <fileclose>
    fileclose(wf);
    80005e80:	fc843503          	ld	a0,-56(s0)
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	9f4080e7          	jalr	-1548(ra) # 80004878 <fileclose>
    return -1;
    80005e8c:	57fd                	li	a5,-1
}
    80005e8e:	853e                	mv	a0,a5
    80005e90:	70e2                	ld	ra,56(sp)
    80005e92:	7442                	ld	s0,48(sp)
    80005e94:	74a2                	ld	s1,40(sp)
    80005e96:	6121                	addi	sp,sp,64
    80005e98:	8082                	ret
    80005e9a:	0000                	unimp
    80005e9c:	0000                	unimp
	...

0000000080005ea0 <kernelvec>:
    80005ea0:	7111                	addi	sp,sp,-256
    80005ea2:	e006                	sd	ra,0(sp)
    80005ea4:	e40a                	sd	sp,8(sp)
    80005ea6:	e80e                	sd	gp,16(sp)
    80005ea8:	ec12                	sd	tp,24(sp)
    80005eaa:	f016                	sd	t0,32(sp)
    80005eac:	f41a                	sd	t1,40(sp)
    80005eae:	f81e                	sd	t2,48(sp)
    80005eb0:	fc22                	sd	s0,56(sp)
    80005eb2:	e0a6                	sd	s1,64(sp)
    80005eb4:	e4aa                	sd	a0,72(sp)
    80005eb6:	e8ae                	sd	a1,80(sp)
    80005eb8:	ecb2                	sd	a2,88(sp)
    80005eba:	f0b6                	sd	a3,96(sp)
    80005ebc:	f4ba                	sd	a4,104(sp)
    80005ebe:	f8be                	sd	a5,112(sp)
    80005ec0:	fcc2                	sd	a6,120(sp)
    80005ec2:	e146                	sd	a7,128(sp)
    80005ec4:	e54a                	sd	s2,136(sp)
    80005ec6:	e94e                	sd	s3,144(sp)
    80005ec8:	ed52                	sd	s4,152(sp)
    80005eca:	f156                	sd	s5,160(sp)
    80005ecc:	f55a                	sd	s6,168(sp)
    80005ece:	f95e                	sd	s7,176(sp)
    80005ed0:	fd62                	sd	s8,184(sp)
    80005ed2:	e1e6                	sd	s9,192(sp)
    80005ed4:	e5ea                	sd	s10,200(sp)
    80005ed6:	e9ee                	sd	s11,208(sp)
    80005ed8:	edf2                	sd	t3,216(sp)
    80005eda:	f1f6                	sd	t4,224(sp)
    80005edc:	f5fa                	sd	t5,232(sp)
    80005ede:	f9fe                	sd	t6,240(sp)
    80005ee0:	c85fc0ef          	jal	ra,80002b64 <kerneltrap>
    80005ee4:	6082                	ld	ra,0(sp)
    80005ee6:	6122                	ld	sp,8(sp)
    80005ee8:	61c2                	ld	gp,16(sp)
    80005eea:	7282                	ld	t0,32(sp)
    80005eec:	7322                	ld	t1,40(sp)
    80005eee:	73c2                	ld	t2,48(sp)
    80005ef0:	7462                	ld	s0,56(sp)
    80005ef2:	6486                	ld	s1,64(sp)
    80005ef4:	6526                	ld	a0,72(sp)
    80005ef6:	65c6                	ld	a1,80(sp)
    80005ef8:	6666                	ld	a2,88(sp)
    80005efa:	7686                	ld	a3,96(sp)
    80005efc:	7726                	ld	a4,104(sp)
    80005efe:	77c6                	ld	a5,112(sp)
    80005f00:	7866                	ld	a6,120(sp)
    80005f02:	688a                	ld	a7,128(sp)
    80005f04:	692a                	ld	s2,136(sp)
    80005f06:	69ca                	ld	s3,144(sp)
    80005f08:	6a6a                	ld	s4,152(sp)
    80005f0a:	7a8a                	ld	s5,160(sp)
    80005f0c:	7b2a                	ld	s6,168(sp)
    80005f0e:	7bca                	ld	s7,176(sp)
    80005f10:	7c6a                	ld	s8,184(sp)
    80005f12:	6c8e                	ld	s9,192(sp)
    80005f14:	6d2e                	ld	s10,200(sp)
    80005f16:	6dce                	ld	s11,208(sp)
    80005f18:	6e6e                	ld	t3,216(sp)
    80005f1a:	7e8e                	ld	t4,224(sp)
    80005f1c:	7f2e                	ld	t5,232(sp)
    80005f1e:	7fce                	ld	t6,240(sp)
    80005f20:	6111                	addi	sp,sp,256
    80005f22:	10200073          	sret
    80005f26:	00000013          	nop
    80005f2a:	00000013          	nop
    80005f2e:	0001                	nop

0000000080005f30 <timervec>:
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	e10c                	sd	a1,0(a0)
    80005f36:	e510                	sd	a2,8(a0)
    80005f38:	e914                	sd	a3,16(a0)
    80005f3a:	6d0c                	ld	a1,24(a0)
    80005f3c:	7110                	ld	a2,32(a0)
    80005f3e:	6194                	ld	a3,0(a1)
    80005f40:	96b2                	add	a3,a3,a2
    80005f42:	e194                	sd	a3,0(a1)
    80005f44:	4589                	li	a1,2
    80005f46:	14459073          	csrw	sip,a1
    80005f4a:	6914                	ld	a3,16(a0)
    80005f4c:	6510                	ld	a2,8(a0)
    80005f4e:	610c                	ld	a1,0(a0)
    80005f50:	34051573          	csrrw	a0,mscratch,a0
    80005f54:	30200073          	mret
	...

0000000080005f5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f5a:	1141                	addi	sp,sp,-16
    80005f5c:	e422                	sd	s0,8(sp)
    80005f5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f60:	0c0007b7          	lui	a5,0xc000
    80005f64:	4705                	li	a4,1
    80005f66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f68:	c3d8                	sw	a4,4(a5)
}
    80005f6a:	6422                	ld	s0,8(sp)
    80005f6c:	0141                	addi	sp,sp,16
    80005f6e:	8082                	ret

0000000080005f70 <plicinithart>:

void
plicinithart(void)
{
    80005f70:	1141                	addi	sp,sp,-16
    80005f72:	e406                	sd	ra,8(sp)
    80005f74:	e022                	sd	s0,0(sp)
    80005f76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	9ee080e7          	jalr	-1554(ra) # 80001966 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f80:	0085171b          	slliw	a4,a0,0x8
    80005f84:	0c0027b7          	lui	a5,0xc002
    80005f88:	97ba                	add	a5,a5,a4
    80005f8a:	40200713          	li	a4,1026
    80005f8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f92:	00d5151b          	slliw	a0,a0,0xd
    80005f96:	0c2017b7          	lui	a5,0xc201
    80005f9a:	953e                	add	a0,a0,a5
    80005f9c:	00052023          	sw	zero,0(a0)
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret

0000000080005fa8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fa8:	1141                	addi	sp,sp,-16
    80005faa:	e406                	sd	ra,8(sp)
    80005fac:	e022                	sd	s0,0(sp)
    80005fae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fb0:	ffffc097          	auipc	ra,0xffffc
    80005fb4:	9b6080e7          	jalr	-1610(ra) # 80001966 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fb8:	00d5179b          	slliw	a5,a0,0xd
    80005fbc:	0c201537          	lui	a0,0xc201
    80005fc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fc2:	4148                	lw	a0,4(a0)
    80005fc4:	60a2                	ld	ra,8(sp)
    80005fc6:	6402                	ld	s0,0(sp)
    80005fc8:	0141                	addi	sp,sp,16
    80005fca:	8082                	ret

0000000080005fcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fcc:	1101                	addi	sp,sp,-32
    80005fce:	ec06                	sd	ra,24(sp)
    80005fd0:	e822                	sd	s0,16(sp)
    80005fd2:	e426                	sd	s1,8(sp)
    80005fd4:	1000                	addi	s0,sp,32
    80005fd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	98e080e7          	jalr	-1650(ra) # 80001966 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fe0:	00d5151b          	slliw	a0,a0,0xd
    80005fe4:	0c2017b7          	lui	a5,0xc201
    80005fe8:	97aa                	add	a5,a5,a0
    80005fea:	c3c4                	sw	s1,4(a5)
}
    80005fec:	60e2                	ld	ra,24(sp)
    80005fee:	6442                	ld	s0,16(sp)
    80005ff0:	64a2                	ld	s1,8(sp)
    80005ff2:	6105                	addi	sp,sp,32
    80005ff4:	8082                	ret

0000000080005ff6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ff6:	1141                	addi	sp,sp,-16
    80005ff8:	e406                	sd	ra,8(sp)
    80005ffa:	e022                	sd	s0,0(sp)
    80005ffc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ffe:	479d                	li	a5,7
    80006000:	06a7c963          	blt	a5,a0,80006072 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006004:	0001d797          	auipc	a5,0x1d
    80006008:	ffc78793          	addi	a5,a5,-4 # 80023000 <disk>
    8000600c:	00a78733          	add	a4,a5,a0
    80006010:	6789                	lui	a5,0x2
    80006012:	97ba                	add	a5,a5,a4
    80006014:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006018:	e7ad                	bnez	a5,80006082 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000601a:	00451793          	slli	a5,a0,0x4
    8000601e:	0001f717          	auipc	a4,0x1f
    80006022:	fe270713          	addi	a4,a4,-30 # 80025000 <disk+0x2000>
    80006026:	6314                	ld	a3,0(a4)
    80006028:	96be                	add	a3,a3,a5
    8000602a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000602e:	6314                	ld	a3,0(a4)
    80006030:	96be                	add	a3,a3,a5
    80006032:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006036:	6314                	ld	a3,0(a4)
    80006038:	96be                	add	a3,a3,a5
    8000603a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000603e:	6318                	ld	a4,0(a4)
    80006040:	97ba                	add	a5,a5,a4
    80006042:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006046:	0001d797          	auipc	a5,0x1d
    8000604a:	fba78793          	addi	a5,a5,-70 # 80023000 <disk>
    8000604e:	97aa                	add	a5,a5,a0
    80006050:	6509                	lui	a0,0x2
    80006052:	953e                	add	a0,a0,a5
    80006054:	4785                	li	a5,1
    80006056:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000605a:	0001f517          	auipc	a0,0x1f
    8000605e:	fbe50513          	addi	a0,a0,-66 # 80025018 <disk+0x2018>
    80006062:	ffffc097          	auipc	ra,0xffffc
    80006066:	1f8080e7          	jalr	504(ra) # 8000225a <wakeup>
}
    8000606a:	60a2                	ld	ra,8(sp)
    8000606c:	6402                	ld	s0,0(sp)
    8000606e:	0141                	addi	sp,sp,16
    80006070:	8082                	ret
    panic("free_desc 1");
    80006072:	00003517          	auipc	a0,0x3
    80006076:	93e50513          	addi	a0,a0,-1730 # 800089b0 <syscalls_str+0x330>
    8000607a:	ffffa097          	auipc	ra,0xffffa
    8000607e:	4b0080e7          	jalr	1200(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006082:	00003517          	auipc	a0,0x3
    80006086:	93e50513          	addi	a0,a0,-1730 # 800089c0 <syscalls_str+0x340>
    8000608a:	ffffa097          	auipc	ra,0xffffa
    8000608e:	4a0080e7          	jalr	1184(ra) # 8000052a <panic>

0000000080006092 <virtio_disk_init>:
{
    80006092:	1101                	addi	sp,sp,-32
    80006094:	ec06                	sd	ra,24(sp)
    80006096:	e822                	sd	s0,16(sp)
    80006098:	e426                	sd	s1,8(sp)
    8000609a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000609c:	00003597          	auipc	a1,0x3
    800060a0:	93458593          	addi	a1,a1,-1740 # 800089d0 <syscalls_str+0x350>
    800060a4:	0001f517          	auipc	a0,0x1f
    800060a8:	08450513          	addi	a0,a0,132 # 80025128 <disk+0x2128>
    800060ac:	ffffb097          	auipc	ra,0xffffb
    800060b0:	a86080e7          	jalr	-1402(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060b4:	100017b7          	lui	a5,0x10001
    800060b8:	4398                	lw	a4,0(a5)
    800060ba:	2701                	sext.w	a4,a4
    800060bc:	747277b7          	lui	a5,0x74727
    800060c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060c4:	0ef71163          	bne	a4,a5,800061a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060c8:	100017b7          	lui	a5,0x10001
    800060cc:	43dc                	lw	a5,4(a5)
    800060ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060d0:	4705                	li	a4,1
    800060d2:	0ce79a63          	bne	a5,a4,800061a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060d6:	100017b7          	lui	a5,0x10001
    800060da:	479c                	lw	a5,8(a5)
    800060dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060de:	4709                	li	a4,2
    800060e0:	0ce79363          	bne	a5,a4,800061a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060e4:	100017b7          	lui	a5,0x10001
    800060e8:	47d8                	lw	a4,12(a5)
    800060ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ec:	554d47b7          	lui	a5,0x554d4
    800060f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060f4:	0af71963          	bne	a4,a5,800061a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f8:	100017b7          	lui	a5,0x10001
    800060fc:	4705                	li	a4,1
    800060fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006100:	470d                	li	a4,3
    80006102:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006104:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006106:	c7ffe737          	lui	a4,0xc7ffe
    8000610a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000610e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006110:	2701                	sext.w	a4,a4
    80006112:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006114:	472d                	li	a4,11
    80006116:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006118:	473d                	li	a4,15
    8000611a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000611c:	6705                	lui	a4,0x1
    8000611e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006120:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006124:	5bdc                	lw	a5,52(a5)
    80006126:	2781                	sext.w	a5,a5
  if(max == 0)
    80006128:	c7d9                	beqz	a5,800061b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000612a:	471d                	li	a4,7
    8000612c:	08f77d63          	bgeu	a4,a5,800061c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006130:	100014b7          	lui	s1,0x10001
    80006134:	47a1                	li	a5,8
    80006136:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006138:	6609                	lui	a2,0x2
    8000613a:	4581                	li	a1,0
    8000613c:	0001d517          	auipc	a0,0x1d
    80006140:	ec450513          	addi	a0,a0,-316 # 80023000 <disk>
    80006144:	ffffb097          	auipc	ra,0xffffb
    80006148:	b7a080e7          	jalr	-1158(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000614c:	0001d717          	auipc	a4,0x1d
    80006150:	eb470713          	addi	a4,a4,-332 # 80023000 <disk>
    80006154:	00c75793          	srli	a5,a4,0xc
    80006158:	2781                	sext.w	a5,a5
    8000615a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000615c:	0001f797          	auipc	a5,0x1f
    80006160:	ea478793          	addi	a5,a5,-348 # 80025000 <disk+0x2000>
    80006164:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006166:	0001d717          	auipc	a4,0x1d
    8000616a:	f1a70713          	addi	a4,a4,-230 # 80023080 <disk+0x80>
    8000616e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006170:	0001e717          	auipc	a4,0x1e
    80006174:	e9070713          	addi	a4,a4,-368 # 80024000 <disk+0x1000>
    80006178:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000617a:	4705                	li	a4,1
    8000617c:	00e78c23          	sb	a4,24(a5)
    80006180:	00e78ca3          	sb	a4,25(a5)
    80006184:	00e78d23          	sb	a4,26(a5)
    80006188:	00e78da3          	sb	a4,27(a5)
    8000618c:	00e78e23          	sb	a4,28(a5)
    80006190:	00e78ea3          	sb	a4,29(a5)
    80006194:	00e78f23          	sb	a4,30(a5)
    80006198:	00e78fa3          	sb	a4,31(a5)
}
    8000619c:	60e2                	ld	ra,24(sp)
    8000619e:	6442                	ld	s0,16(sp)
    800061a0:	64a2                	ld	s1,8(sp)
    800061a2:	6105                	addi	sp,sp,32
    800061a4:	8082                	ret
    panic("could not find virtio disk");
    800061a6:	00003517          	auipc	a0,0x3
    800061aa:	83a50513          	addi	a0,a0,-1990 # 800089e0 <syscalls_str+0x360>
    800061ae:	ffffa097          	auipc	ra,0xffffa
    800061b2:	37c080e7          	jalr	892(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800061b6:	00003517          	auipc	a0,0x3
    800061ba:	84a50513          	addi	a0,a0,-1974 # 80008a00 <syscalls_str+0x380>
    800061be:	ffffa097          	auipc	ra,0xffffa
    800061c2:	36c080e7          	jalr	876(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800061c6:	00003517          	auipc	a0,0x3
    800061ca:	85a50513          	addi	a0,a0,-1958 # 80008a20 <syscalls_str+0x3a0>
    800061ce:	ffffa097          	auipc	ra,0xffffa
    800061d2:	35c080e7          	jalr	860(ra) # 8000052a <panic>

00000000800061d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061d6:	7119                	addi	sp,sp,-128
    800061d8:	fc86                	sd	ra,120(sp)
    800061da:	f8a2                	sd	s0,112(sp)
    800061dc:	f4a6                	sd	s1,104(sp)
    800061de:	f0ca                	sd	s2,96(sp)
    800061e0:	ecce                	sd	s3,88(sp)
    800061e2:	e8d2                	sd	s4,80(sp)
    800061e4:	e4d6                	sd	s5,72(sp)
    800061e6:	e0da                	sd	s6,64(sp)
    800061e8:	fc5e                	sd	s7,56(sp)
    800061ea:	f862                	sd	s8,48(sp)
    800061ec:	f466                	sd	s9,40(sp)
    800061ee:	f06a                	sd	s10,32(sp)
    800061f0:	ec6e                	sd	s11,24(sp)
    800061f2:	0100                	addi	s0,sp,128
    800061f4:	8aaa                	mv	s5,a0
    800061f6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061f8:	00c52c83          	lw	s9,12(a0)
    800061fc:	001c9c9b          	slliw	s9,s9,0x1
    80006200:	1c82                	slli	s9,s9,0x20
    80006202:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006206:	0001f517          	auipc	a0,0x1f
    8000620a:	f2250513          	addi	a0,a0,-222 # 80025128 <disk+0x2128>
    8000620e:	ffffb097          	auipc	ra,0xffffb
    80006212:	9b4080e7          	jalr	-1612(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006216:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006218:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000621a:	0001dc17          	auipc	s8,0x1d
    8000621e:	de6c0c13          	addi	s8,s8,-538 # 80023000 <disk>
    80006222:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006224:	4b0d                	li	s6,3
    80006226:	a0ad                	j	80006290 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006228:	00fc0733          	add	a4,s8,a5
    8000622c:	975e                	add	a4,a4,s7
    8000622e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006232:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006234:	0207c563          	bltz	a5,8000625e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006238:	2905                	addiw	s2,s2,1
    8000623a:	0611                	addi	a2,a2,4
    8000623c:	19690d63          	beq	s2,s6,800063d6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006240:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006242:	0001f717          	auipc	a4,0x1f
    80006246:	dd670713          	addi	a4,a4,-554 # 80025018 <disk+0x2018>
    8000624a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000624c:	00074683          	lbu	a3,0(a4)
    80006250:	fee1                	bnez	a3,80006228 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006252:	2785                	addiw	a5,a5,1
    80006254:	0705                	addi	a4,a4,1
    80006256:	fe979be3          	bne	a5,s1,8000624c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000625a:	57fd                	li	a5,-1
    8000625c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000625e:	01205d63          	blez	s2,80006278 <virtio_disk_rw+0xa2>
    80006262:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006264:	000a2503          	lw	a0,0(s4)
    80006268:	00000097          	auipc	ra,0x0
    8000626c:	d8e080e7          	jalr	-626(ra) # 80005ff6 <free_desc>
      for(int j = 0; j < i; j++)
    80006270:	2d85                	addiw	s11,s11,1
    80006272:	0a11                	addi	s4,s4,4
    80006274:	ffb918e3          	bne	s2,s11,80006264 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006278:	0001f597          	auipc	a1,0x1f
    8000627c:	eb058593          	addi	a1,a1,-336 # 80025128 <disk+0x2128>
    80006280:	0001f517          	auipc	a0,0x1f
    80006284:	d9850513          	addi	a0,a0,-616 # 80025018 <disk+0x2018>
    80006288:	ffffc097          	auipc	ra,0xffffc
    8000628c:	e46080e7          	jalr	-442(ra) # 800020ce <sleep>
  for(int i = 0; i < 3; i++){
    80006290:	f8040a13          	addi	s4,s0,-128
{
    80006294:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006296:	894e                	mv	s2,s3
    80006298:	b765                	j	80006240 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000629a:	0001f697          	auipc	a3,0x1f
    8000629e:	d666b683          	ld	a3,-666(a3) # 80025000 <disk+0x2000>
    800062a2:	96ba                	add	a3,a3,a4
    800062a4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062a8:	0001d817          	auipc	a6,0x1d
    800062ac:	d5880813          	addi	a6,a6,-680 # 80023000 <disk>
    800062b0:	0001f697          	auipc	a3,0x1f
    800062b4:	d5068693          	addi	a3,a3,-688 # 80025000 <disk+0x2000>
    800062b8:	6290                	ld	a2,0(a3)
    800062ba:	963a                	add	a2,a2,a4
    800062bc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800062c0:	0015e593          	ori	a1,a1,1
    800062c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800062c8:	f8842603          	lw	a2,-120(s0)
    800062cc:	628c                	ld	a1,0(a3)
    800062ce:	972e                	add	a4,a4,a1
    800062d0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062d4:	20050593          	addi	a1,a0,512
    800062d8:	0592                	slli	a1,a1,0x4
    800062da:	95c2                	add	a1,a1,a6
    800062dc:	577d                	li	a4,-1
    800062de:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062e2:	00461713          	slli	a4,a2,0x4
    800062e6:	6290                	ld	a2,0(a3)
    800062e8:	963a                	add	a2,a2,a4
    800062ea:	03078793          	addi	a5,a5,48
    800062ee:	97c2                	add	a5,a5,a6
    800062f0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800062f2:	629c                	ld	a5,0(a3)
    800062f4:	97ba                	add	a5,a5,a4
    800062f6:	4605                	li	a2,1
    800062f8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062fa:	629c                	ld	a5,0(a3)
    800062fc:	97ba                	add	a5,a5,a4
    800062fe:	4809                	li	a6,2
    80006300:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006304:	629c                	ld	a5,0(a3)
    80006306:	973e                	add	a4,a4,a5
    80006308:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000630c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006310:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006314:	6698                	ld	a4,8(a3)
    80006316:	00275783          	lhu	a5,2(a4)
    8000631a:	8b9d                	andi	a5,a5,7
    8000631c:	0786                	slli	a5,a5,0x1
    8000631e:	97ba                	add	a5,a5,a4
    80006320:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006324:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006328:	6698                	ld	a4,8(a3)
    8000632a:	00275783          	lhu	a5,2(a4)
    8000632e:	2785                	addiw	a5,a5,1
    80006330:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006334:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006338:	100017b7          	lui	a5,0x10001
    8000633c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006340:	004aa783          	lw	a5,4(s5)
    80006344:	02c79163          	bne	a5,a2,80006366 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006348:	0001f917          	auipc	s2,0x1f
    8000634c:	de090913          	addi	s2,s2,-544 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006350:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006352:	85ca                	mv	a1,s2
    80006354:	8556                	mv	a0,s5
    80006356:	ffffc097          	auipc	ra,0xffffc
    8000635a:	d78080e7          	jalr	-648(ra) # 800020ce <sleep>
  while(b->disk == 1) {
    8000635e:	004aa783          	lw	a5,4(s5)
    80006362:	fe9788e3          	beq	a5,s1,80006352 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006366:	f8042903          	lw	s2,-128(s0)
    8000636a:	20090793          	addi	a5,s2,512
    8000636e:	00479713          	slli	a4,a5,0x4
    80006372:	0001d797          	auipc	a5,0x1d
    80006376:	c8e78793          	addi	a5,a5,-882 # 80023000 <disk>
    8000637a:	97ba                	add	a5,a5,a4
    8000637c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006380:	0001f997          	auipc	s3,0x1f
    80006384:	c8098993          	addi	s3,s3,-896 # 80025000 <disk+0x2000>
    80006388:	00491713          	slli	a4,s2,0x4
    8000638c:	0009b783          	ld	a5,0(s3)
    80006390:	97ba                	add	a5,a5,a4
    80006392:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006396:	854a                	mv	a0,s2
    80006398:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000639c:	00000097          	auipc	ra,0x0
    800063a0:	c5a080e7          	jalr	-934(ra) # 80005ff6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063a4:	8885                	andi	s1,s1,1
    800063a6:	f0ed                	bnez	s1,80006388 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063a8:	0001f517          	auipc	a0,0x1f
    800063ac:	d8050513          	addi	a0,a0,-640 # 80025128 <disk+0x2128>
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	8c6080e7          	jalr	-1850(ra) # 80000c76 <release>
}
    800063b8:	70e6                	ld	ra,120(sp)
    800063ba:	7446                	ld	s0,112(sp)
    800063bc:	74a6                	ld	s1,104(sp)
    800063be:	7906                	ld	s2,96(sp)
    800063c0:	69e6                	ld	s3,88(sp)
    800063c2:	6a46                	ld	s4,80(sp)
    800063c4:	6aa6                	ld	s5,72(sp)
    800063c6:	6b06                	ld	s6,64(sp)
    800063c8:	7be2                	ld	s7,56(sp)
    800063ca:	7c42                	ld	s8,48(sp)
    800063cc:	7ca2                	ld	s9,40(sp)
    800063ce:	7d02                	ld	s10,32(sp)
    800063d0:	6de2                	ld	s11,24(sp)
    800063d2:	6109                	addi	sp,sp,128
    800063d4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063d6:	f8042503          	lw	a0,-128(s0)
    800063da:	20050793          	addi	a5,a0,512
    800063de:	0792                	slli	a5,a5,0x4
  if(write)
    800063e0:	0001d817          	auipc	a6,0x1d
    800063e4:	c2080813          	addi	a6,a6,-992 # 80023000 <disk>
    800063e8:	00f80733          	add	a4,a6,a5
    800063ec:	01a036b3          	snez	a3,s10
    800063f0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800063f4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063f8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063fc:	7679                	lui	a2,0xffffe
    800063fe:	963e                	add	a2,a2,a5
    80006400:	0001f697          	auipc	a3,0x1f
    80006404:	c0068693          	addi	a3,a3,-1024 # 80025000 <disk+0x2000>
    80006408:	6298                	ld	a4,0(a3)
    8000640a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000640c:	0a878593          	addi	a1,a5,168
    80006410:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006412:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006414:	6298                	ld	a4,0(a3)
    80006416:	9732                	add	a4,a4,a2
    80006418:	45c1                	li	a1,16
    8000641a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000641c:	6298                	ld	a4,0(a3)
    8000641e:	9732                	add	a4,a4,a2
    80006420:	4585                	li	a1,1
    80006422:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006426:	f8442703          	lw	a4,-124(s0)
    8000642a:	628c                	ld	a1,0(a3)
    8000642c:	962e                	add	a2,a2,a1
    8000642e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006432:	0712                	slli	a4,a4,0x4
    80006434:	6290                	ld	a2,0(a3)
    80006436:	963a                	add	a2,a2,a4
    80006438:	058a8593          	addi	a1,s5,88
    8000643c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000643e:	6294                	ld	a3,0(a3)
    80006440:	96ba                	add	a3,a3,a4
    80006442:	40000613          	li	a2,1024
    80006446:	c690                	sw	a2,8(a3)
  if(write)
    80006448:	e40d19e3          	bnez	s10,8000629a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000644c:	0001f697          	auipc	a3,0x1f
    80006450:	bb46b683          	ld	a3,-1100(a3) # 80025000 <disk+0x2000>
    80006454:	96ba                	add	a3,a3,a4
    80006456:	4609                	li	a2,2
    80006458:	00c69623          	sh	a2,12(a3)
    8000645c:	b5b1                	j	800062a8 <virtio_disk_rw+0xd2>

000000008000645e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000645e:	1101                	addi	sp,sp,-32
    80006460:	ec06                	sd	ra,24(sp)
    80006462:	e822                	sd	s0,16(sp)
    80006464:	e426                	sd	s1,8(sp)
    80006466:	e04a                	sd	s2,0(sp)
    80006468:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000646a:	0001f517          	auipc	a0,0x1f
    8000646e:	cbe50513          	addi	a0,a0,-834 # 80025128 <disk+0x2128>
    80006472:	ffffa097          	auipc	ra,0xffffa
    80006476:	750080e7          	jalr	1872(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000647a:	10001737          	lui	a4,0x10001
    8000647e:	533c                	lw	a5,96(a4)
    80006480:	8b8d                	andi	a5,a5,3
    80006482:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006484:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006488:	0001f797          	auipc	a5,0x1f
    8000648c:	b7878793          	addi	a5,a5,-1160 # 80025000 <disk+0x2000>
    80006490:	6b94                	ld	a3,16(a5)
    80006492:	0207d703          	lhu	a4,32(a5)
    80006496:	0026d783          	lhu	a5,2(a3)
    8000649a:	06f70163          	beq	a4,a5,800064fc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000649e:	0001d917          	auipc	s2,0x1d
    800064a2:	b6290913          	addi	s2,s2,-1182 # 80023000 <disk>
    800064a6:	0001f497          	auipc	s1,0x1f
    800064aa:	b5a48493          	addi	s1,s1,-1190 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800064ae:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064b2:	6898                	ld	a4,16(s1)
    800064b4:	0204d783          	lhu	a5,32(s1)
    800064b8:	8b9d                	andi	a5,a5,7
    800064ba:	078e                	slli	a5,a5,0x3
    800064bc:	97ba                	add	a5,a5,a4
    800064be:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064c0:	20078713          	addi	a4,a5,512
    800064c4:	0712                	slli	a4,a4,0x4
    800064c6:	974a                	add	a4,a4,s2
    800064c8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064cc:	e731                	bnez	a4,80006518 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064ce:	20078793          	addi	a5,a5,512
    800064d2:	0792                	slli	a5,a5,0x4
    800064d4:	97ca                	add	a5,a5,s2
    800064d6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064d8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064dc:	ffffc097          	auipc	ra,0xffffc
    800064e0:	d7e080e7          	jalr	-642(ra) # 8000225a <wakeup>

    disk.used_idx += 1;
    800064e4:	0204d783          	lhu	a5,32(s1)
    800064e8:	2785                	addiw	a5,a5,1
    800064ea:	17c2                	slli	a5,a5,0x30
    800064ec:	93c1                	srli	a5,a5,0x30
    800064ee:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064f2:	6898                	ld	a4,16(s1)
    800064f4:	00275703          	lhu	a4,2(a4)
    800064f8:	faf71be3          	bne	a4,a5,800064ae <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064fc:	0001f517          	auipc	a0,0x1f
    80006500:	c2c50513          	addi	a0,a0,-980 # 80025128 <disk+0x2128>
    80006504:	ffffa097          	auipc	ra,0xffffa
    80006508:	772080e7          	jalr	1906(ra) # 80000c76 <release>
}
    8000650c:	60e2                	ld	ra,24(sp)
    8000650e:	6442                	ld	s0,16(sp)
    80006510:	64a2                	ld	s1,8(sp)
    80006512:	6902                	ld	s2,0(sp)
    80006514:	6105                	addi	sp,sp,32
    80006516:	8082                	ret
      panic("virtio_disk_intr status");
    80006518:	00002517          	auipc	a0,0x2
    8000651c:	52850513          	addi	a0,a0,1320 # 80008a40 <syscalls_str+0x3c0>
    80006520:	ffffa097          	auipc	ra,0xffffa
    80006524:	00a080e7          	jalr	10(ra) # 8000052a <panic>
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
