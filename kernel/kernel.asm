
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
    80000068:	d4c78793          	addi	a5,a5,-692 # 80005db0 <timervec>
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
    80000122:	450080e7          	jalr	1104(ra) # 8000256e <either_copyin>
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
    80000202:	31a080e7          	jalr	794(ra) # 80002518 <either_copyout>
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
    800002e2:	2e6080e7          	jalr	742(ra) # 800025c4 <procdump>
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
    80000eb6:	854080e7          	jalr	-1964(ra) # 80002706 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	f36080e7          	jalr	-202(ra) # 80005df0 <plicinithart>
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
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	7b4080e7          	jalr	1972(ra) # 800026de <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	7d4080e7          	jalr	2004(ra) # 80002706 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	ea0080e7          	jalr	-352(ra) # 80005dda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	eae080e7          	jalr	-338(ra) # 80005df0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	078080e7          	jalr	120(ra) # 80002fc2 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	70a080e7          	jalr	1802(ra) # 8000365c <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	6b8080e7          	jalr	1720(ra) # 80004612 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	fb0080e7          	jalr	-80(ra) # 80005f12 <virtio_disk_init>
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
    800019e6:	06e7a783          	lw	a5,110(a5) # 80008a50 <first.1>
    800019ea:	eb89                	bnez	a5,800019fc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ec:	00001097          	auipc	ra,0x1
    800019f0:	d32080e7          	jalr	-718(ra) # 8000271e <usertrapret>
}
    800019f4:	60a2                	ld	ra,8(sp)
    800019f6:	6402                	ld	s0,0(sp)
    800019f8:	0141                	addi	sp,sp,16
    800019fa:	8082                	ret
    first = 0;
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	0407aa23          	sw	zero,84(a5) # 80008a50 <first.1>
    fsinit(ROOTDEV);
    80001a04:	4505                	li	a0,1
    80001a06:	00002097          	auipc	ra,0x2
    80001a0a:	bd6080e7          	jalr	-1066(ra) # 800035dc <fsinit>
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
    80001a32:	02678793          	addi	a5,a5,38 # 80008a54 <nextpid>
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
    80001cd6:	d8e58593          	addi	a1,a1,-626 # 80008a60 <initcode>
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
    80001d14:	2fa080e7          	jalr	762(ra) # 8000400a <namei>
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
    80001e5c:	84c080e7          	jalr	-1972(ra) # 800046a4 <filedup>
    80001e60:	00a93023          	sd	a0,0(s2)
    80001e64:	b7e5                	j	80001e4c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e66:	150ab503          	ld	a0,336(s5)
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	9ac080e7          	jalr	-1620(ra) # 80003816 <idup>
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
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	6e6080e7          	jalr	1766(ra) # 80002674 <swtch>
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
    80002034:	644080e7          	jalr	1604(ra) # 80002674 <swtch>
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
    80002356:	00007597          	auipc	a1,0x7
    8000235a:	cda5a583          	lw	a1,-806(a1) # 80009030 <ticks>
    8000235e:	16b9a623          	sw	a1,364(s3)
  printf("ttime: %d", p->ttime);
    80002362:	00006517          	auipc	a0,0x6
    80002366:	ee650513          	addi	a0,a0,-282 # 80008248 <digits+0x208>
    8000236a:	ffffe097          	auipc	ra,0xffffe
    8000236e:	20a080e7          	jalr	522(ra) # 80000574 <printf>
  release(&tickslock);
    80002372:	00015517          	auipc	a0,0x15
    80002376:	35e50513          	addi	a0,a0,862 # 800176d0 <tickslock>
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	8fc080e7          	jalr	-1796(ra) # 80000c76 <release>
  if (p == initproc)
    80002382:	00007797          	auipc	a5,0x7
    80002386:	ca67b783          	ld	a5,-858(a5) # 80009028 <initproc>
    8000238a:	0d098493          	addi	s1,s3,208
    8000238e:	15098913          	addi	s2,s3,336
    80002392:	03379363          	bne	a5,s3,800023b8 <exit+0x8e>
    panic("init exiting");
    80002396:	00006517          	auipc	a0,0x6
    8000239a:	ec250513          	addi	a0,a0,-318 # 80008258 <digits+0x218>
    8000239e:	ffffe097          	auipc	ra,0xffffe
    800023a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>
      fileclose(f);
    800023a6:	00002097          	auipc	ra,0x2
    800023aa:	350080e7          	jalr	848(ra) # 800046f6 <fileclose>
      p->ofile[fd] = 0;
    800023ae:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023b2:	04a1                	addi	s1,s1,8
    800023b4:	01248563          	beq	s1,s2,800023be <exit+0x94>
    if (p->ofile[fd])
    800023b8:	6088                	ld	a0,0(s1)
    800023ba:	f575                	bnez	a0,800023a6 <exit+0x7c>
    800023bc:	bfdd                	j	800023b2 <exit+0x88>
  begin_op();
    800023be:	00002097          	auipc	ra,0x2
    800023c2:	e6c080e7          	jalr	-404(ra) # 8000422a <begin_op>
  iput(p->cwd);
    800023c6:	1509b503          	ld	a0,336(s3)
    800023ca:	00001097          	auipc	ra,0x1
    800023ce:	644080e7          	jalr	1604(ra) # 80003a0e <iput>
  end_op();
    800023d2:	00002097          	auipc	ra,0x2
    800023d6:	ed8080e7          	jalr	-296(ra) # 800042aa <end_op>
  p->cwd = 0;
    800023da:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023de:	0000f497          	auipc	s1,0xf
    800023e2:	eda48493          	addi	s1,s1,-294 # 800112b8 <wait_lock>
    800023e6:	8526                	mv	a0,s1
    800023e8:	ffffe097          	auipc	ra,0xffffe
    800023ec:	7da080e7          	jalr	2010(ra) # 80000bc2 <acquire>
  reparent(p);
    800023f0:	854e                	mv	a0,s3
    800023f2:	00000097          	auipc	ra,0x0
    800023f6:	ede080e7          	jalr	-290(ra) # 800022d0 <reparent>
  wakeup(p->parent);
    800023fa:	0389b503          	ld	a0,56(s3)
    800023fe:	00000097          	auipc	ra,0x0
    80002402:	e5c080e7          	jalr	-420(ra) # 8000225a <wakeup>
  acquire(&p->lock);
    80002406:	854e                	mv	a0,s3
    80002408:	ffffe097          	auipc	ra,0xffffe
    8000240c:	7ba080e7          	jalr	1978(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002410:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002414:	4795                	li	a5,5
    80002416:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	85a080e7          	jalr	-1958(ra) # 80000c76 <release>
  sched();
    80002424:	00000097          	auipc	ra,0x0
    80002428:	b98080e7          	jalr	-1128(ra) # 80001fbc <sched>
  panic("zombie exit");
    8000242c:	00006517          	auipc	a0,0x6
    80002430:	e3c50513          	addi	a0,a0,-452 # 80008268 <digits+0x228>
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	0f6080e7          	jalr	246(ra) # 8000052a <panic>

000000008000243c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000243c:	7179                	addi	sp,sp,-48
    8000243e:	f406                	sd	ra,40(sp)
    80002440:	f022                	sd	s0,32(sp)
    80002442:	ec26                	sd	s1,24(sp)
    80002444:	e84a                	sd	s2,16(sp)
    80002446:	e44e                	sd	s3,8(sp)
    80002448:	1800                	addi	s0,sp,48
    8000244a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000244c:	0000f497          	auipc	s1,0xf
    80002450:	28448493          	addi	s1,s1,644 # 800116d0 <proc>
    80002454:	00015997          	auipc	s3,0x15
    80002458:	27c98993          	addi	s3,s3,636 # 800176d0 <tickslock>
  {
    acquire(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	764080e7          	jalr	1892(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    80002466:	589c                	lw	a5,48(s1)
    80002468:	01278d63          	beq	a5,s2,80002482 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	808080e7          	jalr	-2040(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002476:	18048493          	addi	s1,s1,384
    8000247a:	ff3491e3          	bne	s1,s3,8000245c <kill+0x20>
  }
  return -1;
    8000247e:	557d                	li	a0,-1
    80002480:	a829                	j	8000249a <kill+0x5e>
      p->killed = 1;
    80002482:	4785                	li	a5,1
    80002484:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002486:	4c98                	lw	a4,24(s1)
    80002488:	4789                	li	a5,2
    8000248a:	00f70f63          	beq	a4,a5,800024a8 <kill+0x6c>
      release(&p->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	7e6080e7          	jalr	2022(ra) # 80000c76 <release>
      return 0;
    80002498:	4501                	li	a0,0
}
    8000249a:	70a2                	ld	ra,40(sp)
    8000249c:	7402                	ld	s0,32(sp)
    8000249e:	64e2                	ld	s1,24(sp)
    800024a0:	6942                	ld	s2,16(sp)
    800024a2:	69a2                	ld	s3,8(sp)
    800024a4:	6145                	addi	sp,sp,48
    800024a6:	8082                	ret
        p->state = RUNNABLE;
    800024a8:	478d                	li	a5,3
    800024aa:	cc9c                	sw	a5,24(s1)
    800024ac:	b7cd                	j	8000248e <kill+0x52>

00000000800024ae <trace>:

int trace(int mask, int pid)
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	e052                	sd	s4,0(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	8a2a                	mv	s4,a0
    800024c0:	892e                	mv	s2,a1
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800024c2:	0000f497          	auipc	s1,0xf
    800024c6:	20e48493          	addi	s1,s1,526 # 800116d0 <proc>
    800024ca:	00015997          	auipc	s3,0x15
    800024ce:	20698993          	addi	s3,s3,518 # 800176d0 <tickslock>
  {
    acquire(&p->lock);
    800024d2:	8526                	mv	a0,s1
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	6ee080e7          	jalr	1774(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    800024dc:	589c                	lw	a5,48(s1)
    800024de:	01278d63          	beq	a5,s2,800024f8 <trace+0x4a>
    {
      p->traceMask = mask;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	792080e7          	jalr	1938(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800024ec:	18048493          	addi	s1,s1,384
    800024f0:	ff3491e3          	bne	s1,s3,800024d2 <trace+0x24>
  }
  return -1;
    800024f4:	557d                	li	a0,-1
    800024f6:	a809                	j	80002508 <trace+0x5a>
      p->traceMask = mask;
    800024f8:	0344aa23          	sw	s4,52(s1)
      release(&p->lock);
    800024fc:	8526                	mv	a0,s1
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	778080e7          	jalr	1912(ra) # 80000c76 <release>
      return 0;
    80002506:	4501                	li	a0,0
}
    80002508:	70a2                	ld	ra,40(sp)
    8000250a:	7402                	ld	s0,32(sp)
    8000250c:	64e2                	ld	s1,24(sp)
    8000250e:	6942                	ld	s2,16(sp)
    80002510:	69a2                	ld	s3,8(sp)
    80002512:	6a02                	ld	s4,0(sp)
    80002514:	6145                	addi	sp,sp,48
    80002516:	8082                	ret

0000000080002518 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002518:	7179                	addi	sp,sp,-48
    8000251a:	f406                	sd	ra,40(sp)
    8000251c:	f022                	sd	s0,32(sp)
    8000251e:	ec26                	sd	s1,24(sp)
    80002520:	e84a                	sd	s2,16(sp)
    80002522:	e44e                	sd	s3,8(sp)
    80002524:	e052                	sd	s4,0(sp)
    80002526:	1800                	addi	s0,sp,48
    80002528:	84aa                	mv	s1,a0
    8000252a:	892e                	mv	s2,a1
    8000252c:	89b2                	mv	s3,a2
    8000252e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	462080e7          	jalr	1122(ra) # 80001992 <myproc>
  if (user_dst)
    80002538:	c08d                	beqz	s1,8000255a <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000253a:	86d2                	mv	a3,s4
    8000253c:	864e                	mv	a2,s3
    8000253e:	85ca                	mv	a1,s2
    80002540:	6928                	ld	a0,80(a0)
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	0fc080e7          	jalr	252(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000254a:	70a2                	ld	ra,40(sp)
    8000254c:	7402                	ld	s0,32(sp)
    8000254e:	64e2                	ld	s1,24(sp)
    80002550:	6942                	ld	s2,16(sp)
    80002552:	69a2                	ld	s3,8(sp)
    80002554:	6a02                	ld	s4,0(sp)
    80002556:	6145                	addi	sp,sp,48
    80002558:	8082                	ret
    memmove((char *)dst, src, len);
    8000255a:	000a061b          	sext.w	a2,s4
    8000255e:	85ce                	mv	a1,s3
    80002560:	854a                	mv	a0,s2
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	7b8080e7          	jalr	1976(ra) # 80000d1a <memmove>
    return 0;
    8000256a:	8526                	mv	a0,s1
    8000256c:	bff9                	j	8000254a <either_copyout+0x32>

000000008000256e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000256e:	7179                	addi	sp,sp,-48
    80002570:	f406                	sd	ra,40(sp)
    80002572:	f022                	sd	s0,32(sp)
    80002574:	ec26                	sd	s1,24(sp)
    80002576:	e84a                	sd	s2,16(sp)
    80002578:	e44e                	sd	s3,8(sp)
    8000257a:	e052                	sd	s4,0(sp)
    8000257c:	1800                	addi	s0,sp,48
    8000257e:	892a                	mv	s2,a0
    80002580:	84ae                	mv	s1,a1
    80002582:	89b2                	mv	s3,a2
    80002584:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002586:	fffff097          	auipc	ra,0xfffff
    8000258a:	40c080e7          	jalr	1036(ra) # 80001992 <myproc>
  if (user_src)
    8000258e:	c08d                	beqz	s1,800025b0 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002590:	86d2                	mv	a3,s4
    80002592:	864e                	mv	a2,s3
    80002594:	85ca                	mv	a1,s2
    80002596:	6928                	ld	a0,80(a0)
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	132080e7          	jalr	306(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800025a0:	70a2                	ld	ra,40(sp)
    800025a2:	7402                	ld	s0,32(sp)
    800025a4:	64e2                	ld	s1,24(sp)
    800025a6:	6942                	ld	s2,16(sp)
    800025a8:	69a2                	ld	s3,8(sp)
    800025aa:	6a02                	ld	s4,0(sp)
    800025ac:	6145                	addi	sp,sp,48
    800025ae:	8082                	ret
    memmove(dst, (char *)src, len);
    800025b0:	000a061b          	sext.w	a2,s4
    800025b4:	85ce                	mv	a1,s3
    800025b6:	854a                	mv	a0,s2
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	762080e7          	jalr	1890(ra) # 80000d1a <memmove>
    return 0;
    800025c0:	8526                	mv	a0,s1
    800025c2:	bff9                	j	800025a0 <either_copyin+0x32>

00000000800025c4 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025c4:	715d                	addi	sp,sp,-80
    800025c6:	e486                	sd	ra,72(sp)
    800025c8:	e0a2                	sd	s0,64(sp)
    800025ca:	fc26                	sd	s1,56(sp)
    800025cc:	f84a                	sd	s2,48(sp)
    800025ce:	f44e                	sd	s3,40(sp)
    800025d0:	f052                	sd	s4,32(sp)
    800025d2:	ec56                	sd	s5,24(sp)
    800025d4:	e85a                	sd	s6,16(sp)
    800025d6:	e45e                	sd	s7,8(sp)
    800025d8:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800025da:	00006517          	auipc	a0,0x6
    800025de:	aee50513          	addi	a0,a0,-1298 # 800080c8 <digits+0x88>
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	f92080e7          	jalr	-110(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025ea:	0000f497          	auipc	s1,0xf
    800025ee:	23e48493          	addi	s1,s1,574 # 80011828 <proc+0x158>
    800025f2:	00015917          	auipc	s2,0x15
    800025f6:	23690913          	addi	s2,s2,566 # 80017828 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fa:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025fc:	00006997          	auipc	s3,0x6
    80002600:	c7c98993          	addi	s3,s3,-900 # 80008278 <digits+0x238>
    printf("%d %s %s", p->pid, state, p->name);
    80002604:	00006a97          	auipc	s5,0x6
    80002608:	c7ca8a93          	addi	s5,s5,-900 # 80008280 <digits+0x240>
    printf("\n");
    8000260c:	00006a17          	auipc	s4,0x6
    80002610:	abca0a13          	addi	s4,s4,-1348 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002614:	00006b97          	auipc	s7,0x6
    80002618:	ca4b8b93          	addi	s7,s7,-860 # 800082b8 <states.0>
    8000261c:	a00d                	j	8000263e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000261e:	ed86a583          	lw	a1,-296(a3)
    80002622:	8556                	mv	a0,s5
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	f50080e7          	jalr	-176(ra) # 80000574 <printf>
    printf("\n");
    8000262c:	8552                	mv	a0,s4
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	f46080e7          	jalr	-186(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002636:	18048493          	addi	s1,s1,384
    8000263a:	03248263          	beq	s1,s2,8000265e <procdump+0x9a>
    if (p->state == UNUSED)
    8000263e:	86a6                	mv	a3,s1
    80002640:	ec04a783          	lw	a5,-320(s1)
    80002644:	dbed                	beqz	a5,80002636 <procdump+0x72>
      state = "???";
    80002646:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002648:	fcfb6be3          	bltu	s6,a5,8000261e <procdump+0x5a>
    8000264c:	02079713          	slli	a4,a5,0x20
    80002650:	01d75793          	srli	a5,a4,0x1d
    80002654:	97de                	add	a5,a5,s7
    80002656:	6390                	ld	a2,0(a5)
    80002658:	f279                	bnez	a2,8000261e <procdump+0x5a>
      state = "???";
    8000265a:	864e                	mv	a2,s3
    8000265c:	b7c9                	j	8000261e <procdump+0x5a>
  }
}
    8000265e:	60a6                	ld	ra,72(sp)
    80002660:	6406                	ld	s0,64(sp)
    80002662:	74e2                	ld	s1,56(sp)
    80002664:	7942                	ld	s2,48(sp)
    80002666:	79a2                	ld	s3,40(sp)
    80002668:	7a02                	ld	s4,32(sp)
    8000266a:	6ae2                	ld	s5,24(sp)
    8000266c:	6b42                	ld	s6,16(sp)
    8000266e:	6ba2                	ld	s7,8(sp)
    80002670:	6161                	addi	sp,sp,80
    80002672:	8082                	ret

0000000080002674 <swtch>:
    80002674:	00153023          	sd	ra,0(a0)
    80002678:	00253423          	sd	sp,8(a0)
    8000267c:	e900                	sd	s0,16(a0)
    8000267e:	ed04                	sd	s1,24(a0)
    80002680:	03253023          	sd	s2,32(a0)
    80002684:	03353423          	sd	s3,40(a0)
    80002688:	03453823          	sd	s4,48(a0)
    8000268c:	03553c23          	sd	s5,56(a0)
    80002690:	05653023          	sd	s6,64(a0)
    80002694:	05753423          	sd	s7,72(a0)
    80002698:	05853823          	sd	s8,80(a0)
    8000269c:	05953c23          	sd	s9,88(a0)
    800026a0:	07a53023          	sd	s10,96(a0)
    800026a4:	07b53423          	sd	s11,104(a0)
    800026a8:	0005b083          	ld	ra,0(a1)
    800026ac:	0085b103          	ld	sp,8(a1)
    800026b0:	6980                	ld	s0,16(a1)
    800026b2:	6d84                	ld	s1,24(a1)
    800026b4:	0205b903          	ld	s2,32(a1)
    800026b8:	0285b983          	ld	s3,40(a1)
    800026bc:	0305ba03          	ld	s4,48(a1)
    800026c0:	0385ba83          	ld	s5,56(a1)
    800026c4:	0405bb03          	ld	s6,64(a1)
    800026c8:	0485bb83          	ld	s7,72(a1)
    800026cc:	0505bc03          	ld	s8,80(a1)
    800026d0:	0585bc83          	ld	s9,88(a1)
    800026d4:	0605bd03          	ld	s10,96(a1)
    800026d8:	0685bd83          	ld	s11,104(a1)
    800026dc:	8082                	ret

00000000800026de <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026de:	1141                	addi	sp,sp,-16
    800026e0:	e406                	sd	ra,8(sp)
    800026e2:	e022                	sd	s0,0(sp)
    800026e4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026e6:	00006597          	auipc	a1,0x6
    800026ea:	c0258593          	addi	a1,a1,-1022 # 800082e8 <states.0+0x30>
    800026ee:	00015517          	auipc	a0,0x15
    800026f2:	fe250513          	addi	a0,a0,-30 # 800176d0 <tickslock>
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	43c080e7          	jalr	1084(ra) # 80000b32 <initlock>
}
    800026fe:	60a2                	ld	ra,8(sp)
    80002700:	6402                	ld	s0,0(sp)
    80002702:	0141                	addi	sp,sp,16
    80002704:	8082                	ret

0000000080002706 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002706:	1141                	addi	sp,sp,-16
    80002708:	e422                	sd	s0,8(sp)
    8000270a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000270c:	00003797          	auipc	a5,0x3
    80002710:	61478793          	addi	a5,a5,1556 # 80005d20 <kernelvec>
    80002714:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002718:	6422                	ld	s0,8(sp)
    8000271a:	0141                	addi	sp,sp,16
    8000271c:	8082                	ret

000000008000271e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000271e:	1141                	addi	sp,sp,-16
    80002720:	e406                	sd	ra,8(sp)
    80002722:	e022                	sd	s0,0(sp)
    80002724:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	26c080e7          	jalr	620(ra) # 80001992 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002732:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002734:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002738:	00005617          	auipc	a2,0x5
    8000273c:	8c860613          	addi	a2,a2,-1848 # 80007000 <_trampoline>
    80002740:	00005697          	auipc	a3,0x5
    80002744:	8c068693          	addi	a3,a3,-1856 # 80007000 <_trampoline>
    80002748:	8e91                	sub	a3,a3,a2
    8000274a:	040007b7          	lui	a5,0x4000
    8000274e:	17fd                	addi	a5,a5,-1
    80002750:	07b2                	slli	a5,a5,0xc
    80002752:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002754:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002758:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000275a:	180026f3          	csrr	a3,satp
    8000275e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002760:	6d38                	ld	a4,88(a0)
    80002762:	6134                	ld	a3,64(a0)
    80002764:	6585                	lui	a1,0x1
    80002766:	96ae                	add	a3,a3,a1
    80002768:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000276a:	6d38                	ld	a4,88(a0)
    8000276c:	00000697          	auipc	a3,0x0
    80002770:	1be68693          	addi	a3,a3,446 # 8000292a <usertrap>
    80002774:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002776:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002778:	8692                	mv	a3,tp
    8000277a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000277c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002780:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002784:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002788:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000278c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000278e:	6f18                	ld	a4,24(a4)
    80002790:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002794:	692c                	ld	a1,80(a0)
    80002796:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002798:	00005717          	auipc	a4,0x5
    8000279c:	8f870713          	addi	a4,a4,-1800 # 80007090 <userret>
    800027a0:	8f11                	sub	a4,a4,a2
    800027a2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027a4:	577d                	li	a4,-1
    800027a6:	177e                	slli	a4,a4,0x3f
    800027a8:	8dd9                	or	a1,a1,a4
    800027aa:	02000537          	lui	a0,0x2000
    800027ae:	157d                	addi	a0,a0,-1
    800027b0:	0536                	slli	a0,a0,0xd
    800027b2:	9782                	jalr	a5
}
    800027b4:	60a2                	ld	ra,8(sp)
    800027b6:	6402                	ld	s0,0(sp)
    800027b8:	0141                	addi	sp,sp,16
    800027ba:	8082                	ret

00000000800027bc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027bc:	7139                	addi	sp,sp,-64
    800027be:	fc06                	sd	ra,56(sp)
    800027c0:	f822                	sd	s0,48(sp)
    800027c2:	f426                	sd	s1,40(sp)
    800027c4:	f04a                	sd	s2,32(sp)
    800027c6:	ec4e                	sd	s3,24(sp)
    800027c8:	e852                	sd	s4,16(sp)
    800027ca:	e456                	sd	s5,8(sp)
    800027cc:	0080                	addi	s0,sp,64
  acquire(&tickslock);
    800027ce:	00015517          	auipc	a0,0x15
    800027d2:	f0250513          	addi	a0,a0,-254 # 800176d0 <tickslock>
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	3ec080e7          	jalr	1004(ra) # 80000bc2 <acquire>
  ticks++;
    800027de:	00007717          	auipc	a4,0x7
    800027e2:	85270713          	addi	a4,a4,-1966 # 80009030 <ticks>
    800027e6:	431c                	lw	a5,0(a4)
    800027e8:	2785                	addiw	a5,a5,1
    800027ea:	c31c                	sw	a5,0(a4)
  //start add UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE
  struct proc *p;
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	020080e7          	jalr	32(ra) # 8000180c <getProc>
    800027f4:	84aa                	mv	s1,a0
    800027f6:	6919                	lui	s2,0x6
    acquire(&p->lock);

    enum procstate state = p->state;
    switch (state)
    800027f8:	4a8d                	li	s5,3
    800027fa:	4a11                	li	s4,4
    800027fc:	4989                	li	s3,2
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    800027fe:	a829                	j	80002818 <clockintr+0x5c>
        break;
      case SLEEPING:
        p->stime += 1;
        break;
      case RUNNABLE:
        p->retime += 1;
    80002800:	1744a783          	lw	a5,372(s1)
    80002804:	2785                	addiw	a5,a5,1
    80002806:	16f4aa23          	sw	a5,372(s1)
      case ZOMBIE:   
        break; 
      default:
        break;
    }
    release(&p->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	46a080e7          	jalr	1130(ra) # 80000c76 <release>
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    80002814:	18048493          	addi	s1,s1,384
    80002818:	fffff097          	auipc	ra,0xfffff
    8000281c:	ff4080e7          	jalr	-12(ra) # 8000180c <getProc>
    80002820:	954a                	add	a0,a0,s2
    80002822:	02a4fa63          	bgeu	s1,a0,80002856 <clockintr+0x9a>
    acquire(&p->lock);
    80002826:	8526                	mv	a0,s1
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	39a080e7          	jalr	922(ra) # 80000bc2 <acquire>
    enum procstate state = p->state;
    80002830:	4c9c                	lw	a5,24(s1)
    switch (state)
    80002832:	fd5787e3          	beq	a5,s5,80002800 <clockintr+0x44>
    80002836:	01478a63          	beq	a5,s4,8000284a <clockintr+0x8e>
    8000283a:	fd3798e3          	bne	a5,s3,8000280a <clockintr+0x4e>
        p->stime += 1;
    8000283e:	1704a783          	lw	a5,368(s1)
    80002842:	2785                	addiw	a5,a5,1
    80002844:	16f4a823          	sw	a5,368(s1)
        break;
    80002848:	b7c9                	j	8000280a <clockintr+0x4e>
        p->runtime += 1;
    8000284a:	1784a783          	lw	a5,376(s1)
    8000284e:	2785                	addiw	a5,a5,1
    80002850:	16f4ac23          	sw	a5,376(s1)
        break;
    80002854:	bf5d                	j	8000280a <clockintr+0x4e>
  }
  // end add
  wakeup(&ticks);
    80002856:	00006517          	auipc	a0,0x6
    8000285a:	7da50513          	addi	a0,a0,2010 # 80009030 <ticks>
    8000285e:	00000097          	auipc	ra,0x0
    80002862:	9fc080e7          	jalr	-1540(ra) # 8000225a <wakeup>
  release(&tickslock);
    80002866:	00015517          	auipc	a0,0x15
    8000286a:	e6a50513          	addi	a0,a0,-406 # 800176d0 <tickslock>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	408080e7          	jalr	1032(ra) # 80000c76 <release>
}
    80002876:	70e2                	ld	ra,56(sp)
    80002878:	7442                	ld	s0,48(sp)
    8000287a:	74a2                	ld	s1,40(sp)
    8000287c:	7902                	ld	s2,32(sp)
    8000287e:	69e2                	ld	s3,24(sp)
    80002880:	6a42                	ld	s4,16(sp)
    80002882:	6aa2                	ld	s5,8(sp)
    80002884:	6121                	addi	sp,sp,64
    80002886:	8082                	ret

0000000080002888 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002888:	1101                	addi	sp,sp,-32
    8000288a:	ec06                	sd	ra,24(sp)
    8000288c:	e822                	sd	s0,16(sp)
    8000288e:	e426                	sd	s1,8(sp)
    80002890:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002892:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002896:	00074d63          	bltz	a4,800028b0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000289a:	57fd                	li	a5,-1
    8000289c:	17fe                	slli	a5,a5,0x3f
    8000289e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028a0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028a2:	06f70363          	beq	a4,a5,80002908 <devintr+0x80>
  }
}
    800028a6:	60e2                	ld	ra,24(sp)
    800028a8:	6442                	ld	s0,16(sp)
    800028aa:	64a2                	ld	s1,8(sp)
    800028ac:	6105                	addi	sp,sp,32
    800028ae:	8082                	ret
     (scause & 0xff) == 9){
    800028b0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028b4:	46a5                	li	a3,9
    800028b6:	fed792e3          	bne	a5,a3,8000289a <devintr+0x12>
    int irq = plic_claim();
    800028ba:	00003097          	auipc	ra,0x3
    800028be:	56e080e7          	jalr	1390(ra) # 80005e28 <plic_claim>
    800028c2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028c4:	47a9                	li	a5,10
    800028c6:	02f50763          	beq	a0,a5,800028f4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028ca:	4785                	li	a5,1
    800028cc:	02f50963          	beq	a0,a5,800028fe <devintr+0x76>
    return 1;
    800028d0:	4505                	li	a0,1
    } else if(irq){
    800028d2:	d8f1                	beqz	s1,800028a6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028d4:	85a6                	mv	a1,s1
    800028d6:	00006517          	auipc	a0,0x6
    800028da:	a1a50513          	addi	a0,a0,-1510 # 800082f0 <states.0+0x38>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	c96080e7          	jalr	-874(ra) # 80000574 <printf>
      plic_complete(irq);
    800028e6:	8526                	mv	a0,s1
    800028e8:	00003097          	auipc	ra,0x3
    800028ec:	564080e7          	jalr	1380(ra) # 80005e4c <plic_complete>
    return 1;
    800028f0:	4505                	li	a0,1
    800028f2:	bf55                	j	800028a6 <devintr+0x1e>
      uartintr();
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	092080e7          	jalr	146(ra) # 80000986 <uartintr>
    800028fc:	b7ed                	j	800028e6 <devintr+0x5e>
      virtio_disk_intr();
    800028fe:	00004097          	auipc	ra,0x4
    80002902:	9e0080e7          	jalr	-1568(ra) # 800062de <virtio_disk_intr>
    80002906:	b7c5                	j	800028e6 <devintr+0x5e>
    if(cpuid() == 0){
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	05e080e7          	jalr	94(ra) # 80001966 <cpuid>
    80002910:	c901                	beqz	a0,80002920 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002912:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002916:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002918:	14479073          	csrw	sip,a5
    return 2;
    8000291c:	4509                	li	a0,2
    8000291e:	b761                	j	800028a6 <devintr+0x1e>
      clockintr();
    80002920:	00000097          	auipc	ra,0x0
    80002924:	e9c080e7          	jalr	-356(ra) # 800027bc <clockintr>
    80002928:	b7ed                	j	80002912 <devintr+0x8a>

000000008000292a <usertrap>:
{
    8000292a:	1101                	addi	sp,sp,-32
    8000292c:	ec06                	sd	ra,24(sp)
    8000292e:	e822                	sd	s0,16(sp)
    80002930:	e426                	sd	s1,8(sp)
    80002932:	e04a                	sd	s2,0(sp)
    80002934:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002936:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000293a:	1007f793          	andi	a5,a5,256
    8000293e:	e3ad                	bnez	a5,800029a0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002940:	00003797          	auipc	a5,0x3
    80002944:	3e078793          	addi	a5,a5,992 # 80005d20 <kernelvec>
    80002948:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	046080e7          	jalr	70(ra) # 80001992 <myproc>
    80002954:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002956:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002958:	14102773          	csrr	a4,sepc
    8000295c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002962:	47a1                	li	a5,8
    80002964:	04f71c63          	bne	a4,a5,800029bc <usertrap+0x92>
    if(p->killed)
    80002968:	551c                	lw	a5,40(a0)
    8000296a:	e3b9                	bnez	a5,800029b0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000296c:	6cb8                	ld	a4,88(s1)
    8000296e:	6f1c                	ld	a5,24(a4)
    80002970:	0791                	addi	a5,a5,4
    80002972:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002974:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002978:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000297c:	10079073          	csrw	sstatus,a5
    syscall();
    80002980:	00000097          	auipc	ra,0x0
    80002984:	2e0080e7          	jalr	736(ra) # 80002c60 <syscall>
  if(p->killed)
    80002988:	549c                	lw	a5,40(s1)
    8000298a:	ebc1                	bnez	a5,80002a1a <usertrap+0xf0>
  usertrapret();
    8000298c:	00000097          	auipc	ra,0x0
    80002990:	d92080e7          	jalr	-622(ra) # 8000271e <usertrapret>
}
    80002994:	60e2                	ld	ra,24(sp)
    80002996:	6442                	ld	s0,16(sp)
    80002998:	64a2                	ld	s1,8(sp)
    8000299a:	6902                	ld	s2,0(sp)
    8000299c:	6105                	addi	sp,sp,32
    8000299e:	8082                	ret
    panic("usertrap: not from user mode");
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	97050513          	addi	a0,a0,-1680 # 80008310 <states.0+0x58>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	b82080e7          	jalr	-1150(ra) # 8000052a <panic>
      exit(-1);
    800029b0:	557d                	li	a0,-1
    800029b2:	00000097          	auipc	ra,0x0
    800029b6:	978080e7          	jalr	-1672(ra) # 8000232a <exit>
    800029ba:	bf4d                	j	8000296c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029bc:	00000097          	auipc	ra,0x0
    800029c0:	ecc080e7          	jalr	-308(ra) # 80002888 <devintr>
    800029c4:	892a                	mv	s2,a0
    800029c6:	c501                	beqz	a0,800029ce <usertrap+0xa4>
  if(p->killed)
    800029c8:	549c                	lw	a5,40(s1)
    800029ca:	c3a1                	beqz	a5,80002a0a <usertrap+0xe0>
    800029cc:	a815                	j	80002a00 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029d2:	5890                	lw	a2,48(s1)
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	95c50513          	addi	a0,a0,-1700 # 80008330 <states.0+0x78>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	b98080e7          	jalr	-1128(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029e8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	97450513          	addi	a0,a0,-1676 # 80008360 <states.0+0xa8>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b80080e7          	jalr	-1152(ra) # 80000574 <printf>
    p->killed = 1;
    800029fc:	4785                	li	a5,1
    800029fe:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a00:	557d                	li	a0,-1
    80002a02:	00000097          	auipc	ra,0x0
    80002a06:	928080e7          	jalr	-1752(ra) # 8000232a <exit>
  if(which_dev == 2)
    80002a0a:	4789                	li	a5,2
    80002a0c:	f8f910e3          	bne	s2,a5,8000298c <usertrap+0x62>
    yield();
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	682080e7          	jalr	1666(ra) # 80002092 <yield>
    80002a18:	bf95                	j	8000298c <usertrap+0x62>
  int which_dev = 0;
    80002a1a:	4901                	li	s2,0
    80002a1c:	b7d5                	j	80002a00 <usertrap+0xd6>

0000000080002a1e <kerneltrap>:
{
    80002a1e:	7179                	addi	sp,sp,-48
    80002a20:	f406                	sd	ra,40(sp)
    80002a22:	f022                	sd	s0,32(sp)
    80002a24:	ec26                	sd	s1,24(sp)
    80002a26:	e84a                	sd	s2,16(sp)
    80002a28:	e44e                	sd	s3,8(sp)
    80002a2a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a2c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a30:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a34:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a38:	1004f793          	andi	a5,s1,256
    80002a3c:	cb85                	beqz	a5,80002a6c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a42:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a44:	ef85                	bnez	a5,80002a7c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	e42080e7          	jalr	-446(ra) # 80002888 <devintr>
    80002a4e:	cd1d                	beqz	a0,80002a8c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a50:	4789                	li	a5,2
    80002a52:	06f50a63          	beq	a0,a5,80002ac6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a56:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a5a:	10049073          	csrw	sstatus,s1
}
    80002a5e:	70a2                	ld	ra,40(sp)
    80002a60:	7402                	ld	s0,32(sp)
    80002a62:	64e2                	ld	s1,24(sp)
    80002a64:	6942                	ld	s2,16(sp)
    80002a66:	69a2                	ld	s3,8(sp)
    80002a68:	6145                	addi	sp,sp,48
    80002a6a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a6c:	00006517          	auipc	a0,0x6
    80002a70:	91450513          	addi	a0,a0,-1772 # 80008380 <states.0+0xc8>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	ab6080e7          	jalr	-1354(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	92c50513          	addi	a0,a0,-1748 # 800083a8 <states.0+0xf0>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	aa6080e7          	jalr	-1370(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002a8c:	85ce                	mv	a1,s3
    80002a8e:	00006517          	auipc	a0,0x6
    80002a92:	93a50513          	addi	a0,a0,-1734 # 800083c8 <states.0+0x110>
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	ade080e7          	jalr	-1314(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aa2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aa6:	00006517          	auipc	a0,0x6
    80002aaa:	93250513          	addi	a0,a0,-1742 # 800083d8 <states.0+0x120>
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	ac6080e7          	jalr	-1338(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	93a50513          	addi	a0,a0,-1734 # 800083f0 <states.0+0x138>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	a6c080e7          	jalr	-1428(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	ecc080e7          	jalr	-308(ra) # 80001992 <myproc>
    80002ace:	d541                	beqz	a0,80002a56 <kerneltrap+0x38>
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	ec2080e7          	jalr	-318(ra) # 80001992 <myproc>
    80002ad8:	4d18                	lw	a4,24(a0)
    80002ada:	4791                	li	a5,4
    80002adc:	f6f71de3          	bne	a4,a5,80002a56 <kerneltrap+0x38>
    yield();
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	5b2080e7          	jalr	1458(ra) # 80002092 <yield>
    80002ae8:	b7bd                	j	80002a56 <kerneltrap+0x38>

0000000080002aea <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aea:	1101                	addi	sp,sp,-32
    80002aec:	ec06                	sd	ra,24(sp)
    80002aee:	e822                	sd	s0,16(sp)
    80002af0:	e426                	sd	s1,8(sp)
    80002af2:	1000                	addi	s0,sp,32
    80002af4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	e9c080e7          	jalr	-356(ra) # 80001992 <myproc>
  switch (n)
    80002afe:	4795                	li	a5,5
    80002b00:	0497e163          	bltu	a5,s1,80002b42 <argraw+0x58>
    80002b04:	048a                	slli	s1,s1,0x2
    80002b06:	00006717          	auipc	a4,0x6
    80002b0a:	aa270713          	addi	a4,a4,-1374 # 800085a8 <states.0+0x2f0>
    80002b0e:	94ba                	add	s1,s1,a4
    80002b10:	409c                	lw	a5,0(s1)
    80002b12:	97ba                	add	a5,a5,a4
    80002b14:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002b16:	6d3c                	ld	a5,88(a0)
    80002b18:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b1a:	60e2                	ld	ra,24(sp)
    80002b1c:	6442                	ld	s0,16(sp)
    80002b1e:	64a2                	ld	s1,8(sp)
    80002b20:	6105                	addi	sp,sp,32
    80002b22:	8082                	ret
    return p->trapframe->a1;
    80002b24:	6d3c                	ld	a5,88(a0)
    80002b26:	7fa8                	ld	a0,120(a5)
    80002b28:	bfcd                	j	80002b1a <argraw+0x30>
    return p->trapframe->a2;
    80002b2a:	6d3c                	ld	a5,88(a0)
    80002b2c:	63c8                	ld	a0,128(a5)
    80002b2e:	b7f5                	j	80002b1a <argraw+0x30>
    return p->trapframe->a3;
    80002b30:	6d3c                	ld	a5,88(a0)
    80002b32:	67c8                	ld	a0,136(a5)
    80002b34:	b7dd                	j	80002b1a <argraw+0x30>
    return p->trapframe->a4;
    80002b36:	6d3c                	ld	a5,88(a0)
    80002b38:	6bc8                	ld	a0,144(a5)
    80002b3a:	b7c5                	j	80002b1a <argraw+0x30>
    return p->trapframe->a5;
    80002b3c:	6d3c                	ld	a5,88(a0)
    80002b3e:	6fc8                	ld	a0,152(a5)
    80002b40:	bfe9                	j	80002b1a <argraw+0x30>
  panic("argraw");
    80002b42:	00006517          	auipc	a0,0x6
    80002b46:	8be50513          	addi	a0,a0,-1858 # 80008400 <states.0+0x148>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	9e0080e7          	jalr	-1568(ra) # 8000052a <panic>

0000000080002b52 <fetchaddr>:
{
    80002b52:	1101                	addi	sp,sp,-32
    80002b54:	ec06                	sd	ra,24(sp)
    80002b56:	e822                	sd	s0,16(sp)
    80002b58:	e426                	sd	s1,8(sp)
    80002b5a:	e04a                	sd	s2,0(sp)
    80002b5c:	1000                	addi	s0,sp,32
    80002b5e:	84aa                	mv	s1,a0
    80002b60:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	e30080e7          	jalr	-464(ra) # 80001992 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002b6a:	653c                	ld	a5,72(a0)
    80002b6c:	02f4f863          	bgeu	s1,a5,80002b9c <fetchaddr+0x4a>
    80002b70:	00848713          	addi	a4,s1,8
    80002b74:	02e7e663          	bltu	a5,a4,80002ba0 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b78:	46a1                	li	a3,8
    80002b7a:	8626                	mv	a2,s1
    80002b7c:	85ca                	mv	a1,s2
    80002b7e:	6928                	ld	a0,80(a0)
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	b4a080e7          	jalr	-1206(ra) # 800016ca <copyin>
    80002b88:	00a03533          	snez	a0,a0
    80002b8c:	40a00533          	neg	a0,a0
}
    80002b90:	60e2                	ld	ra,24(sp)
    80002b92:	6442                	ld	s0,16(sp)
    80002b94:	64a2                	ld	s1,8(sp)
    80002b96:	6902                	ld	s2,0(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret
    return -1;
    80002b9c:	557d                	li	a0,-1
    80002b9e:	bfcd                	j	80002b90 <fetchaddr+0x3e>
    80002ba0:	557d                	li	a0,-1
    80002ba2:	b7fd                	j	80002b90 <fetchaddr+0x3e>

0000000080002ba4 <fetchstr>:
{
    80002ba4:	7179                	addi	sp,sp,-48
    80002ba6:	f406                	sd	ra,40(sp)
    80002ba8:	f022                	sd	s0,32(sp)
    80002baa:	ec26                	sd	s1,24(sp)
    80002bac:	e84a                	sd	s2,16(sp)
    80002bae:	e44e                	sd	s3,8(sp)
    80002bb0:	1800                	addi	s0,sp,48
    80002bb2:	892a                	mv	s2,a0
    80002bb4:	84ae                	mv	s1,a1
    80002bb6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bb8:	fffff097          	auipc	ra,0xfffff
    80002bbc:	dda080e7          	jalr	-550(ra) # 80001992 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bc0:	86ce                	mv	a3,s3
    80002bc2:	864a                	mv	a2,s2
    80002bc4:	85a6                	mv	a1,s1
    80002bc6:	6928                	ld	a0,80(a0)
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	b90080e7          	jalr	-1136(ra) # 80001758 <copyinstr>
  if (err < 0)
    80002bd0:	00054763          	bltz	a0,80002bde <fetchstr+0x3a>
  return strlen(buf);
    80002bd4:	8526                	mv	a0,s1
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	26c080e7          	jalr	620(ra) # 80000e42 <strlen>
}
    80002bde:	70a2                	ld	ra,40(sp)
    80002be0:	7402                	ld	s0,32(sp)
    80002be2:	64e2                	ld	s1,24(sp)
    80002be4:	6942                	ld	s2,16(sp)
    80002be6:	69a2                	ld	s3,8(sp)
    80002be8:	6145                	addi	sp,sp,48
    80002bea:	8082                	ret

0000000080002bec <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	1000                	addi	s0,sp,32
    80002bf6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	ef2080e7          	jalr	-270(ra) # 80002aea <argraw>
    80002c00:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c02:	4501                	li	a0,0
    80002c04:	60e2                	ld	ra,24(sp)
    80002c06:	6442                	ld	s0,16(sp)
    80002c08:	64a2                	ld	s1,8(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret

0000000080002c0e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002c0e:	1101                	addi	sp,sp,-32
    80002c10:	ec06                	sd	ra,24(sp)
    80002c12:	e822                	sd	s0,16(sp)
    80002c14:	e426                	sd	s1,8(sp)
    80002c16:	1000                	addi	s0,sp,32
    80002c18:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	ed0080e7          	jalr	-304(ra) # 80002aea <argraw>
    80002c22:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c24:	4501                	li	a0,0
    80002c26:	60e2                	ld	ra,24(sp)
    80002c28:	6442                	ld	s0,16(sp)
    80002c2a:	64a2                	ld	s1,8(sp)
    80002c2c:	6105                	addi	sp,sp,32
    80002c2e:	8082                	ret

0000000080002c30 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002c30:	1101                	addi	sp,sp,-32
    80002c32:	ec06                	sd	ra,24(sp)
    80002c34:	e822                	sd	s0,16(sp)
    80002c36:	e426                	sd	s1,8(sp)
    80002c38:	e04a                	sd	s2,0(sp)
    80002c3a:	1000                	addi	s0,sp,32
    80002c3c:	84ae                	mv	s1,a1
    80002c3e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	eaa080e7          	jalr	-342(ra) # 80002aea <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c48:	864a                	mv	a2,s2
    80002c4a:	85a6                	mv	a1,s1
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	f58080e7          	jalr	-168(ra) # 80002ba4 <fetchstr>
}
    80002c54:	60e2                	ld	ra,24(sp)
    80002c56:	6442                	ld	s0,16(sp)
    80002c58:	64a2                	ld	s1,8(sp)
    80002c5a:	6902                	ld	s2,0(sp)
    80002c5c:	6105                	addi	sp,sp,32
    80002c5e:	8082                	ret

0000000080002c60 <syscall>:
    [SYS_mkdir] "sys_mkdir",
    [SYS_close] "sys_close",
    [SYS_trace] "sys_trace",
};
void syscall(void)
{
    80002c60:	7139                	addi	sp,sp,-64
    80002c62:	fc06                	sd	ra,56(sp)
    80002c64:	f822                	sd	s0,48(sp)
    80002c66:	f426                	sd	s1,40(sp)
    80002c68:	f04a                	sd	s2,32(sp)
    80002c6a:	ec4e                	sd	s3,24(sp)
    80002c6c:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	d24080e7          	jalr	-732(ra) # 80001992 <myproc>
    80002c76:	84aa                	mv	s1,a0
  int firstArg;
  num = p->trapframe->a7;
    80002c78:	05853903          	ld	s2,88(a0)
    80002c7c:	0a893783          	ld	a5,168(s2) # 60a8 <_entry-0x7fff9f58>
    80002c80:	0007899b          	sext.w	s3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002c84:	37fd                	addiw	a5,a5,-1
    80002c86:	4755                	li	a4,21
    80002c88:	0cf76563          	bltu	a4,a5,80002d52 <syscall+0xf2>
    80002c8c:	00399713          	slli	a4,s3,0x3
    80002c90:	00006797          	auipc	a5,0x6
    80002c94:	93078793          	addi	a5,a5,-1744 # 800085c0 <syscalls>
    80002c98:	97ba                	add	a5,a5,a4
    80002c9a:	639c                	ld	a5,0(a5)
    80002c9c:	cbdd                	beqz	a5,80002d52 <syscall+0xf2>
  {
    p->trapframe->a0 = syscalls[num]();
    80002c9e:	9782                	jalr	a5
    80002ca0:	06a93823          	sd	a0,112(s2)
    //start messing with code
    if ((p->traceMask & (1 << num)))
    80002ca4:	58dc                	lw	a5,52(s1)
    80002ca6:	4137d7bb          	sraw	a5,a5,s3
    80002caa:	8b85                	andi	a5,a5,1
    80002cac:	c3f1                	beqz	a5,80002d70 <syscall+0x110>
    {
      printf("%d: syscall %s ", p->pid, syscalls_str[num]);
    80002cae:	00399713          	slli	a4,s3,0x3
    80002cb2:	00006797          	auipc	a5,0x6
    80002cb6:	90e78793          	addi	a5,a5,-1778 # 800085c0 <syscalls>
    80002cba:	97ba                	add	a5,a5,a4
    80002cbc:	7fd0                	ld	a2,184(a5)
    80002cbe:	588c                	lw	a1,48(s1)
    80002cc0:	00005517          	auipc	a0,0x5
    80002cc4:	74850513          	addi	a0,a0,1864 # 80008408 <states.0+0x150>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	8ac080e7          	jalr	-1876(ra) # 80000574 <printf>
      if (num == SYS_fork)
    80002cd0:	4785                	li	a5,1
    80002cd2:	02f98363          	beq	s3,a5,80002cf8 <syscall+0x98>
      {
        printf("NULL ");
      }
      if (num == SYS_kill)
    80002cd6:	4799                	li	a5,6
    80002cd8:	02f98963          	beq	s3,a5,80002d0a <syscall+0xaa>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      if (num == SYS_sbrk)
    80002cdc:	47b1                	li	a5,12
    80002cde:	04f98863          	beq	s3,a5,80002d2e <syscall+0xce>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      printf("-> %d\n", p->trapframe->a0);
    80002ce2:	6cbc                	ld	a5,88(s1)
    80002ce4:	7bac                	ld	a1,112(a5)
    80002ce6:	00005517          	auipc	a0,0x5
    80002cea:	74250513          	addi	a0,a0,1858 # 80008428 <states.0+0x170>
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	886080e7          	jalr	-1914(ra) # 80000574 <printf>
    80002cf6:	a8ad                	j	80002d70 <syscall+0x110>
        printf("NULL ");
    80002cf8:	00005517          	auipc	a0,0x5
    80002cfc:	72050513          	addi	a0,a0,1824 # 80008418 <states.0+0x160>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	874080e7          	jalr	-1932(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002d08:	bfe9                	j	80002ce2 <syscall+0x82>
        argint(0, &firstArg);
    80002d0a:	fcc40593          	addi	a1,s0,-52
    80002d0e:	4501                	li	a0,0
    80002d10:	00000097          	auipc	ra,0x0
    80002d14:	edc080e7          	jalr	-292(ra) # 80002bec <argint>
        printf("%d ", firstArg);
    80002d18:	fcc42583          	lw	a1,-52(s0)
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	70450513          	addi	a0,a0,1796 # 80008420 <states.0+0x168>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	850080e7          	jalr	-1968(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002d2c:	bf5d                	j	80002ce2 <syscall+0x82>
        argint(0, &firstArg);
    80002d2e:	fcc40593          	addi	a1,s0,-52
    80002d32:	4501                	li	a0,0
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	eb8080e7          	jalr	-328(ra) # 80002bec <argint>
        printf("%d ", firstArg);
    80002d3c:	fcc42583          	lw	a1,-52(s0)
    80002d40:	00005517          	auipc	a0,0x5
    80002d44:	6e050513          	addi	a0,a0,1760 # 80008420 <states.0+0x168>
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	82c080e7          	jalr	-2004(ra) # 80000574 <printf>
    80002d50:	bf49                	j	80002ce2 <syscall+0x82>
    }
    //end messing with code
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002d52:	86ce                	mv	a3,s3
    80002d54:	15848613          	addi	a2,s1,344
    80002d58:	588c                	lw	a1,48(s1)
    80002d5a:	00005517          	auipc	a0,0x5
    80002d5e:	6d650513          	addi	a0,a0,1750 # 80008430 <states.0+0x178>
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	812080e7          	jalr	-2030(ra) # 80000574 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d6a:	6cbc                	ld	a5,88(s1)
    80002d6c:	577d                	li	a4,-1
    80002d6e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d70:	70e2                	ld	ra,56(sp)
    80002d72:	7442                	ld	s0,48(sp)
    80002d74:	74a2                	ld	s1,40(sp)
    80002d76:	7902                	ld	s2,32(sp)
    80002d78:	69e2                	ld	s3,24(sp)
    80002d7a:	6121                	addi	sp,sp,64
    80002d7c:	8082                	ret

0000000080002d7e <sys_trace>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_trace(void)
{
    80002d7e:	1101                	addi	sp,sp,-32
    80002d80:	ec06                	sd	ra,24(sp)
    80002d82:	e822                	sd	s0,16(sp)
    80002d84:	1000                	addi	s0,sp,32
  int mask;
  int pid;
  argint(0, &mask);
    80002d86:	fec40593          	addi	a1,s0,-20
    80002d8a:	4501                	li	a0,0
    80002d8c:	00000097          	auipc	ra,0x0
    80002d90:	e60080e7          	jalr	-416(ra) # 80002bec <argint>
  if(argint(1, &pid) < 0)
    80002d94:	fe840593          	addi	a1,s0,-24
    80002d98:	4505                	li	a0,1
    80002d9a:	00000097          	auipc	ra,0x0
    80002d9e:	e52080e7          	jalr	-430(ra) # 80002bec <argint>
    80002da2:	87aa                	mv	a5,a0
    return -1;
    80002da4:	557d                	li	a0,-1
  if(argint(1, &pid) < 0)
    80002da6:	0007ca63          	bltz	a5,80002dba <sys_trace+0x3c>
  return trace(mask, pid);
    80002daa:	fe842583          	lw	a1,-24(s0)
    80002dae:	fec42503          	lw	a0,-20(s0)
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	6fc080e7          	jalr	1788(ra) # 800024ae <trace>
}
    80002dba:	60e2                	ld	ra,24(sp)
    80002dbc:	6442                	ld	s0,16(sp)
    80002dbe:	6105                	addi	sp,sp,32
    80002dc0:	8082                	ret

0000000080002dc2 <sys_exit>:

uint64
sys_exit(void)
{
    80002dc2:	1101                	addi	sp,sp,-32
    80002dc4:	ec06                	sd	ra,24(sp)
    80002dc6:	e822                	sd	s0,16(sp)
    80002dc8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dca:	fec40593          	addi	a1,s0,-20
    80002dce:	4501                	li	a0,0
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	e1c080e7          	jalr	-484(ra) # 80002bec <argint>
    return -1;
    80002dd8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dda:	00054963          	bltz	a0,80002dec <sys_exit+0x2a>
  exit(n);
    80002dde:	fec42503          	lw	a0,-20(s0)
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	548080e7          	jalr	1352(ra) # 8000232a <exit>
  return 0;  // not reached
    80002dea:	4781                	li	a5,0
}
    80002dec:	853e                	mv	a0,a5
    80002dee:	60e2                	ld	ra,24(sp)
    80002df0:	6442                	ld	s0,16(sp)
    80002df2:	6105                	addi	sp,sp,32
    80002df4:	8082                	ret

0000000080002df6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002df6:	1141                	addi	sp,sp,-16
    80002df8:	e406                	sd	ra,8(sp)
    80002dfa:	e022                	sd	s0,0(sp)
    80002dfc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dfe:	fffff097          	auipc	ra,0xfffff
    80002e02:	b94080e7          	jalr	-1132(ra) # 80001992 <myproc>
}
    80002e06:	5908                	lw	a0,48(a0)
    80002e08:	60a2                	ld	ra,8(sp)
    80002e0a:	6402                	ld	s0,0(sp)
    80002e0c:	0141                	addi	sp,sp,16
    80002e0e:	8082                	ret

0000000080002e10 <sys_fork>:

uint64
sys_fork(void)
{
    80002e10:	1141                	addi	sp,sp,-16
    80002e12:	e406                	sd	ra,8(sp)
    80002e14:	e022                	sd	s0,0(sp)
    80002e16:	0800                	addi	s0,sp,16
  return fork();
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	f90080e7          	jalr	-112(ra) # 80001da8 <fork>
}
    80002e20:	60a2                	ld	ra,8(sp)
    80002e22:	6402                	ld	s0,0(sp)
    80002e24:	0141                	addi	sp,sp,16
    80002e26:	8082                	ret

0000000080002e28 <sys_wait>:

uint64
sys_wait(void)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e30:	fe840593          	addi	a1,s0,-24
    80002e34:	4501                	li	a0,0
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	dd8080e7          	jalr	-552(ra) # 80002c0e <argaddr>
    80002e3e:	87aa                	mv	a5,a0
    return -1;
    80002e40:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e42:	0007c863          	bltz	a5,80002e52 <sys_wait+0x2a>
  return wait(p);
    80002e46:	fe843503          	ld	a0,-24(s0)
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	2e8080e7          	jalr	744(ra) # 80002132 <wait>
}
    80002e52:	60e2                	ld	ra,24(sp)
    80002e54:	6442                	ld	s0,16(sp)
    80002e56:	6105                	addi	sp,sp,32
    80002e58:	8082                	ret

0000000080002e5a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e5a:	7179                	addi	sp,sp,-48
    80002e5c:	f406                	sd	ra,40(sp)
    80002e5e:	f022                	sd	s0,32(sp)
    80002e60:	ec26                	sd	s1,24(sp)
    80002e62:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e64:	fdc40593          	addi	a1,s0,-36
    80002e68:	4501                	li	a0,0
    80002e6a:	00000097          	auipc	ra,0x0
    80002e6e:	d82080e7          	jalr	-638(ra) # 80002bec <argint>
    return -1;
    80002e72:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002e74:	00054f63          	bltz	a0,80002e92 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	b1a080e7          	jalr	-1254(ra) # 80001992 <myproc>
    80002e80:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e82:	fdc42503          	lw	a0,-36(s0)
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	eae080e7          	jalr	-338(ra) # 80001d34 <growproc>
    80002e8e:	00054863          	bltz	a0,80002e9e <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002e92:	8526                	mv	a0,s1
    80002e94:	70a2                	ld	ra,40(sp)
    80002e96:	7402                	ld	s0,32(sp)
    80002e98:	64e2                	ld	s1,24(sp)
    80002e9a:	6145                	addi	sp,sp,48
    80002e9c:	8082                	ret
    return -1;
    80002e9e:	54fd                	li	s1,-1
    80002ea0:	bfcd                	j	80002e92 <sys_sbrk+0x38>

0000000080002ea2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ea2:	7139                	addi	sp,sp,-64
    80002ea4:	fc06                	sd	ra,56(sp)
    80002ea6:	f822                	sd	s0,48(sp)
    80002ea8:	f426                	sd	s1,40(sp)
    80002eaa:	f04a                	sd	s2,32(sp)
    80002eac:	ec4e                	sd	s3,24(sp)
    80002eae:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002eb0:	fcc40593          	addi	a1,s0,-52
    80002eb4:	4501                	li	a0,0
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	d36080e7          	jalr	-714(ra) # 80002bec <argint>
    return -1;
    80002ebe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ec0:	06054563          	bltz	a0,80002f2a <sys_sleep+0x88>
  acquire(&tickslock);
    80002ec4:	00015517          	auipc	a0,0x15
    80002ec8:	80c50513          	addi	a0,a0,-2036 # 800176d0 <tickslock>
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	cf6080e7          	jalr	-778(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002ed4:	00006917          	auipc	s2,0x6
    80002ed8:	15c92903          	lw	s2,348(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002edc:	fcc42783          	lw	a5,-52(s0)
    80002ee0:	cf85                	beqz	a5,80002f18 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ee2:	00014997          	auipc	s3,0x14
    80002ee6:	7ee98993          	addi	s3,s3,2030 # 800176d0 <tickslock>
    80002eea:	00006497          	auipc	s1,0x6
    80002eee:	14648493          	addi	s1,s1,326 # 80009030 <ticks>
    if(myproc()->killed){
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	aa0080e7          	jalr	-1376(ra) # 80001992 <myproc>
    80002efa:	551c                	lw	a5,40(a0)
    80002efc:	ef9d                	bnez	a5,80002f3a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002efe:	85ce                	mv	a1,s3
    80002f00:	8526                	mv	a0,s1
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	1cc080e7          	jalr	460(ra) # 800020ce <sleep>
  while(ticks - ticks0 < n){
    80002f0a:	409c                	lw	a5,0(s1)
    80002f0c:	412787bb          	subw	a5,a5,s2
    80002f10:	fcc42703          	lw	a4,-52(s0)
    80002f14:	fce7efe3          	bltu	a5,a4,80002ef2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f18:	00014517          	auipc	a0,0x14
    80002f1c:	7b850513          	addi	a0,a0,1976 # 800176d0 <tickslock>
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	d56080e7          	jalr	-682(ra) # 80000c76 <release>
  return 0;
    80002f28:	4781                	li	a5,0
}
    80002f2a:	853e                	mv	a0,a5
    80002f2c:	70e2                	ld	ra,56(sp)
    80002f2e:	7442                	ld	s0,48(sp)
    80002f30:	74a2                	ld	s1,40(sp)
    80002f32:	7902                	ld	s2,32(sp)
    80002f34:	69e2                	ld	s3,24(sp)
    80002f36:	6121                	addi	sp,sp,64
    80002f38:	8082                	ret
      release(&tickslock);
    80002f3a:	00014517          	auipc	a0,0x14
    80002f3e:	79650513          	addi	a0,a0,1942 # 800176d0 <tickslock>
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	d34080e7          	jalr	-716(ra) # 80000c76 <release>
      return -1;
    80002f4a:	57fd                	li	a5,-1
    80002f4c:	bff9                	j	80002f2a <sys_sleep+0x88>

0000000080002f4e <sys_kill>:

uint64
sys_kill(void)
{
    80002f4e:	1101                	addi	sp,sp,-32
    80002f50:	ec06                	sd	ra,24(sp)
    80002f52:	e822                	sd	s0,16(sp)
    80002f54:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f56:	fec40593          	addi	a1,s0,-20
    80002f5a:	4501                	li	a0,0
    80002f5c:	00000097          	auipc	ra,0x0
    80002f60:	c90080e7          	jalr	-880(ra) # 80002bec <argint>
    80002f64:	87aa                	mv	a5,a0
    return -1;
    80002f66:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f68:	0007c863          	bltz	a5,80002f78 <sys_kill+0x2a>
  return kill(pid);
    80002f6c:	fec42503          	lw	a0,-20(s0)
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	4cc080e7          	jalr	1228(ra) # 8000243c <kill>
}
    80002f78:	60e2                	ld	ra,24(sp)
    80002f7a:	6442                	ld	s0,16(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret

0000000080002f80 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f80:	1101                	addi	sp,sp,-32
    80002f82:	ec06                	sd	ra,24(sp)
    80002f84:	e822                	sd	s0,16(sp)
    80002f86:	e426                	sd	s1,8(sp)
    80002f88:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f8a:	00014517          	auipc	a0,0x14
    80002f8e:	74650513          	addi	a0,a0,1862 # 800176d0 <tickslock>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	c30080e7          	jalr	-976(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002f9a:	00006497          	auipc	s1,0x6
    80002f9e:	0964a483          	lw	s1,150(s1) # 80009030 <ticks>
  release(&tickslock);
    80002fa2:	00014517          	auipc	a0,0x14
    80002fa6:	72e50513          	addi	a0,a0,1838 # 800176d0 <tickslock>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	ccc080e7          	jalr	-820(ra) # 80000c76 <release>
  return xticks;
}
    80002fb2:	02049513          	slli	a0,s1,0x20
    80002fb6:	9101                	srli	a0,a0,0x20
    80002fb8:	60e2                	ld	ra,24(sp)
    80002fba:	6442                	ld	s0,16(sp)
    80002fbc:	64a2                	ld	s1,8(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret

0000000080002fc2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fc2:	7179                	addi	sp,sp,-48
    80002fc4:	f406                	sd	ra,40(sp)
    80002fc6:	f022                	sd	s0,32(sp)
    80002fc8:	ec26                	sd	s1,24(sp)
    80002fca:	e84a                	sd	s2,16(sp)
    80002fcc:	e44e                	sd	s3,8(sp)
    80002fce:	e052                	sd	s4,0(sp)
    80002fd0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fd2:	00005597          	auipc	a1,0x5
    80002fd6:	75e58593          	addi	a1,a1,1886 # 80008730 <syscalls_str+0xb8>
    80002fda:	00014517          	auipc	a0,0x14
    80002fde:	70e50513          	addi	a0,a0,1806 # 800176e8 <bcache>
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	b50080e7          	jalr	-1200(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fea:	0001c797          	auipc	a5,0x1c
    80002fee:	6fe78793          	addi	a5,a5,1790 # 8001f6e8 <bcache+0x8000>
    80002ff2:	0001d717          	auipc	a4,0x1d
    80002ff6:	95e70713          	addi	a4,a4,-1698 # 8001f950 <bcache+0x8268>
    80002ffa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ffe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003002:	00014497          	auipc	s1,0x14
    80003006:	6fe48493          	addi	s1,s1,1790 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    8000300a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000300c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000300e:	00005a17          	auipc	s4,0x5
    80003012:	72aa0a13          	addi	s4,s4,1834 # 80008738 <syscalls_str+0xc0>
    b->next = bcache.head.next;
    80003016:	2b893783          	ld	a5,696(s2)
    8000301a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000301c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003020:	85d2                	mv	a1,s4
    80003022:	01048513          	addi	a0,s1,16
    80003026:	00001097          	auipc	ra,0x1
    8000302a:	4c2080e7          	jalr	1218(ra) # 800044e8 <initsleeplock>
    bcache.head.next->prev = b;
    8000302e:	2b893783          	ld	a5,696(s2)
    80003032:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003034:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003038:	45848493          	addi	s1,s1,1112
    8000303c:	fd349de3          	bne	s1,s3,80003016 <binit+0x54>
  }
}
    80003040:	70a2                	ld	ra,40(sp)
    80003042:	7402                	ld	s0,32(sp)
    80003044:	64e2                	ld	s1,24(sp)
    80003046:	6942                	ld	s2,16(sp)
    80003048:	69a2                	ld	s3,8(sp)
    8000304a:	6a02                	ld	s4,0(sp)
    8000304c:	6145                	addi	sp,sp,48
    8000304e:	8082                	ret

0000000080003050 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003050:	7179                	addi	sp,sp,-48
    80003052:	f406                	sd	ra,40(sp)
    80003054:	f022                	sd	s0,32(sp)
    80003056:	ec26                	sd	s1,24(sp)
    80003058:	e84a                	sd	s2,16(sp)
    8000305a:	e44e                	sd	s3,8(sp)
    8000305c:	1800                	addi	s0,sp,48
    8000305e:	892a                	mv	s2,a0
    80003060:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003062:	00014517          	auipc	a0,0x14
    80003066:	68650513          	addi	a0,a0,1670 # 800176e8 <bcache>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	b58080e7          	jalr	-1192(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003072:	0001d497          	auipc	s1,0x1d
    80003076:	92e4b483          	ld	s1,-1746(s1) # 8001f9a0 <bcache+0x82b8>
    8000307a:	0001d797          	auipc	a5,0x1d
    8000307e:	8d678793          	addi	a5,a5,-1834 # 8001f950 <bcache+0x8268>
    80003082:	02f48f63          	beq	s1,a5,800030c0 <bread+0x70>
    80003086:	873e                	mv	a4,a5
    80003088:	a021                	j	80003090 <bread+0x40>
    8000308a:	68a4                	ld	s1,80(s1)
    8000308c:	02e48a63          	beq	s1,a4,800030c0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003090:	449c                	lw	a5,8(s1)
    80003092:	ff279ce3          	bne	a5,s2,8000308a <bread+0x3a>
    80003096:	44dc                	lw	a5,12(s1)
    80003098:	ff3799e3          	bne	a5,s3,8000308a <bread+0x3a>
      b->refcnt++;
    8000309c:	40bc                	lw	a5,64(s1)
    8000309e:	2785                	addiw	a5,a5,1
    800030a0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030a2:	00014517          	auipc	a0,0x14
    800030a6:	64650513          	addi	a0,a0,1606 # 800176e8 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	bcc080e7          	jalr	-1076(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800030b2:	01048513          	addi	a0,s1,16
    800030b6:	00001097          	auipc	ra,0x1
    800030ba:	46c080e7          	jalr	1132(ra) # 80004522 <acquiresleep>
      return b;
    800030be:	a8b9                	j	8000311c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c0:	0001d497          	auipc	s1,0x1d
    800030c4:	8d84b483          	ld	s1,-1832(s1) # 8001f998 <bcache+0x82b0>
    800030c8:	0001d797          	auipc	a5,0x1d
    800030cc:	88878793          	addi	a5,a5,-1912 # 8001f950 <bcache+0x8268>
    800030d0:	00f48863          	beq	s1,a5,800030e0 <bread+0x90>
    800030d4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030d6:	40bc                	lw	a5,64(s1)
    800030d8:	cf81                	beqz	a5,800030f0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030da:	64a4                	ld	s1,72(s1)
    800030dc:	fee49de3          	bne	s1,a4,800030d6 <bread+0x86>
  panic("bget: no buffers");
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	66050513          	addi	a0,a0,1632 # 80008740 <syscalls_str+0xc8>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	442080e7          	jalr	1090(ra) # 8000052a <panic>
      b->dev = dev;
    800030f0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030f4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030f8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030fc:	4785                	li	a5,1
    800030fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003100:	00014517          	auipc	a0,0x14
    80003104:	5e850513          	addi	a0,a0,1512 # 800176e8 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	b6e080e7          	jalr	-1170(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003110:	01048513          	addi	a0,s1,16
    80003114:	00001097          	auipc	ra,0x1
    80003118:	40e080e7          	jalr	1038(ra) # 80004522 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000311c:	409c                	lw	a5,0(s1)
    8000311e:	cb89                	beqz	a5,80003130 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003120:	8526                	mv	a0,s1
    80003122:	70a2                	ld	ra,40(sp)
    80003124:	7402                	ld	s0,32(sp)
    80003126:	64e2                	ld	s1,24(sp)
    80003128:	6942                	ld	s2,16(sp)
    8000312a:	69a2                	ld	s3,8(sp)
    8000312c:	6145                	addi	sp,sp,48
    8000312e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003130:	4581                	li	a1,0
    80003132:	8526                	mv	a0,s1
    80003134:	00003097          	auipc	ra,0x3
    80003138:	f22080e7          	jalr	-222(ra) # 80006056 <virtio_disk_rw>
    b->valid = 1;
    8000313c:	4785                	li	a5,1
    8000313e:	c09c                	sw	a5,0(s1)
  return b;
    80003140:	b7c5                	j	80003120 <bread+0xd0>

0000000080003142 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000314e:	0541                	addi	a0,a0,16
    80003150:	00001097          	auipc	ra,0x1
    80003154:	46c080e7          	jalr	1132(ra) # 800045bc <holdingsleep>
    80003158:	cd01                	beqz	a0,80003170 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000315a:	4585                	li	a1,1
    8000315c:	8526                	mv	a0,s1
    8000315e:	00003097          	auipc	ra,0x3
    80003162:	ef8080e7          	jalr	-264(ra) # 80006056 <virtio_disk_rw>
}
    80003166:	60e2                	ld	ra,24(sp)
    80003168:	6442                	ld	s0,16(sp)
    8000316a:	64a2                	ld	s1,8(sp)
    8000316c:	6105                	addi	sp,sp,32
    8000316e:	8082                	ret
    panic("bwrite");
    80003170:	00005517          	auipc	a0,0x5
    80003174:	5e850513          	addi	a0,a0,1512 # 80008758 <syscalls_str+0xe0>
    80003178:	ffffd097          	auipc	ra,0xffffd
    8000317c:	3b2080e7          	jalr	946(ra) # 8000052a <panic>

0000000080003180 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	e426                	sd	s1,8(sp)
    80003188:	e04a                	sd	s2,0(sp)
    8000318a:	1000                	addi	s0,sp,32
    8000318c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000318e:	01050913          	addi	s2,a0,16
    80003192:	854a                	mv	a0,s2
    80003194:	00001097          	auipc	ra,0x1
    80003198:	428080e7          	jalr	1064(ra) # 800045bc <holdingsleep>
    8000319c:	c92d                	beqz	a0,8000320e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000319e:	854a                	mv	a0,s2
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	3d8080e7          	jalr	984(ra) # 80004578 <releasesleep>

  acquire(&bcache.lock);
    800031a8:	00014517          	auipc	a0,0x14
    800031ac:	54050513          	addi	a0,a0,1344 # 800176e8 <bcache>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	a12080e7          	jalr	-1518(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800031b8:	40bc                	lw	a5,64(s1)
    800031ba:	37fd                	addiw	a5,a5,-1
    800031bc:	0007871b          	sext.w	a4,a5
    800031c0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031c2:	eb05                	bnez	a4,800031f2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031c4:	68bc                	ld	a5,80(s1)
    800031c6:	64b8                	ld	a4,72(s1)
    800031c8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031ca:	64bc                	ld	a5,72(s1)
    800031cc:	68b8                	ld	a4,80(s1)
    800031ce:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031d0:	0001c797          	auipc	a5,0x1c
    800031d4:	51878793          	addi	a5,a5,1304 # 8001f6e8 <bcache+0x8000>
    800031d8:	2b87b703          	ld	a4,696(a5)
    800031dc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031de:	0001c717          	auipc	a4,0x1c
    800031e2:	77270713          	addi	a4,a4,1906 # 8001f950 <bcache+0x8268>
    800031e6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031e8:	2b87b703          	ld	a4,696(a5)
    800031ec:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ee:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031f2:	00014517          	auipc	a0,0x14
    800031f6:	4f650513          	addi	a0,a0,1270 # 800176e8 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	a7c080e7          	jalr	-1412(ra) # 80000c76 <release>
}
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	64a2                	ld	s1,8(sp)
    80003208:	6902                	ld	s2,0(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret
    panic("brelse");
    8000320e:	00005517          	auipc	a0,0x5
    80003212:	55250513          	addi	a0,a0,1362 # 80008760 <syscalls_str+0xe8>
    80003216:	ffffd097          	auipc	ra,0xffffd
    8000321a:	314080e7          	jalr	788(ra) # 8000052a <panic>

000000008000321e <bpin>:

void
bpin(struct buf *b) {
    8000321e:	1101                	addi	sp,sp,-32
    80003220:	ec06                	sd	ra,24(sp)
    80003222:	e822                	sd	s0,16(sp)
    80003224:	e426                	sd	s1,8(sp)
    80003226:	1000                	addi	s0,sp,32
    80003228:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000322a:	00014517          	auipc	a0,0x14
    8000322e:	4be50513          	addi	a0,a0,1214 # 800176e8 <bcache>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	990080e7          	jalr	-1648(ra) # 80000bc2 <acquire>
  b->refcnt++;
    8000323a:	40bc                	lw	a5,64(s1)
    8000323c:	2785                	addiw	a5,a5,1
    8000323e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003240:	00014517          	auipc	a0,0x14
    80003244:	4a850513          	addi	a0,a0,1192 # 800176e8 <bcache>
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	a2e080e7          	jalr	-1490(ra) # 80000c76 <release>
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	64a2                	ld	s1,8(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret

000000008000325a <bunpin>:

void
bunpin(struct buf *b) {
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003266:	00014517          	auipc	a0,0x14
    8000326a:	48250513          	addi	a0,a0,1154 # 800176e8 <bcache>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	954080e7          	jalr	-1708(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003276:	40bc                	lw	a5,64(s1)
    80003278:	37fd                	addiw	a5,a5,-1
    8000327a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000327c:	00014517          	auipc	a0,0x14
    80003280:	46c50513          	addi	a0,a0,1132 # 800176e8 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	9f2080e7          	jalr	-1550(ra) # 80000c76 <release>
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret

0000000080003296 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003296:	1101                	addi	sp,sp,-32
    80003298:	ec06                	sd	ra,24(sp)
    8000329a:	e822                	sd	s0,16(sp)
    8000329c:	e426                	sd	s1,8(sp)
    8000329e:	e04a                	sd	s2,0(sp)
    800032a0:	1000                	addi	s0,sp,32
    800032a2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032a4:	00d5d59b          	srliw	a1,a1,0xd
    800032a8:	0001d797          	auipc	a5,0x1d
    800032ac:	b1c7a783          	lw	a5,-1252(a5) # 8001fdc4 <sb+0x1c>
    800032b0:	9dbd                	addw	a1,a1,a5
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	d9e080e7          	jalr	-610(ra) # 80003050 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032ba:	0074f713          	andi	a4,s1,7
    800032be:	4785                	li	a5,1
    800032c0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032c4:	14ce                	slli	s1,s1,0x33
    800032c6:	90d9                	srli	s1,s1,0x36
    800032c8:	00950733          	add	a4,a0,s1
    800032cc:	05874703          	lbu	a4,88(a4)
    800032d0:	00e7f6b3          	and	a3,a5,a4
    800032d4:	c69d                	beqz	a3,80003302 <bfree+0x6c>
    800032d6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032d8:	94aa                	add	s1,s1,a0
    800032da:	fff7c793          	not	a5,a5
    800032de:	8ff9                	and	a5,a5,a4
    800032e0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032e4:	00001097          	auipc	ra,0x1
    800032e8:	11e080e7          	jalr	286(ra) # 80004402 <log_write>
  brelse(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	e92080e7          	jalr	-366(ra) # 80003180 <brelse>
}
    800032f6:	60e2                	ld	ra,24(sp)
    800032f8:	6442                	ld	s0,16(sp)
    800032fa:	64a2                	ld	s1,8(sp)
    800032fc:	6902                	ld	s2,0(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret
    panic("freeing free block");
    80003302:	00005517          	auipc	a0,0x5
    80003306:	46650513          	addi	a0,a0,1126 # 80008768 <syscalls_str+0xf0>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	220080e7          	jalr	544(ra) # 8000052a <panic>

0000000080003312 <balloc>:
{
    80003312:	711d                	addi	sp,sp,-96
    80003314:	ec86                	sd	ra,88(sp)
    80003316:	e8a2                	sd	s0,80(sp)
    80003318:	e4a6                	sd	s1,72(sp)
    8000331a:	e0ca                	sd	s2,64(sp)
    8000331c:	fc4e                	sd	s3,56(sp)
    8000331e:	f852                	sd	s4,48(sp)
    80003320:	f456                	sd	s5,40(sp)
    80003322:	f05a                	sd	s6,32(sp)
    80003324:	ec5e                	sd	s7,24(sp)
    80003326:	e862                	sd	s8,16(sp)
    80003328:	e466                	sd	s9,8(sp)
    8000332a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000332c:	0001d797          	auipc	a5,0x1d
    80003330:	a807a783          	lw	a5,-1408(a5) # 8001fdac <sb+0x4>
    80003334:	cbd1                	beqz	a5,800033c8 <balloc+0xb6>
    80003336:	8baa                	mv	s7,a0
    80003338:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000333a:	0001db17          	auipc	s6,0x1d
    8000333e:	a6eb0b13          	addi	s6,s6,-1426 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003342:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003344:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003346:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003348:	6c89                	lui	s9,0x2
    8000334a:	a831                	j	80003366 <balloc+0x54>
    brelse(bp);
    8000334c:	854a                	mv	a0,s2
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	e32080e7          	jalr	-462(ra) # 80003180 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003356:	015c87bb          	addw	a5,s9,s5
    8000335a:	00078a9b          	sext.w	s5,a5
    8000335e:	004b2703          	lw	a4,4(s6)
    80003362:	06eaf363          	bgeu	s5,a4,800033c8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003366:	41fad79b          	sraiw	a5,s5,0x1f
    8000336a:	0137d79b          	srliw	a5,a5,0x13
    8000336e:	015787bb          	addw	a5,a5,s5
    80003372:	40d7d79b          	sraiw	a5,a5,0xd
    80003376:	01cb2583          	lw	a1,28(s6)
    8000337a:	9dbd                	addw	a1,a1,a5
    8000337c:	855e                	mv	a0,s7
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	cd2080e7          	jalr	-814(ra) # 80003050 <bread>
    80003386:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003388:	004b2503          	lw	a0,4(s6)
    8000338c:	000a849b          	sext.w	s1,s5
    80003390:	8662                	mv	a2,s8
    80003392:	faa4fde3          	bgeu	s1,a0,8000334c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003396:	41f6579b          	sraiw	a5,a2,0x1f
    8000339a:	01d7d69b          	srliw	a3,a5,0x1d
    8000339e:	00c6873b          	addw	a4,a3,a2
    800033a2:	00777793          	andi	a5,a4,7
    800033a6:	9f95                	subw	a5,a5,a3
    800033a8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033ac:	4037571b          	sraiw	a4,a4,0x3
    800033b0:	00e906b3          	add	a3,s2,a4
    800033b4:	0586c683          	lbu	a3,88(a3)
    800033b8:	00d7f5b3          	and	a1,a5,a3
    800033bc:	cd91                	beqz	a1,800033d8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033be:	2605                	addiw	a2,a2,1
    800033c0:	2485                	addiw	s1,s1,1
    800033c2:	fd4618e3          	bne	a2,s4,80003392 <balloc+0x80>
    800033c6:	b759                	j	8000334c <balloc+0x3a>
  panic("balloc: out of blocks");
    800033c8:	00005517          	auipc	a0,0x5
    800033cc:	3b850513          	addi	a0,a0,952 # 80008780 <syscalls_str+0x108>
    800033d0:	ffffd097          	auipc	ra,0xffffd
    800033d4:	15a080e7          	jalr	346(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033d8:	974a                	add	a4,a4,s2
    800033da:	8fd5                	or	a5,a5,a3
    800033dc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033e0:	854a                	mv	a0,s2
    800033e2:	00001097          	auipc	ra,0x1
    800033e6:	020080e7          	jalr	32(ra) # 80004402 <log_write>
        brelse(bp);
    800033ea:	854a                	mv	a0,s2
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	d94080e7          	jalr	-620(ra) # 80003180 <brelse>
  bp = bread(dev, bno);
    800033f4:	85a6                	mv	a1,s1
    800033f6:	855e                	mv	a0,s7
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	c58080e7          	jalr	-936(ra) # 80003050 <bread>
    80003400:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003402:	40000613          	li	a2,1024
    80003406:	4581                	li	a1,0
    80003408:	05850513          	addi	a0,a0,88
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	8b2080e7          	jalr	-1870(ra) # 80000cbe <memset>
  log_write(bp);
    80003414:	854a                	mv	a0,s2
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	fec080e7          	jalr	-20(ra) # 80004402 <log_write>
  brelse(bp);
    8000341e:	854a                	mv	a0,s2
    80003420:	00000097          	auipc	ra,0x0
    80003424:	d60080e7          	jalr	-672(ra) # 80003180 <brelse>
}
    80003428:	8526                	mv	a0,s1
    8000342a:	60e6                	ld	ra,88(sp)
    8000342c:	6446                	ld	s0,80(sp)
    8000342e:	64a6                	ld	s1,72(sp)
    80003430:	6906                	ld	s2,64(sp)
    80003432:	79e2                	ld	s3,56(sp)
    80003434:	7a42                	ld	s4,48(sp)
    80003436:	7aa2                	ld	s5,40(sp)
    80003438:	7b02                	ld	s6,32(sp)
    8000343a:	6be2                	ld	s7,24(sp)
    8000343c:	6c42                	ld	s8,16(sp)
    8000343e:	6ca2                	ld	s9,8(sp)
    80003440:	6125                	addi	sp,sp,96
    80003442:	8082                	ret

0000000080003444 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	e84a                	sd	s2,16(sp)
    8000344e:	e44e                	sd	s3,8(sp)
    80003450:	e052                	sd	s4,0(sp)
    80003452:	1800                	addi	s0,sp,48
    80003454:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003456:	47ad                	li	a5,11
    80003458:	04b7fe63          	bgeu	a5,a1,800034b4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000345c:	ff45849b          	addiw	s1,a1,-12
    80003460:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003464:	0ff00793          	li	a5,255
    80003468:	0ae7e463          	bltu	a5,a4,80003510 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000346c:	08052583          	lw	a1,128(a0)
    80003470:	c5b5                	beqz	a1,800034dc <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003472:	00092503          	lw	a0,0(s2)
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	bda080e7          	jalr	-1062(ra) # 80003050 <bread>
    8000347e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003480:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003484:	02049713          	slli	a4,s1,0x20
    80003488:	01e75593          	srli	a1,a4,0x1e
    8000348c:	00b784b3          	add	s1,a5,a1
    80003490:	0004a983          	lw	s3,0(s1)
    80003494:	04098e63          	beqz	s3,800034f0 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003498:	8552                	mv	a0,s4
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	ce6080e7          	jalr	-794(ra) # 80003180 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034a2:	854e                	mv	a0,s3
    800034a4:	70a2                	ld	ra,40(sp)
    800034a6:	7402                	ld	s0,32(sp)
    800034a8:	64e2                	ld	s1,24(sp)
    800034aa:	6942                	ld	s2,16(sp)
    800034ac:	69a2                	ld	s3,8(sp)
    800034ae:	6a02                	ld	s4,0(sp)
    800034b0:	6145                	addi	sp,sp,48
    800034b2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034b4:	02059793          	slli	a5,a1,0x20
    800034b8:	01e7d593          	srli	a1,a5,0x1e
    800034bc:	00b504b3          	add	s1,a0,a1
    800034c0:	0504a983          	lw	s3,80(s1)
    800034c4:	fc099fe3          	bnez	s3,800034a2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034c8:	4108                	lw	a0,0(a0)
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	e48080e7          	jalr	-440(ra) # 80003312 <balloc>
    800034d2:	0005099b          	sext.w	s3,a0
    800034d6:	0534a823          	sw	s3,80(s1)
    800034da:	b7e1                	j	800034a2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034dc:	4108                	lw	a0,0(a0)
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	e34080e7          	jalr	-460(ra) # 80003312 <balloc>
    800034e6:	0005059b          	sext.w	a1,a0
    800034ea:	08b92023          	sw	a1,128(s2)
    800034ee:	b751                	j	80003472 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034f0:	00092503          	lw	a0,0(s2)
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	e1e080e7          	jalr	-482(ra) # 80003312 <balloc>
    800034fc:	0005099b          	sext.w	s3,a0
    80003500:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003504:	8552                	mv	a0,s4
    80003506:	00001097          	auipc	ra,0x1
    8000350a:	efc080e7          	jalr	-260(ra) # 80004402 <log_write>
    8000350e:	b769                	j	80003498 <bmap+0x54>
  panic("bmap: out of range");
    80003510:	00005517          	auipc	a0,0x5
    80003514:	28850513          	addi	a0,a0,648 # 80008798 <syscalls_str+0x120>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	012080e7          	jalr	18(ra) # 8000052a <panic>

0000000080003520 <iget>:
{
    80003520:	7179                	addi	sp,sp,-48
    80003522:	f406                	sd	ra,40(sp)
    80003524:	f022                	sd	s0,32(sp)
    80003526:	ec26                	sd	s1,24(sp)
    80003528:	e84a                	sd	s2,16(sp)
    8000352a:	e44e                	sd	s3,8(sp)
    8000352c:	e052                	sd	s4,0(sp)
    8000352e:	1800                	addi	s0,sp,48
    80003530:	89aa                	mv	s3,a0
    80003532:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003534:	0001d517          	auipc	a0,0x1d
    80003538:	89450513          	addi	a0,a0,-1900 # 8001fdc8 <itable>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	686080e7          	jalr	1670(ra) # 80000bc2 <acquire>
  empty = 0;
    80003544:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003546:	0001d497          	auipc	s1,0x1d
    8000354a:	89a48493          	addi	s1,s1,-1894 # 8001fde0 <itable+0x18>
    8000354e:	0001e697          	auipc	a3,0x1e
    80003552:	32268693          	addi	a3,a3,802 # 80021870 <log>
    80003556:	a039                	j	80003564 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003558:	02090b63          	beqz	s2,8000358e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000355c:	08848493          	addi	s1,s1,136
    80003560:	02d48a63          	beq	s1,a3,80003594 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003564:	449c                	lw	a5,8(s1)
    80003566:	fef059e3          	blez	a5,80003558 <iget+0x38>
    8000356a:	4098                	lw	a4,0(s1)
    8000356c:	ff3716e3          	bne	a4,s3,80003558 <iget+0x38>
    80003570:	40d8                	lw	a4,4(s1)
    80003572:	ff4713e3          	bne	a4,s4,80003558 <iget+0x38>
      ip->ref++;
    80003576:	2785                	addiw	a5,a5,1
    80003578:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000357a:	0001d517          	auipc	a0,0x1d
    8000357e:	84e50513          	addi	a0,a0,-1970 # 8001fdc8 <itable>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	6f4080e7          	jalr	1780(ra) # 80000c76 <release>
      return ip;
    8000358a:	8926                	mv	s2,s1
    8000358c:	a03d                	j	800035ba <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000358e:	f7f9                	bnez	a5,8000355c <iget+0x3c>
    80003590:	8926                	mv	s2,s1
    80003592:	b7e9                	j	8000355c <iget+0x3c>
  if(empty == 0)
    80003594:	02090c63          	beqz	s2,800035cc <iget+0xac>
  ip->dev = dev;
    80003598:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000359c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035a0:	4785                	li	a5,1
    800035a2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035a6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035aa:	0001d517          	auipc	a0,0x1d
    800035ae:	81e50513          	addi	a0,a0,-2018 # 8001fdc8 <itable>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	6c4080e7          	jalr	1732(ra) # 80000c76 <release>
}
    800035ba:	854a                	mv	a0,s2
    800035bc:	70a2                	ld	ra,40(sp)
    800035be:	7402                	ld	s0,32(sp)
    800035c0:	64e2                	ld	s1,24(sp)
    800035c2:	6942                	ld	s2,16(sp)
    800035c4:	69a2                	ld	s3,8(sp)
    800035c6:	6a02                	ld	s4,0(sp)
    800035c8:	6145                	addi	sp,sp,48
    800035ca:	8082                	ret
    panic("iget: no inodes");
    800035cc:	00005517          	auipc	a0,0x5
    800035d0:	1e450513          	addi	a0,a0,484 # 800087b0 <syscalls_str+0x138>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	f56080e7          	jalr	-170(ra) # 8000052a <panic>

00000000800035dc <fsinit>:
fsinit(int dev) {
    800035dc:	7179                	addi	sp,sp,-48
    800035de:	f406                	sd	ra,40(sp)
    800035e0:	f022                	sd	s0,32(sp)
    800035e2:	ec26                	sd	s1,24(sp)
    800035e4:	e84a                	sd	s2,16(sp)
    800035e6:	e44e                	sd	s3,8(sp)
    800035e8:	1800                	addi	s0,sp,48
    800035ea:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ec:	4585                	li	a1,1
    800035ee:	00000097          	auipc	ra,0x0
    800035f2:	a62080e7          	jalr	-1438(ra) # 80003050 <bread>
    800035f6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035f8:	0001c997          	auipc	s3,0x1c
    800035fc:	7b098993          	addi	s3,s3,1968 # 8001fda8 <sb>
    80003600:	02000613          	li	a2,32
    80003604:	05850593          	addi	a1,a0,88
    80003608:	854e                	mv	a0,s3
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	710080e7          	jalr	1808(ra) # 80000d1a <memmove>
  brelse(bp);
    80003612:	8526                	mv	a0,s1
    80003614:	00000097          	auipc	ra,0x0
    80003618:	b6c080e7          	jalr	-1172(ra) # 80003180 <brelse>
  if(sb.magic != FSMAGIC)
    8000361c:	0009a703          	lw	a4,0(s3)
    80003620:	102037b7          	lui	a5,0x10203
    80003624:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003628:	02f71263          	bne	a4,a5,8000364c <fsinit+0x70>
  initlog(dev, &sb);
    8000362c:	0001c597          	auipc	a1,0x1c
    80003630:	77c58593          	addi	a1,a1,1916 # 8001fda8 <sb>
    80003634:	854a                	mv	a0,s2
    80003636:	00001097          	auipc	ra,0x1
    8000363a:	b4e080e7          	jalr	-1202(ra) # 80004184 <initlog>
}
    8000363e:	70a2                	ld	ra,40(sp)
    80003640:	7402                	ld	s0,32(sp)
    80003642:	64e2                	ld	s1,24(sp)
    80003644:	6942                	ld	s2,16(sp)
    80003646:	69a2                	ld	s3,8(sp)
    80003648:	6145                	addi	sp,sp,48
    8000364a:	8082                	ret
    panic("invalid file system");
    8000364c:	00005517          	auipc	a0,0x5
    80003650:	17450513          	addi	a0,a0,372 # 800087c0 <syscalls_str+0x148>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	ed6080e7          	jalr	-298(ra) # 8000052a <panic>

000000008000365c <iinit>:
{
    8000365c:	7179                	addi	sp,sp,-48
    8000365e:	f406                	sd	ra,40(sp)
    80003660:	f022                	sd	s0,32(sp)
    80003662:	ec26                	sd	s1,24(sp)
    80003664:	e84a                	sd	s2,16(sp)
    80003666:	e44e                	sd	s3,8(sp)
    80003668:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000366a:	00005597          	auipc	a1,0x5
    8000366e:	16e58593          	addi	a1,a1,366 # 800087d8 <syscalls_str+0x160>
    80003672:	0001c517          	auipc	a0,0x1c
    80003676:	75650513          	addi	a0,a0,1878 # 8001fdc8 <itable>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	4b8080e7          	jalr	1208(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003682:	0001c497          	auipc	s1,0x1c
    80003686:	76e48493          	addi	s1,s1,1902 # 8001fdf0 <itable+0x28>
    8000368a:	0001e997          	auipc	s3,0x1e
    8000368e:	1f698993          	addi	s3,s3,502 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003692:	00005917          	auipc	s2,0x5
    80003696:	14e90913          	addi	s2,s2,334 # 800087e0 <syscalls_str+0x168>
    8000369a:	85ca                	mv	a1,s2
    8000369c:	8526                	mv	a0,s1
    8000369e:	00001097          	auipc	ra,0x1
    800036a2:	e4a080e7          	jalr	-438(ra) # 800044e8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036a6:	08848493          	addi	s1,s1,136
    800036aa:	ff3498e3          	bne	s1,s3,8000369a <iinit+0x3e>
}
    800036ae:	70a2                	ld	ra,40(sp)
    800036b0:	7402                	ld	s0,32(sp)
    800036b2:	64e2                	ld	s1,24(sp)
    800036b4:	6942                	ld	s2,16(sp)
    800036b6:	69a2                	ld	s3,8(sp)
    800036b8:	6145                	addi	sp,sp,48
    800036ba:	8082                	ret

00000000800036bc <ialloc>:
{
    800036bc:	715d                	addi	sp,sp,-80
    800036be:	e486                	sd	ra,72(sp)
    800036c0:	e0a2                	sd	s0,64(sp)
    800036c2:	fc26                	sd	s1,56(sp)
    800036c4:	f84a                	sd	s2,48(sp)
    800036c6:	f44e                	sd	s3,40(sp)
    800036c8:	f052                	sd	s4,32(sp)
    800036ca:	ec56                	sd	s5,24(sp)
    800036cc:	e85a                	sd	s6,16(sp)
    800036ce:	e45e                	sd	s7,8(sp)
    800036d0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036d2:	0001c717          	auipc	a4,0x1c
    800036d6:	6e272703          	lw	a4,1762(a4) # 8001fdb4 <sb+0xc>
    800036da:	4785                	li	a5,1
    800036dc:	04e7fa63          	bgeu	a5,a4,80003730 <ialloc+0x74>
    800036e0:	8aaa                	mv	s5,a0
    800036e2:	8bae                	mv	s7,a1
    800036e4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036e6:	0001ca17          	auipc	s4,0x1c
    800036ea:	6c2a0a13          	addi	s4,s4,1730 # 8001fda8 <sb>
    800036ee:	00048b1b          	sext.w	s6,s1
    800036f2:	0044d793          	srli	a5,s1,0x4
    800036f6:	018a2583          	lw	a1,24(s4)
    800036fa:	9dbd                	addw	a1,a1,a5
    800036fc:	8556                	mv	a0,s5
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	952080e7          	jalr	-1710(ra) # 80003050 <bread>
    80003706:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003708:	05850993          	addi	s3,a0,88
    8000370c:	00f4f793          	andi	a5,s1,15
    80003710:	079a                	slli	a5,a5,0x6
    80003712:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003714:	00099783          	lh	a5,0(s3)
    80003718:	c785                	beqz	a5,80003740 <ialloc+0x84>
    brelse(bp);
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	a66080e7          	jalr	-1434(ra) # 80003180 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003722:	0485                	addi	s1,s1,1
    80003724:	00ca2703          	lw	a4,12(s4)
    80003728:	0004879b          	sext.w	a5,s1
    8000372c:	fce7e1e3          	bltu	a5,a4,800036ee <ialloc+0x32>
  panic("ialloc: no inodes");
    80003730:	00005517          	auipc	a0,0x5
    80003734:	0b850513          	addi	a0,a0,184 # 800087e8 <syscalls_str+0x170>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	df2080e7          	jalr	-526(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003740:	04000613          	li	a2,64
    80003744:	4581                	li	a1,0
    80003746:	854e                	mv	a0,s3
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	576080e7          	jalr	1398(ra) # 80000cbe <memset>
      dip->type = type;
    80003750:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003754:	854a                	mv	a0,s2
    80003756:	00001097          	auipc	ra,0x1
    8000375a:	cac080e7          	jalr	-852(ra) # 80004402 <log_write>
      brelse(bp);
    8000375e:	854a                	mv	a0,s2
    80003760:	00000097          	auipc	ra,0x0
    80003764:	a20080e7          	jalr	-1504(ra) # 80003180 <brelse>
      return iget(dev, inum);
    80003768:	85da                	mv	a1,s6
    8000376a:	8556                	mv	a0,s5
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	db4080e7          	jalr	-588(ra) # 80003520 <iget>
}
    80003774:	60a6                	ld	ra,72(sp)
    80003776:	6406                	ld	s0,64(sp)
    80003778:	74e2                	ld	s1,56(sp)
    8000377a:	7942                	ld	s2,48(sp)
    8000377c:	79a2                	ld	s3,40(sp)
    8000377e:	7a02                	ld	s4,32(sp)
    80003780:	6ae2                	ld	s5,24(sp)
    80003782:	6b42                	ld	s6,16(sp)
    80003784:	6ba2                	ld	s7,8(sp)
    80003786:	6161                	addi	sp,sp,80
    80003788:	8082                	ret

000000008000378a <iupdate>:
{
    8000378a:	1101                	addi	sp,sp,-32
    8000378c:	ec06                	sd	ra,24(sp)
    8000378e:	e822                	sd	s0,16(sp)
    80003790:	e426                	sd	s1,8(sp)
    80003792:	e04a                	sd	s2,0(sp)
    80003794:	1000                	addi	s0,sp,32
    80003796:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003798:	415c                	lw	a5,4(a0)
    8000379a:	0047d79b          	srliw	a5,a5,0x4
    8000379e:	0001c597          	auipc	a1,0x1c
    800037a2:	6225a583          	lw	a1,1570(a1) # 8001fdc0 <sb+0x18>
    800037a6:	9dbd                	addw	a1,a1,a5
    800037a8:	4108                	lw	a0,0(a0)
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	8a6080e7          	jalr	-1882(ra) # 80003050 <bread>
    800037b2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b4:	05850793          	addi	a5,a0,88
    800037b8:	40c8                	lw	a0,4(s1)
    800037ba:	893d                	andi	a0,a0,15
    800037bc:	051a                	slli	a0,a0,0x6
    800037be:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037c0:	04449703          	lh	a4,68(s1)
    800037c4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037c8:	04649703          	lh	a4,70(s1)
    800037cc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037d0:	04849703          	lh	a4,72(s1)
    800037d4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037d8:	04a49703          	lh	a4,74(s1)
    800037dc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037e0:	44f8                	lw	a4,76(s1)
    800037e2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037e4:	03400613          	li	a2,52
    800037e8:	05048593          	addi	a1,s1,80
    800037ec:	0531                	addi	a0,a0,12
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	52c080e7          	jalr	1324(ra) # 80000d1a <memmove>
  log_write(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	c0a080e7          	jalr	-1014(ra) # 80004402 <log_write>
  brelse(bp);
    80003800:	854a                	mv	a0,s2
    80003802:	00000097          	auipc	ra,0x0
    80003806:	97e080e7          	jalr	-1666(ra) # 80003180 <brelse>
}
    8000380a:	60e2                	ld	ra,24(sp)
    8000380c:	6442                	ld	s0,16(sp)
    8000380e:	64a2                	ld	s1,8(sp)
    80003810:	6902                	ld	s2,0(sp)
    80003812:	6105                	addi	sp,sp,32
    80003814:	8082                	ret

0000000080003816 <idup>:
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003822:	0001c517          	auipc	a0,0x1c
    80003826:	5a650513          	addi	a0,a0,1446 # 8001fdc8 <itable>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	398080e7          	jalr	920(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003832:	449c                	lw	a5,8(s1)
    80003834:	2785                	addiw	a5,a5,1
    80003836:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003838:	0001c517          	auipc	a0,0x1c
    8000383c:	59050513          	addi	a0,a0,1424 # 8001fdc8 <itable>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	436080e7          	jalr	1078(ra) # 80000c76 <release>
}
    80003848:	8526                	mv	a0,s1
    8000384a:	60e2                	ld	ra,24(sp)
    8000384c:	6442                	ld	s0,16(sp)
    8000384e:	64a2                	ld	s1,8(sp)
    80003850:	6105                	addi	sp,sp,32
    80003852:	8082                	ret

0000000080003854 <ilock>:
{
    80003854:	1101                	addi	sp,sp,-32
    80003856:	ec06                	sd	ra,24(sp)
    80003858:	e822                	sd	s0,16(sp)
    8000385a:	e426                	sd	s1,8(sp)
    8000385c:	e04a                	sd	s2,0(sp)
    8000385e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003860:	c115                	beqz	a0,80003884 <ilock+0x30>
    80003862:	84aa                	mv	s1,a0
    80003864:	451c                	lw	a5,8(a0)
    80003866:	00f05f63          	blez	a5,80003884 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000386a:	0541                	addi	a0,a0,16
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	cb6080e7          	jalr	-842(ra) # 80004522 <acquiresleep>
  if(ip->valid == 0){
    80003874:	40bc                	lw	a5,64(s1)
    80003876:	cf99                	beqz	a5,80003894 <ilock+0x40>
}
    80003878:	60e2                	ld	ra,24(sp)
    8000387a:	6442                	ld	s0,16(sp)
    8000387c:	64a2                	ld	s1,8(sp)
    8000387e:	6902                	ld	s2,0(sp)
    80003880:	6105                	addi	sp,sp,32
    80003882:	8082                	ret
    panic("ilock");
    80003884:	00005517          	auipc	a0,0x5
    80003888:	f7c50513          	addi	a0,a0,-132 # 80008800 <syscalls_str+0x188>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	c9e080e7          	jalr	-866(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003894:	40dc                	lw	a5,4(s1)
    80003896:	0047d79b          	srliw	a5,a5,0x4
    8000389a:	0001c597          	auipc	a1,0x1c
    8000389e:	5265a583          	lw	a1,1318(a1) # 8001fdc0 <sb+0x18>
    800038a2:	9dbd                	addw	a1,a1,a5
    800038a4:	4088                	lw	a0,0(s1)
    800038a6:	fffff097          	auipc	ra,0xfffff
    800038aa:	7aa080e7          	jalr	1962(ra) # 80003050 <bread>
    800038ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038b0:	05850593          	addi	a1,a0,88
    800038b4:	40dc                	lw	a5,4(s1)
    800038b6:	8bbd                	andi	a5,a5,15
    800038b8:	079a                	slli	a5,a5,0x6
    800038ba:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038bc:	00059783          	lh	a5,0(a1)
    800038c0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038c4:	00259783          	lh	a5,2(a1)
    800038c8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038cc:	00459783          	lh	a5,4(a1)
    800038d0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038d4:	00659783          	lh	a5,6(a1)
    800038d8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038dc:	459c                	lw	a5,8(a1)
    800038de:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038e0:	03400613          	li	a2,52
    800038e4:	05b1                	addi	a1,a1,12
    800038e6:	05048513          	addi	a0,s1,80
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	430080e7          	jalr	1072(ra) # 80000d1a <memmove>
    brelse(bp);
    800038f2:	854a                	mv	a0,s2
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	88c080e7          	jalr	-1908(ra) # 80003180 <brelse>
    ip->valid = 1;
    800038fc:	4785                	li	a5,1
    800038fe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003900:	04449783          	lh	a5,68(s1)
    80003904:	fbb5                	bnez	a5,80003878 <ilock+0x24>
      panic("ilock: no type");
    80003906:	00005517          	auipc	a0,0x5
    8000390a:	f0250513          	addi	a0,a0,-254 # 80008808 <syscalls_str+0x190>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	c1c080e7          	jalr	-996(ra) # 8000052a <panic>

0000000080003916 <iunlock>:
{
    80003916:	1101                	addi	sp,sp,-32
    80003918:	ec06                	sd	ra,24(sp)
    8000391a:	e822                	sd	s0,16(sp)
    8000391c:	e426                	sd	s1,8(sp)
    8000391e:	e04a                	sd	s2,0(sp)
    80003920:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003922:	c905                	beqz	a0,80003952 <iunlock+0x3c>
    80003924:	84aa                	mv	s1,a0
    80003926:	01050913          	addi	s2,a0,16
    8000392a:	854a                	mv	a0,s2
    8000392c:	00001097          	auipc	ra,0x1
    80003930:	c90080e7          	jalr	-880(ra) # 800045bc <holdingsleep>
    80003934:	cd19                	beqz	a0,80003952 <iunlock+0x3c>
    80003936:	449c                	lw	a5,8(s1)
    80003938:	00f05d63          	blez	a5,80003952 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000393c:	854a                	mv	a0,s2
    8000393e:	00001097          	auipc	ra,0x1
    80003942:	c3a080e7          	jalr	-966(ra) # 80004578 <releasesleep>
}
    80003946:	60e2                	ld	ra,24(sp)
    80003948:	6442                	ld	s0,16(sp)
    8000394a:	64a2                	ld	s1,8(sp)
    8000394c:	6902                	ld	s2,0(sp)
    8000394e:	6105                	addi	sp,sp,32
    80003950:	8082                	ret
    panic("iunlock");
    80003952:	00005517          	auipc	a0,0x5
    80003956:	ec650513          	addi	a0,a0,-314 # 80008818 <syscalls_str+0x1a0>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	bd0080e7          	jalr	-1072(ra) # 8000052a <panic>

0000000080003962 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003962:	7179                	addi	sp,sp,-48
    80003964:	f406                	sd	ra,40(sp)
    80003966:	f022                	sd	s0,32(sp)
    80003968:	ec26                	sd	s1,24(sp)
    8000396a:	e84a                	sd	s2,16(sp)
    8000396c:	e44e                	sd	s3,8(sp)
    8000396e:	e052                	sd	s4,0(sp)
    80003970:	1800                	addi	s0,sp,48
    80003972:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003974:	05050493          	addi	s1,a0,80
    80003978:	08050913          	addi	s2,a0,128
    8000397c:	a021                	j	80003984 <itrunc+0x22>
    8000397e:	0491                	addi	s1,s1,4
    80003980:	01248d63          	beq	s1,s2,8000399a <itrunc+0x38>
    if(ip->addrs[i]){
    80003984:	408c                	lw	a1,0(s1)
    80003986:	dde5                	beqz	a1,8000397e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003988:	0009a503          	lw	a0,0(s3)
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	90a080e7          	jalr	-1782(ra) # 80003296 <bfree>
      ip->addrs[i] = 0;
    80003994:	0004a023          	sw	zero,0(s1)
    80003998:	b7dd                	j	8000397e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000399a:	0809a583          	lw	a1,128(s3)
    8000399e:	e185                	bnez	a1,800039be <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039a0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039a4:	854e                	mv	a0,s3
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	de4080e7          	jalr	-540(ra) # 8000378a <iupdate>
}
    800039ae:	70a2                	ld	ra,40(sp)
    800039b0:	7402                	ld	s0,32(sp)
    800039b2:	64e2                	ld	s1,24(sp)
    800039b4:	6942                	ld	s2,16(sp)
    800039b6:	69a2                	ld	s3,8(sp)
    800039b8:	6a02                	ld	s4,0(sp)
    800039ba:	6145                	addi	sp,sp,48
    800039bc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039be:	0009a503          	lw	a0,0(s3)
    800039c2:	fffff097          	auipc	ra,0xfffff
    800039c6:	68e080e7          	jalr	1678(ra) # 80003050 <bread>
    800039ca:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039cc:	05850493          	addi	s1,a0,88
    800039d0:	45850913          	addi	s2,a0,1112
    800039d4:	a021                	j	800039dc <itrunc+0x7a>
    800039d6:	0491                	addi	s1,s1,4
    800039d8:	01248b63          	beq	s1,s2,800039ee <itrunc+0x8c>
      if(a[j])
    800039dc:	408c                	lw	a1,0(s1)
    800039de:	dde5                	beqz	a1,800039d6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039e0:	0009a503          	lw	a0,0(s3)
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	8b2080e7          	jalr	-1870(ra) # 80003296 <bfree>
    800039ec:	b7ed                	j	800039d6 <itrunc+0x74>
    brelse(bp);
    800039ee:	8552                	mv	a0,s4
    800039f0:	fffff097          	auipc	ra,0xfffff
    800039f4:	790080e7          	jalr	1936(ra) # 80003180 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039f8:	0809a583          	lw	a1,128(s3)
    800039fc:	0009a503          	lw	a0,0(s3)
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	896080e7          	jalr	-1898(ra) # 80003296 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a08:	0809a023          	sw	zero,128(s3)
    80003a0c:	bf51                	j	800039a0 <itrunc+0x3e>

0000000080003a0e <iput>:
{
    80003a0e:	1101                	addi	sp,sp,-32
    80003a10:	ec06                	sd	ra,24(sp)
    80003a12:	e822                	sd	s0,16(sp)
    80003a14:	e426                	sd	s1,8(sp)
    80003a16:	e04a                	sd	s2,0(sp)
    80003a18:	1000                	addi	s0,sp,32
    80003a1a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a1c:	0001c517          	auipc	a0,0x1c
    80003a20:	3ac50513          	addi	a0,a0,940 # 8001fdc8 <itable>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	19e080e7          	jalr	414(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a2c:	4498                	lw	a4,8(s1)
    80003a2e:	4785                	li	a5,1
    80003a30:	02f70363          	beq	a4,a5,80003a56 <iput+0x48>
  ip->ref--;
    80003a34:	449c                	lw	a5,8(s1)
    80003a36:	37fd                	addiw	a5,a5,-1
    80003a38:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a3a:	0001c517          	auipc	a0,0x1c
    80003a3e:	38e50513          	addi	a0,a0,910 # 8001fdc8 <itable>
    80003a42:	ffffd097          	auipc	ra,0xffffd
    80003a46:	234080e7          	jalr	564(ra) # 80000c76 <release>
}
    80003a4a:	60e2                	ld	ra,24(sp)
    80003a4c:	6442                	ld	s0,16(sp)
    80003a4e:	64a2                	ld	s1,8(sp)
    80003a50:	6902                	ld	s2,0(sp)
    80003a52:	6105                	addi	sp,sp,32
    80003a54:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a56:	40bc                	lw	a5,64(s1)
    80003a58:	dff1                	beqz	a5,80003a34 <iput+0x26>
    80003a5a:	04a49783          	lh	a5,74(s1)
    80003a5e:	fbf9                	bnez	a5,80003a34 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a60:	01048913          	addi	s2,s1,16
    80003a64:	854a                	mv	a0,s2
    80003a66:	00001097          	auipc	ra,0x1
    80003a6a:	abc080e7          	jalr	-1348(ra) # 80004522 <acquiresleep>
    release(&itable.lock);
    80003a6e:	0001c517          	auipc	a0,0x1c
    80003a72:	35a50513          	addi	a0,a0,858 # 8001fdc8 <itable>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	200080e7          	jalr	512(ra) # 80000c76 <release>
    itrunc(ip);
    80003a7e:	8526                	mv	a0,s1
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	ee2080e7          	jalr	-286(ra) # 80003962 <itrunc>
    ip->type = 0;
    80003a88:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a8c:	8526                	mv	a0,s1
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	cfc080e7          	jalr	-772(ra) # 8000378a <iupdate>
    ip->valid = 0;
    80003a96:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a9a:	854a                	mv	a0,s2
    80003a9c:	00001097          	auipc	ra,0x1
    80003aa0:	adc080e7          	jalr	-1316(ra) # 80004578 <releasesleep>
    acquire(&itable.lock);
    80003aa4:	0001c517          	auipc	a0,0x1c
    80003aa8:	32450513          	addi	a0,a0,804 # 8001fdc8 <itable>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	116080e7          	jalr	278(ra) # 80000bc2 <acquire>
    80003ab4:	b741                	j	80003a34 <iput+0x26>

0000000080003ab6 <iunlockput>:
{
    80003ab6:	1101                	addi	sp,sp,-32
    80003ab8:	ec06                	sd	ra,24(sp)
    80003aba:	e822                	sd	s0,16(sp)
    80003abc:	e426                	sd	s1,8(sp)
    80003abe:	1000                	addi	s0,sp,32
    80003ac0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	e54080e7          	jalr	-428(ra) # 80003916 <iunlock>
  iput(ip);
    80003aca:	8526                	mv	a0,s1
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	f42080e7          	jalr	-190(ra) # 80003a0e <iput>
}
    80003ad4:	60e2                	ld	ra,24(sp)
    80003ad6:	6442                	ld	s0,16(sp)
    80003ad8:	64a2                	ld	s1,8(sp)
    80003ada:	6105                	addi	sp,sp,32
    80003adc:	8082                	ret

0000000080003ade <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ade:	1141                	addi	sp,sp,-16
    80003ae0:	e422                	sd	s0,8(sp)
    80003ae2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ae4:	411c                	lw	a5,0(a0)
    80003ae6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ae8:	415c                	lw	a5,4(a0)
    80003aea:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aec:	04451783          	lh	a5,68(a0)
    80003af0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003af4:	04a51783          	lh	a5,74(a0)
    80003af8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003afc:	04c56783          	lwu	a5,76(a0)
    80003b00:	e99c                	sd	a5,16(a1)
}
    80003b02:	6422                	ld	s0,8(sp)
    80003b04:	0141                	addi	sp,sp,16
    80003b06:	8082                	ret

0000000080003b08 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b08:	457c                	lw	a5,76(a0)
    80003b0a:	0ed7e963          	bltu	a5,a3,80003bfc <readi+0xf4>
{
    80003b0e:	7159                	addi	sp,sp,-112
    80003b10:	f486                	sd	ra,104(sp)
    80003b12:	f0a2                	sd	s0,96(sp)
    80003b14:	eca6                	sd	s1,88(sp)
    80003b16:	e8ca                	sd	s2,80(sp)
    80003b18:	e4ce                	sd	s3,72(sp)
    80003b1a:	e0d2                	sd	s4,64(sp)
    80003b1c:	fc56                	sd	s5,56(sp)
    80003b1e:	f85a                	sd	s6,48(sp)
    80003b20:	f45e                	sd	s7,40(sp)
    80003b22:	f062                	sd	s8,32(sp)
    80003b24:	ec66                	sd	s9,24(sp)
    80003b26:	e86a                	sd	s10,16(sp)
    80003b28:	e46e                	sd	s11,8(sp)
    80003b2a:	1880                	addi	s0,sp,112
    80003b2c:	8baa                	mv	s7,a0
    80003b2e:	8c2e                	mv	s8,a1
    80003b30:	8ab2                	mv	s5,a2
    80003b32:	84b6                	mv	s1,a3
    80003b34:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b36:	9f35                	addw	a4,a4,a3
    return 0;
    80003b38:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b3a:	0ad76063          	bltu	a4,a3,80003bda <readi+0xd2>
  if(off + n > ip->size)
    80003b3e:	00e7f463          	bgeu	a5,a4,80003b46 <readi+0x3e>
    n = ip->size - off;
    80003b42:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b46:	0a0b0963          	beqz	s6,80003bf8 <readi+0xf0>
    80003b4a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b50:	5cfd                	li	s9,-1
    80003b52:	a82d                	j	80003b8c <readi+0x84>
    80003b54:	020a1d93          	slli	s11,s4,0x20
    80003b58:	020ddd93          	srli	s11,s11,0x20
    80003b5c:	05890793          	addi	a5,s2,88
    80003b60:	86ee                	mv	a3,s11
    80003b62:	963e                	add	a2,a2,a5
    80003b64:	85d6                	mv	a1,s5
    80003b66:	8562                	mv	a0,s8
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	9b0080e7          	jalr	-1616(ra) # 80002518 <either_copyout>
    80003b70:	05950d63          	beq	a0,s9,80003bca <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b74:	854a                	mv	a0,s2
    80003b76:	fffff097          	auipc	ra,0xfffff
    80003b7a:	60a080e7          	jalr	1546(ra) # 80003180 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b7e:	013a09bb          	addw	s3,s4,s3
    80003b82:	009a04bb          	addw	s1,s4,s1
    80003b86:	9aee                	add	s5,s5,s11
    80003b88:	0569f763          	bgeu	s3,s6,80003bd6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b8c:	000ba903          	lw	s2,0(s7)
    80003b90:	00a4d59b          	srliw	a1,s1,0xa
    80003b94:	855e                	mv	a0,s7
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	8ae080e7          	jalr	-1874(ra) # 80003444 <bmap>
    80003b9e:	0005059b          	sext.w	a1,a0
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	fffff097          	auipc	ra,0xfffff
    80003ba8:	4ac080e7          	jalr	1196(ra) # 80003050 <bread>
    80003bac:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bae:	3ff4f613          	andi	a2,s1,1023
    80003bb2:	40cd07bb          	subw	a5,s10,a2
    80003bb6:	413b073b          	subw	a4,s6,s3
    80003bba:	8a3e                	mv	s4,a5
    80003bbc:	2781                	sext.w	a5,a5
    80003bbe:	0007069b          	sext.w	a3,a4
    80003bc2:	f8f6f9e3          	bgeu	a3,a5,80003b54 <readi+0x4c>
    80003bc6:	8a3a                	mv	s4,a4
    80003bc8:	b771                	j	80003b54 <readi+0x4c>
      brelse(bp);
    80003bca:	854a                	mv	a0,s2
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	5b4080e7          	jalr	1460(ra) # 80003180 <brelse>
      tot = -1;
    80003bd4:	59fd                	li	s3,-1
  }
  return tot;
    80003bd6:	0009851b          	sext.w	a0,s3
}
    80003bda:	70a6                	ld	ra,104(sp)
    80003bdc:	7406                	ld	s0,96(sp)
    80003bde:	64e6                	ld	s1,88(sp)
    80003be0:	6946                	ld	s2,80(sp)
    80003be2:	69a6                	ld	s3,72(sp)
    80003be4:	6a06                	ld	s4,64(sp)
    80003be6:	7ae2                	ld	s5,56(sp)
    80003be8:	7b42                	ld	s6,48(sp)
    80003bea:	7ba2                	ld	s7,40(sp)
    80003bec:	7c02                	ld	s8,32(sp)
    80003bee:	6ce2                	ld	s9,24(sp)
    80003bf0:	6d42                	ld	s10,16(sp)
    80003bf2:	6da2                	ld	s11,8(sp)
    80003bf4:	6165                	addi	sp,sp,112
    80003bf6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf8:	89da                	mv	s3,s6
    80003bfa:	bff1                	j	80003bd6 <readi+0xce>
    return 0;
    80003bfc:	4501                	li	a0,0
}
    80003bfe:	8082                	ret

0000000080003c00 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c00:	457c                	lw	a5,76(a0)
    80003c02:	10d7e863          	bltu	a5,a3,80003d12 <writei+0x112>
{
    80003c06:	7159                	addi	sp,sp,-112
    80003c08:	f486                	sd	ra,104(sp)
    80003c0a:	f0a2                	sd	s0,96(sp)
    80003c0c:	eca6                	sd	s1,88(sp)
    80003c0e:	e8ca                	sd	s2,80(sp)
    80003c10:	e4ce                	sd	s3,72(sp)
    80003c12:	e0d2                	sd	s4,64(sp)
    80003c14:	fc56                	sd	s5,56(sp)
    80003c16:	f85a                	sd	s6,48(sp)
    80003c18:	f45e                	sd	s7,40(sp)
    80003c1a:	f062                	sd	s8,32(sp)
    80003c1c:	ec66                	sd	s9,24(sp)
    80003c1e:	e86a                	sd	s10,16(sp)
    80003c20:	e46e                	sd	s11,8(sp)
    80003c22:	1880                	addi	s0,sp,112
    80003c24:	8b2a                	mv	s6,a0
    80003c26:	8c2e                	mv	s8,a1
    80003c28:	8ab2                	mv	s5,a2
    80003c2a:	8936                	mv	s2,a3
    80003c2c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c2e:	00e687bb          	addw	a5,a3,a4
    80003c32:	0ed7e263          	bltu	a5,a3,80003d16 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c36:	00043737          	lui	a4,0x43
    80003c3a:	0ef76063          	bltu	a4,a5,80003d1a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c3e:	0c0b8863          	beqz	s7,80003d0e <writei+0x10e>
    80003c42:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c44:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c48:	5cfd                	li	s9,-1
    80003c4a:	a091                	j	80003c8e <writei+0x8e>
    80003c4c:	02099d93          	slli	s11,s3,0x20
    80003c50:	020ddd93          	srli	s11,s11,0x20
    80003c54:	05848793          	addi	a5,s1,88
    80003c58:	86ee                	mv	a3,s11
    80003c5a:	8656                	mv	a2,s5
    80003c5c:	85e2                	mv	a1,s8
    80003c5e:	953e                	add	a0,a0,a5
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	90e080e7          	jalr	-1778(ra) # 8000256e <either_copyin>
    80003c68:	07950263          	beq	a0,s9,80003ccc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c6c:	8526                	mv	a0,s1
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	794080e7          	jalr	1940(ra) # 80004402 <log_write>
    brelse(bp);
    80003c76:	8526                	mv	a0,s1
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	508080e7          	jalr	1288(ra) # 80003180 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c80:	01498a3b          	addw	s4,s3,s4
    80003c84:	0129893b          	addw	s2,s3,s2
    80003c88:	9aee                	add	s5,s5,s11
    80003c8a:	057a7663          	bgeu	s4,s7,80003cd6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c8e:	000b2483          	lw	s1,0(s6)
    80003c92:	00a9559b          	srliw	a1,s2,0xa
    80003c96:	855a                	mv	a0,s6
    80003c98:	fffff097          	auipc	ra,0xfffff
    80003c9c:	7ac080e7          	jalr	1964(ra) # 80003444 <bmap>
    80003ca0:	0005059b          	sext.w	a1,a0
    80003ca4:	8526                	mv	a0,s1
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	3aa080e7          	jalr	938(ra) # 80003050 <bread>
    80003cae:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb0:	3ff97513          	andi	a0,s2,1023
    80003cb4:	40ad07bb          	subw	a5,s10,a0
    80003cb8:	414b873b          	subw	a4,s7,s4
    80003cbc:	89be                	mv	s3,a5
    80003cbe:	2781                	sext.w	a5,a5
    80003cc0:	0007069b          	sext.w	a3,a4
    80003cc4:	f8f6f4e3          	bgeu	a3,a5,80003c4c <writei+0x4c>
    80003cc8:	89ba                	mv	s3,a4
    80003cca:	b749                	j	80003c4c <writei+0x4c>
      brelse(bp);
    80003ccc:	8526                	mv	a0,s1
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	4b2080e7          	jalr	1202(ra) # 80003180 <brelse>
  }

  if(off > ip->size)
    80003cd6:	04cb2783          	lw	a5,76(s6)
    80003cda:	0127f463          	bgeu	a5,s2,80003ce2 <writei+0xe2>
    ip->size = off;
    80003cde:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ce2:	855a                	mv	a0,s6
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	aa6080e7          	jalr	-1370(ra) # 8000378a <iupdate>

  return tot;
    80003cec:	000a051b          	sext.w	a0,s4
}
    80003cf0:	70a6                	ld	ra,104(sp)
    80003cf2:	7406                	ld	s0,96(sp)
    80003cf4:	64e6                	ld	s1,88(sp)
    80003cf6:	6946                	ld	s2,80(sp)
    80003cf8:	69a6                	ld	s3,72(sp)
    80003cfa:	6a06                	ld	s4,64(sp)
    80003cfc:	7ae2                	ld	s5,56(sp)
    80003cfe:	7b42                	ld	s6,48(sp)
    80003d00:	7ba2                	ld	s7,40(sp)
    80003d02:	7c02                	ld	s8,32(sp)
    80003d04:	6ce2                	ld	s9,24(sp)
    80003d06:	6d42                	ld	s10,16(sp)
    80003d08:	6da2                	ld	s11,8(sp)
    80003d0a:	6165                	addi	sp,sp,112
    80003d0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d0e:	8a5e                	mv	s4,s7
    80003d10:	bfc9                	j	80003ce2 <writei+0xe2>
    return -1;
    80003d12:	557d                	li	a0,-1
}
    80003d14:	8082                	ret
    return -1;
    80003d16:	557d                	li	a0,-1
    80003d18:	bfe1                	j	80003cf0 <writei+0xf0>
    return -1;
    80003d1a:	557d                	li	a0,-1
    80003d1c:	bfd1                	j	80003cf0 <writei+0xf0>

0000000080003d1e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d1e:	1141                	addi	sp,sp,-16
    80003d20:	e406                	sd	ra,8(sp)
    80003d22:	e022                	sd	s0,0(sp)
    80003d24:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d26:	4639                	li	a2,14
    80003d28:	ffffd097          	auipc	ra,0xffffd
    80003d2c:	06e080e7          	jalr	110(ra) # 80000d96 <strncmp>
}
    80003d30:	60a2                	ld	ra,8(sp)
    80003d32:	6402                	ld	s0,0(sp)
    80003d34:	0141                	addi	sp,sp,16
    80003d36:	8082                	ret

0000000080003d38 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d38:	7139                	addi	sp,sp,-64
    80003d3a:	fc06                	sd	ra,56(sp)
    80003d3c:	f822                	sd	s0,48(sp)
    80003d3e:	f426                	sd	s1,40(sp)
    80003d40:	f04a                	sd	s2,32(sp)
    80003d42:	ec4e                	sd	s3,24(sp)
    80003d44:	e852                	sd	s4,16(sp)
    80003d46:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d48:	04451703          	lh	a4,68(a0)
    80003d4c:	4785                	li	a5,1
    80003d4e:	00f71a63          	bne	a4,a5,80003d62 <dirlookup+0x2a>
    80003d52:	892a                	mv	s2,a0
    80003d54:	89ae                	mv	s3,a1
    80003d56:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d58:	457c                	lw	a5,76(a0)
    80003d5a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d5c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5e:	e79d                	bnez	a5,80003d8c <dirlookup+0x54>
    80003d60:	a8a5                	j	80003dd8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d62:	00005517          	auipc	a0,0x5
    80003d66:	abe50513          	addi	a0,a0,-1346 # 80008820 <syscalls_str+0x1a8>
    80003d6a:	ffffc097          	auipc	ra,0xffffc
    80003d6e:	7c0080e7          	jalr	1984(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003d72:	00005517          	auipc	a0,0x5
    80003d76:	ac650513          	addi	a0,a0,-1338 # 80008838 <syscalls_str+0x1c0>
    80003d7a:	ffffc097          	auipc	ra,0xffffc
    80003d7e:	7b0080e7          	jalr	1968(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d82:	24c1                	addiw	s1,s1,16
    80003d84:	04c92783          	lw	a5,76(s2)
    80003d88:	04f4f763          	bgeu	s1,a5,80003dd6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d8c:	4741                	li	a4,16
    80003d8e:	86a6                	mv	a3,s1
    80003d90:	fc040613          	addi	a2,s0,-64
    80003d94:	4581                	li	a1,0
    80003d96:	854a                	mv	a0,s2
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	d70080e7          	jalr	-656(ra) # 80003b08 <readi>
    80003da0:	47c1                	li	a5,16
    80003da2:	fcf518e3          	bne	a0,a5,80003d72 <dirlookup+0x3a>
    if(de.inum == 0)
    80003da6:	fc045783          	lhu	a5,-64(s0)
    80003daa:	dfe1                	beqz	a5,80003d82 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dac:	fc240593          	addi	a1,s0,-62
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	f6c080e7          	jalr	-148(ra) # 80003d1e <namecmp>
    80003dba:	f561                	bnez	a0,80003d82 <dirlookup+0x4a>
      if(poff)
    80003dbc:	000a0463          	beqz	s4,80003dc4 <dirlookup+0x8c>
        *poff = off;
    80003dc0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dc4:	fc045583          	lhu	a1,-64(s0)
    80003dc8:	00092503          	lw	a0,0(s2)
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	754080e7          	jalr	1876(ra) # 80003520 <iget>
    80003dd4:	a011                	j	80003dd8 <dirlookup+0xa0>
  return 0;
    80003dd6:	4501                	li	a0,0
}
    80003dd8:	70e2                	ld	ra,56(sp)
    80003dda:	7442                	ld	s0,48(sp)
    80003ddc:	74a2                	ld	s1,40(sp)
    80003dde:	7902                	ld	s2,32(sp)
    80003de0:	69e2                	ld	s3,24(sp)
    80003de2:	6a42                	ld	s4,16(sp)
    80003de4:	6121                	addi	sp,sp,64
    80003de6:	8082                	ret

0000000080003de8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003de8:	711d                	addi	sp,sp,-96
    80003dea:	ec86                	sd	ra,88(sp)
    80003dec:	e8a2                	sd	s0,80(sp)
    80003dee:	e4a6                	sd	s1,72(sp)
    80003df0:	e0ca                	sd	s2,64(sp)
    80003df2:	fc4e                	sd	s3,56(sp)
    80003df4:	f852                	sd	s4,48(sp)
    80003df6:	f456                	sd	s5,40(sp)
    80003df8:	f05a                	sd	s6,32(sp)
    80003dfa:	ec5e                	sd	s7,24(sp)
    80003dfc:	e862                	sd	s8,16(sp)
    80003dfe:	e466                	sd	s9,8(sp)
    80003e00:	1080                	addi	s0,sp,96
    80003e02:	84aa                	mv	s1,a0
    80003e04:	8aae                	mv	s5,a1
    80003e06:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e08:	00054703          	lbu	a4,0(a0)
    80003e0c:	02f00793          	li	a5,47
    80003e10:	02f70363          	beq	a4,a5,80003e36 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e14:	ffffe097          	auipc	ra,0xffffe
    80003e18:	b7e080e7          	jalr	-1154(ra) # 80001992 <myproc>
    80003e1c:	15053503          	ld	a0,336(a0)
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	9f6080e7          	jalr	-1546(ra) # 80003816 <idup>
    80003e28:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e2a:	02f00913          	li	s2,47
  len = path - s;
    80003e2e:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e30:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e32:	4b85                	li	s7,1
    80003e34:	a865                	j	80003eec <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e36:	4585                	li	a1,1
    80003e38:	4505                	li	a0,1
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	6e6080e7          	jalr	1766(ra) # 80003520 <iget>
    80003e42:	89aa                	mv	s3,a0
    80003e44:	b7dd                	j	80003e2a <namex+0x42>
      iunlockput(ip);
    80003e46:	854e                	mv	a0,s3
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	c6e080e7          	jalr	-914(ra) # 80003ab6 <iunlockput>
      return 0;
    80003e50:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e52:	854e                	mv	a0,s3
    80003e54:	60e6                	ld	ra,88(sp)
    80003e56:	6446                	ld	s0,80(sp)
    80003e58:	64a6                	ld	s1,72(sp)
    80003e5a:	6906                	ld	s2,64(sp)
    80003e5c:	79e2                	ld	s3,56(sp)
    80003e5e:	7a42                	ld	s4,48(sp)
    80003e60:	7aa2                	ld	s5,40(sp)
    80003e62:	7b02                	ld	s6,32(sp)
    80003e64:	6be2                	ld	s7,24(sp)
    80003e66:	6c42                	ld	s8,16(sp)
    80003e68:	6ca2                	ld	s9,8(sp)
    80003e6a:	6125                	addi	sp,sp,96
    80003e6c:	8082                	ret
      iunlock(ip);
    80003e6e:	854e                	mv	a0,s3
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	aa6080e7          	jalr	-1370(ra) # 80003916 <iunlock>
      return ip;
    80003e78:	bfe9                	j	80003e52 <namex+0x6a>
      iunlockput(ip);
    80003e7a:	854e                	mv	a0,s3
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	c3a080e7          	jalr	-966(ra) # 80003ab6 <iunlockput>
      return 0;
    80003e84:	89e6                	mv	s3,s9
    80003e86:	b7f1                	j	80003e52 <namex+0x6a>
  len = path - s;
    80003e88:	40b48633          	sub	a2,s1,a1
    80003e8c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e90:	099c5463          	bge	s8,s9,80003f18 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e94:	4639                	li	a2,14
    80003e96:	8552                	mv	a0,s4
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	e82080e7          	jalr	-382(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003ea0:	0004c783          	lbu	a5,0(s1)
    80003ea4:	01279763          	bne	a5,s2,80003eb2 <namex+0xca>
    path++;
    80003ea8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eaa:	0004c783          	lbu	a5,0(s1)
    80003eae:	ff278de3          	beq	a5,s2,80003ea8 <namex+0xc0>
    ilock(ip);
    80003eb2:	854e                	mv	a0,s3
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	9a0080e7          	jalr	-1632(ra) # 80003854 <ilock>
    if(ip->type != T_DIR){
    80003ebc:	04499783          	lh	a5,68(s3)
    80003ec0:	f97793e3          	bne	a5,s7,80003e46 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ec4:	000a8563          	beqz	s5,80003ece <namex+0xe6>
    80003ec8:	0004c783          	lbu	a5,0(s1)
    80003ecc:	d3cd                	beqz	a5,80003e6e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ece:	865a                	mv	a2,s6
    80003ed0:	85d2                	mv	a1,s4
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	e64080e7          	jalr	-412(ra) # 80003d38 <dirlookup>
    80003edc:	8caa                	mv	s9,a0
    80003ede:	dd51                	beqz	a0,80003e7a <namex+0x92>
    iunlockput(ip);
    80003ee0:	854e                	mv	a0,s3
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	bd4080e7          	jalr	-1068(ra) # 80003ab6 <iunlockput>
    ip = next;
    80003eea:	89e6                	mv	s3,s9
  while(*path == '/')
    80003eec:	0004c783          	lbu	a5,0(s1)
    80003ef0:	05279763          	bne	a5,s2,80003f3e <namex+0x156>
    path++;
    80003ef4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef6:	0004c783          	lbu	a5,0(s1)
    80003efa:	ff278de3          	beq	a5,s2,80003ef4 <namex+0x10c>
  if(*path == 0)
    80003efe:	c79d                	beqz	a5,80003f2c <namex+0x144>
    path++;
    80003f00:	85a6                	mv	a1,s1
  len = path - s;
    80003f02:	8cda                	mv	s9,s6
    80003f04:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f06:	01278963          	beq	a5,s2,80003f18 <namex+0x130>
    80003f0a:	dfbd                	beqz	a5,80003e88 <namex+0xa0>
    path++;
    80003f0c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f0e:	0004c783          	lbu	a5,0(s1)
    80003f12:	ff279ce3          	bne	a5,s2,80003f0a <namex+0x122>
    80003f16:	bf8d                	j	80003e88 <namex+0xa0>
    memmove(name, s, len);
    80003f18:	2601                	sext.w	a2,a2
    80003f1a:	8552                	mv	a0,s4
    80003f1c:	ffffd097          	auipc	ra,0xffffd
    80003f20:	dfe080e7          	jalr	-514(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003f24:	9cd2                	add	s9,s9,s4
    80003f26:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f2a:	bf9d                	j	80003ea0 <namex+0xb8>
  if(nameiparent){
    80003f2c:	f20a83e3          	beqz	s5,80003e52 <namex+0x6a>
    iput(ip);
    80003f30:	854e                	mv	a0,s3
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	adc080e7          	jalr	-1316(ra) # 80003a0e <iput>
    return 0;
    80003f3a:	4981                	li	s3,0
    80003f3c:	bf19                	j	80003e52 <namex+0x6a>
  if(*path == 0)
    80003f3e:	d7fd                	beqz	a5,80003f2c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	85a6                	mv	a1,s1
    80003f46:	b7d1                	j	80003f0a <namex+0x122>

0000000080003f48 <dirlink>:
{
    80003f48:	7139                	addi	sp,sp,-64
    80003f4a:	fc06                	sd	ra,56(sp)
    80003f4c:	f822                	sd	s0,48(sp)
    80003f4e:	f426                	sd	s1,40(sp)
    80003f50:	f04a                	sd	s2,32(sp)
    80003f52:	ec4e                	sd	s3,24(sp)
    80003f54:	e852                	sd	s4,16(sp)
    80003f56:	0080                	addi	s0,sp,64
    80003f58:	892a                	mv	s2,a0
    80003f5a:	8a2e                	mv	s4,a1
    80003f5c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f5e:	4601                	li	a2,0
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	dd8080e7          	jalr	-552(ra) # 80003d38 <dirlookup>
    80003f68:	e93d                	bnez	a0,80003fde <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f6a:	04c92483          	lw	s1,76(s2)
    80003f6e:	c49d                	beqz	s1,80003f9c <dirlink+0x54>
    80003f70:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f72:	4741                	li	a4,16
    80003f74:	86a6                	mv	a3,s1
    80003f76:	fc040613          	addi	a2,s0,-64
    80003f7a:	4581                	li	a1,0
    80003f7c:	854a                	mv	a0,s2
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	b8a080e7          	jalr	-1142(ra) # 80003b08 <readi>
    80003f86:	47c1                	li	a5,16
    80003f88:	06f51163          	bne	a0,a5,80003fea <dirlink+0xa2>
    if(de.inum == 0)
    80003f8c:	fc045783          	lhu	a5,-64(s0)
    80003f90:	c791                	beqz	a5,80003f9c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f92:	24c1                	addiw	s1,s1,16
    80003f94:	04c92783          	lw	a5,76(s2)
    80003f98:	fcf4ede3          	bltu	s1,a5,80003f72 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f9c:	4639                	li	a2,14
    80003f9e:	85d2                	mv	a1,s4
    80003fa0:	fc240513          	addi	a0,s0,-62
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	e2e080e7          	jalr	-466(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003fac:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb0:	4741                	li	a4,16
    80003fb2:	86a6                	mv	a3,s1
    80003fb4:	fc040613          	addi	a2,s0,-64
    80003fb8:	4581                	li	a1,0
    80003fba:	854a                	mv	a0,s2
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	c44080e7          	jalr	-956(ra) # 80003c00 <writei>
    80003fc4:	872a                	mv	a4,a0
    80003fc6:	47c1                	li	a5,16
  return 0;
    80003fc8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fca:	02f71863          	bne	a4,a5,80003ffa <dirlink+0xb2>
}
    80003fce:	70e2                	ld	ra,56(sp)
    80003fd0:	7442                	ld	s0,48(sp)
    80003fd2:	74a2                	ld	s1,40(sp)
    80003fd4:	7902                	ld	s2,32(sp)
    80003fd6:	69e2                	ld	s3,24(sp)
    80003fd8:	6a42                	ld	s4,16(sp)
    80003fda:	6121                	addi	sp,sp,64
    80003fdc:	8082                	ret
    iput(ip);
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	a30080e7          	jalr	-1488(ra) # 80003a0e <iput>
    return -1;
    80003fe6:	557d                	li	a0,-1
    80003fe8:	b7dd                	j	80003fce <dirlink+0x86>
      panic("dirlink read");
    80003fea:	00005517          	auipc	a0,0x5
    80003fee:	85e50513          	addi	a0,a0,-1954 # 80008848 <syscalls_str+0x1d0>
    80003ff2:	ffffc097          	auipc	ra,0xffffc
    80003ff6:	538080e7          	jalr	1336(ra) # 8000052a <panic>
    panic("dirlink");
    80003ffa:	00005517          	auipc	a0,0x5
    80003ffe:	95e50513          	addi	a0,a0,-1698 # 80008958 <syscalls_str+0x2e0>
    80004002:	ffffc097          	auipc	ra,0xffffc
    80004006:	528080e7          	jalr	1320(ra) # 8000052a <panic>

000000008000400a <namei>:

struct inode*
namei(char *path)
{
    8000400a:	1101                	addi	sp,sp,-32
    8000400c:	ec06                	sd	ra,24(sp)
    8000400e:	e822                	sd	s0,16(sp)
    80004010:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004012:	fe040613          	addi	a2,s0,-32
    80004016:	4581                	li	a1,0
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	dd0080e7          	jalr	-560(ra) # 80003de8 <namex>
}
    80004020:	60e2                	ld	ra,24(sp)
    80004022:	6442                	ld	s0,16(sp)
    80004024:	6105                	addi	sp,sp,32
    80004026:	8082                	ret

0000000080004028 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004028:	1141                	addi	sp,sp,-16
    8000402a:	e406                	sd	ra,8(sp)
    8000402c:	e022                	sd	s0,0(sp)
    8000402e:	0800                	addi	s0,sp,16
    80004030:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004032:	4585                	li	a1,1
    80004034:	00000097          	auipc	ra,0x0
    80004038:	db4080e7          	jalr	-588(ra) # 80003de8 <namex>
}
    8000403c:	60a2                	ld	ra,8(sp)
    8000403e:	6402                	ld	s0,0(sp)
    80004040:	0141                	addi	sp,sp,16
    80004042:	8082                	ret

0000000080004044 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004044:	1101                	addi	sp,sp,-32
    80004046:	ec06                	sd	ra,24(sp)
    80004048:	e822                	sd	s0,16(sp)
    8000404a:	e426                	sd	s1,8(sp)
    8000404c:	e04a                	sd	s2,0(sp)
    8000404e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004050:	0001e917          	auipc	s2,0x1e
    80004054:	82090913          	addi	s2,s2,-2016 # 80021870 <log>
    80004058:	01892583          	lw	a1,24(s2)
    8000405c:	02892503          	lw	a0,40(s2)
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	ff0080e7          	jalr	-16(ra) # 80003050 <bread>
    80004068:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000406a:	02c92683          	lw	a3,44(s2)
    8000406e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004070:	02d05863          	blez	a3,800040a0 <write_head+0x5c>
    80004074:	0001e797          	auipc	a5,0x1e
    80004078:	82c78793          	addi	a5,a5,-2004 # 800218a0 <log+0x30>
    8000407c:	05c50713          	addi	a4,a0,92
    80004080:	36fd                	addiw	a3,a3,-1
    80004082:	02069613          	slli	a2,a3,0x20
    80004086:	01e65693          	srli	a3,a2,0x1e
    8000408a:	0001e617          	auipc	a2,0x1e
    8000408e:	81a60613          	addi	a2,a2,-2022 # 800218a4 <log+0x34>
    80004092:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004094:	4390                	lw	a2,0(a5)
    80004096:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004098:	0791                	addi	a5,a5,4
    8000409a:	0711                	addi	a4,a4,4
    8000409c:	fed79ce3          	bne	a5,a3,80004094 <write_head+0x50>
  }
  bwrite(buf);
    800040a0:	8526                	mv	a0,s1
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	0a0080e7          	jalr	160(ra) # 80003142 <bwrite>
  brelse(buf);
    800040aa:	8526                	mv	a0,s1
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	0d4080e7          	jalr	212(ra) # 80003180 <brelse>
}
    800040b4:	60e2                	ld	ra,24(sp)
    800040b6:	6442                	ld	s0,16(sp)
    800040b8:	64a2                	ld	s1,8(sp)
    800040ba:	6902                	ld	s2,0(sp)
    800040bc:	6105                	addi	sp,sp,32
    800040be:	8082                	ret

00000000800040c0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c0:	0001d797          	auipc	a5,0x1d
    800040c4:	7dc7a783          	lw	a5,2012(a5) # 8002189c <log+0x2c>
    800040c8:	0af05d63          	blez	a5,80004182 <install_trans+0xc2>
{
    800040cc:	7139                	addi	sp,sp,-64
    800040ce:	fc06                	sd	ra,56(sp)
    800040d0:	f822                	sd	s0,48(sp)
    800040d2:	f426                	sd	s1,40(sp)
    800040d4:	f04a                	sd	s2,32(sp)
    800040d6:	ec4e                	sd	s3,24(sp)
    800040d8:	e852                	sd	s4,16(sp)
    800040da:	e456                	sd	s5,8(sp)
    800040dc:	e05a                	sd	s6,0(sp)
    800040de:	0080                	addi	s0,sp,64
    800040e0:	8b2a                	mv	s6,a0
    800040e2:	0001da97          	auipc	s5,0x1d
    800040e6:	7bea8a93          	addi	s5,s5,1982 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ea:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ec:	0001d997          	auipc	s3,0x1d
    800040f0:	78498993          	addi	s3,s3,1924 # 80021870 <log>
    800040f4:	a00d                	j	80004116 <install_trans+0x56>
    brelse(lbuf);
    800040f6:	854a                	mv	a0,s2
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	088080e7          	jalr	136(ra) # 80003180 <brelse>
    brelse(dbuf);
    80004100:	8526                	mv	a0,s1
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	07e080e7          	jalr	126(ra) # 80003180 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000410a:	2a05                	addiw	s4,s4,1
    8000410c:	0a91                	addi	s5,s5,4
    8000410e:	02c9a783          	lw	a5,44(s3)
    80004112:	04fa5e63          	bge	s4,a5,8000416e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004116:	0189a583          	lw	a1,24(s3)
    8000411a:	014585bb          	addw	a1,a1,s4
    8000411e:	2585                	addiw	a1,a1,1
    80004120:	0289a503          	lw	a0,40(s3)
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	f2c080e7          	jalr	-212(ra) # 80003050 <bread>
    8000412c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000412e:	000aa583          	lw	a1,0(s5)
    80004132:	0289a503          	lw	a0,40(s3)
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	f1a080e7          	jalr	-230(ra) # 80003050 <bread>
    8000413e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004140:	40000613          	li	a2,1024
    80004144:	05890593          	addi	a1,s2,88
    80004148:	05850513          	addi	a0,a0,88
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	bce080e7          	jalr	-1074(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004154:	8526                	mv	a0,s1
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	fec080e7          	jalr	-20(ra) # 80003142 <bwrite>
    if(recovering == 0)
    8000415e:	f80b1ce3          	bnez	s6,800040f6 <install_trans+0x36>
      bunpin(dbuf);
    80004162:	8526                	mv	a0,s1
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	0f6080e7          	jalr	246(ra) # 8000325a <bunpin>
    8000416c:	b769                	j	800040f6 <install_trans+0x36>
}
    8000416e:	70e2                	ld	ra,56(sp)
    80004170:	7442                	ld	s0,48(sp)
    80004172:	74a2                	ld	s1,40(sp)
    80004174:	7902                	ld	s2,32(sp)
    80004176:	69e2                	ld	s3,24(sp)
    80004178:	6a42                	ld	s4,16(sp)
    8000417a:	6aa2                	ld	s5,8(sp)
    8000417c:	6b02                	ld	s6,0(sp)
    8000417e:	6121                	addi	sp,sp,64
    80004180:	8082                	ret
    80004182:	8082                	ret

0000000080004184 <initlog>:
{
    80004184:	7179                	addi	sp,sp,-48
    80004186:	f406                	sd	ra,40(sp)
    80004188:	f022                	sd	s0,32(sp)
    8000418a:	ec26                	sd	s1,24(sp)
    8000418c:	e84a                	sd	s2,16(sp)
    8000418e:	e44e                	sd	s3,8(sp)
    80004190:	1800                	addi	s0,sp,48
    80004192:	892a                	mv	s2,a0
    80004194:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004196:	0001d497          	auipc	s1,0x1d
    8000419a:	6da48493          	addi	s1,s1,1754 # 80021870 <log>
    8000419e:	00004597          	auipc	a1,0x4
    800041a2:	6ba58593          	addi	a1,a1,1722 # 80008858 <syscalls_str+0x1e0>
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	98a080e7          	jalr	-1654(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    800041b0:	0149a583          	lw	a1,20(s3)
    800041b4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041b6:	0109a783          	lw	a5,16(s3)
    800041ba:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041bc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041c0:	854a                	mv	a0,s2
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	e8e080e7          	jalr	-370(ra) # 80003050 <bread>
  log.lh.n = lh->n;
    800041ca:	4d34                	lw	a3,88(a0)
    800041cc:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041ce:	02d05663          	blez	a3,800041fa <initlog+0x76>
    800041d2:	05c50793          	addi	a5,a0,92
    800041d6:	0001d717          	auipc	a4,0x1d
    800041da:	6ca70713          	addi	a4,a4,1738 # 800218a0 <log+0x30>
    800041de:	36fd                	addiw	a3,a3,-1
    800041e0:	02069613          	slli	a2,a3,0x20
    800041e4:	01e65693          	srli	a3,a2,0x1e
    800041e8:	06050613          	addi	a2,a0,96
    800041ec:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041ee:	4390                	lw	a2,0(a5)
    800041f0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041f2:	0791                	addi	a5,a5,4
    800041f4:	0711                	addi	a4,a4,4
    800041f6:	fed79ce3          	bne	a5,a3,800041ee <initlog+0x6a>
  brelse(buf);
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	f86080e7          	jalr	-122(ra) # 80003180 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004202:	4505                	li	a0,1
    80004204:	00000097          	auipc	ra,0x0
    80004208:	ebc080e7          	jalr	-324(ra) # 800040c0 <install_trans>
  log.lh.n = 0;
    8000420c:	0001d797          	auipc	a5,0x1d
    80004210:	6807a823          	sw	zero,1680(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    80004214:	00000097          	auipc	ra,0x0
    80004218:	e30080e7          	jalr	-464(ra) # 80004044 <write_head>
}
    8000421c:	70a2                	ld	ra,40(sp)
    8000421e:	7402                	ld	s0,32(sp)
    80004220:	64e2                	ld	s1,24(sp)
    80004222:	6942                	ld	s2,16(sp)
    80004224:	69a2                	ld	s3,8(sp)
    80004226:	6145                	addi	sp,sp,48
    80004228:	8082                	ret

000000008000422a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000422a:	1101                	addi	sp,sp,-32
    8000422c:	ec06                	sd	ra,24(sp)
    8000422e:	e822                	sd	s0,16(sp)
    80004230:	e426                	sd	s1,8(sp)
    80004232:	e04a                	sd	s2,0(sp)
    80004234:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004236:	0001d517          	auipc	a0,0x1d
    8000423a:	63a50513          	addi	a0,a0,1594 # 80021870 <log>
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	984080e7          	jalr	-1660(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004246:	0001d497          	auipc	s1,0x1d
    8000424a:	62a48493          	addi	s1,s1,1578 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000424e:	4979                	li	s2,30
    80004250:	a039                	j	8000425e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004252:	85a6                	mv	a1,s1
    80004254:	8526                	mv	a0,s1
    80004256:	ffffe097          	auipc	ra,0xffffe
    8000425a:	e78080e7          	jalr	-392(ra) # 800020ce <sleep>
    if(log.committing){
    8000425e:	50dc                	lw	a5,36(s1)
    80004260:	fbed                	bnez	a5,80004252 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004262:	509c                	lw	a5,32(s1)
    80004264:	0017871b          	addiw	a4,a5,1
    80004268:	0007069b          	sext.w	a3,a4
    8000426c:	0027179b          	slliw	a5,a4,0x2
    80004270:	9fb9                	addw	a5,a5,a4
    80004272:	0017979b          	slliw	a5,a5,0x1
    80004276:	54d8                	lw	a4,44(s1)
    80004278:	9fb9                	addw	a5,a5,a4
    8000427a:	00f95963          	bge	s2,a5,8000428c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000427e:	85a6                	mv	a1,s1
    80004280:	8526                	mv	a0,s1
    80004282:	ffffe097          	auipc	ra,0xffffe
    80004286:	e4c080e7          	jalr	-436(ra) # 800020ce <sleep>
    8000428a:	bfd1                	j	8000425e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000428c:	0001d517          	auipc	a0,0x1d
    80004290:	5e450513          	addi	a0,a0,1508 # 80021870 <log>
    80004294:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	9e0080e7          	jalr	-1568(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000429e:	60e2                	ld	ra,24(sp)
    800042a0:	6442                	ld	s0,16(sp)
    800042a2:	64a2                	ld	s1,8(sp)
    800042a4:	6902                	ld	s2,0(sp)
    800042a6:	6105                	addi	sp,sp,32
    800042a8:	8082                	ret

00000000800042aa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042aa:	7139                	addi	sp,sp,-64
    800042ac:	fc06                	sd	ra,56(sp)
    800042ae:	f822                	sd	s0,48(sp)
    800042b0:	f426                	sd	s1,40(sp)
    800042b2:	f04a                	sd	s2,32(sp)
    800042b4:	ec4e                	sd	s3,24(sp)
    800042b6:	e852                	sd	s4,16(sp)
    800042b8:	e456                	sd	s5,8(sp)
    800042ba:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042bc:	0001d497          	auipc	s1,0x1d
    800042c0:	5b448493          	addi	s1,s1,1460 # 80021870 <log>
    800042c4:	8526                	mv	a0,s1
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	8fc080e7          	jalr	-1796(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800042ce:	509c                	lw	a5,32(s1)
    800042d0:	37fd                	addiw	a5,a5,-1
    800042d2:	0007891b          	sext.w	s2,a5
    800042d6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042d8:	50dc                	lw	a5,36(s1)
    800042da:	e7b9                	bnez	a5,80004328 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042dc:	04091e63          	bnez	s2,80004338 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042e0:	0001d497          	auipc	s1,0x1d
    800042e4:	59048493          	addi	s1,s1,1424 # 80021870 <log>
    800042e8:	4785                	li	a5,1
    800042ea:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042ec:	8526                	mv	a0,s1
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042f6:	54dc                	lw	a5,44(s1)
    800042f8:	06f04763          	bgtz	a5,80004366 <end_op+0xbc>
    acquire(&log.lock);
    800042fc:	0001d497          	auipc	s1,0x1d
    80004300:	57448493          	addi	s1,s1,1396 # 80021870 <log>
    80004304:	8526                	mv	a0,s1
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	8bc080e7          	jalr	-1860(ra) # 80000bc2 <acquire>
    log.committing = 0;
    8000430e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004312:	8526                	mv	a0,s1
    80004314:	ffffe097          	auipc	ra,0xffffe
    80004318:	f46080e7          	jalr	-186(ra) # 8000225a <wakeup>
    release(&log.lock);
    8000431c:	8526                	mv	a0,s1
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	958080e7          	jalr	-1704(ra) # 80000c76 <release>
}
    80004326:	a03d                	j	80004354 <end_op+0xaa>
    panic("log.committing");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	53850513          	addi	a0,a0,1336 # 80008860 <syscalls_str+0x1e8>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	1fa080e7          	jalr	506(ra) # 8000052a <panic>
    wakeup(&log);
    80004338:	0001d497          	auipc	s1,0x1d
    8000433c:	53848493          	addi	s1,s1,1336 # 80021870 <log>
    80004340:	8526                	mv	a0,s1
    80004342:	ffffe097          	auipc	ra,0xffffe
    80004346:	f18080e7          	jalr	-232(ra) # 8000225a <wakeup>
  release(&log.lock);
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	92a080e7          	jalr	-1750(ra) # 80000c76 <release>
}
    80004354:	70e2                	ld	ra,56(sp)
    80004356:	7442                	ld	s0,48(sp)
    80004358:	74a2                	ld	s1,40(sp)
    8000435a:	7902                	ld	s2,32(sp)
    8000435c:	69e2                	ld	s3,24(sp)
    8000435e:	6a42                	ld	s4,16(sp)
    80004360:	6aa2                	ld	s5,8(sp)
    80004362:	6121                	addi	sp,sp,64
    80004364:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004366:	0001da97          	auipc	s5,0x1d
    8000436a:	53aa8a93          	addi	s5,s5,1338 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000436e:	0001da17          	auipc	s4,0x1d
    80004372:	502a0a13          	addi	s4,s4,1282 # 80021870 <log>
    80004376:	018a2583          	lw	a1,24(s4)
    8000437a:	012585bb          	addw	a1,a1,s2
    8000437e:	2585                	addiw	a1,a1,1
    80004380:	028a2503          	lw	a0,40(s4)
    80004384:	fffff097          	auipc	ra,0xfffff
    80004388:	ccc080e7          	jalr	-820(ra) # 80003050 <bread>
    8000438c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000438e:	000aa583          	lw	a1,0(s5)
    80004392:	028a2503          	lw	a0,40(s4)
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	cba080e7          	jalr	-838(ra) # 80003050 <bread>
    8000439e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043a0:	40000613          	li	a2,1024
    800043a4:	05850593          	addi	a1,a0,88
    800043a8:	05848513          	addi	a0,s1,88
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	96e080e7          	jalr	-1682(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    800043b4:	8526                	mv	a0,s1
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	d8c080e7          	jalr	-628(ra) # 80003142 <bwrite>
    brelse(from);
    800043be:	854e                	mv	a0,s3
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	dc0080e7          	jalr	-576(ra) # 80003180 <brelse>
    brelse(to);
    800043c8:	8526                	mv	a0,s1
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	db6080e7          	jalr	-586(ra) # 80003180 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d2:	2905                	addiw	s2,s2,1
    800043d4:	0a91                	addi	s5,s5,4
    800043d6:	02ca2783          	lw	a5,44(s4)
    800043da:	f8f94ee3          	blt	s2,a5,80004376 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	c66080e7          	jalr	-922(ra) # 80004044 <write_head>
    install_trans(0); // Now install writes to home locations
    800043e6:	4501                	li	a0,0
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	cd8080e7          	jalr	-808(ra) # 800040c0 <install_trans>
    log.lh.n = 0;
    800043f0:	0001d797          	auipc	a5,0x1d
    800043f4:	4a07a623          	sw	zero,1196(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	c4c080e7          	jalr	-948(ra) # 80004044 <write_head>
    80004400:	bdf5                	j	800042fc <end_op+0x52>

0000000080004402 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004402:	1101                	addi	sp,sp,-32
    80004404:	ec06                	sd	ra,24(sp)
    80004406:	e822                	sd	s0,16(sp)
    80004408:	e426                	sd	s1,8(sp)
    8000440a:	e04a                	sd	s2,0(sp)
    8000440c:	1000                	addi	s0,sp,32
    8000440e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004410:	0001d917          	auipc	s2,0x1d
    80004414:	46090913          	addi	s2,s2,1120 # 80021870 <log>
    80004418:	854a                	mv	a0,s2
    8000441a:	ffffc097          	auipc	ra,0xffffc
    8000441e:	7a8080e7          	jalr	1960(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004422:	02c92603          	lw	a2,44(s2)
    80004426:	47f5                	li	a5,29
    80004428:	06c7c563          	blt	a5,a2,80004492 <log_write+0x90>
    8000442c:	0001d797          	auipc	a5,0x1d
    80004430:	4607a783          	lw	a5,1120(a5) # 8002188c <log+0x1c>
    80004434:	37fd                	addiw	a5,a5,-1
    80004436:	04f65e63          	bge	a2,a5,80004492 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000443a:	0001d797          	auipc	a5,0x1d
    8000443e:	4567a783          	lw	a5,1110(a5) # 80021890 <log+0x20>
    80004442:	06f05063          	blez	a5,800044a2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004446:	4781                	li	a5,0
    80004448:	06c05563          	blez	a2,800044b2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000444c:	44cc                	lw	a1,12(s1)
    8000444e:	0001d717          	auipc	a4,0x1d
    80004452:	45270713          	addi	a4,a4,1106 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004456:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004458:	4314                	lw	a3,0(a4)
    8000445a:	04b68c63          	beq	a3,a1,800044b2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000445e:	2785                	addiw	a5,a5,1
    80004460:	0711                	addi	a4,a4,4
    80004462:	fef61be3          	bne	a2,a5,80004458 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004466:	0621                	addi	a2,a2,8
    80004468:	060a                	slli	a2,a2,0x2
    8000446a:	0001d797          	auipc	a5,0x1d
    8000446e:	40678793          	addi	a5,a5,1030 # 80021870 <log>
    80004472:	963e                	add	a2,a2,a5
    80004474:	44dc                	lw	a5,12(s1)
    80004476:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004478:	8526                	mv	a0,s1
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	da4080e7          	jalr	-604(ra) # 8000321e <bpin>
    log.lh.n++;
    80004482:	0001d717          	auipc	a4,0x1d
    80004486:	3ee70713          	addi	a4,a4,1006 # 80021870 <log>
    8000448a:	575c                	lw	a5,44(a4)
    8000448c:	2785                	addiw	a5,a5,1
    8000448e:	d75c                	sw	a5,44(a4)
    80004490:	a835                	j	800044cc <log_write+0xca>
    panic("too big a transaction");
    80004492:	00004517          	auipc	a0,0x4
    80004496:	3de50513          	addi	a0,a0,990 # 80008870 <syscalls_str+0x1f8>
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	090080e7          	jalr	144(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800044a2:	00004517          	auipc	a0,0x4
    800044a6:	3e650513          	addi	a0,a0,998 # 80008888 <syscalls_str+0x210>
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	080080e7          	jalr	128(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800044b2:	00878713          	addi	a4,a5,8
    800044b6:	00271693          	slli	a3,a4,0x2
    800044ba:	0001d717          	auipc	a4,0x1d
    800044be:	3b670713          	addi	a4,a4,950 # 80021870 <log>
    800044c2:	9736                	add	a4,a4,a3
    800044c4:	44d4                	lw	a3,12(s1)
    800044c6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044c8:	faf608e3          	beq	a2,a5,80004478 <log_write+0x76>
  }
  release(&log.lock);
    800044cc:	0001d517          	auipc	a0,0x1d
    800044d0:	3a450513          	addi	a0,a0,932 # 80021870 <log>
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	7a2080e7          	jalr	1954(ra) # 80000c76 <release>
}
    800044dc:	60e2                	ld	ra,24(sp)
    800044de:	6442                	ld	s0,16(sp)
    800044e0:	64a2                	ld	s1,8(sp)
    800044e2:	6902                	ld	s2,0(sp)
    800044e4:	6105                	addi	sp,sp,32
    800044e6:	8082                	ret

00000000800044e8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044e8:	1101                	addi	sp,sp,-32
    800044ea:	ec06                	sd	ra,24(sp)
    800044ec:	e822                	sd	s0,16(sp)
    800044ee:	e426                	sd	s1,8(sp)
    800044f0:	e04a                	sd	s2,0(sp)
    800044f2:	1000                	addi	s0,sp,32
    800044f4:	84aa                	mv	s1,a0
    800044f6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044f8:	00004597          	auipc	a1,0x4
    800044fc:	3b058593          	addi	a1,a1,944 # 800088a8 <syscalls_str+0x230>
    80004500:	0521                	addi	a0,a0,8
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	630080e7          	jalr	1584(ra) # 80000b32 <initlock>
  lk->name = name;
    8000450a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000450e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004512:	0204a423          	sw	zero,40(s1)
}
    80004516:	60e2                	ld	ra,24(sp)
    80004518:	6442                	ld	s0,16(sp)
    8000451a:	64a2                	ld	s1,8(sp)
    8000451c:	6902                	ld	s2,0(sp)
    8000451e:	6105                	addi	sp,sp,32
    80004520:	8082                	ret

0000000080004522 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	e426                	sd	s1,8(sp)
    8000452a:	e04a                	sd	s2,0(sp)
    8000452c:	1000                	addi	s0,sp,32
    8000452e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004530:	00850913          	addi	s2,a0,8
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	68c080e7          	jalr	1676(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    8000453e:	409c                	lw	a5,0(s1)
    80004540:	cb89                	beqz	a5,80004552 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004542:	85ca                	mv	a1,s2
    80004544:	8526                	mv	a0,s1
    80004546:	ffffe097          	auipc	ra,0xffffe
    8000454a:	b88080e7          	jalr	-1144(ra) # 800020ce <sleep>
  while (lk->locked) {
    8000454e:	409c                	lw	a5,0(s1)
    80004550:	fbed                	bnez	a5,80004542 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004552:	4785                	li	a5,1
    80004554:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004556:	ffffd097          	auipc	ra,0xffffd
    8000455a:	43c080e7          	jalr	1084(ra) # 80001992 <myproc>
    8000455e:	591c                	lw	a5,48(a0)
    80004560:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004562:	854a                	mv	a0,s2
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	712080e7          	jalr	1810(ra) # 80000c76 <release>
}
    8000456c:	60e2                	ld	ra,24(sp)
    8000456e:	6442                	ld	s0,16(sp)
    80004570:	64a2                	ld	s1,8(sp)
    80004572:	6902                	ld	s2,0(sp)
    80004574:	6105                	addi	sp,sp,32
    80004576:	8082                	ret

0000000080004578 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004578:	1101                	addi	sp,sp,-32
    8000457a:	ec06                	sd	ra,24(sp)
    8000457c:	e822                	sd	s0,16(sp)
    8000457e:	e426                	sd	s1,8(sp)
    80004580:	e04a                	sd	s2,0(sp)
    80004582:	1000                	addi	s0,sp,32
    80004584:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004586:	00850913          	addi	s2,a0,8
    8000458a:	854a                	mv	a0,s2
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	636080e7          	jalr	1590(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004594:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004598:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000459c:	8526                	mv	a0,s1
    8000459e:	ffffe097          	auipc	ra,0xffffe
    800045a2:	cbc080e7          	jalr	-836(ra) # 8000225a <wakeup>
  release(&lk->lk);
    800045a6:	854a                	mv	a0,s2
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	6ce080e7          	jalr	1742(ra) # 80000c76 <release>
}
    800045b0:	60e2                	ld	ra,24(sp)
    800045b2:	6442                	ld	s0,16(sp)
    800045b4:	64a2                	ld	s1,8(sp)
    800045b6:	6902                	ld	s2,0(sp)
    800045b8:	6105                	addi	sp,sp,32
    800045ba:	8082                	ret

00000000800045bc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045bc:	7179                	addi	sp,sp,-48
    800045be:	f406                	sd	ra,40(sp)
    800045c0:	f022                	sd	s0,32(sp)
    800045c2:	ec26                	sd	s1,24(sp)
    800045c4:	e84a                	sd	s2,16(sp)
    800045c6:	e44e                	sd	s3,8(sp)
    800045c8:	1800                	addi	s0,sp,48
    800045ca:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045cc:	00850913          	addi	s2,a0,8
    800045d0:	854a                	mv	a0,s2
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	5f0080e7          	jalr	1520(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045da:	409c                	lw	a5,0(s1)
    800045dc:	ef99                	bnez	a5,800045fa <holdingsleep+0x3e>
    800045de:	4481                	li	s1,0
  release(&lk->lk);
    800045e0:	854a                	mv	a0,s2
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	694080e7          	jalr	1684(ra) # 80000c76 <release>
  return r;
}
    800045ea:	8526                	mv	a0,s1
    800045ec:	70a2                	ld	ra,40(sp)
    800045ee:	7402                	ld	s0,32(sp)
    800045f0:	64e2                	ld	s1,24(sp)
    800045f2:	6942                	ld	s2,16(sp)
    800045f4:	69a2                	ld	s3,8(sp)
    800045f6:	6145                	addi	sp,sp,48
    800045f8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045fa:	0284a983          	lw	s3,40(s1)
    800045fe:	ffffd097          	auipc	ra,0xffffd
    80004602:	394080e7          	jalr	916(ra) # 80001992 <myproc>
    80004606:	5904                	lw	s1,48(a0)
    80004608:	413484b3          	sub	s1,s1,s3
    8000460c:	0014b493          	seqz	s1,s1
    80004610:	bfc1                	j	800045e0 <holdingsleep+0x24>

0000000080004612 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004612:	1141                	addi	sp,sp,-16
    80004614:	e406                	sd	ra,8(sp)
    80004616:	e022                	sd	s0,0(sp)
    80004618:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000461a:	00004597          	auipc	a1,0x4
    8000461e:	29e58593          	addi	a1,a1,670 # 800088b8 <syscalls_str+0x240>
    80004622:	0001d517          	auipc	a0,0x1d
    80004626:	39650513          	addi	a0,a0,918 # 800219b8 <ftable>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	508080e7          	jalr	1288(ra) # 80000b32 <initlock>
}
    80004632:	60a2                	ld	ra,8(sp)
    80004634:	6402                	ld	s0,0(sp)
    80004636:	0141                	addi	sp,sp,16
    80004638:	8082                	ret

000000008000463a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000463a:	1101                	addi	sp,sp,-32
    8000463c:	ec06                	sd	ra,24(sp)
    8000463e:	e822                	sd	s0,16(sp)
    80004640:	e426                	sd	s1,8(sp)
    80004642:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004644:	0001d517          	auipc	a0,0x1d
    80004648:	37450513          	addi	a0,a0,884 # 800219b8 <ftable>
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	576080e7          	jalr	1398(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004654:	0001d497          	auipc	s1,0x1d
    80004658:	37c48493          	addi	s1,s1,892 # 800219d0 <ftable+0x18>
    8000465c:	0001e717          	auipc	a4,0x1e
    80004660:	31470713          	addi	a4,a4,788 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    80004664:	40dc                	lw	a5,4(s1)
    80004666:	cf99                	beqz	a5,80004684 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004668:	02848493          	addi	s1,s1,40
    8000466c:	fee49ce3          	bne	s1,a4,80004664 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004670:	0001d517          	auipc	a0,0x1d
    80004674:	34850513          	addi	a0,a0,840 # 800219b8 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	5fe080e7          	jalr	1534(ra) # 80000c76 <release>
  return 0;
    80004680:	4481                	li	s1,0
    80004682:	a819                	j	80004698 <filealloc+0x5e>
      f->ref = 1;
    80004684:	4785                	li	a5,1
    80004686:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004688:	0001d517          	auipc	a0,0x1d
    8000468c:	33050513          	addi	a0,a0,816 # 800219b8 <ftable>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	5e6080e7          	jalr	1510(ra) # 80000c76 <release>
}
    80004698:	8526                	mv	a0,s1
    8000469a:	60e2                	ld	ra,24(sp)
    8000469c:	6442                	ld	s0,16(sp)
    8000469e:	64a2                	ld	s1,8(sp)
    800046a0:	6105                	addi	sp,sp,32
    800046a2:	8082                	ret

00000000800046a4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046a4:	1101                	addi	sp,sp,-32
    800046a6:	ec06                	sd	ra,24(sp)
    800046a8:	e822                	sd	s0,16(sp)
    800046aa:	e426                	sd	s1,8(sp)
    800046ac:	1000                	addi	s0,sp,32
    800046ae:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046b0:	0001d517          	auipc	a0,0x1d
    800046b4:	30850513          	addi	a0,a0,776 # 800219b8 <ftable>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	50a080e7          	jalr	1290(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800046c0:	40dc                	lw	a5,4(s1)
    800046c2:	02f05263          	blez	a5,800046e6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046c6:	2785                	addiw	a5,a5,1
    800046c8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046ca:	0001d517          	auipc	a0,0x1d
    800046ce:	2ee50513          	addi	a0,a0,750 # 800219b8 <ftable>
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	5a4080e7          	jalr	1444(ra) # 80000c76 <release>
  return f;
}
    800046da:	8526                	mv	a0,s1
    800046dc:	60e2                	ld	ra,24(sp)
    800046de:	6442                	ld	s0,16(sp)
    800046e0:	64a2                	ld	s1,8(sp)
    800046e2:	6105                	addi	sp,sp,32
    800046e4:	8082                	ret
    panic("filedup");
    800046e6:	00004517          	auipc	a0,0x4
    800046ea:	1da50513          	addi	a0,a0,474 # 800088c0 <syscalls_str+0x248>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	e3c080e7          	jalr	-452(ra) # 8000052a <panic>

00000000800046f6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046f6:	7139                	addi	sp,sp,-64
    800046f8:	fc06                	sd	ra,56(sp)
    800046fa:	f822                	sd	s0,48(sp)
    800046fc:	f426                	sd	s1,40(sp)
    800046fe:	f04a                	sd	s2,32(sp)
    80004700:	ec4e                	sd	s3,24(sp)
    80004702:	e852                	sd	s4,16(sp)
    80004704:	e456                	sd	s5,8(sp)
    80004706:	0080                	addi	s0,sp,64
    80004708:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000470a:	0001d517          	auipc	a0,0x1d
    8000470e:	2ae50513          	addi	a0,a0,686 # 800219b8 <ftable>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	4b0080e7          	jalr	1200(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000471a:	40dc                	lw	a5,4(s1)
    8000471c:	06f05163          	blez	a5,8000477e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004720:	37fd                	addiw	a5,a5,-1
    80004722:	0007871b          	sext.w	a4,a5
    80004726:	c0dc                	sw	a5,4(s1)
    80004728:	06e04363          	bgtz	a4,8000478e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000472c:	0004a903          	lw	s2,0(s1)
    80004730:	0094ca83          	lbu	s5,9(s1)
    80004734:	0104ba03          	ld	s4,16(s1)
    80004738:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000473c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004740:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004744:	0001d517          	auipc	a0,0x1d
    80004748:	27450513          	addi	a0,a0,628 # 800219b8 <ftable>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	52a080e7          	jalr	1322(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004754:	4785                	li	a5,1
    80004756:	04f90d63          	beq	s2,a5,800047b0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000475a:	3979                	addiw	s2,s2,-2
    8000475c:	4785                	li	a5,1
    8000475e:	0527e063          	bltu	a5,s2,8000479e <fileclose+0xa8>
    begin_op();
    80004762:	00000097          	auipc	ra,0x0
    80004766:	ac8080e7          	jalr	-1336(ra) # 8000422a <begin_op>
    iput(ff.ip);
    8000476a:	854e                	mv	a0,s3
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	2a2080e7          	jalr	674(ra) # 80003a0e <iput>
    end_op();
    80004774:	00000097          	auipc	ra,0x0
    80004778:	b36080e7          	jalr	-1226(ra) # 800042aa <end_op>
    8000477c:	a00d                	j	8000479e <fileclose+0xa8>
    panic("fileclose");
    8000477e:	00004517          	auipc	a0,0x4
    80004782:	14a50513          	addi	a0,a0,330 # 800088c8 <syscalls_str+0x250>
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	da4080e7          	jalr	-604(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000478e:	0001d517          	auipc	a0,0x1d
    80004792:	22a50513          	addi	a0,a0,554 # 800219b8 <ftable>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	4e0080e7          	jalr	1248(ra) # 80000c76 <release>
  }
}
    8000479e:	70e2                	ld	ra,56(sp)
    800047a0:	7442                	ld	s0,48(sp)
    800047a2:	74a2                	ld	s1,40(sp)
    800047a4:	7902                	ld	s2,32(sp)
    800047a6:	69e2                	ld	s3,24(sp)
    800047a8:	6a42                	ld	s4,16(sp)
    800047aa:	6aa2                	ld	s5,8(sp)
    800047ac:	6121                	addi	sp,sp,64
    800047ae:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047b0:	85d6                	mv	a1,s5
    800047b2:	8552                	mv	a0,s4
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	34c080e7          	jalr	844(ra) # 80004b00 <pipeclose>
    800047bc:	b7cd                	j	8000479e <fileclose+0xa8>

00000000800047be <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047be:	715d                	addi	sp,sp,-80
    800047c0:	e486                	sd	ra,72(sp)
    800047c2:	e0a2                	sd	s0,64(sp)
    800047c4:	fc26                	sd	s1,56(sp)
    800047c6:	f84a                	sd	s2,48(sp)
    800047c8:	f44e                	sd	s3,40(sp)
    800047ca:	0880                	addi	s0,sp,80
    800047cc:	84aa                	mv	s1,a0
    800047ce:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047d0:	ffffd097          	auipc	ra,0xffffd
    800047d4:	1c2080e7          	jalr	450(ra) # 80001992 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047d8:	409c                	lw	a5,0(s1)
    800047da:	37f9                	addiw	a5,a5,-2
    800047dc:	4705                	li	a4,1
    800047de:	04f76763          	bltu	a4,a5,8000482c <filestat+0x6e>
    800047e2:	892a                	mv	s2,a0
    ilock(f->ip);
    800047e4:	6c88                	ld	a0,24(s1)
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	06e080e7          	jalr	110(ra) # 80003854 <ilock>
    stati(f->ip, &st);
    800047ee:	fb840593          	addi	a1,s0,-72
    800047f2:	6c88                	ld	a0,24(s1)
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	2ea080e7          	jalr	746(ra) # 80003ade <stati>
    iunlock(f->ip);
    800047fc:	6c88                	ld	a0,24(s1)
    800047fe:	fffff097          	auipc	ra,0xfffff
    80004802:	118080e7          	jalr	280(ra) # 80003916 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004806:	46e1                	li	a3,24
    80004808:	fb840613          	addi	a2,s0,-72
    8000480c:	85ce                	mv	a1,s3
    8000480e:	05093503          	ld	a0,80(s2)
    80004812:	ffffd097          	auipc	ra,0xffffd
    80004816:	e2c080e7          	jalr	-468(ra) # 8000163e <copyout>
    8000481a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000481e:	60a6                	ld	ra,72(sp)
    80004820:	6406                	ld	s0,64(sp)
    80004822:	74e2                	ld	s1,56(sp)
    80004824:	7942                	ld	s2,48(sp)
    80004826:	79a2                	ld	s3,40(sp)
    80004828:	6161                	addi	sp,sp,80
    8000482a:	8082                	ret
  return -1;
    8000482c:	557d                	li	a0,-1
    8000482e:	bfc5                	j	8000481e <filestat+0x60>

0000000080004830 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004830:	7179                	addi	sp,sp,-48
    80004832:	f406                	sd	ra,40(sp)
    80004834:	f022                	sd	s0,32(sp)
    80004836:	ec26                	sd	s1,24(sp)
    80004838:	e84a                	sd	s2,16(sp)
    8000483a:	e44e                	sd	s3,8(sp)
    8000483c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000483e:	00854783          	lbu	a5,8(a0)
    80004842:	c3d5                	beqz	a5,800048e6 <fileread+0xb6>
    80004844:	84aa                	mv	s1,a0
    80004846:	89ae                	mv	s3,a1
    80004848:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000484a:	411c                	lw	a5,0(a0)
    8000484c:	4705                	li	a4,1
    8000484e:	04e78963          	beq	a5,a4,800048a0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004852:	470d                	li	a4,3
    80004854:	04e78d63          	beq	a5,a4,800048ae <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004858:	4709                	li	a4,2
    8000485a:	06e79e63          	bne	a5,a4,800048d6 <fileread+0xa6>
    ilock(f->ip);
    8000485e:	6d08                	ld	a0,24(a0)
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	ff4080e7          	jalr	-12(ra) # 80003854 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004868:	874a                	mv	a4,s2
    8000486a:	5094                	lw	a3,32(s1)
    8000486c:	864e                	mv	a2,s3
    8000486e:	4585                	li	a1,1
    80004870:	6c88                	ld	a0,24(s1)
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	296080e7          	jalr	662(ra) # 80003b08 <readi>
    8000487a:	892a                	mv	s2,a0
    8000487c:	00a05563          	blez	a0,80004886 <fileread+0x56>
      f->off += r;
    80004880:	509c                	lw	a5,32(s1)
    80004882:	9fa9                	addw	a5,a5,a0
    80004884:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004886:	6c88                	ld	a0,24(s1)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	08e080e7          	jalr	142(ra) # 80003916 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004890:	854a                	mv	a0,s2
    80004892:	70a2                	ld	ra,40(sp)
    80004894:	7402                	ld	s0,32(sp)
    80004896:	64e2                	ld	s1,24(sp)
    80004898:	6942                	ld	s2,16(sp)
    8000489a:	69a2                	ld	s3,8(sp)
    8000489c:	6145                	addi	sp,sp,48
    8000489e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048a0:	6908                	ld	a0,16(a0)
    800048a2:	00000097          	auipc	ra,0x0
    800048a6:	3c0080e7          	jalr	960(ra) # 80004c62 <piperead>
    800048aa:	892a                	mv	s2,a0
    800048ac:	b7d5                	j	80004890 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048ae:	02451783          	lh	a5,36(a0)
    800048b2:	03079693          	slli	a3,a5,0x30
    800048b6:	92c1                	srli	a3,a3,0x30
    800048b8:	4725                	li	a4,9
    800048ba:	02d76863          	bltu	a4,a3,800048ea <fileread+0xba>
    800048be:	0792                	slli	a5,a5,0x4
    800048c0:	0001d717          	auipc	a4,0x1d
    800048c4:	05870713          	addi	a4,a4,88 # 80021918 <devsw>
    800048c8:	97ba                	add	a5,a5,a4
    800048ca:	639c                	ld	a5,0(a5)
    800048cc:	c38d                	beqz	a5,800048ee <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048ce:	4505                	li	a0,1
    800048d0:	9782                	jalr	a5
    800048d2:	892a                	mv	s2,a0
    800048d4:	bf75                	j	80004890 <fileread+0x60>
    panic("fileread");
    800048d6:	00004517          	auipc	a0,0x4
    800048da:	00250513          	addi	a0,a0,2 # 800088d8 <syscalls_str+0x260>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	c4c080e7          	jalr	-948(ra) # 8000052a <panic>
    return -1;
    800048e6:	597d                	li	s2,-1
    800048e8:	b765                	j	80004890 <fileread+0x60>
      return -1;
    800048ea:	597d                	li	s2,-1
    800048ec:	b755                	j	80004890 <fileread+0x60>
    800048ee:	597d                	li	s2,-1
    800048f0:	b745                	j	80004890 <fileread+0x60>

00000000800048f2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048f2:	715d                	addi	sp,sp,-80
    800048f4:	e486                	sd	ra,72(sp)
    800048f6:	e0a2                	sd	s0,64(sp)
    800048f8:	fc26                	sd	s1,56(sp)
    800048fa:	f84a                	sd	s2,48(sp)
    800048fc:	f44e                	sd	s3,40(sp)
    800048fe:	f052                	sd	s4,32(sp)
    80004900:	ec56                	sd	s5,24(sp)
    80004902:	e85a                	sd	s6,16(sp)
    80004904:	e45e                	sd	s7,8(sp)
    80004906:	e062                	sd	s8,0(sp)
    80004908:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000490a:	00954783          	lbu	a5,9(a0)
    8000490e:	10078663          	beqz	a5,80004a1a <filewrite+0x128>
    80004912:	892a                	mv	s2,a0
    80004914:	8aae                	mv	s5,a1
    80004916:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004918:	411c                	lw	a5,0(a0)
    8000491a:	4705                	li	a4,1
    8000491c:	02e78263          	beq	a5,a4,80004940 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004920:	470d                	li	a4,3
    80004922:	02e78663          	beq	a5,a4,8000494e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004926:	4709                	li	a4,2
    80004928:	0ee79163          	bne	a5,a4,80004a0a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000492c:	0ac05d63          	blez	a2,800049e6 <filewrite+0xf4>
    int i = 0;
    80004930:	4981                	li	s3,0
    80004932:	6b05                	lui	s6,0x1
    80004934:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004938:	6b85                	lui	s7,0x1
    8000493a:	c00b8b9b          	addiw	s7,s7,-1024
    8000493e:	a861                	j	800049d6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004940:	6908                	ld	a0,16(a0)
    80004942:	00000097          	auipc	ra,0x0
    80004946:	22e080e7          	jalr	558(ra) # 80004b70 <pipewrite>
    8000494a:	8a2a                	mv	s4,a0
    8000494c:	a045                	j	800049ec <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000494e:	02451783          	lh	a5,36(a0)
    80004952:	03079693          	slli	a3,a5,0x30
    80004956:	92c1                	srli	a3,a3,0x30
    80004958:	4725                	li	a4,9
    8000495a:	0cd76263          	bltu	a4,a3,80004a1e <filewrite+0x12c>
    8000495e:	0792                	slli	a5,a5,0x4
    80004960:	0001d717          	auipc	a4,0x1d
    80004964:	fb870713          	addi	a4,a4,-72 # 80021918 <devsw>
    80004968:	97ba                	add	a5,a5,a4
    8000496a:	679c                	ld	a5,8(a5)
    8000496c:	cbdd                	beqz	a5,80004a22 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000496e:	4505                	li	a0,1
    80004970:	9782                	jalr	a5
    80004972:	8a2a                	mv	s4,a0
    80004974:	a8a5                	j	800049ec <filewrite+0xfa>
    80004976:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	8b0080e7          	jalr	-1872(ra) # 8000422a <begin_op>
      ilock(f->ip);
    80004982:	01893503          	ld	a0,24(s2)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	ece080e7          	jalr	-306(ra) # 80003854 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000498e:	8762                	mv	a4,s8
    80004990:	02092683          	lw	a3,32(s2)
    80004994:	01598633          	add	a2,s3,s5
    80004998:	4585                	li	a1,1
    8000499a:	01893503          	ld	a0,24(s2)
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	262080e7          	jalr	610(ra) # 80003c00 <writei>
    800049a6:	84aa                	mv	s1,a0
    800049a8:	00a05763          	blez	a0,800049b6 <filewrite+0xc4>
        f->off += r;
    800049ac:	02092783          	lw	a5,32(s2)
    800049b0:	9fa9                	addw	a5,a5,a0
    800049b2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049b6:	01893503          	ld	a0,24(s2)
    800049ba:	fffff097          	auipc	ra,0xfffff
    800049be:	f5c080e7          	jalr	-164(ra) # 80003916 <iunlock>
      end_op();
    800049c2:	00000097          	auipc	ra,0x0
    800049c6:	8e8080e7          	jalr	-1816(ra) # 800042aa <end_op>

      if(r != n1){
    800049ca:	009c1f63          	bne	s8,s1,800049e8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049ce:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049d2:	0149db63          	bge	s3,s4,800049e8 <filewrite+0xf6>
      int n1 = n - i;
    800049d6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049da:	84be                	mv	s1,a5
    800049dc:	2781                	sext.w	a5,a5
    800049de:	f8fb5ce3          	bge	s6,a5,80004976 <filewrite+0x84>
    800049e2:	84de                	mv	s1,s7
    800049e4:	bf49                	j	80004976 <filewrite+0x84>
    int i = 0;
    800049e6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049e8:	013a1f63          	bne	s4,s3,80004a06 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049ec:	8552                	mv	a0,s4
    800049ee:	60a6                	ld	ra,72(sp)
    800049f0:	6406                	ld	s0,64(sp)
    800049f2:	74e2                	ld	s1,56(sp)
    800049f4:	7942                	ld	s2,48(sp)
    800049f6:	79a2                	ld	s3,40(sp)
    800049f8:	7a02                	ld	s4,32(sp)
    800049fa:	6ae2                	ld	s5,24(sp)
    800049fc:	6b42                	ld	s6,16(sp)
    800049fe:	6ba2                	ld	s7,8(sp)
    80004a00:	6c02                	ld	s8,0(sp)
    80004a02:	6161                	addi	sp,sp,80
    80004a04:	8082                	ret
    ret = (i == n ? n : -1);
    80004a06:	5a7d                	li	s4,-1
    80004a08:	b7d5                	j	800049ec <filewrite+0xfa>
    panic("filewrite");
    80004a0a:	00004517          	auipc	a0,0x4
    80004a0e:	ede50513          	addi	a0,a0,-290 # 800088e8 <syscalls_str+0x270>
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	b18080e7          	jalr	-1256(ra) # 8000052a <panic>
    return -1;
    80004a1a:	5a7d                	li	s4,-1
    80004a1c:	bfc1                	j	800049ec <filewrite+0xfa>
      return -1;
    80004a1e:	5a7d                	li	s4,-1
    80004a20:	b7f1                	j	800049ec <filewrite+0xfa>
    80004a22:	5a7d                	li	s4,-1
    80004a24:	b7e1                	j	800049ec <filewrite+0xfa>

0000000080004a26 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a26:	7179                	addi	sp,sp,-48
    80004a28:	f406                	sd	ra,40(sp)
    80004a2a:	f022                	sd	s0,32(sp)
    80004a2c:	ec26                	sd	s1,24(sp)
    80004a2e:	e84a                	sd	s2,16(sp)
    80004a30:	e44e                	sd	s3,8(sp)
    80004a32:	e052                	sd	s4,0(sp)
    80004a34:	1800                	addi	s0,sp,48
    80004a36:	84aa                	mv	s1,a0
    80004a38:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a3a:	0005b023          	sd	zero,0(a1)
    80004a3e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a42:	00000097          	auipc	ra,0x0
    80004a46:	bf8080e7          	jalr	-1032(ra) # 8000463a <filealloc>
    80004a4a:	e088                	sd	a0,0(s1)
    80004a4c:	c551                	beqz	a0,80004ad8 <pipealloc+0xb2>
    80004a4e:	00000097          	auipc	ra,0x0
    80004a52:	bec080e7          	jalr	-1044(ra) # 8000463a <filealloc>
    80004a56:	00aa3023          	sd	a0,0(s4)
    80004a5a:	c92d                	beqz	a0,80004acc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	076080e7          	jalr	118(ra) # 80000ad2 <kalloc>
    80004a64:	892a                	mv	s2,a0
    80004a66:	c125                	beqz	a0,80004ac6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a68:	4985                	li	s3,1
    80004a6a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a6e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a72:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a76:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a7a:	00004597          	auipc	a1,0x4
    80004a7e:	e7e58593          	addi	a1,a1,-386 # 800088f8 <syscalls_str+0x280>
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	0b0080e7          	jalr	176(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004a8a:	609c                	ld	a5,0(s1)
    80004a8c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a90:	609c                	ld	a5,0(s1)
    80004a92:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a96:	609c                	ld	a5,0(s1)
    80004a98:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a9c:	609c                	ld	a5,0(s1)
    80004a9e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004aa2:	000a3783          	ld	a5,0(s4)
    80004aa6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004aaa:	000a3783          	ld	a5,0(s4)
    80004aae:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ab2:	000a3783          	ld	a5,0(s4)
    80004ab6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aba:	000a3783          	ld	a5,0(s4)
    80004abe:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ac2:	4501                	li	a0,0
    80004ac4:	a025                	j	80004aec <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ac6:	6088                	ld	a0,0(s1)
    80004ac8:	e501                	bnez	a0,80004ad0 <pipealloc+0xaa>
    80004aca:	a039                	j	80004ad8 <pipealloc+0xb2>
    80004acc:	6088                	ld	a0,0(s1)
    80004ace:	c51d                	beqz	a0,80004afc <pipealloc+0xd6>
    fileclose(*f0);
    80004ad0:	00000097          	auipc	ra,0x0
    80004ad4:	c26080e7          	jalr	-986(ra) # 800046f6 <fileclose>
  if(*f1)
    80004ad8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004adc:	557d                	li	a0,-1
  if(*f1)
    80004ade:	c799                	beqz	a5,80004aec <pipealloc+0xc6>
    fileclose(*f1);
    80004ae0:	853e                	mv	a0,a5
    80004ae2:	00000097          	auipc	ra,0x0
    80004ae6:	c14080e7          	jalr	-1004(ra) # 800046f6 <fileclose>
  return -1;
    80004aea:	557d                	li	a0,-1
}
    80004aec:	70a2                	ld	ra,40(sp)
    80004aee:	7402                	ld	s0,32(sp)
    80004af0:	64e2                	ld	s1,24(sp)
    80004af2:	6942                	ld	s2,16(sp)
    80004af4:	69a2                	ld	s3,8(sp)
    80004af6:	6a02                	ld	s4,0(sp)
    80004af8:	6145                	addi	sp,sp,48
    80004afa:	8082                	ret
  return -1;
    80004afc:	557d                	li	a0,-1
    80004afe:	b7fd                	j	80004aec <pipealloc+0xc6>

0000000080004b00 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b00:	1101                	addi	sp,sp,-32
    80004b02:	ec06                	sd	ra,24(sp)
    80004b04:	e822                	sd	s0,16(sp)
    80004b06:	e426                	sd	s1,8(sp)
    80004b08:	e04a                	sd	s2,0(sp)
    80004b0a:	1000                	addi	s0,sp,32
    80004b0c:	84aa                	mv	s1,a0
    80004b0e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	0b2080e7          	jalr	178(ra) # 80000bc2 <acquire>
  if(writable){
    80004b18:	02090d63          	beqz	s2,80004b52 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b1c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b20:	21848513          	addi	a0,s1,536
    80004b24:	ffffd097          	auipc	ra,0xffffd
    80004b28:	736080e7          	jalr	1846(ra) # 8000225a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b2c:	2204b783          	ld	a5,544(s1)
    80004b30:	eb95                	bnez	a5,80004b64 <pipeclose+0x64>
    release(&pi->lock);
    80004b32:	8526                	mv	a0,s1
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	142080e7          	jalr	322(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004b3c:	8526                	mv	a0,s1
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	e98080e7          	jalr	-360(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004b46:	60e2                	ld	ra,24(sp)
    80004b48:	6442                	ld	s0,16(sp)
    80004b4a:	64a2                	ld	s1,8(sp)
    80004b4c:	6902                	ld	s2,0(sp)
    80004b4e:	6105                	addi	sp,sp,32
    80004b50:	8082                	ret
    pi->readopen = 0;
    80004b52:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b56:	21c48513          	addi	a0,s1,540
    80004b5a:	ffffd097          	auipc	ra,0xffffd
    80004b5e:	700080e7          	jalr	1792(ra) # 8000225a <wakeup>
    80004b62:	b7e9                	j	80004b2c <pipeclose+0x2c>
    release(&pi->lock);
    80004b64:	8526                	mv	a0,s1
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	110080e7          	jalr	272(ra) # 80000c76 <release>
}
    80004b6e:	bfe1                	j	80004b46 <pipeclose+0x46>

0000000080004b70 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b70:	711d                	addi	sp,sp,-96
    80004b72:	ec86                	sd	ra,88(sp)
    80004b74:	e8a2                	sd	s0,80(sp)
    80004b76:	e4a6                	sd	s1,72(sp)
    80004b78:	e0ca                	sd	s2,64(sp)
    80004b7a:	fc4e                	sd	s3,56(sp)
    80004b7c:	f852                	sd	s4,48(sp)
    80004b7e:	f456                	sd	s5,40(sp)
    80004b80:	f05a                	sd	s6,32(sp)
    80004b82:	ec5e                	sd	s7,24(sp)
    80004b84:	e862                	sd	s8,16(sp)
    80004b86:	1080                	addi	s0,sp,96
    80004b88:	84aa                	mv	s1,a0
    80004b8a:	8aae                	mv	s5,a1
    80004b8c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	e04080e7          	jalr	-508(ra) # 80001992 <myproc>
    80004b96:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	028080e7          	jalr	40(ra) # 80000bc2 <acquire>
  while(i < n){
    80004ba2:	0b405363          	blez	s4,80004c48 <pipewrite+0xd8>
  int i = 0;
    80004ba6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004baa:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bae:	21c48b93          	addi	s7,s1,540
    80004bb2:	a089                	j	80004bf4 <pipewrite+0x84>
      release(&pi->lock);
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	0c0080e7          	jalr	192(ra) # 80000c76 <release>
      return -1;
    80004bbe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bc0:	854a                	mv	a0,s2
    80004bc2:	60e6                	ld	ra,88(sp)
    80004bc4:	6446                	ld	s0,80(sp)
    80004bc6:	64a6                	ld	s1,72(sp)
    80004bc8:	6906                	ld	s2,64(sp)
    80004bca:	79e2                	ld	s3,56(sp)
    80004bcc:	7a42                	ld	s4,48(sp)
    80004bce:	7aa2                	ld	s5,40(sp)
    80004bd0:	7b02                	ld	s6,32(sp)
    80004bd2:	6be2                	ld	s7,24(sp)
    80004bd4:	6c42                	ld	s8,16(sp)
    80004bd6:	6125                	addi	sp,sp,96
    80004bd8:	8082                	ret
      wakeup(&pi->nread);
    80004bda:	8562                	mv	a0,s8
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	67e080e7          	jalr	1662(ra) # 8000225a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004be4:	85a6                	mv	a1,s1
    80004be6:	855e                	mv	a0,s7
    80004be8:	ffffd097          	auipc	ra,0xffffd
    80004bec:	4e6080e7          	jalr	1254(ra) # 800020ce <sleep>
  while(i < n){
    80004bf0:	05495d63          	bge	s2,s4,80004c4a <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004bf4:	2204a783          	lw	a5,544(s1)
    80004bf8:	dfd5                	beqz	a5,80004bb4 <pipewrite+0x44>
    80004bfa:	0289a783          	lw	a5,40(s3)
    80004bfe:	fbdd                	bnez	a5,80004bb4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c00:	2184a783          	lw	a5,536(s1)
    80004c04:	21c4a703          	lw	a4,540(s1)
    80004c08:	2007879b          	addiw	a5,a5,512
    80004c0c:	fcf707e3          	beq	a4,a5,80004bda <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c10:	4685                	li	a3,1
    80004c12:	01590633          	add	a2,s2,s5
    80004c16:	faf40593          	addi	a1,s0,-81
    80004c1a:	0509b503          	ld	a0,80(s3)
    80004c1e:	ffffd097          	auipc	ra,0xffffd
    80004c22:	aac080e7          	jalr	-1364(ra) # 800016ca <copyin>
    80004c26:	03650263          	beq	a0,s6,80004c4a <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c2a:	21c4a783          	lw	a5,540(s1)
    80004c2e:	0017871b          	addiw	a4,a5,1
    80004c32:	20e4ae23          	sw	a4,540(s1)
    80004c36:	1ff7f793          	andi	a5,a5,511
    80004c3a:	97a6                	add	a5,a5,s1
    80004c3c:	faf44703          	lbu	a4,-81(s0)
    80004c40:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c44:	2905                	addiw	s2,s2,1
    80004c46:	b76d                	j	80004bf0 <pipewrite+0x80>
  int i = 0;
    80004c48:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c4a:	21848513          	addi	a0,s1,536
    80004c4e:	ffffd097          	auipc	ra,0xffffd
    80004c52:	60c080e7          	jalr	1548(ra) # 8000225a <wakeup>
  release(&pi->lock);
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	01e080e7          	jalr	30(ra) # 80000c76 <release>
  return i;
    80004c60:	b785                	j	80004bc0 <pipewrite+0x50>

0000000080004c62 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c62:	715d                	addi	sp,sp,-80
    80004c64:	e486                	sd	ra,72(sp)
    80004c66:	e0a2                	sd	s0,64(sp)
    80004c68:	fc26                	sd	s1,56(sp)
    80004c6a:	f84a                	sd	s2,48(sp)
    80004c6c:	f44e                	sd	s3,40(sp)
    80004c6e:	f052                	sd	s4,32(sp)
    80004c70:	ec56                	sd	s5,24(sp)
    80004c72:	e85a                	sd	s6,16(sp)
    80004c74:	0880                	addi	s0,sp,80
    80004c76:	84aa                	mv	s1,a0
    80004c78:	892e                	mv	s2,a1
    80004c7a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	d16080e7          	jalr	-746(ra) # 80001992 <myproc>
    80004c84:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	f3a080e7          	jalr	-198(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c90:	2184a703          	lw	a4,536(s1)
    80004c94:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c98:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c9c:	02f71463          	bne	a4,a5,80004cc4 <piperead+0x62>
    80004ca0:	2244a783          	lw	a5,548(s1)
    80004ca4:	c385                	beqz	a5,80004cc4 <piperead+0x62>
    if(pr->killed){
    80004ca6:	028a2783          	lw	a5,40(s4)
    80004caa:	ebc1                	bnez	a5,80004d3a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cac:	85a6                	mv	a1,s1
    80004cae:	854e                	mv	a0,s3
    80004cb0:	ffffd097          	auipc	ra,0xffffd
    80004cb4:	41e080e7          	jalr	1054(ra) # 800020ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb8:	2184a703          	lw	a4,536(s1)
    80004cbc:	21c4a783          	lw	a5,540(s1)
    80004cc0:	fef700e3          	beq	a4,a5,80004ca0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cc6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc8:	05505363          	blez	s5,80004d0e <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004ccc:	2184a783          	lw	a5,536(s1)
    80004cd0:	21c4a703          	lw	a4,540(s1)
    80004cd4:	02f70d63          	beq	a4,a5,80004d0e <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cd8:	0017871b          	addiw	a4,a5,1
    80004cdc:	20e4ac23          	sw	a4,536(s1)
    80004ce0:	1ff7f793          	andi	a5,a5,511
    80004ce4:	97a6                	add	a5,a5,s1
    80004ce6:	0187c783          	lbu	a5,24(a5)
    80004cea:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cee:	4685                	li	a3,1
    80004cf0:	fbf40613          	addi	a2,s0,-65
    80004cf4:	85ca                	mv	a1,s2
    80004cf6:	050a3503          	ld	a0,80(s4)
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	944080e7          	jalr	-1724(ra) # 8000163e <copyout>
    80004d02:	01650663          	beq	a0,s6,80004d0e <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d06:	2985                	addiw	s3,s3,1
    80004d08:	0905                	addi	s2,s2,1
    80004d0a:	fd3a91e3          	bne	s5,s3,80004ccc <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d0e:	21c48513          	addi	a0,s1,540
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	548080e7          	jalr	1352(ra) # 8000225a <wakeup>
  release(&pi->lock);
    80004d1a:	8526                	mv	a0,s1
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	f5a080e7          	jalr	-166(ra) # 80000c76 <release>
  return i;
}
    80004d24:	854e                	mv	a0,s3
    80004d26:	60a6                	ld	ra,72(sp)
    80004d28:	6406                	ld	s0,64(sp)
    80004d2a:	74e2                	ld	s1,56(sp)
    80004d2c:	7942                	ld	s2,48(sp)
    80004d2e:	79a2                	ld	s3,40(sp)
    80004d30:	7a02                	ld	s4,32(sp)
    80004d32:	6ae2                	ld	s5,24(sp)
    80004d34:	6b42                	ld	s6,16(sp)
    80004d36:	6161                	addi	sp,sp,80
    80004d38:	8082                	ret
      release(&pi->lock);
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	f3a080e7          	jalr	-198(ra) # 80000c76 <release>
      return -1;
    80004d44:	59fd                	li	s3,-1
    80004d46:	bff9                	j	80004d24 <piperead+0xc2>

0000000080004d48 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d48:	de010113          	addi	sp,sp,-544
    80004d4c:	20113c23          	sd	ra,536(sp)
    80004d50:	20813823          	sd	s0,528(sp)
    80004d54:	20913423          	sd	s1,520(sp)
    80004d58:	21213023          	sd	s2,512(sp)
    80004d5c:	ffce                	sd	s3,504(sp)
    80004d5e:	fbd2                	sd	s4,496(sp)
    80004d60:	f7d6                	sd	s5,488(sp)
    80004d62:	f3da                	sd	s6,480(sp)
    80004d64:	efde                	sd	s7,472(sp)
    80004d66:	ebe2                	sd	s8,464(sp)
    80004d68:	e7e6                	sd	s9,456(sp)
    80004d6a:	e3ea                	sd	s10,448(sp)
    80004d6c:	ff6e                	sd	s11,440(sp)
    80004d6e:	1400                	addi	s0,sp,544
    80004d70:	892a                	mv	s2,a0
    80004d72:	dea43423          	sd	a0,-536(s0)
    80004d76:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	c18080e7          	jalr	-1000(ra) # 80001992 <myproc>
    80004d82:	84aa                	mv	s1,a0

  begin_op();
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	4a6080e7          	jalr	1190(ra) # 8000422a <begin_op>

  if((ip = namei(path)) == 0){
    80004d8c:	854a                	mv	a0,s2
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	27c080e7          	jalr	636(ra) # 8000400a <namei>
    80004d96:	c93d                	beqz	a0,80004e0c <exec+0xc4>
    80004d98:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	aba080e7          	jalr	-1350(ra) # 80003854 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004da2:	04000713          	li	a4,64
    80004da6:	4681                	li	a3,0
    80004da8:	e4840613          	addi	a2,s0,-440
    80004dac:	4581                	li	a1,0
    80004dae:	8556                	mv	a0,s5
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	d58080e7          	jalr	-680(ra) # 80003b08 <readi>
    80004db8:	04000793          	li	a5,64
    80004dbc:	00f51a63          	bne	a0,a5,80004dd0 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dc0:	e4842703          	lw	a4,-440(s0)
    80004dc4:	464c47b7          	lui	a5,0x464c4
    80004dc8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dcc:	04f70663          	beq	a4,a5,80004e18 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dd0:	8556                	mv	a0,s5
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	ce4080e7          	jalr	-796(ra) # 80003ab6 <iunlockput>
    end_op();
    80004dda:	fffff097          	auipc	ra,0xfffff
    80004dde:	4d0080e7          	jalr	1232(ra) # 800042aa <end_op>
  }
  return -1;
    80004de2:	557d                	li	a0,-1
}
    80004de4:	21813083          	ld	ra,536(sp)
    80004de8:	21013403          	ld	s0,528(sp)
    80004dec:	20813483          	ld	s1,520(sp)
    80004df0:	20013903          	ld	s2,512(sp)
    80004df4:	79fe                	ld	s3,504(sp)
    80004df6:	7a5e                	ld	s4,496(sp)
    80004df8:	7abe                	ld	s5,488(sp)
    80004dfa:	7b1e                	ld	s6,480(sp)
    80004dfc:	6bfe                	ld	s7,472(sp)
    80004dfe:	6c5e                	ld	s8,464(sp)
    80004e00:	6cbe                	ld	s9,456(sp)
    80004e02:	6d1e                	ld	s10,448(sp)
    80004e04:	7dfa                	ld	s11,440(sp)
    80004e06:	22010113          	addi	sp,sp,544
    80004e0a:	8082                	ret
    end_op();
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	49e080e7          	jalr	1182(ra) # 800042aa <end_op>
    return -1;
    80004e14:	557d                	li	a0,-1
    80004e16:	b7f9                	j	80004de4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e18:	8526                	mv	a0,s1
    80004e1a:	ffffd097          	auipc	ra,0xffffd
    80004e1e:	c3c080e7          	jalr	-964(ra) # 80001a56 <proc_pagetable>
    80004e22:	8b2a                	mv	s6,a0
    80004e24:	d555                	beqz	a0,80004dd0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e26:	e6842783          	lw	a5,-408(s0)
    80004e2a:	e8045703          	lhu	a4,-384(s0)
    80004e2e:	c735                	beqz	a4,80004e9a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e30:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e32:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e36:	6a05                	lui	s4,0x1
    80004e38:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e3c:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e40:	6d85                	lui	s11,0x1
    80004e42:	7d7d                	lui	s10,0xfffff
    80004e44:	ac1d                	j	8000507a <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e46:	00004517          	auipc	a0,0x4
    80004e4a:	aba50513          	addi	a0,a0,-1350 # 80008900 <syscalls_str+0x288>
    80004e4e:	ffffb097          	auipc	ra,0xffffb
    80004e52:	6dc080e7          	jalr	1756(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e56:	874a                	mv	a4,s2
    80004e58:	009c86bb          	addw	a3,s9,s1
    80004e5c:	4581                	li	a1,0
    80004e5e:	8556                	mv	a0,s5
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	ca8080e7          	jalr	-856(ra) # 80003b08 <readi>
    80004e68:	2501                	sext.w	a0,a0
    80004e6a:	1aa91863          	bne	s2,a0,8000501a <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e6e:	009d84bb          	addw	s1,s11,s1
    80004e72:	013d09bb          	addw	s3,s10,s3
    80004e76:	1f74f263          	bgeu	s1,s7,8000505a <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e7a:	02049593          	slli	a1,s1,0x20
    80004e7e:	9181                	srli	a1,a1,0x20
    80004e80:	95e2                	add	a1,a1,s8
    80004e82:	855a                	mv	a0,s6
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	1c8080e7          	jalr	456(ra) # 8000104c <walkaddr>
    80004e8c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e8e:	dd45                	beqz	a0,80004e46 <exec+0xfe>
      n = PGSIZE;
    80004e90:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e92:	fd49f2e3          	bgeu	s3,s4,80004e56 <exec+0x10e>
      n = sz - i;
    80004e96:	894e                	mv	s2,s3
    80004e98:	bf7d                	j	80004e56 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e9a:	4481                	li	s1,0
  iunlockput(ip);
    80004e9c:	8556                	mv	a0,s5
    80004e9e:	fffff097          	auipc	ra,0xfffff
    80004ea2:	c18080e7          	jalr	-1000(ra) # 80003ab6 <iunlockput>
  end_op();
    80004ea6:	fffff097          	auipc	ra,0xfffff
    80004eaa:	404080e7          	jalr	1028(ra) # 800042aa <end_op>
  p = myproc();
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	ae4080e7          	jalr	-1308(ra) # 80001992 <myproc>
    80004eb6:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004eb8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ebc:	6785                	lui	a5,0x1
    80004ebe:	17fd                	addi	a5,a5,-1
    80004ec0:	94be                	add	s1,s1,a5
    80004ec2:	77fd                	lui	a5,0xfffff
    80004ec4:	8fe5                	and	a5,a5,s1
    80004ec6:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eca:	6609                	lui	a2,0x2
    80004ecc:	963e                	add	a2,a2,a5
    80004ece:	85be                	mv	a1,a5
    80004ed0:	855a                	mv	a0,s6
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	51c080e7          	jalr	1308(ra) # 800013ee <uvmalloc>
    80004eda:	8c2a                	mv	s8,a0
  ip = 0;
    80004edc:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ede:	12050e63          	beqz	a0,8000501a <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ee2:	75f9                	lui	a1,0xffffe
    80004ee4:	95aa                	add	a1,a1,a0
    80004ee6:	855a                	mv	a0,s6
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	724080e7          	jalr	1828(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004ef0:	7afd                	lui	s5,0xfffff
    80004ef2:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ef4:	df043783          	ld	a5,-528(s0)
    80004ef8:	6388                	ld	a0,0(a5)
    80004efa:	c925                	beqz	a0,80004f6a <exec+0x222>
    80004efc:	e8840993          	addi	s3,s0,-376
    80004f00:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f04:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f06:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f08:	ffffc097          	auipc	ra,0xffffc
    80004f0c:	f3a080e7          	jalr	-198(ra) # 80000e42 <strlen>
    80004f10:	0015079b          	addiw	a5,a0,1
    80004f14:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f18:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f1c:	13596363          	bltu	s2,s5,80005042 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f20:	df043d83          	ld	s11,-528(s0)
    80004f24:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f28:	8552                	mv	a0,s4
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	f18080e7          	jalr	-232(ra) # 80000e42 <strlen>
    80004f32:	0015069b          	addiw	a3,a0,1
    80004f36:	8652                	mv	a2,s4
    80004f38:	85ca                	mv	a1,s2
    80004f3a:	855a                	mv	a0,s6
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	702080e7          	jalr	1794(ra) # 8000163e <copyout>
    80004f44:	10054363          	bltz	a0,8000504a <exec+0x302>
    ustack[argc] = sp;
    80004f48:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f4c:	0485                	addi	s1,s1,1
    80004f4e:	008d8793          	addi	a5,s11,8
    80004f52:	def43823          	sd	a5,-528(s0)
    80004f56:	008db503          	ld	a0,8(s11)
    80004f5a:	c911                	beqz	a0,80004f6e <exec+0x226>
    if(argc >= MAXARG)
    80004f5c:	09a1                	addi	s3,s3,8
    80004f5e:	fb3c95e3          	bne	s9,s3,80004f08 <exec+0x1c0>
  sz = sz1;
    80004f62:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f66:	4a81                	li	s5,0
    80004f68:	a84d                	j	8000501a <exec+0x2d2>
  sp = sz;
    80004f6a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f6c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f6e:	00349793          	slli	a5,s1,0x3
    80004f72:	f9040713          	addi	a4,s0,-112
    80004f76:	97ba                	add	a5,a5,a4
    80004f78:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f7c:	00148693          	addi	a3,s1,1
    80004f80:	068e                	slli	a3,a3,0x3
    80004f82:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f86:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f8a:	01597663          	bgeu	s2,s5,80004f96 <exec+0x24e>
  sz = sz1;
    80004f8e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f92:	4a81                	li	s5,0
    80004f94:	a059                	j	8000501a <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f96:	e8840613          	addi	a2,s0,-376
    80004f9a:	85ca                	mv	a1,s2
    80004f9c:	855a                	mv	a0,s6
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	6a0080e7          	jalr	1696(ra) # 8000163e <copyout>
    80004fa6:	0a054663          	bltz	a0,80005052 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004faa:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004fae:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fb2:	de843783          	ld	a5,-536(s0)
    80004fb6:	0007c703          	lbu	a4,0(a5)
    80004fba:	cf11                	beqz	a4,80004fd6 <exec+0x28e>
    80004fbc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fbe:	02f00693          	li	a3,47
    80004fc2:	a039                	j	80004fd0 <exec+0x288>
      last = s+1;
    80004fc4:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004fc8:	0785                	addi	a5,a5,1
    80004fca:	fff7c703          	lbu	a4,-1(a5)
    80004fce:	c701                	beqz	a4,80004fd6 <exec+0x28e>
    if(*s == '/')
    80004fd0:	fed71ce3          	bne	a4,a3,80004fc8 <exec+0x280>
    80004fd4:	bfc5                	j	80004fc4 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fd6:	4641                	li	a2,16
    80004fd8:	de843583          	ld	a1,-536(s0)
    80004fdc:	158b8513          	addi	a0,s7,344
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	e30080e7          	jalr	-464(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fe8:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fec:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ff0:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ff4:	058bb783          	ld	a5,88(s7)
    80004ff8:	e6043703          	ld	a4,-416(s0)
    80004ffc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ffe:	058bb783          	ld	a5,88(s7)
    80005002:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005006:	85ea                	mv	a1,s10
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	aea080e7          	jalr	-1302(ra) # 80001af2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005010:	0004851b          	sext.w	a0,s1
    80005014:	bbc1                	j	80004de4 <exec+0x9c>
    80005016:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000501a:	df843583          	ld	a1,-520(s0)
    8000501e:	855a                	mv	a0,s6
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	ad2080e7          	jalr	-1326(ra) # 80001af2 <proc_freepagetable>
  if(ip){
    80005028:	da0a94e3          	bnez	s5,80004dd0 <exec+0x88>
  return -1;
    8000502c:	557d                	li	a0,-1
    8000502e:	bb5d                	j	80004de4 <exec+0x9c>
    80005030:	de943c23          	sd	s1,-520(s0)
    80005034:	b7dd                	j	8000501a <exec+0x2d2>
    80005036:	de943c23          	sd	s1,-520(s0)
    8000503a:	b7c5                	j	8000501a <exec+0x2d2>
    8000503c:	de943c23          	sd	s1,-520(s0)
    80005040:	bfe9                	j	8000501a <exec+0x2d2>
  sz = sz1;
    80005042:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005046:	4a81                	li	s5,0
    80005048:	bfc9                	j	8000501a <exec+0x2d2>
  sz = sz1;
    8000504a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000504e:	4a81                	li	s5,0
    80005050:	b7e9                	j	8000501a <exec+0x2d2>
  sz = sz1;
    80005052:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005056:	4a81                	li	s5,0
    80005058:	b7c9                	j	8000501a <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000505a:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000505e:	e0843783          	ld	a5,-504(s0)
    80005062:	0017869b          	addiw	a3,a5,1
    80005066:	e0d43423          	sd	a3,-504(s0)
    8000506a:	e0043783          	ld	a5,-512(s0)
    8000506e:	0387879b          	addiw	a5,a5,56
    80005072:	e8045703          	lhu	a4,-384(s0)
    80005076:	e2e6d3e3          	bge	a3,a4,80004e9c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000507a:	2781                	sext.w	a5,a5
    8000507c:	e0f43023          	sd	a5,-512(s0)
    80005080:	03800713          	li	a4,56
    80005084:	86be                	mv	a3,a5
    80005086:	e1040613          	addi	a2,s0,-496
    8000508a:	4581                	li	a1,0
    8000508c:	8556                	mv	a0,s5
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	a7a080e7          	jalr	-1414(ra) # 80003b08 <readi>
    80005096:	03800793          	li	a5,56
    8000509a:	f6f51ee3          	bne	a0,a5,80005016 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000509e:	e1042783          	lw	a5,-496(s0)
    800050a2:	4705                	li	a4,1
    800050a4:	fae79de3          	bne	a5,a4,8000505e <exec+0x316>
    if(ph.memsz < ph.filesz)
    800050a8:	e3843603          	ld	a2,-456(s0)
    800050ac:	e3043783          	ld	a5,-464(s0)
    800050b0:	f8f660e3          	bltu	a2,a5,80005030 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050b4:	e2043783          	ld	a5,-480(s0)
    800050b8:	963e                	add	a2,a2,a5
    800050ba:	f6f66ee3          	bltu	a2,a5,80005036 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050be:	85a6                	mv	a1,s1
    800050c0:	855a                	mv	a0,s6
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	32c080e7          	jalr	812(ra) # 800013ee <uvmalloc>
    800050ca:	dea43c23          	sd	a0,-520(s0)
    800050ce:	d53d                	beqz	a0,8000503c <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800050d0:	e2043c03          	ld	s8,-480(s0)
    800050d4:	de043783          	ld	a5,-544(s0)
    800050d8:	00fc77b3          	and	a5,s8,a5
    800050dc:	ff9d                	bnez	a5,8000501a <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050de:	e1842c83          	lw	s9,-488(s0)
    800050e2:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050e6:	f60b8ae3          	beqz	s7,8000505a <exec+0x312>
    800050ea:	89de                	mv	s3,s7
    800050ec:	4481                	li	s1,0
    800050ee:	b371                	j	80004e7a <exec+0x132>

00000000800050f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050f0:	7179                	addi	sp,sp,-48
    800050f2:	f406                	sd	ra,40(sp)
    800050f4:	f022                	sd	s0,32(sp)
    800050f6:	ec26                	sd	s1,24(sp)
    800050f8:	e84a                	sd	s2,16(sp)
    800050fa:	1800                	addi	s0,sp,48
    800050fc:	892e                	mv	s2,a1
    800050fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005100:	fdc40593          	addi	a1,s0,-36
    80005104:	ffffe097          	auipc	ra,0xffffe
    80005108:	ae8080e7          	jalr	-1304(ra) # 80002bec <argint>
    8000510c:	04054063          	bltz	a0,8000514c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005110:	fdc42703          	lw	a4,-36(s0)
    80005114:	47bd                	li	a5,15
    80005116:	02e7ed63          	bltu	a5,a4,80005150 <argfd+0x60>
    8000511a:	ffffd097          	auipc	ra,0xffffd
    8000511e:	878080e7          	jalr	-1928(ra) # 80001992 <myproc>
    80005122:	fdc42703          	lw	a4,-36(s0)
    80005126:	01a70793          	addi	a5,a4,26
    8000512a:	078e                	slli	a5,a5,0x3
    8000512c:	953e                	add	a0,a0,a5
    8000512e:	611c                	ld	a5,0(a0)
    80005130:	c395                	beqz	a5,80005154 <argfd+0x64>
    return -1;
  if(pfd)
    80005132:	00090463          	beqz	s2,8000513a <argfd+0x4a>
    *pfd = fd;
    80005136:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000513a:	4501                	li	a0,0
  if(pf)
    8000513c:	c091                	beqz	s1,80005140 <argfd+0x50>
    *pf = f;
    8000513e:	e09c                	sd	a5,0(s1)
}
    80005140:	70a2                	ld	ra,40(sp)
    80005142:	7402                	ld	s0,32(sp)
    80005144:	64e2                	ld	s1,24(sp)
    80005146:	6942                	ld	s2,16(sp)
    80005148:	6145                	addi	sp,sp,48
    8000514a:	8082                	ret
    return -1;
    8000514c:	557d                	li	a0,-1
    8000514e:	bfcd                	j	80005140 <argfd+0x50>
    return -1;
    80005150:	557d                	li	a0,-1
    80005152:	b7fd                	j	80005140 <argfd+0x50>
    80005154:	557d                	li	a0,-1
    80005156:	b7ed                	j	80005140 <argfd+0x50>

0000000080005158 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005158:	1101                	addi	sp,sp,-32
    8000515a:	ec06                	sd	ra,24(sp)
    8000515c:	e822                	sd	s0,16(sp)
    8000515e:	e426                	sd	s1,8(sp)
    80005160:	1000                	addi	s0,sp,32
    80005162:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005164:	ffffd097          	auipc	ra,0xffffd
    80005168:	82e080e7          	jalr	-2002(ra) # 80001992 <myproc>
    8000516c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000516e:	0d050793          	addi	a5,a0,208
    80005172:	4501                	li	a0,0
    80005174:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005176:	6398                	ld	a4,0(a5)
    80005178:	cb19                	beqz	a4,8000518e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000517a:	2505                	addiw	a0,a0,1
    8000517c:	07a1                	addi	a5,a5,8
    8000517e:	fed51ce3          	bne	a0,a3,80005176 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005182:	557d                	li	a0,-1
}
    80005184:	60e2                	ld	ra,24(sp)
    80005186:	6442                	ld	s0,16(sp)
    80005188:	64a2                	ld	s1,8(sp)
    8000518a:	6105                	addi	sp,sp,32
    8000518c:	8082                	ret
      p->ofile[fd] = f;
    8000518e:	01a50793          	addi	a5,a0,26
    80005192:	078e                	slli	a5,a5,0x3
    80005194:	963e                	add	a2,a2,a5
    80005196:	e204                	sd	s1,0(a2)
      return fd;
    80005198:	b7f5                	j	80005184 <fdalloc+0x2c>

000000008000519a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000519a:	715d                	addi	sp,sp,-80
    8000519c:	e486                	sd	ra,72(sp)
    8000519e:	e0a2                	sd	s0,64(sp)
    800051a0:	fc26                	sd	s1,56(sp)
    800051a2:	f84a                	sd	s2,48(sp)
    800051a4:	f44e                	sd	s3,40(sp)
    800051a6:	f052                	sd	s4,32(sp)
    800051a8:	ec56                	sd	s5,24(sp)
    800051aa:	0880                	addi	s0,sp,80
    800051ac:	89ae                	mv	s3,a1
    800051ae:	8ab2                	mv	s5,a2
    800051b0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051b2:	fb040593          	addi	a1,s0,-80
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	e72080e7          	jalr	-398(ra) # 80004028 <nameiparent>
    800051be:	892a                	mv	s2,a0
    800051c0:	12050e63          	beqz	a0,800052fc <create+0x162>
    return 0;

  ilock(dp);
    800051c4:	ffffe097          	auipc	ra,0xffffe
    800051c8:	690080e7          	jalr	1680(ra) # 80003854 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051cc:	4601                	li	a2,0
    800051ce:	fb040593          	addi	a1,s0,-80
    800051d2:	854a                	mv	a0,s2
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	b64080e7          	jalr	-1180(ra) # 80003d38 <dirlookup>
    800051dc:	84aa                	mv	s1,a0
    800051de:	c921                	beqz	a0,8000522e <create+0x94>
    iunlockput(dp);
    800051e0:	854a                	mv	a0,s2
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	8d4080e7          	jalr	-1836(ra) # 80003ab6 <iunlockput>
    ilock(ip);
    800051ea:	8526                	mv	a0,s1
    800051ec:	ffffe097          	auipc	ra,0xffffe
    800051f0:	668080e7          	jalr	1640(ra) # 80003854 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051f4:	2981                	sext.w	s3,s3
    800051f6:	4789                	li	a5,2
    800051f8:	02f99463          	bne	s3,a5,80005220 <create+0x86>
    800051fc:	0444d783          	lhu	a5,68(s1)
    80005200:	37f9                	addiw	a5,a5,-2
    80005202:	17c2                	slli	a5,a5,0x30
    80005204:	93c1                	srli	a5,a5,0x30
    80005206:	4705                	li	a4,1
    80005208:	00f76c63          	bltu	a4,a5,80005220 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000520c:	8526                	mv	a0,s1
    8000520e:	60a6                	ld	ra,72(sp)
    80005210:	6406                	ld	s0,64(sp)
    80005212:	74e2                	ld	s1,56(sp)
    80005214:	7942                	ld	s2,48(sp)
    80005216:	79a2                	ld	s3,40(sp)
    80005218:	7a02                	ld	s4,32(sp)
    8000521a:	6ae2                	ld	s5,24(sp)
    8000521c:	6161                	addi	sp,sp,80
    8000521e:	8082                	ret
    iunlockput(ip);
    80005220:	8526                	mv	a0,s1
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	894080e7          	jalr	-1900(ra) # 80003ab6 <iunlockput>
    return 0;
    8000522a:	4481                	li	s1,0
    8000522c:	b7c5                	j	8000520c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000522e:	85ce                	mv	a1,s3
    80005230:	00092503          	lw	a0,0(s2)
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	488080e7          	jalr	1160(ra) # 800036bc <ialloc>
    8000523c:	84aa                	mv	s1,a0
    8000523e:	c521                	beqz	a0,80005286 <create+0xec>
  ilock(ip);
    80005240:	ffffe097          	auipc	ra,0xffffe
    80005244:	614080e7          	jalr	1556(ra) # 80003854 <ilock>
  ip->major = major;
    80005248:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000524c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005250:	4a05                	li	s4,1
    80005252:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005256:	8526                	mv	a0,s1
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	532080e7          	jalr	1330(ra) # 8000378a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005260:	2981                	sext.w	s3,s3
    80005262:	03498a63          	beq	s3,s4,80005296 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005266:	40d0                	lw	a2,4(s1)
    80005268:	fb040593          	addi	a1,s0,-80
    8000526c:	854a                	mv	a0,s2
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	cda080e7          	jalr	-806(ra) # 80003f48 <dirlink>
    80005276:	06054b63          	bltz	a0,800052ec <create+0x152>
  iunlockput(dp);
    8000527a:	854a                	mv	a0,s2
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	83a080e7          	jalr	-1990(ra) # 80003ab6 <iunlockput>
  return ip;
    80005284:	b761                	j	8000520c <create+0x72>
    panic("create: ialloc");
    80005286:	00003517          	auipc	a0,0x3
    8000528a:	69a50513          	addi	a0,a0,1690 # 80008920 <syscalls_str+0x2a8>
    8000528e:	ffffb097          	auipc	ra,0xffffb
    80005292:	29c080e7          	jalr	668(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005296:	04a95783          	lhu	a5,74(s2)
    8000529a:	2785                	addiw	a5,a5,1
    8000529c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052a0:	854a                	mv	a0,s2
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	4e8080e7          	jalr	1256(ra) # 8000378a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052aa:	40d0                	lw	a2,4(s1)
    800052ac:	00003597          	auipc	a1,0x3
    800052b0:	68458593          	addi	a1,a1,1668 # 80008930 <syscalls_str+0x2b8>
    800052b4:	8526                	mv	a0,s1
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	c92080e7          	jalr	-878(ra) # 80003f48 <dirlink>
    800052be:	00054f63          	bltz	a0,800052dc <create+0x142>
    800052c2:	00492603          	lw	a2,4(s2)
    800052c6:	00003597          	auipc	a1,0x3
    800052ca:	67258593          	addi	a1,a1,1650 # 80008938 <syscalls_str+0x2c0>
    800052ce:	8526                	mv	a0,s1
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	c78080e7          	jalr	-904(ra) # 80003f48 <dirlink>
    800052d8:	f80557e3          	bgez	a0,80005266 <create+0xcc>
      panic("create dots");
    800052dc:	00003517          	auipc	a0,0x3
    800052e0:	66450513          	addi	a0,a0,1636 # 80008940 <syscalls_str+0x2c8>
    800052e4:	ffffb097          	auipc	ra,0xffffb
    800052e8:	246080e7          	jalr	582(ra) # 8000052a <panic>
    panic("create: dirlink");
    800052ec:	00003517          	auipc	a0,0x3
    800052f0:	66450513          	addi	a0,a0,1636 # 80008950 <syscalls_str+0x2d8>
    800052f4:	ffffb097          	auipc	ra,0xffffb
    800052f8:	236080e7          	jalr	566(ra) # 8000052a <panic>
    return 0;
    800052fc:	84aa                	mv	s1,a0
    800052fe:	b739                	j	8000520c <create+0x72>

0000000080005300 <sys_dup>:
{
    80005300:	7179                	addi	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	ec26                	sd	s1,24(sp)
    80005308:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000530a:	fd840613          	addi	a2,s0,-40
    8000530e:	4581                	li	a1,0
    80005310:	4501                	li	a0,0
    80005312:	00000097          	auipc	ra,0x0
    80005316:	dde080e7          	jalr	-546(ra) # 800050f0 <argfd>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000531c:	02054363          	bltz	a0,80005342 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005320:	fd843503          	ld	a0,-40(s0)
    80005324:	00000097          	auipc	ra,0x0
    80005328:	e34080e7          	jalr	-460(ra) # 80005158 <fdalloc>
    8000532c:	84aa                	mv	s1,a0
    return -1;
    8000532e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005330:	00054963          	bltz	a0,80005342 <sys_dup+0x42>
  filedup(f);
    80005334:	fd843503          	ld	a0,-40(s0)
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	36c080e7          	jalr	876(ra) # 800046a4 <filedup>
  return fd;
    80005340:	87a6                	mv	a5,s1
}
    80005342:	853e                	mv	a0,a5
    80005344:	70a2                	ld	ra,40(sp)
    80005346:	7402                	ld	s0,32(sp)
    80005348:	64e2                	ld	s1,24(sp)
    8000534a:	6145                	addi	sp,sp,48
    8000534c:	8082                	ret

000000008000534e <sys_read>:
{
    8000534e:	7179                	addi	sp,sp,-48
    80005350:	f406                	sd	ra,40(sp)
    80005352:	f022                	sd	s0,32(sp)
    80005354:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005356:	fe840613          	addi	a2,s0,-24
    8000535a:	4581                	li	a1,0
    8000535c:	4501                	li	a0,0
    8000535e:	00000097          	auipc	ra,0x0
    80005362:	d92080e7          	jalr	-622(ra) # 800050f0 <argfd>
    return -1;
    80005366:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005368:	04054163          	bltz	a0,800053aa <sys_read+0x5c>
    8000536c:	fe440593          	addi	a1,s0,-28
    80005370:	4509                	li	a0,2
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	87a080e7          	jalr	-1926(ra) # 80002bec <argint>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537c:	02054763          	bltz	a0,800053aa <sys_read+0x5c>
    80005380:	fd840593          	addi	a1,s0,-40
    80005384:	4505                	li	a0,1
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	888080e7          	jalr	-1912(ra) # 80002c0e <argaddr>
    return -1;
    8000538e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005390:	00054d63          	bltz	a0,800053aa <sys_read+0x5c>
  return fileread(f, p, n);
    80005394:	fe442603          	lw	a2,-28(s0)
    80005398:	fd843583          	ld	a1,-40(s0)
    8000539c:	fe843503          	ld	a0,-24(s0)
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	490080e7          	jalr	1168(ra) # 80004830 <fileread>
    800053a8:	87aa                	mv	a5,a0
}
    800053aa:	853e                	mv	a0,a5
    800053ac:	70a2                	ld	ra,40(sp)
    800053ae:	7402                	ld	s0,32(sp)
    800053b0:	6145                	addi	sp,sp,48
    800053b2:	8082                	ret

00000000800053b4 <sys_write>:
{
    800053b4:	7179                	addi	sp,sp,-48
    800053b6:	f406                	sd	ra,40(sp)
    800053b8:	f022                	sd	s0,32(sp)
    800053ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053bc:	fe840613          	addi	a2,s0,-24
    800053c0:	4581                	li	a1,0
    800053c2:	4501                	li	a0,0
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	d2c080e7          	jalr	-724(ra) # 800050f0 <argfd>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ce:	04054163          	bltz	a0,80005410 <sys_write+0x5c>
    800053d2:	fe440593          	addi	a1,s0,-28
    800053d6:	4509                	li	a0,2
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	814080e7          	jalr	-2028(ra) # 80002bec <argint>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e2:	02054763          	bltz	a0,80005410 <sys_write+0x5c>
    800053e6:	fd840593          	addi	a1,s0,-40
    800053ea:	4505                	li	a0,1
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	822080e7          	jalr	-2014(ra) # 80002c0e <argaddr>
    return -1;
    800053f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f6:	00054d63          	bltz	a0,80005410 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053fa:	fe442603          	lw	a2,-28(s0)
    800053fe:	fd843583          	ld	a1,-40(s0)
    80005402:	fe843503          	ld	a0,-24(s0)
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	4ec080e7          	jalr	1260(ra) # 800048f2 <filewrite>
    8000540e:	87aa                	mv	a5,a0
}
    80005410:	853e                	mv	a0,a5
    80005412:	70a2                	ld	ra,40(sp)
    80005414:	7402                	ld	s0,32(sp)
    80005416:	6145                	addi	sp,sp,48
    80005418:	8082                	ret

000000008000541a <sys_close>:
{
    8000541a:	1101                	addi	sp,sp,-32
    8000541c:	ec06                	sd	ra,24(sp)
    8000541e:	e822                	sd	s0,16(sp)
    80005420:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005422:	fe040613          	addi	a2,s0,-32
    80005426:	fec40593          	addi	a1,s0,-20
    8000542a:	4501                	li	a0,0
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	cc4080e7          	jalr	-828(ra) # 800050f0 <argfd>
    return -1;
    80005434:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005436:	02054463          	bltz	a0,8000545e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000543a:	ffffc097          	auipc	ra,0xffffc
    8000543e:	558080e7          	jalr	1368(ra) # 80001992 <myproc>
    80005442:	fec42783          	lw	a5,-20(s0)
    80005446:	07e9                	addi	a5,a5,26
    80005448:	078e                	slli	a5,a5,0x3
    8000544a:	97aa                	add	a5,a5,a0
    8000544c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005450:	fe043503          	ld	a0,-32(s0)
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	2a2080e7          	jalr	674(ra) # 800046f6 <fileclose>
  return 0;
    8000545c:	4781                	li	a5,0
}
    8000545e:	853e                	mv	a0,a5
    80005460:	60e2                	ld	ra,24(sp)
    80005462:	6442                	ld	s0,16(sp)
    80005464:	6105                	addi	sp,sp,32
    80005466:	8082                	ret

0000000080005468 <sys_fstat>:
{
    80005468:	1101                	addi	sp,sp,-32
    8000546a:	ec06                	sd	ra,24(sp)
    8000546c:	e822                	sd	s0,16(sp)
    8000546e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005470:	fe840613          	addi	a2,s0,-24
    80005474:	4581                	li	a1,0
    80005476:	4501                	li	a0,0
    80005478:	00000097          	auipc	ra,0x0
    8000547c:	c78080e7          	jalr	-904(ra) # 800050f0 <argfd>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005482:	02054563          	bltz	a0,800054ac <sys_fstat+0x44>
    80005486:	fe040593          	addi	a1,s0,-32
    8000548a:	4505                	li	a0,1
    8000548c:	ffffd097          	auipc	ra,0xffffd
    80005490:	782080e7          	jalr	1922(ra) # 80002c0e <argaddr>
    return -1;
    80005494:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005496:	00054b63          	bltz	a0,800054ac <sys_fstat+0x44>
  return filestat(f, st);
    8000549a:	fe043583          	ld	a1,-32(s0)
    8000549e:	fe843503          	ld	a0,-24(s0)
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	31c080e7          	jalr	796(ra) # 800047be <filestat>
    800054aa:	87aa                	mv	a5,a0
}
    800054ac:	853e                	mv	a0,a5
    800054ae:	60e2                	ld	ra,24(sp)
    800054b0:	6442                	ld	s0,16(sp)
    800054b2:	6105                	addi	sp,sp,32
    800054b4:	8082                	ret

00000000800054b6 <sys_link>:
{
    800054b6:	7169                	addi	sp,sp,-304
    800054b8:	f606                	sd	ra,296(sp)
    800054ba:	f222                	sd	s0,288(sp)
    800054bc:	ee26                	sd	s1,280(sp)
    800054be:	ea4a                	sd	s2,272(sp)
    800054c0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c2:	08000613          	li	a2,128
    800054c6:	ed040593          	addi	a1,s0,-304
    800054ca:	4501                	li	a0,0
    800054cc:	ffffd097          	auipc	ra,0xffffd
    800054d0:	764080e7          	jalr	1892(ra) # 80002c30 <argstr>
    return -1;
    800054d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d6:	10054e63          	bltz	a0,800055f2 <sys_link+0x13c>
    800054da:	08000613          	li	a2,128
    800054de:	f5040593          	addi	a1,s0,-176
    800054e2:	4505                	li	a0,1
    800054e4:	ffffd097          	auipc	ra,0xffffd
    800054e8:	74c080e7          	jalr	1868(ra) # 80002c30 <argstr>
    return -1;
    800054ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ee:	10054263          	bltz	a0,800055f2 <sys_link+0x13c>
  begin_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	d38080e7          	jalr	-712(ra) # 8000422a <begin_op>
  if((ip = namei(old)) == 0){
    800054fa:	ed040513          	addi	a0,s0,-304
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	b0c080e7          	jalr	-1268(ra) # 8000400a <namei>
    80005506:	84aa                	mv	s1,a0
    80005508:	c551                	beqz	a0,80005594 <sys_link+0xde>
  ilock(ip);
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	34a080e7          	jalr	842(ra) # 80003854 <ilock>
  if(ip->type == T_DIR){
    80005512:	04449703          	lh	a4,68(s1)
    80005516:	4785                	li	a5,1
    80005518:	08f70463          	beq	a4,a5,800055a0 <sys_link+0xea>
  ip->nlink++;
    8000551c:	04a4d783          	lhu	a5,74(s1)
    80005520:	2785                	addiw	a5,a5,1
    80005522:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	262080e7          	jalr	610(ra) # 8000378a <iupdate>
  iunlock(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	3e4080e7          	jalr	996(ra) # 80003916 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000553a:	fd040593          	addi	a1,s0,-48
    8000553e:	f5040513          	addi	a0,s0,-176
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	ae6080e7          	jalr	-1306(ra) # 80004028 <nameiparent>
    8000554a:	892a                	mv	s2,a0
    8000554c:	c935                	beqz	a0,800055c0 <sys_link+0x10a>
  ilock(dp);
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	306080e7          	jalr	774(ra) # 80003854 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005556:	00092703          	lw	a4,0(s2)
    8000555a:	409c                	lw	a5,0(s1)
    8000555c:	04f71d63          	bne	a4,a5,800055b6 <sys_link+0x100>
    80005560:	40d0                	lw	a2,4(s1)
    80005562:	fd040593          	addi	a1,s0,-48
    80005566:	854a                	mv	a0,s2
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	9e0080e7          	jalr	-1568(ra) # 80003f48 <dirlink>
    80005570:	04054363          	bltz	a0,800055b6 <sys_link+0x100>
  iunlockput(dp);
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	540080e7          	jalr	1344(ra) # 80003ab6 <iunlockput>
  iput(ip);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	48e080e7          	jalr	1166(ra) # 80003a0e <iput>
  end_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	d22080e7          	jalr	-734(ra) # 800042aa <end_op>
  return 0;
    80005590:	4781                	li	a5,0
    80005592:	a085                	j	800055f2 <sys_link+0x13c>
    end_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	d16080e7          	jalr	-746(ra) # 800042aa <end_op>
    return -1;
    8000559c:	57fd                	li	a5,-1
    8000559e:	a891                	j	800055f2 <sys_link+0x13c>
    iunlockput(ip);
    800055a0:	8526                	mv	a0,s1
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	514080e7          	jalr	1300(ra) # 80003ab6 <iunlockput>
    end_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	d00080e7          	jalr	-768(ra) # 800042aa <end_op>
    return -1;
    800055b2:	57fd                	li	a5,-1
    800055b4:	a83d                	j	800055f2 <sys_link+0x13c>
    iunlockput(dp);
    800055b6:	854a                	mv	a0,s2
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	4fe080e7          	jalr	1278(ra) # 80003ab6 <iunlockput>
  ilock(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	292080e7          	jalr	658(ra) # 80003854 <ilock>
  ip->nlink--;
    800055ca:	04a4d783          	lhu	a5,74(s1)
    800055ce:	37fd                	addiw	a5,a5,-1
    800055d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	1b4080e7          	jalr	436(ra) # 8000378a <iupdate>
  iunlockput(ip);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	4d6080e7          	jalr	1238(ra) # 80003ab6 <iunlockput>
  end_op();
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	cc2080e7          	jalr	-830(ra) # 800042aa <end_op>
  return -1;
    800055f0:	57fd                	li	a5,-1
}
    800055f2:	853e                	mv	a0,a5
    800055f4:	70b2                	ld	ra,296(sp)
    800055f6:	7412                	ld	s0,288(sp)
    800055f8:	64f2                	ld	s1,280(sp)
    800055fa:	6952                	ld	s2,272(sp)
    800055fc:	6155                	addi	sp,sp,304
    800055fe:	8082                	ret

0000000080005600 <sys_unlink>:
{
    80005600:	7151                	addi	sp,sp,-240
    80005602:	f586                	sd	ra,232(sp)
    80005604:	f1a2                	sd	s0,224(sp)
    80005606:	eda6                	sd	s1,216(sp)
    80005608:	e9ca                	sd	s2,208(sp)
    8000560a:	e5ce                	sd	s3,200(sp)
    8000560c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000560e:	08000613          	li	a2,128
    80005612:	f3040593          	addi	a1,s0,-208
    80005616:	4501                	li	a0,0
    80005618:	ffffd097          	auipc	ra,0xffffd
    8000561c:	618080e7          	jalr	1560(ra) # 80002c30 <argstr>
    80005620:	18054163          	bltz	a0,800057a2 <sys_unlink+0x1a2>
  begin_op();
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	c06080e7          	jalr	-1018(ra) # 8000422a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000562c:	fb040593          	addi	a1,s0,-80
    80005630:	f3040513          	addi	a0,s0,-208
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	9f4080e7          	jalr	-1548(ra) # 80004028 <nameiparent>
    8000563c:	84aa                	mv	s1,a0
    8000563e:	c979                	beqz	a0,80005714 <sys_unlink+0x114>
  ilock(dp);
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	214080e7          	jalr	532(ra) # 80003854 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005648:	00003597          	auipc	a1,0x3
    8000564c:	2e858593          	addi	a1,a1,744 # 80008930 <syscalls_str+0x2b8>
    80005650:	fb040513          	addi	a0,s0,-80
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	6ca080e7          	jalr	1738(ra) # 80003d1e <namecmp>
    8000565c:	14050a63          	beqz	a0,800057b0 <sys_unlink+0x1b0>
    80005660:	00003597          	auipc	a1,0x3
    80005664:	2d858593          	addi	a1,a1,728 # 80008938 <syscalls_str+0x2c0>
    80005668:	fb040513          	addi	a0,s0,-80
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	6b2080e7          	jalr	1714(ra) # 80003d1e <namecmp>
    80005674:	12050e63          	beqz	a0,800057b0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005678:	f2c40613          	addi	a2,s0,-212
    8000567c:	fb040593          	addi	a1,s0,-80
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	6b6080e7          	jalr	1718(ra) # 80003d38 <dirlookup>
    8000568a:	892a                	mv	s2,a0
    8000568c:	12050263          	beqz	a0,800057b0 <sys_unlink+0x1b0>
  ilock(ip);
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	1c4080e7          	jalr	452(ra) # 80003854 <ilock>
  if(ip->nlink < 1)
    80005698:	04a91783          	lh	a5,74(s2)
    8000569c:	08f05263          	blez	a5,80005720 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056a0:	04491703          	lh	a4,68(s2)
    800056a4:	4785                	li	a5,1
    800056a6:	08f70563          	beq	a4,a5,80005730 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056aa:	4641                	li	a2,16
    800056ac:	4581                	li	a1,0
    800056ae:	fc040513          	addi	a0,s0,-64
    800056b2:	ffffb097          	auipc	ra,0xffffb
    800056b6:	60c080e7          	jalr	1548(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ba:	4741                	li	a4,16
    800056bc:	f2c42683          	lw	a3,-212(s0)
    800056c0:	fc040613          	addi	a2,s0,-64
    800056c4:	4581                	li	a1,0
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	538080e7          	jalr	1336(ra) # 80003c00 <writei>
    800056d0:	47c1                	li	a5,16
    800056d2:	0af51563          	bne	a0,a5,8000577c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056d6:	04491703          	lh	a4,68(s2)
    800056da:	4785                	li	a5,1
    800056dc:	0af70863          	beq	a4,a5,8000578c <sys_unlink+0x18c>
  iunlockput(dp);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	3d4080e7          	jalr	980(ra) # 80003ab6 <iunlockput>
  ip->nlink--;
    800056ea:	04a95783          	lhu	a5,74(s2)
    800056ee:	37fd                	addiw	a5,a5,-1
    800056f0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056f4:	854a                	mv	a0,s2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	094080e7          	jalr	148(ra) # 8000378a <iupdate>
  iunlockput(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	3b6080e7          	jalr	950(ra) # 80003ab6 <iunlockput>
  end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	ba2080e7          	jalr	-1118(ra) # 800042aa <end_op>
  return 0;
    80005710:	4501                	li	a0,0
    80005712:	a84d                	j	800057c4 <sys_unlink+0x1c4>
    end_op();
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	b96080e7          	jalr	-1130(ra) # 800042aa <end_op>
    return -1;
    8000571c:	557d                	li	a0,-1
    8000571e:	a05d                	j	800057c4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005720:	00003517          	auipc	a0,0x3
    80005724:	24050513          	addi	a0,a0,576 # 80008960 <syscalls_str+0x2e8>
    80005728:	ffffb097          	auipc	ra,0xffffb
    8000572c:	e02080e7          	jalr	-510(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005730:	04c92703          	lw	a4,76(s2)
    80005734:	02000793          	li	a5,32
    80005738:	f6e7f9e3          	bgeu	a5,a4,800056aa <sys_unlink+0xaa>
    8000573c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005740:	4741                	li	a4,16
    80005742:	86ce                	mv	a3,s3
    80005744:	f1840613          	addi	a2,s0,-232
    80005748:	4581                	li	a1,0
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	3bc080e7          	jalr	956(ra) # 80003b08 <readi>
    80005754:	47c1                	li	a5,16
    80005756:	00f51b63          	bne	a0,a5,8000576c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000575a:	f1845783          	lhu	a5,-232(s0)
    8000575e:	e7a1                	bnez	a5,800057a6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005760:	29c1                	addiw	s3,s3,16
    80005762:	04c92783          	lw	a5,76(s2)
    80005766:	fcf9ede3          	bltu	s3,a5,80005740 <sys_unlink+0x140>
    8000576a:	b781                	j	800056aa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000576c:	00003517          	auipc	a0,0x3
    80005770:	20c50513          	addi	a0,a0,524 # 80008978 <syscalls_str+0x300>
    80005774:	ffffb097          	auipc	ra,0xffffb
    80005778:	db6080e7          	jalr	-586(ra) # 8000052a <panic>
    panic("unlink: writei");
    8000577c:	00003517          	auipc	a0,0x3
    80005780:	21450513          	addi	a0,a0,532 # 80008990 <syscalls_str+0x318>
    80005784:	ffffb097          	auipc	ra,0xffffb
    80005788:	da6080e7          	jalr	-602(ra) # 8000052a <panic>
    dp->nlink--;
    8000578c:	04a4d783          	lhu	a5,74(s1)
    80005790:	37fd                	addiw	a5,a5,-1
    80005792:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	ff2080e7          	jalr	-14(ra) # 8000378a <iupdate>
    800057a0:	b781                	j	800056e0 <sys_unlink+0xe0>
    return -1;
    800057a2:	557d                	li	a0,-1
    800057a4:	a005                	j	800057c4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057a6:	854a                	mv	a0,s2
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	30e080e7          	jalr	782(ra) # 80003ab6 <iunlockput>
  iunlockput(dp);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	304080e7          	jalr	772(ra) # 80003ab6 <iunlockput>
  end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	af0080e7          	jalr	-1296(ra) # 800042aa <end_op>
  return -1;
    800057c2:	557d                	li	a0,-1
}
    800057c4:	70ae                	ld	ra,232(sp)
    800057c6:	740e                	ld	s0,224(sp)
    800057c8:	64ee                	ld	s1,216(sp)
    800057ca:	694e                	ld	s2,208(sp)
    800057cc:	69ae                	ld	s3,200(sp)
    800057ce:	616d                	addi	sp,sp,240
    800057d0:	8082                	ret

00000000800057d2 <sys_open>:

uint64
sys_open(void)
{
    800057d2:	7131                	addi	sp,sp,-192
    800057d4:	fd06                	sd	ra,184(sp)
    800057d6:	f922                	sd	s0,176(sp)
    800057d8:	f526                	sd	s1,168(sp)
    800057da:	f14a                	sd	s2,160(sp)
    800057dc:	ed4e                	sd	s3,152(sp)
    800057de:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057e0:	08000613          	li	a2,128
    800057e4:	f5040593          	addi	a1,s0,-176
    800057e8:	4501                	li	a0,0
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	446080e7          	jalr	1094(ra) # 80002c30 <argstr>
    return -1;
    800057f2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057f4:	0c054163          	bltz	a0,800058b6 <sys_open+0xe4>
    800057f8:	f4c40593          	addi	a1,s0,-180
    800057fc:	4505                	li	a0,1
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	3ee080e7          	jalr	1006(ra) # 80002bec <argint>
    80005806:	0a054863          	bltz	a0,800058b6 <sys_open+0xe4>

  begin_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	a20080e7          	jalr	-1504(ra) # 8000422a <begin_op>

  if(omode & O_CREATE){
    80005812:	f4c42783          	lw	a5,-180(s0)
    80005816:	2007f793          	andi	a5,a5,512
    8000581a:	cbdd                	beqz	a5,800058d0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000581c:	4681                	li	a3,0
    8000581e:	4601                	li	a2,0
    80005820:	4589                	li	a1,2
    80005822:	f5040513          	addi	a0,s0,-176
    80005826:	00000097          	auipc	ra,0x0
    8000582a:	974080e7          	jalr	-1676(ra) # 8000519a <create>
    8000582e:	892a                	mv	s2,a0
    if(ip == 0){
    80005830:	c959                	beqz	a0,800058c6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005832:	04491703          	lh	a4,68(s2)
    80005836:	478d                	li	a5,3
    80005838:	00f71763          	bne	a4,a5,80005846 <sys_open+0x74>
    8000583c:	04695703          	lhu	a4,70(s2)
    80005840:	47a5                	li	a5,9
    80005842:	0ce7ec63          	bltu	a5,a4,8000591a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	df4080e7          	jalr	-524(ra) # 8000463a <filealloc>
    8000584e:	89aa                	mv	s3,a0
    80005850:	10050263          	beqz	a0,80005954 <sys_open+0x182>
    80005854:	00000097          	auipc	ra,0x0
    80005858:	904080e7          	jalr	-1788(ra) # 80005158 <fdalloc>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	0e054663          	bltz	a0,8000594a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005862:	04491703          	lh	a4,68(s2)
    80005866:	478d                	li	a5,3
    80005868:	0cf70463          	beq	a4,a5,80005930 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000586c:	4789                	li	a5,2
    8000586e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005872:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005876:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000587a:	f4c42783          	lw	a5,-180(s0)
    8000587e:	0017c713          	xori	a4,a5,1
    80005882:	8b05                	andi	a4,a4,1
    80005884:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005888:	0037f713          	andi	a4,a5,3
    8000588c:	00e03733          	snez	a4,a4
    80005890:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005894:	4007f793          	andi	a5,a5,1024
    80005898:	c791                	beqz	a5,800058a4 <sys_open+0xd2>
    8000589a:	04491703          	lh	a4,68(s2)
    8000589e:	4789                	li	a5,2
    800058a0:	08f70f63          	beq	a4,a5,8000593e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	070080e7          	jalr	112(ra) # 80003916 <iunlock>
  end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	9fc080e7          	jalr	-1540(ra) # 800042aa <end_op>

  return fd;
}
    800058b6:	8526                	mv	a0,s1
    800058b8:	70ea                	ld	ra,184(sp)
    800058ba:	744a                	ld	s0,176(sp)
    800058bc:	74aa                	ld	s1,168(sp)
    800058be:	790a                	ld	s2,160(sp)
    800058c0:	69ea                	ld	s3,152(sp)
    800058c2:	6129                	addi	sp,sp,192
    800058c4:	8082                	ret
      end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	9e4080e7          	jalr	-1564(ra) # 800042aa <end_op>
      return -1;
    800058ce:	b7e5                	j	800058b6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058d0:	f5040513          	addi	a0,s0,-176
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	736080e7          	jalr	1846(ra) # 8000400a <namei>
    800058dc:	892a                	mv	s2,a0
    800058de:	c905                	beqz	a0,8000590e <sys_open+0x13c>
    ilock(ip);
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	f74080e7          	jalr	-140(ra) # 80003854 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058e8:	04491703          	lh	a4,68(s2)
    800058ec:	4785                	li	a5,1
    800058ee:	f4f712e3          	bne	a4,a5,80005832 <sys_open+0x60>
    800058f2:	f4c42783          	lw	a5,-180(s0)
    800058f6:	dba1                	beqz	a5,80005846 <sys_open+0x74>
      iunlockput(ip);
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	1bc080e7          	jalr	444(ra) # 80003ab6 <iunlockput>
      end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	9a8080e7          	jalr	-1624(ra) # 800042aa <end_op>
      return -1;
    8000590a:	54fd                	li	s1,-1
    8000590c:	b76d                	j	800058b6 <sys_open+0xe4>
      end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	99c080e7          	jalr	-1636(ra) # 800042aa <end_op>
      return -1;
    80005916:	54fd                	li	s1,-1
    80005918:	bf79                	j	800058b6 <sys_open+0xe4>
    iunlockput(ip);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	19a080e7          	jalr	410(ra) # 80003ab6 <iunlockput>
    end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	986080e7          	jalr	-1658(ra) # 800042aa <end_op>
    return -1;
    8000592c:	54fd                	li	s1,-1
    8000592e:	b761                	j	800058b6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005930:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005934:	04691783          	lh	a5,70(s2)
    80005938:	02f99223          	sh	a5,36(s3)
    8000593c:	bf2d                	j	80005876 <sys_open+0xa4>
    itrunc(ip);
    8000593e:	854a                	mv	a0,s2
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	022080e7          	jalr	34(ra) # 80003962 <itrunc>
    80005948:	bfb1                	j	800058a4 <sys_open+0xd2>
      fileclose(f);
    8000594a:	854e                	mv	a0,s3
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	daa080e7          	jalr	-598(ra) # 800046f6 <fileclose>
    iunlockput(ip);
    80005954:	854a                	mv	a0,s2
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	160080e7          	jalr	352(ra) # 80003ab6 <iunlockput>
    end_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	94c080e7          	jalr	-1716(ra) # 800042aa <end_op>
    return -1;
    80005966:	54fd                	li	s1,-1
    80005968:	b7b9                	j	800058b6 <sys_open+0xe4>

000000008000596a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000596a:	7175                	addi	sp,sp,-144
    8000596c:	e506                	sd	ra,136(sp)
    8000596e:	e122                	sd	s0,128(sp)
    80005970:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	8b8080e7          	jalr	-1864(ra) # 8000422a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000597a:	08000613          	li	a2,128
    8000597e:	f7040593          	addi	a1,s0,-144
    80005982:	4501                	li	a0,0
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	2ac080e7          	jalr	684(ra) # 80002c30 <argstr>
    8000598c:	02054963          	bltz	a0,800059be <sys_mkdir+0x54>
    80005990:	4681                	li	a3,0
    80005992:	4601                	li	a2,0
    80005994:	4585                	li	a1,1
    80005996:	f7040513          	addi	a0,s0,-144
    8000599a:	00000097          	auipc	ra,0x0
    8000599e:	800080e7          	jalr	-2048(ra) # 8000519a <create>
    800059a2:	cd11                	beqz	a0,800059be <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	112080e7          	jalr	274(ra) # 80003ab6 <iunlockput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	8fe080e7          	jalr	-1794(ra) # 800042aa <end_op>
  return 0;
    800059b4:	4501                	li	a0,0
}
    800059b6:	60aa                	ld	ra,136(sp)
    800059b8:	640a                	ld	s0,128(sp)
    800059ba:	6149                	addi	sp,sp,144
    800059bc:	8082                	ret
    end_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	8ec080e7          	jalr	-1812(ra) # 800042aa <end_op>
    return -1;
    800059c6:	557d                	li	a0,-1
    800059c8:	b7fd                	j	800059b6 <sys_mkdir+0x4c>

00000000800059ca <sys_mknod>:

uint64
sys_mknod(void)
{
    800059ca:	7135                	addi	sp,sp,-160
    800059cc:	ed06                	sd	ra,152(sp)
    800059ce:	e922                	sd	s0,144(sp)
    800059d0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	858080e7          	jalr	-1960(ra) # 8000422a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059da:	08000613          	li	a2,128
    800059de:	f7040593          	addi	a1,s0,-144
    800059e2:	4501                	li	a0,0
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	24c080e7          	jalr	588(ra) # 80002c30 <argstr>
    800059ec:	04054a63          	bltz	a0,80005a40 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059f0:	f6c40593          	addi	a1,s0,-148
    800059f4:	4505                	li	a0,1
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	1f6080e7          	jalr	502(ra) # 80002bec <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059fe:	04054163          	bltz	a0,80005a40 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a02:	f6840593          	addi	a1,s0,-152
    80005a06:	4509                	li	a0,2
    80005a08:	ffffd097          	auipc	ra,0xffffd
    80005a0c:	1e4080e7          	jalr	484(ra) # 80002bec <argint>
     argint(1, &major) < 0 ||
    80005a10:	02054863          	bltz	a0,80005a40 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a14:	f6841683          	lh	a3,-152(s0)
    80005a18:	f6c41603          	lh	a2,-148(s0)
    80005a1c:	458d                	li	a1,3
    80005a1e:	f7040513          	addi	a0,s0,-144
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	778080e7          	jalr	1912(ra) # 8000519a <create>
     argint(2, &minor) < 0 ||
    80005a2a:	c919                	beqz	a0,80005a40 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	08a080e7          	jalr	138(ra) # 80003ab6 <iunlockput>
  end_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	876080e7          	jalr	-1930(ra) # 800042aa <end_op>
  return 0;
    80005a3c:	4501                	li	a0,0
    80005a3e:	a031                	j	80005a4a <sys_mknod+0x80>
    end_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	86a080e7          	jalr	-1942(ra) # 800042aa <end_op>
    return -1;
    80005a48:	557d                	li	a0,-1
}
    80005a4a:	60ea                	ld	ra,152(sp)
    80005a4c:	644a                	ld	s0,144(sp)
    80005a4e:	610d                	addi	sp,sp,160
    80005a50:	8082                	ret

0000000080005a52 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a52:	7135                	addi	sp,sp,-160
    80005a54:	ed06                	sd	ra,152(sp)
    80005a56:	e922                	sd	s0,144(sp)
    80005a58:	e526                	sd	s1,136(sp)
    80005a5a:	e14a                	sd	s2,128(sp)
    80005a5c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a5e:	ffffc097          	auipc	ra,0xffffc
    80005a62:	f34080e7          	jalr	-204(ra) # 80001992 <myproc>
    80005a66:	892a                	mv	s2,a0
  
  begin_op();
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	7c2080e7          	jalr	1986(ra) # 8000422a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a70:	08000613          	li	a2,128
    80005a74:	f6040593          	addi	a1,s0,-160
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	1b6080e7          	jalr	438(ra) # 80002c30 <argstr>
    80005a82:	04054b63          	bltz	a0,80005ad8 <sys_chdir+0x86>
    80005a86:	f6040513          	addi	a0,s0,-160
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	580080e7          	jalr	1408(ra) # 8000400a <namei>
    80005a92:	84aa                	mv	s1,a0
    80005a94:	c131                	beqz	a0,80005ad8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	dbe080e7          	jalr	-578(ra) # 80003854 <ilock>
  if(ip->type != T_DIR){
    80005a9e:	04449703          	lh	a4,68(s1)
    80005aa2:	4785                	li	a5,1
    80005aa4:	04f71063          	bne	a4,a5,80005ae4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	e6c080e7          	jalr	-404(ra) # 80003916 <iunlock>
  iput(p->cwd);
    80005ab2:	15093503          	ld	a0,336(s2)
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	f58080e7          	jalr	-168(ra) # 80003a0e <iput>
  end_op();
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	7ec080e7          	jalr	2028(ra) # 800042aa <end_op>
  p->cwd = ip;
    80005ac6:	14993823          	sd	s1,336(s2)
  return 0;
    80005aca:	4501                	li	a0,0
}
    80005acc:	60ea                	ld	ra,152(sp)
    80005ace:	644a                	ld	s0,144(sp)
    80005ad0:	64aa                	ld	s1,136(sp)
    80005ad2:	690a                	ld	s2,128(sp)
    80005ad4:	610d                	addi	sp,sp,160
    80005ad6:	8082                	ret
    end_op();
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	7d2080e7          	jalr	2002(ra) # 800042aa <end_op>
    return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	b7ed                	j	80005acc <sys_chdir+0x7a>
    iunlockput(ip);
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	fd0080e7          	jalr	-48(ra) # 80003ab6 <iunlockput>
    end_op();
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	7bc080e7          	jalr	1980(ra) # 800042aa <end_op>
    return -1;
    80005af6:	557d                	li	a0,-1
    80005af8:	bfd1                	j	80005acc <sys_chdir+0x7a>

0000000080005afa <sys_exec>:

uint64
sys_exec(void)
{
    80005afa:	7145                	addi	sp,sp,-464
    80005afc:	e786                	sd	ra,456(sp)
    80005afe:	e3a2                	sd	s0,448(sp)
    80005b00:	ff26                	sd	s1,440(sp)
    80005b02:	fb4a                	sd	s2,432(sp)
    80005b04:	f74e                	sd	s3,424(sp)
    80005b06:	f352                	sd	s4,416(sp)
    80005b08:	ef56                	sd	s5,408(sp)
    80005b0a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b0c:	08000613          	li	a2,128
    80005b10:	f4040593          	addi	a1,s0,-192
    80005b14:	4501                	li	a0,0
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	11a080e7          	jalr	282(ra) # 80002c30 <argstr>
    return -1;
    80005b1e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b20:	0c054a63          	bltz	a0,80005bf4 <sys_exec+0xfa>
    80005b24:	e3840593          	addi	a1,s0,-456
    80005b28:	4505                	li	a0,1
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	0e4080e7          	jalr	228(ra) # 80002c0e <argaddr>
    80005b32:	0c054163          	bltz	a0,80005bf4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b36:	10000613          	li	a2,256
    80005b3a:	4581                	li	a1,0
    80005b3c:	e4040513          	addi	a0,s0,-448
    80005b40:	ffffb097          	auipc	ra,0xffffb
    80005b44:	17e080e7          	jalr	382(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b48:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b4c:	89a6                	mv	s3,s1
    80005b4e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b50:	02000a13          	li	s4,32
    80005b54:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b58:	00391793          	slli	a5,s2,0x3
    80005b5c:	e3040593          	addi	a1,s0,-464
    80005b60:	e3843503          	ld	a0,-456(s0)
    80005b64:	953e                	add	a0,a0,a5
    80005b66:	ffffd097          	auipc	ra,0xffffd
    80005b6a:	fec080e7          	jalr	-20(ra) # 80002b52 <fetchaddr>
    80005b6e:	02054a63          	bltz	a0,80005ba2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b72:	e3043783          	ld	a5,-464(s0)
    80005b76:	c3b9                	beqz	a5,80005bbc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b78:	ffffb097          	auipc	ra,0xffffb
    80005b7c:	f5a080e7          	jalr	-166(ra) # 80000ad2 <kalloc>
    80005b80:	85aa                	mv	a1,a0
    80005b82:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b86:	cd11                	beqz	a0,80005ba2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b88:	6605                	lui	a2,0x1
    80005b8a:	e3043503          	ld	a0,-464(s0)
    80005b8e:	ffffd097          	auipc	ra,0xffffd
    80005b92:	016080e7          	jalr	22(ra) # 80002ba4 <fetchstr>
    80005b96:	00054663          	bltz	a0,80005ba2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b9a:	0905                	addi	s2,s2,1
    80005b9c:	09a1                	addi	s3,s3,8
    80005b9e:	fb491be3          	bne	s2,s4,80005b54 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba2:	10048913          	addi	s2,s1,256
    80005ba6:	6088                	ld	a0,0(s1)
    80005ba8:	c529                	beqz	a0,80005bf2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	e2c080e7          	jalr	-468(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb2:	04a1                	addi	s1,s1,8
    80005bb4:	ff2499e3          	bne	s1,s2,80005ba6 <sys_exec+0xac>
  return -1;
    80005bb8:	597d                	li	s2,-1
    80005bba:	a82d                	j	80005bf4 <sys_exec+0xfa>
      argv[i] = 0;
    80005bbc:	0a8e                	slli	s5,s5,0x3
    80005bbe:	fc040793          	addi	a5,s0,-64
    80005bc2:	9abe                	add	s5,s5,a5
    80005bc4:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005bc8:	e4040593          	addi	a1,s0,-448
    80005bcc:	f4040513          	addi	a0,s0,-192
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	178080e7          	jalr	376(ra) # 80004d48 <exec>
    80005bd8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bda:	10048993          	addi	s3,s1,256
    80005bde:	6088                	ld	a0,0(s1)
    80005be0:	c911                	beqz	a0,80005bf4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	df4080e7          	jalr	-524(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bea:	04a1                	addi	s1,s1,8
    80005bec:	ff3499e3          	bne	s1,s3,80005bde <sys_exec+0xe4>
    80005bf0:	a011                	j	80005bf4 <sys_exec+0xfa>
  return -1;
    80005bf2:	597d                	li	s2,-1
}
    80005bf4:	854a                	mv	a0,s2
    80005bf6:	60be                	ld	ra,456(sp)
    80005bf8:	641e                	ld	s0,448(sp)
    80005bfa:	74fa                	ld	s1,440(sp)
    80005bfc:	795a                	ld	s2,432(sp)
    80005bfe:	79ba                	ld	s3,424(sp)
    80005c00:	7a1a                	ld	s4,416(sp)
    80005c02:	6afa                	ld	s5,408(sp)
    80005c04:	6179                	addi	sp,sp,464
    80005c06:	8082                	ret

0000000080005c08 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c08:	7139                	addi	sp,sp,-64
    80005c0a:	fc06                	sd	ra,56(sp)
    80005c0c:	f822                	sd	s0,48(sp)
    80005c0e:	f426                	sd	s1,40(sp)
    80005c10:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c12:	ffffc097          	auipc	ra,0xffffc
    80005c16:	d80080e7          	jalr	-640(ra) # 80001992 <myproc>
    80005c1a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c1c:	fd840593          	addi	a1,s0,-40
    80005c20:	4501                	li	a0,0
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	fec080e7          	jalr	-20(ra) # 80002c0e <argaddr>
    return -1;
    80005c2a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c2c:	0e054063          	bltz	a0,80005d0c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c30:	fc840593          	addi	a1,s0,-56
    80005c34:	fd040513          	addi	a0,s0,-48
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	dee080e7          	jalr	-530(ra) # 80004a26 <pipealloc>
    return -1;
    80005c40:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c42:	0c054563          	bltz	a0,80005d0c <sys_pipe+0x104>
  fd0 = -1;
    80005c46:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c4a:	fd043503          	ld	a0,-48(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	50a080e7          	jalr	1290(ra) # 80005158 <fdalloc>
    80005c56:	fca42223          	sw	a0,-60(s0)
    80005c5a:	08054c63          	bltz	a0,80005cf2 <sys_pipe+0xea>
    80005c5e:	fc843503          	ld	a0,-56(s0)
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	4f6080e7          	jalr	1270(ra) # 80005158 <fdalloc>
    80005c6a:	fca42023          	sw	a0,-64(s0)
    80005c6e:	06054863          	bltz	a0,80005cde <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c72:	4691                	li	a3,4
    80005c74:	fc440613          	addi	a2,s0,-60
    80005c78:	fd843583          	ld	a1,-40(s0)
    80005c7c:	68a8                	ld	a0,80(s1)
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	9c0080e7          	jalr	-1600(ra) # 8000163e <copyout>
    80005c86:	02054063          	bltz	a0,80005ca6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c8a:	4691                	li	a3,4
    80005c8c:	fc040613          	addi	a2,s0,-64
    80005c90:	fd843583          	ld	a1,-40(s0)
    80005c94:	0591                	addi	a1,a1,4
    80005c96:	68a8                	ld	a0,80(s1)
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	9a6080e7          	jalr	-1626(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ca0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca2:	06055563          	bgez	a0,80005d0c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ca6:	fc442783          	lw	a5,-60(s0)
    80005caa:	07e9                	addi	a5,a5,26
    80005cac:	078e                	slli	a5,a5,0x3
    80005cae:	97a6                	add	a5,a5,s1
    80005cb0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cb4:	fc042503          	lw	a0,-64(s0)
    80005cb8:	0569                	addi	a0,a0,26
    80005cba:	050e                	slli	a0,a0,0x3
    80005cbc:	9526                	add	a0,a0,s1
    80005cbe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cc2:	fd043503          	ld	a0,-48(s0)
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	a30080e7          	jalr	-1488(ra) # 800046f6 <fileclose>
    fileclose(wf);
    80005cce:	fc843503          	ld	a0,-56(s0)
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	a24080e7          	jalr	-1500(ra) # 800046f6 <fileclose>
    return -1;
    80005cda:	57fd                	li	a5,-1
    80005cdc:	a805                	j	80005d0c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cde:	fc442783          	lw	a5,-60(s0)
    80005ce2:	0007c863          	bltz	a5,80005cf2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ce6:	01a78513          	addi	a0,a5,26
    80005cea:	050e                	slli	a0,a0,0x3
    80005cec:	9526                	add	a0,a0,s1
    80005cee:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cf2:	fd043503          	ld	a0,-48(s0)
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	a00080e7          	jalr	-1536(ra) # 800046f6 <fileclose>
    fileclose(wf);
    80005cfe:	fc843503          	ld	a0,-56(s0)
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	9f4080e7          	jalr	-1548(ra) # 800046f6 <fileclose>
    return -1;
    80005d0a:	57fd                	li	a5,-1
}
    80005d0c:	853e                	mv	a0,a5
    80005d0e:	70e2                	ld	ra,56(sp)
    80005d10:	7442                	ld	s0,48(sp)
    80005d12:	74a2                	ld	s1,40(sp)
    80005d14:	6121                	addi	sp,sp,64
    80005d16:	8082                	ret
	...

0000000080005d20 <kernelvec>:
    80005d20:	7111                	addi	sp,sp,-256
    80005d22:	e006                	sd	ra,0(sp)
    80005d24:	e40a                	sd	sp,8(sp)
    80005d26:	e80e                	sd	gp,16(sp)
    80005d28:	ec12                	sd	tp,24(sp)
    80005d2a:	f016                	sd	t0,32(sp)
    80005d2c:	f41a                	sd	t1,40(sp)
    80005d2e:	f81e                	sd	t2,48(sp)
    80005d30:	fc22                	sd	s0,56(sp)
    80005d32:	e0a6                	sd	s1,64(sp)
    80005d34:	e4aa                	sd	a0,72(sp)
    80005d36:	e8ae                	sd	a1,80(sp)
    80005d38:	ecb2                	sd	a2,88(sp)
    80005d3a:	f0b6                	sd	a3,96(sp)
    80005d3c:	f4ba                	sd	a4,104(sp)
    80005d3e:	f8be                	sd	a5,112(sp)
    80005d40:	fcc2                	sd	a6,120(sp)
    80005d42:	e146                	sd	a7,128(sp)
    80005d44:	e54a                	sd	s2,136(sp)
    80005d46:	e94e                	sd	s3,144(sp)
    80005d48:	ed52                	sd	s4,152(sp)
    80005d4a:	f156                	sd	s5,160(sp)
    80005d4c:	f55a                	sd	s6,168(sp)
    80005d4e:	f95e                	sd	s7,176(sp)
    80005d50:	fd62                	sd	s8,184(sp)
    80005d52:	e1e6                	sd	s9,192(sp)
    80005d54:	e5ea                	sd	s10,200(sp)
    80005d56:	e9ee                	sd	s11,208(sp)
    80005d58:	edf2                	sd	t3,216(sp)
    80005d5a:	f1f6                	sd	t4,224(sp)
    80005d5c:	f5fa                	sd	t5,232(sp)
    80005d5e:	f9fe                	sd	t6,240(sp)
    80005d60:	cbffc0ef          	jal	ra,80002a1e <kerneltrap>
    80005d64:	6082                	ld	ra,0(sp)
    80005d66:	6122                	ld	sp,8(sp)
    80005d68:	61c2                	ld	gp,16(sp)
    80005d6a:	7282                	ld	t0,32(sp)
    80005d6c:	7322                	ld	t1,40(sp)
    80005d6e:	73c2                	ld	t2,48(sp)
    80005d70:	7462                	ld	s0,56(sp)
    80005d72:	6486                	ld	s1,64(sp)
    80005d74:	6526                	ld	a0,72(sp)
    80005d76:	65c6                	ld	a1,80(sp)
    80005d78:	6666                	ld	a2,88(sp)
    80005d7a:	7686                	ld	a3,96(sp)
    80005d7c:	7726                	ld	a4,104(sp)
    80005d7e:	77c6                	ld	a5,112(sp)
    80005d80:	7866                	ld	a6,120(sp)
    80005d82:	688a                	ld	a7,128(sp)
    80005d84:	692a                	ld	s2,136(sp)
    80005d86:	69ca                	ld	s3,144(sp)
    80005d88:	6a6a                	ld	s4,152(sp)
    80005d8a:	7a8a                	ld	s5,160(sp)
    80005d8c:	7b2a                	ld	s6,168(sp)
    80005d8e:	7bca                	ld	s7,176(sp)
    80005d90:	7c6a                	ld	s8,184(sp)
    80005d92:	6c8e                	ld	s9,192(sp)
    80005d94:	6d2e                	ld	s10,200(sp)
    80005d96:	6dce                	ld	s11,208(sp)
    80005d98:	6e6e                	ld	t3,216(sp)
    80005d9a:	7e8e                	ld	t4,224(sp)
    80005d9c:	7f2e                	ld	t5,232(sp)
    80005d9e:	7fce                	ld	t6,240(sp)
    80005da0:	6111                	addi	sp,sp,256
    80005da2:	10200073          	sret
    80005da6:	00000013          	nop
    80005daa:	00000013          	nop
    80005dae:	0001                	nop

0000000080005db0 <timervec>:
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	e10c                	sd	a1,0(a0)
    80005db6:	e510                	sd	a2,8(a0)
    80005db8:	e914                	sd	a3,16(a0)
    80005dba:	6d0c                	ld	a1,24(a0)
    80005dbc:	7110                	ld	a2,32(a0)
    80005dbe:	6194                	ld	a3,0(a1)
    80005dc0:	96b2                	add	a3,a3,a2
    80005dc2:	e194                	sd	a3,0(a1)
    80005dc4:	4589                	li	a1,2
    80005dc6:	14459073          	csrw	sip,a1
    80005dca:	6914                	ld	a3,16(a0)
    80005dcc:	6510                	ld	a2,8(a0)
    80005dce:	610c                	ld	a1,0(a0)
    80005dd0:	34051573          	csrrw	a0,mscratch,a0
    80005dd4:	30200073          	mret
	...

0000000080005dda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dda:	1141                	addi	sp,sp,-16
    80005ddc:	e422                	sd	s0,8(sp)
    80005dde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005de0:	0c0007b7          	lui	a5,0xc000
    80005de4:	4705                	li	a4,1
    80005de6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005de8:	c3d8                	sw	a4,4(a5)
}
    80005dea:	6422                	ld	s0,8(sp)
    80005dec:	0141                	addi	sp,sp,16
    80005dee:	8082                	ret

0000000080005df0 <plicinithart>:

void
plicinithart(void)
{
    80005df0:	1141                	addi	sp,sp,-16
    80005df2:	e406                	sd	ra,8(sp)
    80005df4:	e022                	sd	s0,0(sp)
    80005df6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	b6e080e7          	jalr	-1170(ra) # 80001966 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e00:	0085171b          	slliw	a4,a0,0x8
    80005e04:	0c0027b7          	lui	a5,0xc002
    80005e08:	97ba                	add	a5,a5,a4
    80005e0a:	40200713          	li	a4,1026
    80005e0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e12:	00d5151b          	slliw	a0,a0,0xd
    80005e16:	0c2017b7          	lui	a5,0xc201
    80005e1a:	953e                	add	a0,a0,a5
    80005e1c:	00052023          	sw	zero,0(a0)
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret

0000000080005e28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e28:	1141                	addi	sp,sp,-16
    80005e2a:	e406                	sd	ra,8(sp)
    80005e2c:	e022                	sd	s0,0(sp)
    80005e2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e30:	ffffc097          	auipc	ra,0xffffc
    80005e34:	b36080e7          	jalr	-1226(ra) # 80001966 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e38:	00d5179b          	slliw	a5,a0,0xd
    80005e3c:	0c201537          	lui	a0,0xc201
    80005e40:	953e                	add	a0,a0,a5
  return irq;
}
    80005e42:	4148                	lw	a0,4(a0)
    80005e44:	60a2                	ld	ra,8(sp)
    80005e46:	6402                	ld	s0,0(sp)
    80005e48:	0141                	addi	sp,sp,16
    80005e4a:	8082                	ret

0000000080005e4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e4c:	1101                	addi	sp,sp,-32
    80005e4e:	ec06                	sd	ra,24(sp)
    80005e50:	e822                	sd	s0,16(sp)
    80005e52:	e426                	sd	s1,8(sp)
    80005e54:	1000                	addi	s0,sp,32
    80005e56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	b0e080e7          	jalr	-1266(ra) # 80001966 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e60:	00d5151b          	slliw	a0,a0,0xd
    80005e64:	0c2017b7          	lui	a5,0xc201
    80005e68:	97aa                	add	a5,a5,a0
    80005e6a:	c3c4                	sw	s1,4(a5)
}
    80005e6c:	60e2                	ld	ra,24(sp)
    80005e6e:	6442                	ld	s0,16(sp)
    80005e70:	64a2                	ld	s1,8(sp)
    80005e72:	6105                	addi	sp,sp,32
    80005e74:	8082                	ret

0000000080005e76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e76:	1141                	addi	sp,sp,-16
    80005e78:	e406                	sd	ra,8(sp)
    80005e7a:	e022                	sd	s0,0(sp)
    80005e7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e7e:	479d                	li	a5,7
    80005e80:	06a7c963          	blt	a5,a0,80005ef2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e84:	0001d797          	auipc	a5,0x1d
    80005e88:	17c78793          	addi	a5,a5,380 # 80023000 <disk>
    80005e8c:	00a78733          	add	a4,a5,a0
    80005e90:	6789                	lui	a5,0x2
    80005e92:	97ba                	add	a5,a5,a4
    80005e94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e98:	e7ad                	bnez	a5,80005f02 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e9a:	00451793          	slli	a5,a0,0x4
    80005e9e:	0001f717          	auipc	a4,0x1f
    80005ea2:	16270713          	addi	a4,a4,354 # 80025000 <disk+0x2000>
    80005ea6:	6314                	ld	a3,0(a4)
    80005ea8:	96be                	add	a3,a3,a5
    80005eaa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005eae:	6314                	ld	a3,0(a4)
    80005eb0:	96be                	add	a3,a3,a5
    80005eb2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005eb6:	6314                	ld	a3,0(a4)
    80005eb8:	96be                	add	a3,a3,a5
    80005eba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005ebe:	6318                	ld	a4,0(a4)
    80005ec0:	97ba                	add	a5,a5,a4
    80005ec2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ec6:	0001d797          	auipc	a5,0x1d
    80005eca:	13a78793          	addi	a5,a5,314 # 80023000 <disk>
    80005ece:	97aa                	add	a5,a5,a0
    80005ed0:	6509                	lui	a0,0x2
    80005ed2:	953e                	add	a0,a0,a5
    80005ed4:	4785                	li	a5,1
    80005ed6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eda:	0001f517          	auipc	a0,0x1f
    80005ede:	13e50513          	addi	a0,a0,318 # 80025018 <disk+0x2018>
    80005ee2:	ffffc097          	auipc	ra,0xffffc
    80005ee6:	378080e7          	jalr	888(ra) # 8000225a <wakeup>
}
    80005eea:	60a2                	ld	ra,8(sp)
    80005eec:	6402                	ld	s0,0(sp)
    80005eee:	0141                	addi	sp,sp,16
    80005ef0:	8082                	ret
    panic("free_desc 1");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	aae50513          	addi	a0,a0,-1362 # 800089a0 <syscalls_str+0x328>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	630080e7          	jalr	1584(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	aae50513          	addi	a0,a0,-1362 # 800089b0 <syscalls_str+0x338>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	620080e7          	jalr	1568(ra) # 8000052a <panic>

0000000080005f12 <virtio_disk_init>:
{
    80005f12:	1101                	addi	sp,sp,-32
    80005f14:	ec06                	sd	ra,24(sp)
    80005f16:	e822                	sd	s0,16(sp)
    80005f18:	e426                	sd	s1,8(sp)
    80005f1a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f1c:	00003597          	auipc	a1,0x3
    80005f20:	aa458593          	addi	a1,a1,-1372 # 800089c0 <syscalls_str+0x348>
    80005f24:	0001f517          	auipc	a0,0x1f
    80005f28:	20450513          	addi	a0,a0,516 # 80025128 <disk+0x2128>
    80005f2c:	ffffb097          	auipc	ra,0xffffb
    80005f30:	c06080e7          	jalr	-1018(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f34:	100017b7          	lui	a5,0x10001
    80005f38:	4398                	lw	a4,0(a5)
    80005f3a:	2701                	sext.w	a4,a4
    80005f3c:	747277b7          	lui	a5,0x74727
    80005f40:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f44:	0ef71163          	bne	a4,a5,80006026 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f48:	100017b7          	lui	a5,0x10001
    80005f4c:	43dc                	lw	a5,4(a5)
    80005f4e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f50:	4705                	li	a4,1
    80005f52:	0ce79a63          	bne	a5,a4,80006026 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f56:	100017b7          	lui	a5,0x10001
    80005f5a:	479c                	lw	a5,8(a5)
    80005f5c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f5e:	4709                	li	a4,2
    80005f60:	0ce79363          	bne	a5,a4,80006026 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f64:	100017b7          	lui	a5,0x10001
    80005f68:	47d8                	lw	a4,12(a5)
    80005f6a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f6c:	554d47b7          	lui	a5,0x554d4
    80005f70:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f74:	0af71963          	bne	a4,a5,80006026 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f78:	100017b7          	lui	a5,0x10001
    80005f7c:	4705                	li	a4,1
    80005f7e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f80:	470d                	li	a4,3
    80005f82:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f84:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f86:	c7ffe737          	lui	a4,0xc7ffe
    80005f8a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f8e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f90:	2701                	sext.w	a4,a4
    80005f92:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f94:	472d                	li	a4,11
    80005f96:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f98:	473d                	li	a4,15
    80005f9a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f9c:	6705                	lui	a4,0x1
    80005f9e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fa0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fa4:	5bdc                	lw	a5,52(a5)
    80005fa6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fa8:	c7d9                	beqz	a5,80006036 <virtio_disk_init+0x124>
  if(max < NUM)
    80005faa:	471d                	li	a4,7
    80005fac:	08f77d63          	bgeu	a4,a5,80006046 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fb0:	100014b7          	lui	s1,0x10001
    80005fb4:	47a1                	li	a5,8
    80005fb6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fb8:	6609                	lui	a2,0x2
    80005fba:	4581                	li	a1,0
    80005fbc:	0001d517          	auipc	a0,0x1d
    80005fc0:	04450513          	addi	a0,a0,68 # 80023000 <disk>
    80005fc4:	ffffb097          	auipc	ra,0xffffb
    80005fc8:	cfa080e7          	jalr	-774(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fcc:	0001d717          	auipc	a4,0x1d
    80005fd0:	03470713          	addi	a4,a4,52 # 80023000 <disk>
    80005fd4:	00c75793          	srli	a5,a4,0xc
    80005fd8:	2781                	sext.w	a5,a5
    80005fda:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fdc:	0001f797          	auipc	a5,0x1f
    80005fe0:	02478793          	addi	a5,a5,36 # 80025000 <disk+0x2000>
    80005fe4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fe6:	0001d717          	auipc	a4,0x1d
    80005fea:	09a70713          	addi	a4,a4,154 # 80023080 <disk+0x80>
    80005fee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005ff0:	0001e717          	auipc	a4,0x1e
    80005ff4:	01070713          	addi	a4,a4,16 # 80024000 <disk+0x1000>
    80005ff8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ffa:	4705                	li	a4,1
    80005ffc:	00e78c23          	sb	a4,24(a5)
    80006000:	00e78ca3          	sb	a4,25(a5)
    80006004:	00e78d23          	sb	a4,26(a5)
    80006008:	00e78da3          	sb	a4,27(a5)
    8000600c:	00e78e23          	sb	a4,28(a5)
    80006010:	00e78ea3          	sb	a4,29(a5)
    80006014:	00e78f23          	sb	a4,30(a5)
    80006018:	00e78fa3          	sb	a4,31(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6105                	addi	sp,sp,32
    80006024:	8082                	ret
    panic("could not find virtio disk");
    80006026:	00003517          	auipc	a0,0x3
    8000602a:	9aa50513          	addi	a0,a0,-1622 # 800089d0 <syscalls_str+0x358>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	4fc080e7          	jalr	1276(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006036:	00003517          	auipc	a0,0x3
    8000603a:	9ba50513          	addi	a0,a0,-1606 # 800089f0 <syscalls_str+0x378>
    8000603e:	ffffa097          	auipc	ra,0xffffa
    80006042:	4ec080e7          	jalr	1260(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006046:	00003517          	auipc	a0,0x3
    8000604a:	9ca50513          	addi	a0,a0,-1590 # 80008a10 <syscalls_str+0x398>
    8000604e:	ffffa097          	auipc	ra,0xffffa
    80006052:	4dc080e7          	jalr	1244(ra) # 8000052a <panic>

0000000080006056 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006056:	7119                	addi	sp,sp,-128
    80006058:	fc86                	sd	ra,120(sp)
    8000605a:	f8a2                	sd	s0,112(sp)
    8000605c:	f4a6                	sd	s1,104(sp)
    8000605e:	f0ca                	sd	s2,96(sp)
    80006060:	ecce                	sd	s3,88(sp)
    80006062:	e8d2                	sd	s4,80(sp)
    80006064:	e4d6                	sd	s5,72(sp)
    80006066:	e0da                	sd	s6,64(sp)
    80006068:	fc5e                	sd	s7,56(sp)
    8000606a:	f862                	sd	s8,48(sp)
    8000606c:	f466                	sd	s9,40(sp)
    8000606e:	f06a                	sd	s10,32(sp)
    80006070:	ec6e                	sd	s11,24(sp)
    80006072:	0100                	addi	s0,sp,128
    80006074:	8aaa                	mv	s5,a0
    80006076:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006078:	00c52c83          	lw	s9,12(a0)
    8000607c:	001c9c9b          	slliw	s9,s9,0x1
    80006080:	1c82                	slli	s9,s9,0x20
    80006082:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006086:	0001f517          	auipc	a0,0x1f
    8000608a:	0a250513          	addi	a0,a0,162 # 80025128 <disk+0x2128>
    8000608e:	ffffb097          	auipc	ra,0xffffb
    80006092:	b34080e7          	jalr	-1228(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006096:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006098:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000609a:	0001dc17          	auipc	s8,0x1d
    8000609e:	f66c0c13          	addi	s8,s8,-154 # 80023000 <disk>
    800060a2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800060a4:	4b0d                	li	s6,3
    800060a6:	a0ad                	j	80006110 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800060a8:	00fc0733          	add	a4,s8,a5
    800060ac:	975e                	add	a4,a4,s7
    800060ae:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060b2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060b4:	0207c563          	bltz	a5,800060de <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060b8:	2905                	addiw	s2,s2,1
    800060ba:	0611                	addi	a2,a2,4
    800060bc:	19690d63          	beq	s2,s6,80006256 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800060c0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060c2:	0001f717          	auipc	a4,0x1f
    800060c6:	f5670713          	addi	a4,a4,-170 # 80025018 <disk+0x2018>
    800060ca:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060cc:	00074683          	lbu	a3,0(a4)
    800060d0:	fee1                	bnez	a3,800060a8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060d2:	2785                	addiw	a5,a5,1
    800060d4:	0705                	addi	a4,a4,1
    800060d6:	fe979be3          	bne	a5,s1,800060cc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060da:	57fd                	li	a5,-1
    800060dc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060de:	01205d63          	blez	s2,800060f8 <virtio_disk_rw+0xa2>
    800060e2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060e4:	000a2503          	lw	a0,0(s4)
    800060e8:	00000097          	auipc	ra,0x0
    800060ec:	d8e080e7          	jalr	-626(ra) # 80005e76 <free_desc>
      for(int j = 0; j < i; j++)
    800060f0:	2d85                	addiw	s11,s11,1
    800060f2:	0a11                	addi	s4,s4,4
    800060f4:	ffb918e3          	bne	s2,s11,800060e4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f8:	0001f597          	auipc	a1,0x1f
    800060fc:	03058593          	addi	a1,a1,48 # 80025128 <disk+0x2128>
    80006100:	0001f517          	auipc	a0,0x1f
    80006104:	f1850513          	addi	a0,a0,-232 # 80025018 <disk+0x2018>
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	fc6080e7          	jalr	-58(ra) # 800020ce <sleep>
  for(int i = 0; i < 3; i++){
    80006110:	f8040a13          	addi	s4,s0,-128
{
    80006114:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006116:	894e                	mv	s2,s3
    80006118:	b765                	j	800060c0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000611a:	0001f697          	auipc	a3,0x1f
    8000611e:	ee66b683          	ld	a3,-282(a3) # 80025000 <disk+0x2000>
    80006122:	96ba                	add	a3,a3,a4
    80006124:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006128:	0001d817          	auipc	a6,0x1d
    8000612c:	ed880813          	addi	a6,a6,-296 # 80023000 <disk>
    80006130:	0001f697          	auipc	a3,0x1f
    80006134:	ed068693          	addi	a3,a3,-304 # 80025000 <disk+0x2000>
    80006138:	6290                	ld	a2,0(a3)
    8000613a:	963a                	add	a2,a2,a4
    8000613c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006140:	0015e593          	ori	a1,a1,1
    80006144:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006148:	f8842603          	lw	a2,-120(s0)
    8000614c:	628c                	ld	a1,0(a3)
    8000614e:	972e                	add	a4,a4,a1
    80006150:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006154:	20050593          	addi	a1,a0,512
    80006158:	0592                	slli	a1,a1,0x4
    8000615a:	95c2                	add	a1,a1,a6
    8000615c:	577d                	li	a4,-1
    8000615e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006162:	00461713          	slli	a4,a2,0x4
    80006166:	6290                	ld	a2,0(a3)
    80006168:	963a                	add	a2,a2,a4
    8000616a:	03078793          	addi	a5,a5,48
    8000616e:	97c2                	add	a5,a5,a6
    80006170:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006172:	629c                	ld	a5,0(a3)
    80006174:	97ba                	add	a5,a5,a4
    80006176:	4605                	li	a2,1
    80006178:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000617a:	629c                	ld	a5,0(a3)
    8000617c:	97ba                	add	a5,a5,a4
    8000617e:	4809                	li	a6,2
    80006180:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006184:	629c                	ld	a5,0(a3)
    80006186:	973e                	add	a4,a4,a5
    80006188:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000618c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006190:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006194:	6698                	ld	a4,8(a3)
    80006196:	00275783          	lhu	a5,2(a4)
    8000619a:	8b9d                	andi	a5,a5,7
    8000619c:	0786                	slli	a5,a5,0x1
    8000619e:	97ba                	add	a5,a5,a4
    800061a0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    800061a4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061a8:	6698                	ld	a4,8(a3)
    800061aa:	00275783          	lhu	a5,2(a4)
    800061ae:	2785                	addiw	a5,a5,1
    800061b0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061b4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061b8:	100017b7          	lui	a5,0x10001
    800061bc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061c0:	004aa783          	lw	a5,4(s5)
    800061c4:	02c79163          	bne	a5,a2,800061e6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800061c8:	0001f917          	auipc	s2,0x1f
    800061cc:	f6090913          	addi	s2,s2,-160 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061d0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061d2:	85ca                	mv	a1,s2
    800061d4:	8556                	mv	a0,s5
    800061d6:	ffffc097          	auipc	ra,0xffffc
    800061da:	ef8080e7          	jalr	-264(ra) # 800020ce <sleep>
  while(b->disk == 1) {
    800061de:	004aa783          	lw	a5,4(s5)
    800061e2:	fe9788e3          	beq	a5,s1,800061d2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800061e6:	f8042903          	lw	s2,-128(s0)
    800061ea:	20090793          	addi	a5,s2,512
    800061ee:	00479713          	slli	a4,a5,0x4
    800061f2:	0001d797          	auipc	a5,0x1d
    800061f6:	e0e78793          	addi	a5,a5,-498 # 80023000 <disk>
    800061fa:	97ba                	add	a5,a5,a4
    800061fc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006200:	0001f997          	auipc	s3,0x1f
    80006204:	e0098993          	addi	s3,s3,-512 # 80025000 <disk+0x2000>
    80006208:	00491713          	slli	a4,s2,0x4
    8000620c:	0009b783          	ld	a5,0(s3)
    80006210:	97ba                	add	a5,a5,a4
    80006212:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006216:	854a                	mv	a0,s2
    80006218:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000621c:	00000097          	auipc	ra,0x0
    80006220:	c5a080e7          	jalr	-934(ra) # 80005e76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006224:	8885                	andi	s1,s1,1
    80006226:	f0ed                	bnez	s1,80006208 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006228:	0001f517          	auipc	a0,0x1f
    8000622c:	f0050513          	addi	a0,a0,-256 # 80025128 <disk+0x2128>
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
}
    80006238:	70e6                	ld	ra,120(sp)
    8000623a:	7446                	ld	s0,112(sp)
    8000623c:	74a6                	ld	s1,104(sp)
    8000623e:	7906                	ld	s2,96(sp)
    80006240:	69e6                	ld	s3,88(sp)
    80006242:	6a46                	ld	s4,80(sp)
    80006244:	6aa6                	ld	s5,72(sp)
    80006246:	6b06                	ld	s6,64(sp)
    80006248:	7be2                	ld	s7,56(sp)
    8000624a:	7c42                	ld	s8,48(sp)
    8000624c:	7ca2                	ld	s9,40(sp)
    8000624e:	7d02                	ld	s10,32(sp)
    80006250:	6de2                	ld	s11,24(sp)
    80006252:	6109                	addi	sp,sp,128
    80006254:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006256:	f8042503          	lw	a0,-128(s0)
    8000625a:	20050793          	addi	a5,a0,512
    8000625e:	0792                	slli	a5,a5,0x4
  if(write)
    80006260:	0001d817          	auipc	a6,0x1d
    80006264:	da080813          	addi	a6,a6,-608 # 80023000 <disk>
    80006268:	00f80733          	add	a4,a6,a5
    8000626c:	01a036b3          	snez	a3,s10
    80006270:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006274:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006278:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000627c:	7679                	lui	a2,0xffffe
    8000627e:	963e                	add	a2,a2,a5
    80006280:	0001f697          	auipc	a3,0x1f
    80006284:	d8068693          	addi	a3,a3,-640 # 80025000 <disk+0x2000>
    80006288:	6298                	ld	a4,0(a3)
    8000628a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000628c:	0a878593          	addi	a1,a5,168
    80006290:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006292:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006294:	6298                	ld	a4,0(a3)
    80006296:	9732                	add	a4,a4,a2
    80006298:	45c1                	li	a1,16
    8000629a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000629c:	6298                	ld	a4,0(a3)
    8000629e:	9732                	add	a4,a4,a2
    800062a0:	4585                	li	a1,1
    800062a2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800062a6:	f8442703          	lw	a4,-124(s0)
    800062aa:	628c                	ld	a1,0(a3)
    800062ac:	962e                	add	a2,a2,a1
    800062ae:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800062b2:	0712                	slli	a4,a4,0x4
    800062b4:	6290                	ld	a2,0(a3)
    800062b6:	963a                	add	a2,a2,a4
    800062b8:	058a8593          	addi	a1,s5,88
    800062bc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062be:	6294                	ld	a3,0(a3)
    800062c0:	96ba                	add	a3,a3,a4
    800062c2:	40000613          	li	a2,1024
    800062c6:	c690                	sw	a2,8(a3)
  if(write)
    800062c8:	e40d19e3          	bnez	s10,8000611a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062cc:	0001f697          	auipc	a3,0x1f
    800062d0:	d346b683          	ld	a3,-716(a3) # 80025000 <disk+0x2000>
    800062d4:	96ba                	add	a3,a3,a4
    800062d6:	4609                	li	a2,2
    800062d8:	00c69623          	sh	a2,12(a3)
    800062dc:	b5b1                	j	80006128 <virtio_disk_rw+0xd2>

00000000800062de <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062de:	1101                	addi	sp,sp,-32
    800062e0:	ec06                	sd	ra,24(sp)
    800062e2:	e822                	sd	s0,16(sp)
    800062e4:	e426                	sd	s1,8(sp)
    800062e6:	e04a                	sd	s2,0(sp)
    800062e8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062ea:	0001f517          	auipc	a0,0x1f
    800062ee:	e3e50513          	addi	a0,a0,-450 # 80025128 <disk+0x2128>
    800062f2:	ffffb097          	auipc	ra,0xffffb
    800062f6:	8d0080e7          	jalr	-1840(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062fa:	10001737          	lui	a4,0x10001
    800062fe:	533c                	lw	a5,96(a4)
    80006300:	8b8d                	andi	a5,a5,3
    80006302:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006304:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006308:	0001f797          	auipc	a5,0x1f
    8000630c:	cf878793          	addi	a5,a5,-776 # 80025000 <disk+0x2000>
    80006310:	6b94                	ld	a3,16(a5)
    80006312:	0207d703          	lhu	a4,32(a5)
    80006316:	0026d783          	lhu	a5,2(a3)
    8000631a:	06f70163          	beq	a4,a5,8000637c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000631e:	0001d917          	auipc	s2,0x1d
    80006322:	ce290913          	addi	s2,s2,-798 # 80023000 <disk>
    80006326:	0001f497          	auipc	s1,0x1f
    8000632a:	cda48493          	addi	s1,s1,-806 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000632e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006332:	6898                	ld	a4,16(s1)
    80006334:	0204d783          	lhu	a5,32(s1)
    80006338:	8b9d                	andi	a5,a5,7
    8000633a:	078e                	slli	a5,a5,0x3
    8000633c:	97ba                	add	a5,a5,a4
    8000633e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006340:	20078713          	addi	a4,a5,512
    80006344:	0712                	slli	a4,a4,0x4
    80006346:	974a                	add	a4,a4,s2
    80006348:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000634c:	e731                	bnez	a4,80006398 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000634e:	20078793          	addi	a5,a5,512
    80006352:	0792                	slli	a5,a5,0x4
    80006354:	97ca                	add	a5,a5,s2
    80006356:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006358:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000635c:	ffffc097          	auipc	ra,0xffffc
    80006360:	efe080e7          	jalr	-258(ra) # 8000225a <wakeup>

    disk.used_idx += 1;
    80006364:	0204d783          	lhu	a5,32(s1)
    80006368:	2785                	addiw	a5,a5,1
    8000636a:	17c2                	slli	a5,a5,0x30
    8000636c:	93c1                	srli	a5,a5,0x30
    8000636e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006372:	6898                	ld	a4,16(s1)
    80006374:	00275703          	lhu	a4,2(a4)
    80006378:	faf71be3          	bne	a4,a5,8000632e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000637c:	0001f517          	auipc	a0,0x1f
    80006380:	dac50513          	addi	a0,a0,-596 # 80025128 <disk+0x2128>
    80006384:	ffffb097          	auipc	ra,0xffffb
    80006388:	8f2080e7          	jalr	-1806(ra) # 80000c76 <release>
}
    8000638c:	60e2                	ld	ra,24(sp)
    8000638e:	6442                	ld	s0,16(sp)
    80006390:	64a2                	ld	s1,8(sp)
    80006392:	6902                	ld	s2,0(sp)
    80006394:	6105                	addi	sp,sp,32
    80006396:	8082                	ret
      panic("virtio_disk_intr status");
    80006398:	00002517          	auipc	a0,0x2
    8000639c:	69850513          	addi	a0,a0,1688 # 80008a30 <syscalls_str+0x3b8>
    800063a0:	ffffa097          	auipc	ra,0xffffa
    800063a4:	18a080e7          	jalr	394(ra) # 8000052a <panic>
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
